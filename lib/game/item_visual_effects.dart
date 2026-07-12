import 'dart:math' as math;
import 'dart:ui';

enum AuraItemEffectLayer { behind, front }

enum AuraItemEffectKind {
  statusPulse,
  receiptScan,
  lensScan,
  zipperSpark,
  hotfixOrbit,
  alarmRing,
  lagTrail,
  remainderOrbit,
  unionLink,
  statementTick,
  glitchSplit,
  decimalDrift,
  cacheFlow,
  routerSignal,
  missingFrame,
  meetingSync,
  spectrumConverge,
  canonicalTorque,
}

enum AuraItemEffectAnchor { authored, raisedHand, bothHands }

class AuraItemVisualProfile {
  const AuraItemVisualProfile({
    required this.contentId,
    required this.kind,
    required this.layer,
    required this.anchor,
    this.anchorMode = AuraItemEffectAnchor.authored,
    this.followsCharacter = false,
    this.leanFactor = 1.0,
  });

  final String contentId;
  final AuraItemEffectKind kind;
  final AuraItemEffectLayer layer;
  final Offset anchor;
  final AuraItemEffectAnchor anchorMode;
  final bool followsCharacter;
  final double leanFactor;
}

class AuraItemEffectFrame {
  const AuraItemEffectFrame({
    required this.elapsed,
    required this.energy,
    required this.level,
    required this.reduceMotion,
    required this.swing,
    required this.leftHand,
    required this.rightHand,
    required this.leftWrist,
    required this.rightWrist,
  });

  final double elapsed;
  final double energy;
  final int level;
  final bool reduceMotion;
  final double swing;
  final Offset leftHand;
  final Offset rightHand;
  final Offset leftWrist;
  final Offset rightWrist;
}

/// Testable route for the two-touch union cable.
///
/// The controls bow below the lower wrist, keeping the cable out of the
/// mascot's face even when one hand is high and the other is low.
class AuraUnionLinkGeometry {
  const AuraUnionLinkGeometry({
    required this.leftSocket,
    required this.leftDrop,
    required this.leftControl,
    required this.rightControl,
    required this.rightDrop,
    required this.rightSocket,
  });

  factory AuraUnionLinkGeometry.fromWrists(
    Offset leftWrist,
    Offset rightWrist,
  ) {
    final routeY = math.max(
      548.0,
      math.max(leftWrist.dy, rightWrist.dy) + 82,
    );
    // Exit on the outer/lower side of each wrist. A raised wrist can sit beside
    // an ear, so routing inward first would still scrape the head silhouette.
    final leftSocket = leftWrist + const Offset(-34, 18);
    final rightSocket = rightWrist + const Offset(34, 18);
    final leftDrop = Offset(leftSocket.dx, routeY);
    final rightDrop = Offset(rightSocket.dx, routeY);
    return AuraUnionLinkGeometry(
      leftSocket: leftSocket,
      leftDrop: leftDrop,
      leftControl: Offset(leftDrop.dx + 96, routeY),
      rightControl: Offset(rightDrop.dx - 96, routeY),
      rightDrop: rightDrop,
      rightSocket: rightSocket,
    );
  }

  final Offset leftSocket;
  final Offset leftDrop;
  final Offset leftControl;
  final Offset rightControl;
  final Offset rightDrop;
  final Offset rightSocket;

  Offset pointAt(double t) {
    if (t <= 0.2) {
      return Offset.lerp(leftSocket, leftDrop, t / 0.2)!;
    }
    if (t >= 0.8) {
      return Offset.lerp(rightDrop, rightSocket, (t - 0.8) / 0.2)!;
    }
    final curveT = (t - 0.2) / 0.6;
    final inverse = 1 - curveT;
    return leftDrop * (inverse * inverse * inverse) +
        leftControl * (3 * inverse * inverse * curveT) +
        rightControl * (3 * inverse * curveT * curveT) +
        rightDrop * (curveT * curveT * curveT);
  }
}

