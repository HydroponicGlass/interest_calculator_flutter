import 'package:flutter/foundation.dart';
import '../services/ad_service.dart';

class AdProvider extends ChangeNotifier {
  final AdService _adService = AdService();
  bool _isInitialized = false;
  bool _showCalculationAdWarning = false;
  bool _showAccountAdWarning = true; // Always show for account creation
  
  bool get isInitialized => _isInitialized;
  bool get showCalculationAdWarning => _showCalculationAdWarning;
  bool get showAccountAdWarning => _showAccountAdWarning;
  int get calculationCount => _adService.calculationCount;
  int get remainingCalculations => _adService.getRemainingCalculations();
  bool get isCalculationAdLoaded => _adService.isCalculationAdLoaded;
  bool get isAccountAdLoaded => _adService.isAccountAdLoaded;

  /// Initialize ad service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _adService.initialize();
    _isInitialized = true;
    _updateAdWarnings();
    notifyListeners();
  }

  /// Handle calculation button press
  Future<bool> onCalculationButtonPressed() async {
    if (!_isInitialized) await initialize();
    
    final adShown = await _adService.onCalculationButtonPressed();
    _updateAdWarnings();
    notifyListeners();
    return adShown;
  }

  /// Handle account creation button press
  Future<bool> onAccountButtonPressed() async {
    debugPrint('🎯 [AdProvider] onAccountButtonPressed 호출됨');
    
    if (!_isInitialized) {
      debugPrint('🔄 [AdProvider] 초기화되지 않음, 초기화 진행');
      await initialize();
    }
    
    debugPrint('🎯 [AdProvider] AdService.onAccountButtonPressed 호출');
    final adShown = await _adService.onAccountButtonPressed();
    debugPrint('🎯 [AdProvider] 광고 표시 결과: $adShown');
    
    notifyListeners();
    debugPrint('✅ [AdProvider] notifyListeners 호출 완료');
    return adShown;
  }

  /// Update ad warning states
  void _updateAdWarnings() {
    _showCalculationAdWarning = _adService.shouldShowCalculationAd();
  }

  /// Reset calculation count (for testing)
  Future<void> resetCalculationCount() async {
    if (!_isInitialized) await initialize();
    
    await _adService.resetCalculationCount();
    _updateAdWarnings();
    notifyListeners();
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }
}