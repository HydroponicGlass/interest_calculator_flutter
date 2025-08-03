import '../models/calculation_models.dart';
import '../models/additional_info_models.dart';
import '../services/interest_calculator.dart';
import '../utils/currency_formatter.dart';

class AdditionalInfoService {
  static AdditionalInfoData generateAdditionalInfo(
    InterestCalculationInput input,
    InterestCalculationResult currentResult,
  ) {
    return AdditionalInfoData(
      accountTypeChangeDescription: _generateAccountTypeChangeDescription(input, currentResult),
      interestTypeChangeDescription: _generateInterestTypeChangeDescription(input, currentResult),
      amountVariations: _generateAmountVariations(input, currentResult),
      periodVariations: _generatePeriodVariations(input, currentResult),
      interestRateVariations: _generateInterestRateVariations(input, currentResult),
    );
  }

  static String _generateAccountTypeChangeDescription(
    InterestCalculationInput input,
    InterestCalculationResult currentResult,
  ) {
    late InterestCalculationInput alternativeInput;
    late InterestCalculationResult alternativeResult;
    
    if (input.accountType == AccountType.checking) {
      // 적금 → 예금으로 변경
      final totalAmount = input.monthlyDeposit * input.periodMonths;
      alternativeInput = input.copyWith(
        accountType: AccountType.savings,
        principal: totalAmount,
        monthlyDeposit: 0,
      );
    } else {
      // 예금 → 적금으로 변경  
      final monthlyDeposit = input.principal / input.periodMonths;
      alternativeInput = input.copyWith(
        accountType: AccountType.checking,
        principal: 0,
        monthlyDeposit: monthlyDeposit,
      );
    }
    
    alternativeResult = InterestCalculator.calculateInterest(alternativeInput);
    
    final currentAfterTaxInterest = currentResult.totalInterest - currentResult.taxAmount;
    final alternativeAfterTaxInterest = alternativeResult.totalInterest - alternativeResult.taxAmount;
    final difference = alternativeAfterTaxInterest - currentAfterTaxInterest;
    
    final accountTypeName = input.accountType == AccountType.checking ? '적금' : '예금';
    final isIncrease = difference > 0;
    
    if (input.accountType == AccountType.checking) {
      // 적금 → 예금
      final totalAmount = input.monthlyDeposit * input.periodMonths;
      return '계좌 유형을 예금으로 변경 시:\n'
             '• 납입 방식: 월 ${CurrencyFormatter.formatWon(input.monthlyDeposit)}씩 ${input.periodMonths}개월 → ${CurrencyFormatter.formatWon(totalAmount)} 일시납입\n'
             '• 현재 세후이자: ${CurrencyFormatter.formatWon(currentAfterTaxInterest)}\n'
             '• 변경 후 세후이자: ${CurrencyFormatter.formatWon(alternativeAfterTaxInterest)}\n'
             '• 이자 차이: ${CurrencyFormatter.formatWon(difference.abs())} ${isIncrease ? '증가' : '감소'}';
    } else {
      // 예금 → 적금
      final monthlyDeposit = input.principal / input.periodMonths;
      return '계좌 유형을 적금으로 변경 시:\n'
             '• 납입 방식: ${CurrencyFormatter.formatWon(input.principal)} 일시납입 → 월 ${CurrencyFormatter.formatWon(monthlyDeposit)}씩 ${input.periodMonths}개월\n'
             '• 현재 세후이자: ${CurrencyFormatter.formatWon(currentAfterTaxInterest)}\n'
             '• 변경 후 세후이자: ${CurrencyFormatter.formatWon(alternativeAfterTaxInterest)}\n'
             '• 이자 차이: ${CurrencyFormatter.formatWon(difference.abs())} ${isIncrease ? '증가' : '감소'}';
    }
  }

