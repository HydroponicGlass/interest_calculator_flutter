import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../models/calculation_models.dart';
import '../../services/interest_calculator.dart';
import '../../services/calculation_history_service.dart';
import '../../utils/currency_formatter.dart';

class CheckingNeedPeriodScreen extends StatefulWidget {
  const CheckingNeedPeriodScreen({super.key});

  @override
  State<CheckingNeedPeriodScreen> createState() => _CheckingNeedPeriodScreenState();
}

class _CheckingNeedPeriodScreenState extends State<CheckingNeedPeriodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _resultSectionKey = GlobalKey();
  final _targetAmountController = TextEditingController();
  final _monthlyDepositController = TextEditingController();
  final _interestRateController = TextEditingController();

  InterestType _interestType = InterestType.compoundMonthly;
  int? _resultPeriod;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _loadLastInput();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _targetAmountController.dispose();
    _monthlyDepositController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  void _loadLastInput() async {
    final lastInput = await CalculationHistoryService.getLastCheckingNeedPeriodInput();
    if (lastInput != null && mounted) {
      setState(() {
        if (lastInput['targetAmount'] != null && lastInput['targetAmount'] > 0) {
          _targetAmountController.text = CurrencyFormatter.formatWonInput(lastInput['targetAmount']);
        }
        if (lastInput['monthlyDeposit'] != null && lastInput['monthlyDeposit'] > 0) {
          _monthlyDepositController.text = CurrencyFormatter.formatWonInput(lastInput['monthlyDeposit']);
        }
        if (lastInput['interestRate'] != null && lastInput['interestRate'] > 0) {
          _interestRateController.text = lastInput['interestRate'].toString();
        }
        if (lastInput['interestType'] != null) {
          _interestType = InterestType.values[lastInput['interestType']];
        }
      });
    }
  }

  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final formContext = _formKey.currentContext;
      if (formContext != null) {
        final formRenderBox = formContext.findRenderObject() as RenderBox?;
        if (formRenderBox != null) {
          // Find the first TextFormField with an error
          void findFirstErrorField(Element element) {
            if (element.widget is TextFormField) {
              final textFormField = element.widget as TextFormField;
              final fieldState = element as StatefulElement;
              if (fieldState.state is FormFieldState) {
                final formFieldState = fieldState.state as FormFieldState;
                if (formFieldState.hasError) {
                  // Scroll to this field
                  Scrollable.ensureVisible(
                    element,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                  return;
                }
              }
            }
            element.visitChildren(findFirstErrorField);
          }
          formContext.visitChildElements(findFirstErrorField);
        }
      }
    });
  }

  void _calculate() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    final targetAmount = CurrencyFormatter.parseWon(_targetAmountController.text);
    final monthlyDeposit = CurrencyFormatter.parseWon(_monthlyDepositController.text);
    final interestRate = CurrencyFormatter.parsePercent(_interestRateController.text);

    final period = InterestCalculator.calculateNeedPeriodForGoal(
      targetAmount: targetAmount,
      monthlyDeposit: monthlyDeposit,
      interestRate: interestRate,
      interestType: _interestType,
      accountType: AccountType.checking,
    );

    // Save the inputs for next time
    final inputData = {
      'targetAmount': targetAmount,
      'monthlyDeposit': monthlyDeposit,
      'interestRate': interestRate,
      'interestType': _interestType.index,
    };
    await CalculationHistoryService.saveLastCheckingNeedPeriodInput(inputData);

    setState(() {
      _resultPeriod = period;
      _showResult = true;
    });

    // Scroll to results after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _resultSectionKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultSectionKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('적금 필요기간'),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SingleChildScrollView(
          controller: _scrollController,
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
                              color: AppTheme.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: AppTheme.accentColor,
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
                      CurrencyInputField(
                        label: '월 납입금액',
                        controller: _monthlyDepositController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '월 납입금액을 입력해주세요';
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
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '필요기간 계산하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_showResult && _resultPeriod != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    key: _resultSectionKey,
                    child: _buildResultSection(),
                  ),
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
          activeColor: AppTheme.accentColor,
        );
      }).toList(),
    );
  }

  Widget _buildResultSection() {
    if (_resultPeriod == null || _resultPeriod! <= 0) {
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
            '설정하신 조건으로는 목표 금액 달성이 어렵습니다.\n월 납입금액을 늘리거나 목표 금액을 조정해보세요.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return GradientCard(
      gradientColors: const [AppTheme.accentColor, Color(0xFFDB2777)],
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
              Icons.access_time,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '필요 기간',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatPeriod(_resultPeriod!),
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
    final monthlyDeposit = CurrencyFormatter.parseWon(_monthlyDepositController.text);
    final interestRate = CurrencyFormatter.parsePercent(_interestRateController.text);
    
    final totalDeposit = monthlyDeposit * _resultPeriod!;
    final expectedInterest = targetAmount - totalDeposit;

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
            AppTheme.accentColor,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            '총 납입원금',
            CurrencyFormatter.formatWon(totalDeposit),
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
            '연 이자율',
            CurrencyFormatter.formatPercent(interestRate),
            Icons.percent,
            Colors.orange,
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
                    '매월 ${CurrencyFormatter.formatWon(monthlyDeposit)}씩 ${_resultPeriod}개월간 납입하시면 목표 달성이 가능합니다.',
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