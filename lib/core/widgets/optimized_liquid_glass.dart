import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../theme/app_theme.dart';
import '../utils/performance_utils.dart';

/// Performance-optimized Liquid Glass wrapper
/// Automatically switches between real and fake glass based on device
class OptimizedLiquidGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final LiquidGlassSettings? settings;
  final bool forceRealGlass;

  const OptimizedLiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.settings,
    this.forceRealGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final glassSettings =
        settings ??
        const LiquidGlassSettings(
          thickness: 15,
          blur: 12,
          glassColor: Color(0x15FFFFFF),
          lightIntensity: 0.6,
          saturation: 1.3,
          ambientStrength: 0.3,
          refractiveIndex: 1.15,
        );

    final useFakeGlass = !forceRealGlass && PerformanceUtils.shouldUseFakeGlass;

    if (useFakeGlass) {
      return FakeGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
        settings: glassSettings,
        child: child,
      );
    }

    return LiquidGlass.withOwnLayer(
      settings: glassSettings,
      shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
      child: child,
    );
  }
}

/// Optimized Liquid Glass Layer
/// Uses fake glass on low-performance devices
class OptimizedLiquidGlassLayer extends StatelessWidget {
  final Widget child;
  final LiquidGlassSettings? settings;
  final bool forceRealGlass;

  const OptimizedLiquidGlassLayer({
    super.key,
    required this.child,
    this.settings,
    this.forceRealGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final glassSettings =
        settings ??
        const LiquidGlassSettings(
          thickness: 15,
          blur: 12,
          glassColor: Color(0x15FFFFFF),
          lightIntensity: 0.6,
          saturation: 1.3,
          ambientStrength: 0.3,
          refractiveIndex: 1.15,
        );

    final useFakeGlass = !forceRealGlass && PerformanceUtils.shouldUseFakeGlass;

    return LiquidGlassLayer(
      fake: useFakeGlass,
      settings: glassSettings,
      child: child,
    );
  }
}
