import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final FocusNode? focusNode;

  const CustomInputField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.prefixIcon,
    this.suffixWidget,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppTheme.textSecondary)
                : null,
            suffix: suffixWidget,
          ),
        ),
      ],
    );
  }
}

class CurrencyInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(double)? onChanged;
  final bool enabled;
  final FocusNode? focusNode;

  const CurrencyInputField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<CurrencyInputField> createState() => _CurrencyInputFieldState();
}

class _CurrencyInputFieldState extends State<CurrencyInputField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
          validator: widget.validator,
          onChanged: (value) {
            if (widget.onChanged != null) {
              double amount = CurrencyFormatter.parseWon(value);
              widget.onChanged!(amount);
            }
          },
          enabled: widget.enabled,
          decoration: const InputDecoration(
            hintText: '0',
            suffixText: '원',
            prefixIcon: Icon(Icons.attach_money, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickAmountButtons(),
      ],
    );
  }

  Widget _buildQuickAmountButtons() {
    final amounts = [
      {'label': '1만원', 'value': 10000},
      {'label': '10만원', 'value': 100000},
      {'label': '50만원', 'value': 500000},
      {'label': '100만원', 'value': 1000000},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: amounts.map((amount) {
        return OutlinedButton(
          onPressed: widget.enabled ? () {
            final addValue = (amount['value'] as int).toDouble();
            final currentValue = CurrencyFormatter.parseWon(widget.controller.text);
            final newValue = currentValue + addValue;
            widget.controller.text = CurrencyFormatter.formatWon(newValue).replaceAll('원', '');
            if (widget.onChanged != null) {
              widget.onChanged!(newValue);
            }
          } : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            amount['label'] as String,
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }
}

class PercentInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(double)? onChanged;
  final bool enabled;
  final FocusNode? focusNode;

  const PercentInputField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<PercentInputField> createState() => _PercentInputFieldState();
}

class _PercentInputFieldState extends State<PercentInputField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: widget.validator,
          onChanged: (value) {
            if (widget.onChanged != null) {
              double percent = CurrencyFormatter.parsePercent(value);
              widget.onChanged!(percent);
            }
          },
          enabled: widget.enabled,
          decoration: const InputDecoration(
            hintText: '0.0',
            suffixText: '%',
            prefixIcon: Icon(Icons.percent, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickPercentButtons(),
      ],
    );
  }

  Widget _buildQuickPercentButtons() {
    final percents = [0.1, 1.0, 2.5, 5.0];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: percents.map((percent) {
        return OutlinedButton(
          onPressed: widget.enabled ? () {
            final currentValue = CurrencyFormatter.parsePercent(widget.controller.text);
            final newValue = currentValue + percent;
            // Round to 2 decimal places to avoid floating point precision issues
            final roundedValue = double.parse(newValue.toStringAsFixed(2));
            widget.controller.text = roundedValue.toString();
            if (widget.onChanged != null) {
              widget.onChanged!(roundedValue);
            }
          } : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '${percent}%',
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }
}

class PeriodInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(int)? onChanged;
  final bool enabled;
  final FocusNode? focusNode;

  const PeriodInputField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<PeriodInputField> createState() => _PeriodInputFieldState();
}

class _PeriodInputFieldState extends State<PeriodInputField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: widget.validator,
          onChanged: (value) {
            if (widget.onChanged != null) {
              int months = int.tryParse(value) ?? 0;
              widget.onChanged!(months);
            }
          },
          enabled: widget.enabled,
          decoration: const InputDecoration(
            hintText: '0',
            suffixText: '개월',
            prefixIcon: Icon(Icons.calendar_month, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickPeriodButtons(),
      ],
    );
  }

  Widget _buildQuickPeriodButtons() {
    final periods = [
      {'label': '1개월', 'value': 1},
      {'label': '6개월', 'value': 6},
      {'label': '12개월', 'value': 12},
      {'label': '24개월', 'value': 24},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: periods.map((period) {
        return OutlinedButton(
          onPressed: widget.enabled ? () {
            final addValue = period['value'] as int;
            final currentValue = int.tryParse(widget.controller.text) ?? 0;
            final newValue = currentValue + addValue;
            widget.controller.text = newValue.toString();
            if (widget.onChanged != null) {
              widget.onChanged!(newValue);
            }
          } : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            period['label'] as String,
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }
}

class NumberInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(double)? onChanged;
  final bool enabled;
  final String? suffix;

  const NumberInputField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.suffix,
  });

  @override
  State<NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<NumberInputField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: widget.validator,
          onChanged: (value) {
            if (widget.onChanged != null) {
              double number = CurrencyFormatter.parseNumber(value);
              widget.onChanged!(number);
            }
          },
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: '0',
            suffixText: widget.suffix,
            prefixIcon: const Icon(Icons.numbers, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    int value = int.parse(digitsOnly);
    String formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]},',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}