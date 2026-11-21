import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance_flutter/core/formatters/money.dart';

void main() {
  group('VND amount handling', () {
    test('parses grouped and ungrouped whole amounts', () {
      expect(parseVnd('1.250.000'), 1250000);
      expect(parseVnd('1250000'), 1250000);
      expect(parseVnd('0', allowZero: true), 0);
    });

    test('rejects invalid text, negatives, and zero for transactions', () {
      expect(() => parseVnd('12abc'), throwsA(isA<FormatException>()));
      expect(() => parseVnd('-100'), throwsA(isA<FormatException>()));
      expect(() => parseVnd('0'), throwsA(isA<FormatException>()));
    });

    test('formats integer values in Vietnamese dong', () {
      expect(formatVnd(1250000), contains('1.250.000'));
      expect(formatVnd(1250000), contains('₫'));
    });
  });
}
