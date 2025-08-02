import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../models/calculation_models.dart';
import '../../providers/account_provider.dart';
import '../../services/interest_calculator.dart';
import '../../utils/currency_formatter.dart';
import 'edit_account_screen.dart';

class AccountDetailScreen extends StatelessWidget {
  final MyAccount account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(account.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditAccountScreen(account: account),
                ),
              );
            },
            icon: const Icon(Icons.edit),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('삭제'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAccountOverview(context),
              const SizedBox(height: 16),
              _buildCurrentStatus(context),
              const SizedBox(height: 16),
              _buildProjections(context),
              const SizedBox(height: 16),
              _buildAccountSettings(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountOverview(BuildContext context) {
    final provider = context.read<AccountProvider>();
    final remainingDays = provider.getRemainingDays(account);
    final currentBalance = provider.getCurrentBalance(account);
    final isExpired = remainingDays == 0;

    return GradientCard(
      gradientColors: account.accountType == AccountType.checking
          ? [AppTheme.primaryColor, const Color(0xFF8B5CF6)]
          : [AppTheme.secondaryColor, const Color(0xFF059669)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  account.accountType == AccountType.checking
                      ? Icons.savings
                      : Icons.account_balance,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      account.bankName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '현재 잔액',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          Text(
            CurrencyFormatter.formatWon(currentBalance),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  context,
                  '연 이자율',
                  CurrencyFormatter.formatPercent(account.interestRate),
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  context,
                  isExpired ? '만료됨' : '남은 기간',
                  isExpired ? '만료' : '${remainingDays}일',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStatus(BuildContext context) {
    final provider = context.read<AccountProvider>();
    final remainingDays = provider.getRemainingDays(account);
    final progressValue = remainingDays > 0 
        ? 1 - (remainingDays / (account.periodMonths * 30))
        : 1.0;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '진행 상황',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: AppTheme.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              account.accountType == AccountType.checking
                  ? AppTheme.primaryColor
                  : AppTheme.secondaryColor,
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '시작일',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${account.startDate.year}.${account.startDate.month.toString().padLeft(2, '0')}.${account.startDate.day.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '만료일',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _getMaturityDate(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '진행률: ${(progressValue * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjections(BuildContext context) {
    final input = InterestCalculationInput(
      principal: account.principal,
      interestRate: account.interestRate,
      periodMonths: account.periodMonths,
      interestType: account.interestType,
      accountType: account.accountType,
      taxType: account.taxType,
      customTaxRate: account.customTaxRate,
      monthlyDeposit: account.monthlyDeposit,
    );

    final result = InterestCalculator.calculateInterest(input);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '만기 예상 수익',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildProjectionRow(
            context,
            '총 원금',
            result.totalAmount - result.totalInterest,
            Icons.account_balance_wallet,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          _buildProjectionRow(
            context,
            '이자 수익',
            result.totalInterest,
            Icons.trending_up,
            AppTheme.secondaryColor,
          ),
          const SizedBox(height: 12),
          _buildProjectionRow(
            context,
            '세금',
            result.taxAmount,
            Icons.receipt,
            AppTheme.errorColor,
          ),
          const Divider(height: 24),
          _buildProjectionRow(
            context,
            '최종 수령액',
            result.finalAmount,
            Icons.payments,
            AppTheme.accentColor,
            isTotal: true,
          ),
          const SizedBox(height: 16),
          _buildEarningsChart(context, result),
        ],
      ),
    );
  }

  Widget _buildProjectionRow(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color, {
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          CurrencyFormatter.formatWon(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 18 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsChart(BuildContext context, InterestCalculationResult result) {
    final principal = result.totalAmount - result.totalInterest;
    final interest = result.totalInterest;
    
    return SizedBox(
      height: 150,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: principal,
              title: '${(principal / result.totalAmount * 100).toStringAsFixed(1)}%',
              color: AppTheme.primaryColor,
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value: interest,
              title: '${(interest / result.totalAmount * 100).toStringAsFixed(1)}%',
              color: AppTheme.secondaryColor,
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
          centerSpaceRadius: 30,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '계좌 설정',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingRow(
            context,
            '계좌 유형',
            CurrencyFormatter.getAccountTypeText(account.accountType == AccountType.checking),
            Icons.account_circle,
          ),
          const SizedBox(height: 12),
          _buildSettingRow(
            context,
            '이자 계산 방식',
            CurrencyFormatter.getInterestTypeText(account.interestType.index),
            Icons.calculate,
          ),
          const SizedBox(height: 12),
          _buildSettingRow(
            context,
            '세금 설정',
            CurrencyFormatter.getTaxTypeText(account.taxType.index),
            Icons.receipt_long,
          ),
          if (account.accountType == AccountType.checking) ...[
            const SizedBox(height: 12),
            _buildSettingRow(
              context,
              '월 납입금액',
              CurrencyFormatter.formatWon(account.monthlyDeposit),
              Icons.savings,
            ),
          ] else ...[
            const SizedBox(height: 12),
            _buildSettingRow(
              context,
              '초기 원금',
              CurrencyFormatter.formatWon(account.principal),
              Icons.account_balance,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.textSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getMaturityDate() {
    final maturityDate = DateTime(
      account.startDate.year,
      account.startDate.month + account.periodMonths,
      account.startDate.day,
    );
    return '${maturityDate.year}.${maturityDate.month.toString().padLeft(2, '0')}.${maturityDate.day.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계좌 삭제'),
        content: Text('${account.name} 계좌를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<AccountProvider>().deleteAccount(account.id!);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('계좌가 삭제되었습니다')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('삭제 중 오류가 발생했습니다')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}