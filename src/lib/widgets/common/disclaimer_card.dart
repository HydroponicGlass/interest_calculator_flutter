import 'package:flutter/material.dart';

class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '계산 결과 안내',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• 본 앱의 계산 결과는 참고용으로, 실제 금융상품의 이자계산과 차이가 발생할 수 있습니다.\n'
            '• 금융기관별로 이자계산 방식, 세금처리, 수수료 등이 다를 수 있습니다.\n'
            '• 정확한 수익률과 조건은 해당 금융기관에 직접 확인하시기 바랍니다.\n'
            '• 본 계산 결과로 인한 어떠한 손실에 대해서도 책임지지 않습니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.orange.shade800,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}