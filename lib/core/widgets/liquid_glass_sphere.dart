import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../theme/app_theme.dart';
import '../animations/liquid_physics.dart';

/// LiquidGlassSphere - Animated 3D sphere with Liquid Glass effect
/// Apple-style glass morphism with breathing animation
///
/// Features:
/// - Real Liquid Glass effect (not BackdropFilter)
/// - Pulsing glow effect with GlassGlow
/// - Smooth breathing animation
/// - LiquidStretch for organic movement
/// - Customizable size and tint color
class LiquidGlassSphere extends StatefulWidget {
  final double size;
  final Widget? child;
  final Color? tintColor;
  final bool animate;
  final Duration animationDuration;
  final bool enableGlow;

  const LiquidGlassSphere({
    super.key,
    this.size = 140,
    this.child,
    this.tintColor,
    this.animate = true,
    this.animationDuration = LiquidDurations.ambientLong,
    this.enableGlow = true,
  });

  @override
  State<LiquidGlassSphere> createState() => _LiquidGlassSphereState();
}

class _LiquidGlassSphereState extends State<LiquidGlassSphere>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.15,
      end: 0.35,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return _buildSphere(1.0, 0.25);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _buildSphere(_scaleAnimation.value, _glowAnimation.value);
      },
    );
  }

  Widget _buildSphere(double scale, double glowIntensity) {
    final tintColor = widget.tintColor ?? AppTheme.colors.primary;
    final borderRadius = widget.size / 3.0; // Squircle-like shape

    Widget sphere = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Inner glow
          BoxShadow(
            color: tintColor.withValues(alpha: glowIntensity * 0.5),
            blurRadius: 30,
            spreadRadius: 0,
          ),
          // Outer glow
          BoxShadow(
            color: tintColor.withValues(alpha: glowIntensity * 0.25),
            blurRadius: 50,
            spreadRadius: 5,
          ),
        ],
      ),
      child: LiquidGlass.withOwnLayer(
        settings: LiquidGlassSettings(
          thickness: 20,
          blur: 15,
          glassColor: tintColor.withValues(alpha: 0.08),
          lightIntensity: 0.65,
          saturation: 1.35,
          ambientStrength: 0.4,
          refractiveIndex: 1.25,
        ),
        shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
        child: widget.child != null
            ? Center(child: widget.child)
            : const SizedBox.shrink(),
      ),
    );

    // Add GlassGlow for interactive feel
    if (widget.enableGlow) {
      sphere = GlassGlow(
        glowColor: tintColor.withValues(alpha: glowIntensity * 0.4),
        glowRadius: 1.5,
        child: sphere,
      );
    }

    // Add subtle stretch animation
    if (widget.animate) {
      sphere = LiquidStretch(
        stretch: 0.15,
        interactionScale: 1.0,
        child: sphere,
      );
    }

    return Transform.scale(scale: scale, child: sphere);
  }
}
