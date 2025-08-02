import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../models/calculation_models.dart';
import '../../services/interest_calculator.dart';
import '../../utils/currency_formatter.dart';

class SavingsCompareScreen extends StatefulWidget {
  const SavingsCompareScreen({super.key});

  @override
  State<SavingsCompareScreen> createState() => _SavingsCompareScreenState();
}

class _SavingsCompareScreenState extends State<SavingsCompareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _resultSectionKey = GlobalKey();
  
  // Account A controllers
  final _principalAController = TextEditingController();
  final _interestRateAController = TextEditingController();
  final _periodAController = TextEditingController();
  
  // Account B controllers
  final _principalBController = TextEditingController();
  final _interestRateBController = TextEditingController();
  final _periodBController = TextEditingController();

  InterestType _interestTypeA = InterestType.compoundMonthly;
  InterestType _interestTypeB = InterestType.compoundMonthly;
  
  InterestCalculationResult? _resultA;
  InterestCalculationResult? _resultB;
  bool _showResult = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _principalAController.dispose();
    _interestRateAController.dispose();
    _periodAController.dispose();
    _principalBController.dispose();
    _interestRateBController.dispose();
    _periodBController.dispose();
    super.dispose();
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

  void _calculate() {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    final principalA = CurrencyFormatter.parseWon(_principalAController.text);
    final interestRateA = CurrencyFormatter.parsePercent(_interestRateAController.text);
    final periodA = CurrencyFormatter.parseNumber(_periodAController.text).toInt();
    
    final principalB = CurrencyFormatter.parseWon(_principalBController.text);
    final interestRateB = CurrencyFormatter.parsePercent(_interestRateBController.text);
    final periodB = CurrencyFormatter.parseNumber(_periodBController.text).toInt();

    final inputA = InterestCalculationInput(
      principal: principalA,
      interestRate: interestRateA,
      periodMonths: periodA,
      interestType: _interestTypeA,
      accountType: AccountType.savings,
      taxType: TaxType.normal,
      monthlyDeposit: 0,
    );
    
    final inputB = InterestCalculationInput(
      principal: principalB,
      interestRate: interestRateB,
      periodMonths: periodB,
      interestType: _interestTypeB,
      accountType: AccountType.savings,
      taxType: TaxType.normal,
      monthlyDeposit: 0,
    );

    setState(() {
      _resultA = InterestCalculator.calculateInterest(inputA);
      _resultB = InterestCalculator.calculateInterest(inputB);
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
        title: const Text('예금 상품 비교'),
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
                        color: Colors.indigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.balance,
                        color: Colors.indigo,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '예금 상품 비교 분석',
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
                  _principalAController,
                  _interestRateAController,
                  _periodAController,
                  _interestTypeA,
                  (value) => setState(() => _interestTypeA = value!),
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
                        color: Colors.indigo,
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
                  _principalBController,
                  _interestRateBController,
                  _periodBController,
                  _interestTypeB,
                  (value) => setState(() => _interestTypeB = value!),
                ),
                
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
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
    TextEditingController principalController,
    TextEditingController rateController,
    TextEditingController periodController,
    InterestType interestType,
    Function(InterestType?) onInterestTypeChanged,
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
          CurrencyInputField(
            label: '원금',
            controller: principalController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '원금을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          PercentInputField(
            label: '연 이자율',
            controller: rateController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '연 이자율을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          PeriodInputField(
            label: '예치기간',
            controller: periodController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '예치기간을 입력해주세요';
              }
              return null;
            },
            onChanged: (value) {
              // Handle period change if needed
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
          case InterestType.compoundDaily:
            title = '일복리';
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

  Widget _buildComparisonResults() {
    final betterOption = _resultA!.finalAmount > _resultB!.finalAmount ? 'A' : 'B';
    final difference = (_resultA!.finalAmount - _resultB!.finalAmount).abs();

    return Column(
      children: [
        // Summary Card
        GradientCard(
          gradientColors: const [Colors.indigo, Color(0xFF3F51B5)],
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
                CurrencyFormatter.parseWon(_principalAController.text),
                CurrencyFormatter.parseNumber(_periodAController.text).toInt(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildResultCard(
                'B 상품',
                Colors.red,
                _resultB!,
                CurrencyFormatter.parseWon(_principalBController.text),
                CurrencyFormatter.parseNumber(_periodBController.text).toInt(),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Comparison Table
        _buildComparisonTable(),
      ],
    );
  }

  Widget _buildResultCard(
    String title,
    Color color,
    InterestCalculationResult result,
    double principal,
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
                  _buildTableCell('원금'),
                  _buildTableCell(CurrencyFormatter.formatWon(
                    CurrencyFormatter.parseWon(_principalAController.text)
                  )),
                  _buildTableCell(CurrencyFormatter.formatWon(
                    CurrencyFormatter.parseWon(_principalBController.text)
                  )),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('예치기간'),
                  _buildTableCell('${_periodAController.text}개월'),
                  _buildTableCell('${_periodBController.text}개월'),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('연 이자율'),
                  _buildTableCell('${_interestRateAController.text}%'),
                  _buildTableCell('${_interestRateBController.text}%'),
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
          const SizedBox(height: 16),
          _buildEffectiveRateComparison(),
        ],
      ),
    );
  }

  Widget _buildEffectiveRateComparison() {
    final principalA = CurrencyFormatter.parseWon(_principalAController.text);
    final principalB = CurrencyFormatter.parseWon(_principalBController.text);
    final periodA = CurrencyFormatter.parseNumber(_periodAController.text).toInt();
    final periodB = CurrencyFormatter.parseNumber(_periodBController.text).toInt();
    
    final effectiveRateA = (_resultA!.totalInterest / principalA) / (periodA / 12) * 100;
    final effectiveRateB = (_resultB!.totalInterest / principalB) / (periodB / 12) * 100;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '실질 수익률 비교',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('A 상품 실질 수익률: ', style: Theme.of(context).textTheme.bodySmall),
              Text(
                '${effectiveRateA.toStringAsFixed(2)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('B 상품 실질 수익률: ', style: Theme.of(context).textTheme.bodySmall),
              Text(
                '${effectiveRateB.toStringAsFixed(2)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
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
}