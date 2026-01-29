import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../theme/dynamic_theme.dart';

/// UniTune Logo Widget
///
/// A reusable logo component that displays the UniTune brand identity
/// consistently across all screens. Features a gradient background with
/// a music note icon and the app name.
///
/// Requirements:
/// - 19.1: UniTune logo integration across all screens
/// - 19.2: Brand colors from design system
/// - 19.3: Consistent visual language
class UniTuneLogo extends StatelessWidget {
  /// Creates a UniTune logo widget
  ///
  /// [size] controls the size of the icon container (default: 40)
  /// [showText] determines if the "UniTune" text is displayed (default: true)
  /// [textStyle] allows customization of the text style
  const UniTuneLogo({
    super.key,
    this.size = 40.0,
    this.showText = true,
    this.textStyle,
  });

  final double size;
  final bool showText;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: SvgPicture.asset(
            'assets/icon/app_icon.svg',
            width: size,
            height: size,
            fit: BoxFit.contain, // Changed to contain to ensure full icon is visible
            colorFilter: ColorFilter.mode(
              context.primaryColor,
              BlendMode.srcIn,
            ),
            placeholderBuilder: (context) {
              return Center(
                child: Text(
                  '♪',
                  style: TextStyle(
                    fontSize: size * 0.6,
                    color: AppTheme.colors.textPrimary,
                  ),
                ),
              );
            },
          ),
        ),

        // App name text
        if (showText) ...[
          SizedBox(width: AppTheme.spacing.m),
          Text(
            'UniTune',
            style:
                textStyle ??
                AppTheme.typography.titleLarge.copyWith(
                  color: context.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ],
    );
  }
}
