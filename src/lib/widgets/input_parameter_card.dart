import 'package:flutter/material.dart';
import '../models/calculation_models.dart';

class InputParameterCard extends StatelessWidget {
  final InterestCalculationInput input;

  const InputParameterCard({
    Key? key,
    required this.input,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '입력 내용',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3A59),
              ),
            ),
            const SizedBox(height: 16),
            _buildParameterTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.8),
      },
      children: [
        _buildTableRow('계좌 유형', _getAccountTypeText()),
        _buildTableRow('예치금액', _formatCurrency(input.principal)),
        if (input.accountType == AccountType.checking && input.monthlyDeposit > 0)
          _buildTableRow('월 납입액', _formatCurrency(input.monthlyDeposit)),
        _buildTableRow('기간', '${input.periodMonths}개월'),
        _buildTableRow('이자 유형', _getInterestTypeText()),
        _buildTableRow('이자율', '${input.interestRate}%'),
        _buildTableRow('세율', _getTaxRateText()),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E3A59),
            ),
          ),
        ),
      ],
    );
  }

  String _getAccountTypeText() {
    switch (input.accountType) {
      case AccountType.savings:
        return '예금';
      case AccountType.checking:
        return '적금';
    }
  }

  String _getInterestTypeText() {
    switch (input.interestType) {
      case InterestType.simple:
        return '단리';
      case InterestType.compoundMonthly:
        return '월복리';
    }
  }

  String _getTaxRateText() {
    switch (input.taxType) {
      case TaxType.normal:
        return '일반과세 (15.4%)';
      case TaxType.noTax:
        return '비과세';
      case TaxType.custom:
        return '사용자 정의 (${input.customTaxRate}%)';
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }
}