import 'dart:math';
import '../models/calculation_models.dart';

class InterestCalculator {
  static const double defaultTaxRate = 0.154; // 15.4%

  static InterestCalculationResult calculateInterest(InterestCalculationInput input) {
    switch (input.accountType) {
      case AccountType.checking:
        return _calculateCheckingInterest(input);
      case AccountType.savings:
        return _calculateSavingsInterest(input);
    }
  }

  static InterestCalculationResult _calculateCheckingInterest(InterestCalculationInput input) {
    List<PeriodResult> periodResults = [];
    double totalPrincipal = input.monthlyDeposit * input.periodMonths;
    double totalInterest = 0;
    double interestRateDecimal = input.interestRate / 100;

    // Generate period-by-period results exactly matching original Kotlin SetCheckingInterest logic
    for (int month = 1; month <= input.periodMonths; month++) {
      double monthPrincipal = input.monthlyDeposit * month;
      double monthInterest = 0;
      
      // Calculate interest exactly as original Kotlin SetCheckingInterest does
      switch (input.interestType) {
        case InterestType.simple:
          // Original: amount * interest_rate * month / interest_type.value (where SIMPLE.value = 12)
          monthInterest = input.monthlyDeposit * interestRateDecimal * month / 12;
          break;
        case InterestType.compoundMonthly:
          // Original: amount * ((1+interest_rate/interest_type.value)^month - 1) (where COMPOUND_MONTHLY.value = 12)
          monthInterest = input.monthlyDeposit * (pow(1 + interestRateDecimal / 12, month) - 1);
          break;
        case InterestType.compoundDaily:
          // Original: amount * ((1+interest_rate/interest_type.value)^(month*30) - 1) (where COMPOUND_DAILY.value = 365)
          monthInterest = input.monthlyDeposit * (pow(1 + interestRateDecimal / 365, month * 30) - 1);
          break;
      }

      double monthlyInterestIncrement = month == 1 
          ? monthInterest 
          : monthInterest - (periodResults.isNotEmpty ? periodResults.last.cumulativeInterest : 0);

      periodResults.add(PeriodResult(
        period: month,
        principal: monthPrincipal,
        interest: monthlyInterestIncrement,
        cumulativeInterest: monthInterest,
        totalAmount: monthPrincipal + monthInterest,
      ));
    }

    // Final total interest is the last month's cumulative interest
    totalInterest = periodResults.isNotEmpty ? periodResults.last.cumulativeInterest : 0;

    double taxRate = _getTaxRate(input.taxType, input.customTaxRate);
    double taxAmount = totalInterest * taxRate;
    double finalAmount = totalPrincipal + totalInterest - taxAmount;

    return InterestCalculationResult(
      totalAmount: totalPrincipal + totalInterest,
      totalInterest: totalInterest,
      taxAmount: taxAmount,
      finalAmount: finalAmount,
      periodResults: periodResults,
    );
  }

  static InterestCalculationResult _calculateSavingsInterest(InterestCalculationInput input) {
    List<PeriodResult> periodResults = [];
    double principal = input.principal;
    double totalInterest = 0;

    switch (input.interestType) {
      case InterestType.simple:
        totalInterest = principal * (input.interestRate / 100) * (input.periodMonths / 12);
        break;
      case InterestType.compoundMonthly:
        double finalAmount = principal * pow(1 + (input.interestRate / 100 / 12), input.periodMonths);
        totalInterest = finalAmount - principal;
        break;
      case InterestType.compoundDaily:
        double finalAmount = principal * pow(1 + (input.interestRate / 100 / 365), input.periodMonths * 30);
        totalInterest = finalAmount - principal;
        break;
    }

    // Generate monthly breakdown
    for (int month = 1; month <= input.periodMonths; month++) {
      double cumulativeInterest = 0;
      
      switch (input.interestType) {
        case InterestType.simple:
          cumulativeInterest = principal * (input.interestRate / 100) * (month / 12);
          break;
        case InterestType.compoundMonthly:
          double currentAmount = principal * pow(1 + (input.interestRate / 100 / 12), month);
          cumulativeInterest = currentAmount - principal;
          break;
        case InterestType.compoundDaily:
          double currentAmount = principal * pow(1 + (input.interestRate / 100 / 365), month * 30);
          cumulativeInterest = currentAmount - principal;
          break;
      }

      double monthlyInterest = month == 1 
          ? cumulativeInterest 
          : cumulativeInterest - (periodResults.isNotEmpty ? periodResults.last.cumulativeInterest : 0);

      periodResults.add(PeriodResult(
        period: month,
        principal: principal,
        interest: monthlyInterest,
        cumulativeInterest: cumulativeInterest,
        totalAmount: principal + cumulativeInterest,
      ));
    }

    double taxRate = _getTaxRate(input.taxType, input.customTaxRate);
    double taxAmount = totalInterest * taxRate;
    double finalAmount = principal + totalInterest - taxAmount;

    return InterestCalculationResult(
      totalAmount: principal + totalInterest,
      totalInterest: totalInterest,
      taxAmount: taxAmount,
      finalAmount: finalAmount,
      periodResults: periodResults,
    );
  }

