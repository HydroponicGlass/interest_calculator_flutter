import 'package:flutter_test/flutter_test.dart';
import 'package:interestcalculator/models/calculation_models.dart';
import 'package:interestcalculator/services/interest_calculator.dart';
import 'dart:math';

/// This test suite contains real-world calculation scenarios to ensure
/// the Flutter implementation matches the original Android app calculations
void main() {
  group('Calculation Accuracy Tests - Matching Original Android App', () {
    group('Real Korean Banking Scenarios', () {
      test('KB 적금 상품 시뮬레이션 - 월 50만원, 2.5% 연이율, 24개월', () {
        final input = InterestCalculationInput(
          principal: 0,
          interestRate: 2.5,
          periodMonths: 24,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.checking,
          taxType: TaxType.normal, // 15.4% tax
          monthlyDeposit: 500000,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Expected calculations:
        // Total principal: 500,000 * 24 = 12,000,000
        // Interest calculation for monthly compound checking account
        final expectedPrincipal = 12000000.0;
        final expectedTaxRate = 0.154;
        
        expect(result.totalAmount - result.totalInterest, equals(expectedPrincipal));
        expect(result.taxAmount, equals(result.totalInterest * expectedTaxRate));
        expect(result.finalAmount, equals(result.totalAmount - result.taxAmount));
        expect(result.periodResults.length, equals(24));
      });

      test('신한은행 정기예금 시뮬레이션 - 1천만원, 3.2% 연이율, 12개월', () {
        final input = InterestCalculationInput(
          principal: 10000000,
          interestRate: 3.2,
          periodMonths: 12,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
          taxType: TaxType.normal,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Expected calculation for savings compound interest:
        // Final amount = 10,000,000 * (1 + 3.2%/12)^12
        final expectedAmount = 10000000 * pow(1 + (3.2 / 100 / 12), 12);
        final expectedInterest = expectedAmount - 10000000;
        final expectedTax = expectedInterest * 0.154;
        
        expect(result.totalAmount - result.totalInterest, equals(10000000));
        expect(result.totalInterest, closeTo(expectedInterest, 100));
        expect(result.taxAmount, closeTo(expectedTax, 10));
        expect(result.finalAmount, closeTo(expectedAmount - expectedTax, 100));
      });

      test('우리은행 적금 시뮬레이션 - 월 10만원, 2.8% 연이율, 36개월, 단리', () {
        final input = InterestCalculationInput(
          principal: 0,
          interestRate: 2.8,
          periodMonths: 36,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
          taxType: TaxType.normal,
          monthlyDeposit: 100000,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Manual calculation for simple interest checking:
        // Each monthly deposit earns interest for remaining months
        double expectedInterest = 0;
        for (int month = 1; month <= 36; month++) {
          int remainingMonths = 36 - month + 1;
          expectedInterest += 100000 * (2.8 / 100) * (remainingMonths / 12);
        }
        
        expect(result.totalAmount - result.totalInterest, equals(3600000));
        expect(result.totalInterest, closeTo(expectedInterest, 1000));
        expect(result.taxAmount, closeTo(expectedInterest * 0.154, 100));
      });

      test('하나은행 정기예금 시뮬레이션 - 5천만원, 2.1% 연이율, 6개월, 일복리', () {
        final input = InterestCalculationInput(
          principal: 50000000,
          interestRate: 2.1,
          periodMonths: 6,
          interestType: InterestType.compoundDaily,
          accountType: AccountType.savings,
          taxType: TaxType.normal,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Expected calculation for daily compound:
        // Final amount = 50,000,000 * (1 + 2.1%/365)^(6*30)
        final expectedAmount = 50000000 * pow(1 + (2.1 / 100 / 365), 6 * 30);
        final expectedInterest = expectedAmount - 50000000;
        
        expect(result.totalAmount - result.totalInterest, equals(50000000));
        expect(result.totalInterest, closeTo(expectedInterest, 1000));
      });
    });

    group('Tax Calculation Verification', () {
      test('일반과세 15.4% 정확성 검증', () {
        final input = InterestCalculationInput(
          principal: 10000000,
          interestRate: 4.0,
          periodMonths: 12,
          interestType: InterestType.simple,
          accountType: AccountType.savings,
          taxType: TaxType.normal,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Simple interest: 10,000,000 * 4% = 400,000
        // Tax: 400,000 * 15.4% = 61,600
        // Final: 10,000,000 + 400,000 - 61,600 = 10,338,400
        
        expect(result.totalInterest, equals(400000));
        expect(result.taxAmount, equals(61600));
        expect(result.finalAmount, equals(10338400));
      });

      test('비과세 계산 정확성 검증', () {
        final input = InterestCalculationInput(
          principal: 5000000,
          interestRate: 3.5,
          periodMonths: 24,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
          taxType: TaxType.noTax,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.taxAmount, equals(0));
        expect(result.finalAmount, equals(result.totalAmount));
      });

      test('사용자 정의 세율 20% 정확성 검증', () {
        final input = InterestCalculationInput(
          principal: 2000000,
          interestRate: 5.0,
          periodMonths: 12,
          interestType: InterestType.simple,
          accountType: AccountType.savings,
          taxType: TaxType.custom,
          customTaxRate: 20.0,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // Simple interest: 2,000,000 * 5% = 100,000
        // Custom tax: 100,000 * 20% = 20,000
        // Final: 2,000,000 + 100,000 - 20,000 = 2,080,000
        
        expect(result.totalInterest, equals(100000));
        expect(result.taxAmount, equals(20000));
        expect(result.finalAmount, equals(2080000));
      });
    });

    group('Period Calculation Accuracy', () {
      test('적금 목표 달성 기간 계산 정확성', () {
        // 월 30만원 납입으로 1천만원 목표
        final period = InterestCalculator.calculateNeedPeriodForGoal(
          targetAmount: 10000000,
          monthlyDeposit: 300000,
          interestRate: 3.0,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.checking,
        );
        
        expect(period, greaterThan(0));
        expect(period, lessThan(40)); // Should be reasonable
        
        // Verify calculation
        final verifyInput = InterestCalculationInput(
          principal: 0,
          interestRate: 3.0,
          periodMonths: period,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.checking,
          taxType: TaxType.noTax,
          monthlyDeposit: 300000,
        );
        
        final verifyResult = InterestCalculator.calculateInterest(verifyInput);
        expect(verifyResult.totalAmount, greaterThanOrEqualTo(10000000));
      });

      test('예금 목표 달성 기간 계산 정확성', () {
        // 500만원으로 600만원 목표
        final period = InterestCalculator.calculateNeedPeriodForGoal(
          targetAmount: 6000000,
          monthlyDeposit: 0,
          interestRate: 4.0,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
          initialPrincipal: 5000000,
        );
        
        expect(period, greaterThan(0));
        expect(period, lessThan(60)); // Should be reasonable
      });
    });

    group('Amount Calculation Accuracy', () {
      test('예금 필요 원금 계산 정확성', () {
        // 12개월 후 1천만원 목표를 위한 필요 원금
        final needAmount = InterestCalculator.calculateNeedAmountForGoal(
          targetAmount: 10000000,
          periodMonths: 12,
          interestRate: 3.5,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
        );
        
        expect(needAmount, greaterThan(0));
        expect(needAmount, lessThan(10000000));
        
        // Verify calculation
        final verifyInput = InterestCalculationInput(
          principal: needAmount,
          interestRate: 3.5,
          periodMonths: 12,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
          taxType: TaxType.noTax,
          monthlyDeposit: 0,
        );
        
        final verifyResult = InterestCalculator.calculateInterest(verifyInput);
        expect(verifyResult.totalAmount, closeTo(10000000, 1000));
      });

      test('적금 필요 월납입액 계산 정확성', () {
        // 24개월 후 2천만원 목표를 위한 필요 월납입액
        final needAmount = InterestCalculator.calculateNeedAmountForGoal(
          targetAmount: 20000000,
          periodMonths: 24,
          interestRate: 2.8,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
        );
        
        expect(needAmount, greaterThan(0));
        expect(needAmount, lessThan(1000000)); // Should be reasonable
        
        // Verify calculation
        final verifyInput = InterestCalculationInput(
          principal: 0,
          interestRate: 2.8,
          periodMonths: 24,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
          taxType: TaxType.noTax,
          monthlyDeposit: needAmount,
        );
        
        final verifyResult = InterestCalculator.calculateInterest(verifyInput);
        expect(verifyResult.totalAmount, closeTo(20000000, 10000));
      });
    });

    group('Edge Cases in Real Banking', () {
      test('최소 가입 금액 시나리오 - 월 1만원 적금', () {
        final input = InterestCalculationInput(
          principal: 0,
          interestRate: 1.5,
          periodMonths: 12,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
          taxType: TaxType.normal,
          monthlyDeposit: 10000,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.totalAmount - result.totalInterest, equals(120000));
        expect(result.totalInterest, greaterThan(0));
        expect(result.taxAmount, greaterThan(0));
        expect(result.finalAmount, greaterThan(120000));
      });

      test('고액 예금 시나리오 - 10억원 예금', () {
        final input = InterestCalculationInput(
          principal: 1000000000, // 10억원
          interestRate: 2.0,
          periodMonths: 12,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
          taxType: TaxType.normal,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.totalAmount - result.totalInterest, equals(1000000000));
        expect(result.totalInterest, greaterThan(19000000)); // Should be around 20 million
        expect(result.totalInterest, lessThan(21000000));
        expect(result.taxAmount, greaterThan(0));
      });

      test('단기 예금 시나리오 - 1개월 예금', () {
        final input = InterestCalculationInput(
          principal: 5000000,
          interestRate: 3.0,
          periodMonths: 1,
          interestType: InterestType.simple,
          accountType: AccountType.savings,
          taxType: TaxType.normal,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        // 1 month simple interest: 5,000,000 * 3% / 12 = 12,500
        expect(result.totalInterest, closeTo(12500, 10));
        expect(result.periodResults.length, equals(1));
      });

      test('장기 적금 시나리오 - 5년 적금', () {
        final input = InterestCalculationInput(
          principal: 0,
          interestRate: 3.8,
          periodMonths: 60, // 5 years
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.checking,
          taxType: TaxType.normal,
          monthlyDeposit: 200000,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.totalAmount - result.totalInterest, equals(12000000)); // 60 * 200,000
        expect(result.totalInterest, greaterThan(1000000)); // Should have significant interest
        expect(result.periodResults.length, equals(60));
      });
    });

    group('Compound Interest Variations', () {
      test('단리 vs 월복리 vs 일복리 비교 - 동일 조건', () {
        final baseParams = {
          'principal': 10000000.0,
          'interestRate': 3.5,
          'periodMonths': 24,
          'accountType': AccountType.savings,
          'taxType': TaxType.noTax,
        };

        final simpleResult = InterestCalculator.calculateInterest(
          InterestCalculationInput(
            principal: baseParams['principal'] as double,
            interestRate: baseParams['interestRate'] as double,
            periodMonths: baseParams['periodMonths'] as int,
            interestType: InterestType.simple,
            accountType: baseParams['accountType'] as AccountType,
            taxType: baseParams['taxType'] as TaxType,
            monthlyDeposit: 0,
          ),
        );

        final monthlyCompoundResult = InterestCalculator.calculateInterest(
          InterestCalculationInput(
            principal: baseParams['principal'] as double,
            interestRate: baseParams['interestRate'] as double,
            periodMonths: baseParams['periodMonths'] as int,
            interestType: InterestType.compoundMonthly,
            accountType: baseParams['accountType'] as AccountType,
            taxType: baseParams['taxType'] as TaxType,
            monthlyDeposit: 0,
          ),
        );

        final dailyCompoundResult = InterestCalculator.calculateInterest(
          InterestCalculationInput(
            principal: baseParams['principal'] as double,
            interestRate: baseParams['interestRate'] as double,
            periodMonths: baseParams['periodMonths'] as int,
            interestType: InterestType.compoundDaily,
            accountType: baseParams['accountType'] as AccountType,
            taxType: baseParams['taxType'] as TaxType,
            monthlyDeposit: 0,
          ),
        );

        // Interest should be: Simple < Daily Compound < Monthly Compound
        // Daily compound is actually lower than monthly due to different compounding frequency
        expect(simpleResult.totalInterest, lessThan(dailyCompoundResult.totalInterest));
        expect(dailyCompoundResult.totalInterest, lessThan(monthlyCompoundResult.totalInterest));
        
        // Verify specific calculations
        // Simple: 10,000,000 * 3.5% * 2 = 700,000
        expect(simpleResult.totalInterest, closeTo(700000, 0.1));
        
        // Monthly compound: 10,000,000 * (1 + 3.5%/12)^24 - 10,000,000
        final expectedMonthlyCompound = 10000000 * pow(1 + (3.5 / 100 / 12), 24) - 10000000;
        expect(monthlyCompoundResult.totalInterest, closeTo(expectedMonthlyCompound, 100));
        
        // Daily compound should be slightly lower than monthly compound for this frequency
        expect(dailyCompoundResult.totalInterest, lessThan(expectedMonthlyCompound));
      });
    });

    group('Period Results Verification', () {
      test('적금 월별 결과 일관성 검증', () {
        final input = InterestCalculationInput(
          principal: 0,
          interestRate: 3.0,
          periodMonths: 6,
          interestType: InterestType.simple,
          accountType: AccountType.checking,
          taxType: TaxType.noTax,
          monthlyDeposit: 100000,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.periodResults.length, equals(6));
        
        // Check progressive principal accumulation
        for (int i = 0; i < result.periodResults.length; i++) {
          final period = result.periodResults[i];
          expect(period.period, equals(i + 1));
          expect(period.principal, equals((i + 1) * 100000));
          expect(period.interest, greaterThanOrEqualTo(0));
          expect(period.cumulativeInterest, greaterThanOrEqualTo(0));
          expect(period.totalAmount, equals(period.principal + period.cumulativeInterest));
          
          // Cumulative interest should not decrease
          if (i > 0) {
            expect(period.cumulativeInterest, 
                   greaterThanOrEqualTo(result.periodResults[i - 1].cumulativeInterest));
          }
        }
        
        // Last period cumulative interest should equal total interest
        expect(result.periodResults.last.cumulativeInterest, equals(result.totalInterest));
      });

      test('예금 월별 결과 일관성 검증', () {
        final input = InterestCalculationInput(
          principal: 1000000,
          interestRate: 2.4,
          periodMonths: 12,
          interestType: InterestType.compoundMonthly,
          accountType: AccountType.savings,
          taxType: TaxType.noTax,
          monthlyDeposit: 0,
        );

        final result = InterestCalculator.calculateInterest(input);
        
        expect(result.periodResults.length, equals(12));
        
        // Check that principal remains constant for savings
        for (final period in result.periodResults) {
          expect(period.principal, equals(1000000));
        }
        
        // Check compound growth pattern
        for (int i = 1; i < result.periodResults.length; i++) {
          final prevPeriod = result.periodResults[i - 1];
          final currPeriod = result.periodResults[i];
          
          // Cumulative interest should grow
          expect(currPeriod.cumulativeInterest, greaterThan(prevPeriod.cumulativeInterest));
          
          // Total amount should grow
          expect(currPeriod.totalAmount, greaterThan(prevPeriod.totalAmount));
        }
      });
    });
  });
}