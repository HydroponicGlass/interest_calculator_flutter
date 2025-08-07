import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:logger/logger.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../models/calculation_models.dart';
import '../../providers/account_provider.dart';
import '../../services/interest_calculator.dart';
import '../../utils/currency_formatter.dart';
import 'edit_account_screen.dart';

class AccountDetailScreen extends StatefulWidget {
  final MyAccount account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  // 디버깅용 로거
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  MyAccount? currentAccount;

  @override
  void initState() {
    super.initState();
    currentAccount = widget.account;
    _logger.i('🏦 [계좌 상세] 화면 초기화: ${currentAccount!.name} (${currentAccount!.bankName})');
    _logger.d('📊 [계좌 상세] 계좌 정보 - 유형: ${currentAccount!.accountType}, 이자율: ${currentAccount!.interestRate}%, 기간: ${currentAccount!.periodMonths}개월');
  }

  void _refreshAccountData() {
    final provider = context.read<AccountProvider>();
    final updatedAccount = provider.accounts.firstWhere(
      (account) => account.id == currentAccount!.id,
      orElse: () => currentAccount!,
    );
    
    if (mounted) {
      setState(() {
        currentAccount = updatedAccount;
      });
      _logger.i('🔄 [계좌 상세] 계좌 데이터 새로고침: ${currentAccount!.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentAccount == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('계좌 상세')),
        body: const Center(child: Text('계좌 정보를 불러올 수 없습니다.')),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(currentAccount!.name),
        actions: [
          IconButton(
            onPressed: () {
              _logger.i('✏️ [계좌 상세] 수정 버튼 클릭: ${currentAccount!.name}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditAccountScreen(account: currentAccount!),
                ),
              ).then((_) {
                // 수정 완료 후 돌아왔을 때 화면 새로고침
                _logger.i('🔄 [계좌 상세] 수정 완료 후 계좌 목록 및 상세 데이터 새로고침');
                context.read<AccountProvider>().loadAccounts().then((_) {
                  _refreshAccountData();
                });
              });
            },
            icon: const Icon(Icons.edit),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _logger.w('🗑️ [계좌 상세] 삭제 메뉴 선택: ${currentAccount!.name}');
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
              _buildAccountOverview(context, currentAccount!),
              const SizedBox(height: 16),
              _buildCurrentStatus(context, currentAccount!),
              const SizedBox(height: 16),
              _buildProjections(context, currentAccount!),
              const SizedBox(height: 16),
              _buildAccountSettings(context, currentAccount!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountOverview(BuildContext context, MyAccount account) {
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

  Widget _buildCurrentStatus(BuildContext context, MyAccount account) {
    final provider = context.read<AccountProvider>();
    final remainingDays = provider.getRemainingDays(account);
    final currentInterest = provider.getCurrentAccruedInterest(account);
    final currentBalance = provider.getCurrentBalance(account);
    final isFutureAccount = account.startDate.isAfter(DateTime.now());
    final progressValue = _calculateProgress(remainingDays);
    
    // 만기시 이자 계산
    final maturityInput = InterestCalculationInput(
      principal: account.principal,
      interestRate: account.interestRate,
      periodMonths: account.periodMonths,
      interestType: account.interestType,
      accountType: account.accountType,
      taxType: account.taxType,
      customTaxRate: account.customTaxRate,
      monthlyDeposit: account.monthlyDeposit,
    );
    final maturityResult = InterestCalculator.calculateInterest(maturityInput);
    final maturityInterest = maturityResult.totalInterest - maturityResult.taxAmount;
    
    _logger.d('💰 [계좌 상세] 현재 잔액: ${CurrencyFormatter.formatWon(currentBalance)}, 현재 누적이자: ${CurrencyFormatter.formatWon(currentInterest)}, 만기시 이자: ${CurrencyFormatter.formatWon(maturityInterest)}');

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
          if (!isFutureAccount)
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                account.accountType == AccountType.checking
                    ? AppTheme.primaryColor
                    : AppTheme.secondaryColor,
              ),
              minHeight: 8,
            )
          else
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '현재 잔액',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatWon(currentBalance),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '현재 누적이자',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatWon(currentInterest),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '만기시 이자 (세후)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatWon(maturityInterest),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (account.earlyTerminationRate > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '중도해지이율',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatPercent(account.earlyTerminationRate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isFutureAccount 
                            ? '가입까지 ${(-remainingDays).abs()}일 남음'
                            : '진행률: ${(progressValue * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isFutureAccount ? Colors.orange.shade700 : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProgress(int remainingDays) {
    if (remainingDays < 0) return 0.0; // 미래 가입일
    final totalDays = currentAccount!.periodMonths * 30;
    final elapsedDays = totalDays - remainingDays;
    final progress = elapsedDays / totalDays;
    return progress.clamp(0.0, 1.0);
  }

  Widget _buildProjections(BuildContext context, MyAccount account) {
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


  Widget _buildAccountSettings(BuildContext context, MyAccount account) {
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
      currentAccount!.startDate.year,
      currentAccount!.startDate.month + currentAccount!.periodMonths,
      currentAccount!.startDate.day,
    );
    return '${maturityDate.year}.${maturityDate.month.toString().padLeft(2, '0')}.${maturityDate.day.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(BuildContext context) {
    _logger.w('🗑️ [계좌 상세] 삭제 다이얼로그 표시: ${currentAccount!.name}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계좌 삭제'),
        content: Text('${currentAccount!.name} 계좌를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              _logger.d('❌ [계좌 상세] 삭제 취소');
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              try {
                _logger.w('🗑️ [계좌 상세] 계좌 삭제 실행: ${currentAccount!.name} (ID: ${currentAccount!.id})');
                await context.read<AccountProvider>().deleteAccount(currentAccount!.id!);
                if (context.mounted) {
                  _logger.i('✅ [계좌 상세] 계좌 삭제 성공: ${currentAccount!.name}');
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('계좌가 삭제되었습니다')),
                  );
                }
              } catch (e) {
                _logger.e('❌ [계좌 상세] 계좌 삭제 실패: ${currentAccount!.name}, 오류: $e');
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