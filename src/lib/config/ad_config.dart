/// Ad configuration constants for the interest calculator app
class AdConfig {
  /// How many calculations to show before displaying an ad
  /// Change this value to modify ad frequency (e.g., set to 3 for every 3rd calculation)
  static const int calculationsPerAd = 5;
  
  /// Whether to show ads for new account creation (always true by default)
  static const bool showAccountCreationAds = true;
  
  /// Ad configuration description for developers
  static const String description = '''
Ad Configuration:
- calculationsPerAd: Shows ad every N calculations (currently: $calculationsPerAd)
- showAccountCreationAds: Shows ad when creating accounts (currently: $showAccountCreationAds)

To change ad frequency, modify the calculationsPerAd constant.
''';
}