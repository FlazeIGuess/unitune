import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../theme/app_theme.dart';
import '../theme/dynamic_theme.dart';

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
class ServiceButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final primaryColor = context.primaryColor;
    return Semantics(
      button: true,
      label: '$serviceName, $actionLabel',
      hint: 'Opens $serviceName',
      child: GlassButton.custom(
        onTap: onTap,
        width: double.infinity,
        height: 72,
        useOwnLayer: true,
        shape: LiquidRoundedSuperellipse(borderRadius: AppTheme.radii.large),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing.m),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 24,
                ),
              ),
              SizedBox(width: AppTheme.spacing.m),
              Expanded(
                child: Text(
                  serviceName,
                  style: AppTheme.typography.titleMedium.copyWith(
                    color: primaryColor,
                  ),
                ),
              ),
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
                  actionLabel ?? 'Open',
                  style: AppTheme.typography.labelMedium.copyWith(
                    color: primaryColor.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
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
    final primaryColor = context.primaryColor;
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      hint: selected ? 'Selected' : 'Tap to select',
      child: GlassButton.custom(
        onTap: onTap,
        width: double.infinity,
        height: 72,
        useOwnLayer: true,
        shape: LiquidRoundedSuperellipse(borderRadius: AppTheme.radii.medium),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.m,
            vertical: AppTheme.spacing.m,
          ),
          child: Row(
            children: [
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
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:
                      selected ? primaryColor : AppTheme.colors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
