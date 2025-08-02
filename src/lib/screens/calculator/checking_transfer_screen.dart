import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../models/calculation_models.dart';
import '../../services/interest_calculator.dart';
import '../../utils/currency_formatter.dart';

class CheckingTransferScreen extends StatefulWidget {
  const CheckingTransferScreen({super.key});

  @override
  State<CheckingTransferScreen> createState() => _CheckingTransferScreenState();
}

class _CheckingTransferScreenState extends State<CheckingTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _resultSectionKey = GlobalKey();
  
  final _currentBalanceController = TextEditingController();
  final _remainingPeriodController = TextEditingController();
  final _currentRateController = TextEditingController();
  final _newRateController = TextEditingController();
  final _transferFeeController = TextEditingController();
  final _monthlyDepositController = TextEditingController();

  InterestType _interestType = InterestType.compoundMonthly;
  
  InterestCalculationResult? _keepCurrentResult;
  InterestCalculationResult? _transferResult;
  bool _showResult = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _currentBalanceController.dispose();
    _remainingPeriodController.dispose();
    _currentRateController.dispose();
    _newRateController.dispose();
    _transferFeeController.dispose();
    _monthlyDepositController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final currentBalance = CurrencyFormatter.parseWon(_currentBalanceController.text);
    final remainingPeriod = CurrencyFormatter.parseNumber(_remainingPeriodController.text).toInt();
    final currentRate = CurrencyFormatter.parsePercent(_currentRateController.text);
    final newRate = CurrencyFormatter.parsePercent(_newRateController.text);
    final transferFee = CurrencyFormatter.parseWon(_transferFeeController.text);
    final monthlyDeposit = CurrencyFormatter.parseWon(_monthlyDepositController.text);

    // Calculate keeping current account
    final keepCurrentInput = InterestCalculationInput(
      principal: currentBalance,
      interestRate: currentRate,
      periodMonths: remainingPeriod,
      interestType: _interestType,
      accountType: AccountType.checking,
      taxType: TaxType.normal,
      monthlyDeposit: monthlyDeposit,
    );
    
    // Calculate transfer to new account (subtract transfer fee from current balance)
    final transferInput = InterestCalculationInput(
      principal: currentBalance - transferFee,
      interestRate: newRate,
      periodMonths: remainingPeriod,
      interestType: _interestType,
      accountType: AccountType.checking,
      taxType: TaxType.normal,
      monthlyDeposit: monthlyDeposit,
    );

    setState(() {
      _keepCurrentResult = InterestCalculator.calculateInterest(keepCurrentInput);
      _transferResult = InterestCalculator.calculateInterest(transferInput);
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
        title: const Text('적금 이관 분석'),
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
                              color: Colors.brown.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.swap_horiz,
                              color: Colors.brown,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '현재 적금 정보',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CurrencyInputField(
                        label: '현재 잔액 (납입된 원금)',
                        controller: _currentBalanceController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '현재 잔액을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      PeriodInputField(
                        label: '남은 기간',
                        controller: _remainingPeriodController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '남은 기간을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      PercentInputField(
                        label: '현재 연 이자율',
                        controller: _currentRateController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '현재 이자율을 입력해주세요';
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
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: Colors.green,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '새로운 적금 정보',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      PercentInputField(
                        label: '새로운 연 이자율',
                        controller: _newRateController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '새로운 이자율을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CurrencyInputField(
                        label: '이관 수수료',
                        controller: _transferFeeController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '이관 수수료를 입력해주세요 (없으면 0)';
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
                    backgroundColor: Colors.brown,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '이관 분석하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                
                if (_showResult && _keepCurrentResult != null && _transferResult != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    key: _resultSectionKey,
                    child: _buildTransferAnalysis(),
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
          activeColor: Colors.brown,
        );
      }).toList(),
    );
  }

  Widget _buildTransferAnalysis() {
    final transferFee = CurrencyFormatter.parseWon(_transferFeeController.text);
    final isTransferBetter = _transferResult!.finalAmount > _keepCurrentResult!.finalAmount;
    final difference = (_transferResult!.finalAmount - _keepCurrentResult!.finalAmount).abs();
    final currentRate = CurrencyFormatter.parsePercent(_currentRateController.text);
    final newRate = CurrencyFormatter.parsePercent(_newRateController.text);

    return Column(
      children: [
        // Summary Card
        GradientCard(
          gradientColors: [
            isTransferBetter ? Colors.green : Colors.orange,
            isTransferBetter ? Colors.green.shade700 : Colors.orange.shade700,
          ],
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isTransferBetter ? Icons.trending_up : Icons.trending_down,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '이관 분석 결과',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isTransferBetter ? '이관 권장' : '현재 유지 권장',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${CurrencyFormatter.formatWon(difference)} ${isTransferBetter ? '더 많은' : '덜한'} 수익',
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
                '현재 유지',
                Colors.blue,
                _keepCurrentResult!,
                '${currentRate.toStringAsFixed(1)}% 이자율',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildResultCard(
                '이관 후',
                Colors.green,
                _transferResult!,
                '${newRate.toStringAsFixed(1)}% 이자율',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Detailed Analysis Table
        _buildAnalysisTable(),
        
        const SizedBox(height: 16),
        
        // Break-even Analysis
        _buildBreakEvenAnalysis(),
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

  Widget _buildAnalysisTable() {
    final currentBalance = CurrencyFormatter.parseWon(_currentBalanceController.text);
    final transferFee = CurrencyFormatter.parseWon(_transferFeeController.text);
    final monthlyDeposit = CurrencyFormatter.parseWon(_monthlyDepositController.text);
    final remainingPeriod = CurrencyFormatter.parseNumber(_remainingPeriodController.text).toInt();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상세 비교 분석',
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
                  _buildTableCell('현재 유지', isHeader: true, color: Colors.blue),
                  _buildTableCell('이관 후', isHeader: true, color: Colors.green),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('시작 원금'),
                  _buildTableCell(CurrencyFormatter.formatWon(currentBalance)),
                  _buildTableCell(CurrencyFormatter.formatWon(currentBalance - transferFee)),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('이관 수수료'),
                  _buildTableCell('0원'),
                  _buildTableCell(CurrencyFormatter.formatWon(transferFee)),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('월 납입액'),
                  _buildTableCell(CurrencyFormatter.formatWon(monthlyDeposit)),
                  _buildTableCell(CurrencyFormatter.formatWon(monthlyDeposit)),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('총 납입원금'),
                  _buildTableCell(CurrencyFormatter.formatWon(
                    currentBalance + (monthlyDeposit * remainingPeriod)
                  )),
                  _buildTableCell(CurrencyFormatter.formatWon(
                    (currentBalance - transferFee) + (monthlyDeposit * remainingPeriod)
                  )),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('이자수익'),
                  _buildTableCell(CurrencyFormatter.formatWon(_keepCurrentResult!.totalInterest)),
                  _buildTableCell(CurrencyFormatter.formatWon(_transferResult!.totalInterest)),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('세금'),
                  _buildTableCell(CurrencyFormatter.formatWon(_keepCurrentResult!.taxAmount)),
                  _buildTableCell(CurrencyFormatter.formatWon(_transferResult!.taxAmount)),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(color: AppTheme.backgroundColor),
                children: [
                  _buildTableCell('최종 수령액', isHeader: true),
                  _buildTableCell(
                    CurrencyFormatter.formatWon(_keepCurrentResult!.finalAmount),
                    isHeader: true,
                    color: Colors.blue,
                  ),
                  _buildTableCell(
                    CurrencyFormatter.formatWon(_transferResult!.finalAmount),
                    isHeader: true,
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakEvenAnalysis() {
    final currentRate = CurrencyFormatter.parsePercent(_currentRateController.text);
    final newRate = CurrencyFormatter.parsePercent(_newRateController.text);
    final transferFee = CurrencyFormatter.parseWon(_transferFeeController.text);
    final currentBalance = CurrencyFormatter.parseWon(_currentBalanceController.text);
    
    // Calculate minimum rate difference needed to break even
    final rateDifference = newRate - currentRate;
    final feeRatio = transferFee / currentBalance * 100;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '손익분기점 분석',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.brown.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics, color: Colors.brown, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '이자율 차이 분석',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.brown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• 현재 이자율: ${currentRate.toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '• 새로운 이자율: ${newRate.toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '• 이자율 차이: ${rateDifference > 0 ? '+' : ''}${rateDifference.toStringAsFixed(2)}%p',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: rateDifference > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• 이관 수수료 비중: ${feeRatio.toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
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
                    rateDifference > 0.5 
                      ? '이자율 차이가 충분히 커서 이관을 고려해볼 만합니다.'
                      : '이자율 차이가 작아 이관 수수료를 고려하면 현재 유지가 나을 수 있습니다.',
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