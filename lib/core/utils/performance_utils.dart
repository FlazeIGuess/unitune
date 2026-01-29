import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// Performance utilities for Liquid Glass effects
/// Helps optimize rendering on different devices

class PerformanceUtils {
  PerformanceUtils._();

  /// Check if device is likely to handle liquid glass well
  /// Based on platform and available information
  static bool get isHighPerformanceDevice {
    // iOS devices generally handle liquid glass better
    if (Platform.isIOS) {
      return true;
    }

    // Android - be more conservative
    if (Platform.isAndroid) {
      // Could check device specs here if needed
      return false; // Default to conservative
    }

    // Desktop platforms
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return true;
    }

    return false;
  }

  /// Get recommended blur value based on device performance
  static double getRecommendedBlur({
    double highPerformance = 12.0,
    double lowPerformance = 6.0,
  }) {
    return isHighPerformanceDevice ? highPerformance : lowPerformance;
  }

  /// Get recommended thickness based on device performance
  static double getRecommendedThickness({
    double highPerformance = 15.0,
    double lowPerformance = 10.0,
  }) {
    return isHighPerformanceDevice ? highPerformance : lowPerformance;
  }

  /// Should use fake glass instead of real liquid glass
  static bool get shouldUseFakeGlass {
    return !isHighPerformanceDevice;
  }

  /// Wrap widget with RepaintBoundary for performance
  static Widget withRepaintBoundary(Widget child) {
    return RepaintBoundary(child: child);
  }

  /// Create performance-optimized glass settings
  static Map<String, dynamic> getOptimizedSettings() {
    if (isHighPerformanceDevice) {
      return {
        'blur': 12.0,
        'thickness': 15.0,
        'useFakeGlass': false,
        'enableAnimations': true,
        'enableGlow': true,
        'enableStretch': true,
      };
    } else {
      return {
        'blur': 6.0,
        'thickness': 10.0,
        'useFakeGlass': true,
        'enableAnimations': false,
        'enableGlow': false,
        'enableStretch': false,
      };
    }
  }
}

/// Mixin for widgets that use liquid glass
/// Provides easy access to performance settings
mixin LiquidGlassPerformance {
  bool get isHighPerformance => PerformanceUtils.isHighPerformanceDevice;
  bool get shouldUseFakeGlass => PerformanceUtils.shouldUseFakeGlass;

  double getBlur({double high = 12.0, double low = 6.0}) {
    return PerformanceUtils.getRecommendedBlur(
      highPerformance: high,
      lowPerformance: low,
    );
  }

  double getThickness({double high = 15.0, double low = 10.0}) {
    return PerformanceUtils.getRecommendedThickness(
      highPerformance: high,
      lowPerformance: low,
    );
  }
}