  static String _generateInterestTypeChangeDescription(
    InterestCalculationInput input,
    InterestCalculationResult currentResult,
  ) {
    final alternativeInterestType = input.interestType == InterestType.simple 
        ? InterestType.compoundMonthly 
        : InterestType.simple;
    
    final alternativeInput = input.copyWith(interestType: alternativeInterestType);
    final alternativeResult = InterestCalculator.calculateInterest(alternativeInput);
    
    final currentAfterTaxInterest = currentResult.totalInterest - currentResult.taxAmount;
    final alternativeAfterTaxInterest = alternativeResult.totalInterest - alternativeResult.taxAmount;
    final difference = alternativeAfterTaxInterest - currentAfterTaxInterest;
    
    final currentTypeName = input.interestType == InterestType.simple ? '단리' : '월복리';
    final alternativeTypeName = alternativeInterestType == InterestType.simple ? '단리' : '월복리';
    final isIncrease = difference > 0;
    
    return '이자 계산 방식을 $alternativeTypeName로 변경 시:\n'
           '• 현재 계산방식: $currentTypeName (세후이자: ${CurrencyFormatter.formatWon(currentAfterTaxInterest)})\n'
           '• 변경 후 계산방식: $alternativeTypeName (세후이자: ${CurrencyFormatter.formatWon(alternativeAfterTaxInterest)})\n'
           '• 이자 차이: ${CurrencyFormatter.formatWon(difference.abs())} ${isIncrease ? '증가' : '감소'}\n'
           '• 수익률 차이: ${((difference / currentAfterTaxInterest) * 100).toStringAsFixed(2)}% ${isIncrease ? '상승' : '하락'}';
  }

  static List<AdditionalInfoTableItem> _generateAmountVariations(
    InterestCalculationInput input,
    InterestCalculationResult currentResult,
  ) {
    final variations = <AdditionalInfoTableItem>[];
    final currentAfterTaxInterest = currentResult.totalInterest - currentResult.taxAmount;
    
    // 원본 앱 방식: 입력 금액에 따라 적절한 단위로 변화
    final baseAmount = input.accountType == AccountType.checking ? input.monthlyDeposit : input.principal;
    
    // 금액 단위 결정
    double unitAmount;
    if (baseAmount >= 10000000) { // 천만원 이상
      unitAmount = 10000000; // 천만원 단위
    } else if (baseAmount >= 1000000) { // 백만원 이상
      unitAmount = 1000000; // 백만원 단위
    } else if (baseAmount >= 100000) { // 십만원 이상
      unitAmount = 100000; // 십만원 단위
    } else if (baseAmount >= 10000) { // 만원 이상
      unitAmount = 10000; // 만원 단위
    } else {
      unitAmount = 1000; // 천원 단위
    }
    
    final baseUnit = (baseAmount / unitAmount).round();
    final amounts = [
      (baseUnit - 1) * unitAmount,
      baseUnit * unitAmount,
      (baseUnit + 1) * unitAmount,
      (baseUnit + 2) * unitAmount,
      (baseUnit + 3) * unitAmount,
    ];
    
    for (final newAmount in amounts) {
      if (newAmount <= 0) continue;
      
      late InterestCalculationInput newInput;
      if (input.accountType == AccountType.checking) {
        newInput = input.copyWith(monthlyDeposit: newAmount);
      } else {
        newInput = input.copyWith(principal: newAmount);
      }
      
      final newResult = InterestCalculator.calculateInterest(newInput);
      final newAfterTaxInterest = newResult.totalInterest - newResult.taxAmount;
      final afterTaxOffset = newAfterTaxInterest - currentAfterTaxInterest;
      final beforeTaxOffset = newResult.totalInterest - currentResult.totalInterest;
      
      variations.add(AdditionalInfoTableItem(
        parameter: CurrencyFormatter.formatWon(newAmount),
        beforeTaxInterestOffset: beforeTaxOffset == 0 ? '0' : CurrencyFormatter.formatWon(beforeTaxOffset),
        afterTaxInterestOffset: afterTaxOffset == 0 ? '0' : CurrencyFormatter.formatWon(afterTaxOffset),
        beforeTaxInterest: CurrencyFormatter.formatWon(newResult.totalInterest),
        afterTaxInterest: CurrencyFormatter.formatWon(newAfterTaxInterest),
      ));
    }
    
    return variations;
  }

