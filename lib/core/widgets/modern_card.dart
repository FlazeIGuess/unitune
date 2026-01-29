import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

/// ModernCard - Dark mode card with soft shadows
/// Inspired by GO club App & Calm Sleep App
///
/// Features:
/// - Dark background with subtle elevation
/// - Soft shadows
/// - Optional glassmorphism effect
/// - Customizable padding and radius
class ModernCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool elevated;
  final bool glassmorphic;
  final EdgeInsets? padding;
  final double? borderRadius;
  final VoidCallback? onTap;

  const ModernCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.elevated = true,
    this.glassmorphic = false,
    this.padding,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTheme.radii.large;
    final bgColor = backgroundColor ?? AppTheme.colors.backgroundCard;

    Widget content = Container(
      padding: padding ?? EdgeInsets.all(AppTheme.spacing.l),
      decoration: glassmorphic
          ? null
          : BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: elevated ? AppTheme.shadowSoft : null,
            ),
      child: child,
    );

    if (glassmorphic) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding ?? EdgeInsets.all(AppTheme.spacing.l),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// PreferenceCard - Specialized card for settings display
class PreferenceCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const PreferenceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      glassmorphic: true,
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
