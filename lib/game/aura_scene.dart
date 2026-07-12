import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_selection.dart';
import '../audio/aura_audio_controller.dart';
import '../core/formatting.dart';
import '../core/game_controller.dart';
import 'art_catalog.dart';
import 'item_visual_effects.dart';

/// Pure, testable geometry for the on-canvas character rig.
///
/// [swing] follows the gesture as it is seen on screen: `-1` is Six (the hand
/// on the right side of the screen is high), `1` is Seven (the hand on the
/// left is high), and `0` is the neutral crossing pose. Both hands keep their
/// palm plane facing the sky throughout the interpolation.
class AuraCharacterRigPose {
  const AuraCharacterRigPose({
    required this.leftHand,
    required this.rightHand,
    required this.leftArm,
    required this.rightArm,
  });

  factory AuraCharacterRigPose.forSwing(
    double swing, {
    double rootShiftX = 0,
  }) {
    final phase = ((swing + 1) * 0.5).clamp(0.0, 1.0);
    final left = _hand(
      isLeft: true,
      lift: phase,
      rootShiftX: rootShiftX,
    );
    final right = _hand(
      isLeft: false,
      lift: 1 - phase,
      rootShiftX: rootShiftX,
    );
    final leftShoulder = Offset(390 + rootShiftX, 548);
    final rightShoulder = Offset(634 + rootShiftX, 548);
    return AuraCharacterRigPose(
      leftHand: left,
      rightHand: right,
      leftArm: _arm(leftShoulder, left.wrist, isLeft: true),
      rightArm: _arm(rightShoulder, right.wrist, isLeft: false),
    );
  }

  final AuraHandRigPose leftHand;
  final AuraHandRigPose rightHand;
  final AuraArmRigPose leftArm;
  final AuraArmRigPose rightArm;

  static AuraHandRigPose _hand({
    required bool isLeft,
    required double lift,
    required double rootShiftX,
  }) {
    final t = lift.clamp(0.0, 1.0);
    final eased = t * t * (3 - 2 * t);
    final side = isLeft ? -1.0 : 1.0;
    final lowX = isLeft ? 232.0 : 792.0;
    final highX = isLeft ? 310.0 : 714.0;
    final arc = sin(pi * eased);
    final center = Offset(
      ui.lerpDouble(lowX, highX, eased)! + side * arc * 16 + rootShiftX,
      ui.lerpDouble(604, 264, eased)! - arc * 18,
    );
    final angle = side * ui.lerpDouble(8, 21, eased)! * pi / 180;
    final scale = ui.lerpDouble(0.96, 1.055, eased)!;
    // 0 = a palm plane parallel to the sky; 1 = a palm facing the camera.
    // Keeping this projection shallow is what prevents the gesture from
    // reading as a stop sign. The raised hand opens a little toward camera,
    // but never leaves the upturned range.
    final projectionYScale = ui.lerpDouble(0.46, 0.52, eased)!;
    final cupAmount = ui.lerpDouble(0.90, 0.84, eased)!;
    final wristLocal = Offset(-side * 18 * scale, 62 * scale);
    final wrist = center +
        Offset(
          wristLocal.dx * cos(angle) - wristLocal.dy * sin(angle),
          wristLocal.dx * sin(angle) + wristLocal.dy * cos(angle),
        );
    return AuraHandRigPose(
      center: center,
      wrist: wrist,
      angleRadians: angle,
      scale: scale,
      palmUp: true,
      projectionYScale: projectionYScale,
      cupAmount: cupAmount,
    );
  }

  static AuraArmRigPose _arm(
    Offset shoulder,
    Offset wrist, {
    required bool isLeft,
  }) {
    const upperLength = 126.0;
    const forearmLength = 132.0;
    final delta = wrist - shoulder;
    final rawDistance = delta.distance;
    final distance = rawDistance.clamp(
      (upperLength - forearmLength).abs() + 0.001,
      upperLength + forearmLength - 0.001,
    );
    final direction =
        rawDistance == 0 ? const Offset(0, -1) : delta / rawDistance;
    final along = (upperLength * upperLength -
            forearmLength * forearmLength +
            distance * distance) /
        (2 * distance);
    final height = sqrt(max(0, upperLength * upperLength - along * along));
    final base = shoulder + direction * along;
    final perpendicular = Offset(-direction.dy, direction.dx);
    final candidateA = base + perpendicular * height;
    final candidateB = base - perpendicular * height;
    final elbow = isLeft
        ? (candidateA.dx < candidateB.dx ? candidateA : candidateB)
        : (candidateA.dx > candidateB.dx ? candidateA : candidateB);
    return AuraArmRigPose(
      shoulder: shoulder,
      elbow: elbow,
      wrist: wrist,
      upperLength: upperLength,
      forearmLength: forearmLength,
    );
  }
}

class AuraHandRigPose {
  const AuraHandRigPose({
    required this.center,
    required this.wrist,
    required this.angleRadians,
    required this.scale,
    required this.palmUp,
    required this.projectionYScale,
    required this.cupAmount,
  });

  final Offset center;
  final Offset wrist;
  final double angleRadians;
  final double scale;
  final bool palmUp;
  final double projectionYScale;
  final double cupAmount;
}

/// Normalized 2.5D construction shared by the painter and geometry tests.
///
/// The palm is a shallow bowl: [projectionYScale] controls its projected
/// front-to-back depth, while the four [fingers] start at the far rim and curl
/// back toward the near rim. Coordinates are normalized by the painter's hand
/// radius and use positive Y toward the wrist / viewer.
class AuraCuppedHandGeometry {
  AuraCuppedHandGeometry._({
    required this.outer,
    required this.projectionYScale,
    required this.cupAmount,
    required this.palmHalfWidth,
    required this.palmHalfDepth,
    required this.wristAnchor,
    required this.thumbRoot,
    required this.thumbTip,
    required this.fingers,
  });

  factory AuraCuppedHandGeometry.fromPose(
    AuraHandRigPose pose, {
    required bool isLeft,
  }) {
    final outer = isLeft ? -1.0 : 1.0;
    const palmHalfWidth = 1.02;
    final palmHalfDepth = palmHalfWidth * pose.projectionYScale;
    const specs = <(double, double, double, double, double)>[
      (0.50, 0.27, 0.58, 0.48, 0.10),
      (0.16, 0.38, 0.62, 0.52, 0.03),
      (-0.17, 0.37, 0.57, 0.48, -0.03),
      (-0.48, 0.30, 0.46, 0.38, -0.10),
    ];
    final fingers = specs
        .map(
          (spec) => AuraCurledFingerGeometry(
            base: Offset(outer * spec.$1, -palmHalfDepth * 0.30),
            tip: Offset(outer * spec.$1, spec.$2 * pose.cupAmount),
            width: spec.$3,
            height: spec.$4,
            angleRadians: outer * spec.$5,
          ),
        )
        .toList(growable: false);

    return AuraCuppedHandGeometry._(
      outer: outer,
      projectionYScale: pose.projectionYScale,
      cupAmount: pose.cupAmount,
      palmHalfWidth: palmHalfWidth,
      palmHalfDepth: palmHalfDepth,
      wristAnchor: Offset(-outer * 0.16, palmHalfDepth * 1.22),
      thumbRoot: Offset(outer * 0.50, palmHalfDepth * 0.20),
      thumbTip: Offset(outer * 1.10, -palmHalfDepth * 1.10),
      fingers: fingers,
    );
  }

  final double outer;
  final double projectionYScale;
  final double cupAmount;
  final double palmHalfWidth;
  final double palmHalfDepth;
  final Offset wristAnchor;
  final Offset thumbRoot;
  final Offset thumbTip;
  final List<AuraCurledFingerGeometry> fingers;

  double get projectedPalmAspect => palmHalfDepth / palmHalfWidth;
}

class AuraCurledFingerGeometry {
  const AuraCurledFingerGeometry({
    required this.base,
    required this.tip,
    required this.width,
    required this.height,
    required this.angleRadians,
  });

  final Offset base;
  final Offset tip;
  final double width;
  final double height;
  final double angleRadians;
}

class AuraArmRigPose {
  const AuraArmRigPose({
    required this.shoulder,
    required this.elbow,
    required this.wrist,
    required this.upperLength,
    required this.forearmLength,
  });

  final Offset shoulder;
  final Offset elbow;
  final Offset wrist;
  final double upperLength;
  final double forearmLength;
}

/// Placement rules shared by equipped appearance assets and their tests.
///
/// Character-worn art is authored in the neutral 1024x1024 stage. At runtime
/// it must inherit the mascot's bob, lean, and foot-pivot rotation; otherwise a
/// pair of glasses or shoes visibly slides away from the character while the
/// pose changes. Scene, ground, and aura props intentionally stay world-fixed.
abstract final class AuraAppearancePlacement {
  static const _worldSlots = <String>{
    'GROUND_BACK',
    'GROUND_PROP',
    'SCENE_FRAME',
    'AURA_BACK',
  };

  static bool followsCharacter(String? slot) =>
      slot != null && !_worldSlots.contains(slot);

