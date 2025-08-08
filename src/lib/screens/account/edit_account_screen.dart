import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_input_field.dart';
import '../../models/calculation_models.dart';
import '../../providers/account_provider.dart';

class EditAccountScreen extends StatefulWidget {
  final MyAccount account;

  const EditAccountScreen({super.key, required this.account});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _principalController = TextEditingController();
  final _monthlyDepositController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _periodController = TextEditingController();
  final _customTaxRateController = TextEditingController();
  final _earlyTerminationRateController = TextEditingController();

  late AccountType _accountType;
  late InterestType _interestType;
  late InterestType _earlyTerminationInterestType;
  late TaxType _taxType;
  late DateTime _startDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.account.name;
    _bankNameController.text = widget.account.bankName;
    _principalController.text = widget.account.principal > 0 
        ? widget.account.principal.toInt().toString()
        : '';
    _monthlyDepositController.text = widget.account.monthlyDeposit > 0
        ? widget.account.monthlyDeposit.toInt().toString()
        : '';
    _interestRateController.text = widget.account.interestRate.toString();
    _periodController.text = widget.account.periodMonths.toString();
    _customTaxRateController.text = widget.account.customTaxRate.toString();
    _earlyTerminationRateController.text = widget.account.earlyTerminationRate > 0 ? widget.account.earlyTerminationRate.toString() : '';
    
    _accountType = widget.account.accountType;
    _interestType = widget.account.interestType;
    _earlyTerminationInterestType = widget.account.earlyTerminationInterestType;
    _taxType = widget.account.taxType;
    _startDate = widget.account.startDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _principalController.dispose();
    _monthlyDepositController.dispose();
    _interestRateController.dispose();
    _periodController.dispose();
    _customTaxRateController.dispose();
    _earlyTerminationRateController.dispose();
    super.dispose();
  }

  void _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedAccount = MyAccount(
        id: widget.account.id,
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

      await context.read<AccountProvider>().updateAccount(updatedAccount);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계좌가 수정되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계좌 수정 중 오류가 발생했습니다')),
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
        title: const Text('계좌 수정'),
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
                GradientCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '계좌 정보 수정',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '계좌의 기본 정보를 수정할 수 있습니다.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAccount,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
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
                                '저장',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
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
              lastDate: DateTime.now(),
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
                const Icon(Icons.calendar_today, color: AppTheme.textSecondary),
                const SizedBox(width: 12),
                Text(
                  '${_startDate.year}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.day.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodyLarge,
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