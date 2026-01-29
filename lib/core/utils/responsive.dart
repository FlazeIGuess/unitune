import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Responsive utilities for adapting layouts to different screen sizes
///
/// Supports screen widths from 320px (minimum) to 428px (maximum)
/// Provides proportional scaling for spacing and typography
class ResponsiveUtils {
  ResponsiveUtils._();

  // Screen width breakpoints (mobile range)
  static const double minScreenWidth = 320.0;
  static const double maxScreenWidth = 428.0;
  static const double baseScreenWidth = 390.0; // iPhone 12/13/14 Pro

  /// Get the current screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get the current screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Calculate scale factor based on screen width
  /// Returns 1.0 for base width (390px)
  /// Scales proportionally for other widths
  static double scaleFactor(BuildContext context) {
    final width = screenWidth(context);
    return (width / baseScreenWidth).clamp(
      minScreenWidth / baseScreenWidth,
      maxScreenWidth / baseScreenWidth,
    );
  }

  /// Scale spacing value proportionally based on screen width
  /// Example: 16px at 390px becomes ~13px at 320px and ~17.6px at 428px
  static double scaleSpacing(BuildContext context, double baseSpacing) {
    return baseSpacing * scaleFactor(context);
  }

  /// Scale typography size proportionally based on screen width
  /// Example: 16px at 390px becomes ~13px at 320px and ~17.6px at 428px
  static double scaleTypography(BuildContext context, double baseFontSize) {
    return baseFontSize * scaleFactor(context);
  }

  /// Get scaled spacing values based on AppTheme.spacing
  static ScaledSpacing spacing(BuildContext context) {
    final scale = scaleFactor(context);
    return ScaledSpacing(
      xs: AppTheme.spacing.xs * scale,
      s: AppTheme.spacing.s * scale,
      m: AppTheme.spacing.m * scale,
      l: AppTheme.spacing.l * scale,
      xl: AppTheme.spacing.xl * scale,
      xxl: AppTheme.spacing.xxl * scale,
    );
  }

  /// Get scaled typography based on AppTheme.typography
  static ScaledTypography typography(BuildContext context) {
    final scale = scaleFactor(context);
    return ScaledTypography(
      displayLarge: AppTheme.typography.displayLarge.copyWith(
        fontSize: AppTheme.typography.displayLarge.fontSize! * scale,
      ),
      displayMedium: AppTheme.typography.displayMedium.copyWith(
        fontSize: AppTheme.typography.displayMedium.fontSize! * scale,
      ),
      titleLarge: AppTheme.typography.titleLarge.copyWith(
        fontSize: AppTheme.typography.titleLarge.fontSize! * scale,
      ),
      titleMedium: AppTheme.typography.titleMedium.copyWith(
        fontSize: AppTheme.typography.titleMedium.fontSize! * scale,
      ),
      bodyLarge: AppTheme.typography.bodyLarge.copyWith(
        fontSize: AppTheme.typography.bodyLarge.fontSize! * scale,
      ),
      bodyMedium: AppTheme.typography.bodyMedium.copyWith(
        fontSize: AppTheme.typography.bodyMedium.fontSize! * scale,
      ),
      labelLarge: AppTheme.typography.labelLarge.copyWith(
        fontSize: AppTheme.typography.labelLarge.fontSize! * scale,
      ),
      labelMedium: AppTheme.typography.labelMedium.copyWith(
        fontSize: AppTheme.typography.labelMedium.fontSize! * scale,
      ),
    );
  }

  /// Check if screen is at minimum width (320px)
  static bool isMinWidth(BuildContext context) {
    return screenWidth(context) <= minScreenWidth + 10; // 10px tolerance
  }

  /// Check if screen is at maximum width (428px)
  static bool isMaxWidth(BuildContext context) {
    return screenWidth(context) >= maxScreenWidth - 10; // 10px tolerance
  }

  /// Get responsive padding for containers (16-24px range)
  /// Scales from 16px at min width to 24px at max width
  static EdgeInsets containerPadding(BuildContext context) {
    final width = screenWidth(context);
    final padding =
        16.0 +
        ((width - minScreenWidth) / (maxScreenWidth - minScreenWidth)) * 8.0;
    return EdgeInsets.all(padding.clamp(16.0, 24.0));
  }

  /// Get responsive margin for sections (16-32px range)
  /// Scales from 16px at min width to 32px at max width
  static double sectionMargin(BuildContext context) {
    final width = screenWidth(context);
    final margin =
        16.0 +
        ((width - minScreenWidth) / (maxScreenWidth - minScreenWidth)) * 16.0;
    return margin.clamp(16.0, 32.0);
  }

  /// Get responsive horizontal padding for screen edges
  static EdgeInsets screenPadding(BuildContext context) {
    final spacing = ResponsiveUtils.spacing(context);
    return EdgeInsets.symmetric(horizontal: spacing.m);
  }

  /// Get responsive album art size
  /// Scales from 200px at min width to 280px at max width
  static double albumArtSize(BuildContext context) {
    final width = screenWidth(context);
    final size =
        200.0 +
        ((width - minScreenWidth) / (maxScreenWidth - minScreenWidth)) * 80.0;
    return size.clamp(200.0, 280.0);
  }
}

/// Scaled spacing values
class ScaledSpacing {
  const ScaledSpacing({
    required this.xs,
    required this.s,
    required this.m,
    required this.l,
    required this.xl,
    required this.xxl,
  });

  final double xs;
  final double s;
  final double m;
  final double l;
  final double xl;
  final double xxl;
}

/// Scaled typography values
class ScaledTypography {
  const ScaledTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.titleLarge,
    required this.titleMedium,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.labelLarge,
    required this.labelMedium,
  });

  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle labelLarge;
  final TextStyle labelMedium;
}
