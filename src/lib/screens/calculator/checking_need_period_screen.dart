import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../widgets/common/disclaimer_card.dart';
import '../../widgets/quick_input_buttons.dart';
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
  final Logger _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _resultSectionKey = GlobalKey();
  final _targetAmountController = TextEditingController();
  final _monthlyDepositController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _customTaxRateController = TextEditingController();

  InterestType _interestType = InterestType.compoundMonthly;
  TaxType _taxType = TaxType.normal;
  PeriodCalculationResult? _calculationResult;
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
    _customTaxRateController.dispose();
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
      _monthlyDepositController.clear();
      _interestRateController.clear();
      _customTaxRateController.clear();
      _interestType = InterestType.compoundMonthly;
      _taxType = TaxType.normal;
      _calculationResult = null;
      _showResult = false;
    });
  }

  void _calculate() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    _logger.i('🎯 적금 필요기간 계산 시작');

    final targetAmount = CurrencyFormatter.parseWon(_targetAmountController.text);
    final monthlyDeposit = CurrencyFormatter.parseWon(_monthlyDepositController.text);
    final interestRate = CurrencyFormatter.parsePercent(_interestRateController.text);
    final customTaxRate = _taxType == TaxType.custom 
        ? CurrencyFormatter.parsePercent(_customTaxRateController.text)
        : 0.0;

    _logger.d('입력값 - 목표금액: ${CurrencyFormatter.formatWon(targetAmount)}, 월납입금액: ${CurrencyFormatter.formatWon(monthlyDeposit)}, 연이자율: ${CurrencyFormatter.formatPercent(interestRate)}, 계산방식: ${_interestType.name}, 세금유형: $_taxType ${_taxType == TaxType.custom ? '($customTaxRate%)' : ''}');

    final calculationResult = InterestCalculator.calculateNeedPeriodForGoalWithDetails(
      targetAmount: targetAmount,
      monthlyDeposit: monthlyDeposit,
      interestRate: interestRate,
      interestType: _interestType,
      accountType: AccountType.checking,
      taxType: _taxType,
      customTaxRate: customTaxRate,
    );

    _logger.i('계산 결과 - 필요기간: ${calculationResult.requiredPeriod != null ? CurrencyFormatter.formatPeriod(calculationResult.requiredPeriod!) : "계산불가"} (${calculationResult.requiredPeriod ?? 0}개월)');

    // Save the inputs for next time
    final inputData = {
      'targetAmount': targetAmount,
      'monthlyDeposit': monthlyDeposit,
      'interestRate': interestRate,
      'interestType': _interestType.index,
      'taxType': _taxType.index,
      'customTaxRate': customTaxRate,
    };
    await CalculationHistoryService.saveLastCheckingNeedPeriodInput(inputData);

    setState(() {
      _calculationResult = calculationResult;
      _showResult = true;
    });

    _logger.i('✅ 적금 필요기간 계산 완료');

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
                        controller: _monthlyDepositController,
                        labelText: '월 납입금액',
                        values: QuickInputConstants.amountValues,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '월 납입금액을 입력해주세요';
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
                          side: BorderSide(color: AppTheme.accentColor),
                        ),
                        child: Text(
                          '초기화',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentColor,
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
                    ),
                  ],
                ),
                if (_showResult && _calculationResult != null) ...[
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
    if (_calculationResult == null || !_calculationResult!.achievable) {
      return _buildErrorResult();
    }

    return Column(
      children: [
        _buildResultCard(),
        const SizedBox(height: 16),
        _buildDetailCard(),
        if (_calculationResult!.monthlyResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildMonthlyProgressCard(),
        ],
        const SizedBox(height: 16),
        const DisclaimerCard(),
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
            CurrencyFormatter.formatPeriod(_calculationResult!.requiredPeriod!),
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
    
    final totalDeposit = monthlyDeposit * _calculationResult!.requiredPeriod!;
    
    // Get the actual interest from the target achievement month
    final requiredPeriod = _calculationResult!.requiredPeriod!;
    final targetResult = _calculationResult!.monthlyResults.firstWhere(
      (result) => result.period == requiredPeriod,
      orElse: () => _calculationResult!.monthlyResults.last,
    );
    final expectedInterest = targetResult.cumulativeInterest;

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
                    '매월 ${CurrencyFormatter.formatWon(monthlyDeposit)}씩 ${_calculationResult!.requiredPeriod}개월간 납입하시면 목표 달성이 가능합니다.',
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
          activeColor: AppTheme.accentColor,
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyProgressCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '월별 진행 상황',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(color: AppTheme.borderColor),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(2), 
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: AppTheme.backgroundColor),
                    children: [
                      _buildProgressTableCell('개월', isHeader: true),
                      _buildProgressTableCell('납입원금', isHeader: true),
                      _buildProgressTableCell('이자수익', isHeader: true),
                      _buildProgressTableCell('세금', isHeader: true),
                      _buildProgressTableCell('세후금액', isHeader: true),
                    ],
                  ),
                  ..._buildMonthlyResultRows(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_calculationResult!.requiredPeriod}개월째에 목표금액 ${CurrencyFormatter.formatWon(_calculationResult!.targetAmount)}에 도달합니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentColor,
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

  List<TableRow> _buildMonthlyResultRows() {
    final results = <TableRow>[];
    final monthlyResults = _calculationResult!.monthlyResults;
    final requiredPeriod = _calculationResult!.requiredPeriod;

    // Show key months: first few, around target achievement, and last few
    Set<int> importantMonths = {};
    
    // Add first 3 months
    for (int i = 0; i < 3 && i < monthlyResults.length; i++) {
      importantMonths.add(i);
    }
    
    // Add months around target achievement
    if (requiredPeriod != null && requiredPeriod > 0) {
      for (int i = requiredPeriod - 2; i <= requiredPeriod + 1; i++) {
        if (i >= 0 && i < monthlyResults.length) {
          importantMonths.add(i);
        }
      }
    }
    
    // Add last 2 months
    for (int i = monthlyResults.length - 2; i < monthlyResults.length; i++) {
      if (i >= 0) {
        importantMonths.add(i);
      }
    }

    List<int> sortedMonths = importantMonths.toList()..sort();
    
    for (int i = 0; i < sortedMonths.length; i++) {
      int monthIndex = sortedMonths[i];
      final result = monthlyResults[monthIndex];
      final isTargetMonth = requiredPeriod != null && result.period == requiredPeriod;
      
      results.add(
        TableRow(
          decoration: isTargetMonth 
            ? BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1))
            : null,
          children: [
            _buildProgressTableCell(
              '${result.period}',
              color: isTargetMonth ? AppTheme.accentColor : null,
              fontWeight: isTargetMonth ? FontWeight.bold : null,
            ),
            _buildProgressTableCell(
              CurrencyFormatter.formatWon(result.principal),
              color: isTargetMonth ? AppTheme.accentColor : null,
              fontWeight: isTargetMonth ? FontWeight.bold : null,
            ),
            _buildProgressTableCell(
              CurrencyFormatter.formatWon(result.cumulativeInterest),
              color: isTargetMonth ? AppTheme.accentColor : null,
              fontWeight: isTargetMonth ? FontWeight.bold : null,
            ),
            _buildProgressTableCell(
              CurrencyFormatter.formatWon(result.tax),
              color: isTargetMonth ? AppTheme.accentColor : null,
              fontWeight: isTargetMonth ? FontWeight.bold : null,
            ),
            _buildProgressTableCell(
              CurrencyFormatter.formatWon(result.afterTaxTotalAmount),
              color: isTargetMonth ? AppTheme.accentColor : null,
              fontWeight: isTargetMonth ? FontWeight.bold : null,
            ),
          ],
        ),
      );
      
      // Add separator if there's a gap
      if (i < sortedMonths.length - 1 && sortedMonths[i + 1] - sortedMonths[i] > 1) {
        results.add(
          TableRow(
            children: [
              _buildProgressTableCell('⋮', isCenter: true),
              _buildProgressTableCell('⋮', isCenter: true),
              _buildProgressTableCell('⋮', isCenter: true),
              _buildProgressTableCell('⋮', isCenter: true),
              _buildProgressTableCell('⋮', isCenter: true),
            ],
          ),
        );
      }
    }

    return results;
  }

  Widget _buildProgressTableCell(String text, {
    bool isHeader = false, 
    Color? color, 
    FontWeight? fontWeight,
    bool isCenter = false
  }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: isCenter ? TextAlign.center : TextAlign.left,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: fontWeight ?? (isHeader ? FontWeight.w600 : FontWeight.normal),
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }
}