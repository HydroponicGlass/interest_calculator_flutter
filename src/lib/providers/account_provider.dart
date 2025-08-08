import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/calculation_models.dart';
import '../services/database_service.dart';
import '../services/interest_calculator.dart';
import '../utils/currency_formatter.dart';

class AccountProvider extends ChangeNotifier {
  List<MyAccount> _accounts = [];
  bool _isLoading = false;
  
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  List<MyAccount> get accounts => _accounts;
  bool get isLoading => _isLoading;

  Future<void> loadAccounts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _accounts = await DatabaseService.getAccounts();
    } catch (e) {
      debugPrint('Error loading accounts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAccount(MyAccount account) async {
    try {
      final id = await DatabaseService.insertAccount(account);
      final newAccount = MyAccount(
        id: id,
        name: account.name,
        bankName: account.bankName,
        principal: account.principal,
        interestRate: account.interestRate,
        earlyTerminationRate: account.earlyTerminationRate,
        earlyTerminationInterestType: account.earlyTerminationInterestType,
        periodMonths: account.periodMonths,
        startDate: account.startDate,
        interestType: account.interestType,
        accountType: account.accountType,
        taxType: account.taxType,
        customTaxRate: account.customTaxRate,
        monthlyDeposit: account.monthlyDeposit,
      );
      _accounts.add(newAccount);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding account: $e');
      rethrow;
    }
  }

  Future<void> updateAccount(MyAccount account) async {
    try {
      await DatabaseService.updateAccount(account);
      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index >= 0) {
        _accounts[index] = account;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating account: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      await DatabaseService.deleteAccount(id);
      _accounts.removeWhere((account) => account.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  int getRemainingDays(MyAccount account) {
    final now = DateTime.now();
    
    // 정확한 만료일 계산: 시작일에서 정확히 periodMonths만큼 더함
    DateTime endDate = DateTime(account.startDate.year, account.startDate.month, account.startDate.day);
    
    // 월 단위로 정확히 계산
    int targetYear = endDate.year;
    int targetMonth = endDate.month + account.periodMonths;
    
    // 년도 조정
    while (targetMonth > 12) {
      targetYear += 1;
      targetMonth -= 12;
    }
    
    // 일자 조정 (해당 월의 마지막 일을 초과하지 않도록)
    int targetDay = account.startDate.day;
    final lastDayOfMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    if (targetDay > lastDayOfMonth) {
      targetDay = lastDayOfMonth;
    }
    
    endDate = DateTime(targetYear, targetMonth, targetDay);
    
    // 현재 날짜와 비교 (시간 제외)
    final today = DateTime(now.year, now.month, now.day);
    final maturityDate = DateTime(endDate.year, endDate.month, endDate.day);
    
    final difference = maturityDate.difference(today).inDays;
    
    // D-day 형식: 실제 남은 일수 계산 (음수면 만료됨을 나타내기 위해 그대로 반환)
    return difference;
  }

  double getCurrentBalance(MyAccount account) {
    final now = DateTime.now();
    final startDate = account.startDate;
    final maturityDate = getMaturityDate(account);
    
    // 미래 가입일인 경우
    if (now.isBefore(startDate)) {
      return account.accountType == AccountType.checking ? 0 : account.principal;
    }
    
    // 만료일을 넘은 경우
    if (now.isAfter(maturityDate)) {
      final input = InterestCalculationInput(
        principal: account.principal,
        interestRate: account.interestRate,
        periodMonths: account.periodMonths,
        interestType: account.interestType,
        accountType: account.accountType,
        taxType: account.taxType,
        customTaxRate: account.customTaxRate,
        monthlyDeposit: account.monthlyDeposit,
      );
      final result = InterestCalculator.calculateInterest(input);
      return result.totalAmount;
    }
    
    // 현재 시점의 잔액 계산
    if (account.accountType == AccountType.checking) {
      // 적금: 경과한 개월수만큼 납입된 금액
      final elapsedMonths = _getElapsedMonths(account);
      final depositedAmount = account.monthlyDeposit * elapsedMonths;
      final currentInterest = getCurrentAccruedInterest(account);
      return depositedAmount + currentInterest;
    } else {
      // 예금: 초기 원금 + 현재까지 발생한 이자
      final currentInterest = getCurrentAccruedInterest(account);
      return account.principal + currentInterest;
    }
  }

  double calculateCurrentBalance(InterestCalculationInput input, int months) {
    if (input.accountType == AccountType.savings) {
      return input.principal;
    } else {
      return input.monthlyDeposit * months;
    }
  }

  int _getElapsedMonths(MyAccount account) {
    final now = DateTime.now();
    final startDate = account.startDate;
    
    _logger.d('📅 [월수계산] ${account.name} - 시작일: ${startDate.year}-${startDate.month}-${startDate.day}, 현재: ${now.year}-${now.month}-${now.day}');
    
    int yearsDiff = now.year - startDate.year;
    int monthsDiff = now.month - startDate.month;
    
    int totalMonths = yearsDiff * 12 + monthsDiff;
    
    // 일자 비교하여 정확한 월수 계산
    if (now.day < startDate.day) {
      totalMonths -= 1;
      _logger.d('📅 [월수계산] ${account.name} - 일자 조정: 현재일(${now.day}) < 시작일(${startDate.day}), 월수 -1');
    }
    
    final finalMonths = totalMonths > 0 ? totalMonths : 0;
    _logger.d('📅 [월수계산] ${account.name} - 최종 경과월수: ${finalMonths}개월 (연차: ${yearsDiff}, 월차: ${monthsDiff})');
    
    return finalMonths;
  }

  double getCurrentAccruedInterest(MyAccount account) {
    final now = DateTime.now();
    final startDate = account.startDate;
    final maturityDate = getMaturityDate(account);
    
    // 미래 가입일인 경우
    if (now.isBefore(startDate)) {
      _logger.d('📊 [이자계산] ${account.name} - 미래 가입일이므로 이자 0 반환');
      return 0.0;
    }
    
    // 만료일을 넘은 경우
    if (now.isAfter(maturityDate)) {
      _logger.d('📊 [이자계산] ${account.name} - 만료일 경과, 만기 이자 반환');
      return _getMaturityInterest(account);
    }
    
    if (account.accountType == AccountType.checking) {
      // 적금: 매월 납입된 금액에 대해 각각의 이자를 계산
      return _calculateCheckingCurrentInterest(account, now);
    } else {
      // 예금: 전체 기간 기준 비례 계산
      return _calculateSavingsCurrentInterest(account, now, maturityDate, startDate);
    }
  }
  
  double _calculateCheckingCurrentInterest(MyAccount account, DateTime now) {
    double totalInterest = 0.0;
    final interestRateDecimal = account.interestRate / 100; // 연 이자율
    final monthlyRate = interestRateDecimal / 12; // 월 이자율
    
    _logger.d('📊 [적금이자] ${account.name} - 시작일: ${account.startDate}, 현재: ${now}, 연이자율: ${account.interestRate}%');
    
    // 이전 앱과 동일한 방식: 각 월별 납입에 대해 개별적으로 운용기간을 계산하여 이자 산출
    // 매월 16일에 납입했다고 가정하고, 각 납입금이 실제로 운용된 일수에 따라 이자 계산
    List<DateTime> depositDates = [];
    DateTime currentDepositDate = account.startDate;
    
    // 최대 periodMonths만큼의 납입일 계산
    for (int i = 0; i < account.periodMonths; i++) {
      if (currentDepositDate.isAfter(now)) break; // 미래 납입일은 제외
      depositDates.add(currentDepositDate);
      
      // 다음 월 같은 날짜로 설정
      if (currentDepositDate.month == 12) {
        currentDepositDate = DateTime(currentDepositDate.year + 1, 1, currentDepositDate.day);
      } else {
        try {
          currentDepositDate = DateTime(currentDepositDate.year, currentDepositDate.month + 1, currentDepositDate.day);
        } catch (ArgumentError) {
          // 월말 날짜 처리 (예: 1/31 -> 2/28)
          currentDepositDate = DateTime(currentDepositDate.year, currentDepositDate.month + 1, 
              DateTime(currentDepositDate.year, currentDepositDate.month + 2, 0).day);
        }
      }
    }
    
    _logger.d('📊 [적금이자] ${account.name} - 총 납입 횟수: ${depositDates.length}회');
    
    // 각 납입에 대해 개별 이자 계산
    for (int i = 0; i < depositDates.length; i++) {
      final depositDate = depositDates[i];
      final daysInvested = now.difference(depositDate).inDays;
      
      if (daysInvested <= 0) continue; // 아직 납입하지 않은 경우
      
      final monthsInvested = daysInvested / 30.0; // 30일 기준으로 월 계산
      double depositInterest = 0.0;
      
      if (account.interestType == InterestType.simple) {
        // 단리: amount * interest_rate * time
        depositInterest = account.monthlyDeposit * interestRateDecimal * monthsInvested / 12;
      } else {
        // 월복리: amount * ((1 + monthly_rate)^months - 1)
        depositInterest = account.monthlyDeposit * (pow(1 + monthlyRate, monthsInvested) - 1);
      }
      
      totalInterest += depositInterest;
      
      _logger.d('📊 [적금이자] ${account.name} - ${i+1}회차 납입(${depositDate.year}-${depositDate.month.toString().padLeft(2, '0')}-${depositDate.day.toString().padLeft(2, '0')}): ${daysInvested}일(${monthsInvested.toStringAsFixed(2)}개월) 운용, 이자 ${CurrencyFormatter.formatWon(depositInterest)}');
    }
    
    // 세후 이자 계산
    final taxRate = _getTaxRate(account);
    final tax = totalInterest * taxRate;
    final afterTaxInterest = totalInterest - tax;
    
    _logger.d('📊 [적금이자] ${account.name} - 세전이자: ${CurrencyFormatter.formatWon(totalInterest)}, 세금: ${CurrencyFormatter.formatWon(tax)}, 세후이자: ${CurrencyFormatter.formatWon(afterTaxInterest)}');
    
    return afterTaxInterest;
  }
  
  double _calculateSavingsCurrentInterest(MyAccount account, DateTime now, DateTime maturityDate, DateTime startDate) {
    // 예금: 전체 기간 기준 비례 계산
    final totalDays = maturityDate.difference(startDate).inDays;
    final elapsedDays = now.difference(startDate).inDays;
    
    _logger.d('📊 [예금이자] ${account.name} - 총기간: ${totalDays}일, 경과: ${elapsedDays}일 (${(elapsedDays / totalDays * 100).toStringAsFixed(1)}%)');
    
    if (elapsedDays <= 0) {
      _logger.d('📊 [예금이자] ${account.name} - 경과일수가 0 이하이므로 이자 0 반환');
      return 0.0;
    }
    
    // 만기 이자를 기준으로 비례 계산
    final maturityInterest = _getMaturityInterest(account);
    final currentInterest = maturityInterest * (elapsedDays / totalDays);
    
    _logger.d('📊 [예금이자] ${account.name} - 만기이자: ${CurrencyFormatter.formatWon(maturityInterest)}, 현재이자: ${CurrencyFormatter.formatWon(currentInterest)} (진행률: ${(elapsedDays / totalDays * 100).toStringAsFixed(1)}%)');
    
    return currentInterest;
  }
  
  double _getTaxRate(MyAccount account) {
    switch (account.taxType) {
      case TaxType.normal:
        return 0.154; // 15.4%
      case TaxType.noTax:
        return 0.0;
      case TaxType.custom:
        return account.customTaxRate / 100;
    }
  }
  
  double _getMaturityInterest(MyAccount account) {
    final input = InterestCalculationInput(
      principal: account.principal,
      interestRate: account.interestRate,
      periodMonths: account.periodMonths,
      interestType: account.interestType,
      accountType: account.accountType,
      taxType: account.taxType,
      customTaxRate: account.customTaxRate,
      monthlyDeposit: account.monthlyDeposit,
    );
    
    final result = InterestCalculator.calculateInterest(input);
    return result.totalInterest - result.taxAmount; // 세후 이자
  }

  DateTime getMaturityDate(MyAccount account) {
    final startDate = account.startDate;
    int targetYear = startDate.year;
    int targetMonth = startDate.month + account.periodMonths;
    
    while (targetMonth > 12) {
      targetYear += 1;
      targetMonth -= 12;
    }
    
    int targetDay = startDate.day;
    final lastDayOfMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    if (targetDay > lastDayOfMonth) {
      targetDay = lastDayOfMonth;
    }
    
    return DateTime(targetYear, targetMonth, targetDay);
  }
  
  /// 오늘 중도해지시 예상이자를 계산합니다
  double getEarlyTerminationInterest(MyAccount account) {
    final now = DateTime.now();
    final startDate = account.startDate;
    
    // 아직 시작하지 않은 계좌
    if (now.isBefore(startDate)) {
      _logger.d('📊 [중도해지] ${account.name} - 아직 시작하지 않은 계좌이므로 이자 0');
      return 0.0;
    }
    
    // 중도해지이율이 없는 경우 현재 누적이자와 동일
    if (account.earlyTerminationRate <= 0) {
      final currentInterest = getCurrentAccruedInterest(account);
      _logger.d('📊 [중도해지] ${account.name} - 중도해지이율 없음, 현재 누적이자 반환: ${CurrencyFormatter.formatWon(currentInterest)}');
      return currentInterest;
    }
    
    // 중도해지이율로 계산
    double earlyTerminationInterest = 0.0;
    final earlyTerminationRateDecimal = account.earlyTerminationRate / 100;
    final taxRate = _getTaxRate(account);
    
    if (account.accountType == AccountType.checking) {
      // 적금: 각 납입에 대해 중도해지이율로 계산
      final elapsedMonths = _getElapsedMonths(account);
      
      if (account.earlyTerminationInterestType == InterestType.simple) {
        // 단리 계산
        for (int i = 1; i <= elapsedMonths; i++) {
          final monthInterest = account.monthlyDeposit * earlyTerminationRateDecimal * i / 12;
          earlyTerminationInterest += monthInterest;
        }
      } else {
        // 월복리 계산
        final monthlyRate = earlyTerminationRateDecimal / 12;
        for (int i = 1; i <= elapsedMonths; i++) {
          final monthInterest = account.monthlyDeposit * (pow(1 + monthlyRate, i) - 1);
          earlyTerminationInterest += monthInterest;
        }
      }
      
      _logger.d('📊 [중도해지] ${account.name} - 적금 중도해지이자: ${elapsedMonths}개월, ${account.earlyTerminationInterestType == InterestType.simple ? "단리" : "월복리"}, 세전이자 ${CurrencyFormatter.formatWon(earlyTerminationInterest)}');
    } else {
      // 예금: 경과일수에 비례하여 중도해지이율로 계산
      final elapsedDays = now.difference(startDate).inDays;
      
      if (account.earlyTerminationInterestType == InterestType.simple) {
        // 단리 계산
        final yearlyInterest = account.principal * earlyTerminationRateDecimal;
        earlyTerminationInterest = yearlyInterest * (elapsedDays / 365.0);
      } else {
        // 월복리 계산 (일할계산)
        final dailyRate = earlyTerminationRateDecimal / 365;
        earlyTerminationInterest = account.principal * (pow(1 + dailyRate, elapsedDays) - 1);
      }
      
      _logger.d('📊 [중도해지] ${account.name} - 예금 중도해지이자: ${elapsedDays}일, ${account.earlyTerminationInterestType == InterestType.simple ? "단리" : "월복리"}, 세전이자 ${CurrencyFormatter.formatWon(earlyTerminationInterest)}');
    }
    
    // 세후 이자 계산
    final tax = earlyTerminationInterest * taxRate;
    final afterTaxInterest = earlyTerminationInterest - tax;
    
    _logger.d('📊 [중도해지] ${account.name} - 중도해지 세금: ${CurrencyFormatter.formatWon(tax)}, 세후이자: ${CurrencyFormatter.formatWon(afterTaxInterest)}');
    
    return afterTaxInterest;
  }
}