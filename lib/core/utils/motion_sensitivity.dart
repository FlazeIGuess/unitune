import 'package:flutter/widgets.dart';

/// Utility class for handling motion sensitivity preferences.
///
/// This class provides methods to check if the user has enabled
/// reduce-motion settings in their system accessibility preferences,
/// and provides adjusted animation durations accordingly.
///
/// **Validates: Requirement 16.6**
class MotionSensitivity {
  MotionSensitivity._();

  /// Checks if the system reduce-motion setting is enabled.
  ///
  /// Returns true if the user has enabled reduce-motion in their
  /// system accessibility settings, false otherwise.
  static bool isReduceMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Returns an adjusted duration based on reduce-motion settings.
  ///
  /// If reduce-motion is enabled, returns a very short duration (50ms)
  /// to provide instant feedback while maintaining functionality.
  /// Otherwise, returns the original duration.
  ///
  /// Parameters:
  /// - [context]: BuildContext to access MediaQuery
  /// - [normalDuration]: The normal animation duration
  ///
  /// Returns: Duration adjusted for motion sensitivity
  static Duration getDuration(BuildContext context, Duration normalDuration) {
    if (isReduceMotionEnabled(context)) {
      // Use a very short duration (50ms) instead of zero
      // to maintain smooth state transitions
      return const Duration(milliseconds: 50);
    }
    return normalDuration;
  }

  /// Returns an adjusted animation scale based on reduce-motion settings.
  ///
  /// If reduce-motion is enabled, returns 0.0 to disable scale animations.
  /// Otherwise, returns the original scale value.
  ///
  /// Parameters:
  /// - [context]: BuildContext to access MediaQuery
  /// - [normalScale]: The normal scale value (e.g., 0.95 for button press)
  ///
  /// Returns: Scale value adjusted for motion sensitivity
  static double getScale(BuildContext context, double normalScale) {
    if (isReduceMotionEnabled(context)) {
      // Return 1.0 (no scale change) when reduce-motion is enabled
      return 1.0;
    }
    return normalScale;
  }

  /// Returns whether to show a fade animation based on reduce-motion settings.
  ///
  /// If reduce-motion is enabled, returns false to skip fade animations.
  /// Otherwise, returns true.
  ///
  /// Parameters:
  /// - [context]: BuildContext to access MediaQuery
  ///
  /// Returns: Whether to show fade animations
  static bool shouldAnimate(BuildContext context) {
    return !isReduceMotionEnabled(context);
  }

  /// Returns an opacity value for fade animations based on reduce-motion settings.
  ///
  /// If reduce-motion is enabled, returns 1.0 (fully opaque, no fade).
  /// Otherwise, returns the provided opacity value.
  ///
  /// Parameters:
  /// - [context]: BuildContext to access MediaQuery
  /// - [normalOpacity]: The normal opacity value for the animation
  ///
  /// Returns: Opacity value adjusted for motion sensitivity
  static double getOpacity(BuildContext context, double normalOpacity) {
    if (isReduceMotionEnabled(context)) {
      // Always fully opaque when reduce-motion is enabled
      return 1.0;
    }
    return normalOpacity;
  }
}
