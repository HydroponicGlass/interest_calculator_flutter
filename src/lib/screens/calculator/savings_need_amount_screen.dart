import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../models/calculation_models.dart';
import '../../services/interest_calculator.dart';
import '../../utils/currency_formatter.dart';

class SavingsNeedAmountScreen extends StatefulWidget {
  const SavingsNeedAmountScreen({super.key});

  @override
  State<SavingsNeedAmountScreen> createState() => _SavingsNeedAmountScreenState();
}

class _SavingsNeedAmountScreenState extends State<SavingsNeedAmountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetAmountController = TextEditingController();
  final _periodController = TextEditingController();
  final _interestRateController = TextEditingController();

  InterestType _interestType = InterestType.compoundMonthly;
  double? _resultAmount;
  bool _showResult = false;

  @override
  void dispose() {
    _targetAmountController.dispose();
    _periodController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final targetAmount = CurrencyFormatter.parseWon(_targetAmountController.text);
    final period = CurrencyFormatter.parseNumber(_periodController.text).toInt();
    final interestRate = CurrencyFormatter.parsePercent(_interestRateController.text);

    final requiredAmount = InterestCalculator.calculateNeedAmountForGoal(
      targetAmount: targetAmount,
      periodMonths: period,
      interestRate: interestRate,
      interestType: _interestType,
      accountType: AccountType.savings,
    );

    setState(() {
      _resultAmount = requiredAmount;
      _showResult = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('예금 필요금액'),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.attach_money,
                              color: Colors.purple,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '목표 설정',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CurrencyInputField(
                        label: '목표 금액',
                        controller: _targetAmountController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '목표 금액을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      NumberInputField(
                        label: '예치 기간 (월)',
                        controller: _periodController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '예치 기간을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      PercentInputField(
                        label: '연 이자율',
                        controller: _interestRateController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '연 이자율을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이자 계산 방식',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInterestTypeSelector(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '필요금액 계산하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_showResult && _resultAmount != null) ...[
                  const SizedBox(height: 24),
                  _buildResultSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterestTypeSelector() {
    return Column(
      children: InterestType.values.map((type) {
        String title = '';
        String subtitle = '';
        
        switch (type) {
          case InterestType.simple:
            title = '단리';
            subtitle = '이자에 대한 이자 없음';
            break;
          case InterestType.compoundMonthly:
            title = '월복리';
            subtitle = '매월 이자가 원금에 추가';
            break;
          case InterestType.compoundDaily:
            title = '일복리';
            subtitle = '매일 이자가 원금에 추가';
            break;
        }

        return RadioListTile<InterestType>(
          title: Text(title),
          subtitle: Text(subtitle),
          value: type,
          groupValue: _interestType,
          onChanged: (value) {
            setState(() {
              _interestType = value!;
            });
          },
          activeColor: Colors.purple,
        );
      }).toList(),
    );
  }

  Widget _buildResultSection() {
    if (_resultAmount == null || _resultAmount! <= 0) {
      return _buildErrorResult();
    }

    return Column(
      children: [
        _buildResultCard(),
        const SizedBox(height: 16),
        _buildDetailCard(),
      ],
    );
  }

  Widget _buildErrorResult() {
    return CustomCard(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 30,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '계산 불가',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '설정하신 조건으로는 계산이 어렵습니다.\n조건을 다시 확인해보세요.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return GradientCard(
      gradientColors: const [Colors.purple, Color(0xFF9C27B0)],
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '필요 원금',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatWon(_resultAmount!),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    final targetAmount = CurrencyFormatter.parseWon(_targetAmountController.text);
    final period = CurrencyFormatter.parseNumber(_periodController.text).toInt();
    final interestRate = CurrencyFormatter.parsePercent(_interestRateController.text);
    
    final expectedInterest = targetAmount - _resultAmount!;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상세 분석',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            '목표 금액',
            CurrencyFormatter.formatWon(targetAmount),
            Icons.flag,
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            '필요 원금',
            CurrencyFormatter.formatWon(_resultAmount!),
            Icons.account_balance_wallet,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            '예상 이자수익',
            CurrencyFormatter.formatWon(expectedInterest),
            Icons.trending_up,
            AppTheme.secondaryColor,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            '예치 기간',
            CurrencyFormatter.formatPeriod(period),
            Icons.schedule,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            '연 이자율',
            CurrencyFormatter.formatPercent(interestRate),
            Icons.percent,
            Colors.purple,
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
                const Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${CurrencyFormatter.formatWon(_resultAmount!)}을 ${period}개월간 예치하면 목표 달성이 가능합니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
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
}