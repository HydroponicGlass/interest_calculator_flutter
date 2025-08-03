import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../services/onboarding_service.dart';
import '../../services/calculation_history_service.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Info Section
              _buildSectionHeader('앱 정보'),
              const SizedBox(height: 12),
              CustomCard(
                child: Column(
                  children: [
                    _buildSettingItem(
                      Icons.info_outline,
                      '앱 소개 보기',
                      '앱의 기능과 사용법을 다시 확인하세요',
                      onTap: _showOnboarding,
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      Icons.star_outline,
                      '버전 정보',
                      '1.0.0',
                      showArrow: false,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Data Management Section
              _buildSectionHeader('데이터 관리'),
              const SizedBox(height: 12),
              CustomCard(
                child: Column(
                  children: [
                    _buildSettingItem(
                      Icons.history,
                      '계산 기록 초기화',
                      '저장된 계산 입력값들을 모두 삭제합니다',
                      onTap: _showClearHistoryDialog,
                      iconColor: Colors.orange,
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      Icons.refresh,
                      '앱 초기화',
                      '모든 데이터를 삭제하고 처음 상태로 되돌립니다',
                      onTap: _showResetAppDialog,
                      iconColor: Colors.red,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Help Section
              _buildSectionHeader('도움말'),
              const SizedBox(height: 12),
              CustomCard(
                child: Column(
                  children: [
                    _buildSettingItem(
                      Icons.help_outline,
                      '사용법 가이드',
                      '각 계산기의 상세한 사용법을 확인하세요',
                      onTap: _showHelpDialog,
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      Icons.calculate,
                      '계산 공식',
                      '이자 계산에 사용되는 공식들을 확인하세요',
                      onTap: _showFormulaDialog,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Footer
              Center(
                child: Text(
                  '올인원 이자 계산기 v1.0.0\\n똑똑한 금융 계산의 시작',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    Color? iconColor,
    bool showArrow = true,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: showArrow
          ? const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            )
          : null,
      onTap: onTap,
    );
  }

  void _showOnboarding() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OnboardingScreen(),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계산 기록 초기화'),
        content: const Text(
          '저장된 모든 계산 입력값들이 삭제됩니다.\\n다음에 계산기를 사용할 때 빈 화면으로 시작됩니다.\\n\\n계속하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await CalculationHistoryService.clearAllHistory();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('계산 기록이 초기화되었습니다'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }

  void _showResetAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 초기화'),
        content: const Text(
          '다음 항목들이 모두 삭제됩니다:\\n\\n• 저장된 모든 계좌\\n• 계산 기록\\n• 앱 설정\\n\\n이 작업은 되돌릴 수 없습니다.\\n계속하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await CalculationHistoryService.clearAllHistory();
              await OnboardingService.resetOnboarding();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('앱이 초기화되었습니다. 앱을 재시작해주세요.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용법 가이드'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '💰 이자 계산',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 예금: 목돈을 한 번에 투자하는 상품'),
              Text('• 적금: 매월 일정 금액을 납입하는 상품'),
              SizedBox(height: 12),
              Text(
                '📊 비교 기능',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 여러 금융 상품의 수익률 비교'),
              Text('• 최적의 투자 옵션 선택 도움'),
              SizedBox(height: 12),
              Text(
                '🎯 목표 계산',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 목표 금액 달성 기간 계산'),
              Text('• 목표 달성을 위한 필요 금액 계산'),
              SizedBox(height: 12),
              Text(
                '💾 자동 저장',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 마지막 계산 값들이 자동으로 저장'),
              Text('• 다음 사용 시 자동으로 입력됨'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showFormulaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계산 공식'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🧮 단리 (Simple Interest)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('이자 = 원금 × 이자율 × 기간'),
              SizedBox(height: 12),
              Text(
                '📈 복리 (Compound Interest)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('최종금액 = 원금 × (1 + 이자율)^기간'),
              SizedBox(height: 12),
              Text(
                '💰 적금 (Monthly Deposit)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('각 월 납입금에 대해 남은 기간만큼 이자 적용'),
              SizedBox(height: 12),
              Text(
                '🏦 세금 (Tax)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 일반과세: 15.4%'),
              Text('• 비과세: 0%'),
              Text('• 사용자 정의: 직접 입력'),
              SizedBox(height: 12),
              Text(
                '⚡ 복리 주기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 월복리: 매월 복리 적용'),
              Text('• 일복리: 매일 복리 적용'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}