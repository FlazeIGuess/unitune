import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Handles GDPR consent via Google's User Messaging Platform (UMP) SDK.
///
/// For EEA/UK users: shows a native Google GDPR consent dialog before any
/// ad SDK is initialized (Art. 6(1)(a) GDPR).
/// For non-EEA users: no dialog is shown, ads proceed immediately.
///
/// Usage:
///   final canShowAds = await ConsentHelper.requestConsentAndCheck();
///   if (canShowAds) await MobileAds.instance.initialize();
class ConsentHelper {
  /// Requests consent info from Google's UMP SDK, shows the consent form
  /// if required (EEA/UK users), and returns whether ads may be requested.
  ///
  /// Returns true if the SDK may initialize and serve ads.
  /// Returns false if the user has declined or consent is still pending.
  /// Returns true on network error (silent fallback, non-personalized).
  static Future<bool> requestConsentAndCheck() async {
    final completer = Completer<bool>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        // Consent info retrieved successfully
        final isFormAvailable = await ConsentInformation.instance
            .isConsentFormAvailable();

        if (isFormAvailable) {
          // Show form if required (e.g. EEA user, consent not yet given)
          ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
            if (!completer.isCompleted) {
              completer.complete(ConsentInformation.instance.canRequestAds());
            }
          });
        } else {
          // No form required (e.g. non-EEA user or consent already up-to-date)
          if (!completer.isCompleted) {
            completer.complete(ConsentInformation.instance.canRequestAds());
          }
        }
      },
      (FormError error) {
        // Network or SDK error: default to allowing non-personalized ads
        // The AdRequest already has nonPersonalizedAds: true as fallback
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
    );

    // Timeout safety: after 5 seconds, proceed with non-personalized ads
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => true,
    );
  }

  /// Returns whether ads can currently be requested, based on the last
  /// known consent status. Does NOT show a form.
  static Future<bool> canRequestAds() async {
    return ConsentInformation.instance.canRequestAds();
  }

  /// Opens the UMP consent form again so the user can update their choice.
  /// Call this from the Settings screen "Manage Ad Consent" button.
  /// Returns true if the form was shown and completed.
  static Future<bool> showPrivacyOptionsForm() async {
    final completer = Completer<bool>();

    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (!completer.isCompleted) {
        completer.complete(error == null);
      }
    });

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => false,
    );
  }

  /// Returns true if a "Manage Consent" entry point should be shown.
  /// Always returns true — the UMP form itself handles whether anything
  /// needs to be displayed (non-EEA users see nothing). This ensures
  /// EEA/UK users always have access to update their consent choice.
  static bool shouldShowPrivacyOptionsButton() {
    return true;
  }

  /// Resets consent state — for testing purposes only.
  /// Remove this before production release.
  static void resetForTesting() {
    ConsentInformation.instance.reset();
  }
}
