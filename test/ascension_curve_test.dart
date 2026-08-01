import 'package:aura_shift_six_seven/core/ascension_curve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final qa = BigInt.from(ascensionThreshold);

  test('whole multiplier thresholds follow the sum of squares', () {
    expect(AscensionCurve.auraForMultiplier(BigInt.from(100)), BigInt.zero);
    expect(AscensionCurve.auraForMultiplier(BigInt.from(200)), qa);
    expect(AscensionCurve.auraForMultiplier(BigInt.from(300)),
        qa * BigInt.from(5));
    expect(
      AscensionCurve.auraForMultiplier(BigInt.from(1000)),
      qa * BigInt.from(285),
    );
    expect(
      AscensionCurve.auraForMultiplier(BigInt.from(1100)),
      qa * BigInt.from(385),
    );
  });

  test('10x to 11x requires one hundred Qa', () {
    final atTen = AscensionCurve.auraForMultiplier(BigInt.from(1000));
    final atEleven = AscensionCurve.auraForMultiplier(BigInt.from(1100));
    expect(atEleven - atTen, qa * BigInt.from(100));
  });

  test('inverse returns the largest earned hundredth exactly', () {
    for (final multiplier in [
      100,
      101,
      199,
      200,
      201,
      236,
      300,
      1000,
      1100,
    ]) {
      final value = BigInt.from(multiplier);
      final threshold = AscensionCurve.auraForMultiplier(value);
      expect(AscensionCurve.multiplierForAura(threshold), value);
      if (threshold > BigInt.zero) {
        expect(
          AscensionCurve.multiplierForAura(threshold - BigInt.one),
          value - BigInt.one,
        );
      }
    }
  });
}
