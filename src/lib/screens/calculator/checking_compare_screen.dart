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

class CheckingCompareScreen extends StatefulWidget {
  const CheckingCompareScreen({super.key});

  @override
  State<CheckingCompareScreen> createState() => _CheckingCompareScreenState();
}

class _CheckingCompareScreenState extends State<CheckingCompareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _resultSectionKey = GlobalKey();
  
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
  
  // Account A controllers
  final _monthlyDepositAController = TextEditingController();
  final _interestRateAController = TextEditingController();
  final _periodAController = TextEditingController();
  
  // Account B controllers
  final _monthlyDepositBController = TextEditingController();
  final _interestRateBController = TextEditingController();
  final _periodBController = TextEditingController();
  final _customTaxRateAController = TextEditingController();
  final _customTaxRateBController = TextEditingController();

  InterestType _interestTypeA = InterestType.compoundMonthly;
  InterestType _interestTypeB = InterestType.compoundMonthly;
  TaxType _taxTypeA = TaxType.normal;
  TaxType _taxTypeB = TaxType.normal;
  
  InterestCalculationResult? _resultA;
  InterestCalculationResult? _resultB;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _loadLastInput();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _monthlyDepositAController.dispose();
    _interestRateAController.dispose();
    _periodAController.dispose();
    _monthlyDepositBController.dispose();
    _interestRateBController.dispose();
    _periodBController.dispose();
    _customTaxRateAController.dispose();
    _customTaxRateBController.dispose();
    super.dispose();
  }

  void _loadLastInput() async {
    final lastInput = await CalculationHistoryService.getLastCheckingCompareInput();
    if (lastInput != null && mounted) {
      setState(() {
        // Product A
        if (lastInput['monthlyDepositA'] != null && lastInput['monthlyDepositA'] > 0) {
          _monthlyDepositAController.text = CurrencyFormatter.formatWonInput(lastInput['monthlyDepositA']);
        }
        if (lastInput['interestRateA'] != null && lastInput['interestRateA'] > 0) {
          _interestRateAController.text = lastInput['interestRateA'].toString();
        }
        if (lastInput['periodA'] != null && lastInput['periodA'] > 0) {
          _periodAController.text = lastInput['periodA'].toString();
        }
        if (lastInput['interestTypeA'] != null) {
          _interestTypeA = InterestType.values[lastInput['interestTypeA']];
        }
        if (lastInput['customTaxRateA'] != null && lastInput['customTaxRateA'] > 0) {
          _customTaxRateAController.text = lastInput['customTaxRateA'].toString();
        }
        if (lastInput['taxTypeA'] != null) {
          _taxTypeA = TaxType.values[lastInput['taxTypeA']];
        }

        // Product B
        if (lastInput['monthlyDepositB'] != null && lastInput['monthlyDepositB'] > 0) {
          _monthlyDepositBController.text = CurrencyFormatter.formatWonInput(lastInput['monthlyDepositB']);
        }
        if (lastInput['interestRateB'] != null && lastInput['interestRateB'] > 0) {
          _interestRateBController.text = lastInput['interestRateB'].toString();
        }
        if (lastInput['periodB'] != null && lastInput['periodB'] > 0) {
          _periodBController.text = lastInput['periodB'].toString();
        }
        if (lastInput['interestTypeB'] != null) {
          _interestTypeB = InterestType.values[lastInput['interestTypeB']];
        }
        if (lastInput['customTaxRateB'] != null && lastInput['customTaxRateB'] > 0) {
          _customTaxRateBController.text = lastInput['customTaxRateB'].toString();
        }
        if (lastInput['taxTypeB'] != null) {
          _taxTypeB = TaxType.values[lastInput['taxTypeB']];
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
      _monthlyDepositAController.clear();
      _interestRateAController.clear();
      _periodAController.clear();
      _monthlyDepositBController.clear();
      _interestRateBController.clear();
      _periodBController.clear();
      _customTaxRateAController.clear();
      _customTaxRateBController.clear();
      _interestTypeA = InterestType.compoundMonthly;
      _interestTypeB = InterestType.compoundMonthly;
      _taxTypeA = TaxType.normal;
      _taxTypeB = TaxType.normal;
      _resultA = null;
      _resultB = null;
      _showResult = false;
    });
  }

  void _calculate() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    _logger.i('⚔️ [적금 상품 비교] 계산 시작');

    final monthlyDepositA = CurrencyFormatter.parseWon(_monthlyDepositAController.text);
    final interestRateA = CurrencyFormatter.parsePercent(_interestRateAController.text);
    final periodA = CurrencyFormatter.parseNumber(_periodAController.text).toInt();
    
    final monthlyDepositB = CurrencyFormatter.parseWon(_monthlyDepositBController.text);
    final interestRateB = CurrencyFormatter.parsePercent(_interestRateBController.text);
    final periodB = CurrencyFormatter.parseNumber(_periodBController.text).toInt();
    final customTaxRateA = _taxTypeA == TaxType.custom 
        ? CurrencyFormatter.parsePercent(_customTaxRateAController.text)
        : 0.0;
    final customTaxRateB = _taxTypeB == TaxType.custom 
        ? CurrencyFormatter.parsePercent(_customTaxRateBController.text)
        : 0.0;

    // Log input values for both products
    _logger.i('📊 [A 상품 입력값] 월납입: ${CurrencyFormatter.formatWon(monthlyDepositA)}, '
        '이자율: ${interestRateA.toStringAsFixed(2)}%, 기간: ${periodA}개월, '
        '계산방식: ${_interestTypeA == InterestType.simple ? "단리" : "월복리"}, '
        '세금유형: $_taxTypeA ${_taxTypeA == TaxType.custom ? '($customTaxRateA%)' : ''}');
    
    _logger.i('📊 [B 상품 입력값] 월납입: ${CurrencyFormatter.formatWon(monthlyDepositB)}, '
        '이자율: ${interestRateB.toStringAsFixed(2)}%, 기간: ${periodB}개월, '
        '계산방식: ${_interestTypeB == InterestType.simple ? "단리" : "월복리"}, '
        '세금유형: $_taxTypeB ${_taxTypeB == TaxType.custom ? '($customTaxRateB%)' : ''}');

    final inputA = InterestCalculationInput(
      principal: 0,
      interestRate: interestRateA,
      periodMonths: periodA,
      interestType: _interestTypeA,
      accountType: AccountType.checking,
      taxType: _taxTypeA,
      customTaxRate: customTaxRateA,
      monthlyDeposit: monthlyDepositA,
    );
    
    final inputB = InterestCalculationInput(
      principal: 0,
      interestRate: interestRateB,
      periodMonths: periodB,
      interestType: _interestTypeB,
      accountType: AccountType.checking,
      taxType: _taxTypeB,
      customTaxRate: customTaxRateB,
      monthlyDeposit: monthlyDepositB,
    );

    // Calculate results
    final resultA = InterestCalculator.calculateInterest(inputA);
    final resultB = InterestCalculator.calculateInterest(inputB);

    // Log intermediate calculation results
    _logger.i('🧮 [A 상품 계산결과] 총납입: ${CurrencyFormatter.formatWon(resultA.totalAmount - resultA.totalInterest)}, '
        '이자수익: ${CurrencyFormatter.formatWon(resultA.totalInterest)}, '
        '세금: ${CurrencyFormatter.formatWon(resultA.taxAmount)}, '
        '세후수령액: ${CurrencyFormatter.formatWon(resultA.finalAmount)}');
    
    _logger.i('🧮 [B 상품 계산결과] 총납입: ${CurrencyFormatter.formatWon(resultB.totalAmount - resultB.totalInterest)}, '
        '이자수익: ${CurrencyFormatter.formatWon(resultB.totalInterest)}, '
        '세금: ${CurrencyFormatter.formatWon(resultB.taxAmount)}, '
        '세후수령액: ${CurrencyFormatter.formatWon(resultB.finalAmount)}');

    // Log comparison results
    final betterOption = resultA.finalAmount > resultB.finalAmount ? 'A' : 'B';
    final difference = (resultA.finalAmount - resultB.finalAmount).abs();
    final profitDiffPercent = (difference / (resultA.finalAmount < resultB.finalAmount ? resultA.finalAmount : resultB.finalAmount) * 100);
    
    _logger.i('🏆 [비교 결과] $betterOption 상품이 유리함! '
        '차이: ${CurrencyFormatter.formatWon(difference)} (${profitDiffPercent.toStringAsFixed(2)}% 더 유리)');

    // Save the inputs for next time
    final compareData = {
      'monthlyDepositA': monthlyDepositA,
      'interestRateA': interestRateA,
      'periodA': periodA,
      'interestTypeA': _interestTypeA.index,
      'taxTypeA': _taxTypeA.index,
      'customTaxRateA': customTaxRateA,
      'monthlyDepositB': monthlyDepositB,
      'interestRateB': interestRateB,
      'periodB': periodB,
      'interestTypeB': _interestTypeB.index,
      'taxTypeB': _taxTypeB.index,
      'customTaxRateB': customTaxRateB,
    };
    await CalculationHistoryService.saveLastCheckingCompareInput(compareData);

    setState(() {
      _resultA = resultA;
      _resultB = resultB;
      _showResult = true;
    });

    _logger.i('✅ [적금 상품 비교] 계산 완료 및 결과 표시');

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
        title: const Text('적금 상품 비교'),
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
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.compare_arrows,
                        color: Colors.teal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '적금 상품 비교 분석',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Account A Section
                _buildAccountSection(
                  'A 상품',
                  Colors.blue,
                  _monthlyDepositAController,
                  _interestRateAController,
                  _periodAController,
                  _interestTypeA,
                  (value) => setState(() => _interestTypeA = value!),
                  _taxTypeA,
                  (value) => setState(() => _taxTypeA = value!),
                  _customTaxRateAController,
                ),
                
                const SizedBox(height: 24),
                
                // VS Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Account B Section
                _buildAccountSection(
                  'B 상품',
                  Colors.red,
                  _monthlyDepositBController,
                  _interestRateBController,
                  _periodBController,
                  _interestTypeB,
                  (value) => setState(() => _interestTypeB = value!),
                  _taxTypeB,
                  (value) => setState(() => _taxTypeB = value!),
                  _customTaxRateBController,
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
                          side: const BorderSide(color: Colors.teal),
                        ),
                        child: const Text(
                          '초기화',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal,
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
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '비교 분석하기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (_showResult && _resultA != null && _resultB != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    key: _resultSectionKey,
                    child: _buildComparisonResults(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(
    String title,
    Color color,
    TextEditingController monthlyController,
    TextEditingController rateController,
    TextEditingController periodController,
    InterestType interestType,
    Function(InterestType?) onInterestTypeChanged,
    TaxType taxType,
    Function(TaxType?) onTaxTypeChanged,
    TextEditingController customTaxRateController,
  ) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          QuickInputButtons(
            controller: monthlyController,
            labelText: '월 납입금액',
            values: QuickInputConstants.amountValues,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '월 납입금액을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          QuickInputButtons(
            controller: rateController,
            labelText: '연 이자율',
            values: QuickInputConstants.interestRateValues,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '연 이자율을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          QuickInputButtons(
            controller: periodController,
            labelText: '가입기간',
            values: QuickInputConstants.periodValues,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '가입기간을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            '이자 계산 방식',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildInterestTypeSelector(interestType, onInterestTypeChanged, color),
          const SizedBox(height: 16),
          Text(
            '세금 설정',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildTaxTypeSelector(taxType, onTaxTypeChanged, color),
          if (taxType == TaxType.custom) ...[
            const SizedBox(height: 12),
            PercentInputField(
              label: '사용자 정의 세율',
              controller: customTaxRateController,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInterestTypeSelector(
    InterestType currentType,
    Function(InterestType?) onChanged,
    Color accentColor,
  ) {
    return Column(
      children: InterestType.values.map((type) {
        String title = '';
        switch (type) {
          case InterestType.simple:
            title = '단리';
            break;
          case InterestType.compoundMonthly:
            title = '월복리';
            break;
        }

        return RadioListTile<InterestType>(
          dense: true,
          title: Text(title, style: const TextStyle(fontSize: 14)),
          value: type,
          groupValue: currentType,
          onChanged: onChanged,
          activeColor: accentColor,
        );
      }).toList(),
    );
  }

  Widget _buildTaxTypeSelector(
    TaxType currentType,
    Function(TaxType?) onChanged,
    Color accentColor,
  ) {
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
          dense: true,
          title: Text(title, style: const TextStyle(fontSize: 14)),
          value: type,
          groupValue: currentType,
          onChanged: onChanged,
          activeColor: accentColor,
        );
      }).toList(),
    );
  }

  Widget _buildComparisonResults() {
    final betterOption = _resultA!.finalAmount > _resultB!.finalAmount ? 'A' : 'B';
    final difference = (_resultA!.finalAmount - _resultB!.finalAmount).abs();

    return Column(
      children: [
        // Summary Card
        GradientCard(
          gradientColors: const [Colors.teal, Color(0xFF26A69A)],
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
                  Icons.analytics,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '비교 결과',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$betterOption 상품이 유리',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${CurrencyFormatter.formatWon(difference)} 더 많은 수익',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Detailed Comparison
        Row(
          children: [
            Expanded(
              child: _buildResultCard(
                'A 상품',
                Colors.blue,
                _resultA!,
                CurrencyFormatter.parseWon(_monthlyDepositAController.text),
                CurrencyFormatter.parseNumber(_periodAController.text).toInt(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildResultCard(
                'B 상품',
                Colors.red,
                _resultB!,
                CurrencyFormatter.parseWon(_monthlyDepositBController.text),
                CurrencyFormatter.parseNumber(_periodBController.text).toInt(),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Comparison Table
        _buildComparisonTable(),
        
        const SizedBox(height: 16),
        const DisclaimerCard(),
      ],
    );
  }

  Widget _buildResultCard(
    String title,
    Color color,
    InterestCalculationResult result,
    double monthlyDeposit,
    int period,
  ) {
    return CustomCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.formatWon(result.finalAmount),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '세후 수령액',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상세 비교표',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: AppTheme.borderColor),
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppTheme.backgroundColor),
                children: [
                  _buildTableCell('구분', isHeader: true),
                  _buildTableCell('A 상품', isHeader: true, color: Colors.blue),
                  _buildTableCell('B 상품', isHeader: true, color: Colors.red),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('월 납입금액'),
                  _buildTableCell(CurrencyFormatter.formatWon(
                    CurrencyFormatter.parseWon(_monthlyDepositAController.text)
                  )),
                  _buildTableCell(CurrencyFormatter.formatWon(
                    CurrencyFormatter.parseWon(_monthlyDepositBController.text)
                  )),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('총 납입원금'),
                  _buildTableCell(CurrencyFormatter.formatWon(
                    _resultA!.totalAmount - _resultA!.totalInterest
                  )),
                  _buildTableCell(CurrencyFormatter.formatWon(
                    _resultB!.totalAmount - _resultB!.totalInterest
                  )),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('이자수익'),
                  _buildTableCell(CurrencyFormatter.formatWon(_resultA!.totalInterest)),
                  _buildTableCell(CurrencyFormatter.formatWon(_resultB!.totalInterest)),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('세금유형'),
                  _buildTableCell(_getTaxTypeDisplayText(_taxTypeA)),
                  _buildTableCell(_getTaxTypeDisplayText(_taxTypeB)),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('세금'),
                  _buildTableCell(CurrencyFormatter.formatWon(_resultA!.taxAmount)),
                  _buildTableCell(CurrencyFormatter.formatWon(_resultB!.taxAmount)),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(color: AppTheme.backgroundColor),
                children: [
                  _buildTableCell('세후 수령액', isHeader: true),
                  _buildTableCell(
                    CurrencyFormatter.formatWon(_resultA!.finalAmount),
                    isHeader: true,
                    color: Colors.blue,
                  ),
                  _buildTableCell(
                    CurrencyFormatter.formatWon(_resultB!.finalAmount),
                    isHeader: true,
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  String _getTaxTypeDisplayText(TaxType taxType) {
    switch (taxType) {
      case TaxType.normal:
        return '일반과세 (15.4%)';
      case TaxType.noTax:
        return '비과세';
      case TaxType.custom:
        final customRate = taxType == _taxTypeA 
            ? _customTaxRateAController.text
            : _customTaxRateBController.text;
        return '사용자 정의 ($customRate%)';
    }
  }
}