  static double leanFactor(String? slot) => switch (slot) {
        'FACE_SIDE' || 'FACE_WEAR' || 'HEAD_BACK' || 'HEAD_WEAR' => 1.15,
        'SHOULDER' => 0.72,
        _ => 1.0,
      };
}

enum _AuraAppearanceLayer { behindMascot, underHands, overHands }

/// Pure retargetable spring shared by runtime motion and frame-rate tests.
///
/// Velocity is intentionally preserved when [target] changes, so a fast player
/// redirects the hands instead of restarting a tween and producing a snap.
abstract final class AuraPoseSpring {
  static const frequency = 26.0;
  static const damping = 0.86;

  static ({double value, double velocity}) advance({
    required double value,
    required double velocity,
    required double target,
    required double dt,
  }) {
    final steps = max(1, (dt * 120).ceil());
    final step = dt / steps;
    var nextValue = value;
    var nextVelocity = velocity;
    for (var i = 0; i < steps; i++) {
      final acceleration = frequency * frequency * (target - nextValue) -
          2 * damping * frequency * nextVelocity;
      nextVelocity += acceleration * step;
      nextValue += nextVelocity * step;
    }
    if ((target - nextValue).abs() < 0.0005 && nextVelocity.abs() < 0.005) {
      return (value: target, velocity: 0);
    }
    return (value: nextValue, velocity: nextVelocity);
  }
}

/// The Aura Area — "Rua Pixel" direction. A chibi street kid (67 cap, SIX
/// SEVEN tee, chunky sneakers, oversized upturned hands, blue meme tears)
/// performs the Six-Seven. The aura is made of rising PURPLE PIXELS: squares
/// that grow denser with the combo, purple lightning + a ground ring at max
/// charge, and glowing purple eyes when the kid is fully "aurado".
///
///  * **Combo / heat** — tap tempo builds [heat]: pixel density, halo size,
///    shake and rising numbers all scale with it.
///  * **Motion** — every contact retargets a continuous spring immediately;
///    visual completion never changes the canonical Aura reward.
class AuraScene extends FlameGame with TapCallbacks {
  AuraScene(this.controller, this.audio) {
    final restoredPose = controller.phase == CyclePhase.seven
        ? -1.0
        : controller.cycles > 0
            ? 1.0
            : 0.0;
    _swing = restoredPose;
    _swingTarget = restoredPose;
  }

  final GameController controller;
  final AuraAudioController audio;
  final _random = Random();
  final _inputClock = Stopwatch()..start();
  ArtCatalog? _artCatalog;
  final Map<String, ui.Image> _appearanceImages = <String, ui.Image>{};
  String? _requestedAppearanceId;
  String? _loadedAppearanceId;
  int _appearanceLoadEpoch = 0;
  bool _listeningForAppearance = false;
  bool _removed = false;

  double heat = 0; // 0..1 combo intensity
  final ValueNotifier<double> charge = ValueNotifier<double>(0);

  double pulse = 0;
  double _flash = 0;
  double _shake = 0;
  double _elapsed = 0;
  double _passiveTimer = 0;
  int _windowStart = 0;
  int _contactsInWindow = 0;

  // Retargetable pseudo-rig state. -1 = Six (screen-right hand high),
  // +1 = Seven (screen-left hand high), 0 = neutral crossing pose.
  double _swing = 0;
  double _swingTarget = 0;
  double _swingVelocity = 0;

  final List<_Particle> _pixels = <_Particle>[]; // rising aura pixels
  final List<_Particle> _groundPixels = <_Particle>[]; // hot ground burst
  final List<_Particle> _sparks = <_Particle>[]; // tap sparks
  final List<_Shockwave> _waves = <_Shockwave>[];
  final List<_Gain> _gains = <_Gain>[];

  // Combo climb and visual timing. Economy is deliberately independent of the
  // animation: a fast retarget never reduces the canonical cycle reward.
  static const _heatPerHalfTap = 0.05;
  static const _heatPerCycle = 0.11;
  static const _heatDecay = 0.32;
  // The combined peak stays within the motion-v1 budget of 80 live particles:
  // 48 ambient + 20 ground + 12 contact sparks.
  static const _maxPixels = 48;
  static const _maxGroundPixels = 20;
  static const _maxSparks = 12;

