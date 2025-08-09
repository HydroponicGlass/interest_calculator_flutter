import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../widgets/common/disclaimer_card.dart';
import '../../widgets/quick_input_buttons.dart';
import '../../models/calculation_models.dart';
import '../../services/interest_calculator.dart';
import '../../services/calculation_history_service.dart';
import '../../utils/currency_formatter.dart';
import '../../providers/ad_provider.dart';
import '../../widgets/common/ad_warning_text.dart';

class CheckingSavingsCompareScreen extends StatefulWidget {
  const CheckingSavingsCompareScreen({super.key});

  @override
  State<CheckingSavingsCompareScreen> createState() => _CheckingSavingsCompareScreenState();
}

class _CheckingSavingsCompareScreenState extends State<CheckingSavingsCompareScreen> {
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
  
  // 적금 관련 컨트롤러
  final _checkingAmountController = TextEditingController(); // 적금 월납입금액
  final _checkingInterestRateController = TextEditingController(); // 적금 연 이자율
  final _checkingPeriodController = TextEditingController(); // 적금 기간
  final _checkingCustomTaxRateController = TextEditingController(); // 적금 사용자 정의 세율

  // 예금 관련 컨트롤러
  final _savingsAmountController = TextEditingController(); // 예금 예치금액
  final _savingsInterestRateController = TextEditingController(); // 예금 연 이자율
  final _savingsPeriodController = TextEditingController(); // 예금 기간
  final _savingsCustomTaxRateController = TextEditingController(); // 예금 사용자 정의 세율

  // 적금 설정
  InterestType _checkingInterestType = InterestType.compoundMonthly;
  TaxType _checkingTaxType = TaxType.normal;
  
  // 예금 설정
  InterestType _savingsInterestType = InterestType.compoundMonthly;
  TaxType _savingsTaxType = TaxType.normal;
  