  static double _calculateSimpleInterest(double principal, double rate, int months) {
    return (principal * rate / 100 * months) / 12;
  }

  static double _calculateCompoundMonthlyInterest(double principal, double rate, int months) {
    return principal * (pow(1 + (rate / 100 / 12), months) - 1);
  }

  static double _calculateCompoundDailyInterest(double principal, double rate, int months) {
    int days = months * 30;
    return principal * (pow(1 + (rate / 100 / 365), days) - 1);
  }

  static double _getTaxRate(TaxType taxType, double customTaxRate) {
    switch (taxType) {
      case TaxType.normal:
        return defaultTaxRate;
      case TaxType.noTax:
        return 0.0;
      case TaxType.custom:
        return customTaxRate / 100;
    }
  }

  static int calculateNeedPeriodForGoal({
    required double targetAmount,
    required double monthlyDeposit,
    required double interestRate,
    required InterestType interestType,
    required AccountType accountType,
    double initialPrincipal = 0.0,
  }) {
    if (accountType == AccountType.savings) {
      if (initialPrincipal >= targetAmount) return 0;
      
      switch (interestType) {
        case InterestType.simple:
          return ((targetAmount - initialPrincipal) / (initialPrincipal * interestRate / 100 / 12)).ceil();
        case InterestType.compoundMonthly:
          return (log(targetAmount / initialPrincipal) / log(1 + (interestRate / 100 / 12))).ceil();
        case InterestType.compoundDaily:
          return (log(targetAmount / initialPrincipal) / log(1 + (interestRate / 100 / 365)) / 30).ceil();
      }
    } else {
      for (int months = 1; months <= 1200; months++) {
        var input = InterestCalculationInput(
          principal: initialPrincipal,
          interestRate: interestRate,
          periodMonths: months,
          interestType: interestType,
          accountType: accountType,
          taxType: TaxType.noTax,
          monthlyDeposit: monthlyDeposit,
        );
        
        var result = calculateInterest(input);
        if (result.totalAmount >= targetAmount) {
          return months;
        }
      }
    }
    return -1;
  }

  static double calculateNeedAmountForGoal({
    required double targetAmount,
    required int periodMonths,
    required double interestRate,
    required InterestType interestType,
    required AccountType accountType,
  }) {
    if (accountType == AccountType.savings) {
      switch (interestType) {
        case InterestType.simple:
          return targetAmount / (1 + (interestRate / 100 * periodMonths / 12));
        case InterestType.compoundMonthly:
          return targetAmount / pow(1 + (interestRate / 100 / 12), periodMonths);
        case InterestType.compoundDaily:
          return targetAmount / pow(1 + (interestRate / 100 / 365), periodMonths * 30);
      }
    } else {
      double low = 1000;
      double high = targetAmount;
      
      while (high - low > 1) {
        double mid = (low + high) / 2;
        
        var input = InterestCalculationInput(
          principal: 0,
          interestRate: interestRate,
          periodMonths: periodMonths,
          interestType: interestType,
          accountType: accountType,
          taxType: TaxType.noTax,
          monthlyDeposit: mid,
        );
        
        var result = calculateInterest(input);
        
        if (result.totalAmount >= targetAmount) {
          high = mid;
        } else {
          low = mid;
        }
      }
      
      return high;
    }
  }
}