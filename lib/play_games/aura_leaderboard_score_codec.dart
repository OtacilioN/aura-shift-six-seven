/// Order-preserving encoding from arbitrary non-negative Aura values to int64.
///
/// Values with at most 15 decimal digits remain exact. Larger values store a
/// decimal digit bucket and their 15 most significant digits. Once int64 is
/// saturated, even larger values intentionally tie instead of overflowing.
abstract final class AuraLeaderboardScoreCodec {
  static final BigInt _bucketSize = BigInt.from(10).pow(15);
  static final BigInt maxInt64 = BigInt.parse('9223372036854775807');

  static int encode(BigInt value) {
    if (value.isNegative) {
      throw ArgumentError.value(value, 'value', 'Aura cannot be negative.');
    }
    if (value < _bucketSize) return value.toInt();
    final digits = value.toString();
    final bucket = digits.length - 15;
    final mantissa = BigInt.parse(digits.substring(0, 15));
    final encoded = BigInt.from(bucket) * _bucketSize + mantissa;
    return (encoded > maxInt64 ? maxInt64 : encoded).toInt();
  }

  static BigInt decodeApproximate(int encoded) {
    if (encoded < 0) {
      throw ArgumentError.value(
        encoded,
        'encoded',
        'Leaderboard scores cannot be negative.',
      );
    }
    final value = BigInt.from(encoded);
    if (value < _bucketSize) return value;
    if (value == maxInt64) {
      final bucket = value ~/ _bucketSize;
      final mantissa = value % _bucketSize;
      return mantissa * BigInt.from(10).pow(bucket.toInt());
    }
    final bucket = value ~/ _bucketSize;
    final mantissa = value % _bucketSize;
    return mantissa * BigInt.from(10).pow(bucket.toInt());
  }
}
