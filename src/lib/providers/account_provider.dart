import 'package:flutter/foundation.dart';
import '../models/calculation_models.dart';
import '../services/database_service.dart';

class AccountProvider extends ChangeNotifier {
  List<MyAccount> _accounts = [];
  bool _isLoading = false;

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
    final endDate = DateTime(
      account.startDate.year,
      account.startDate.month + account.periodMonths,
      account.startDate.day,
    );
    final difference = endDate.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  double getCurrentBalance(MyAccount account) {
    final now = DateTime.now();
    final elapsedMonths = (now.difference(account.startDate).inDays / 30).floor();
    
    if (elapsedMonths <= 0) return account.principal;
    if (elapsedMonths >= account.periodMonths) {
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
      return calculateCurrentBalance(input, account.periodMonths);
    }

    final input = InterestCalculationInput(
      principal: account.principal,
      interestRate: account.interestRate,
      periodMonths: elapsedMonths,
      interestType: account.interestType,
      accountType: account.accountType,
      taxType: account.taxType,
      customTaxRate: account.customTaxRate,
      monthlyDeposit: account.monthlyDeposit,
    );
    return calculateCurrentBalance(input, elapsedMonths);
  }

  double calculateCurrentBalance(InterestCalculationInput input, int months) {
    if (input.accountType == AccountType.savings) {
      return input.principal;
    } else {
      return input.monthlyDeposit * months;
    }
  }
}