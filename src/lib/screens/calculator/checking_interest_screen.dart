import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../widgets/common/disclaimer_card.dart';
import '../../widgets/common/ad_warning_text.dart';
import '../../models/calculation_models.dart';
import '../../services/interest_calculator.dart';
import '../../services/calculation_history_service.dart';
import '../../utils/currency_formatter.dart';
import '../../models/additional_info_models.dart';
import '../../services/additional_info_service.dart';
import '../../widgets/additional_info_card.dart';
import '../../widgets/quick_input_buttons.dart';
import '../../widgets/input_parameter_card.dart';
import '../../providers/ad_provider.dart';

class CheckingInterestScreen extends StatefulWidget {
  const CheckingInterestScreen({super.key});

  @override
  State<CheckingInterestScreen> createState() => _CheckingInterestScreenState();
}

class _CheckingInterestScreenState extends State<CheckingInterestScreen> {
  final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );
  
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _resultSectionKey = GlobalKey();
  final _monthlyDepositController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _periodController = TextEditingController();
  final _customTaxRateController = TextEditingController();

  InterestType _interestType = InterestType.compoundMonthly;
  TaxType _taxType = TaxType.normal;
  InterestCalculationResult? _result;
  AdditionalInfoData? _additionalInfo;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _loadLastInput();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _monthlyDepositController.dispose();
    _interestRateController.dispose();
    _periodController.dispose();
    _customTaxRateController.dispose();
    super.dispose();
  }

  void _loadLastInput() async {
    final lastInput = await CalculationHistoryService.getLastCheckingInput();
    if (lastInput != null && mounted) {
      setState(() {
        if (lastInput['monthlyDeposit'] > 0) {
          _monthlyDepositController.text = CurrencyFormatter.formatWonInput(lastInput['monthlyDeposit']);
        }
        if (lastInput['interestRate'] > 0) {
          _interestRateController.text = lastInput['interestRate'].toString();
        }
        if (lastInput['periodMonths'] > 0) {
          _periodController.text = lastInput['periodMonths'].toString();
        }
        if (lastInput['customTaxRate'] > 0) {
          _customTaxRateController.text = lastInput['customTaxRate'].toString();
        }
        _interestType = lastInput['interestType'];
        _taxType = lastInput['taxType'];
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
      _monthlyDepositController.clear();
      _interestRateController.clear();
      _periodController.clear();
      _customTaxRateController.clear();
      _interestType = InterestType.compoundMonthly;
      _taxType = TaxType.normal;
      _result = null;
      _additionalInfo = null;
      _showResult = false;
    });
  }

  void _calculate() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    // Show ad every 5th calculation
    try {
      final adProvider = context.read<AdProvider>();
      await adProvider.onCalculationButtonPressed();
    } catch (e) {
      _logger.w('⚠️ [적금계산] 광고 표시 중 오류 (무시하고 계속): $e');
    }

    final monthlyDeposit = CurrencyFormatter.parseWon(_monthlyDepositController.text);
    final interestRate = CurrencyFormatter.parsePercent(_interestRateController.text);
    final period = int.tryParse(_periodController.text) ?? 0;
    final customTaxRate = _taxType == TaxType.custom 
        ? CurrencyFormatter.parsePercent(_customTaxRateController.text)
        : 0.0;

    _logger.i('🏦 적금 이자계산 시작');
    _logger.i('📋 입력값:');
    _logger.i('  💵 월 납입금액: ${CurrencyFormatter.formatWon(monthlyDeposit)}');
    _logger.i('  📈 연 이자율: ${interestRate.toStringAsFixed(2)}%');
    _logger.i('  📅 가입기간: $period개월');
    _logger.i('  ⚙️ 계산방식: $_interestType');
    _logger.i('  🏛️ 세금 유형: $_taxType ${_taxType == TaxType.custom ? '($customTaxRate%)' : ''}');

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

    _logger.i('');
    _logger.i('🔢 적금 계산 진행:');
    _logger.i('  💰 총 납입원금: ${CurrencyFormatter.formatWon(monthlyDeposit * period)} (${CurrencyFormatter.formatWon(monthlyDeposit)} × $period개월)');
    _logger.i('  📊 계산 유형: 적금 (매월 납입)');
    _logger.i('  ⚙️ 이자 계산방식: $_interestType');

    // Save the input for next time
    await CalculationHistoryService.saveLastCheckingInput(input);

    final result = InterestCalculator.calculateInterest(input);
    final additionalInfo = AdditionalInfoService.generateAdditionalInfo(input, result);

    final afterTaxInterest = result.totalInterest - result.taxAmount;
    
    _logger.i('');
    _logger.i('📊 계산 결과:');
    _logger.i('  💎 세전 이자수익: ${CurrencyFormatter.formatWon(result.totalInterest)}');
    _logger.i('  🏛️ 세금: ${CurrencyFormatter.formatWon(result.taxAmount)}');
    _logger.i('  💰 세후 이자수익: ${CurrencyFormatter.formatWon(afterTaxInterest)}');
    _logger.i('  🎯 최종 수령액: ${CurrencyFormatter.formatWon(result.finalAmount)}');
    _logger.i('  📈 수익률: ${((afterTaxInterest / (monthlyDeposit * period)) * 100).toStringAsFixed(2)}% (세후 기준)');
    _logger.i('✅ 적금 이자계산 완료');

    setState(() {
      _result = result;
      _additionalInfo = additionalInfo;
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
        title: const Text('적금 이자계산'),
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
                      const SizedBox(height: 20),
                      QuickInputButtons(
                        controller: _periodController,
                        labelText: '가입기간',
                        values: QuickInputConstants.periodValues,
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
                Column(
                  children: [
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
                              side: BorderSide(color: AppTheme.primaryColor),
                            ),
                            child: Text(
                              '초기화',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
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
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: SizedBox()), // Empty space for reset button area
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Consumer<AdProvider>(
                            builder: (context, adProvider, child) {
                              return AdWarningText(
                                type: AdWarningType.calculation,
                                show: adProvider.showCalculationAdWarning,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_showResult && _result != null) ...[
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

    final input = InterestCalculationInput(
      principal: 0, // Not applicable for checking accounts
      interestRate: CurrencyFormatter.parsePercent(_interestRateController.text),
      periodMonths: int.tryParse(_periodController.text) ?? 0,
      interestType: _interestType,
      accountType: AccountType.checking,
      taxType: _taxType,
      customTaxRate: _taxType == TaxType.custom 
          ? CurrencyFormatter.parsePercent(_customTaxRateController.text)
          : 0.0,
      monthlyDeposit: CurrencyFormatter.parseWon(_monthlyDepositController.text),
    );

    return Column(
      children: [
        InputParameterCard(input: input),
        const SizedBox(height: 16),
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildPieChart(),
        const SizedBox(height: 16),
        _buildDetailsList(),
        if (_additionalInfo != null) ...[
          const SizedBox(height: 16),
          AdditionalInfoCard(additionalInfo: _additionalInfo!),
        ],
        const SizedBox(height: 16),
        const DisclaimerCard(),
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
          _buildResultRow('세전 이자수익', _result!.totalInterest),
          const SizedBox(height: 8),
          _buildResultRow('세금', _result!.taxAmount),
          const SizedBox(height: 8),
          _buildResultRow('세후 이자수익', _result!.totalInterest - _result!.taxAmount),
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
    final afterTaxInterest = _result!.totalInterest - _result!.taxAmount;
    final finalTotal = principal + afterTaxInterest;
    
    return CustomCard(
      child: Column(
        children: [
          Text(
            '원금 vs 세후이자 비율',
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
                    title: '${(principal / finalTotal * 100).toStringAsFixed(1)}%',
                    color: AppTheme.primaryColor,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: afterTaxInterest,
                    title: '${(afterTaxInterest / finalTotal * 100).toStringAsFixed(1)}%',
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
              _buildLegendItem('세후이자', AppTheme.secondaryColor, afterTaxInterest),
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
                      Text('세후 누적이자: ${CurrencyFormatter.formatWon(period.afterTaxCumulativeInterest)}'),
                    ],
                  ),
                  trailing: Text(
                    CurrencyFormatter.formatWon(period.afterTaxTotalAmount),
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