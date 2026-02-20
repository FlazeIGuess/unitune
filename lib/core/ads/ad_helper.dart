import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Helper class for AdMob configuration
/// Manages ad unit IDs for different platforms and environments
class AdHelper {
  static const bool adsEnabled = true;
  // Test mode - using Google's test ad units for development
  static const bool _useTesting = false;

  /// Default AdRequest for all ad placements.
  /// Always non-personalized: no GAID, no behavioral profiling.
  /// GDPR-compliant without a consent dialog (EEA contextual-ads exemption).
  static AdRequest get defaultRequest =>
      const AdRequest(nonPersonalizedAds: true);

  /// Native Ad Unit ID
  /// Used for native ads in history list
  static String get nativeAdUnitId {
    if (_useTesting) {
      // Test IDs from Google
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/2247696110';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/3986624511';
      }
    }

    // Production IDs - History Screen Native Ads
    if (Platform.isAndroid) {
      return 'ca-app-pub-8547021258440704/3521838107';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-8547021258440704/3521838107'; // TODO: Create separate iOS unit
    }

    throw UnsupportedError('Unsupported platform');
  }

  /// Banner Ad Unit ID
  /// Used for banner ads in processing screen
  static String get bannerAdUnitId {
    if (_useTesting) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }

    // Production IDs - Processing Screen Banner Ads
    if (Platform.isAndroid) {
      return 'ca-app-pub-8547021258440704/7813172999';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-8547021258440704/7813172999'; // TODO: Create separate iOS unit
    }

    throw UnsupportedError('Unsupported platform');
  }

  /// Rewarded Ad Unit ID
  /// Used for support flow
  static String get rewardedAdUnitId {
    if (_useTesting) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/5224354917';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712485313';
      }
    }

    if (Platform.isAndroid) {
      return 'ca-app-pub-8547021258440704/4291061156';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-8547021258440704/4291061156';
    }

    throw UnsupportedError('Unsupported platform');
  }
}
