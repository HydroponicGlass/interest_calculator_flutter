import 'package:flutter/material.dart';
import '../models/calculation_models.dart';
import 'quick_input_buttons.dart';

class InterestRateInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final InterestType initialInterestType;
  final ValueChanged<InterestType> onInterestTypeChanged;
  final String? Function(String?)? validator;

  const InterestRateInputField({
    Key? key,
    required this.label,
    required this.controller,
    required this.initialInterestType,
    required this.onInterestTypeChanged,
    this.validator,
  }) : super(key: key);

  @override
  State<InterestRateInputField> createState() => _InterestRateInputFieldState();
}

class _InterestRateInputFieldState extends State<InterestRateInputField> {
  late InterestType _interestType;

  @override
  void initState() {
    super.initState();
    _interestType = widget.initialInterestType;
  }

  @override
  void didUpdateWidget(InterestRateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialInterestType != widget.initialInterestType) {
      setState(() {
        _interestType = widget.initialInterestType;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // 단리/월복리 선택
        Row(
          children: [
            Expanded(
              child: RadioListTile<InterestType>(
                title: const Text('단리'),
                value: InterestType.simple,
                groupValue: _interestType,
                onChanged: (value) {
                  setState(() {
                    _interestType = value!;
                  });
                  widget.onInterestTypeChanged(_interestType);
                },
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(
              child: RadioListTile<InterestType>(
                title: const Text('월복리'),
                value: InterestType.compoundMonthly,
                groupValue: _interestType,
                onChanged: (value) {
                  setState(() {
                    _interestType = value!;
                  });
                  widget.onInterestTypeChanged(_interestType);
                },
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // 이자율 입력 필드와 퀵 버튼
        QuickInputButtons(
          controller: widget.controller,
          labelText: '이자율',
          values: QuickInputConstants.interestRateValues,
          validator: widget.validator,
        ),
      ],
    );
  }
}