import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../widgets/quick_input_buttons.dart';
import '../../models/calculation_models.dart';
import '../../services/interest_calculator.dart';
import '../../services/calculation_history_service.dart';
import '../../utils/currency_formatter.dart';

class SavingsNeedAmountScreen extends StatefulWidget {
  const SavingsNeedAmountScreen({super.key});

  @override
  State<SavingsNeedAmountScreen> createState() => _SavingsNeedAmountScreenState();
}

class _SavingsNeedAmountScreenState extends State<SavingsNeedAmountScreen> {
  final Logger logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _resultSectionKey = GlobalKey();
  final _targetAmountController = TextEditingController();
  final _periodController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _customTaxRateController = TextEditingController();

  InterestType _interestType = InterestType.compoundMonthly;
  TaxType _taxType = TaxType.normal;
  double? _resultAmount;
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
    _periodController.dispose();
    _interestRateController.dispose();
    _customTaxRateController.dispose();
    super.dispose();
  }

  void _loadLastInput() async {
    final lastInput = await CalculationHistoryService.getLastSavingsNeedAmountInput();
    if (lastInput != null && mounted) {
      setState(() {
        if (lastInput['targetAmount'] != null && lastInput['targetAmount'] > 0) {
          _targetAmountController.text = CurrencyFormatter.formatWonInput(lastInput['targetAmount']);
        }
        if (lastInput['period'] != null && lastInput['period'] > 0) {
          _periodController.text = lastInput['period'].toString();
        }
        if (lastInput['interestRate'] != null && lastInput['interestRate'] > 0) {
          _interestRateController.text = lastInput['interestRate'].toString();
        }
        if (lastInput['interestType'] != null) {
          _interestType = InterestType.values[lastInput['interestType']];
        }
        if (lastInput['customTaxRate'] != null && lastInput['customTaxRate'] > 0) {
          _customTaxRateController.text = lastInput['customTaxRate'].toString();
        }
        if (lastInput['taxType'] != null) {
          _taxType = TaxType.values[lastInput['taxType']];
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

  void _resetForm() {
    setState(() {
      _targetAmountController.clear();
      _periodController.clear();
      _interestRateController.clear();
      _customTaxRateController.clear();
      _interestType = InterestType.compoundMonthly;
      _taxType = TaxType.normal;
      _resultAmount = null;
      _showResult = false;
    });
  }

  void _calculate() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    // Log calculation start
    logger.i('🎯 적금 목표수익 필요 월납입액 계산을 시작합니다');

    final targetAmount = CurrencyFormatter.parseWon(_targetAmountController.text);
    final period = CurrencyFormatter.parseNumber(_periodController.text).toInt();
    final interestRate = CurrencyFormatter.parsePercent(_interestRateController.text);
    final customTaxRate = _taxType == TaxType.custom 
        ? CurrencyFormatter.parsePercent(_customTaxRateController.text)
        : 0.0;

    // Log all input values
    logger.d('입력값 - 목표 금액: ${CurrencyFormatter.formatWon(targetAmount)}');
    logger.d('입력값 - 예치 기간: ${period}개월');
    logger.d('입력값 - 연 이자율: ${CurrencyFormatter.formatPercent(interestRate)}');
    logger.d('입력값 - 계산 방식: ${_interestType == InterestType.simple ? "단리" : "월복리"}');
    logger.d('입력값 - 세금유형: $_taxType ${_taxType == TaxType.custom ? '($customTaxRate%)' : ''}');

    final requiredAmount = InterestCalculator.calculateNeedAmountForGoal(
      targetAmount: targetAmount,
      periodMonths: period,
      interestRate: interestRate,
      interestType: _interestType,
      accountType: AccountType.checking,
      taxType: _taxType,
      customTaxRate: customTaxRate,
    );

    // Log the calculated result
    logger.i('계산 결과 - 필요 월납입액: ${CurrencyFormatter.formatWon(requiredAmount)}');
    
    // Calculate total deposit and expected interest for checking account
    final totalDeposit = requiredAmount * period;
    final expectedInterest = targetAmount - totalDeposit;
    logger.i('총 납입원금: ${CurrencyFormatter.formatWon(totalDeposit)}');
    logger.i('예상 이자수익: ${CurrencyFormatter.formatWon(expectedInterest)}');

    // Save the inputs for next time
    final inputData = {
      'targetAmount': targetAmount,
      'period': period,
      'interestRate': interestRate,
      'interestType': _interestType.index,
      'taxType': _taxType.index,
      'customTaxRate': customTaxRate,
    };
    await CalculationHistoryService.saveLastSavingsNeedAmountInput(inputData);

    setState(() {
      _resultAmount = requiredAmount;
      _showResult = true;
    });

    // Log completion
    logger.i('✅ 적금 목표수익 필요 월납입액 계산이 완료되었습니다');

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
        title: const Text('적금 목표수익 필요 월납입액'),
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
                      QuickInputButtons(
                        controller: _targetAmountController,
                        labelText: '목표 금액',
                        values: QuickInputConstants.amountValues,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '목표 금액을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      QuickInputButtons(
                        controller: _periodController,
                        labelText: '예치 기간',
                        values: QuickInputConstants.periodValues,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '예치 기간을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      QuickInputButtons(
                        controller: _interestRateController,
                        labelText: '연 이자율',
                        values: QuickInputConstants.interestRateValues,
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
                const SizedBox(height: 16),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '세금 설정',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTaxTypeSelector(),
                      if (_taxType == TaxType.custom) ...[
                        const SizedBox(height: 16),
                        PercentInputField(
                          label: '사용자 정의 세율',
                          controller: _customTaxRateController,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetForm,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.purple),
                        ),
                        child: const Text(
                          '초기화',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _calculate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '필요 월납입액 계산하기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showResult && _resultAmount != null) ...[
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
            '필요 월납입액',
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
    
    final totalDeposit = _resultAmount! * period;
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
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            '필요 월납입액',
            CurrencyFormatter.formatWon(_resultAmount!),
            Icons.account_balance_wallet,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            '총 납입원금',
            CurrencyFormatter.formatWon(totalDeposit),
            Icons.savings,
            Colors.blue,
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
                    '매월 ${CurrencyFormatter.formatWon(_resultAmount!)}씩 ${period}개월간 납입하면 목표 달성이 가능합니다.',
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

  Widget _buildTaxTypeSelector() {
    return Column(
      children: TaxType.values.map((type) {
        String title = '';
        
        switch (type) {
          case TaxType.normal:
            title = '일반과세 (15.4%)';
            break;
          case TaxType.noTax:
            title = '비과세';
            break;
          case TaxType.custom:
            title = '사용자 정의';
            break;
        }

        return RadioListTile<TaxType>(
          title: Text(title),
          value: type,
          groupValue: _taxType,
          onChanged: (value) {
            setState(() {
              _taxType = value!;
            });
          },
          activeColor: Colors.purple,
        );
      }).toList(),
    );
  }
}