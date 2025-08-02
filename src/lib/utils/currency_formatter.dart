import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _wonFormatter = NumberFormat('#,###', 'ko_KR');
  static final NumberFormat _percentFormatter = NumberFormat('0.0#');

  static String formatWon(double amount) {
    if (amount == 0) return '0원';
    return '${_wonFormatter.format(amount)}원';
  }

  static String formatWonInput(double amount) {
    if (amount == 0) return '';
    return _wonFormatter.format(amount);
  }

  static String formatPercent(double percent) {
    // Round to 2 decimal places to avoid floating point precision issues
    double roundedPercent = double.parse(percent.toStringAsFixed(2));
    
    // Format without trailing zeros
    if (roundedPercent == roundedPercent.round()) {
      return '${roundedPercent.round()}%';
    } else {
      return '${_percentFormatter.format(roundedPercent)}%';
    }
  }

  static String formatPeriod(int months) {
    if (months < 12) {
      return '${months}개월';
    } else {
      int years = months ~/ 12;
      int remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '${years}년';
      } else {
        return '${years}년 ${remainingMonths}개월';
      }
    }
  }

  static double parseWon(String value) {
    String cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  static double parsePercent(String value) {
    String cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  static double parseNumber(String value) {
    String cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  static String getAccountTypeText(bool isChecking) {
    return isChecking ? '적금' : '예금';
  }

  static String getInterestTypeText(int interestType) {
    switch (interestType) {
      case 0: return '단리';
      case 1: return '월복리';
      case 2: return '일복리';
      default: return '단리';
    }
  }

  static String getTaxTypeText(int taxType) {
    switch (taxType) {
      case 0: return '일반과세 (15.4%)';
      case 1: return '비과세';
      case 2: return '사용자 설정';
      default: return '일반과세 (15.4%)';
    }
  }
}