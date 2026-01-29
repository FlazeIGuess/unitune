import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// LiquidGlassContainer - Reusable glassmorphism container
///
/// A modern glassmorphism container using BackdropFilter for blur effects.
/// Provides consistent glass styling across the app with customizable parameters.
///
/// Features:
/// - BackdropFilter-based blur effect (10-20px range per requirements)
/// - Customizable glass color, border, and shadows
/// - Fallback rendering for devices without backdrop filter support
/// - Uses theme values for defaults
/// - Configurable border radius and padding
///
/// Requirements: 4.1, 4.2, 4.3, 4.4, 4.6, 20.1
class LiquidGlassContainer extends StatelessWidget {
  /// The widget to display inside the glass container
  final Widget child;

  /// Border radius for the container (default: 20.0 from theme)
  final double borderRadius;

  /// Padding inside the container (optional)
  final EdgeInsets? padding;

  /// Blur sigma for the backdrop filter (default: 12.0, range: 10-20)
  /// Validates: Requirement 4.2
  final double blurSigma;

  /// Glass color with opacity (default: 5% white from theme)
  /// Validates: Requirement 4.3
  final Color? glassColor;

  /// Border color (default: 10% white from theme)
  final Color? borderColor;

  /// Optional box shadows for depth
  final List<BoxShadow>? shadows;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.padding,
    this.blurSigma = 12.0,
    this.glassColor,
    this.borderColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    // Use theme values for defaults
    final effectiveGlassColor = glassColor ?? AppTheme.colors.glassBase;
    final effectiveBorderColor = borderColor ?? AppTheme.colors.glassBorder;

    // Check if backdrop filter is supported (fallback for unsupported devices)
    // Requirement 4.6: Provide fallback rendering
    final supportsBackdropFilter = _supportsBackdropFilter();

    if (supportsBackdropFilter) {
      // Use BackdropFilter for glass effect
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveGlassColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: effectiveBorderColor, width: 1.0),
              boxShadow: shadows,
            ),
            child: child,
          ),
        ),
      );
    } else {
      // Fallback: Use solid color container without blur
      // Requirement 4.6: Fallback for devices without backdrop filter support
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          // Use slightly more opaque color for fallback
          color: effectiveGlassColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: effectiveBorderColor, width: 1.0),
          boxShadow: shadows,
        ),
        child: child,
      );
    }
  }

  /// Check if the current platform supports BackdropFilter
  /// Returns false for web and older devices that don't support backdrop filters
  bool _supportsBackdropFilter() {
    // BackdropFilter is not well supported on web
    if (kIsWeb) {
      return false;
    }
    // On mobile platforms, BackdropFilter is generally supported
    // Could add more sophisticated detection if needed
    return true;
  }
}

/// LiquidGlassCard - Specialized card with Liquid Glass effect
/// Wrapper around LiquidGlassContainer with additional styling options
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool elevated;
  final EdgeInsets? padding;
  final double? borderRadius;
  final VoidCallback? onTap;
  final Color? tintColor;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.elevated = true,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTheme.radii.large;

    Widget glassContainer = LiquidGlassContainer(
      borderRadius: radius,
      padding: padding ?? EdgeInsets.all(AppTheme.spacing.l),
      glassColor: tintColor?.withValues(alpha: 0.05),
      child: child,
    );

    if (onTap != null) {
      glassContainer = GestureDetector(onTap: onTap, child: glassContainer);
    }

    if (elevated) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: AppTheme.shadowSoft,
        ),
        child: glassContainer,
      );
    }

    return glassContainer;
  }
}

/// PreferenceLiquidCard - Specialized card for settings display
/// Uses Liquid Glass for a premium feel
class PreferenceLiquidCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const PreferenceLiquidCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      onTap: onTap,
      tintColor: color,
      child: Row(
        children: [
          // Icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radii.small),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          SizedBox(width: AppTheme.spacing.m),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Chevron
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              color: AppTheme.colors.textMuted,
              size: 24,
            ),
        ],
      ),
    );
  }
}
