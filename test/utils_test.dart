import 'package:flutter_test/flutter_test.dart';
import 'package:device_inspector/device_inspector.dart';

void main() {
  group('SafeParser Tests', () {
    test('parseInt handles null, int, double, string', () {
      expect(SafeParser.parseInt(null), isNull);
      expect(SafeParser.parseInt(42), equals(42));
      expect(SafeParser.parseInt(42.8), equals(42));
      expect(SafeParser.parseInt('123'), equals(123));
      expect(SafeParser.parseInt('invalid'), isNull);
    });

    test('parseDouble handles NaN, int, double, string', () {
      expect(SafeParser.parseDouble(null), isNull);
      expect(SafeParser.parseDouble(double.nan), isNull);
      expect(SafeParser.parseDouble(10), equals(10.0));
      expect(SafeParser.parseDouble(15.5), equals(15.5));
      expect(SafeParser.parseDouble('99.9'), equals(99.9));
      expect(SafeParser.parseDouble('bad'), isNull);
    });

    test('parseBool handles bool, int, string', () {
      expect(SafeParser.parseBool(null), isNull);
      expect(SafeParser.parseBool(true), isTrue);
      expect(SafeParser.parseBool(false), isFalse);
      expect(SafeParser.parseBool(1), isTrue);
      expect(SafeParser.parseBool(0), isFalse);
      expect(SafeParser.parseBool('true'), isTrue);
      expect(SafeParser.parseBool('YES'), isTrue);
      expect(SafeParser.parseBool('0'), isFalse);
      expect(SafeParser.parseBool('unknown'), isNull);
    });

    test('parseStringList handles string and list', () {
      expect(SafeParser.parseStringList(null), isEmpty);
      expect(SafeParser.parseStringList(['a', 'b']), equals(['a', 'b']));
      expect(SafeParser.parseStringList('neon, avx, sse'), equals(['neon', 'avx', 'sse']));
    });
  });

  group('Validators Tests', () {
    test('clampPercentage clamps appropriately', () {
      expect(Validators.clampPercentage(null), isNull);
      expect(Validators.clampPercentage(-10.0), equals(0.0));
      expect(Validators.clampPercentage(50.5), equals(50.5));
      expect(Validators.clampPercentage(150.0), equals(100.0));
    });

    test('validateNonNegativeInt ensures non-negative numbers', () {
      expect(Validators.validateNonNegativeInt(null), isNull);
      expect(Validators.validateNonNegativeInt(-5), isNull);
      expect(Validators.validateNonNegativeInt(0), equals(0));
      expect(Validators.validateNonNegativeInt(1024), equals(1024));
    });
  });

  group('Converters Tests', () {
    test('formatBytes formats bytes correctly', () {
      expect(Converters.formatBytes(null), equals('N/A'));
      expect(Converters.formatBytes(0), equals('0 B'));
      expect(Converters.formatBytes(1024), equals('1.00 KB'));
      expect(Converters.formatBytes(1024 * 1024 * 1024 * 2), equals('2.00 GB'));
    });

    test('formatFrequency formats MHz to GHz or MHz', () {
      expect(Converters.formatFrequency(null), equals('N/A'));
      expect(Converters.formatFrequency(800.0), equals('800 MHz'));
      expect(Converters.formatFrequency(3200.0), equals('3.20 GHz'));
    });

    test('formatTemperature formats Celsius and Fahrenheit', () {
      expect(Converters.formatTemperature(null), equals('N/A'));
      expect(Converters.formatTemperature(25.0), equals('25.0 °C'));
      expect(Converters.formatTemperature(25.0, useFahrenheit: true), equals('77.0 °F'));
    });

    test('formatUptime formats seconds to readable string', () {
      expect(Converters.formatUptime(null), equals('N/A'));
      expect(Converters.formatUptime(3665), equals('1h 1m 5s'));
    });
  });
}
