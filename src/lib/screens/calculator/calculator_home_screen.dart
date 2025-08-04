import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import 'checking_interest_screen.dart';
import 'savings_interest_screen.dart';
import 'checking_need_period_screen.dart';
import 'savings_need_period_screen.dart';
import 'savings_need_amount_screen.dart';
import 'checking_compare_screen.dart';
import 'savings_compare_screen.dart';
import 'checking_savings_compare_screen.dart';
import 'checking_transfer_screen.dart';

class CalculatorHomeScreen extends StatelessWidget {
  const CalculatorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('올인원 이자 계산기'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientCard(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '금융 계산의 모든 것',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '적금, 예금부터 비교 분석까지\n모든 이자 계산을 한 번에',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '계산 도구',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildCalculatorCard(
                      context,
                      icon: Icons.savings,
                      title: '적금 이자계산',
                      subtitle: '정기적금 수익 계산',
                      color: AppTheme.primaryColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckingInterestScreen()),
                      ),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.account_balance,
                      title: '예금 이자계산',
                      subtitle: '예금 수익 계산',
                      color: AppTheme.secondaryColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavingsInterestScreen()),
                      ),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.schedule,
                      title: '적금 필요기간',
                      subtitle: '목표금액 달성 기간',
                      color: AppTheme.accentColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckingNeedPeriodScreen()),
                      ),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.timer,
                      title: '예금 필요기간',
                      subtitle: '목표수익 달성 기간',
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavingsNeedPeriodScreen()),
                      ),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.attach_money,
                      title: '적금 목표수익\n필요 입금액',
                      subtitle: '목표수익을 위한 월간 필요입금액',
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavingsNeedAmountScreen()),
                      ),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.compare_arrows,
                      title: '적금 비교',
                      subtitle: '적금 상품 비교',
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckingCompareScreen()),
                      ),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.balance,
                      title: '예금 비교',
                      subtitle: '예금 상품 비교',
                      color: Colors.indigo,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavingsCompareScreen()),
                      ),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.analytics,
                      title: '적금vs예금',
                      subtitle: '적금과 예금 비교',
                      color: Colors.deepOrange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckingSavingsCompareScreen()),
                      ),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.swap_horiz,
                      title: '예금 갈아타기',
                      subtitle: '만기 전 다른 예금으로 변경시 이자 비교',
                      color: Colors.brown,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckingTransferScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms, delay: (100).ms)
      .slideY(begin: 0.2, end: 0);
  }
}