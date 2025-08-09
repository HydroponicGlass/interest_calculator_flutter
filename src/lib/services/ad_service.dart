import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../admob/ad_helper.dart';
import '../admob/interstitial_ad_manager.dart';
import '../config/ad_config.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: false,
    ),
  );

  InterstitialAdManager? _calculationAdManager;
  InterstitialAdManager? _accountAdManager;
  int _calculationCount = 0;
  // Configuration from AdConfig
  int _calculationThreshold = AdConfig.calculationsPerAd;

  /// Initialize the ad service and load shared preferences
  Future<void> initialize() async {
    _logger.i('🎯 [광고] AdService 초기화 시작 - 광고 주기: ${_calculationThreshold}회마다');
    await _loadCalculationCount();
    _initializeAdManagers();
    _logger.i('🎯 [광고] AdService 초기화 완료 - 계산 횟수: $_calculationCount/${_calculationThreshold}');
  }

  /// Initialize ad managers
  void _initializeAdManagers() {
    _logger.d('🎯 [광고] AdManager 초기화');
    
    // Initialize calculation ad manager
    _calculationAdManager = InterstitialAdManager(AdHelper.calculationInterstitialAdUnitId);
    _calculationAdManager!.loadAd();
    
    // Set up callback to reload ad after dismissal
    _calculationAdManager!.onAdDismissedCallback = () {
      _logger.i('✅ [광고] 계산 광고 닫힘 - 새 광고 로딩');
      _calculationAdManager!.loadAd();
    };
    
    // Initialize account ad manager  
    _accountAdManager = InterstitialAdManager(AdHelper.newAccountInterstitialAdUnitId);
    _accountAdManager!.loadAd();
    
    // Set up callback to reload ad after dismissal
    _accountAdManager!.onAdDismissedCallback = () {
      _logger.i('✅ [광고] 계좌 광고 닫힘 - 새 광고 로딩');
      _accountAdManager!.loadAd();
    };
  }

  /// Load calculation count from SharedPreferences
  Future<void> _loadCalculationCount() async {
    final prefs = await SharedPreferences.getInstance();
    _calculationCount = prefs.getInt('calculation_count') ?? 0;
    _logger.d('📊 [광고] 저장된 계산 횟수 로드: $_calculationCount');
  }

  /// Save calculation count to SharedPreferences
  Future<void> _saveCalculationCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('calculation_count', _calculationCount);
    _logger.d('💾 [광고] 계산 횟수 저장: $_calculationCount');
  }


  /// Increment calculation count and check if ad should be shown
  Future<bool> onCalculationButtonPressed() async {
    _calculationCount++;
    await _saveCalculationCount();
    
    _logger.d('🔢 [광고] 계산 버튼 클릭 - 총 횟수: $_calculationCount (${_calculationCount % _calculationThreshold}/$_calculationThreshold)');
    
    if (_calculationCount % _calculationThreshold == 0) {
      _logger.i('🎯 [광고] 계산 ${_calculationThreshold}회 달성 - 광고 표시 예정');
      return _showCalculationAd();
    }
    return false;
  }

  /// Show interstitial ad for account creation (always)
  Future<bool> onAccountButtonPressed() async {
    _logger.i('🏦 [광고] 계좌 생성 버튼 클릭 - 광고 표시 예정');
    return _showAccountAd();
  }

  /// Show calculation interstitial ad if loaded
  bool _showCalculationAd() {
    if (_calculationAdManager != null && isCalculationAdLoaded) {
      _logger.i('📺 [광고] 계산 전면광고 표시 시작');
      _calculationAdManager!.show();
      return true;
    } else {
      _logger.w('⚠️ [광고] 계산 전면광고가 준비되지 않음 - 로드상태: ${_calculationAdManager?.isAdLoadedNotifier.value}');
      // Try to reload ad for next time  
      if (_calculationAdManager != null) {
        _calculationAdManager!.loadAd();
      }
      return false;
    }
  }

  /// Show account interstitial ad if loaded
  bool _showAccountAd() {
    if (_accountAdManager != null && isAccountAdLoaded) {
      _logger.i('📺 [광고] 계좌 전면광고 표시 시작');
      _accountAdManager!.show();
      return true;
    } else {
      _logger.w('⚠️ [광고] 계좌 전면광고가 준비되지 않음 - 로드상태: ${_accountAdManager?.isAdLoadedNotifier.value}');
      // Try to reload ad for next time
      if (_accountAdManager != null) {
        _accountAdManager!.loadAd();
      }
      return false;
    }
  }

  /// Check if calculation count should trigger ad
  bool shouldShowCalculationAd() {
    final remaining = _calculationThreshold - (_calculationCount % _calculationThreshold);
    return remaining == 1; // Show warning when 1 click away from ad
  }

  /// Get remaining calculations until next ad
  int getRemainingCalculations() {
    return _calculationThreshold - (_calculationCount % _calculationThreshold);
  }

  /// Get current calculation count
  int get calculationCount => _calculationCount;

  /// Check if calculation ad is loaded and ready
  bool get isCalculationAdLoaded => _calculationAdManager?.isAdLoadedNotifier.value.name == 'success';

  /// Check if account ad is loaded and ready
  bool get isAccountAdLoaded => _accountAdManager?.isAdLoadedNotifier.value.name == 'success';

  /// Get current ad threshold configuration
  int get calculationThreshold => _calculationThreshold;

  /// Set ad threshold configuration (for easy configuration)
  void setCalculationThreshold(int threshold) {
    if (threshold > 0) {
      _calculationThreshold = threshold;
      _logger.i('⚙️ [광고] 광고 표시 주기 변경: ${threshold}회마다');
    }
  }

  /// Dispose of resources
  void dispose() {
    _logger.i('🔄 [광고] AdService 리소스 해제');
    _calculationAdManager = null;
    _accountAdManager = null;
  }

  /// Reset calculation count (for testing purposes)
  Future<void> resetCalculationCount() async {
    _calculationCount = 0;
    await _saveCalculationCount();
    _logger.i('🔄 [광고] 계산 횟수 초기화');
  }
}