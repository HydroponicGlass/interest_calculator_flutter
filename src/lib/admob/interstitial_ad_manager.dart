import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';

import 'ad_load_return.dart';


class InterstitialAdManager{
  Logger logger = Logger();
  String adUnitId;
  InterstitialAd? _interstitialAd;
  final ValueNotifier<AdLoadReturn> isAdLoadedNotifier = ValueNotifier<AdLoadReturn>(AdLoadReturn.waiting);

  VoidCallback? onAdDismissedCallback;
  /// Loads an interstitial ad.

  InterstitialAdManager(this.adUnitId);

  void loadAd() {
    InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              // Called when the ad showed the full screen content.
                onAdShowedFullScreenContent: (ad) {},
                // Called when an impression occurs on the ad.
                onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  // Call the callback if provided
                  onAdDismissedCallback?.call();
                },
                // Called when a click is recorded for an ad.
                onAdClicked: (ad) {});

            logger.d('$ad loaded: ${ad.responseInfo}');

            // Keep a reference to the ad so you can show it later.
            _interstitialAd = ad;
            isAdLoadedNotifier.value = AdLoadReturn.success;
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            isAdLoadedNotifier.value = AdLoadReturn.fail;
            logger.d('InterstitialAd failed to load: $error');
          },
        ));
  }

  void show(){
    if(_interstitialAd != null){
      logger.d('InterstitialAd show');
      _interstitialAd?.show();
    }
  }
}