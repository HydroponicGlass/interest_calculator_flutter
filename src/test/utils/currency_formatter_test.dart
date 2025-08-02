import 'package:flutter_test/flutter_test.dart';
import 'package:interestcalculator/utils/currency_formatter.dart';

void main() {
  group('Currency Formatter Tests', () {
    group('formatWon', () {
      test('should format zero correctly', () {
        expect(CurrencyFormatter.formatWon(0), equals('0원'));
      });

      test('should format small amounts correctly', () {
        expect(CurrencyFormatter.formatWon(100), equals('100원'));
        expect(CurrencyFormatter.formatWon(999), equals('999원'));
      });

      test('should format thousands with commas', () {
        expect(CurrencyFormatter.formatWon(1000), equals('1,000원'));
        expect(CurrencyFormatter.formatWon(10000), equals('10,000원'));
        expect(CurrencyFormatter.formatWon(100000), equals('100,000원'));
      });

      test('should format millions with commas', () {
        expect(CurrencyFormatter.formatWon(1000000), equals('1,000,000원'));
        expect(CurrencyFormatter.formatWon(10000000), equals('10,000,000원'));
        expect(CurrencyFormatter.formatWon(100000000), equals('100,000,000원'));
      });

      test('should format complex amounts correctly', () {
        expect(CurrencyFormatter.formatWon(1234567), equals('1,234,567원'));
        expect(CurrencyFormatter.formatWon(987654321), equals('987,654,321원'));
        expect(CurrencyFormatter.formatWon(123456789.5), equals('123,456,790원')); // Rounded
      });

      test('should handle decimal amounts by rounding', () {
        expect(CurrencyFormatter.formatWon(1234.5), equals('1,235원'));
        expect(CurrencyFormatter.formatWon(1234.4), equals('1,234원'));
        expect(CurrencyFormatter.formatWon(999.9), equals('1,000원'));
      });

      test('should handle negative amounts', () {
        expect(CurrencyFormatter.formatWon(-1000), equals('-1,000원'));
        expect(CurrencyFormatter.formatWon(-123456), equals('-123,456원'));
      });
    });

    group('formatPercent', () {
      test('should format zero percent correctly', () {
        expect(CurrencyFormatter.formatPercent(0), equals('0%'));
      });

      test('should format integer percentages correctly', () {
        expect(CurrencyFormatter.formatPercent(1), equals('1%'));
        expect(CurrencyFormatter.formatPercent(15), equals('15%'));
        expect(CurrencyFormatter.formatPercent(100), equals('100%'));
      });

      test('should format decimal percentages correctly', () {
        expect(CurrencyFormatter.formatPercent(2.5), equals('2.5%'));
        expect(CurrencyFormatter.formatPercent(15.4), equals('15.4%'));
        expect(CurrencyFormatter.formatPercent(0.1), equals('0.1%'));
      });

      test('should format percentages with trailing zeros', () {
        expect(CurrencyFormatter.formatPercent(3.0), equals('3%'));
        expect(CurrencyFormatter.formatPercent(15.50), equals('15.5%'));
        expect(CurrencyFormatter.formatPercent(100.00), equals('100%'));
      });

      test('should handle many decimal places', () {
        expect(CurrencyFormatter.formatPercent(3.14159), equals('3.14%'));
        expect(CurrencyFormatter.formatPercent(2.666666), equals('2.67%'));
      });

      test('should handle negative percentages', () {
        expect(CurrencyFormatter.formatPercent(-1.5), equals('-1.5%'));
        expect(CurrencyFormatter.formatPercent(-100), equals('-100%'));
      });
    });

    group('formatPeriod', () {
      test('should format months correctly', () {
        expect(CurrencyFormatter.formatPeriod(1), equals('1개월'));
        expect(CurrencyFormatter.formatPeriod(6), equals('6개월'));
        expect(CurrencyFormatter.formatPeriod(11), equals('11개월'));
      });

      test('should format full years correctly', () {
        expect(CurrencyFormatter.formatPeriod(12), equals('1년'));
        expect(CurrencyFormatter.formatPeriod(24), equals('2년'));
        expect(CurrencyFormatter.formatPeriod(60), equals('5년'));
      });

      test('should format years with remaining months correctly', () {
        expect(CurrencyFormatter.formatPeriod(13), equals('1년 1개월'));
        expect(CurrencyFormatter.formatPeriod(18), equals('1년 6개월'));
        expect(CurrencyFormatter.formatPeriod(25), equals('2년 1개월'));
        expect(CurrencyFormatter.formatPeriod(35), equals('2년 11개월'));
      });

      test('should handle edge cases', () {
        expect(CurrencyFormatter.formatPeriod(0), equals('0개월'));
        expect(CurrencyFormatter.formatPeriod(120), equals('10년'));
        expect(CurrencyFormatter.formatPeriod(121), equals('10년 1개월'));
      });
    });

    group('parseWon', () {
      test('should parse simple numbers correctly', () {
        expect(CurrencyFormatter.parseWon('100'), equals(100));
        expect(CurrencyFormatter.parseWon('1000'), equals(1000));
        expect(CurrencyFormatter.parseWon('123456'), equals(123456));
      });

      test('should parse numbers with commas correctly', () {
        expect(CurrencyFormatter.parseWon('1,000'), equals(1000));
        expect(CurrencyFormatter.parseWon('10,000'), equals(10000));
        expect(CurrencyFormatter.parseWon('1,000,000'), equals(1000000));
        expect(CurrencyFormatter.parseWon('1,234,567'), equals(1234567));
      });

      test('should parse numbers with won symbol correctly', () {
        expect(CurrencyFormatter.parseWon('100원'), equals(100));
        expect(CurrencyFormatter.parseWon('1,000원'), equals(1000));
        expect(CurrencyFormatter.parseWon('1,234,567원'), equals(1234567));
      });

      test('should handle decimal numbers correctly', () {
        expect(CurrencyFormatter.parseWon('100.5'), equals(100.5));
        expect(CurrencyFormatter.parseWon('1,000.75'), equals(1000.75));
      });

      test('should handle empty and invalid strings', () {
        expect(CurrencyFormatter.parseWon(''), equals(0));
        expect(CurrencyFormatter.parseWon('abc'), equals(0));
        expect(CurrencyFormatter.parseWon('원'), equals(0));
        expect(CurrencyFormatter.parseWon(','), equals(0));
      });

      test('should handle mixed valid and invalid characters', () {
        expect(CurrencyFormatter.parseWon('1,000abc원'), equals(1000));
        expect(CurrencyFormatter.parseWon('abc1,000원'), equals(1000));
        expect(CurrencyFormatter.parseWon('1,0a0b0'), equals(1000));
      });

      test('should handle whitespace', () {
        expect(CurrencyFormatter.parseWon(' 1,000 '), equals(1000));
        expect(CurrencyFormatter.parseWon('1 000'), equals(1000));
        expect(CurrencyFormatter.parseWon(' 1,000원 '), equals(1000));
      });
    });

    group('parsePercent', () {
      test('should parse simple percentages correctly', () {
        expect(CurrencyFormatter.parsePercent('5'), equals(5));
        expect(CurrencyFormatter.parsePercent('15'), equals(15));
        expect(CurrencyFormatter.parsePercent('100'), equals(100));
      });

      test('should parse decimal percentages correctly', () {
        expect(CurrencyFormatter.parsePercent('2.5'), equals(2.5));
        expect(CurrencyFormatter.parsePercent('15.4'), equals(15.4));
        expect(CurrencyFormatter.parsePercent('0.1'), equals(0.1));
      });

      test('should parse percentages with percent symbol correctly', () {
        expect(CurrencyFormatter.parsePercent('5%'), equals(5));
        expect(CurrencyFormatter.parsePercent('15.4%'), equals(15.4));
        expect(CurrencyFormatter.parsePercent('100%'), equals(100));
      });

      test('should handle empty and invalid strings', () {
        expect(CurrencyFormatter.parsePercent(''), equals(0));
        expect(CurrencyFormatter.parsePercent('abc'), equals(0));
        expect(CurrencyFormatter.parsePercent('%'), equals(0));
      });

      test('should handle mixed valid and invalid characters', () {
        expect(CurrencyFormatter.parsePercent('abc5%'), equals(5));
        expect(CurrencyFormatter.parsePercent('5.4abc%'), equals(5.4));
      });
    });

    group('parseNumber', () {
      test('should parse simple numbers correctly', () {
        expect(CurrencyFormatter.parseNumber('123'), equals(123));
        expect(CurrencyFormatter.parseNumber('456.78'), equals(456.78));
      });

      test('should parse numbers with various formats', () {
        expect(CurrencyFormatter.parseNumber('1,234'), equals(1234));
        expect(CurrencyFormatter.parseNumber('1234.5'), equals(1234.5));
        expect(CurrencyFormatter.parseNumber('0.123'), equals(0.123));
      });

      test('should handle empty and invalid strings', () {
        expect(CurrencyFormatter.parseNumber(''), equals(0));
        expect(CurrencyFormatter.parseNumber('abc'), equals(0));
        expect(CurrencyFormatter.parseNumber('!@#'), equals(0));
      });

      test('should handle mixed content', () {
        expect(CurrencyFormatter.parseNumber('abc123def'), equals(123));
        expect(CurrencyFormatter.parseNumber('12.34abc'), equals(12.34));
      });
    });

    group('getAccountTypeText', () {
      test('should return correct text for checking account', () {
        expect(CurrencyFormatter.getAccountTypeText(true), equals('적금'));
      });

      test('should return correct text for savings account', () {
        expect(CurrencyFormatter.getAccountTypeText(false), equals('예금'));
      });
    });

    group('getInterestTypeText', () {
      test('should return correct text for interest types', () {
        expect(CurrencyFormatter.getInterestTypeText(0), equals('단리'));
        expect(CurrencyFormatter.getInterestTypeText(1), equals('월복리'));
        expect(CurrencyFormatter.getInterestTypeText(2), equals('일복리'));
      });

      test('should return default for invalid index', () {
        expect(CurrencyFormatter.getInterestTypeText(-1), equals('단리'));
        expect(CurrencyFormatter.getInterestTypeText(3), equals('단리'));
        expect(CurrencyFormatter.getInterestTypeText(100), equals('단리'));
      });
    });

    group('getTaxTypeText', () {
      test('should return correct text for tax types', () {
        expect(CurrencyFormatter.getTaxTypeText(0), equals('일반과세 (15.4%)'));
        expect(CurrencyFormatter.getTaxTypeText(1), equals('비과세'));
        expect(CurrencyFormatter.getTaxTypeText(2), equals('사용자 설정'));
      });

      test('should return default for invalid index', () {
        expect(CurrencyFormatter.getTaxTypeText(-1), equals('일반과세 (15.4%)'));
        expect(CurrencyFormatter.getTaxTypeText(3), equals('일반과세 (15.4%)'));
        expect(CurrencyFormatter.getTaxTypeText(100), equals('일반과세 (15.4%)'));
      });
    });
  });

  group('Real-world Scenarios', () {
    test('should handle typical Korean financial amounts', () {
      // Test typical amounts used in Korea
      final testCases = [
        {'input': 10000.0, 'expected': '10,000원'},
        {'input': 50000.0, 'expected': '50,000원'},
        {'input': 100000.0, 'expected': '100,000원'},
        {'input': 500000.0, 'expected': '500,000원'},
        {'input': 1000000.0, 'expected': '1,000,000원'},
        {'input': 5000000.0, 'expected': '5,000,000원'},
        {'input': 10000000.0, 'expected': '10,000,000원'},
      ];

      for (final testCase in testCases) {
        expect(
          CurrencyFormatter.formatWon(testCase['input'] as double),
          equals(testCase['expected'] as String),
        );
      }
    });

    test('should handle typical Korean interest rates', () {
      // Test typical interest rates used in Korea
      final testCases = [
        {'input': 0.1, 'expected': '0.1%'},
        {'input': 1.0, 'expected': '1%'},
        {'input': 1.5, 'expected': '1.5%'},
        {'input': 2.0, 'expected': '2%'},
        {'input': 2.5, 'expected': '2.5%'},
        {'input': 3.0, 'expected': '3%'},
        {'input': 4.5, 'expected': '4.5%'},
        {'input': 5.0, 'expected': '5%'},
      ];

      for (final testCase in testCases) {
        expect(
          CurrencyFormatter.formatPercent(testCase['input'] as double),
          equals(testCase['expected'] as String),
        );
      }
    });

    test('should handle typical savings periods', () {
      // Test typical savings periods used in Korea
      final testCases = [
        {'input': 1, 'expected': '1개월'},
        {'input': 3, 'expected': '3개월'},
        {'input': 6, 'expected': '6개월'},
        {'input': 12, 'expected': '1년'},
        {'input': 18, 'expected': '1년 6개월'},
        {'input': 24, 'expected': '2년'},
        {'input': 36, 'expected': '3년'},
        {'input': 60, 'expected': '5년'},
      ];

      for (final testCase in testCases) {
        expect(
          CurrencyFormatter.formatPeriod(testCase['input'] as int),
          equals(testCase['expected'] as String),
        );
      }
    });

    test('should roundtrip format and parse correctly', () {
      // Test that formatting and parsing are consistent
      final testAmounts = [1000.0, 123456.0, 9876543.0, 50000.0, 100000.0];

      for (final amount in testAmounts) {
        final formatted = CurrencyFormatter.formatWon(amount);
        final parsed = CurrencyFormatter.parseWon(formatted);
        expect(parsed, equals(amount));
      }
    });

    test('should roundtrip percent format and parse correctly', () {
      // Test that percent formatting and parsing are consistent
      final testPercents = [1.0, 2.5, 15.4, 0.1, 5.0];

      for (final percent in testPercents) {
        final formatted = CurrencyFormatter.formatPercent(percent);
        final parsed = CurrencyFormatter.parsePercent(formatted);
        expect(parsed, equals(percent));
      }
    });
  });
}