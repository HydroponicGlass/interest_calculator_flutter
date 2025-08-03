import 'package:flutter/material.dart';
import 'common/custom_input_field.dart';

class QuickInputButtons extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final List<QuickInputValue> values;
  final String? Function(String?)? validator;

  const QuickInputButtons({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.values,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine input field type based on label and create custom fields without additional buttons
    Widget inputField;
    if (labelText.contains('금액') || labelText.contains('원금') || labelText.contains('납입')) {
      inputField = _buildCurrencyField();
    } else if (labelText.contains('이자율') || labelText.contains('수익률')) {
      inputField = _buildPercentField();
    } else if (labelText.contains('기간') || labelText.contains('개월') || labelText.contains('년')) {
      inputField = _buildPeriodField();
    } else {
      inputField = CustomInputField(
        label: labelText,
        controller: controller,
        validator: validator,
        keyboardType: TextInputType.number,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        inputField,
        const SizedBox(height: 12),
        _buildQuickButtons(),
      ],
    );
  }

  Widget _buildQuickButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: values.map((value) => _buildQuickButton(value)).toList(),
    );
  }

  Widget _buildQuickButton(QuickInputValue value) {
    if (value.isReset) {
      return OutlinedButton(
        onPressed: () => _onQuickButtonPressed(value),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          value.label,
          style: const TextStyle(fontSize: 12),
        ),
      );
    } else {
      return OutlinedButton(
        onPressed: () => _onQuickButtonPressed(value),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          value.label,
          style: const TextStyle(fontSize: 12),
        ),
      );
    }
  }

  void _onQuickButtonPressed(QuickInputValue value) {
    if (value.isReset) {
      controller.clear();
      return;
    }

    String currentText = controller.text.replaceAll(',', '');
    double currentValue = currentText.isEmpty ? 0 : double.tryParse(currentText) ?? 0;
    double newValue = currentValue + value.value;
    
    // Format based on field type
    String formattedValue;
    if (labelText.contains('이자율') || labelText.contains('수익률')) {
      // For percentage fields, keep decimal places
      formattedValue = _formatDecimalNumber(newValue);
    } else {
      // For amount/period fields, use integer with commas
      formattedValue = _formatNumberWithCommas(newValue.toInt());
    }
    controller.text = formattedValue;
  }

  String _formatNumberWithCommas(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDecimalNumber(double number) {
    // Handle floating point precision issues by rounding to reasonable decimal places
    double roundedNumber = double.parse(number.toStringAsFixed(2));
    
    // Convert to string and remove unnecessary trailing zeros
    String result = roundedNumber.toString();
    if (result.contains('.')) {
      result = result.replaceAll(RegExp(r'0*$'), '');
      result = result.replaceAll(RegExp(r'\.$'), '');
    }
    return result;
  }

  Widget _buildCurrencyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          validator: validator,
          decoration: const InputDecoration(
            hintText: '0',
            suffixText: '원',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPercentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: validator,
          decoration: const InputDecoration(
            hintText: '0.0',
            suffixText: '%',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          validator: validator,
          decoration: const InputDecoration(
            hintText: '0',
            suffixText: '개월',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class QuickInputValue {
  final String label;
  final double value;
  final bool isReset;

  const QuickInputValue({
    required this.label,
    required this.value,
    this.isReset = false,
  });
}

// Predefined quick input values
class QuickInputConstants {
  static const List<QuickInputValue> amountValues = [
    QuickInputValue(label: '1천', value: 1000),
    QuickInputValue(label: '1만', value: 10000),
    QuickInputValue(label: '10만', value: 100000),
    QuickInputValue(label: '100만', value: 1000000),
    QuickInputValue(label: '1천만', value: 10000000),
    QuickInputValue(label: '1억', value: 100000000),
    QuickInputValue(label: '초기화', value: 0, isReset: true),
  ];

  static const List<QuickInputValue> periodValues = [
    QuickInputValue(label: '6개월', value: 6),
    QuickInputValue(label: '12개월', value: 12),
    QuickInputValue(label: '24개월', value: 24),
    QuickInputValue(label: '초기화', value: 0, isReset: true),
  ];

  static const List<QuickInputValue> interestRateValues = [
    QuickInputValue(label: '0.1%', value: 0.1),
    QuickInputValue(label: '1%', value: 1.0),
    QuickInputValue(label: '5%', value: 5.0),
    QuickInputValue(label: '초기화', value: 0, isReset: true),
  ];
}