import 'package:flutter_test/flutter_test.dart';
import 'package:interestcalculator/models/calculation_models.dart';
import 'package:interestcalculator/services/interest_calculator.dart';
import 'dart:math';

void main() {
  group('Interest Calculator Tests', () {
    group('Checking Account Calculations', () {
      test('should calculate simple interest for checking account correctly', () {
        // Test case: 100,000원 월납입, 3% 연이율, 12개월, 단리
        final input = InterestCalculationInput(
          principal: 0,
          interestRate: 3.0,
          periodMonths: 12,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
          taxType: TaxType.noTax,
          monthlyDeposit: 100000,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Expected calculation:
        // Month 1: 100,000 * 3% * (12/12) = 3,000
        // Month 2: 100,000 * 3% * (11/12) = 2,750
        // ... 
        // Month 12: 100,000 * 3% * (1/12) = 250
        // Total interest should be: 19,500원
        
        expect(result.totalAmount - result.totalInterest, equals(1200000)); // Total principal
        expect(result.totalInterest, closeTo(19500, 100)); // Allow small deviation
        expect(result.taxAmount, equals(0)); // No tax
        expect(result.finalAmount, equals(result.totalAmount)); // No tax deduction
      });

      test('should calculate monthly compound interest for checking account correctly', () {
        // Test case: 50,000원 월납입, 2% 연이율, 24개월, 월복리
        final input = InterestCalculationInput(
          principal: 0,
          interestRate: 2.0,
          periodMonths: 24,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.checking,
          taxType: TaxType.noTax,
          monthlyDeposit: 50000,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.totalAmount - result.totalInterest, equals(1200000)); // Total principal
        expect(result.totalInterest, greaterThan(0));
        expect(result.totalInterest, lessThan(50000)); // Should be reasonable
      });

      test('should calculate monthly compound interest for checking account correctly', () {
        // Test case: 200,000원 월납입, 4% 연이율, 6개월, 월복리
        final input = InterestCalculationInput(
          principal: 0,
          interestRate: 4.0,
          periodMonths: 6,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.checking,
          taxType: TaxType.noTax,
          monthlyDeposit: 200000,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.totalAmount - result.totalInterest, equals(1200000)); // Total principal
        expect(result.totalInterest, greaterThan(0));
        expect(result.periodResults.length, equals(6));
      });

      test('should apply normal tax correctly for checking account', () {
        final input = InterestCalculationInput(
          principal: 0,
          interestRate: 5.0,
          periodMonths: 12,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
          taxType: TaxType.normal,
          monthlyDeposit: 100000,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Tax should be 15.4% of interest
        final expectedTax = result.totalInterest * 0.154;
        expect(result.taxAmount, closeTo(expectedTax, 1));
        expect(result.finalAmount, closeTo(result.totalAmount - expectedTax, 1));
      });

      test('should apply custom tax correctly for checking account', () {
        final input = InterestCalculationInput(
          principal: 0,
          interestRate: 3.5,
          periodMonths: 18,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.checking,
          taxType: TaxType.custom,
          customTaxRate: 20.0, // 20% custom tax
          monthlyDeposit: 150000,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Tax should be 20% of interest
        final expectedTax = result.totalInterest * 0.20;
        expect(result.taxAmount, closeTo(expectedTax, 1));
        expect(result.finalAmount, closeTo(result.totalAmount - expectedTax, 1));
      });
    });

    group('Savings Account Calculations', () {
      test('should calculate simple interest for savings account correctly', () {
        // Test case: 1,000,000원 원금, 3% 연이율, 12개월, 단리
        final input = InterestCalculationInput(
          principal: 1000000,
          interestRate: 3.0,
          periodMonths: 12,
          interestType: InterestType.simple,
          accountType: AccountType.savings,
          taxType: TaxType.noTax,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Expected: 1,000,000 * 3% * 1 year = 30,000원
        expect(result.totalAmount - result.totalInterest, equals(1000000)); // Principal
        expect(result.totalInterest, closeTo(30000, 10));
        expect(result.taxAmount, equals(0));
        expect(result.finalAmount, equals(result.totalAmount));
      });

      test('should calculate monthly compound interest for savings account correctly', () {
        // Test case: 5,000,000원 원금, 2.5% 연이율, 24개월, 월복리
        final input = InterestCalculationInput(
          principal: 5000000,
          interestRate: 2.5,
          periodMonths: 24,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
          taxType: TaxType.noTax,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Expected calculation using compound formula
        final expectedAmount = 5000000 * pow(1 + (2.5 / 100 / 12), 24);
        final expectedInterest = expectedAmount - 5000000;
        
        expect(result.totalAmount - result.totalInterest, equals(5000000));
        expect(result.totalInterest, closeTo(expectedInterest, 100));
      });

      test('should calculate monthly compound interest for savings account correctly', () {
        // Test case: 2,000,000원 원금, 4% 연이율, 36개월, 월복리
        final input = InterestCalculationInput(
          principal: 2000000,
          interestRate: 4.0,
          periodMonths: 36,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
          taxType: TaxType.noTax,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Expected calculation using monthly compound formula
        final expectedAmount = 2000000 * pow(1 + (4.0 / 100 / 12), 36);
        final expectedInterest = expectedAmount - 2000000;
        
        expect(result.totalAmount - result.totalInterest, equals(2000000));
        expect(result.totalInterest, closeTo(expectedInterest, 1000));
      });

      test('should generate correct period results for savings account', () {
        final input = InterestCalculationInput(
          principal: 1000000,
          interestRate: 3.0,
          periodMonths: 6,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
          taxType: TaxType.noTax,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.periodResults.length, equals(6));
        
        // Check first period
        expect(result.periodResults[0].period, equals(1));
        expect(result.periodResults[0].principal, equals(1000000));
        expect(result.periodResults[0].interest, greaterThan(0));
        
        // Check last period
        expect(result.periodResults[5].period, equals(6));
        expect(result.periodResults[5].cumulativeInterest, equals(result.totalInterest));
      });
    });

    group('Need Period Calculations', () {
      test('should calculate need period for checking account correctly', () {
        // Test case: 월납입 100,000원으로 1,500,000원 목표 달성
        final period = InterestCalculator.calculateNeedPeriodForGoal(
          targetAmount: 1500000,
          monthlyDeposit: 100000,
          interestRate: 3.0,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
        );
        
        expect(period, greaterThan(0));
        expect(period, lessThan(60)); // Should be reasonable (less than 5 years)
        
        // Verify by calculating with the returned period
        final verifyInput = InterestCalculationInput(
          principal: 0,
          interestRate: 3.0,
          periodMonths: period,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
          taxType: TaxType.noTax,
          monthlyDeposit: 100000,
        );
        
        final verifyResult = InterestCalculator.calculateInterest(verifyInput);
        expect(verifyResult.totalAmount, greaterThanOrEqualTo(1500000));
      });

      test('should calculate need period for savings account correctly', () {
        // Test case: 1,000,000원 원금으로 1,200,000원 목표 달성
        final period = InterestCalculator.calculateNeedPeriodForGoal(
          targetAmount: 1200000,
          monthlyDeposit: 0,
          interestRate: 4.0,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
          initialPrincipal: 1000000,
        );
        
        expect(period, greaterThan(0));
        expect(period, lessThan(120)); // Should be reasonable
      });

      test('should return -1 for impossible scenarios', () {
        // Test case: 매우 낮은 월납입으로 높은 목표 달성 시도
        final period = InterestCalculator.calculateNeedPeriodForGoal(
          targetAmount: 10000000,
          monthlyDeposit: 1000,
          interestRate: 0.1,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
        );
        
        expect(period, equals(-1));
      });
    });

    group('Need Amount Calculations', () {
      test('should calculate need amount for savings account correctly', () {
        // Test case: 24개월 후 2,000,000원 목표 달성 필요 원금
        final needAmount = InterestCalculator.calculateNeedAmountForGoal(
          targetAmount: 2000000,
          periodMonths: 24,
          interestRate: 3.0,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
        );
        
        expect(needAmount, greaterThan(0));
        expect(needAmount, lessThan(2000000)); // Should be less than target
        
        // Verify by calculating with the returned amount
        final verifyInput = InterestCalculationInput(
          principal: needAmount,
          interestRate: 3.0,
          periodMonths: 24,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
          taxType: TaxType.noTax,
          monthlyDeposit: 0,
        );
        
        final verifyResult = InterestCalculator.calculateInterest(verifyInput);
        expect(verifyResult.totalAmount, closeTo(2000000, 1000));
      });

      test('should calculate need amount for checking account correctly', () {
        // Test case: 12개월 후 1,500,000원 목표 달성 필요 월납입액
        final needAmount = InterestCalculator.calculateNeedAmountForGoal(
          targetAmount: 1500000,
          periodMonths: 12,
          interestRate: 2.5,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
        );
        
        expect(needAmount, greaterThan(0));
        expect(needAmount, lessThan(150000)); // Should be reasonable
        
        // Verify by calculating with the returned amount
        final verifyInput = InterestCalculationInput(
          principal: 0,
          interestRate: 2.5,
          periodMonths: 12,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
          taxType: TaxType.noTax,
          monthlyDeposit: needAmount,
        );
        
        final verifyResult = InterestCalculator.calculateInterest(verifyInput);
        expect(verifyResult.totalAmount, closeTo(1500000, 1000));
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('should handle zero interest rate', () {
        final input = InterestCalculationInput(
          principal: 1000000,
          interestRate: 0.0,
          periodMonths: 12,
          interestType: InterestType.simple,
          accountType: AccountType.savings,
          taxType: TaxType.noTax,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.totalInterest, equals(0));
        expect(result.taxAmount, equals(0));
        expect(result.finalAmount, equals(1000000));
      });

      test('should handle single month period', () {
        final input = InterestCalculationInput(
          principal: 0,
          interestRate: 5.0,
          periodMonths: 1,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
          taxType: TaxType.noTax,
          monthlyDeposit: 100000,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.periodResults.length, equals(1));
        expect(result.totalAmount - result.totalInterest, equals(100000));
      });

      test('should handle very high interest rate', () {
        final input = InterestCalculationInput(
          principal: 1000000,
          interestRate: 50.0, // 50% interest rate
          periodMonths: 12,
          interestType: InterestType.simple,
          accountType: AccountType.savings,
          taxType: TaxType.noTax,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.totalInterest, equals(500000)); // 50% of principal
        expect(result.finalAmount, equals(1500000));
      });

      test('should handle very long period', () {
        final input = InterestCalculationInput(
          principal: 1000000,
          interestRate: 3.0,
          periodMonths: 120, // 10 years
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
          taxType: TaxType.noTax,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.periodResults.length, equals(120));
        expect(result.totalInterest, greaterThan(0));
        expect(result.totalInterest, lessThan(result.totalAmount));
      });

      test('should handle maximum tax rate', () {
        final input = InterestCalculationInput(
          principal: 1000000,
          interestRate: 5.0,
          periodMonths: 12,
          interestType: InterestType.simple,
          accountType: AccountType.savings,
          taxType: TaxType.custom,
          customTaxRate: 100.0, // 100% tax
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.taxAmount, equals(result.totalInterest));
        expect(result.finalAmount, equals(result.totalAmount - result.totalInterest));
      });
    });

    group('Comparison with Expected Values', () {
      test('should match manual calculation for checking account simple interest', () {
        // Manual calculation test case:
        // 100,000원 월납입, 3.6% 연이율, 12개월, 단리
        final input = InterestCalculationInput(
          principal: 0,
          interestRate: 3.6,
          periodMonths: 12,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
          taxType: TaxType.noTax,
          monthlyDeposit: 100000,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Manual calculation:
        // Month 1: 100,000 * 3.6% * (12/12) = 3,600
        // Month 2: 100,000 * 3.6% * (11/12) = 3,300
        // Month 3: 100,000 * 3.6% * (10/12) = 3,000
        // ...
        // Month 12: 100,000 * 3.6% * (1/12) = 300
        // Total interest = 3,600 + 3,300 + 3,000 + 2,700 + 2,400 + 2,100 + 1,800 + 1,500 + 1,200 + 900 + 600 + 300 = 23,400
        
        expect(result.totalAmount - result.totalInterest, equals(1200000));
        expect(result.totalInterest, closeTo(23400, 50));
      });

      test('should match manual calculation for savings account compound interest', () {
        // Manual calculation test case:
        // 1,000,000원 원금, 2.4% 연이율, 24개월, 월복리
        final input = InterestCalculationInput(
          principal: 1000000,
          interestRate: 2.4,
          periodMonths: 24,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
          taxType: TaxType.noTax,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Manual calculation: 1,000,000 * (1 + 2.4%/12)^24
        final expectedAmount = 1000000 * pow(1 + (2.4 / 100 / 12), 24);
        final expectedInterest = expectedAmount - 1000000;
        
        expect(result.totalAmount - result.totalInterest, equals(1000000));
        expect(result.totalInterest, closeTo(expectedInterest, 10));
      });

      test('should match expected tax calculations', () {
        final input = InterestCalculationInput(
          principal: 5000000,
          interestRate: 4.0,
          periodMonths: 12,
          interestType: InterestType.simple,
          accountType: AccountType.savings,
          taxType: TaxType.normal,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Expected: 5,000,000 * 4% = 200,000 interest
        // Tax: 200,000 * 15.4% = 30,800
        // Final: 5,000,000 + 200,000 - 30,800 = 5,169,200
        
        expect(result.totalInterest, closeTo(200000, 100));
        expect(result.taxAmount, closeTo(30800, 100));
        expect(result.finalAmount, closeTo(5169200, 100));
      });
    });
  });
}