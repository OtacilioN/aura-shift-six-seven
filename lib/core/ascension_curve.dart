const ascensionThreshold = 1000000000000000;

/// Canonical `balance-v0.4` Aura Ascension curve.
///
/// Reaching the next whole multiplier from `n×` costs exactly `n² Qa`.
/// The polynomial is the closed form of the sum of squares, evaluated in
/// hundredths so previews remain smooth and every result stays deterministic.
abstract final class AscensionCurve {
  static final BigInt _baseMultiplier = BigInt.from(100);
  static final BigInt _denominator = BigInt.from(6000000);
  static final BigInt _threshold = BigInt.from(ascensionThreshold);

  static BigInt auraForMultiplier(BigInt multiplier) {
    if (multiplier <= _baseMultiplier) return BigInt.zero;
    final bonus = multiplier - _baseMultiplier;
    final numerator = bonus *
        multiplier *
        (BigInt.two * multiplier - _baseMultiplier) *
        _threshold;
    return (numerator + _denominator - BigInt.one) ~/ _denominator;
  }

  static BigInt multiplierForAura(BigInt aura) {
    if (aura <= BigInt.zero) return _baseMultiplier;
    var lower = _baseMultiplier;
    var upper = _baseMultiplier * BigInt.two;
    while (auraForMultiplier(upper) <= aura) {
      lower = upper;
      upper *= BigInt.two;
    }
    while (lower + BigInt.one < upper) {
      final middle = (lower + upper) >> 1;
      if (auraForMultiplier(middle) <= aura) {
        lower = middle;
      } else {
        upper = middle;
      }
    }
    return lower;
  }
}
