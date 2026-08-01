import 'package:flutter_test/flutter_test.dart';
import 'package:aura_shift_six_seven/core/formatting.dart';

void main() {
  group('number-format-v1', () {
    test('truncates compact values instead of rounding', () {
      expect(AuraFormat.integer(BigInt.from(999)), '999');
      expect(AuraFormat.integer(BigInt.from(1999)), '1.99K');
      expect(AuraFormat.integer(BigInt.from(999999)), '999K');
      expect(
          AuraFormat.integer(BigInt.from(1234567), locale: 'pt-BR'), '1,23M');
    });
    test('keeps terminating rates exact below the compact boundary', () {
      expect(AuraFormat.rate(BigInt.from(1500)), '0.75');
      expect(AuraFormat.rate(BigInt.from(15000)), '7.5');
      expect(AuraFormat.exactRate(BigInt.from(21009)), '10.5045');
    });
    test('groups complete values and exact rates for their locale', () {
      expect(
        AuraFormat.exactInteger(
          BigInt.parse('1000000000000'),
          locale: 'pt-BR',
        ),
        '1.000.000.000.000',
      );
      expect(
        AuraFormat.exactInteger(BigInt.parse('1000000000000')),
        '1,000,000,000,000',
      );
      expect(
        AuraFormat.exactRate(
          BigInt.parse('2000001000'),
          locale: 'pt-BR',
        ),
        '1.000.000,5',
      );
    });
    test('formats return durations without second-level noise', () {
      expect(AuraFormat.duration(const Duration(minutes: 9)), '9min');
      expect(AuraFormat.duration(const Duration(hours: 4)), '4h');
      expect(
        AuraFormat.duration(const Duration(hours: 12, minutes: 7)),
        '12h 7min',
      );
    });
  });
}
