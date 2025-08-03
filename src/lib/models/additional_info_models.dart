class AdditionalInfoTableItem {
  final String parameter;
  final String beforeTaxInterestOffset;
  final String afterTaxInterestOffset;
  final String beforeTaxInterest;
  final String afterTaxInterest;

  AdditionalInfoTableItem({
    required this.parameter,
    required this.beforeTaxInterestOffset,
    required this.afterTaxInterestOffset,
    required this.beforeTaxInterest,
    required this.afterTaxInterest,
  });
}

class AdditionalInfoData {
  final String accountTypeChangeDescription;
  final String interestTypeChangeDescription;
  final List<AdditionalInfoTableItem> amountVariations;
  final List<AdditionalInfoTableItem> periodVariations;
  final List<AdditionalInfoTableItem> interestRateVariations;

  AdditionalInfoData({
    required this.accountTypeChangeDescription,
    required this.interestTypeChangeDescription,
    required this.amountVariations,
    required this.periodVariations,
    required this.interestRateVariations,
  });
}