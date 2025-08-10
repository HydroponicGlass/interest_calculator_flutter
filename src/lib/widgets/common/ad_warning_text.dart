import 'package:flutter/material.dart';

class AdWarningText extends StatelessWidget {
  final AdWarningType type;
  final bool show;

  const AdWarningText({
    super.key,
    required this.type,
    required this.show,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    String text;
    Color color;

    switch (type) {
      case AdWarningType.calculation:
        text = '다음 계산시 광고가 출력됩니다.';
        color = Colors.grey.shade600;
        break;
      case AdWarningType.account:
        text = '계좌 생성시 광고가 출력됩니다.';
        color = Colors.grey.shade600;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

enum AdWarningType {
  calculation,
  account,
}