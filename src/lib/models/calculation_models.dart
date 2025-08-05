enum InterestType {
  simple,
  compoundMonthly,
}

enum AccountType {
  checking,
  savings,
}

enum TaxType {
  normal,
  noTax,
  custom,
}

enum CurrencyDenomination {
  won,
  thousand,
  tenThousand,
  million,
}

class InterestCalculationInput {
  final double principal;
  final double interestRate;
  final int periodMonths;
  final InterestType interestType;
  final AccountType accountType;
  final TaxType taxType;
  final double customTaxRate;
  final double monthlyDeposit;

  InterestCalculationInput({
    required this.principal,
    required this.interestRate,
    required this.periodMonths,
    required this.interestType,
    required this.accountType,
    required this.taxType,
    this.customTaxRate = 0.0,
    this.monthlyDeposit = 0.0,
  });

  InterestCalculationInput copyWith({
    double? principal,
    double? interestRate,
    int? periodMonths,
    InterestType? interestType,
    AccountType? accountType,
    TaxType? taxType,
    double? customTaxRate,
    double? monthlyDeposit,
  }) {
    return InterestCalculationInput(
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      periodMonths: periodMonths ?? this.periodMonths,
      interestType: interestType ?? this.interestType,
      accountType: accountType ?? this.accountType,
      taxType: taxType ?? this.taxType,
      customTaxRate: customTaxRate ?? this.customTaxRate,
      monthlyDeposit: monthlyDeposit ?? this.monthlyDeposit,
    );
  }
}

class InterestCalculationResult {
  final double totalAmount;
  final double totalInterest;
  final double taxAmount;
  final double finalAmount;
  final List<PeriodResult> periodResults;

  InterestCalculationResult({
    required this.totalAmount,
    required this.totalInterest,
    required this.taxAmount,
    required this.finalAmount,
    required this.periodResults,
  });
}

class PeriodResult {
  final int period;
  final double principal;
  final double interest;
  final double cumulativeInterest;
  final double totalAmount;
  final double tax;
  final double afterTaxInterest;
  final double afterTaxCumulativeInterest;
  final double afterTaxTotalAmount;

  PeriodResult({
    required this.period,
    required this.principal,
    required this.interest,
    required this.cumulativeInterest,
    required this.totalAmount,
    required this.tax,
    required this.afterTaxInterest,
    required this.afterTaxCumulativeInterest,
    required this.afterTaxTotalAmount,
  });
}

class PeriodCalculationResult {
  final int? requiredPeriod;
  final List<PeriodResult> monthlyResults;
  final double targetAmount;
  final double initialPrincipal;
  final bool achievable;

  PeriodCalculationResult({
    this.requiredPeriod,
    required this.monthlyResults,
    required this.targetAmount,
    required this.initialPrincipal,
    required this.achievable,
  });
}

class MyAccount {
  final int? id;
  final String name;
  final String bankName;
  final double principal;
  final double interestRate;
  final int periodMonths;
  final DateTime startDate;
  final InterestType interestType;
  final AccountType accountType;
  final TaxType taxType;
  final double customTaxRate;
  final double monthlyDeposit;

  MyAccount({
    this.id,
    required this.name,
    required this.bankName,
    required this.principal,
    required this.interestRate,
    required this.periodMonths,
    required this.startDate,
    required this.interestType,
    required this.accountType,
    required this.taxType,
    this.customTaxRate = 0.0,
    this.monthlyDeposit = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bankName': bankName,
      'principal': principal,
      'interestRate': interestRate,
      'periodMonths': periodMonths,
      'startDate': startDate.millisecondsSinceEpoch,
      'interestType': interestType.index,
      'accountType': accountType.index,
      'taxType': taxType.index,
      'customTaxRate': customTaxRate,
      'monthlyDeposit': monthlyDeposit,
    };
  }

  factory MyAccount.fromMap(Map<String, dynamic> map) {
    return MyAccount(
      id: map['id'],
      name: map['name'],
      bankName: map['bankName'],
      principal: map['principal'],
      interestRate: map['interestRate'],
      periodMonths: map['periodMonths'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      interestType: InterestType.values[map['interestType']],
      accountType: AccountType.values[map['accountType']],
      taxType: TaxType.values[map['taxType']],
      customTaxRate: map['customTaxRate'] ?? 0.0,
      monthlyDeposit: map['monthlyDeposit'] ?? 0.0,
    );
  }
}