  static const _violet = Color(0xFF8B7CFF);
  static const _purple = Color(0xFFB44BFF);
  static const _purpleDeep = Color(0xFF7B3FE4);
  static const _lavender = Color(0xFFD9C8FF);
  static const _blue = Color(0xFF6FC7FF);
  static const _gold = Color(0xFFFFD166);
  static const _cyan = Color(0xFF43E6FF);
  static const _canvas = Color(0xFF090B1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _artCatalog = await ArtCatalog.load(rootBundle);
      if (_removed) return;
      controller.addListener(_appearanceMayHaveChanged);
      _listeningForAppearance = true;
      await _loadEquippedAppearance();
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'Aura Shift appearance renderer',
        context: ErrorDescription('while loading approved appearance art'),
      ));
    }
  }

  void _appearanceMayHaveChanged() {
    if (_removed || controller.equippedAppearance == _requestedAppearanceId) {
      return;
    }
    unawaited(_loadEquippedAppearance());
  }

  Future<void> _loadEquippedAppearance() async {
    final catalog = _artCatalog;
    final contentId = controller.equippedAppearance;
    _requestedAppearanceId = contentId;
    final epoch = ++_appearanceLoadEpoch;
    if (catalog == null || contentId == null) {
      _disposeAppearanceImages();
      _loadedAppearanceId = null;
      return;
    }

    final layerIds = <String>{
      ...AuraArtSelection.skinLayerIds(
        contentId,
        level: 25,
        reduceMotion: false,
      ),
      ...AuraArtSelection.skinLayerIds(
        contentId,
        level: 25,
        reduceMotion: true,
      ),
    };
    final decoded = <String, ui.Image>{};
    try {
      for (final id in layerIds) {
        final record = catalog[id];
        if (record == null) continue;
        final bytes = await rootBundle.load(record.runtimePath);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        try {
          decoded[id] = (await codec.getNextFrame()).image;
        } finally {
          codec.dispose();
        }
      }
    } catch (error, stack) {
      for (final image in decoded.values) {
        image.dispose();
      }
      if (!_removed && epoch == _appearanceLoadEpoch) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'Aura Shift appearance renderer',
          context: ErrorDescription(
            'while decoding appearance art for $contentId',
          ),
        ));
      }
      return;
    }

    if (_removed ||
        epoch != _appearanceLoadEpoch ||
        controller.equippedAppearance != contentId) {
      for (final image in decoded.values) {
        image.dispose();
      }
      return;
    }
    _disposeAppearanceImages();
    _appearanceImages.addAll(decoded);
    _loadedAppearanceId = contentId;
  }

  void _disposeAppearanceImages() {
    for (final image in _appearanceImages.values) {
      image.dispose();
    }
    _appearanceImages.clear();
  }

  @override
  Color backgroundColor() => _canvas;

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------
  @override
  void onTapDown(TapDownEvent event) => activateCycle();

  void activateCycle() {
    final now = _inputClock.elapsedMilliseconds;
    if (now - _windowStart >= 1000) {
      _windowStart = now;
      _contactsInWindow = 0;
    }
    if (_contactsInWindow >= 20) return;
    _contactsInWindow++;

    final phaseBefore = controller.phase;
    final completesCycle = phaseBefore == CyclePhase.seven;
    final reduce = controller.reduceMotion;
    final totalBefore = controller.total;

    // The phase being performed owns the visual target. `controller.phase`
    // changes immediately to the next expected input, so deriving the pose
    // after `tap()` would visually swap Six and Seven.
    _swingTarget = phaseBefore == CyclePhase.six ? -1.0 : 1.0;
    controller.tap();
    audio.recordCycle(
      phaseBefore == CyclePhase.six ? CycleFamily.six : CycleFamily.seven,
    );

    if (reduce) {
      _swing = _swingTarget;
      _swingVelocity = 0;
      charge.value = _energy;
      return;
    }

    pulse = 0.9 + _random.nextDouble() * 0.1;
    heat = min(1, heat + (completesCycle ? _heatPerCycle : _heatPerHalfTap));

    _emitSparks(
      completesCycle ? 12 : 5,
      completesCycle ? 1 : 0.72,
      phaseBefore,
    );

    if (completesCycle) {
      _flash = min(1, _flash + 0.25 + heat * 0.35);
      _shake = min(24, _shake + 4 + heat * 12);
      _waves.add(
          _Shockwave(center: const Offset(512, 540), max: 0.3 + heat * 0.55));
      final delta = controller.total - totalBefore;
      if (delta > BigInt.zero) _spawnGain(delta);
    }
  }

  // ---------------------------------------------------------------------------
  // Simulation
  // ---------------------------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt);
    dt = min(dt, 0.05);

    if (controller.reduceMotion) {
      heat = pulse = _flash = _shake = 0;
      _swing = _swingTarget;
      _swingVelocity = 0;
      _pixels.clear();
      _groundPixels.clear();
      _sparks.clear();
      _waves.clear();
      _gains.clear();
      charge.value = _energy;
      return;
    }

    _elapsed += dt;
    _advanceSwing(dt);
    pulse = max(0, pulse - dt * 2.4);
    heat = max(0, heat - dt * _heatDecay);
    _flash = max(0, _flash - dt * 2.6);
    _shake = max(0, _shake - dt * 44);

    // Passive income rises as small numbers from the aura, once per second.
    _passiveTimer += dt;
    if (_passiveTimer >= 1.0) {
      _passiveTimer -= 1.0;
      final perSec = controller.passiveNumerator *
          BigInt.from(5000) ~/
          BigInt.from(10000000);
      if (perSec > BigInt.zero) _spawnGain(perSec, passive: true);
    }

    _spawnAmbient(dt);
    _advance(_pixels, dt);
    _advance(_groundPixels, dt);
    _advance(_sparks, dt);
    for (final g in _gains) {
      g.life -= dt;
      g.pos += g.vel * dt;
    }
    _gains.removeWhere((g) => g.life <= 0);
    for (final w in _waves) {
      w.t += dt * 1.8;
    }
    _waves.removeWhere((w) => w.t >= 1);
    charge.value = _energy;
  }

  void _advanceSwing(double dt) {
    final next = AuraPoseSpring.advance(
      value: _swing,
      velocity: _swingVelocity,
      target: _swingTarget,
      dt: dt,
    );
    _swing = next.value;
    _swingVelocity = next.velocity;
  }

  void _advance(List<_Particle> list, double dt) {
    for (final p in list) {
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel += p.accel * dt;
    }
    list.removeWhere((p) => p.life <= 0);
  }

  void _spawnAmbient(double dt) {
    // Rising purple pixels — density scales with the combo.
    final pixelRate = (7 + heat * 70) * dt;
    _spawnPoisson(pixelRate, () {
      if (_pixels.length >= _maxPixels) return;
      final x = 512 + (_random.nextDouble() - 0.5) * (320 + heat * 280);
      final y = 520 + _random.nextDouble() * 340;
      final roll = _random.nextDouble();
      final color = roll < 0.12
          ? _blue
          : Color.lerp(
              Color.lerp(_violet, _purple, heat)!, _lavender, roll * 0.6)!;
      _pixels.add(_Particle(
        pos: Offset(x, y),
        vel: Offset((_random.nextDouble() - 0.5) * 40,
            -70 - _random.nextDouble() * 130 - heat * 190),
        accel: const Offset(0, -26),
        life: 1.1 + _random.nextDouble() * 1.0,
        size: 8 + _random.nextDouble() * 14 + heat * 12,
        color: color,
        hollow: _random.nextDouble() < 0.2,
      ));
    });

    // Hot: extra pixels bursting up from the ground ring.
    if (heat > 0.4) {
      final groundRate = (heat - 0.4) * 115 * dt;
      _spawnPoisson(groundRate, () {
        if (_groundPixels.length >= _maxGroundPixels) return;
        final x = 512 + (_random.nextDouble() - 0.5) * 600;
        final y = 940 - _random.nextDouble() * 150;
        _groundPixels.add(_Particle(
          pos: Offset(x, y),
          vel: Offset((_random.nextDouble() - 0.5) * 60,
              -170 - _random.nextDouble() * 250),
          accel: const Offset(0, -40),
          life: 0.8 + _random.nextDouble() * 0.9,
          size: 7 + _random.nextDouble() * 12,
          color: Color.lerp(_purple, _lavender, _random.nextDouble())!,
          hollow: _random.nextDouble() < 0.15,
        ));
      });
    }
  }

  void _spawnPoisson(double expected, VoidCallback spawn) {
    var n = expected.floor();
    if (_random.nextDouble() < expected - n) n++;
    for (var i = 0; i < n; i++) {
      spawn();
    }
  }

  void _emitSparks(int count, double strength, CyclePhase performedPhase) {
    // Start from the hand's CURRENT position. This stays attached when a new
    // touch retargets the rig before the previous movement has settled.
    final rig = AuraCharacterRigPose.forSwing(_swing);
    final from = performedPhase == CyclePhase.six
        ? rig.rightHand.center
        : rig.leftHand.center;
    for (var i = 0; i < count; i++) {
      final a = _random.nextDouble() * pi * 2;
      final speed = (120 + _random.nextDouble() * 240) * (0.5 + 0.5 * strength);
      _sparks.add(_Particle(
        pos: from,
        vel: Offset(cos(a), sin(a) - 0.4) * speed,
        accel: const Offset(0, 240),
        life: 0.35 + _random.nextDouble() * 0.4,
        size: 5 + _random.nextDouble() * 6,
        color: Color.lerp(Colors.white, _purple, 0.4)!,
      ));
    }
    if (_sparks.length > _maxSparks) {
      _sparks.removeRange(0, _sparks.length - _maxSparks);
    }
  }

  void _spawnGain(BigInt delta, {bool passive = false}) {
    if (_gains.length > 18) _gains.removeAt(0);
    final side = _random.nextBool() ? 1.0 : -1.0;
    final radius = 280 + _random.nextDouble() * (110 + heat * 110);
    _gains.add(_Gain(
      text: '+${AuraFormat.integer(delta, locale: controller.locale)}',
      pos:
          Offset(512 + side * radius, 460 + (_random.nextDouble() - 0.5) * 180),
      vel: Offset(side * 26, -90 - (passive ? 0 : 30)),
      life: passive ? 1.0 : 1.4,
      passive: passive,
    ));
  }

  // ---------------------------------------------------------------------------
  // Derived signals
  // ---------------------------------------------------------------------------
  /// Aura hue — purple per the "Rua Pixel" art direction, brightening toward
  /// magenta-purple as the combo builds. (Appearance skins may re-tint later.)
  Color _auraGlow(double t) => Color.lerp(_violet, _purple, t)!;

  int get _formTier {
    var tier = 0;
    for (final f in const [
      'FORM-01',
      'FORM-02',
      'FORM-03',
      'FORM-04',
      'FORM-05'
    ]) {
      if (controller.transformations.contains(f)) tier++;
    }
    return tier;
  }

  double get _energy {
    final floor = _formTier / 5 * 0.3;
    return (floor + heat * (1 - floor)).clamp(0.0, 1.0);
  }

  double get _characterBob =>
      controller.reduceMotion ? 0.0 : sin(_elapsed * 2.0) * 6;

  double get _characterFollowThrough =>
      (_swingVelocity / AuraPoseSpring.frequency).clamp(-0.16, 0.16).toDouble();

  double get _characterLean => _swing * 4 + _characterFollowThrough * 12;

  double get _characterTiltDegrees => controller.reduceMotion
      ? 0.0
      : -_swing * 1.25 - _characterFollowThrough * 4;

  // ---------------------------------------------------------------------------
  // Rendering
  // ---------------------------------------------------------------------------
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;
    final scene = Rect.fromLTWH(0, 0, size.x, size.y);
    final stage = _stageRect(scene);
    final e = _energy;

    canvas.save();
    if (_shake > 0.1) {
      canvas.translate((_random.nextDouble() - 0.5) * _shake,
          (_random.nextDouble() - 0.5) * _shake);
    }

    _drawBackground(canvas, scene, e);
    _drawGroundGlow(canvas, stage, e);
    _drawCharacterHalo(canvas, stage, e);
    _drawEquippedAppearance(
      canvas,
      stage,
      layer: _AuraAppearanceLayer.behindMascot,
    );
    _drawEquippedItemEffect(canvas, stage, behindMascot: true);
    _drawParticles(canvas, stage, _pixels);
    _drawAuraBolts(canvas, stage, e);
    _drawCharacter(
      canvas,
      stage,
      e,
      beforeHands: () => _drawEquippedAppearance(
        canvas,
        stage,
        layer: _AuraAppearanceLayer.underHands,
        characterTransformAlreadyApplied: true,
      ),
    );
    _drawEquippedAppearance(
      canvas,
      stage,
      layer: _AuraAppearanceLayer.overHands,
    );
    _drawEquippedItemEffect(canvas, stage, behindMascot: false);
    _drawParticles(canvas, stage, _sparks);
    _drawParticles(canvas, stage, _groundPixels);
    _drawShockwaves(canvas, stage);
    _drawGains(canvas, stage);

    canvas.restore();

    _drawHeatOverlay(canvas, scene, e);
    if (_flash > 0.01) {
      canvas.drawRect(
        scene,
        Paint()
          ..color = Color.lerp(_purple, Colors.white, 0.6)!
              .withValues(alpha: _flash * 0.42)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  Rect _stageRect(Rect scene) {
    final side = min(scene.width * 0.9, scene.height * 0.92);
    final groundY = scene.top + scene.height * 0.9;
    final top = groundY - side;
    return Rect.fromLTWH(scene.center.dx - side / 2, top, side, side);
  }

  Offset _p(Rect stage, double lx, double ly) => Offset(
        stage.left + lx / 1024 * stage.width,
        stage.top + ly / 1024 * stage.height,
      );

  double _s(Rect stage, double logical) => logical / 1024 * stage.width;

  void _drawText(Canvas canvas, String text, Offset center, double size,
      {Color color = Colors.white,
      FontWeight weight = FontWeight.w800,
      double letterSpacing = 0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'MPlusRounded',
          fontWeight: weight,
          fontSize: size,
          letterSpacing: letterSpacing,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawBackground(Canvas canvas, Rect scene, double e) {
    final top = Color.lerp(_canvas, const Color(0xFF150E24), e * 0.8)!;
    final bottom =
        Color.lerp(const Color(0xFF241A4A), const Color(0xFF5B2AA8), e * 0.6)!;
    canvas.drawRect(
      scene,
      Paint()
        ..shader = ui.Gradient.linear(
            scene.topCenter, scene.bottomCenter, [top, bottom], [0.0, 1.0]),
    );
    final center = Offset(scene.center.dx, scene.top + scene.height * 0.46);
    final radius = scene.height * (0.3 + e * 0.55);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(center, radius, [
          _auraGlow(e).withValues(alpha: 0.22 + e * 0.32),
          Colors.transparent,
        ]),
    );
    final speckPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (var i = 0; i < 26; i++) {
      final seed = i * 12.9898;
      final fx = _frac(sin(seed) * 43758.5453);
      final speed = 0.02 + _frac(seed * 1.7) * 0.05;
      final fy = _frac(1 - (_elapsed * speed + _frac(seed * 2.3)));
      final r = 0.6 + _frac(seed * 3.1) * 1.8;
      canvas.drawCircle(
          Offset(scene.left + fx * scene.width, scene.top + fy * scene.height),
          r,
          speckPaint);
    }
  }

  void _drawGroundGlow(Canvas canvas, Rect stage, double e) {
    final center = _p(stage, 512, 905);
    final w = _s(stage, 620 + e * 320);
    canvas.drawOval(
      Rect.fromCenter(
          center: center, width: w, height: _s(stage, 150 + e * 100)),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(center, w / 2, [
          _auraGlow(e).withValues(alpha: 0.34 + e * 0.42),
          Colors.transparent,
        ]),
    );
    // Charged ground rings (the "Rua Pixel" max-aura floor circle).
    if (e > 0.3) {
      final ringAlpha = ((e - 0.3) / 0.7).clamp(0.0, 1.0);
      for (final (scaleW, scaleH, alpha) in const [
        (1.0, 1.0, 0.8),
        (0.68, 0.62, 0.5),
      ]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: _s(stage, (330 + e * 260)) * scaleW,
            height: _s(stage, (92 + e * 60)) * scaleH,
          ),
          Paint()
            ..blendMode = BlendMode.plus
            ..style = PaintingStyle.stroke
            ..strokeWidth = _s(stage, 9)
            ..color = Color.lerp(_purple, _lavender, 0.3)!
                .withValues(alpha: ringAlpha * alpha),
        );
      }
    }
    canvas.drawOval(
      Rect.fromCenter(
          center: center, width: _s(stage, 320), height: _s(stage, 70)),
      Paint()..color = _canvas.withValues(alpha: 0.5),
    );
  }

  // The "super aura" halo hugging the kid — grows with the combo.
  void _drawCharacterHalo(Canvas canvas, Rect stage, double e) {
    final center = _p(stage, 512, 520);
    final radius = _s(stage, 200 + e * 300);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(center, radius, [
          _auraGlow(e).withValues(alpha: 0.18 + e * 0.5),
          Colors.transparent,
        ], [
          0.2,
          1.0
        ]),
    );
  }

  // Purple lightning arcing around the aura at high charge.
  void _drawAuraBolts(Canvas canvas, Rect stage, double e) {
    if (e < 0.5) return;
    final intensity = (e - 0.5) / 0.5;
    final center = _p(stage, 512, 530);
    final baseR = _s(stage, 250 + e * 150);
    final bolt = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _s(stage, 6)
      ..color = Color.lerp(_lavender, _purple, 0.4)!
          .withValues(alpha: intensity * 0.85)
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, _s(stage, 2.5));
    final bolts = 2 + (intensity * 4).round();
    final tick = (_elapsed * 10).floor();
    for (var b = 0; b < bolts; b++) {
      double sample(int channel) => _frac(
            sin((tick * 97.0 + b * 31.0 + channel * 17.0) * 12.9898) *
                43758.5453,
          );

      var a = sample(0) * pi * 2;
      var p = center + Offset(cos(a), sin(a) * 0.8) * baseR;
      final path = Path()..moveTo(p.dx, p.dy);
      final segs = 2 + (sample(1) * 2).floor();
      for (var s = 0; s < segs; s++) {
        a += (sample(2 + s * 2) - 0.5) * 1.3;
        final len = _s(stage, 26 + sample(3 + s * 2) * 38);
        p = p + Offset(cos(a), sin(a) - 0.4) * len;
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, bolt);
    }
  }

  // Character — "Rua Pixel" kid --------------------------------------------
  void _drawCharacter(
    Canvas canvas,
    Rect stage,
    double e, {
    VoidCallback? beforeHands,
  }) {
    final bob = _characterBob;
    final lean = _characterLean;
    final hot = e > 0.5;

    const outline = Color(0xFF0C0A12);
    const capColor = Color(0xFF191420);
    const capLight = Color(0xFF342A40);
    const hair = Color(0xFF1B1426);
    const hairLight = Color(0xFF352345);
    const tee = Color(0xFF17131E);
    const teeLight = Color(0xFF2A2236);
    const skin = Color(0xFFD89B63);
    const skinLight = Color(0xFFF3C39B);
    const blush = Color(0xFFE9887D);
    const sole = Color(0xFFECEAF2);
    final handBase = Color.lerp(skin, const Color(0xFFA962C4), e * 0.18)!;
    final handLight = Color.lerp(skinLight, const Color(0xFFE5CCFF), e * 0.14)!;

    final cx = 512 + lean;
    final headC = Offset(512 + lean * 1.15, 360);
    const headR = 148.0;
    final rig = AuraCharacterRigPose.forSwing(_swing, rootShiftX: lean * 0.35);

    Paint fill(Color c) => Paint()..color = c;
    Paint stroke(Color c, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _s(stage, w)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = c;

    canvas.save();
    canvas.translate(0, _s(stage, bob));
    if (!controller.reduceMotion) {
      final pivot = _p(stage, 512, 820);
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(_characterTiltDegrees * pi / 180);
      canvas.translate(-pivot.dx, -pivot.dy);
    }

    // --- Sneakers + socks ---------------------------------------------------
    for (final side in const [-1.0, 1.0]) {
      final fx = cx + side * 74;
      const fy = 848.0;
      final sock = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: _p(stage, fx, fy - 64),
          width: _s(stage, 48),
          height: _s(stage, 58),
        ),
        Radius.circular(_s(stage, 14)),
      );
      canvas.drawRRect(sock, fill(sole));
      canvas.drawRRect(sock, stroke(outline, 5));

      final upper = RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: _p(stage, fx + side * 7, fy - 10),
          width: _s(stage, 142),
          height: _s(stage, 92),
        ),
        topLeft: Radius.circular(_s(stage, side < 0 ? 46 : 26)),
        topRight: Radius.circular(_s(stage, side > 0 ? 46 : 26)),
        bottomLeft: Radius.circular(_s(stage, 24)),
        bottomRight: Radius.circular(_s(stage, 24)),
      );
      canvas.drawRRect(upper, fill(tee));
      canvas.drawRRect(upper, stroke(outline, 7));

      final toe = Rect.fromCenter(
        center: _p(stage, fx + side * 34, fy - 2),
        width: _s(stage, 64),
        height: _s(stage, 56),
      );
      canvas.drawOval(toe, fill(sole));
      canvas.drawArc(toe, -pi * 0.1, pi * 1.2, false, stroke(outline, 4));

      final tongue = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: _p(stage, fx - side * 16, fy - 29),
          width: _s(stage, 42),
          height: _s(stage, 58),
        ),
        Radius.circular(_s(stage, 12)),
      );
      canvas.drawRRect(tongue, fill(_purpleDeep));
      canvas.drawRRect(tongue, stroke(outline, 4));
      _drawText(
        canvas,
        '67',
        _p(stage, fx - side * 16, fy - 33),
        _s(stage, 18),
      );

      for (var lace = 0; lace < 3; lace++) {
        final y = fy - 27 + lace * 13;
        canvas.drawLine(
          _p(stage, fx - side * 36, y),
          _p(stage, fx + side * 11, y + 2),
          stroke(sole, 5),
        );
      }

      final band = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: _p(stage, fx + side * 5, fy + 7),
          width: _s(stage, 126),
          height: _s(stage, 23),
        ),
        Radius.circular(_s(stage, 10)),
      );
      canvas.drawRRect(band, fill(_purpleDeep));

      final soleR = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: _p(stage, fx + side * 7, fy + 33),
          width: _s(stage, 160),
          height: _s(stage, 43),
        ),
        Radius.circular(_s(stage, 18)),
      );
      canvas.drawRRect(soleR, fill(sole));
      canvas.drawRRect(soleR, stroke(outline, 7));
      canvas.drawLine(
        _p(stage, fx - 58, fy + 35),
        _p(stage, fx + 58, fy + 35),
        stroke(const Color(0xFFB9B6C8), 3),
      );
    }

    // --- Shorts -------------------------------------------------------------
    final shorts = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: _p(stage, cx, 742),
        width: _s(stage, 270),
        height: _s(stage, 132),
      ),
      Radius.circular(_s(stage, 42)),
    );
    canvas.drawRRect(shorts, fill(tee));
    canvas.drawRRect(shorts, stroke(outline, 7));
    canvas.drawLine(_p(stage, cx, 700), _p(stage, cx, 799), stroke(outline, 5));
    canvas.drawLine(
      _p(stage, cx - 94, 707),
      _p(stage, cx + 94, 707),
      stroke(teeLight, 7),
    );

    void drawArm(AuraArmRigPose arm) {
      final shoulder = _p(stage, arm.shoulder.dx, arm.shoulder.dy);
      final elbow = _p(stage, arm.elbow.dx, arm.elbow.dy);
      final wrist = _p(stage, arm.wrist.dx, arm.wrist.dy);
      final wristDirection = wrist - elbow;
      final hiddenWrist = wristDirection.distance == 0
          ? wrist
          : wrist - wristDirection / wristDirection.distance * _s(stage, 18);
      canvas.drawLine(shoulder, elbow, stroke(outline, 82));
      canvas.drawLine(shoulder, elbow, stroke(tee, 68));
      canvas.drawLine(elbow, hiddenWrist, stroke(outline, 56));
      canvas.drawLine(elbow, hiddenWrist, stroke(handBase, 43));
      final forearm = hiddenWrist - elbow;
      final highlightStart = elbow + forearm * 0.12;
      final highlightEnd = elbow + forearm * 0.68;
      canvas.drawLine(
        highlightStart.translate(-_s(stage, 3), -_s(stage, 3)),
        highlightEnd.translate(-_s(stage, 3), -_s(stage, 3)),
        stroke(handLight.withValues(alpha: 0.52), 8),
      );
    }

    // A stable z-order removes the pop that used to happen at the crossing.
    // Both articulated arms live behind the torso; both palms are drawn last.
    drawArm(rig.leftArm);
    drawArm(rig.rightArm);

    // --- Torso (tee) --------------------------------------------------------
    final torsoRect = Rect.fromCenter(
      center: _p(stage, cx, 622),
      width: _s(stage, 306),
      height: _s(stage, 218),
    );
    final torso = RRect.fromRectAndCorners(
      torsoRect,
      topLeft: Radius.circular(_s(stage, 92)),
      topRight: Radius.circular(_s(stage, 92)),
      bottomLeft: Radius.circular(_s(stage, 52)),
      bottomRight: Radius.circular(_s(stage, 52)),
    );
    canvas.drawRRect(
      torso,
      Paint()
        ..shader = ui.Gradient.linear(
          _p(stage, cx - 36, 515),
          _p(stage, cx + 28, 730),
          [teeLight, tee],
        ),
    );
    canvas.drawRRect(torso, stroke(outline, 8));
    canvas.drawArc(
      Rect.fromCenter(
        center: _p(stage, cx, 548),
        width: _s(stage, 92),
        height: _s(stage, 44),
      ),
      0,
      pi,
      false,
      stroke(outline, 5),
    );
    _drawText(
      canvas,
      'SIX',
      _p(stage, cx, 597),
      _s(stage, 46),
      letterSpacing: _s(stage, 2),
    );
    _drawText(
      canvas,
      'SEVEN',
      _p(stage, cx, 650),
      _s(stage, 44),
      letterSpacing: _s(stage, 1),
    );

    // --- Head, hair and ears -----------------------------------------------
    final hc = _p(stage, headC.dx, headC.dy);
    final hr = _s(stage, headR);
    for (final d in const [-1.0, 1.0]) {
      final ec = hc.translate(d * hr * 0.96, hr * 0.10);
      canvas.drawCircle(ec, hr * 0.18, fill(skin));
      canvas.drawCircle(ec, hr * 0.18, stroke(outline, 7));
      canvas.drawArc(
        Rect.fromCircle(center: ec, radius: hr * 0.095),
        d < 0 ? -pi * 0.7 : pi * 0.2,
        pi * 0.95,
        false,
        stroke(const Color(0xFFA96548), 4),
      );
    }

    final hairBack = Path()
      ..moveTo(hc.dx - hr * 0.96, hc.dy - hr * 0.28)
      ..cubicTo(
        hc.dx - hr * 1.06,
        hc.dy + hr * 0.12,
        hc.dx - hr * 0.72,
        hc.dy + hr * 0.48,
        hc.dx - hr * 0.46,
        hc.dy + hr * 0.28,
      )
      ..cubicTo(
        hc.dx - hr * 0.16,
        hc.dy + hr * 0.53,
        hc.dx + hr * 0.20,
        hc.dy + hr * 0.46,
        hc.dx + hr * 0.45,
        hc.dy + hr * 0.27,
      )
      ..cubicTo(
        hc.dx + hr * 0.76,
        hc.dy + hr * 0.47,
        hc.dx + hr * 1.06,
        hc.dy + hr * 0.12,
        hc.dx + hr * 0.94,
        hc.dy - hr * 0.28,
      )
      ..close();
    canvas.drawPath(
      hairBack,
      Paint()
        ..shader = ui.Gradient.linear(
          hc.translate(-hr * 0.45, -hr * 0.30),
          hc.translate(hr * 0.62, hr * 0.35),
          [hairLight, hair],
        ),
    );
    canvas.drawPath(hairBack, stroke(outline, 7));

    final headPath = Path()
      ..moveTo(hc.dx, hc.dy - hr)
      ..cubicTo(
        hc.dx + hr * 0.78,
        hc.dy - hr,
        hc.dx + hr * 1.02,
        hc.dy - hr * 0.38,
        hc.dx + hr * 0.98,
        hc.dy + hr * 0.16,
      )
      ..cubicTo(
        hc.dx + hr * 0.94,
        hc.dy + hr * 0.72,
        hc.dx + hr * 0.48,
        hc.dy + hr * 0.96,
        hc.dx,
        hc.dy + hr * 0.94,
      )
      ..cubicTo(
        hc.dx - hr * 0.48,
        hc.dy + hr * 0.96,
        hc.dx - hr * 0.94,
        hc.dy + hr * 0.72,
        hc.dx - hr * 0.98,
        hc.dy + hr * 0.16,
      )
      ..cubicTo(
        hc.dx - hr * 1.02,
        hc.dy - hr * 0.38,
        hc.dx - hr * 0.78,
        hc.dy - hr,
        hc.dx,
        hc.dy - hr,
      )
      ..close();
    canvas.drawPath(
      headPath,
      Paint()
        ..shader = ui.Gradient.radial(
          hc.translate(-hr * 0.30, -hr * 0.34),
          hr * 1.55,
          [skinLight, skin],
        ),
    );
    canvas.drawPath(headPath, stroke(outline, 8));

    // A layered fringe reads more naturally than the previous side circles.
    for (final (dx, width, drop, tilt) in const [
      (-0.62, 0.38, 0.31, -0.13),
      (-0.30, 0.42, 0.37, -0.06),
      (0.02, 0.44, 0.40, 0.02),
      (0.34, 0.40, 0.34, 0.08),
      (0.64, 0.32, 0.27, 0.14),
    ]) {
      final tuft = Path()
        ..moveTo(hc.dx + hr * (dx - width * 0.52), hc.dy - hr * 0.56)
        ..quadraticBezierTo(
          hc.dx + hr * (dx + tilt),
          hc.dy - hr * 0.18,
          hc.dx + hr * dx,
          hc.dy - hr * (0.56 - drop),
        )
        ..quadraticBezierTo(
          hc.dx + hr * (dx + width * 0.5),
          hc.dy - hr * 0.34,
          hc.dx + hr * (dx + width * 0.48),
          hc.dy - hr * 0.61,
        )
        ..close();
      canvas.drawPath(tuft, fill(hair));
      canvas.drawPath(tuft, stroke(outline, 4));
    }

    // --- Cap ----------------------------------------------------------------
    final domeRect = Rect.fromCenter(
      center: hc.translate(-hr * 0.08, -hr * 0.52),
      width: hr * 2.12,
      height: hr * 1.30,
    );
    final dome = Path()
      ..moveTo(domeRect.left, domeRect.center.dy)
      ..arcTo(domeRect, pi, pi, false)
      ..quadraticBezierTo(
        domeRect.center.dx,
        domeRect.bottom + hr * 0.08,
        domeRect.right,
        domeRect.center.dy,
      )
      ..close();
    canvas.drawPath(
      dome,
      Paint()
        ..shader = ui.Gradient.linear(
          domeRect.topLeft,
          domeRect.bottomRight,
          [capLight, capColor],
        ),
    );
    canvas.drawPath(dome, stroke(outline, 8));
    canvas.drawLine(
      hc.translate(-hr * 0.08, -hr * 1.08),
      hc.translate(-hr * 0.08, -hr * 0.38),
      stroke(outline.withValues(alpha: 0.52), 3),
    );

    final brim = Path()
      ..moveTo(hc.dx - hr * 0.78, hc.dy - hr * 0.39)
      ..cubicTo(
        hc.dx - hr * 0.12,
        hc.dy - hr * 0.54,
        hc.dx + hr * 0.90,
        hc.dy - hr * 0.43,
        hc.dx + hr * 1.25,
        hc.dy - hr * 0.16,
      )
      ..cubicTo(
        hc.dx + hr * 0.66,
        hc.dy - hr * 0.06,
        hc.dx - hr * 0.22,
        hc.dy - hr * 0.12,
        hc.dx - hr * 0.84,
        hc.dy - hr * 0.26,
      )
      ..close();
    canvas.drawPath(brim, fill(capColor));
    canvas.drawPath(brim, stroke(outline, 7));
    canvas.drawPath(
      Path()
        ..moveTo(hc.dx - hr * 0.62, hc.dy - hr * 0.30)
        ..quadraticBezierTo(
          hc.dx + hr * 0.32,
          hc.dy - hr * 0.19,
          hc.dx + hr * 1.05,
          hc.dy - hr * 0.20,
        ),
      stroke(capLight, 4),
    );
    canvas.drawCircle(
      hc.translate(-hr * 0.08, -hr * 1.15),
      hr * 0.085,
      fill(capLight),
    );
    canvas.drawCircle(
      hc.translate(-hr * 0.08, -hr * 1.15),
      hr * 0.085,
      stroke(outline, 4),
    );
    _drawText(canvas, '67', hc.translate(-hr * 0.08, -hr * 0.72), hr * 0.42);

    // --- Face ---------------------------------------------------------------
    final eyeY = hc.dy + hr * 0.10;
    final eyeDx = hr * 0.40;
    final brow = stroke(outline, 8);
    for (final d in const [-1.0, 1.0]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(hc.dx + d * eyeDx, eyeY - hr * 0.19),
          width: hr * 0.34,
          height: hr * 0.18,
        ),
        d < 0 ? pi * 1.06 : pi * 0.94,
        d < 0 ? pi * 0.62 : -pi * 0.62,
        false,
        brow,
      );
    }
    if (hot) {
      for (final d in const [-1.0, 1.0]) {
        final eye = Offset(hc.dx + d * eyeDx, eyeY);
        canvas.drawOval(
          Rect.fromCenter(center: eye, width: hr * 0.34, height: hr * 0.27),
          Paint()
            ..blendMode = BlendMode.plus
            ..shader = ui.Gradient.radial(
              eye,
              hr * 0.26,
              [Colors.white, _purple, _purple.withValues(alpha: 0)],
              [0, 0.48, 1],
            ),
        );
        canvas.drawArc(
          Rect.fromCenter(center: eye, width: hr * 0.38, height: hr * 0.30),
          pi * 0.04,
          pi * 0.92,
          false,
          stroke(outline, 5),
        );
      }
    } else {
      final eyeInk = stroke(outline, 11);
      for (final d in const [-1.0, 1.0]) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(hc.dx + d * eyeDx, eyeY + hr * 0.05),
            width: hr * 0.36,
            height: hr * 0.30,
          ),
          pi,
          pi,
          false,
          eyeInk,
        );
      }
    }

    for (final d in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(hc.dx + d * hr * 0.62, hc.dy + hr * 0.39),
          width: hr * 0.28,
          height: hr * 0.12,
        ),
        fill(blush.withValues(alpha: 0.42)),
      );
    }
    final tear = Path()
      ..moveTo(hc.dx - hr * 0.66, hc.dy + hr * 0.23)
      ..quadraticBezierTo(
        hc.dx - hr * 0.82,
        hc.dy + hr * 0.36,
        hc.dx - hr * 0.63,
        hc.dy + hr * 0.40,
      )
      ..quadraticBezierTo(
        hc.dx - hr * 0.48,
        hc.dy + hr * 0.34,
        hc.dx - hr * 0.66,
        hc.dy + hr * 0.23,
      )
      ..close();
    canvas.drawPath(
      tear,
      Paint()
        ..shader = ui.Gradient.linear(
          hc.translate(-hr * 0.80, hr * 0.25),
          hc.translate(-hr * 0.48, hr * 0.40),
          [_blue, _cyan],
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: hc.translate(hr * 0.01, hr * 0.27),
        width: hr * 0.08,
        height: hr * 0.045,
      ),
      fill(const Color(0xFF9A5D42)),
    );

    final mouthC = Offset(hc.dx, hc.dy + hr * (hot ? 0.55 : 0.52));
    final mouthW = hr * (hot ? 0.52 : 0.46);
    final mouthH = hr * (hot ? 0.40 : 0.34);
    final mouth = Path()
      ..moveTo(mouthC.dx - mouthW * 0.5, mouthC.dy - mouthH * 0.18)
      ..quadraticBezierTo(
        mouthC.dx,
        mouthC.dy + mouthH * 0.70,
        mouthC.dx + mouthW * 0.5,
        mouthC.dy - mouthH * 0.18,
      )
      ..quadraticBezierTo(
        mouthC.dx,
        mouthC.dy + mouthH * 0.02,
        mouthC.dx - mouthW * 0.5,
        mouthC.dy - mouthH * 0.18,
      )
      ..close();
    canvas.drawPath(mouth, fill(const Color(0xFF4A1E1B)));
    canvas.drawPath(mouth, stroke(outline, 5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: mouthC.translate(0, -mouthH * 0.08),
          width: mouthW * 0.72,
          height: hr * 0.08,
        ),
        Radius.circular(hr * 0.03),
      ),
      fill(Colors.white),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: mouthC.translate(0, mouthH * 0.28),
        width: mouthW * 0.46,
        height: mouthH * 0.28,
      ),
      pi,
      pi,
      true,
      fill(const Color(0xFFE76F83)),
    );

    // Worn face/body/head/ankle art belongs to the character but stays below
    // the articulated palms. Hand props and hand wear are drawn afterwards.
    beforeHands?.call();

    // The palms are always the top readable character layer.
    _drawBigHand(
      canvas,
      stage,
      rig.leftHand,
      e,
      base: handBase,
      light: handLight,
      isLeft: true,
    );
    _drawBigHand(
      canvas,
      stage,
      rig.rightHand,
      e,
      base: handBase,
      light: handLight,
      isLeft: false,
    );
    canvas.restore();
  }

  /// Oversized upturned hand built as a shallow 2.5D bowl. The light palm
  /// plane faces the sky, its near edge is visibly deeper/darker, and the four
  /// distal pads curl back over that edge instead of pointing at the camera.
  void _drawBigHand(
    Canvas canvas,
    Rect stage,
    AuraHandRigPose pose,
    double e, {
    required Color base,
    required Color light,
    required bool isLeft,
  }) {
    assert(pose.palmUp);
    final geometry = AuraCuppedHandGeometry.fromPose(
      pose,
      isLeft: isLeft,
    );
    final c = _p(stage, pose.center.dx, pose.center.dy);
    final worldRadius = _s(stage, 112) * pose.scale;
    const outline = Color(0xFF0C0A12);

    canvas.drawCircle(
      c,
      worldRadius * 1.85,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          c,
          worldRadius * 1.85,
          [
            _auraGlow(e).withValues(alpha: 0.16 + e * 0.34),
            Colors.transparent,
          ],
        ),
    );

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(pose.angleRadians);
    final handScale = pose.scale * (1 + pulse * 0.045);
    canvas.scale(handScale, handScale);

    final r = _s(stage, 122);
    final d = r * geometry.palmHalfDepth;
    final outer = geometry.outer;
    final outlineW = _s(stage, 7.5);
    final skinDark = Color.lerp(base, outline, 0.20)!;
    Paint handStroke([double opacity = 1]) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineW
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = outline.withValues(alpha: opacity);
    Paint skinGradient(Rect bounds) => Paint()
      ..shader = ui.Gradient.linear(
        bounds.topLeft,
        bounds.bottomRight,
        [Color.lerp(light, Colors.white, 0.16)!, base, skinDark],
        const [0, 0.58, 1],
      );

    // The only digit that rises above the bowl is the thumb. It projects to
    // the OUTER side, matching the visual grammar of the supplied reference.
    final thumb = Path()
      ..moveTo(outer * r * 0.48, d * 0.12)
      ..cubicTo(
        outer * r * 0.66,
        d * 0.02,
        outer * r * 0.78,
        -d * 0.30,
        outer * r * 0.84,
        -d * 0.55,
      )
      ..cubicTo(
        outer * r * 0.94,
        -d * 0.88,
        outer * r * 1.10,
        -d * 0.95,
        outer * r * 1.12,
        -d * 0.75,
      )
      ..cubicTo(
        outer * r * 1.18,
        -d * 0.50,
        outer * r * 1.08,
        -d * 0.18,
        outer * r * 0.93,
        d * 0.10,
      )
      ..cubicTo(
        outer * r * 0.84,
        d * 0.38,
        outer * r * 0.68,
        d * 0.50,
        outer * r * 0.54,
        d * 0.38,
      )
      ..cubicTo(
        outer * r * 0.46,
        d * 0.32,
        outer * r * 0.44,
        d * 0.20,
        outer * r * 0.48,
        d * 0.12,
      )
      ..close();
    final thumbBounds = Rect.fromLTRB(-r * 1.50, -d * 1.60, r * 1.50, d * 0.78);
    canvas.drawPath(thumb, skinGradient(thumbBounds));
    canvas.drawPath(thumb, handStroke());
    // Low, wide outer silhouette: its aspect ratio is derived from the palm
    // projection instead of being a near-circle facing the camera.
    final palm = Path()
      ..moveTo(-r * 0.94, -d * 0.22)
      ..cubicTo(-r * 0.82, -d * 0.78, -r * 0.45, -d, 0, -d * 0.96)
      ..cubicTo(r * 0.45, -d, r * 0.82, -d * 0.78, r * 0.94, -d * 0.22)
      ..cubicTo(r * 1.06, d * 0.18, r * 0.93, d * 0.83, r * 0.62, d * 1.10)
      ..cubicTo(r * 0.28, d * 1.28, -r * 0.28, d * 1.28, -r * 0.62, d * 1.10)
      ..cubicTo(-r * 0.93, d * 0.83, -r * 1.06, d * 0.18, -r * 0.94, -d * 0.22)
      ..close();
    final palmBounds = Rect.fromLTRB(-r * 1.08, -d, r * 1.08, d * 1.30);
    canvas.drawPath(palm, skinGradient(palmBounds));
    canvas.drawPath(palm, handStroke());

    // Dark near wall makes the hand read as a tray / concha rather than a
    // vertical badge. The four fingertips will overlap this wall afterward.
    final nearWall = Path()
      ..moveTo(-r * 0.94, d * 0.28)
      ..cubicTo(-r * 0.82, d * 0.96, -r * 0.43, d * 1.24, 0, d * 1.24)
      ..cubicTo(r * 0.43, d * 1.24, r * 0.82, d * 0.96, r * 0.94, d * 0.28)
      ..cubicTo(r * 0.72, d * 0.66, r * 0.34, d * 0.82, 0, d * 0.82)
      ..cubicTo(-r * 0.34, d * 0.82, -r * 0.72, d * 0.66, -r * 0.94, d * 0.28)
      ..close();
    canvas.drawPath(
      nearWall,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, d * 0.20),
          Offset(0, d * 1.28),
          [
            base.withValues(alpha: 0.74),
            Color.lerp(base, skinDark, 0.78)!,
          ],
        ),
    );

    // Concave top plane. It has no closed inner outline; a highlighted far rim
    // and a U-shaped occlusion shadow describe the depth more naturally.
    final palmPlane = Path()
      ..moveTo(-r * 0.82, -d * 0.23)
      ..cubicTo(-r * 0.62, -d * 0.86, r * 0.62, -d * 0.86, r * 0.82, -d * 0.23)
      ..cubicTo(r * 0.83, d * 0.16, r * 0.58, d * 0.65, r * 0.30, d * 0.77)
      ..cubicTo(r * 0.04, d * 0.90, -r * 0.31, d * 0.82, -r * 0.56, d * 0.64)
      ..cubicTo(-r * 0.79, d * 0.43, -r * 0.88, d * 0.02, -r * 0.82, -d * 0.23)
      ..close();
    canvas.drawPath(
      palmPlane,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(-outer * r * 0.10, -d * 0.14),
          r * 0.96,
          [
            Color.lerp(light, Colors.white, 0.22)!,
            light,
            Color.lerp(base, skinDark, 0.22)!,
          ],
          const [0, 0.58, 1],
        ),
    );
    final farRim = Path()
      ..moveTo(-r * 0.34, -d * 0.46)
      ..quadraticBezierTo(-r * 0.03, -d * 0.70, r * 0.29, -d * 0.48);
    canvas.drawPath(
      farRim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineW * 0.52
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.34),
    );
    final bowlShadow = Path()
      ..moveTo(-r * 0.64, d * 0.18)
      ..cubicTo(-r * 0.40, d * 0.72, r * 0.38, d * 0.76, r * 0.64, d * 0.20);
    canvas.drawPath(
      bowlShadow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineW * 0.78
        ..strokeCap = StrokeCap.round
        ..color = skinDark.withValues(alpha: 0.42),
    );

    // A broad distal thumb pad sits over the hidden proximal segment. Its
    // two-volume construction keeps the thumb fleshy and articulated instead
    // of reading as a thin antenna beside the bowl.
    canvas.save();
    canvas.translate(outer * r * 0.86, -d * 0.70);
    canvas.rotate(outer * 0.18);
    final thumbWidth = r * 0.49;
    final thumbHeight = r * 0.76;
    final thumbPad = Path()
      ..moveTo(-thumbWidth * 0.44, -thumbHeight * 0.08)
      ..cubicTo(
        -thumbWidth * 0.46,
        -thumbHeight * 0.40,
        -thumbWidth * 0.20,
        -thumbHeight * 0.54,
        thumbWidth * 0.06,
        -thumbHeight * 0.50,
      )
      ..cubicTo(
        thumbWidth * 0.38,
        -thumbHeight * 0.46,
        thumbWidth * 0.50,
        -thumbHeight * 0.17,
        thumbWidth * 0.44,
        thumbHeight * 0.12,
      )
      ..cubicTo(
        thumbWidth * 0.37,
        thumbHeight * 0.42,
        thumbWidth * 0.09,
        thumbHeight * 0.52,
        -thumbWidth * 0.16,
        thumbHeight * 0.45,
      )
      ..cubicTo(
        -thumbWidth * 0.39,
        thumbHeight * 0.36,
        -thumbWidth * 0.45,
        thumbHeight * 0.16,
        -thumbWidth * 0.44,
        -thumbHeight * 0.08,
      )
      ..close();
    final thumbPadBounds = Rect.fromLTRB(
      -thumbWidth * 0.50,
      -thumbHeight * 0.56,
      thumbWidth * 0.52,
      thumbHeight * 0.54,
    );
    canvas.drawPath(thumbPad, skinGradient(thumbPadBounds));
    final thumbOuterContour = Path()
      ..moveTo(-thumbWidth * 0.08, -thumbHeight * 0.50)
      ..cubicTo(
        thumbWidth * 0.35,
        -thumbHeight * 0.49,
        thumbWidth * 0.50,
        -thumbHeight * 0.18,
        thumbWidth * 0.44,
        thumbHeight * 0.12,
      )
      ..cubicTo(
        thumbWidth * 0.37,
        thumbHeight * 0.42,
        thumbWidth * 0.10,
        thumbHeight * 0.51,
        -thumbWidth * 0.10,
        thumbHeight * 0.46,
      );
    canvas.drawPath(
      thumbOuterContour,
      handStroke()..strokeWidth = outlineW * 0.74,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-outer * thumbWidth * 0.10, -thumbHeight * 0.20),
        width: thumbWidth * 0.34,
        height: thumbHeight * 0.17,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.30),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, thumbHeight * 0.16),
        width: thumbWidth * 0.48,
        height: thumbHeight * 0.18,
      ),
      0.18,
      pi - 0.36,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineW * 0.42
        ..strokeCap = StrokeCap.round
        ..color = skinDark.withValues(alpha: 0.38),
    );
    canvas.restore();

    // Asymmetric thenar/hypothenar volumes and creases reinforce a real palm
    // without the former symmetrical "smiley" lines.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(outer * r * 0.45, -d * 0.02),
        width: r * 0.74,
        height: d * 1.28,
      ),
      Paint()..color = base.withValues(alpha: 0.16),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-outer * r * 0.60, d * 0.06),
        width: r * 0.38,
        height: d * 0.96,
      ),
      Paint()..color = light.withValues(alpha: 0.11),
    );
    final crease = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineW * 0.48
      ..strokeCap = StrokeCap.round
      ..color = skinDark.withValues(alpha: 0.43);
    canvas.drawPath(
      Path()
        ..moveTo(outer * r * 0.30, -d * 0.42)
        ..cubicTo(
          outer * r * 0.58,
          -d * 0.14,
          outer * r * 0.54,
          d * 0.42,
          outer * r * 0.25,
          d * 0.64,
        ),
      crease,
    );

    canvas.drawPath(
      Path()
        ..moveTo(outer * r * 0.16, -d * 0.10)
        ..quadraticBezierTo(0, d * 0.10, -outer * r * 0.44, d * 0.12),
      crease,
    );

    // Four fingertip pads return toward the viewer over the near rim. They
    // are compact, overlapping and almost round—never upright finger shafts.
    const fingerPaintOrder = <int>[3, 2, 0, 1];
    for (final index in fingerPaintOrder) {
      final finger = geometry.fingers[index];
      final center = Offset(finger.tip.dx * r, finger.tip.dy * r);
      final width = finger.width * r;
      final height = finger.height * r;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(finger.angleRadians);
      final pad = Path()
        ..moveTo(-width * 0.46, -height * 0.08)
        ..cubicTo(
          -width * 0.48,
          -height * 0.39,
          -width * 0.25,
          -height * 0.54,
          0,
          -height * 0.53,
        )
        ..cubicTo(
          width * 0.28,
          -height * 0.54,
          width * 0.48,
          -height * 0.33,
          width * 0.47,
          -height * 0.03,
        )
        ..cubicTo(
          width * 0.46,
          height * 0.32,
          width * 0.22,
          height * 0.50,
          0,
          height * 0.49,
        )
        ..cubicTo(
          -width * 0.25,
          height * 0.51,
          -width * 0.46,
          height * 0.27,
          -width * 0.46,
          -height * 0.08,
        )
        ..close();
      final padBounds = Rect.fromLTRB(
        -width * 0.52,
        -height * 0.57,
        width * 0.52,
        height * 0.54,
      );
      canvas.drawPath(pad, skinGradient(padBounds));
      canvas.drawPath(
        pad,
        handStroke()..strokeWidth = outlineW * 0.66,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-outer * width * 0.10, -height * 0.20),
          width: width * 0.34,
          height: height * 0.17,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.27),
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(0, height * 0.13),
          width: width * 0.48,
          height: height * 0.20,
        ),
        0.20,
        pi - 0.40,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = outlineW * 0.42
          ..strokeCap = StrokeCap.round
          ..color = skinDark.withValues(alpha: 0.38),
      );
      canvas.restore();
    }

    if (e > 0.05) {
      canvas.drawPath(
        palm,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _s(stage, 3.5)
          ..strokeJoin = StrokeJoin.round
          ..color = _auraGlow(e).withValues(alpha: 0.20 + e * 0.48)
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, _s(stage, 1.4)),
      );
    }
    canvas.restore();
  }

  // Particles — purple pixels -------------------------------------------------
  void _drawParticles(Canvas canvas, Rect stage, List<_Particle> list) {
    for (final p in list) {
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      final c = _p(stage, p.pos.dx, p.pos.dy);
      final s = _s(stage, p.size) * (0.5 + t * 0.5);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: s * 2, height: s * 2),
        Radius.circular(s * 0.3),
      );
      final paint = Paint()
        ..blendMode = BlendMode.plus
        ..color = p.color.withValues(alpha: t * 0.9);
      if (p.hollow) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, s * 0.28);
      }
      canvas.drawRRect(rect, paint);
    }
  }

  void _drawShockwaves(Canvas canvas, Rect stage) {
    for (final w in _waves) {
      final c = _p(stage, w.center.dx, w.center.dy);
      final r = _s(stage, 40) + _s(stage, 560) * w.max * w.t;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..style = PaintingStyle.stroke
          ..strokeWidth = _s(stage, 10) * (1 - w.t)
          ..color = _auraGlow(heat).withValues(alpha: (1 - w.t) * 0.7),
      );
    }
  }

  void _drawGains(Canvas canvas, Rect stage) {
    for (final g in _gains) {
      final t = (g.life / g.maxLife).clamp(0.0, 1.0);
      final pos = _p(stage, g.pos.dx, g.pos.dy);
      final fontSize = _s(stage, g.passive ? 34 : 56);
      final color = g.passive
          ? _cyan.withValues(alpha: t * 0.8)
          : Color.lerp(_gold, Colors.white, 0.15)!.withValues(alpha: t);
      final painter = TextPainter(
        text: TextSpan(
          text: g.text,
          style: TextStyle(
            fontFamily: 'MPlusRounded',
            fontWeight: g.passive ? FontWeight.w700 : FontWeight.w800,
            fontSize: fontSize,
            color: color,
            shadows: [
              Shadow(
                  color: (g.passive ? _cyan : _gold).withValues(alpha: t * 0.7),
                  blurRadius: fontSize * 0.3),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final scale = 0.7 + (1 - t) * 0.35;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.scale(g.passive ? 1.0 : scale);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    }
  }

  void _drawHeatOverlay(Canvas canvas, Rect scene, double e) {
    if (e < 0.35) return;
    final strength = (e - 0.35) / 0.65;
    canvas.drawRect(
      scene,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          scene.center,
          scene.longestSide * 0.75,
          [Colors.transparent, _purpleDeep.withValues(alpha: strength * 0.3)],
          [0.55, 1.0],
        ),
    );
  }

  double _frac(double v) => v - v.floorToDouble();

  void _drawEquippedItemEffect(
    Canvas canvas,
    Rect stage, {
    required bool behindMascot,
  }) {
    final contentId = controller.equippedAppearance;
    final profile = AuraItemVisualEffects.profiles[contentId];
    if (contentId == null ||
        profile == null ||
        (profile.layer == AuraItemEffectLayer.behind) != behindMascot) {
      return;
    }

    final rig = AuraCharacterRigPose.forSwing(
      _swing,
      rootShiftX: _characterLean * 0.35,
    );
    final frame = AuraItemEffectFrame(
      elapsed: _elapsed,
      energy: _energy,
      level: controller.level(contentId),
      reduceMotion: controller.reduceMotion,
      swing: _swing,
      leftHand: rig.leftHand.center,
      rightHand: rig.rightHand.center,
      leftWrist: rig.leftHand.wrist,
      rightWrist: rig.rightHand.wrist,
    );

    canvas.save();
    if (profile.followsCharacter) {
      final authoredToBody =
          profile.anchorMode == AuraItemEffectAnchor.authored ? 1.0 : 0.0;
      canvas.translate(
        _s(stage, _characterLean * authoredToBody * profile.leanFactor),
        _s(stage, _characterBob),
      );
      if (!controller.reduceMotion) {
        final pivot = _p(stage, 512, 820);
        canvas.translate(pivot.dx, pivot.dy);
        canvas.rotate(_characterTiltDegrees * pi / 180);
        canvas.translate(-pivot.dx, -pivot.dy);
      }
    }
    AuraItemVisualEffects.paint(canvas, stage, profile, frame);
    canvas.restore();
  }

  void _drawEquippedAppearance(
    Canvas canvas,
    Rect stage, {
    required _AuraAppearanceLayer layer,
    bool characterTransformAlreadyApplied = false,
  }) {
    final contentId = controller.equippedAppearance;
    final catalog = _artCatalog;
    if (contentId == null ||
        contentId != _loadedAppearanceId ||
        catalog == null) {
      return;
    }
    final ids = AuraArtSelection.skinLayerIds(
      contentId,
      level: controller.level(contentId),
      reduceMotion: controller.reduceMotion,
    );
    final paint = Paint()..filterQuality = FilterQuality.medium;
    for (final id in ids) {
      final record = catalog[id];
      final image = _appearanceImages[id];
      if (record == null || image == null) continue;
      final recordLayer = AuraArtSelection.isBackAppearanceSlot(record.slot)
          ? _AuraAppearanceLayer.behindMascot
          : AuraArtSelection.isHandOverlayAppearanceSlot(record.slot)
              ? _AuraAppearanceLayer.overHands
              : _AuraAppearanceLayer.underHands;
      if (recordLayer != layer) {
        continue;
      }
      // The collection thumbnail for the two-touch union is authored as a
      // neutral-pose pair. In the live scene the equivalent buttons and link
      // are painted from the articulated hand anchors so they never float away
      // from a fast Six/Seven pose.
      if (contentId == 'ITEM-B-04' && record.slot == 'HANDS_WEAR') {
        continue;
      }
      canvas.save();
      if (AuraAppearancePlacement.followsCharacter(record.slot)) {
        final lean =
            _characterLean * AuraAppearancePlacement.leanFactor(record.slot);
        canvas.translate(
          _s(stage, lean),
          characterTransformAlreadyApplied ? 0 : _s(stage, _characterBob),
        );
        if (!controller.reduceMotion && !characterTransformAlreadyApplied) {
          final pivot = _p(stage, 512, 820);
          canvas.translate(pivot.dx, pivot.dy);
          canvas.rotate(_characterTiltDegrees * pi / 180);
          canvas.translate(-pivot.dx, -pivot.dy);
        }
      }
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        stage,
        paint,
      );
      canvas.restore();
    }
  }

  @override
  void onRemove() {
    _removed = true;
    _appearanceLoadEpoch++;
    if (_listeningForAppearance) {
      controller.removeListener(_appearanceMayHaveChanged);
      _listeningForAppearance = false;
    }
    _disposeAppearanceImages();
    charge.dispose();
    super.onRemove();
  }
}

class _Particle {
  _Particle({
    required this.pos,
    required this.vel,
    required this.accel,
    required this.life,
    required this.size,
    required this.color,
    this.hollow = false,
  }) : maxLife = life;

  Offset pos;
  Offset vel;
  Offset accel;
  double life;
  final double maxLife;
  double size;
  Color color;
  final bool hollow;
}

class _Shockwave {
  _Shockwave({required this.center, required this.max});
  final Offset center;
  final double max;
  double t = 0;
}

class _Gain {
  _Gain({
    required this.text,
    required this.pos,
    required this.vel,
    required this.life,
    this.passive = false,
  }) : maxLife = life;
  final String text;
  Offset pos;
  final Offset vel;
  double life;
  final double maxLife;
  final bool passive;
}