/// Small code-native effects that give every Aura Item a distinct scene read.
///
/// The authored SVG remains responsible for identity and the effect only adds
/// motion or activation feedback. Consequently every item still reads when
/// motion is reduced or when only its base layer is unlocked.
abstract final class AuraItemVisualEffects {
  static const cyan = Color(0xFF43E6FF);
  static const blue = Color(0xFF3478F6);
  static const magenta = Color(0xFFFF4FA3);
  static const coral = Color(0xFFFF7A66);
  static const gold = Color(0xFFFFD166);
  static const mint = Color(0xFF5CF2C7);
  static const violet = Color(0xFF8B7CFF);
  static const paper = Color(0xFFF7F5FF);
  static const ink = Color(0xFF090B1A);

  static const profiles = <String, AuraItemVisualProfile>{
    'ITEM-A-01': AuraItemVisualProfile(
      contentId: 'ITEM-A-01',
      kind: AuraItemEffectKind.statusPulse,
      layer: AuraItemEffectLayer.front,
      anchor: Offset(400, 548),
      followsCharacter: true,
    ),
    'ITEM-A-02': AuraItemVisualProfile(
      contentId: 'ITEM-A-02',
      kind: AuraItemEffectKind.receiptScan,
      layer: AuraItemEffectLayer.front,
      anchor: Offset(668, 654),
      followsCharacter: true,
    ),
    'ITEM-A-03': AuraItemVisualProfile(
      contentId: 'ITEM-A-03',
      kind: AuraItemEffectKind.lensScan,
      layer: AuraItemEffectLayer.front,
      anchor: Offset(512, 374),
      followsCharacter: true,
      leanFactor: 1.15,
    ),
    'ITEM-A-04': AuraItemVisualProfile(
      contentId: 'ITEM-A-04',
      kind: AuraItemEffectKind.zipperSpark,
      layer: AuraItemEffectLayer.front,
      anchor: Offset(512, 640),
      followsCharacter: true,
    ),
    'ITEM-A-05': AuraItemVisualProfile(
      contentId: 'ITEM-A-05',
      kind: AuraItemEffectKind.hotfixOrbit,
      layer: AuraItemEffectLayer.front,
      anchor: Offset(512, 180),
      followsCharacter: true,
      leanFactor: 1.15,
    ),
    'ITEM-B-01': AuraItemVisualProfile(
      contentId: 'ITEM-B-01',
      kind: AuraItemEffectKind.alarmRing,
      layer: AuraItemEffectLayer.behind,
      anchor: Offset(790, 802),
    ),
    'ITEM-B-02': AuraItemVisualProfile(
      contentId: 'ITEM-B-02',
      kind: AuraItemEffectKind.lagTrail,
      layer: AuraItemEffectLayer.front,
      anchor: Offset(512, 852),
      followsCharacter: true,
    ),
    'ITEM-B-03': AuraItemVisualProfile(
      contentId: 'ITEM-B-03',
      kind: AuraItemEffectKind.remainderOrbit,
      layer: AuraItemEffectLayer.front,
      anchor: Offset(790, 370),
      followsCharacter: true,
    ),
    'ITEM-B-04': AuraItemVisualProfile(
      contentId: 'ITEM-B-04',
      kind: AuraItemEffectKind.unionLink,
      layer: AuraItemEffectLayer.front,
      anchor: Offset.zero,
      anchorMode: AuraItemEffectAnchor.bothHands,
      followsCharacter: true,
    ),
    'ITEM-B-05': AuraItemVisualProfile(
      contentId: 'ITEM-B-05',
      kind: AuraItemEffectKind.statementTick,
      layer: AuraItemEffectLayer.behind,
      anchor: Offset(846, 382),
    ),
    'ITEM-C-01': AuraItemVisualProfile(
      contentId: 'ITEM-C-01',
      kind: AuraItemEffectKind.glitchSplit,
      layer: AuraItemEffectLayer.front,
      anchor: Offset(385, 551),
      followsCharacter: true,
    ),
    'ITEM-C-02': AuraItemVisualProfile(
      contentId: 'ITEM-C-02',
      kind: AuraItemEffectKind.decimalDrift,
      layer: AuraItemEffectLayer.front,
      anchor: Offset(730, 690),
      followsCharacter: true,
    ),
    'ITEM-C-03': AuraItemVisualProfile(
      contentId: 'ITEM-C-03',
      kind: AuraItemEffectKind.cacheFlow,
      layer: AuraItemEffectLayer.behind,
      anchor: Offset(512, 620),
      followsCharacter: true,
    ),
    'ITEM-C-04': AuraItemVisualProfile(
      contentId: 'ITEM-C-04',
      kind: AuraItemEffectKind.routerSignal,
      layer: AuraItemEffectLayer.behind,
      anchor: Offset(790, 804),
    ),
    'ITEM-C-05': AuraItemVisualProfile(
      contentId: 'ITEM-C-05',
      kind: AuraItemEffectKind.missingFrame,
      layer: AuraItemEffectLayer.behind,
      anchor: Offset(512, 490),
    ),
    'ITEM-CONV-01': AuraItemVisualProfile(
      contentId: 'ITEM-CONV-01',
      kind: AuraItemEffectKind.meetingSync,
      layer: AuraItemEffectLayer.behind,
      anchor: Offset(512, 500),
    ),
    'ITEM-CONV-02': AuraItemVisualProfile(
      contentId: 'ITEM-CONV-02',
      kind: AuraItemEffectKind.spectrumConverge,
      layer: AuraItemEffectLayer.behind,
      anchor: Offset(512, 500),
    ),
    'ITEM-CONV-03': AuraItemVisualProfile(
      contentId: 'ITEM-CONV-03',
      kind: AuraItemEffectKind.canonicalTorque,
      layer: AuraItemEffectLayer.behind,
      anchor: Offset(800, 300),
    ),
  };