  static List<AdditionalInfoTableItem> _generatePeriodVariations(
    InterestCalculationInput input,
    InterestCalculationResult currentResult,
  ) {
    final variations = <AdditionalInfoTableItem>[];
    final currentAfterTaxInterest = currentResult.totalInterest - currentResult.taxAmount;
    
    // 기간 변화: ±12개월, ±24개월
    final periodOffsets = [-24, -12, 0, 12, 24];
    
    for (final offset in periodOffsets) {
      final newPeriod = input.periodMonths + offset;
      if (newPeriod <= 0) continue;
      
      final newInput = input.copyWith(periodMonths: newPeriod);
      final newResult = InterestCalculator.calculateInterest(newInput);
      final newAfterTaxInterest = newResult.totalInterest - newResult.taxAmount;
      final afterTaxOffset = newAfterTaxInterest - currentAfterTaxInterest;
      final beforeTaxOffset = newResult.totalInterest - currentResult.totalInterest;
      
      variations.add(AdditionalInfoTableItem(
        parameter: '${newPeriod}개월',
        beforeTaxInterestOffset: beforeTaxOffset == 0 ? '0' : CurrencyFormatter.formatWon(beforeTaxOffset),
        afterTaxInterestOffset: afterTaxOffset == 0 ? '0' : CurrencyFormatter.formatWon(afterTaxOffset),
        beforeTaxInterest: CurrencyFormatter.formatWon(newResult.totalInterest),
        afterTaxInterest: CurrencyFormatter.formatWon(newAfterTaxInterest),
      ));
    }
    
    return variations;
  }

  static List<AdditionalInfoTableItem> _generateInterestRateVariations(
    InterestCalculationInput input,
    InterestCalculationResult currentResult,
  ) {
    final variations = <AdditionalInfoTableItem>[];
    final currentAfterTaxInterest = currentResult.totalInterest - currentResult.taxAmount;
    
    // 이자율 변화: ±0.5%씩
    final rateOffsets = [-1.0, -0.5, 0.0, 0.5, 1.0];
    
    for (final offset in rateOffsets) {
      final newRate = input.interestRate + offset;
      if (newRate < 0) continue;
      
      final newInput = input.copyWith(interestRate: newRate);
      final newResult = InterestCalculator.calculateInterest(newInput);
      final newAfterTaxInterest = newResult.totalInterest - newResult.taxAmount;
      final afterTaxOffset = newAfterTaxInterest - currentAfterTaxInterest;
      final beforeTaxOffset = newResult.totalInterest - currentResult.totalInterest;
      
      variations.add(AdditionalInfoTableItem(
        parameter: '${newRate.toStringAsFixed(1)}%',
        beforeTaxInterestOffset: beforeTaxOffset == 0 ? '0' : CurrencyFormatter.formatWon(beforeTaxOffset),
        afterTaxInterestOffset: afterTaxOffset == 0 ? '0' : CurrencyFormatter.formatWon(afterTaxOffset),
        beforeTaxInterest: CurrencyFormatter.formatWon(newResult.totalInterest),
        afterTaxInterest: CurrencyFormatter.formatWon(newAfterTaxInterest),
      ));
    }
    
    return variations;
  }

  static double _getAmountOffsetValue(double amount) {
    if (amount == 0) return 10000; // 기본값
    
    var digitCount = 0;
    var tempAmount = amount;
    while (tempAmount >= 1) {
      tempAmount /= 10;
      digitCount++;
    }
    
    // 최상위 자릿수로 offset 결정
    return [1, 10, 100, 1000, 10000, 100000, 1000000, 10000000][digitCount - 2 >= 0 ? digitCount - 2 : 0].toDouble();
  }
}