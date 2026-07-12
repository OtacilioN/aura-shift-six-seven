import 'dart:math' as math;

import 'package:aura_shift_six_seven/game/aura_scene.dart';
import 'package:aura_shift_six_seven/game/item_visual_effects.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _SpringState = ({double value, double velocity});

_SpringState _runSpring({
  required int fps,
  required double duration,
  required double value,
  required double velocity,
  required double target,
}) {
  final frameDuration = 1 / fps;
  var elapsed = 0.0;
  var state = (value: value, velocity: velocity);

  while (duration - elapsed > 1e-12) {
    final dt = math.min(frameDuration, duration - elapsed);
    state = AuraPoseSpring.advance(
      value: state.value,
      velocity: state.velocity,
      target: target,
      dt: dt,
    );
    elapsed += dt;
  }

  return state;
}

void main() {
  group('AuraItemVisualEffects', () {
    test('defines one distinct effect profile for every appearance', () {
      final expected = <String>{
        for (final branch in const ['A', 'B', 'C'])
          for (var depth = 1; depth <= 5; depth++) 'ITEM-$branch-0$depth',
        for (var depth = 1; depth <= 3; depth++) 'ITEM-CONV-0$depth',
      };
      expect(AuraItemVisualEffects.profiles.keys.toSet(), expected);
      expect(
        AuraItemVisualEffects.profiles.values
            .map((profile) => profile.kind)
            .toSet(),
        hasLength(18),
      );
    });

    test('keeps props world-fixed while wearables inherit character motion',
        () {
      expect(
        AuraItemVisualEffects.profiles['ITEM-A-03']!.followsCharacter,
        isTrue,
      );
      expect(
        AuraItemVisualEffects.profiles['ITEM-B-02']!.followsCharacter,
        isTrue,
      );
      expect(
        AuraItemVisualEffects.profiles['ITEM-B-03']!.followsCharacter,
        isTrue,
      );
      expect(
        AuraItemVisualEffects.profiles['ITEM-B-01']!.followsCharacter,
        isFalse,
      );
      expect(
        AuraItemVisualEffects.profiles['ITEM-C-05']!.followsCharacter,
        isFalse,
      );
    });
  });

  group('AuraAppearancePlacement', () {
    test('keeps scene props world-fixed and worn items on the mascot', () {
      for (final slot in const [
        'GROUND_BACK',
        'GROUND_PROP',
        'SCENE_FRAME',
        'AURA_BACK',
      ]) {
        expect(AuraAppearancePlacement.followsCharacter(slot), isFalse);
      }
      for (final slot in const [
        'CHEST',
        'FACE_SIDE',
        'FACE_WEAR',
        'HEAD_WEAR',
        'BODY_BACK',
        'ANKLES',
      ]) {
        expect(AuraAppearancePlacement.followsCharacter(slot), isTrue);
      }
    });

    test('face and head art follows the head lean more than the torso', () {
      expect(AuraAppearancePlacement.leanFactor('CHEST'), 1.0);
      expect(AuraAppearancePlacement.leanFactor('FACE_WEAR'), 1.15);
      expect(AuraAppearancePlacement.leanFactor('HEAD_WEAR'), 1.15);
      expect(AuraAppearancePlacement.leanFactor('SHOULDER'), 0.72);
    });
  });

  final sampledSwings = List<double>.generate(
    21,
    (index) => -1 + index / 10,
  );

  group('AuraUnionLinkGeometry', () {
    test('routes the hand link below the face for every sampled pose', () {
      for (final swing in sampledSwings) {
        final pose = AuraCharacterRigPose.forSwing(swing);
        final route = AuraUnionLinkGeometry.fromWrists(
          pose.leftHand.wrist,
          pose.rightHand.wrist,
        );

        expect(
          (route.leftSocket - pose.leftHand.wrist).distance,
          closeTo(math.sqrt(34 * 34 + 18 * 18), 0.001),
        );
        expect(
          (route.rightSocket - pose.rightHand.wrist).distance,
          closeTo(math.sqrt(34 * 34 + 18 * 18), 0.001),
        );
        for (var sample = 0; sample <= 40; sample++) {
          final point = route.pointAt(sample / 40);
          if (point.dx >= 338 && point.dx <= 686) {
            expect(
              point.dy,
              greaterThan(520),
              reason: 'union cable entered face corridor at swing $swing',
            );
          }
        }
      }
    });
  });

  group('AuraCharacterRigPose Six-Seven rig', () {
    test('Six raises the screen-right hand and Seven raises screen-left', () {
      final six = AuraCharacterRigPose.forSwing(-1);
      final seven = AuraCharacterRigPose.forSwing(1);

      expect(six.rightHand.center.dx, greaterThan(six.leftHand.center.dx));
      expect(six.rightHand.center.dy, lessThan(six.leftHand.center.dy));
      expect(seven.leftHand.center.dx, lessThan(seven.rightHand.center.dx));
      expect(seven.leftHand.center.dy, lessThan(seven.rightHand.center.dy));
    });

    test('both palms remain turned upward throughout the motion', () {
      for (final swing in sampledSwings) {
        final pose = AuraCharacterRigPose.forSwing(swing);

        expect(
          pose.leftHand.palmUp,
          isTrue,
          reason: 'left palm must face upward at swing $swing',
        );
        expect(
          pose.rightHand.palmUp,
          isTrue,
          reason: 'right palm must face upward at swing $swing',
        );
      }
    });

    test('upturned palms stay foreshortened and deeply cupped', () {
      for (final swing in sampledSwings) {
        final pose = AuraCharacterRigPose.forSwing(swing);
        final hands = <(AuraHandRigPose, bool)>[
          (pose.leftHand, true),
          (pose.rightHand, false),
        ];

        for (final (hand, isLeft) in hands) {
          final geometry = AuraCuppedHandGeometry.fromPose(
            hand,
            isLeft: isLeft,
          );

          expect(
            geometry.projectedPalmAspect,
            inInclusiveRange(0.44, 0.54),
            reason: 'palm became frontal at swing $swing',
          );
          expect(
            hand.projectionYScale,
            lessThan(math.sin(33 * math.pi / 180)),
            reason: 'palm pitch exceeded 33 degrees from sky at swing $swing',
          );
          expect(
            hand.cupAmount,
            greaterThanOrEqualTo(0.82),
            reason: 'palm lost its cup at swing $swing',
          );
          expect(
            geometry.wristAnchor.dy,
            greaterThan(geometry.palmHalfDepth),
            reason: 'wrist must enter behind the near rim at swing $swing',
          );
          expect(
            geometry.wristAnchor.dx.sign,
            -geometry.outer.sign,
            reason: 'wrist must enter from the body-side of the bowl',
          );
        }
      }
    });

    test('four fingertip pads curl into the bowl instead of standing up', () {
      for (final swing in sampledSwings) {
        final pose = AuraCharacterRigPose.forSwing(swing);
        final geometries = [
          AuraCuppedHandGeometry.fromPose(pose.leftHand, isLeft: true),
          AuraCuppedHandGeometry.fromPose(pose.rightHand, isLeft: false),
        ];

        for (final geometry in geometries) {
          expect(geometry.fingers, hasLength(4));
          for (final finger in geometry.fingers) {
            expect(
              finger.tip.dy,
              greaterThan(finger.base.dy),
              reason: 'finger must curl from the far rim toward the bowl',
            );
            expect(
              finger.height / finger.width,
              inInclusiveRange(0.75, 0.90),
              reason:
                  'finger pad must stay compact, not become a stop-sign shaft',
            );
          }
        }
      }
    });

    test('thumbs project to the outer sides like the visual reference', () {
      for (final swing in sampledSwings) {
        final pose = AuraCharacterRigPose.forSwing(swing);
        final geometries = [
          AuraCuppedHandGeometry.fromPose(pose.leftHand, isLeft: true),
          AuraCuppedHandGeometry.fromPose(pose.rightHand, isLeft: false),
        ];

        for (final geometry in geometries) {
          expect(geometry.thumbRoot.dx.sign, geometry.outer.sign);
          expect(geometry.thumbTip.dx.sign, geometry.outer.sign);
          expect(
            geometry.thumbTip.dx.abs(),
            greaterThan(geometry.thumbRoot.dx.abs()),
          );
        }
      }
    });

    test('hand centers follow arcs that stay inside the 1024 stage', () {
      final six = AuraCharacterRigPose.forSwing(-1);
      final neutral = AuraCharacterRigPose.forSwing(0);
      final seven = AuraCharacterRigPose.forSwing(1);

      for (final swing in sampledSwings) {
        final pose = AuraCharacterRigPose.forSwing(swing);
        for (final hand in [pose.leftHand, pose.rightHand]) {
          expect(
            hand.center.dx,
            inInclusiveRange(0, 1024),
            reason: 'hand center x left the stage at swing $swing',
          );
          expect(
            hand.center.dy,
            inInclusiveRange(0, 1024),
            reason: 'hand center y left the stage at swing $swing',
          );
        }
      }

      final leftLinearMidX =
          (six.leftHand.center.dx + seven.leftHand.center.dx) / 2;
      final leftLinearMidY =
          (six.leftHand.center.dy + seven.leftHand.center.dy) / 2;
      final rightLinearMidX =
          (six.rightHand.center.dx + seven.rightHand.center.dx) / 2;
      final rightLinearMidY =
          (six.rightHand.center.dy + seven.rightHand.center.dy) / 2;

      expect(neutral.leftHand.center.dx, lessThan(leftLinearMidX));
      expect(neutral.leftHand.center.dy, lessThan(leftLinearMidY));
      expect(neutral.rightHand.center.dx, greaterThan(rightLinearMidX));
      expect(neutral.rightHand.center.dy, lessThan(rightLinearMidY));
    });

    test('upper-arm and forearm lengths stay constant across the swing', () {
      final reference = AuraCharacterRigPose.forSwing(-1);

      for (final swing in sampledSwings) {
        final pose = AuraCharacterRigPose.forSwing(swing);
        for (final arm in [pose.leftArm, pose.rightArm]) {
          expect(arm.upperLength, reference.leftArm.upperLength);
          expect(arm.forearmLength, reference.leftArm.forearmLength);
          expect(
            (arm.elbow - arm.shoulder).distance,
            closeTo(arm.upperLength, 1e-6),
            reason: 'shoulder-elbow length changed at swing $swing',
          );
          expect(
            (arm.wrist - arm.elbow).distance,
            closeTo(arm.forearmLength, 1e-6),
            reason: 'elbow-wrist length changed at swing $swing',
          );
        }
      }
    });

    test('hand rotations remain moderate throughout the motion', () {
      const moderateRotationLimit = math.pi / 6;

      for (final swing in sampledSwings) {
        final pose = AuraCharacterRigPose.forSwing(swing);
        expect(
          pose.leftHand.angleRadians.abs(),
          lessThanOrEqualTo(moderateRotationLimit),
          reason: 'left-hand rotation is excessive at swing $swing',
        );
        expect(
          pose.rightHand.angleRadians.abs(),
          lessThanOrEqualTo(moderateRotationLimit),
          reason: 'right-hand rotation is excessive at swing $swing',
        );
      }
    });

    test('neutral pose is mirror-symmetric around the stage center', () {
      final neutral = AuraCharacterRigPose.forSwing(0);

      expect(
        neutral.leftHand.center.dx + neutral.rightHand.center.dx,
        closeTo(1024, 1e-9),
      );
      expect(
        neutral.leftHand.center.dy,
        closeTo(neutral.rightHand.center.dy, 1e-9),
      );
      expect(
        neutral.leftHand.wrist.dx + neutral.rightHand.wrist.dx,
        closeTo(1024, 1e-9),
      );
      expect(
        neutral.leftHand.wrist.dy,
        closeTo(neutral.rightHand.wrist.dy, 1e-9),
      );
      expect(
        neutral.leftHand.angleRadians,
        closeTo(-neutral.rightHand.angleRadians, 1e-9),
      );
      expect(
        neutral.leftHand.scale,
        closeTo(neutral.rightHand.scale, 1e-9),
      );
      expect(
        neutral.leftHand.projectionYScale,
        closeTo(neutral.rightHand.projectionYScale, 1e-9),
      );
      expect(
        neutral.leftHand.cupAmount,
        closeTo(neutral.rightHand.cupAmount, 1e-9),
      );

      expect(
        neutral.leftArm.shoulder.dx + neutral.rightArm.shoulder.dx,
        closeTo(1024, 1e-9),
      );
      expect(
        neutral.leftArm.shoulder.dy,
        closeTo(neutral.rightArm.shoulder.dy, 1e-9),
      );
      expect(
        neutral.leftArm.elbow.dx + neutral.rightArm.elbow.dx,
        closeTo(1024, 1e-9),
      );
      expect(
        neutral.leftArm.elbow.dy,
        closeTo(neutral.rightArm.elbow.dy, 1e-9),
      );
    });
  });

  group('AuraPoseSpring motion', () {
    test('converges equivalently after half a second at 60, 30, and 15 fps',
        () {
      final states = <int, _SpringState>{
        for (final fps in [60, 30, 15])
          fps: _runSpring(
            fps: fps,
            duration: 0.5,
            value: -1,
            velocity: 0,
            target: 1,
          ),
      };
      final reference = states[60]!;

      for (final entry in states.entries) {
        expect(
          entry.value.value,
          closeTo(1, 0.002),
          reason: 'spring did not converge at ${entry.key} fps',
        );
        expect(
          entry.value.value,
          closeTo(reference.value, 0.002),
          reason: 'spring value diverged at ${entry.key} fps',
        );
        expect(
          entry.value.velocity,
          closeTo(reference.velocity, 0.02),
          reason: 'spring velocity diverged at ${entry.key} fps',
        );
      }
    });

    test('overshoot remains below six percent of the swing range', () {
      const start = -1.0;
      const target = 1.0;
      const maximumOvershoot = (target - start) * 0.06;

      for (final fps in [60, 30, 15]) {
        var state = (value: start, velocity: 0.0);
        var highestValue = state.value;

        for (var frame = 0; frame < fps; frame++) {
          state = AuraPoseSpring.advance(
            value: state.value,
            velocity: state.velocity,
            target: target,
            dt: 1 / fps,
          );
          highestValue = math.max(highestValue, state.value);
        }

        expect(
          highestValue,
          lessThan(target + maximumOvershoot),
          reason: 'spring overshot by 6% or more at $fps fps',
        );
      }
    });

    test('mid-motion retarget preserves continuity and reaches the new target',
        () {
      final beforeRetarget = _runSpring(
        fps: 60,
        duration: 0.12,
        value: -1,
        velocity: 0,
        target: 1,
      );
      expect(beforeRetarget.velocity, greaterThan(0));

      final atRetarget = AuraPoseSpring.advance(
        value: beforeRetarget.value,
        velocity: beforeRetarget.velocity,
        target: -1,
        dt: 0,
      );
      expect(atRetarget.value, beforeRetarget.value);
      expect(atRetarget.velocity, beforeRetarget.velocity);

      final settled = _runSpring(
        fps: 60,
        duration: 0.6,
        value: atRetarget.value,
        velocity: atRetarget.velocity,
        target: -1,
      );
      expect(settled.value, closeTo(-1, 0.002));
      expect(settled.velocity, closeTo(0, 0.02));
    });
  });
}
