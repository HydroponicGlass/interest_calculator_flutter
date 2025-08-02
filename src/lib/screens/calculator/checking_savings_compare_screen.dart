import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../models/calculation_models.dart';
import '../../services/interest_calculator.dart';
import '../../utils/currency_formatter.dart';

class CheckingSavingsCompareScreen extends StatefulWidget {
  const CheckingSavingsCompareScreen({super.key});

  @override
  State<CheckingSavingsCompareScreen> createState() => _CheckingSavingsCompareScreenState();
}

class _CheckingSavingsCompareScreenState extends State<CheckingSavingsCompareScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _amountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _periodController = TextEditingController();

  InterestType _interestType = InterestType.compoundMonthly;
  
  InterestCalculationResult? _checkingResult;
  InterestCalculationResult? _savingsResult;
  bool _showResult = false;

  @override
  void dispose() {
    _amountController.dispose();
    _interestRateController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final amount = CurrencyFormatter.parseWon(_amountController.text);
    final interestRate = CurrencyFormatter.parsePercent(_interestRateController.text);
    final period = CurrencyFormatter.parseNumber(_periodController.text).toInt();

    // Calculate for checking account (monthly deposits)
    final checkingInput = InterestCalculationInput(
      principal: 0,
      interestRate: interestRate,
      periodMonths: period,
      interestType: _interestType,
      accountType: AccountType.checking,
      taxType: TaxType.normal,
      monthlyDeposit: amount,
    );
    
    // Calculate for savings account (lump sum)
    final savingsInput = InterestCalculationInput(
      principal: amount * period, // Total amount as lump sum
      interestRate: interestRate,
      periodMonths: period,
      interestType: _interestType,
      accountType: AccountType.savings,
      taxType: TaxType.normal,
      monthlyDeposit: 0,
    );

    setState(() {
      _checkingResult = InterestCalculator.calculateInterest(checkingInput);
      _savingsResult = InterestCalculator.calculateInterest(savingsInput);
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
        title: const Text('적금 vs 예금 비교'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                              color: Colors.deepOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.analytics,
                              color: Colors.deepOrange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '적금 vs 예금 비교',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.deepOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '적금: 매월 일정금액 납입 vs 예금: 전체금액 일시예치',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.deepOrange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      CurrencyInputField(
                        label: '월 납입금액 (적금) / 총 예치금액 기준',
                        controller: _amountController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '금액을 입력해주세요';
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
                      const SizedBox(height: 20),
                      NumberInputField(
                        label: '기간 (월)',
                        controller: _periodController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '기간을 입력해주세요';
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
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '적금 vs 예금 비교하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                
                if (_showResult && _checkingResult != null && _savingsResult != null) ...[
                  const SizedBox(height: 24),
                  _buildComparisonResults(),
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
          activeColor: Colors.deepOrange,
        );
      }).toList(),
    );
  }

  Widget _buildComparisonResults() {
    final betterOption = _savingsResult!.finalAmount > _checkingResult!.finalAmount ? '예금' : '적금';
    final difference = (_savingsResult!.finalAmount - _checkingResult!.finalAmount).abs();
    final amount = CurrencyFormatter.parseWon(_amountController.text);
    final period = CurrencyFormatter.parseNumber(_periodController.text).toInt();

    return Column(
      children: [
        // Summary Card
        GradientCard(
          gradientColors: const [Colors.deepOrange, Color(0xFFFF5722)],
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
                '$betterOption이 유리',
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
                '적금',
                Colors.blue,
                _checkingResult!,
                '매월 ${CurrencyFormatter.formatWon(amount)} 납입',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildResultCard(
                '예금',
                Colors.green,
                _savingsResult!,
                '일시 ${CurrencyFormatter.formatWon(amount * period)} 예치',
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
    String description,
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
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.formatWon(result.finalAmount),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
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
    final amount = CurrencyFormatter.parseWon(_amountController.text);
    final period = CurrencyFormatter.parseNumber(_periodController.text).toInt();
    final totalCheckingPrincipal = amount * period;
    final totalSavingsPrincipal = amount * period;

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
                  _buildTableCell('적금', isHeader: true, color: Colors.blue),
                  _buildTableCell('예금', isHeader: true, color: Colors.green),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('납입방식'),
                  _buildTableCell('매월 분할납입'),
                  _buildTableCell('일시납입'),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('총 원금'),
                  _buildTableCell(CurrencyFormatter.formatWon(totalCheckingPrincipal)),
                  _buildTableCell(CurrencyFormatter.formatWon(totalSavingsPrincipal)),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('이자수익'),
                  _buildTableCell(CurrencyFormatter.formatWon(_checkingResult!.totalInterest)),
                  _buildTableCell(CurrencyFormatter.formatWon(_savingsResult!.totalInterest)),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('세금'),
                  _buildTableCell(CurrencyFormatter.formatWon(_checkingResult!.taxAmount)),
                  _buildTableCell(CurrencyFormatter.formatWon(_savingsResult!.taxAmount)),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(color: AppTheme.backgroundColor),
                children: [
                  _buildTableCell('세후 수령액', isHeader: true),
                  _buildTableCell(
                    CurrencyFormatter.formatWon(_checkingResult!.finalAmount),
                    isHeader: true,
                    color: Colors.blue,
                  ),
                  _buildTableCell(
                    CurrencyFormatter.formatWon(_savingsResult!.finalAmount),
                    isHeader: true,
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnalysisSection(),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    final amount = CurrencyFormatter.parseWon(_amountController.text);
    final period = CurrencyFormatter.parseNumber(_periodController.text).toInt();
    final interestRate = CurrencyFormatter.parsePercent(_interestRateController.text);
    
    final checkingAdvantage = _checkingResult!.finalAmount > _savingsResult!.finalAmount;
    
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
            '분석 요약',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          if (checkingAdvantage) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.trending_up, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '적금이 유리한 이유: 매월 분할 납입으로 초기 자금 부담이 적고, 단계적으로 복리 효과를 누릴 수 있습니다.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.trending_up, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '예금이 유리한 이유: 전체 금액을 처음부터 예치하여 더 긴 기간동안 복리 효과를 받을 수 있습니다.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: AppTheme.warningColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '실제 선택 시 고려사항: 현금 유동성, 중도해지 조건, 실제 이자율 차이 등을 종합적으로 고려하세요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
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