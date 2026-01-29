import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../theme/app_theme.dart';
import '../utils/motion_sensitivity.dart';

/// ServiceButton - Interactive button for streaming platform selection
///
/// Displays a streaming platform or messenger service with:
/// - Liquid Glass background effect
/// - Platform icon with accent color background
/// - Service name with clear typography
/// - Action label (e.g., "Play", "Share", "Open")
/// - Scale animation on tap for visual feedback
/// - Subtle glow effect in platform's accent color
///
/// Validates Requirements:
/// - 6.1: Immediate visual feedback through scale animation
/// - 6.2: Subtle glow effect in platform's accent color
/// - 14.1: Platform icon with appropriate accent color
/// - 14.2: Liquid Glass background effects
/// - 14.3: Subtle scale animation on tap
/// - 14.4: Platform name with clear typography
/// - 14.5: Secondary action indicator
/// - 20.2: Standardized button component
class ServiceButton extends StatefulWidget {
  /// The name of the service (e.g., "Spotify", "Apple Music")
  final String serviceName;

  /// The icon to display for the service
  final IconData icon;

  /// The accent color for the service (e.g., Spotify green, Apple Music red)
  final Color accentColor;

  /// Callback when the button is tapped
  final VoidCallback onTap;

  /// Optional action label (defaults to "Open")
  final String? actionLabel;

  const ServiceButton({
    super.key,
    required this.serviceName,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.actionLabel = 'Open',
  });

  @override
  State<ServiceButton> createState() => _ServiceButtonState();
}

class _ServiceButtonState extends State<ServiceButton>
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
      label: '${widget.serviceName}, ${widget.actionLabel}',
      hint: 'Opens ${widget.serviceName}',
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radii.large),
              boxShadow: AppTheme.glowSoft(widget.accentColor),
            ),
            child: LiquidGlass.withOwnLayer(
              settings: AppTheme.liquidGlassDefault,
              shape: LiquidRoundedSuperellipse(
                borderRadius: AppTheme.radii.large,
              ),
              child: Container(
                padding: EdgeInsets.all(AppTheme.spacing.m),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.colors.glassBorder,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radii.large),
                ),
                child: Row(
                  children: [
                    // Icon with accent color background
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.accentColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.m),

                    // Service name
                    Expanded(
                      child: Text(
                        widget.serviceName,
                        style: AppTheme.typography.titleMedium.copyWith(
                          color: AppTheme.colors.textPrimary,
                        ),
                      ),
                    ),

                    // Action label
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.colors.glassHighlight,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radii.pill,
                        ),
                      ),
                      child: Text(
                        widget.actionLabel!,
                        style: AppTheme.typography.labelMedium.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
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

/// CompactServiceButton - Smaller version for lists (Legacy)
///
/// Note: This is a legacy component that will be replaced in the onboarding redesign.
/// It maintains the old API for backward compatibility with existing screens.
class CompactServiceButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const CompactServiceButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      hint: selected ? 'Selected' : 'Tap to select',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radii.medium),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.m,
              vertical: AppTheme.spacing.m,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.1)
                  : AppTheme.colors.backgroundCard,
              borderRadius: BorderRadius.circular(AppTheme.radii.medium),
              border: Border.all(
                color: selected ? color : Colors.white.withValues(alpha: 0.1),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radii.small),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                SizedBox(width: AppTheme.spacing.m),
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected
                          ? AppTheme.colors.textPrimary
                          : AppTheme.colors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                // Checkmark
                if (selected) Icon(Icons.check_circle, color: color, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
