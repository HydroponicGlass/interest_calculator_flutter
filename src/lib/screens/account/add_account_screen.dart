import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../widgets/common/ad_warning_text.dart';
import '../../models/calculation_models.dart';
import '../../providers/account_provider.dart';
import '../../providers/ad_provider.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _principalController = TextEditingController();
  final _monthlyDepositController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _periodController = TextEditingController();
  final _customTaxRateController = TextEditingController();
  final _earlyTerminationRateController = TextEditingController();

  final _nameFocus = FocusNode();
  final _bankNameFocus = FocusNode();
  final _principalFocus = FocusNode();
  final _monthlyDepositFocus = FocusNode();
  final _interestRateFocus = FocusNode();
  final _periodFocus = FocusNode();

  AccountType _accountType = AccountType.checking;
  InterestType _interestType = InterestType.compoundMonthly;
  InterestType _earlyTerminationInterestType = InterestType.simple;
  TaxType _taxType = TaxType.normal;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _bankNameController.dispose();
    _principalController.dispose();
    _monthlyDepositController.dispose();
    _interestRateController.dispose();
    _periodController.dispose();
    _customTaxRateController.dispose();
    _earlyTerminationRateController.dispose();
    _nameFocus.dispose();
    _bankNameFocus.dispose();
    _principalFocus.dispose();
    _monthlyDepositFocus.dispose();
    _interestRateFocus.dispose();
    _periodFocus.dispose();
    super.dispose();
  }

  void _scrollToFirstError() {
    // Define focus nodes and their validation checks in order of appearance
    final validationChecks = [
      (_nameFocus, () => _nameController.text.isEmpty),
      (_bankNameFocus, () => _bankNameController.text.isEmpty),
      if (_accountType == AccountType.savings) 
        (_principalFocus, () => _principalController.text.isEmpty),
      if (_accountType == AccountType.checking)
        (_monthlyDepositFocus, () => _monthlyDepositController.text.isEmpty),
      (_interestRateFocus, () => _interestRateController.text.isEmpty),
      (_periodFocus, () => _periodController.text.isEmpty),
    ];

    // Find the first field with an error
    for (final check in validationChecks) {
      final focusNode = check.$1;
      final hasError = check.$2();
      
      if (hasError && focusNode.context != null) {
        // Focus on this field
        focusNode.requestFocus();
        
        // Scroll to make it visible
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent * 0.3, // Scroll to roughly 1/3 down
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
        break;
      }
    }
  }

  void _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      // Find and scroll to the first error field
      _scrollToFirstError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Show ad for account creation
      final adProvider = context.read<AdProvider>();
      await adProvider.onAccountButtonPressed();

      final account = MyAccount(
        name: _nameController.text,
        bankName: _bankNameController.text,
        principal: _accountType == AccountType.savings 
            ? double.tryParse(_principalController.text.replaceAll(',', '')) ?? 0
            : 0,
        monthlyDeposit: _accountType == AccountType.checking
            ? double.tryParse(_monthlyDepositController.text.replaceAll(',', '')) ?? 0
            : 0,
        interestRate: double.tryParse(_interestRateController.text) ?? 0,
        earlyTerminationRate: double.tryParse(_earlyTerminationRateController.text) ?? 0,
        earlyTerminationInterestType: _earlyTerminationInterestType,
        periodMonths: int.tryParse(_periodController.text) ?? 0,
        startDate: _startDate,
        interestType: _interestType,
        accountType: _accountType,
        taxType: _taxType,
        customTaxRate: _taxType == TaxType.custom 
            ? double.tryParse(_customTaxRateController.text) ?? 0
            : 0,
      );

      await context.read<AccountProvider>().addAccount(account);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계좌가 추가되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계좌 추가 중 오류가 발생했습니다')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('계좌 추가'),
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
                      Text(
                        '기본 정보',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomInputField(
                        label: '계좌명',
                        hint: '계좌의 별명을 입력하세요',
                        controller: _nameController,
                        focusNode: _nameFocus,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '계좌명을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        label: '은행명',
                        hint: '은행명을 입력하세요',
                        controller: _bankNameController,
                        focusNode: _bankNameFocus,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '은행명을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildAccountTypeSelector(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '투자 정보',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_accountType == AccountType.savings) ...[
                        CurrencyInputField(
                          label: '초기 입금액',
                          controller: _principalController,
                          focusNode: _principalFocus,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '초기 입금액을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        CurrencyInputField(
                          label: '월 납입금액',
                          controller: _monthlyDepositController,
                          focusNode: _monthlyDepositFocus,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '월 납입금액을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      PercentInputField(
                        label: '연 이자율',
                        controller: _interestRateController,
                        focusNode: _interestRateFocus,
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
                        focusNode: _periodFocus,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '가입기간을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      PercentInputField(
                        label: '중도해지이율 (선택)',
                        controller: _earlyTerminationRateController,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '중도해지 이자 계산 방식',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildEarlyTerminationInterestTypeSelector(),
                      const SizedBox(height: 20),
                      _buildStartDateSelector(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '계산 설정',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveAccount,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              '계좌 추가',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                    Consumer<AdProvider>(
                      builder: (context, adProvider, child) {
                        return AdWarningText(
                          type: AdWarningType.account,
                          show: adProvider.showAccountAdWarning,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '계좌 유형',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<AccountType>(
                title: const Text('적금'),
                subtitle: const Text('정기적금'),
                value: AccountType.checking,
                groupValue: _accountType,
                onChanged: (value) {
                  setState(() {
                    _accountType = value!;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            Expanded(
              child: RadioListTile<AccountType>(
                title: const Text('예금'),
                subtitle: const Text('정기예금'),
                value: AccountType.savings,
                groupValue: _accountType,
                onChanged: (value) {
                  setState(() {
                    _accountType = value!;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStartDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '가입일',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 3650)), // 10년 후까지 선택 가능
              helpText: '가입일 선택',
            );
            if (date != null) {
              setState(() {
                _startDate = date;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _startDate.isAfter(DateTime.now()) 
                      ? Icons.schedule 
                      : Icons.calendar_today, 
                  color: _startDate.isAfter(DateTime.now()) 
                      ? Colors.orange 
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_startDate.year}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.day.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _startDate.isAfter(DateTime.now()) 
                            ? Colors.orange 
                            : null,
                      ),
                    ),
                    if (_startDate.isAfter(DateTime.now()))
                      Text(
                        '가입 예정일',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildEarlyTerminationInterestTypeSelector() {
    return Column(
      children: InterestType.values.map((type) {
        String title = '';
        String subtitle = '';
        
        switch (type) {
          case InterestType.simple:
            title = '단리';
            subtitle = '중도해지시 단리로 계산';
            break;
          case InterestType.compoundMonthly:
            title = '월복리';
            subtitle = '중도해지시 월복리로 계산';
            break;
        }

        return RadioListTile<InterestType>(
          title: Text(title),
          subtitle: Text(subtitle),
          value: type,
          groupValue: _earlyTerminationInterestType,
          onChanged: (value) {
            setState(() {
              _earlyTerminationInterestType = value!;
            });
          },
          activeColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }
}