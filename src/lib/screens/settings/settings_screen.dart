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
              // CustomCard(
              //   child: Column(
              //     children: [
              //       _buildSettingItem(
              //         Icons.help_outline,
              //         '사용법 가이드',
              //         '각 계산기의 상세한 사용법을 확인하세요',
              //         onTap: _showHelpDialog,
              //       ),
              //       const Divider(height: 1),
              //       _buildSettingItem(
              //         Icons.calculate,
              //         '계산 공식',
              //         '이자 계산에 사용되는 공식들을 확인하세요',
              //         onTap: _showFormulaDialog,
              //       ),
              //     ],
              //   ),
              // ),
              
              const SizedBox(height: 40),
              
              // Footer
              Center(
                child: Text(
                  '올인원 이자계산기 v1.0.0\\n9가지 도구로 완성하는 스마트 금융계산',
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
                '🏠 메인 기능',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• 이자계산: 9가지 계산 도구'),
              Text('• 내 계좌: 실제 계좌 등록 및 관리'),
              Text('• 설정: 앱 설정 및 도움말'),
              SizedBox(height: 16),
              Text(
                '💰 9가지 이자 계산 도구',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '기본 계산:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 적금 이자계산: 월 납입금의 수익 계산'),
              Text('• 예금 이자계산: 목돈의 수익 계산'),
              SizedBox(height: 8),
              Text(
                '목표 달성 계산:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 적금 필요기간: 목표금액까지 기간'),
              Text('• 예금 필요기간: 목표수익까지 기간'),
              Text('• 적금 목표수익 필요입금액'),
              SizedBox(height: 8),
              Text(
                '비교 분석:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 적금 비교: 여러 적금 상품 비교'),
              Text('• 예금 비교: 여러 예금 상품 비교'),
              Text('• 적금vs예금: 직접 비교 분석'),
              Text('• 예금 갈아타기: 만기 전 변경 분석'),
              SizedBox(height: 16),
              Text(
                '🏦 내 계좌 관리',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• 계좌 등록: 실제 계좌 정보 저장'),
              Text('• 실시간 현황: 현재 잔액, 누적이자'),
              Text('• 만기 정보: D-Day, 예상 수익'),
              Text('• 중도해지: 오늘 해지시 예상이자'),
              Text('• 포트폴리오: 전체 계좌 요약'),
              SizedBox(height: 16),
              Text(
                '⚙️ 고급 설정',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• 세금 설정: 일반과세/비과세/사용자정의'),
              Text('• 이자 방식: 단리/월복리 선택'),
              Text('• 중도해지: 별도 이율 및 계산방식'),
              Text('• 미래 가입일: 예약 계좌 등록 가능'),
              SizedBox(height: 16),
              Text(
                '📱 사용 팁',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• 계산 기록 자동 저장'),
              Text('• 스와이프로 화면 전환'),
              Text('• 길게 눌러 상세 메뉴'),
              Text('• 계산 결과에 따라 최적 상품 추천'),
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
                '🏦 예금 계산',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '단리:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('이자 = 원금 × 연이자율 × (기간/12)'),
              Text('최종금액 = 원금 + 이자'),
              SizedBox(height: 8),
              Text(
                '월복리:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('최종금액 = 원금 × (1 + 월이자율)^기간(월)'),
              Text('월이자율 = 연이자율 ÷ 12'),
              SizedBox(height: 16),
              Text(
                '💰 적금 계산',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '개별 납입 방식 (정확한 계산):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('각 월 납입금별로 운용기간을 계산'),
              Text('1회차 납입: n개월 운용'),
              Text('2회차 납입: (n-1)개월 운용'),
              Text('n회차 납입: 1개월 운용'),
              SizedBox(height: 8),
              Text(
                '단리 계산:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('각 납입분 이자 = 월납입금 × 연이자율 × (운용월수/12)'),
              SizedBox(height: 8),
              Text(
                '월복리 계산:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('각 납입분 이자 = 월납입금 × [(1+월이자율)^운용월수 - 1]'),
              SizedBox(height: 16),
              Text(
                '🛡️ 세금 계산',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• 일반과세: 이자소득세 15.4%'),
              Text('• 비과세: 세금 없음 (0%)'),
              Text('• 사용자 정의: 직접 설정한 세율'),
              Text('세후이자 = 세전이자 - (세전이자 × 세율)'),
              SizedBox(height: 16),
              Text(
                '⚠️ 중도해지 계산',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• 중도해지 이자율: 별도 설정된 낮은 이율'),
              Text('• 계산방식: 단리 또는 월복리 선택 가능'),
              Text('• 적금: 각 납입분별 경과기간으로 계산'),
              Text('• 예금: 가입일부터 해지일까지 기간으로 계산'),
              SizedBox(height: 16),
              Text(
                '📅 기간 계산',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• 월 기준: 정확한 월수 계산'),
              Text('• 일 기준: 30일 = 1개월로 환산'),
              Text('• D-Day: 만료일까지 실제 남은 일수'),
              Text('• 미래 가입: 가입 예정일까지 D+형태 표시'),
              SizedBox(height: 16),
              Text(
                '⚡ 주의사항',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
              ),
              SizedBox(height: 8),
              Text('• 실제 은행과 계산방식이 다를 수 있음'),
              Text('• 은행별 단리/복리 적용 방식 상이'),
              Text('• 만기일 말일 처리 방식 차이 가능'),
              Text('• 정확한 금액은 해당 은행에 문의 필요'),
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