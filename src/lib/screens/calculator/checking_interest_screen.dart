import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../models/calculation_models.dart';
import '../../services/interest_calculator.dart';
import '../../utils/currency_formatter.dart';

class CheckingInterestScreen extends StatefulWidget {
  const CheckingInterestScreen({super.key});

  @override
  State<CheckingInterestScreen> createState() => _CheckingInterestScreenState();
}

class _CheckingInterestScreenState extends State<CheckingInterestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyDepositController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _periodController = TextEditingController();
  final _customTaxRateController = TextEditingController();

  InterestType _interestType = InterestType.compoundMonthly;
  TaxType _taxType = TaxType.normal;
  InterestCalculationResult? _result;
  bool _showResult = false;

  @override
  void dispose() {
    _monthlyDepositController.dispose();
    _interestRateController.dispose();
    _periodController.dispose();
    _customTaxRateController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final monthlyDeposit = CurrencyFormatter.parseWon(_monthlyDepositController.text);
    final interestRate = CurrencyFormatter.parsePercent(_interestRateController.text);
    final period = int.tryParse(_periodController.text) ?? 0;
    final customTaxRate = _taxType == TaxType.custom 
        ? CurrencyFormatter.parsePercent(_customTaxRateController.text)
        : 0.0;

    final input = InterestCalculationInput(
      principal: 0,
      interestRate: interestRate,
      periodMonths: period,
      interestType: _interestType,
      accountType: AccountType.checking,
      taxType: _taxType,
      customTaxRate: customTaxRate,
      monthlyDeposit: monthlyDeposit,
    );

    setState(() {
      _result = InterestCalculator.calculateInterest(input);
      _showResult = true;
    });

    // Scroll to results
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
        title: const Text('적금 이자계산'),
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
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.savings,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '적금 정보 입력',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 20),
                      PeriodInputField(
                        label: '가입기간',
                        controller: _periodController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '가입기간을 입력해주세요';
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
                      const SizedBox(height: 20),
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
                ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '계산하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_showResult && _result != null) ...[
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
          activeColor: AppTheme.primaryColor,
        );
      }).toList(),
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
          activeColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildResultSection() {
    if (_result == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildPieChart(),
        const SizedBox(height: 16),
        _buildDetailsList(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return GradientCard(
      child: Column(
        children: [
          Text(
            '계산 결과',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildResultRow('총 납입원금', _result!.totalAmount - _result!.totalInterest),
          const SizedBox(height: 8),
          _buildResultRow('총 이자수익', _result!.totalInterest),
          const SizedBox(height: 8),
          _buildResultRow('세금', _result!.taxAmount),
          const Divider(color: Colors.white30, height: 24),
          _buildResultRow(
            '최종 수령액',
            _result!.finalAmount,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          CurrencyFormatter.formatWon(amount),
          style: TextStyle(
            color: Colors.white,
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    final principal = _result!.totalAmount - _result!.totalInterest;
    final interest = _result!.totalInterest;
    
    return CustomCard(
      child: Column(
        children: [
          Text(
            '원금 vs 이자 비율',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: principal,
                    title: '${(principal / _result!.totalAmount * 100).toStringAsFixed(1)}%',
                    color: AppTheme.primaryColor,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: interest,
                    title: '${(interest / _result!.totalAmount * 100).toStringAsFixed(1)}%',
                    color: AppTheme.secondaryColor,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('원금', AppTheme.primaryColor, principal),
              const SizedBox(width: 24),
              _buildLegendItem('이자', AppTheme.secondaryColor, interest),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double amount) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              CurrencyFormatter.formatWon(amount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsList() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '월별 상세내역',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: ListView.separated(
              itemCount: _result!.periodResults.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final period = _result!.periodResults[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${period.period}개월'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('원금: ${CurrencyFormatter.formatWon(period.principal)}'),
                      Text('이자: ${CurrencyFormatter.formatWon(period.cumulativeInterest)}'),
                    ],
                  ),
                  trailing: Text(
                    CurrencyFormatter.formatWon(period.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}