import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/ad_warning_text.dart';
import '../../providers/ad_provider.dart';
import 'checking_interest_screen.dart';
import 'savings_interest_screen.dart';
import 'checking_need_period_screen.dart';
import 'savings_need_period_screen.dart';
import 'savings_need_amount_screen.dart';
import 'checking_compare_screen.dart';
import 'savings_compare_screen.dart';
import 'checking_savings_compare_screen.dart';
import 'checking_transfer_screen.dart';

class CalculatorHomeScreen extends StatefulWidget {
  const CalculatorHomeScreen({super.key});

  @override
  State<CalculatorHomeScreen> createState() => _CalculatorHomeScreenState();
}

class _CalculatorHomeScreenState extends State<CalculatorHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize ad provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('올인원 이자계산기'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildCalculatorCard(
                      context,
                      icon: Icons.savings,
                      title: '적금 이자계산',
                      subtitle: '정기적금 수익 계산',
                      color: AppTheme.primaryColor,
                      screen: const CheckingInterestScreen(),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.account_balance,
                      title: '예금 이자계산',
                      subtitle: '예금 수익 계산',
                      color: AppTheme.secondaryColor,
                      screen: const SavingsInterestScreen(),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.schedule,
                      title: '적금 필요기간',
                      subtitle: '목표금액 달성 기간',
                      color: AppTheme.accentColor,
                      screen: const CheckingNeedPeriodScreen(),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.timer,
                      title: '예금 필요기간',
                      subtitle: '목표수익 달성 기간',
                      color: Colors.orange,
                      screen: const SavingsNeedPeriodScreen(),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.attach_money,
                      title: '적금 목표수익\n필요 입금액',
                      subtitle: '목표수익 달성을 위한\n월 필요입금액',
                      color: Colors.purple,
                      screen: const SavingsNeedAmountScreen(),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.compare_arrows,
                      title: '적금 비교',
                      subtitle: '적금 상품 비교',
                      color: Colors.teal,
                      screen: const CheckingCompareScreen(),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.balance,
                      title: '예금 비교',
                      subtitle: '예금 상품 비교',
                      color: Colors.indigo,
                      screen: const SavingsCompareScreen(),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.analytics,
                      title: '적금vs예금',
                      subtitle: '적금과 예금 비교',
                      color: Colors.deepOrange,
                      screen: const CheckingSavingsCompareScreen(),
                    ),
                    _buildCalculatorCard(
                      context,
                      icon: Icons.swap_horiz,
                      title: '예금 갈아타기',
                      subtitle: '만기 전 다른 예금으로 변경시 이자 비교',
                      color: Colors.brown,
                      screen: const CheckingTransferScreen(),
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

  /// Navigate to calculator screen
  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildCalculatorCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget screen,
  }) {
    return CustomCard(
          onTap: () => _navigateTo(screen),
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