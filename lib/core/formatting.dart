import 'dart:math';

/// `number-format-v1`: compact values are always truncated, never rounded.
class AuraFormat {
  static const _suffixes = [
    'K',
    'M',
    'B',
    'T',
    'Qa',
    'Qi',
    'Sx',
    'Sp',
    'Oc',
    'No',
    'Dc'
  ];

  static String integer(BigInt value, {String locale = 'en-US'}) {
    if (value < BigInt.from(1000)) return value.toString();
    final digits = value.toString().length;
    if (digits > 36) return _scientific(value, locale);
    final group = (digits - 1) ~/ 3;
    final exponent = group * 3;
    final divisor = BigInt.from(10).pow(exponent);
    final whole = value ~/ divisor;
    final places = whole < BigInt.from(10)
        ? 2
        : whole < BigInt.from(100)
            ? 1
            : 0;
    final scaled = value * BigInt.from(10).pow(places) ~/ divisor;
    final coefficient = _decimal(scaled, places, locale);
    return '$coefficient${_suffixes[group - 1]}';
  }

  /// Formats numerator / 2000 exactly for small values and compactly thereafter.
  static String rate(BigInt numerator, {String locale = 'en-US'}) {
    const denominator = 2000;
    if (numerator < BigInt.from(2000000)) {
      final whole = numerator ~/ BigInt.from(denominator);
      final fractional = numerator % BigInt.from(denominator);
      if (fractional == BigInt.zero) return whole.toString();
      return _decimal(numerator, 4, locale, divisor: BigInt.from(denominator));
    }
    return integer(numerator ~/ BigInt.from(denominator), locale: locale);
  }

  static String exactRate(BigInt numerator) =>
      _decimal(numerator, 4, 'en-US', divisor: BigInt.from(2000));

  static String multiplier(BigInt centi) {
    final whole = centi ~/ BigInt.from(100);
    final fraction = (centi % BigInt.from(100))
        .toString()
        .padLeft(2, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return fraction.isEmpty ? whole.toString() : '$whole.$fraction';
  }

  static String _decimal(BigInt numerator, int places, String locale,
      {BigInt? divisor}) {
    divisor ??= BigInt.from(10).pow(places);
    final scale = BigInt.from(10).pow(places);
    final scaled =
        places == 0 ? numerator ~/ divisor : numerator * scale ~/ divisor;
    var raw = scaled.toString();
    if (places == 0) return raw;
    raw = raw.padLeft(places + 1, '0');
    final split = raw.length - places;
    var result = '${raw.substring(0, split)}.${raw.substring(split)}';
    result = result
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return locale.startsWith('pt') ||
            locale.startsWith('de') ||
            locale.startsWith('fr') ||
            locale == 'ar'
        ? result.replaceAll('.', locale == 'ar' ? '٫' : ',')
        : result;
  }

  static String _scientific(BigInt value, String locale) {
    final raw = value.toString();
    final places = min(2, raw.length - 1);
    final coefficient = raw.substring(0, 1) +
        (places == 0 ? '' : '.${raw.substring(1, places + 1)}');
    final trimmed = coefficient
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return '${locale == 'ar' ? trimmed.replaceAll('.', '٫') : trimmed}e${raw.length - 1}';
  }
}
