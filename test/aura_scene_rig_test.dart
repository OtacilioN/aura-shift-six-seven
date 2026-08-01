import 'dart:math' as math;
import 'dart:ui';

import 'package:aura_shift_six_seven/game/aura_scene.dart';
import 'package:aura_shift_six_seven/game/item_visual_effects.dart';
import 'package:flutter/services.dart';
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

Future<Set<int>> _opaqueStagePixels({
  required Iterable<String> assetPaths,
  required AuraItemSceneLayout layout,
}) async {
  const stageExtent = 1024;
  const visibleAlphaThreshold = 24;
  final result = <int>{};

  for (final assetPath in assetPaths) {
    final encoded = await rootBundle.load(assetPath);
    final codec = await instantiateImageCodec(
      encoded.buffer.asUint8List(encoded.offsetInBytes, encoded.lengthInBytes),
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final rgba = await image.toByteData(format: ImageByteFormat.rawRgba);
    if (rgba == null) {
      image.dispose();
      codec.dispose();
      fail('Could not decode alpha channel for $assetPath');
    }
    final bytes = rgba.buffer.asUint8List(
      rgba.offsetInBytes,
      rgba.lengthInBytes,
    );

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (bytes[(y * image.width + x) * 4 + 3] <= visibleAlphaThreshold) {
          continue;
        }
        final stagePoint = layout.transformStagePoint(
          Offset(
            (x + .5) * stageExtent / image.width,
            (y + .5) * stageExtent / image.height,
          ),
        );
        final stageX = stagePoint.dx.floor();
        final stageY = stagePoint.dy.floor();
        if (stageX >= 0 &&
            stageX < stageExtent &&
            stageY >= 0 &&
            stageY < stageExtent) {
          result.add(stageY * stageExtent + stageX);
        }
      }
    }

    image.dispose();
    codec.dispose();
  }

  return result;
}

