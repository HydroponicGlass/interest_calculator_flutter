import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../models/calculation_models.dart';
import '../../services/interest_calculator.dart';
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
  
  // Account A controllers
  final _monthlyDepositAController = TextEditingController();
  final _interestRateAController = TextEditingController();
  final _periodAController = TextEditingController();
  
  // Account B controllers
  final _monthlyDepositBController = TextEditingController();
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
    _monthlyDepositAController.dispose();
    _interestRateAController.dispose();
    _periodAController.dispose();
    _monthlyDepositBController.dispose();
    _interestRateBController.dispose();
    _periodBController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final monthlyDepositA = CurrencyFormatter.parseWon(_monthlyDepositAController.text);
    final interestRateA = CurrencyFormatter.parsePercent(_interestRateAController.text);
    final periodA = CurrencyFormatter.parseNumber(_periodAController.text).toInt();
    
    final monthlyDepositB = CurrencyFormatter.parseWon(_monthlyDepositBController.text);
    final interestRateB = CurrencyFormatter.parsePercent(_interestRateBController.text);
    final periodB = CurrencyFormatter.parseNumber(_periodBController.text).toInt();

    final inputA = InterestCalculationInput(
      principal: 0,
      interestRate: interestRateA,
      periodMonths: periodA,
      interestType: _interestTypeA,
      accountType: AccountType.checking,
      taxType: TaxType.normal,
      monthlyDeposit: monthlyDepositA,
    );
    
    final inputB = InterestCalculationInput(
      principal: 0,
      interestRate: interestRateB,
      periodMonths: periodB,
      interestType: _interestTypeB,
      accountType: AccountType.checking,
      taxType: TaxType.normal,
      monthlyDeposit: monthlyDepositB,
    );

    setState(() {
      _resultA = InterestCalculator.calculateInterest(inputA);
      _resultB = InterestCalculator.calculateInterest(inputB);
      _showResult = true;
    });

    // Scroll to results after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultSectionKey.currentContext != null) {
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
                ),
                
                const SizedBox(height: 24),
                ElevatedButton(
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
            label: '월 납입금액',
            controller: monthlyController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '월 납입금액을 입력해주세요';
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
            label: '가입기간',
            controller: periodController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '가입기간을 입력해주세요';
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
}