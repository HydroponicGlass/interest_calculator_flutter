import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../widgets/quick_input_buttons.dart';
import '../../widgets/interest_rate_input_field.dart';
import '../../models/calculation_models.dart';
import '../../services/interest_calculator.dart';
import '../../services/calculation_history_service.dart';
import '../../utils/currency_formatter.dart';

class CheckingTransferScreen extends StatefulWidget {
  const CheckingTransferScreen({super.key});

  @override
  State<CheckingTransferScreen> createState() => _CheckingTransferScreenState();
}

class _CheckingTransferScreenState extends State<CheckingTransferScreen> {
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
  
  final _amountController = TextEditingController();
  final _initialPeriodController = TextEditingController();
  final _elapsedPeriodController = TextEditingController();
  final _currentInterestRateController = TextEditingController();
  final _cancellationInterestRateController = TextEditingController();
  final _newInterestRateController = TextEditingController();

  InterestType _currentInterestType = InterestType.compoundMonthly;
  InterestType _cancellationInterestType = InterestType.simple;
  InterestType _newInterestType = InterestType.compoundMonthly;
  TaxType _taxType = TaxType.normal;
  final _customTaxRateController = TextEditingController();
  
  InterestCalculationResult? _keepCurrentResult;
  InterestCalculationResult? _transferResult;
  InterestCalculationResult? _elapsedResult; // 기존예금 경과기간 결과
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _loadLastInput();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _amountController.dispose();
    _initialPeriodController.dispose();
    _elapsedPeriodController.dispose();
    _currentInterestRateController.dispose();
    _cancellationInterestRateController.dispose();
    _newInterestRateController.dispose();
    _customTaxRateController.dispose();
    super.dispose();
  }

  void _loadLastInput() async {
    final lastInput = await CalculationHistoryService.getLastCheckingTransferInput();
    if (lastInput != null && mounted) {
      setState(() {
        if (lastInput['amount'] != null && lastInput['amount'] > 0) {
          _amountController.text = CurrencyFormatter.formatWonInput(lastInput['amount']);
        }
        if (lastInput['initialPeriod'] != null && lastInput['initialPeriod'] > 0) {
          _initialPeriodController.text = lastInput['initialPeriod'].toString();
        }
        if (lastInput['elapsedPeriod'] != null && lastInput['elapsedPeriod'] > 0) {
          _elapsedPeriodController.text = lastInput['elapsedPeriod'].toString();
        }
        if (lastInput['currentRate'] != null && lastInput['currentRate'] > 0) {
          _currentInterestRateController.text = lastInput['currentRate'].toString();
        }
        if (lastInput['cancellationRate'] != null && lastInput['cancellationRate'] > 0) {
          _cancellationInterestRateController.text = lastInput['cancellationRate'].toString();
        }
        if (lastInput['newRate'] != null && lastInput['newRate'] > 0) {
          _newInterestRateController.text = lastInput['newRate'].toString();
        }
        if (lastInput['customTaxRate'] != null && lastInput['customTaxRate'] > 0) {
          _customTaxRateController.text = lastInput['customTaxRate'].toString();
        }
        
        // Restore interest type selections
        if (lastInput['currentInterestType'] != null) {
          _currentInterestType = InterestType.values[lastInput['currentInterestType']];
        }
        if (lastInput['cancellationInterestType'] != null) {
          _cancellationInterestType = InterestType.values[lastInput['cancellationInterestType']];
        }
        if (lastInput['newInterestType'] != null) {
          _newInterestType = InterestType.values[lastInput['newInterestType']];
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
      _amountController.clear();
      _initialPeriodController.clear();
      _elapsedPeriodController.clear();
      _currentInterestRateController.clear();
      _cancellationInterestRateController.clear();
      _newInterestRateController.clear();
      _customTaxRateController.clear();
      _currentInterestType = InterestType.compoundMonthly;
      _cancellationInterestType = InterestType.simple;
      _newInterestType = InterestType.compoundMonthly;
      _taxType = TaxType.normal;
      _keepCurrentResult = null;
      _transferResult = null;
      _elapsedResult = null;
      _showResult = false;
    });
  }

  void _calculate() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    final amount = CurrencyFormatter.parseWon(_amountController.text);
    final initialPeriod = CurrencyFormatter.parseNumber(_initialPeriodController.text).toInt();
    final elapsedPeriod = CurrencyFormatter.parseNumber(_elapsedPeriodController.text).toInt();
    final remainingPeriod = initialPeriod - elapsedPeriod;
    final currentRate = CurrencyFormatter.parsePercent(_currentInterestRateController.text);
    final cancellationRate = CurrencyFormatter.parsePercent(_cancellationInterestRateController.text);
    final newRate = CurrencyFormatter.parsePercent(_newInterestRateController.text);
    final customTaxRate = _taxType == TaxType.custom 
        ? CurrencyFormatter.parsePercent(_customTaxRateController.text)
        : 0.0;

    _logger.i('💰 예금 갈아타기 계산 시작');
    _logger.i('📋 입력값:');
    _logger.i('  💵 예금 원금: ${CurrencyFormatter.formatWon(amount)}');
    _logger.i('  📅 초기 예치기간: $initialPeriod개월');
    _logger.i('  ⏱️ 경과 기간: $elapsedPeriod개월');
    _logger.i('  ⏳ 남은 기간: $remainingPeriod개월');
    _logger.i('  📈 현재 이자율: ${currentRate.toStringAsFixed(2)}% ($_currentInterestType)');
    _logger.i('  📉 중도해지 이자율: ${cancellationRate.toStringAsFixed(2)}% ($_cancellationInterestType)');
    _logger.i('  🆕 새로운 이자율: ${newRate.toStringAsFixed(2)}% ($_newInterestType)');
    _logger.i('  🏛️ 세금 유형: $_taxType ${_taxType == TaxType.custom ? '($customTaxRate%)' : ''}');

    // Calculate current account value - full period at current rate (예금 유지)
    _logger.i('');
    _logger.i('🔷 1. 현재 유지 시나리오 계산:');
    final currentAccountInput = InterestCalculationInput(
      principal: amount,
      interestRate: currentRate,
      periodMonths: initialPeriod,
      interestType: _currentInterestType,
      accountType: AccountType.savings, // 예금이므로 savings
      taxType: _taxType,
      customTaxRate: customTaxRate,
    );
    _logger.i('  💰 원금: ${CurrencyFormatter.formatWon(amount)}');
    _logger.i('  📊 이자율: ${currentRate.toStringAsFixed(2)}%');
    _logger.i('  📅 기간: $initialPeriod개월');
    _logger.i('  ⚙️ 계산방식: $_currentInterestType');
    
    // Calculate transfer scenario:
    // 1. First calculate elapsed period at cancellation rate
    _logger.i('');
    _logger.i('🔶 2. 이관 시나리오 - 기존예금 중도해지 계산:');
    final elapsedInput = InterestCalculationInput(
      principal: amount,
      interestRate: cancellationRate,
      periodMonths: elapsedPeriod,
      interestType: _cancellationInterestType,
      accountType: AccountType.savings,
      taxType: _taxType,
      customTaxRate: customTaxRate,
    );
    _logger.i('  💰 원금: ${CurrencyFormatter.formatWon(amount)}');
    _logger.i('  📉 중도해지 이자율: ${cancellationRate.toStringAsFixed(2)}%');
    _logger.i('  ⏱️ 경과 기간: $elapsedPeriod개월');
    _logger.i('  ⚙️ 계산방식: $_cancellationInterestType');
    
    final elapsedResult = InterestCalculator.calculateInterest(elapsedInput);
    final elapsedAfterTaxInterest = elapsedResult.totalInterest - elapsedResult.taxAmount;
    _logger.i('  📊 결과:');
    _logger.i('    💎 세전 이자수익: ${CurrencyFormatter.formatWon(elapsedResult.totalInterest)}');
    _logger.i('    💰 세후 이자수익: ${CurrencyFormatter.formatWon(elapsedAfterTaxInterest)}');
    _logger.i('    🏛️ 세금: ${CurrencyFormatter.formatWon(elapsedResult.taxAmount)}');
    _logger.i('    🎯 중도해지 수령액: ${CurrencyFormatter.formatWon(elapsedResult.finalAmount)}');
    
    // 2. Then transfer that amount to new account for remaining period
    _logger.i('');
    _logger.i('🔷 3. 이관 시나리오 - 신규예금 계산:');
    final transferInput = InterestCalculationInput(
      principal: elapsedResult.finalAmount, // 중도해지 후 받은 금액을 새 예금에 투입
      interestRate: newRate,
      periodMonths: remainingPeriod,
      interestType: _newInterestType,
      accountType: AccountType.savings,
      taxType: _taxType,
      customTaxRate: customTaxRate,
    );
    _logger.i('  💰 신규예금 원금: ${CurrencyFormatter.formatWon(elapsedResult.finalAmount)} (중도해지 수령액)');
    _logger.i('  🆕 신규 이자율: ${newRate.toStringAsFixed(2)}%');
    _logger.i('  ⏳ 남은 기간: $remainingPeriod개월');
    _logger.i('  ⚙️ 계산방식: $_newInterestType');
    
    // 원본 앱과의 계산 차이 확인을 위한 추가 로그
    final originalPrincipalInterest = amount * (newRate / 100) * (remainingPeriod / 12);
    _logger.w('🔍 계산 차이 분석:');
    _logger.w('  📊 원본앱 방식 (원금 기준): ${amount.toStringAsFixed(0)} × ${newRate.toStringAsFixed(2)}% × ${remainingPeriod}/12 = ${originalPrincipalInterest.toStringAsFixed(0)}');
    _logger.w('  📊 현재앱 방식 (중도해지액 기준): ${elapsedResult.finalAmount.toStringAsFixed(0)} × ${newRate.toStringAsFixed(2)}% × ${remainingPeriod}/12 = ${(elapsedResult.finalAmount * (newRate / 100) * (remainingPeriod / 12)).toStringAsFixed(0)}');

    // Save the inputs for next time
    final inputData = {
      'amount': amount,
      'initialPeriod': initialPeriod,
      'elapsedPeriod': elapsedPeriod,
      'currentRate': currentRate,
      'cancellationRate': cancellationRate,
      'newRate': newRate,
      'currentInterestType': _currentInterestType.index,
      'cancellationInterestType': _cancellationInterestType.index,
      'newInterestType': _newInterestType.index,
      'taxType': _taxType.index,
      'customTaxRate': customTaxRate,
    };
    await CalculationHistoryService.saveLastCheckingTransferInput(inputData);

    final keepCurrentResult = InterestCalculator.calculateInterest(currentAccountInput);
    final newDepositResult = InterestCalculator.calculateInterest(transferInput);
    
    _logger.i('');
    _logger.i('📊 4. 계산 결과:');
    final keepCurrentAfterTaxInterest = keepCurrentResult.totalInterest - keepCurrentResult.taxAmount;
    _logger.i('🔷 현재 유지 결과:');
    _logger.i('  💎 세전 이자수익: ${CurrencyFormatter.formatWon(keepCurrentResult.totalInterest)}');
    _logger.i('  💰 세후 이자수익: ${CurrencyFormatter.formatWon(keepCurrentAfterTaxInterest)}');
    _logger.i('  🏛️ 세금: ${CurrencyFormatter.formatWon(keepCurrentResult.taxAmount)}');
    _logger.i('  🎯 최종 수령액: ${CurrencyFormatter.formatWon(keepCurrentResult.finalAmount)}');
    
    final newDepositAfterTaxInterest = newDepositResult.totalInterest - newDepositResult.taxAmount;
    _logger.i('');
    _logger.i('🔷 신규예금 추가 결과:');
    _logger.i('  💎 신규예금 세전이자: ${CurrencyFormatter.formatWon(newDepositResult.totalInterest)}');
    _logger.i('  💰 신규예금 세후이자: ${CurrencyFormatter.formatWon(newDepositAfterTaxInterest)}');
    _logger.i('  🏛️ 신규예금 세금: ${CurrencyFormatter.formatWon(newDepositResult.taxAmount)}');
    _logger.i('  🎯 신규예금 최종 수령액: ${CurrencyFormatter.formatWon(newDepositResult.finalAmount)}');
    
    // 이관 후 전체 결과 (기존예금 + 신규예금)
    final totalTransferInterest = elapsedResult.totalInterest + newDepositResult.totalInterest;
    final totalTransferAfterTaxInterest = elapsedAfterTaxInterest + newDepositAfterTaxInterest;
    final totalTransferTax = elapsedResult.taxAmount + newDepositResult.taxAmount;
    final totalTransferAmount = newDepositResult.finalAmount;  // 신규예금 최종 수령액이 전체 최종액
    
    _logger.i('');
    _logger.i('🔶 이관 후 전체 결과:');
    _logger.i('  💎 전체 세전이자: ${CurrencyFormatter.formatWon(totalTransferInterest)} (기존: ${CurrencyFormatter.formatWon(elapsedResult.totalInterest)} + 신규: ${CurrencyFormatter.formatWon(newDepositResult.totalInterest)})');
    _logger.i('  💰 전체 세후이자: ${CurrencyFormatter.formatWon(totalTransferAfterTaxInterest)} (기존: ${CurrencyFormatter.formatWon(elapsedAfterTaxInterest)} + 신규: ${CurrencyFormatter.formatWon(newDepositAfterTaxInterest)})');
    _logger.i('  🏛️ 전체 세금: ${CurrencyFormatter.formatWon(totalTransferTax)}');
    _logger.i('  🎯 최종 수령액: ${CurrencyFormatter.formatWon(totalTransferAmount)}');
    
    final difference = totalTransferAmount - keepCurrentResult.finalAmount;
    _logger.i('');
    _logger.i('🏆 5. 비교 결과:');
    _logger.i('  📈 수익 차이: ${CurrencyFormatter.formatWon(difference.abs())} ${difference >= 0 ? '이관이 유리' : '현재 유지가 유리'}');
    _logger.i('  💡 추천: ${difference >= 0 ? '이관 권장' : '현재 유지 권장'}');
    _logger.i('✅ 예금 갈아타기 계산 완료');

    setState(() {
      _keepCurrentResult = keepCurrentResult;
      _elapsedResult = elapsedResult; // 기존예금 경과기간 결과 저장
      _transferResult = newDepositResult;
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
        title: const Text('예금 갈아타기'),
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
                            '현재 예금 정보',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      QuickInputButtons(
                        controller: _amountController,
                        labelText: '예금 금액',
                        values: QuickInputConstants.amountValues,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '예금 금액을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      QuickInputButtons(
                        controller: _initialPeriodController,
                        labelText: '초기 예치 기간',
                        values: QuickInputConstants.periodValues,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '초기 예치 기간을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      QuickInputButtons(
                        controller: _elapsedPeriodController,
                        labelText: '현재까지 경과 기간',
                        values: QuickInputConstants.periodValues,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '경과 기간을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      InterestRateInputField(
                        label: '현재 이자율',
                        controller: _currentInterestRateController,
                        initialInterestType: _currentInterestType,
                        onInterestTypeChanged: (type) {
                          setState(() {
                            _currentInterestType = type;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '현재 이자율을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      InterestRateInputField(
                        label: '중도해지 이자율',
                        controller: _cancellationInterestRateController,
                        initialInterestType: _cancellationInterestType,
                        onInterestTypeChanged: (type) {
                          setState(() {
                            _cancellationInterestType = type;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '중도해지 이자율을 입력해주세요';
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
                            '새로운 예금 정보',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      InterestRateInputField(
                        label: '새로운 이자율',
                        controller: _newInterestRateController,
                        initialInterestType: _newInterestType,
                        onInterestTypeChanged: (type) {
                          setState(() {
                            _newInterestType = type;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '새로운 이자율을 입력해주세요';
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
                          side: const BorderSide(color: Colors.brown),
                        ),
                        child: const Text(
                          '초기화',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.brown,
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
                    ),
                  ],
                ),
                
                if (_showResult && _keepCurrentResult != null && _transferResult != null && _elapsedResult != null) ...[
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


  Widget _buildTransferAnalysis() {
    // 이관 후 전체 결과 계산
    final totalTransferAmount = _transferResult!.finalAmount; // 신규예금 최종 수령액이 전체 최종액
    final isTransferBetter = totalTransferAmount > _keepCurrentResult!.finalAmount;
    final difference = (totalTransferAmount - _keepCurrentResult!.finalAmount).abs();
    final currentRate = CurrencyFormatter.parsePercent(_currentInterestRateController.text);
    final newRate = CurrencyFormatter.parsePercent(_newInterestRateController.text);

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
              child: _buildTransferResultCard(
                '이관 후',
                Colors.green,
                totalTransferAmount,
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

  Widget _buildTransferResultCard(
    String title,
    Color color,
    double finalAmount,
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
            CurrencyFormatter.formatWon(finalAmount),
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
    final amount = CurrencyFormatter.parseWon(_amountController.text);
    final initialPeriod = CurrencyFormatter.parseNumber(_initialPeriodController.text).toInt();
    final elapsedPeriod = CurrencyFormatter.parseNumber(_elapsedPeriodController.text).toInt();
    final remainingPeriod = initialPeriod - elapsedPeriod;

    // 이관 후 전체 결과 계산
    final totalTransferInterest = _elapsedResult!.totalInterest + _transferResult!.totalInterest;
    final totalTransferTax = _elapsedResult!.taxAmount + _transferResult!.taxAmount;
    final totalTransferAmount = _transferResult!.finalAmount; // 신규예금 최종 수령액이 전체 최종액
    
    // 신규예금만의 이자
    final newDepositInterest = _transferResult!.totalInterest;

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
                  _buildTableCell('예금 원금'),
                  _buildTableCell(CurrencyFormatter.formatWon(amount)),
                  _buildTableCell(CurrencyFormatter.formatWon(amount)),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('예치 기간'),
                  _buildTableCell('$initialPeriod개월'),
                  _buildTableCell('$elapsedPeriod+$remainingPeriod개월'),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('기존예금 이자'),
                  _buildTableCell(CurrencyFormatter.formatWon(_keepCurrentResult!.totalInterest)),
                  _buildTableCell(CurrencyFormatter.formatWon(_elapsedResult!.totalInterest)),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('신규예금 이자\n(중도해지액 기준)', isSmallText: true),
                  _buildTableCell('-'),
                  _buildTableCell(CurrencyFormatter.formatWon(newDepositInterest)),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade50),
                children: [
                  _buildTableCell('총 이자수익', isHeader: true),
                  _buildTableCell(
                    CurrencyFormatter.formatWon(_keepCurrentResult!.totalInterest), 
                    isHeader: true,
                    color: Colors.blue,
                  ),
                  _buildTableCell(
                    CurrencyFormatter.formatWon(totalTransferInterest), 
                    isHeader: true,
                    color: Colors.green,
                  ),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('세금'),
                  _buildTableCell(CurrencyFormatter.formatWon(_keepCurrentResult!.taxAmount)),
                  _buildTableCell(CurrencyFormatter.formatWon(totalTransferTax)),
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
                    CurrencyFormatter.formatWon(totalTransferAmount),
                    isHeader: true,
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalculationExplanation(),
        ],
      ),
    );
  }

  Widget _buildCalculationExplanation() {
    final amount = CurrencyFormatter.parseWon(_amountController.text);
    final elapsedPeriod = CurrencyFormatter.parseNumber(_elapsedPeriodController.text).toInt();
    final remainingPeriod = CurrencyFormatter.parseNumber(_initialPeriodController.text).toInt() - elapsedPeriod;
    final newRate = CurrencyFormatter.parsePercent(_newInterestRateController.text);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                '신규예금 이자 계산 방식',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• 중도해지 수령액(${CurrencyFormatter.formatWon(_elapsedResult?.finalAmount ?? 0)})을 신규예금 원금으로 사용',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '• 신규예금 이자 = ${CurrencyFormatter.formatWon(_elapsedResult?.finalAmount ?? 0)} × ${newRate.toStringAsFixed(1)}% × $remainingPeriod개월/12',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '• 실제 투입 자금을 기준으로 한 정확한 복리 계산',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakEvenAnalysis() {
    final currentRate = CurrencyFormatter.parsePercent(_currentInterestRateController.text);
    final cancellationRate = CurrencyFormatter.parsePercent(_cancellationInterestRateController.text);
    final newRate = CurrencyFormatter.parsePercent(_newInterestRateController.text);
    
    // Calculate actual interest benefits/losses for decision making
    final totalCurrentAmount = _keepCurrentResult?.finalAmount ?? 0;
    final totalTransferAmount = _transferResult?.finalAmount ?? 0;
    final actualDifference = totalTransferAmount - totalCurrentAmount;
    final isTransferBetter = actualDifference > 0;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이관 분석',
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
                      '이자율 현황',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.brown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• 현재 예금 이자율: ${currentRate.toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '• 중도해지시 적용 이자율: ${cancellationRate.toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '• 신규 예금 이자율: ${newRate.toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.brown.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Text(
                  '실제 수익 차이:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${CurrencyFormatter.formatWon(actualDifference.abs())} ${isTransferBetter ? '더 많은' : '더 적은'} 수익',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isTransferBetter ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
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
                Icon(
                  isTransferBetter ? Icons.trending_up : Icons.trending_down,
                  color: isTransferBetter ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTransferBetter 
                      ? '이관을 권장합니다. 높은 신규 이자율로 인해 중도해지 손실을 상쇄하고도 더 많은 수익을 얻을 수 있습니다.'
                      : '현재 예금을 유지하는 것이 좋습니다. 중도해지로 인한 손실이 신규 예금의 이익보다 큽니다.',
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

  Widget _buildTableCell(String text, {bool isHeader = false, Color? color, bool isSmallText = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: (isSmallText ? Theme.of(context).textTheme.bodySmall : Theme.of(context).textTheme.bodyMedium)?.copyWith(
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
          color: color,
          height: isSmallText ? 1.3 : null,
        ),
      ),
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
          activeColor: Colors.brown,
        );
      }).toList(),
    );
  }
}