  InterestCalculationResult? _checkingResult;
  InterestCalculationResult? _savingsResult;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _loadLastInput();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // 적금 컨트롤러 dispose
    _checkingAmountController.dispose();
    _checkingInterestRateController.dispose();
    _checkingPeriodController.dispose();
    _checkingCustomTaxRateController.dispose();
    // 예금 컨트롤러 dispose
    _savingsAmountController.dispose();
    _savingsInterestRateController.dispose();
    _savingsPeriodController.dispose();
    _savingsCustomTaxRateController.dispose();
    super.dispose();
  }

  void _loadLastInput() async {
    final lastInput = await CalculationHistoryService.getLastCheckingSavingsCompareInput();
    if (lastInput != null && mounted) {
      setState(() {
        // 적금 데이터 로드
        if (lastInput['checkingAmount'] != null && lastInput['checkingAmount'] > 0) {
          _checkingAmountController.text = CurrencyFormatter.formatWonInput(lastInput['checkingAmount']);
        }
        if (lastInput['checkingInterestRate'] != null && lastInput['checkingInterestRate'] > 0) {
          _checkingInterestRateController.text = lastInput['checkingInterestRate'].toString();
        }
        if (lastInput['checkingPeriod'] != null && lastInput['checkingPeriod'] > 0) {
          _checkingPeriodController.text = lastInput['checkingPeriod'].toString();
        }
        if (lastInput['checkingInterestType'] != null) {
          _checkingInterestType = InterestType.values[lastInput['checkingInterestType']];
        }
        if (lastInput['checkingTaxType'] != null) {
          _checkingTaxType = TaxType.values[lastInput['checkingTaxType']];
        }
        if (lastInput['checkingCustomTaxRate'] != null && lastInput['checkingCustomTaxRate'] > 0) {
          _checkingCustomTaxRateController.text = lastInput['checkingCustomTaxRate'].toString();
        }
        
        // 예금 데이터 로드
        if (lastInput['savingsAmount'] != null && lastInput['savingsAmount'] > 0) {
          _savingsAmountController.text = CurrencyFormatter.formatWonInput(lastInput['savingsAmount']);
        }
        if (lastInput['savingsInterestRate'] != null && lastInput['savingsInterestRate'] > 0) {
          _savingsInterestRateController.text = lastInput['savingsInterestRate'].toString();
        }
        if (lastInput['savingsPeriod'] != null && lastInput['savingsPeriod'] > 0) {
          _savingsPeriodController.text = lastInput['savingsPeriod'].toString();
        }
        if (lastInput['savingsInterestType'] != null) {
          _savingsInterestType = InterestType.values[lastInput['savingsInterestType']];
        }
        if (lastInput['savingsTaxType'] != null) {
          _savingsTaxType = TaxType.values[lastInput['savingsTaxType']];
        }
        if (lastInput['savingsCustomTaxRate'] != null && lastInput['savingsCustomTaxRate'] > 0) {
          _savingsCustomTaxRateController.text = lastInput['savingsCustomTaxRate'].toString();
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
      _checkingAmountController.clear();
      _checkingInterestRateController.clear();
      _checkingPeriodController.clear();
      _checkingCustomTaxRateController.clear();
      _savingsAmountController.clear();
      _savingsInterestRateController.clear();
      _savingsPeriodController.clear();
      _savingsCustomTaxRateController.clear();
      _checkingInterestType = InterestType.compoundMonthly;
      _checkingTaxType = TaxType.normal;
      _savingsInterestType = InterestType.compoundMonthly;
      _savingsTaxType = TaxType.normal;
      _checkingResult = null;
      _savingsResult = null;
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
      _logger.w('⚠️ [계산] 광고 표시 중 오류 (무시하고 계속): $e');
    }

    _logger.i('⚔️ [적금 vs 예금 비교] 계산 시작');

    // 적금 입력값 파싱
    final checkingAmount = CurrencyFormatter.parseWon(_checkingAmountController.text);
    final checkingInterestRate = CurrencyFormatter.parsePercent(_checkingInterestRateController.text);
    final checkingPeriod = CurrencyFormatter.parseNumber(_checkingPeriodController.text).toInt();
    final checkingCustomTaxRate = _checkingTaxType == TaxType.custom 
        ? CurrencyFormatter.parsePercent(_checkingCustomTaxRateController.text)
        : 0.0;
    
    // 예금 입력값 파싱
    final savingsAmount = CurrencyFormatter.parseWon(_savingsAmountController.text);
    final savingsInterestRate = CurrencyFormatter.parsePercent(_savingsInterestRateController.text);
    final savingsPeriod = CurrencyFormatter.parseNumber(_savingsPeriodController.text).toInt();
    final savingsCustomTaxRate = _savingsTaxType == TaxType.custom 
        ? CurrencyFormatter.parsePercent(_savingsCustomTaxRateController.text)
        : 0.0;

    // Log input values
    _logger.i('📊 [적금 입력값] 금액: ${CurrencyFormatter.formatWon(checkingAmount)}, '
        '이자율: ${checkingInterestRate.toStringAsFixed(2)}%, 기간: ${checkingPeriod}개월, '
        '계산방식: ${_checkingInterestType == InterestType.simple ? "단리" : "월복리"}, '
        '세금유형: $_checkingTaxType ${_checkingTaxType == TaxType.custom ? '($checkingCustomTaxRate%)' : ''}');
    
    _logger.i('📊 [예금 입력값] 금액: ${CurrencyFormatter.formatWon(savingsAmount)}, '
        '이자율: ${savingsInterestRate.toStringAsFixed(2)}%, 기간: ${savingsPeriod}개월, '
        '계산방식: ${_savingsInterestType == InterestType.simple ? "단리" : "월복리"}, '
        '세금유형: $_savingsTaxType ${_savingsTaxType == TaxType.custom ? '($savingsCustomTaxRate%)' : ''}');

    // Calculate for checking account (monthly deposits)
    final checkingInput = InterestCalculationInput(
      principal: 0,
      interestRate: checkingInterestRate,
      periodMonths: checkingPeriod,
      interestType: _checkingInterestType,
      accountType: AccountType.checking,
      taxType: _checkingTaxType,
      customTaxRate: checkingCustomTaxRate,
      monthlyDeposit: checkingAmount,
    );
    
    // Calculate for savings account (lump sum)
    final savingsInput = InterestCalculationInput(
      principal: savingsAmount,
      interestRate: savingsInterestRate,
      periodMonths: savingsPeriod,
      interestType: _savingsInterestType,
      accountType: AccountType.savings,
      taxType: _savingsTaxType,
      customTaxRate: savingsCustomTaxRate,
      monthlyDeposit: 0,
    );

    // Calculate results
    final checkingResult = InterestCalculator.calculateInterest(checkingInput);
    final savingsResult = InterestCalculator.calculateInterest(savingsInput);

    // Log calculation results
    _logger.i('🧮 [적금 계산결과] 총납입: ${CurrencyFormatter.formatWon(checkingAmount * checkingPeriod)}, '
        '이자수익: ${CurrencyFormatter.formatWon(checkingResult.totalInterest)}, '
        '세금: ${CurrencyFormatter.formatWon(checkingResult.taxAmount)}, '
        '세후수령액: ${CurrencyFormatter.formatWon(checkingResult.finalAmount)}');
    
    _logger.i('🧮 [예금 계산결과] 원금: ${CurrencyFormatter.formatWon(savingsAmount)}, '
        '이자수익: ${CurrencyFormatter.formatWon(savingsResult.totalInterest)}, '
        '세금: ${CurrencyFormatter.formatWon(savingsResult.taxAmount)}, '
        '세후수령액: ${CurrencyFormatter.formatWon(savingsResult.finalAmount)}');

    // Log comparison results
    final betterOption = savingsResult.finalAmount > checkingResult.finalAmount ? '예금' : '적금';
    final difference = (savingsResult.finalAmount - checkingResult.finalAmount).abs();
    final profitDiffPercent = (difference / (checkingResult.finalAmount < savingsResult.finalAmount ? checkingResult.finalAmount : savingsResult.finalAmount) * 100);
    
    _logger.i('🏆 [비교 결과] $betterOption이 유리함! '
        '차이: ${CurrencyFormatter.formatWon(difference)} (${profitDiffPercent.toStringAsFixed(2)}% 더 유리)');
    
    // Log the reason for better option
    if (savingsResult.finalAmount > checkingResult.finalAmount) {
      _logger.i('📊 [예금 유리 이유] 전체 금액을 처음부터 예치하여 더 긴 기간동안 복리 효과를 받음');
    } else {
      _logger.i('📊 [적금 유리 이유] 매월 분할 납입으로 초기 자금 부담이 적고, 단계적으로 복리 효과를 누림');
    }

    // Save the inputs for next time
    final inputData = {
      // 적금 데이터
      'checkingAmount': checkingAmount,
      'checkingInterestRate': checkingInterestRate,
      'checkingPeriod': checkingPeriod,
      'checkingInterestType': _checkingInterestType.index,
      'checkingTaxType': _checkingTaxType.index,
      'checkingCustomTaxRate': checkingCustomTaxRate,
      // 예금 데이터
      'savingsAmount': savingsAmount,
      'savingsInterestRate': savingsInterestRate,
      'savingsPeriod': savingsPeriod,
      'savingsInterestType': _savingsInterestType.index,
      'savingsTaxType': _savingsTaxType.index,
      'savingsCustomTaxRate': savingsCustomTaxRate,
    };
    await CalculationHistoryService.saveLastCheckingSavingsCompareInput(inputData);

    setState(() {
      _checkingResult = checkingResult;
      _savingsResult = savingsResult;
      _showResult = true;
    });

    _logger.i('✅ [적금 vs 예금 비교] 계산 완료 및 결과 표시');

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
        title: const Text('적금 vs 예금 비교'),
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
                      Text(
                        '각 상품의 조건을 별도로 입력하여 비교하세요',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // 적금 섹션
                _buildCheckingSection(),
                
                const SizedBox(height: 24),
                
                // VS Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
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
                
                // 예금 섹션
                _buildSavingsSection(),
                
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
                              side: const BorderSide(color: Colors.deepOrange),
                            ),
                            child: const Text(
                              '초기화',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepOrange,
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
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: SizedBox()),
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
                
                if (_showResult && _checkingResult != null && _savingsResult != null) ...[
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


  Widget _buildComparisonResults() {
    final betterOption = _savingsResult!.finalAmount > _checkingResult!.finalAmount ? '예금' : '적금';
    final difference = (_savingsResult!.finalAmount - _checkingResult!.finalAmount).abs();
    final savingsAmount = CurrencyFormatter.parseWon(_savingsAmountController.text);
    final checkingAmount = CurrencyFormatter.parseWon(_checkingAmountController.text);
    final checkingPeriod = CurrencyFormatter.parseNumber(_checkingPeriodController.text).toInt();
    final savingsPeriod = CurrencyFormatter.parseNumber(_savingsPeriodController.text).toInt();

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
                '매월 ${CurrencyFormatter.formatWon(checkingAmount)} 납입',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildResultCard(
                '예금',
                Colors.green,
                _savingsResult!,
                '일시 ${CurrencyFormatter.formatWon(savingsAmount)} 예치',
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
    final savingsAmount = CurrencyFormatter.parseWon(_savingsAmountController.text);
    final checkingAmount = CurrencyFormatter.parseWon(_checkingAmountController.text);
    final checkingPeriod = CurrencyFormatter.parseNumber(_checkingPeriodController.text).toInt();
    final savingsPeriod = CurrencyFormatter.parseNumber(_savingsPeriodController.text).toInt();
    final totalCheckingPrincipal = checkingAmount * checkingPeriod;
    final totalSavingsPrincipal = savingsAmount;

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

  Widget _buildCheckingSection() {
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
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '적금 상품',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          QuickInputButtons(
            controller: _checkingAmountController,
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
            controller: _checkingInterestRateController,
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
            controller: _checkingPeriodController,
            labelText: '기간',
            values: QuickInputConstants.periodValues,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '기간을 입력해주세요';
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
          _buildInterestTypeSelector(_checkingInterestType, (value) {
            setState(() {
              _checkingInterestType = value!;
            });
          }, Colors.blue),
          const SizedBox(height: 16),
          Text(
            '세금 설정',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildTaxTypeSelector(_checkingTaxType, (value) {
            setState(() {
              _checkingTaxType = value!;
            });
          }, Colors.blue),
          if (_checkingTaxType == TaxType.custom) ...[
            const SizedBox(height: 12),
            PercentInputField(
              label: '사용자 정의 세율',
              controller: _checkingCustomTaxRateController,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSavingsSection() {
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
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '예금 상품',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          QuickInputButtons(
            controller: _savingsAmountController,
            labelText: '예치금액',
            values: QuickInputConstants.amountValues,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '예치금액을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          QuickInputButtons(
            controller: _savingsInterestRateController,
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
            controller: _savingsPeriodController,
            labelText: '기간',
            values: QuickInputConstants.periodValues,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '기간을 입력해주세요';
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
          _buildInterestTypeSelector(_savingsInterestType, (value) {
            setState(() {
              _savingsInterestType = value!;
            });
          }, Colors.green),
          const SizedBox(height: 16),
          Text(
            '세금 설정',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildTaxTypeSelector(_savingsTaxType, (value) {
            setState(() {
              _savingsTaxType = value!;
            });
          }, Colors.green),
          if (_savingsTaxType == TaxType.custom) ...[
            const SizedBox(height: 12),
            PercentInputField(
              label: '사용자 정의 세율',
              controller: _savingsCustomTaxRateController,
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
}