Iterable<String> _animatedAppearancePaths(String snakeCaseId) sync* {
  for (final variant in const ['base', 'accent', 'glow']) {
    yield 'assets/art/skins/skin_${snakeCaseId}_$variant.webp';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuraAppearanceComposition', () {
    test('orders every appearance deterministically regardless of save order',
        () {
      final expected = <String>{
        for (final branch in const ['A', 'B', 'C'])
          for (var depth = 1; depth <= 5; depth++) 'ITEM-$branch-0$depth',
        for (var depth = 1; depth <= 3; depth++) 'ITEM-CONV-0$depth',
      };

      expect(AuraAppearanceComposition.paintOrder.toSet(), expected);
      expect(
        AuraAppearanceComposition.ordered(expected.toList().reversed),
        AuraAppearanceComposition.paintOrder,
      );
    });

    test('moves dense same-territory items into collision-safe regions', () {
      final active = AuraAppearanceComposition.paintOrder.toSet();
      final sourceBounds = <String, Rect>{
        'ITEM-A-01': const Rect.fromLTRB(334, 482, 464, 612),
        'ITEM-C-01': const Rect.fromLTRB(312, 446, 456, 628),
        'ITEM-A-02': const Rect.fromLTRB(560, 536, 788, 770),
        'ITEM-C-02': const Rect.fromLTRB(606, 616, 846, 764),
        'ITEM-B-01': const Rect.fromLTRB(596, 608, 982, 958),
        'ITEM-C-04': const Rect.fromLTRB(594, 516, 984, 938),
        'ITEM-B-05': const Rect.fromLTRB(686, 126, 1000, 768),
        'ITEM-CONV-01': const Rect.fromLTRB(72, 182, 950, 958),
        'ITEM-CONV-02': const Rect.fromLTRB(64, 252, 958, 888),
        'ITEM-CONV-03': const Rect.fromLTRB(638, 82, 1002, 940),
      };
      final placed = <String, Rect>{
        for (final entry in sourceBounds.entries)
          entry.key: AuraAppearanceComposition.layoutFor(entry.key, active)
              .transformStageRect(entry.value),
      };

      for (final pair in const [
        ('ITEM-A-01', 'ITEM-C-01'),
        ('ITEM-A-02', 'ITEM-C-02'),
        ('ITEM-B-01', 'ITEM-C-04'),
        ('ITEM-CONV-01', 'ITEM-CONV-02'),
        ('ITEM-CONV-01', 'ITEM-CONV-03'),
        ('ITEM-CONV-02', 'ITEM-CONV-03'),
        ('ITEM-CONV-03', 'ITEM-C-04'),
      ]) {
        expect(
          placed[pair.$1]!.overlaps(placed[pair.$2]!),
          isFalse,
          reason: '${pair.$1} overlaps ${pair.$2}',
        );
      }

      const stage = Rect.fromLTWH(0, 0, 1024, 1024);
      const mascotCore = Rect.fromLTRB(300, 200, 724, 960);
      // Alpha-scanned clear pocket inside ITEM-C-05's hollow scene frame.
      const frameLeftClearRegion = Rect.fromLTRB(150, 310, 290, 570);
      final statement = placed['ITEM-B-05']!;
      expect(stage.contains(statement.topLeft), isTrue);
      expect(stage.contains(statement.bottomRight), isTrue);
      expect(statement.overlaps(mascotCore), isFalse);
      expect(frameLeftClearRegion.contains(statement.topLeft), isTrue);
      expect(frameLeftClearRegion.contains(statement.bottomRight), isTrue);

      for (final id in const [
        'ITEM-CONV-01',
        'ITEM-CONV-02',
        'ITEM-CONV-03',
      ]) {
        expect(stage.contains(placed[id]!.topLeft), isTrue);
        expect(stage.contains(placed[id]!.bottomRight), isTrue);
      }
    });

    test('keeps the statement prop inside transparent scene pockets', () async {
      final active = AuraAppearanceComposition.paintOrder.toSet();
      final statement = await _opaqueStagePixels(
        assetPaths: _animatedAppearancePaths('item_b_05'),
        layout: AuraAppearanceComposition.layoutFor('ITEM-B-05', active),
      );

      for (final item in const [
        ('ITEM-C-05', 'item_c_05'),
        ('ITEM-CONV-01', 'item_conv_01'),
        ('ITEM-CONV-02', 'item_conv_02'),
        ('ITEM-CONV-03', 'item_conv_03'),
      ]) {
        final sceneProp = await _opaqueStagePixels(
          assetPaths: _animatedAppearancePaths(item.$2),
          layout: AuraAppearanceComposition.layoutFor(item.$1, active),
        );
        expect(
          statement.intersection(sceneProp),
          isEmpty,
          reason: 'ITEM-B-05 has visible pixels over ${item.$1}',
        );
      }
    });

    test('keeps authored placement when no conflicting item is active', () {
      for (final id in AuraAppearanceComposition.paintOrder) {
        expect(
          AuraAppearanceComposition.layoutFor(id, {id}),
          same(AuraItemSceneLayout.identity),
        );
      }
    });
  });

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

  group('AuraHandAccessoryPlacement', () {
    test('assigns the union and remainder ring to different fingers', () {
      expect(
        AuraHandAccessoryPlacement.unionFingerIndex,
        isNot(AuraHandAccessoryPlacement.remainderRingFingerIndex),
      );
    });

    test('keeps combined hand items separated throughout the gesture', () {
      for (final swing in sampledSwings) {
        final pose = AuraCharacterRigPose.forSwing(swing);
        final union = AuraHandAccessoryPlacement.onFinger(
          pose.rightHand,
          isLeft: false,
          fingerIndex: AuraHandAccessoryPlacement.unionFingerIndex,
        );
        final ring = AuraHandAccessoryPlacement.onFinger(
          pose.rightHand,
          isLeft: false,
          fingerIndex: AuraHandAccessoryPlacement.remainderRingFingerIndex,
        );

        expect(
          (union.center - ring.center).distance,
          greaterThan(43 + ring.fingerWidth * 0.41),
          reason: 'hand accessories overlap at swing $swing',
        );
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
