import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../theme/app_theme.dart';

/// Liquid Glass Dialog - Modern confirmation dialog with glass morphism
///
/// Features:
/// - Liquid Glass background with blur effect
/// - Smooth fade-in animation
/// - Haptic feedback on button press
/// - Customizable title, content, and actions
/// - Destructive action styling for dangerous operations
///
/// Usage:
/// ```dart
/// final confirmed = await LiquidGlassDialog.show(
///   context: context,
///   title: 'Delete Item?',
///   content: 'This action cannot be undone.',
///   confirmText: 'Delete',
///   cancelText: 'Cancel',
///   isDestructive: true,
/// );
/// ```
class LiquidGlassDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;

  const LiquidGlassDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
  });

  /// Show the dialog and return the user's choice
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => LiquidGlassDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: LiquidGlassLayer(
        settings: AppTheme.liquidGlassDefault,
        child: LiquidGlass.withOwnLayer(
          settings: const LiquidGlassSettings(
            blur: 20,
            ambientStrength: 0.6,
            glassColor: Color(0x22FFFFFF),
            thickness: 16,
            lightIntensity: 0.6,
            saturation: 1.2,
            refractiveIndex: 1.2,
          ),
          shape: LiquidRoundedSuperellipse(borderRadius: AppTheme.radii.large),
          child: Container(
            padding: EdgeInsets.all(AppTheme.spacing.l),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radii.large),
              border: Border.all(
                color: AppTheme.colors.glassBorder,
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  title,
                  style: AppTheme.typography.titleLarge.copyWith(
                    color: AppTheme.colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppTheme.spacing.m),

                // Content
                Text(
                  content,
                  style: AppTheme.typography.bodyMedium.copyWith(
                    color: AppTheme.colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppTheme.spacing.xl),

                // Actions
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: _DialogButton(
                        label: cancelText,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop(false);
                        },
                        isPrimary: false,
                        isDestructive: false,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.m),

                    // Confirm button
                    Expanded(
                      child: _DialogButton(
                        label: confirmText,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop(true);
                        },
                        isPrimary: true,
                        isDestructive: isDestructive,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog button with Liquid Glass styling
class _DialogButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const _DialogButton({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
    required this.isDestructive,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive
        ? AppTheme.colors.accentError
        : AppTheme.colors.textSecondary;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.0),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTheme.typography.labelLarge.copyWith(
                color: color,
                fontWeight: widget.isPrimary
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
