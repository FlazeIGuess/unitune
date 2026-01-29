import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../theme/app_theme.dart';
import '../theme/dynamic_theme.dart';
import '../utils/motion_sensitivity.dart';

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
class PrimaryButton extends StatefulWidget {
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
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Animation duration: 250ms (within 200-300ms requirement)
    // Note: Duration will be adjusted at runtime based on reduce-motion setting
    _controller = AnimationController(
      duration: AppTheme.animation.durationNormal,
      vsync: this,
    );
    // Scale from 1.0 to 0.96 for subtle press effect
    // Note: Scale will be adjusted at runtime based on reduce-motion setting
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppTheme.animation.curveStandard,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Adjust animation duration based on reduce-motion setting
    final adjustedDuration = MotionSensitivity.getDuration(
      context,
      AppTheme.animation.durationNormal,
    );
    _controller.duration = adjustedDuration;

    // Adjust scale based on reduce-motion setting
    final adjustedScale = MotionSensitivity.getScale(context, 0.96);
    _scaleAnimation = Tween<double>(begin: 1.0, end: adjustedScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppTheme.animation.curveStandard,
      ),
    );

    return Semantics(
      button: true,
      enabled: !widget.isLoading,
      label: widget.isLoading ? '${widget.label}, loading' : widget.label,
      child: GestureDetector(
        onTapDown: widget.isLoading ? null : (_) => _controller.forward(),
        onTapUp: widget.isLoading
            ? null
            : (_) {
                _controller.reverse();
                HapticFeedback.lightImpact();
                widget.onPressed();
              },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SizedBox(
            height: 56,
            child: LiquidGlass.withOwnLayer(
              settings: AppTheme.liquidGlassButton,
              shape: LiquidRoundedSuperellipse(
                borderRadius: AppTheme.radii.pill,
              ),
              child: Builder(
                builder: (context) {
                  // Get dynamic colors from context
                  final dynamicTheme = DynamicTheme.of(context);
                  return Container(
                    decoration: BoxDecoration(
                      gradient: dynamicTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radii.pill),
                      border: Border.all(
                        color: dynamicTheme.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: dynamicTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppTheme.colors.textPrimary,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    color: AppTheme.colors.textPrimary,
                                    size: 20,
                                  ),
                                  SizedBox(width: AppTheme.spacing.s),
                                ],
                                Text(
                                  widget.label,
                                  style: AppTheme.typography.labelLarge
                                      .copyWith(
                                        color: AppTheme.colors.textPrimary,
                                      ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
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
      child: GestureDetector(
        onTap: onPressed != null
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: LiquidGlass.withOwnLayer(
            settings: AppTheme.liquidGlassButton,
            shape: LiquidRoundedSuperellipse(borderRadius: AppTheme.radii.pill),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radii.pill),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
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
class DangerButton extends StatefulWidget {
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
  State<DangerButton> createState() => _DangerButtonState();
}

class _DangerButtonState extends State<DangerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.animation.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppTheme.animation.curveStandard,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Adjust animation duration based on reduce-motion setting
    final adjustedDuration = MotionSensitivity.getDuration(
      context,
      AppTheme.animation.durationFast,
    );
    _controller.duration = adjustedDuration;

    // Adjust scale based on reduce-motion setting
    final adjustedScale = MotionSensitivity.getScale(context, 0.95);
    _scaleAnimation = Tween<double>(begin: 1.0, end: adjustedScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppTheme.animation.curveStandard,
      ),
    );

    return Semantics(
      button: true,
      label: widget.label,
      hint: 'Destructive action',
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: LiquidGlass.withOwnLayer(
            settings: AppTheme.liquidGlassButton,
            shape: LiquidRoundedSuperellipse(borderRadius: 32),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing.m,
                vertical: AppTheme.spacing.s,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppTheme.colors.accentError.withValues(alpha: 0.3),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.colors.accentError.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: AppTheme.colors.accentError,
                      size: 18,
                    ),
                    SizedBox(width: AppTheme.spacing.xs),
                  ],
                  Text(
                    widget.label,
                    style: AppTheme.typography.labelMedium.copyWith(
                      color: AppTheme.colors.accentError,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
