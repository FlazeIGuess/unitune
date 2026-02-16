import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../theme/app_theme.dart';
import '../theme/dynamic_theme.dart';

/// PrimaryButton - Large CTA button with Liquid Glass design and scale animation
///
/// Features:
/// - Liquid Glass background with blur effect
/// - Scale animation on tap (AnimationController)
/// - Haptic feedback on tap
/// - Pill-shaped border radius (100px)
/// - Glow shadow effect
/// - Loading state with spinner
/// - Optional icon support
/// - 200-300ms animation duration for smooth feedback
///
/// Validates Requirements:
/// - 6.1: Immediate visual feedback through scale animation
/// - 6.3: Pill-shaped buttons (100px border radius) for primary actions
/// - 6.5: Button state changes animated with 200-300ms duration
/// - 20.2: Standardized button component
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.primaryColor;
    return Semantics(
      button: true,
      enabled: !isLoading,
      label: isLoading ? '$label, loading' : label,
      child: GlassButton.custom(
        onTap: () {
          if (isLoading) return;
          HapticFeedback.lightImpact();
          onPressed();
        },
        width: double.infinity,
        height: 56,
        enabled: !isLoading,
        useOwnLayer: true,
        shape: LiquidRoundedSuperellipse(borderRadius: AppTheme.radii.pill),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      primaryColor,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: primaryColor, size: 20),
                      SizedBox(width: AppTheme.spacing.s),
                    ],
                    Text(
                      label,
                      style: AppTheme.typography.labelLarge.copyWith(
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// SecondaryButton - Liquid Glass outlined button for secondary actions
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.primaryColor;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: GlassButton.custom(
        onTap: () {
          if (onPressed == null) return;
          HapticFeedback.lightImpact();
          onPressed!();
        },
        width: double.infinity,
        height: 56,
        enabled: onPressed != null,
        useOwnLayer: true,
        shape: LiquidRoundedSuperellipse(borderRadius: AppTheme.radii.pill),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: primaryColor, size: 20),
                SizedBox(width: AppTheme.spacing.s),
              ],
              Text(
                label,
                style: AppTheme.typography.labelLarge.copyWith(
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// DangerButton - Compact Liquid Glass button for destructive actions
///
/// Features:
/// - Liquid Glass background with blur effect
/// - Scale animation on tap
/// - Haptic feedback
/// - Red accent color for destructive actions
/// - Compact size for header actions
/// - Optional icon support
///
/// Validates Requirements:
/// - 6.1: Immediate visual feedback through scale animation
/// - 6.5: Button state changes animated with 200-300ms duration
/// - 20.2: Standardized button component
class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: 'Destructive action',
      child: GlassButton.custom(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        width: _inlineWidth(label, icon != null),
        height: 44,
        useOwnLayer: true,
        shape: const LiquidRoundedSuperellipse(borderRadius: 32),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.m,
            vertical: AppTheme.spacing.s,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppTheme.colors.accentError, size: 18),
                SizedBox(width: AppTheme.spacing.xs),
              ],
              Text(
                label,
                style: AppTheme.typography.labelMedium.copyWith(
                  color: AppTheme.colors.accentError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InlineGlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;

  const InlineGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.primaryColor;
    return GlassButton.custom(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      width: _inlineWidth(label, icon != null),
      height: 40,
      useOwnLayer: true,
      shape: LiquidRoundedSuperellipse(borderRadius: AppTheme.radii.pill),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.m,
          vertical: AppTheme.spacing.s,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: accent, size: 18),
              SizedBox(width: AppTheme.spacing.xs),
            ],
            Text(
              label,
              style: AppTheme.typography.labelMedium.copyWith(color: accent),
            ),
          ],
        ),
      ),
    );
  }
}

double _inlineWidth(String label, bool hasIcon) {
  final base = (label.length * 8.5) + (hasIcon ? 26.0 : 0.0) + 36.0;
  return base.clamp(100.0, 240.0);
}
