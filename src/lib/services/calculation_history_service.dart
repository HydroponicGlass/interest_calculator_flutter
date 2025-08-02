import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/calculation_models.dart';

class CalculationHistoryService {
  static const String _savingsInputKey = 'last_savings_input';
  static const String _checkingInputKey = 'last_checking_input';
  static const String _savingsCompareKey = 'last_savings_compare';
  static const String _checkingCompareKey = 'last_checking_compare';
  static const String _checkingSavingsCompareKey = 'last_checking_savings_compare';
  static const String _checkingNeedPeriodKey = 'last_checking_need_period';
  static const String _savingsNeedAmountKey = 'last_savings_need_amount';
  static const String _savingsNeedPeriodKey = 'last_savings_need_period';
  static const String _checkingTransferKey = 'last_checking_transfer';

  static Future<void> saveLastSavingsInput(InterestCalculationInput input) async {
    final prefs = await SharedPreferences.getInstance();
    final inputJson = {
      'principal': input.principal,
      'interestRate': input.interestRate,
      'periodMonths': input.periodMonths,
      'interestType': input.interestType.index,
      'taxType': input.taxType.index,
      'customTaxRate': input.customTaxRate,
    };
    await prefs.setString(_savingsInputKey, json.encode(inputJson));
  }

  static Future<void> saveLastCheckingInput(InterestCalculationInput input) async {
    final prefs = await SharedPreferences.getInstance();
    final inputJson = {
      'monthlyDeposit': input.monthlyDeposit,
      'interestRate': input.interestRate,
      'periodMonths': input.periodMonths,
      'interestType': input.interestType.index,
      'taxType': input.taxType.index,
      'customTaxRate': input.customTaxRate,
    };
    await prefs.setString(_checkingInputKey, json.encode(inputJson));
  }

  static Future<void> saveLastSavingsCompareInput(Map<String, dynamic> compareData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savingsCompareKey, json.encode(compareData));
  }

  static Future<void> saveLastCheckingCompareInput(Map<String, dynamic> compareData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_checkingCompareKey, json.encode(compareData));
  }

  static Future<void> saveLastCheckingSavingsCompareInput(Map<String, dynamic> compareData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_checkingSavingsCompareKey, json.encode(compareData));
  }

  static Future<void> saveLastCheckingNeedPeriodInput(Map<String, dynamic> inputData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_checkingNeedPeriodKey, json.encode(inputData));
  }

  static Future<void> saveLastSavingsNeedAmountInput(Map<String, dynamic> inputData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savingsNeedAmountKey, json.encode(inputData));
  }

  static Future<void> saveLastSavingsNeedPeriodInput(Map<String, dynamic> inputData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savingsNeedPeriodKey, json.encode(inputData));
  }

  static Future<void> saveLastCheckingTransferInput(Map<String, dynamic> inputData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_checkingTransferKey, json.encode(inputData));
  }

  static Future<Map<String, dynamic>?> getLastSavingsInput() async {
    final prefs = await SharedPreferences.getInstance();
    final inputString = prefs.getString(_savingsInputKey);
    if (inputString != null) {
      try {
        final inputMap = json.decode(inputString) as Map<String, dynamic>;
        return {
          'principal': inputMap['principal']?.toDouble() ?? 0.0,
          'interestRate': inputMap['interestRate']?.toDouble() ?? 0.0,
          'periodMonths': inputMap['periodMonths']?.toInt() ?? 0,
          'interestType': InterestType.values[inputMap['interestType'] ?? 1],
          'taxType': TaxType.values[inputMap['taxType'] ?? 0],
          'customTaxRate': inputMap['customTaxRate']?.toDouble() ?? 0.0,
        };
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getLastCheckingInput() async {
    final prefs = await SharedPreferences.getInstance();
    final inputString = prefs.getString(_checkingInputKey);
    if (inputString != null) {
      try {
        final inputMap = json.decode(inputString) as Map<String, dynamic>;
        return {
          'monthlyDeposit': inputMap['monthlyDeposit']?.toDouble() ?? 0.0,
          'interestRate': inputMap['interestRate']?.toDouble() ?? 0.0,
          'periodMonths': inputMap['periodMonths']?.toInt() ?? 0,
          'interestType': InterestType.values[inputMap['interestType'] ?? 1],
          'taxType': TaxType.values[inputMap['taxType'] ?? 0],
          'customTaxRate': inputMap['customTaxRate']?.toDouble() ?? 0.0,
        };
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getLastSavingsCompareInput() async {
    final prefs = await SharedPreferences.getInstance();
    final inputString = prefs.getString(_savingsCompareKey);
    if (inputString != null) {
      try {
        return json.decode(inputString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getLastCheckingCompareInput() async {
    final prefs = await SharedPreferences.getInstance();
    final inputString = prefs.getString(_checkingCompareKey);
    if (inputString != null) {
      try {
        return json.decode(inputString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getLastCheckingSavingsCompareInput() async {
    final prefs = await SharedPreferences.getInstance();
    final inputString = prefs.getString(_checkingSavingsCompareKey);
    if (inputString != null) {
      try {
        return json.decode(inputString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getLastCheckingNeedPeriodInput() async {
    final prefs = await SharedPreferences.getInstance();
    final inputString = prefs.getString(_checkingNeedPeriodKey);
    if (inputString != null) {
      try {
        return json.decode(inputString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getLastSavingsNeedAmountInput() async {
    final prefs = await SharedPreferences.getInstance();
    final inputString = prefs.getString(_savingsNeedAmountKey);
    if (inputString != null) {
      try {
        return json.decode(inputString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getLastSavingsNeedPeriodInput() async {
    final prefs = await SharedPreferences.getInstance();
    final inputString = prefs.getString(_savingsNeedPeriodKey);
    if (inputString != null) {
      try {
        return json.decode(inputString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getLastCheckingTransferInput() async {
    final prefs = await SharedPreferences.getInstance();
    final inputString = prefs.getString(_checkingTransferKey);
    if (inputString != null) {
      try {
        return json.decode(inputString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savingsInputKey);
    await prefs.remove(_checkingInputKey);
    await prefs.remove(_savingsCompareKey);
    await prefs.remove(_checkingCompareKey);
    await prefs.remove(_checkingSavingsCompareKey);
    await prefs.remove(_checkingNeedPeriodKey);
    await prefs.remove(_savingsNeedAmountKey);
    await prefs.remove(_savingsNeedPeriodKey);
    await prefs.remove(_checkingTransferKey);
  }
}