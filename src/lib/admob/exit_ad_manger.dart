import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';

import 'ad_helper.dart';

class ExitAdManager{
  Logger logger = Logger();
  NativeAd? exitDialogAd;
  final String _adUnitId = AdHelper.exitBannerAdUnitId;
  final ValueNotifier<bool> isAdLoadedNotifier = ValueNotifier<bool>(false);

  void loadExitDialogNativeAd() {
    exitDialogAd = NativeAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          isAdLoadedNotifier.value = true;
          exitDialogAd = ad as NativeAd;
          logger.d("Exit dialog onAdLoaded");
        },
        onAdFailedToLoad: (ad, error) {
          // Releases an ad resource when it fails to load
          ad.dispose();
          logger.d(
              'Exit dialog ad load failed (code=${error.code} message=${error.message})');
        },
      ),
    );

    exitDialogAd?.load();
    if (exitDialogAd == null) {
      logger.d('Exit dialog ad is null');
    }
  }
}