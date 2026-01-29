import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dynamic_color_provider.dart';
import 'app_theme.dart';

/// Widget that provides dynamic colors throughout the widget tree
///
/// Wraps the app and provides access to dynamic colors via [DynamicTheme.of(context)]
///
/// Usage:
/// ```dart
/// // In main.dart, wrap your app:
/// DynamicThemeBuilder(
///   child: MaterialApp(...)
/// )
///
/// // In any widget:
/// final colors = DynamicTheme.of(context);
/// print(colors.primary); // Dynamic primary color
/// ```
class DynamicThemeBuilder extends ConsumerWidget {
  final Widget child;

  const DynamicThemeBuilder({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorState = ref.watch(dynamicColorProvider);

    return DynamicTheme(
      primary: colorState.primary,
      primaryLight: colorState.primaryLight,
      primaryDark: colorState.primaryDark,
      isDefault: colorState.isDefault,
      child: child,
    );
  }
}

/// InheritedWidget that provides dynamic color access
class DynamicTheme extends InheritedWidget {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final bool isDefault;

  const DynamicTheme({
    super.key,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.isDefault,
    required super.child,
  });

  /// Get dynamic colors from context
  /// Falls back to default AppTheme colors if not found
  static DynamicTheme of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<DynamicTheme>();
    if (result != null) {
      return result;
    }
    // Fallback to default colors
    return DynamicTheme(
      primary: AppTheme.colors.primary,
      primaryLight: AppTheme.colors.primaryLight,
      primaryDark: AppTheme.colors.primaryDark,
      isDefault: true,
      child: const SizedBox.shrink(),
    );
  }

  /// Try to get dynamic colors, returns null if not available
  static DynamicTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DynamicTheme>();
  }

  /// Get a ColorPalette with dynamic primary colors
  ColorPalette get dynamicColors => AppTheme.colors.withPrimaryColors(
    primary: primary,
    primaryLight: primaryLight,
    primaryDark: primaryDark,
  );

  /// Get the primary gradient with dynamic colors
  LinearGradient get primaryGradient =>
      AppTheme.dynamicPrimaryGradient(primary, primaryLight);

  @override
  bool updateShouldNotify(DynamicTheme oldWidget) {
    return primary != oldWidget.primary ||
        primaryLight != oldWidget.primaryLight ||
        primaryDark != oldWidget.primaryDark ||
        isDefault != oldWidget.isDefault;
  }
}

/// Extension for easy access to dynamic colors
extension DynamicThemeExtension on BuildContext {
  /// Get dynamic theme colors
  DynamicTheme get dynamicTheme => DynamicTheme.of(this);

  /// Get dynamic primary color
  Color get primaryColor => DynamicTheme.of(this).primary;

  /// Get dynamic primary light color
  Color get primaryColorLight => DynamicTheme.of(this).primaryLight;

  /// Get dynamic primary dark color
  Color get primaryColorDark => DynamicTheme.of(this).primaryDark;

  /// Get dynamic primary gradient
  LinearGradient get dynamicPrimaryGradient =>
      DynamicTheme.of(this).primaryGradient;
}