  static void paint(
    Canvas canvas,
    Rect stage,
    AuraItemVisualProfile profile,
    AuraItemEffectFrame frame,
  ) {
    final motion = frame.reduceMotion ? 0.0 : frame.elapsed;
    final pulse = 0.5 + 0.5 * math.sin(motion * math.pi * 2 / 1.4);
    final milestone = frame.level >= 25
        ? 1.0
        : frame.level >= 10
            ? 0.78
            : 0.52;
    final alpha = milestone * (0.30 + pulse * 0.28 + frame.energy * 0.12);
    final scale = stage.width / 1024;
    final anchor = _resolvedAnchor(profile, frame);

    canvas.save();
    canvas.translate(stage.left, stage.top);
    canvas.scale(scale, scale);
    switch (profile.kind) {
      case AuraItemEffectKind.statusPulse:
        _ring(canvas, anchor, 46 + pulse * 12, cyan, alpha, width: 8);
        canvas.drawCircle(anchor, 7 + pulse * 2,
            Paint()..color = paper.withValues(alpha: alpha));
      case AuraItemEffectKind.receiptScan:
        final y = anchor.dy - 58 + pulse * 116;
        canvas.drawLine(
          Offset(anchor.dx - 58, y),
          Offset(anchor.dx + 58, y - 16),
          _stroke(cyan, 8, alpha),
        );
        _spark(canvas, anchor + const Offset(90, -75), 15 + pulse * 6, cyan,
            alpha);
      case AuraItemEffectKind.lensScan:
        final x = anchor.dx - 96 + pulse * 192;
        canvas.drawLine(
          Offset(x, anchor.dy - 42),
          Offset(x + 24, anchor.dy + 42),
          _stroke(paper, 10, alpha),
        );
      case AuraItemEffectKind.zipperSpark:
        final y = anchor.dy - 70 + pulse * 140;
        _spark(canvas, Offset(anchor.dx, y), 13 + pulse * 4, cyan, alpha);
      case AuraItemEffectKind.hotfixOrbit:
        for (var i = 0; i < 3; i++) {
          final localPulse = frame.reduceMotion
              ? 0.55
              : (0.5 +
                  0.5 *
                      math.sin(
                        motion * math.pi * 1.4 - i * math.pi * 0.55,
                      ));
          final point = anchor + Offset((i - 1) * 78, 34);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: point, width: 52, height: 24),
              const Radius.circular(7),
            ),
            Paint()
              ..color = (i == 1 ? blue : cyan)
                  .withValues(alpha: alpha * (0.55 + localPulse * 0.45)),
          );
        }
      case AuraItemEffectKind.alarmRing:
        for (var i = 0; i < 2; i++) {
          final side = i == 0 ? -1.0 : 1.0;
          final bell = anchor + Offset(side * 66, -54);
          canvas.drawArc(
            Rect.fromCircle(center: bell, radius: 26 + pulse * 12),
            side < 0 ? math.pi * 0.8 : -math.pi * 0.3,
            side * math.pi * 0.7,
            false,
            _stroke(coral, 8, alpha),
          );
        }
      case AuraItemEffectKind.lagTrail:
        for (var i = 1; i <= 3; i++) {
          final fade = alpha * (1 - i * 0.22);
          for (final side in const [-1.0, 1.0]) {
            canvas.drawOval(
              Rect.fromCenter(
                center: anchor + Offset(side * 78 - i * 24, i * 5),
                width: 112,
                height: 42,
              ),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 8
                ..color = magenta.withValues(alpha: fade),
            );
          }
        }
      case AuraItemEffectKind.remainderOrbit:
        final center = anchor + const Offset(0, -110);
        final angle = frame.reduceMotion ? -math.pi / 2 : -math.pi / 2 + motion;
        final point =
            center + Offset(math.cos(angle) * 82, math.sin(angle) * 112);
        canvas.drawCircle(
          point,
          18,
          Paint()..color = magenta.withValues(alpha: alpha * 0.28),
        );
        canvas.drawCircle(
          point,
          8,
          Paint()..color = coral.withValues(alpha: alpha),
        );
      case AuraItemEffectKind.unionLink:
        final route = AuraUnionLinkGeometry.fromWrists(
          frame.leftWrist,
          frame.rightWrist,
        );
        final linkPath = Path()
          ..moveTo(route.leftSocket.dx, route.leftSocket.dy)
          ..lineTo(route.leftDrop.dx, route.leftDrop.dy)
          ..cubicTo(
            route.leftControl.dx,
            route.leftControl.dy,
            route.rightControl.dx,
            route.rightControl.dy,
            route.rightDrop.dx,
            route.rightDrop.dy,
          )
          ..lineTo(route.rightSocket.dx, route.rightSocket.dy);
        canvas.drawPath(
          linkPath,
          _stroke(magenta, 18, alpha * 0.34)..strokeCap = StrokeCap.round,
        );
        canvas.drawPath(
          linkPath,
          _stroke(coral, 8, alpha * 0.82)..strokeCap = StrokeCap.round,
        );
        _touchDevice(
          canvas,
          hand: frame.leftHand,
          wrist: frame.leftWrist,
          socket: route.leftSocket,
          color: magenta,
          alpha: alpha,
        );
        _touchDevice(
          canvas,
          hand: frame.rightHand,
          wrist: frame.rightWrist,
          socket: route.rightSocket,
          color: coral,
          alpha: alpha,
        );
        if (!frame.reduceMotion) {
          canvas.drawCircle(
            route.pointAt(pulse),
            11,
            Paint()..color = paper.withValues(alpha: alpha),
          );
        }
      case AuraItemEffectKind.statementTick:
        final path = Path()
          ..moveTo(anchor.dx - 82, anchor.dy + 42)
          ..lineTo(anchor.dx - 36, anchor.dy + 10)
          ..lineTo(anchor.dx + 4, anchor.dy + 28)
          ..lineTo(anchor.dx + 46, anchor.dy - 28 - pulse * 18)
          ..lineTo(anchor.dx + 86, anchor.dy - 8);
        canvas.drawPath(path, _stroke(coral, 10, alpha));
        canvas.drawCircle(anchor + Offset(46, -28 - pulse * 18), 10,
            Paint()..color = paper.withValues(alpha: alpha));
      case AuraItemEffectKind.glitchSplit:
        final jump = frame.reduceMotion ? 0.0 : (pulse > 0.82 ? 12.0 : 2.0);
        for (final (dy, color, dx) in [
          (-20.0, gold, -jump),
          (0.0, mint, jump),
          (20.0, paper, -jump * 0.5)
        ]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: anchor + Offset(dx, dy), width: 86, height: 10),
              const Radius.circular(5),
            ),
            Paint()..color = color.withValues(alpha: alpha * 0.8),
          );
        }
      case AuraItemEffectKind.decimalDrift:
        for (var i = 0; i < 4; i++) {
          final phase = motion * 0.7 + i * 0.9;
          final point =
              anchor + Offset(math.sin(phase) * 46, -24 - ((phase * 34) % 104));
          canvas.drawCircle(point, i == 0 ? 7 : 4,
              Paint()..color = (i == 0 ? gold : mint).withValues(alpha: alpha));
        }
      case AuraItemEffectKind.cacheFlow:
        for (var i = 0; i < 5; i++) {
          final y = anchor.dy - 130 + ((motion * 48 + i * 62) % 300);
          final x = anchor.dx + (i.isEven ? -1 : 1) * (54 + i * 8);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(x, y), width: 34, height: 20),
                const Radius.circular(6)),
            Paint()
              ..color =
                  (i.isEven ? gold : mint).withValues(alpha: alpha * 0.72),
          );
        }
      case AuraItemEffectKind.routerSignal:
        for (var i = 1; i <= 3; i++) {
          canvas.drawArc(
            Rect.fromCenter(
                center: anchor + const Offset(0, -42),
                width: 54.0 * i,
                height: 38.0 * i),
            math.pi * 1.12,
            math.pi * 0.76,
            false,
            _stroke(i == 3 ? gold : mint, 8, alpha * (0.45 + pulse * 0.55)),
          );
        }
      case AuraItemEffectKind.missingFrame:
        final offset = 280 + pulse * 14;
        for (final point in [
          anchor + Offset(-offset, -230),
          anchor + Offset(offset, -230),
          anchor + Offset(-offset, 230),
          anchor + Offset(offset, 230),
        ]) {
          _corner(canvas, point, point.dx < anchor.dx ? 1 : -1,
              point.dy < anchor.dy ? 1 : -1, alpha);
        }
      case AuraItemEffectKind.meetingSync:
        for (var i = 0; i < 3; i++) {
          final angle = -math.pi / 2 + i * math.pi * 2 / 3;
          final radius = 170 - pulse * 42;
          final point = anchor +
              Offset(math.cos(angle) * radius, math.sin(angle) * radius);
          canvas.drawLine(
              point, anchor, _stroke([cyan, magenta, gold][i], 9, alpha * 0.7));
          canvas.drawCircle(
              point,
              17,
              Paint()
                ..color = [cyan, magenta, gold][i].withValues(alpha: alpha));
        }
      case AuraItemEffectKind.spectrumConverge:
        for (var i = 0; i < 3; i++) {
          final angle = motion * 0.42 + i * math.pi * 2 / 3;
          final start =
              anchor + Offset(math.cos(angle) * 230, math.sin(angle) * 160);
          final control =
              anchor + Offset(math.sin(angle) * 80, -math.cos(angle) * 54);
          final path = Path()
            ..moveTo(start.dx, start.dy)
            ..quadraticBezierTo(control.dx, control.dy, anchor.dx, anchor.dy);
          canvas.drawPath(path, _stroke([cyan, magenta, gold][i], 13, alpha));
        }
      case AuraItemEffectKind.canonicalTorque:
        canvas.save();
        canvas.translate(anchor.dx, anchor.dy);
        canvas.rotate(frame.reduceMotion ? 0.0 : math.sin(motion * 0.8) * 0.08);
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: 142 + pulse * 6),
          -math.pi * 0.72,
          math.pi * 0.42,
          false,
          _stroke(violet, 11, alpha),
        );
        for (var i = 0; i < 3; i++) {
          final angle = -math.pi * 0.72 + i * math.pi * 0.21;
          final point = Offset(math.cos(angle) * 142, math.sin(angle) * 142);
          canvas.drawCircle(
            point,
            8 + pulse * 2,
            Paint()..color = [cyan, magenta, gold][i].withValues(alpha: alpha),
          );
        }
        canvas.restore();
    }
    canvas.restore();
  }

  static Offset _resolvedAnchor(
    AuraItemVisualProfile profile,
    AuraItemEffectFrame frame,
  ) =>
      switch (profile.anchorMode) {
        AuraItemEffectAnchor.authored => profile.anchor,
        AuraItemEffectAnchor.raisedHand => Offset.lerp(
            frame.rightHand,
            frame.leftHand,
            ((frame.swing + 1) * 0.5).clamp(0.0, 1.0),
          )!,
        AuraItemEffectAnchor.bothHands =>
          Offset.lerp(frame.leftHand, frame.rightHand, 0.5)!,
      };

  static Paint _stroke(Color color, double width, double alpha) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0));

  static void _touchDevice(
    Canvas canvas, {
    required Offset hand,
    required Offset wrist,
    required Offset socket,
    required Color color,
    required double alpha,
  }) {
    final forearmAngle = math.atan2(hand.dy - wrist.dy, hand.dx - wrist.dx);
    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);
    canvas.rotate(forearmAngle + math.pi / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 76, height: 42),
        const Radius.circular(18),
      ),
      Paint()..color = ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 60, height: 26),
        const Radius.circular(12),
      ),
      Paint()..color = color.withValues(alpha: 0.84),
    );
    canvas.restore();

    canvas.drawCircle(hand, 43, Paint()..color = ink);
    canvas.drawCircle(
      hand,
      31,
      Paint()..color = color.withValues(alpha: 0.90),
    );
    canvas.drawCircle(
      hand.translate(-7, -9),
      9,
      Paint()..color = paper.withValues(alpha: alpha),
    );
    canvas.drawCircle(socket, 18, Paint()..color = ink);
    canvas.drawCircle(
      socket,
      8,
      Paint()..color = paper.withValues(alpha: alpha),
    );
  }

  static void _ring(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double alpha, {
    required double width,
  }) =>
      canvas.drawCircle(center, radius, _stroke(color, width, alpha));

  static void _spark(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.32, center.dy - radius * 0.32)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx + radius * 0.32, center.dy + radius * 0.32)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.32, center.dy + radius * 0.32)
      ..lineTo(center.dx - radius, center.dy)
      ..lineTo(center.dx - radius * 0.32, center.dy - radius * 0.32)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
  }

  static void _corner(
    Canvas canvas,
    Offset point,
    double horizontal,
    double vertical,
    double alpha,
  ) {
    final path = Path()
      ..moveTo(point.dx + horizontal * 64, point.dy)
      ..lineTo(point.dx, point.dy)
      ..lineTo(point.dx, point.dy + vertical * 64);
    canvas.drawPath(path, _stroke(gold, 11, alpha));
  }
}
