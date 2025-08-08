import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logger/logger.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../providers/account_provider.dart';
import '../../models/calculation_models.dart';
import '../../services/interest_calculator.dart';
import '../../utils/currency_formatter.dart';
import 'add_account_screen.dart';
import 'account_detail_screen.dart';
import 'edit_account_screen.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
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

  @override
  void initState() {
    super.initState();
    _logger.i('💼 [내 계좌] 화면 초기화');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.i('💼 [내 계좌] 계좌 목록 로드 시작');
      context.read<AccountProvider>().loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('내 계좌'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddAccountScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Consumer<AccountProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (provider.accounts.isEmpty) {
              return _buildEmptyState();
            }

            return _buildAccountList(provider);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '등록된 계좌가 없습니다',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '첫 번째 계좌를 등록하고\n이자 수익을 관리해보세요',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddAccountScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('계좌 추가하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildAccountList(AccountProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientCard(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '전체 계좌 현황',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        '총 계좌 수',
                        '${provider.accounts.length}개',
                        Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        '만기시 총 수익',
                        _calculateTotalExpectedReturn(provider.accounts),
                        Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: provider.accounts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final account = provider.accounts[index];
                return _buildAccountCard(account, provider)
                    .animate(delay: (index * 100).ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.2, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _calculateTotalExpectedReturn(List<MyAccount> accounts) {
    _logger.d('💰 [내 계좌] 총 예상 수익 계산 시작 (계좌 수: ${accounts.length})');
    
    double total = 0;
    for (var account in accounts) {
      // 실제 이자 계산 엔진 사용
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
      final accountReturn = result.totalInterest - result.taxAmount; // 세후 이자수익
      
      if (account.accountType == AccountType.checking) {
        final totalDeposit = account.monthlyDeposit * account.periodMonths;
        _logger.d('📈 [적금] ${account.name}: 총납입${CurrencyFormatter.formatWon(totalDeposit)}, 세후수익${CurrencyFormatter.formatWon(accountReturn)} (${account.interestType == InterestType.simple ? "단리" : "월복리"}, 세금${CurrencyFormatter.formatWon(result.taxAmount)})');
      } else {
        _logger.d('📈 [예금] ${account.name}: 원금${CurrencyFormatter.formatWon(account.principal)}, 세후수익${CurrencyFormatter.formatWon(accountReturn)} (${account.interestType == InterestType.simple ? "단리" : "월복리"}, 세금${CurrencyFormatter.formatWon(result.taxAmount)})');
      }
      
      total += accountReturn;
    }
    
    _logger.i('💰 [내 계좌] 총 예상 수익 (세후): ${CurrencyFormatter.formatWon(total)}');
    return CurrencyFormatter.formatWon(total);
  }

  Widget _buildAccountCard(MyAccount account, AccountProvider provider) {
    final remainingDays = provider.getRemainingDays(account);
    final currentBalance = provider.getCurrentBalance(account);
    final currentInterest = provider.getCurrentAccruedInterest(account);
    final maturityDate = provider.getMaturityDate(account);
    final isExpired = remainingDays < 0;  // 만료일이 지나야 만료됨
    final isMaturityDay = remainingDays == 0;  // D-Day (만료 당일)
    final isFutureAccount = account.startDate.isAfter(DateTime.now());  // 미래 가입일
    
    // 만기시 예상 이자 계산
    final maturityInterestInput = InterestCalculationInput(
      principal: account.principal,
      interestRate: account.interestRate,
      periodMonths: account.periodMonths,
      interestType: account.interestType,
      accountType: account.accountType,
      taxType: account.taxType,
      customTaxRate: account.customTaxRate,
      monthlyDeposit: account.monthlyDeposit,
    );
    final maturityResult = InterestCalculator.calculateInterest(maturityInterestInput);
    final maturityInterest = maturityResult.totalInterest - maturityResult.taxAmount; // 세후 이자
    
    _logger.d('📊 [내 계좌] ${account.name} 카드 정보 - 잔액: ${CurrencyFormatter.formatWon(currentBalance)}, 이자: ${CurrencyFormatter.formatWon(currentInterest)}, 남은일수: ${remainingDays}일');

    return CustomCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountDetailScreen(account: account),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: account.accountType == AccountType.checking
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  account.accountType == AccountType.checking
                      ? Icons.savings
                      : Icons.account_balance,
                  color: account.accountType == AccountType.checking
                      ? AppTheme.primaryColor
                      : AppTheme.secondaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      account.bankName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _navigateToEditAccount(account);
                  } else if (value == 'delete') {
                    _showDeleteDialog(account, provider);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text('수정'),
                      ],
                    ),
                  ),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
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
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      CurrencyFormatter.formatWon(currentBalance),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '현재 누적이자',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      CurrencyFormatter.formatWon(currentInterest),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '만기시 이자 (세후)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      CurrencyFormatter.formatWon(maturityInterest),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '연 이자율',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      CurrencyFormatter.formatPercent(account.interestRate),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (account.earlyTerminationRate > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '중도해지이율',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        CurrencyFormatter.formatPercent(account.earlyTerminationRate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '오늘 해지시 예상이자',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        CurrencyFormatter.formatWon(provider.getEarlyTerminationInterest(account)),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '만료일',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${maturityDate.year}-${maturityDate.month.toString().padLeft(2, '0')}-${maturityDate.day.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isExpired ? Colors.red : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isFutureAccount 
                          ? '가입까지' 
                          : isExpired 
                              ? '상태' 
                              : '남은 기간',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      isFutureAccount 
                          ? 'D${remainingDays > 0 ? '+' : ''}${-remainingDays}일'
                          : isExpired 
                              ? '만료됨' 
                              : isMaturityDay 
                                  ? 'D-Day' 
                                  : 'D-${remainingDays}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isFutureAccount 
                            ? Colors.orange
                            : isExpired 
                                ? Colors.red 
                                : isMaturityDay 
                                    ? Colors.orange 
                                    : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
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


  void _navigateToEditAccount(MyAccount account) {
    _logger.i('✏️ [내 계좌] 계좌 수정 화면 이동: ${account.name}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAccountScreen(account: account),
      ),
    ).then((_) {
      _logger.i('🔄 [내 계좌] 수정 완료 후 계좌 목록 새로고침');
      context.read<AccountProvider>().loadAccounts();
    });
  }

  void _showDeleteDialog(MyAccount account, AccountProvider provider) {
    _logger.w('🗑️ [내 계좌] 계좌 삭제 다이얼로그 표시: ${account.name}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계좌 삭제'),
        content: Text('${account.name} 계좌를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              _logger.d('❌ [내 계좌] 계좌 삭제 취소');
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              try {
                _logger.w('🗑️ [내 계좌] 계좌 삭제 실행: ${account.name} (ID: ${account.id})');
                await provider.deleteAccount(account.id!);
                if (mounted) {
                  Navigator.pop(context);
                  _logger.i('✅ [내 계좌] 계좌 삭제 성공: ${account.name}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('계좌가 삭제되었습니다')),
                  );
                }
              } catch (e) {
                _logger.e('❌ [내 계좌] 계좌 삭제 실패: ${account.name}, 오류: $e');
                if (mounted) {
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