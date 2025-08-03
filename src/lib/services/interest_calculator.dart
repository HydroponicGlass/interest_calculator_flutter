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

    // Calculate total interest using progressive monthly deposit logic
    // Each monthly deposit earns interest for the remaining months
    for (int depositMonth = 1; depositMonth <= input.periodMonths; depositMonth++) {
      int remainingMonths = input.periodMonths - depositMonth + 1;
      
      switch (input.interestType) {
        case InterestType.simple:
          totalInterest += input.monthlyDeposit * interestRateDecimal * (remainingMonths / 12);
          break;
        case InterestType.compoundMonthly:
          totalInterest += input.monthlyDeposit * (pow(1 + interestRateDecimal / 12, remainingMonths) - 1);
          break;
      }
    }

    // Generate period-by-period results showing progressive accumulation
    double accumulatedPrincipal = 0;
    double accumulatedInterest = 0;

    for (int month = 1; month <= input.periodMonths; month++) {
      accumulatedPrincipal += input.monthlyDeposit;
      
      // Calculate cumulative interest up to this month
      double monthCumulativeInterest = 0;
      for (int depositMonth = 1; depositMonth <= month; depositMonth++) {
        int remainingMonths = input.periodMonths - depositMonth + 1;
        
        switch (input.interestType) {
          case InterestType.simple:
            monthCumulativeInterest += input.monthlyDeposit * interestRateDecimal * (remainingMonths / 12);
            break;
          case InterestType.compoundMonthly:
            monthCumulativeInterest += input.monthlyDeposit * (pow(1 + interestRateDecimal / 12, remainingMonths) - 1);
            break;
        }
      }

      double monthlyInterestIncrement = month == 1 
          ? monthCumulativeInterest 
          : monthCumulativeInterest - accumulatedInterest;
      
      accumulatedInterest = monthCumulativeInterest;

      double taxRate = _getTaxRate(input.taxType, input.customTaxRate);
      double monthlyTax = monthlyInterestIncrement * taxRate;
      double afterTaxMonthlyInterest = monthlyInterestIncrement - monthlyTax;
      double cumulativeTax = accumulatedInterest * taxRate;
      double afterTaxCumulativeInterest = accumulatedInterest - cumulativeTax;
      
      periodResults.add(PeriodResult(
        period: month,
        principal: accumulatedPrincipal,
        interest: monthlyInterestIncrement,
        cumulativeInterest: accumulatedInterest,
        totalAmount: accumulatedPrincipal + accumulatedInterest,
        tax: cumulativeTax,
        afterTaxInterest: afterTaxMonthlyInterest,
        afterTaxCumulativeInterest: afterTaxCumulativeInterest,
        afterTaxTotalAmount: accumulatedPrincipal + afterTaxCumulativeInterest,
      ));
    }

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
      }

      double monthlyInterest = month == 1 
          ? cumulativeInterest 
          : cumulativeInterest - (periodResults.isNotEmpty ? periodResults.last.cumulativeInterest : 0);

      double taxRate = _getTaxRate(input.taxType, input.customTaxRate);
      double monthlyTax = monthlyInterest * taxRate;
      double afterTaxMonthlyInterest = monthlyInterest - monthlyTax;
      double cumulativeTax = cumulativeInterest * taxRate;
      double afterTaxCumulativeInterest = cumulativeInterest - cumulativeTax;
      
      periodResults.add(PeriodResult(
        period: month,
        principal: principal,
        interest: monthlyInterest,
        cumulativeInterest: cumulativeInterest,
        totalAmount: principal + cumulativeInterest,
        tax: cumulativeTax,
        afterTaxInterest: afterTaxMonthlyInterest,
        afterTaxCumulativeInterest: afterTaxCumulativeInterest,
        afterTaxTotalAmount: principal + afterTaxCumulativeInterest,
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