import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../theme/app_theme.dart';

/// Liquid Glass Blend Group for overlapping elements
/// Creates seamless blending between multiple glass surfaces
///
/// Use cases:
/// - Overlapping cards in lists
/// - Stacked notifications
/// - Modal overlays
/// - Grouped buttons
class LiquidGlassBlendContainer extends StatelessWidget {
  final List<Widget> children;
  final double blend;
  final LiquidGlassSettings? settings;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const LiquidGlassBlendContainer({
    super.key,
    required this.children,
    this.blend = 20.0,
    this.settings,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 12.0,
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

    return LiquidGlassLayer(
      settings: glassSettings,
      child: LiquidGlassBlendGroup(
        blend: blend,
        child: Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: _buildBlendedChildren(),
        ),
      ),
    );
  }

  List<Widget> _buildBlendedChildren() {
    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(SizedBox(height: spacing));
      }
    }
    return result;
  }
}

/// Wrapper for individual items in a blend group
class BlendedGlassItem extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;

  const BlendedGlassItem({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass.grouped(
      shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
      child: Padding(
        padding: padding ?? EdgeInsets.all(AppTheme.spacing.l),
        child: child,
      ),
    );
  }
}
