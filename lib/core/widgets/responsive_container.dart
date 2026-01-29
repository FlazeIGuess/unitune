import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

/// A container that automatically adapts its padding and spacing
/// based on screen size using ResponsiveUtils
///
/// Example usage:
/// ```dart
/// ResponsiveContainer(
///   child: Text('Hello World'),
/// )
/// ```
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final bool usePadding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.usePadding = true,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: usePadding ? ResponsiveUtils.containerPadding(context) : null,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.colors.backgroundCard,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppTheme.radii.large),
      ),
      child: child,
    );
  }
}

/// A text widget that automatically scales its font size
/// based on screen size using ResponsiveUtils
///
/// Example usage:
/// ```dart
/// ResponsiveText(
///   'Hello World',
///   style: AppTheme.typography.titleLarge,
/// )
/// ```
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    required this.baseStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final scaledFontSize = ResponsiveUtils.scaleTypography(
      context,
      baseStyle.fontSize ?? 16.0,
    );

    return Text(
      text,
      style: baseStyle.copyWith(fontSize: scaledFontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// A sized box that automatically scales its dimensions
/// based on screen size using ResponsiveUtils
///
/// Example usage:
/// ```dart
/// ResponsiveSizedBox(
///   width: 100,
///   height: 50,
///   child: Text('Scaled Box'),
/// )
/// ```
class ResponsiveSizedBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;

  const ResponsiveSizedBox({super.key, this.width, this.height, this.child});

  @override
  Widget build(BuildContext context) {
    final scale = ResponsiveUtils.scaleFactor(context);

    return SizedBox(
      width: width != null ? width! * scale : null,
      height: height != null ? height! * scale : null,
      child: child,
    );
  }
}
