import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'liquid_glass_container.dart';

/// GlassInputField - Text input widget with glass container
///
/// A modern text input field with glassmorphism effects using LiquidGlassContainer.
/// Provides visual feedback for focus states and follows the design system.
///
/// Features:
/// - Glass container background using LiquidGlassContainer
/// - Label and placeholder text support
/// - Focus state visual feedback with border color change
/// - Customizable through parameters
/// - Uses theme values for consistent styling
///
/// Requirements: 8.1, 8.3, 20.4
class GlassInputField extends StatefulWidget {
  /// Label text displayed above the input field
  final String? label;

  /// Placeholder text shown when the field is empty
  final String? placeholder;

  /// Callback when the text changes
  final ValueChanged<String>? onChanged;

  /// Text editing controller for the input field
  final TextEditingController? controller;

  /// Maximum number of lines (default: 1)
  final int maxLines;

  /// Whether the field is enabled (default: true)
  final bool enabled;

  /// Input type (default: text)
  final TextInputType keyboardType;

  /// Whether to obscure text (for passwords)
  final bool obscureText;

  const GlassInputField({
    super.key,
    this.label,
    this.placeholder,
    this.onChanged,
    this.controller,
    this.maxLines = 1,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  State<GlassInputField> createState() => _GlassInputFieldState();
}

class _GlassInputFieldState extends State<GlassInputField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: widget.label,
      hint: widget.placeholder,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: AppTheme.typography.labelLarge.copyWith(
                color: AppTheme.colors.textSecondary,
              ),
            ),
            SizedBox(height: AppTheme.spacing.s),
          ],

          // Input field with glass container
          AnimatedContainer(
            duration: AppTheme.animation.durationFast,
            curve: AppTheme.animation.curveStandard,
            child: LiquidGlassContainer(
              borderRadius: AppTheme.radii.medium,
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing.m,
                vertical: AppTheme.spacing.s,
              ),
              // Change border color on focus
              borderColor: _isFocused
                  ? AppTheme.colors.primary.withValues(alpha: 0.5)
                  : AppTheme.colors.glassBorder,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                enabled: widget.enabled,
                maxLines: widget.maxLines,
                keyboardType: widget.keyboardType,
                obscureText: widget.obscureText,
                style: AppTheme.typography.bodyLarge.copyWith(
                  color: AppTheme.colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: AppTheme.typography.bodyLarge.copyWith(
                    color: AppTheme.colors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
