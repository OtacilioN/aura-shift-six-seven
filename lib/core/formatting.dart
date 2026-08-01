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

  /// Formats the complete integer with locale-aware thousands separators.
  static String exactInteger(BigInt value, {String locale = 'en-US'}) {
    final sign = value.isNegative ? '-' : '';
    return '$sign${_groupDigits(value.abs().toString(), locale)}';
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

  static String exactRate(BigInt numerator, {String locale = 'en-US'}) =>
      _decimal(numerator, 4, locale, divisor: BigInt.from(2000));

  static String multiplier(BigInt centi) {
    final whole = centi ~/ BigInt.from(100);
    final fraction = (centi % BigInt.from(100))
        .toString()
        .padLeft(2, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return fraction.isEmpty ? whole.toString() : '$whole.$fraction';
  }

  static String duration(Duration value) {
    final totalMinutes = max(1, value.inMinutes);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '${minutes}min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }

  static String _decimal(BigInt numerator, int places, String locale,
      {BigInt? divisor}) {
    divisor ??= BigInt.from(10).pow(places);
    final scale = BigInt.from(10).pow(places);
    final scaled =
        places == 0 ? numerator ~/ divisor : numerator * scale ~/ divisor;
    final sign = scaled.isNegative ? '-' : '';
    var raw = scaled.abs().toString();
    if (places == 0) return '$sign${_groupDigits(raw, locale)}';
    raw = raw.padLeft(places + 1, '0');
    final split = raw.length - places;
    final whole = _groupDigits(raw.substring(0, split), locale);
    final fraction = raw.substring(split).replaceFirst(RegExp(r'0+$'), '');
    if (fraction.isEmpty) return '$sign$whole';
    return '$sign$whole${_decimalSeparator(locale)}$fraction';
  }

  static String _groupDigits(String digits, String locale) {
    if (digits.length <= 3) return digits;
    final separator = _groupSeparator(locale);
    final firstGroupLength = digits.length % 3 == 0 ? 3 : digits.length % 3;
    final buffer = StringBuffer(digits.substring(0, firstGroupLength));
    for (var index = firstGroupLength; index < digits.length; index += 3) {
      buffer
        ..write(separator)
        ..write(digits.substring(index, index + 3));
    }
    return buffer.toString();
  }

  static String _groupSeparator(String locale) {
    if (locale.startsWith('pt') || locale.startsWith('de')) return '.';
    if (locale.startsWith('fr')) return '\u202f';
    if (locale == 'ar') return '٬';
    return ',';
  }

  static String _decimalSeparator(String locale) {
    if (locale == 'ar') return '٫';
    if (locale.startsWith('pt') ||
        locale.startsWith('de') ||
        locale.startsWith('fr')) {
      return ',';
    }
    return '.';
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
