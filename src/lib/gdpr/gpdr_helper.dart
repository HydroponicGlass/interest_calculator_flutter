import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gma_mediation_unity/gma_mediation_unity.dart';

// Constant to control whether to set Unity Ads consent
const bool ENABLE_UNITY_ADS_CONSENT = true;

class GdprHelper {
  Future<ConsentStatus> getStatus() {
    return ConsentInformation.instance.getConsentStatus();
  }

  Future<FormError?> init() async {
    final completer = Completer<FormError?>();
    final params = ConsentRequestParameters(
        consentDebugSettings: ConsentDebugSettings(
          /*  To debug: It show form anywhere */
          // debugGeography: DebugGeography.debugGeographyEea,
          // testIdentifiers: ['41C0CDA73EC752DBB5D1A4548BEC10C7']
        ));
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
          () async {
        // The consent information state was updated.
        // You are now ready to check if a form is available.
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          await _loadForm();
        } else {
          await _init();
        }
        completer.complete();
      },
          (FormError error) {
        // Handle the error
        completer.complete(error);
      },
    );
    return completer.future;
  }

  Future<FormError?> _loadForm() async {
    final completer = Completer<FormError?>();
    ConsentForm.loadConsentForm(
          (ConsentForm consentForm) async {
        var status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show(
                (formError) {
              // Handle dismissal by reloading form
              completer.complete(_loadForm());
            },
          );
        } else {
          await _init();
          completer.complete();
        }
      },
          (formError) {
        // Handle the error
        completer.complete(formError);
      },
    );
    return completer.future;
  }

  Future<void> _init() async {
    // Get the current consent status before initializing ads
    final status = await ConsentInformation.instance.getConsentStatus();

    // Only set Unity Ads consent if ENABLE_UNITY_ADS_CONSENT is true
    if (ENABLE_UNITY_ADS_CONSENT) {
      _setUnityAdsConsent(status);
    }

    // Then initialize AdMob
    await MobileAds.instance.initialize();
    if (Platform.isAndroid) {
      await MobileAds.instance.setAppVolume(0.001);
      await MobileAds.instance.setAppMuted(true);
    } else if (Platform.isIOS) {
      await MobileAds.instance.setAppVolume(0.001);
    }
  }

  // Method to set Unity Ads consent based on current consent status
  void _setUnityAdsConsent(ConsentStatus status) {
    // True if consent obtained, false otherwise
    bool hasConsent = status == ConsentStatus.obtained;

    try {
      // Create an instance of GmaMediationUnity since it's an instance method
      final unityMediation = GmaMediationUnity();

      // Call the instance methods
      unityMediation.setGDPRConsent(hasConsent);
      unityMediation.setCCPAConsent(hasConsent);

      print("Unity Ads consent set successfully: GDPR & CCPA = $hasConsent");
    } catch (e) {
      print("Error setting Unity Ads consent: $e");
    }
  }
}
