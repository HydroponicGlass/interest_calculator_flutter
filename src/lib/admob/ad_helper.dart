import 'dart:io';

class AdHelper {
  static String get exitBannerAdUnitId {
    if (Platform.isAndroid) {
      // return "ca-app-pub-3940256099942544/2247696110"; // test
      return "ca-app-pub-2276042557637127/4005110370";
    } else if (Platform.isIOS)  {
      return "<YOUR_IOS_NATIVE_AD_UNIT_ID>";
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
  static String get newAccountInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2276042557637127/7178870951";
    } else if (Platform.isIOS)  {
      return "ca-app-pub-2276042557637127/1150866266";
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
  static String get calculationInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2276042557637127/1578257580";
    } else if (Platform.isIOS)  {
      return "ca-app-pub-2276042557637127/6033310244";
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
}