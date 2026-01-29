import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

/// GlassSphere - Animated 3D sphere with glassmorphism effect
/// Inspired by Calm Sleep App breathing animation
///
/// Features:
/// - Pulsing glow effect
/// - Glassmorphism with backdrop blur
/// - Smooth breathing animation
/// - Customizable size and color
class GlassSphere extends StatefulWidget {
  final double size;
  final Widget? child;
  final Color glowColor;
  final bool animate;
  final Duration animationDuration;

  const GlassSphere({
    super.key,
    this.size = 140,
    this.child,
    Color? glowColor,
    this.animate = true,
    this.animationDuration = const Duration(seconds: 4),
  }) : glowColor = glowColor ?? const Color(0xFF58A6FF);

  @override
  State<GlassSphere> createState() => _GlassSphereState();
}

class _GlassSphereState extends State<GlassSphere>
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
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.2,
      end: 0.5,
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
      return _buildSphere(1.0, 0.3);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _buildSphere(_scaleAnimation.value, _glowAnimation.value);
      },
    );
  }

  Widget _buildSphere(double scale, double glowIntensity) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size / 3.5),
          boxShadow: [
            // Inner glow
            BoxShadow(
              color: widget.glowColor.withValues(alpha: glowIntensity * 0.6),
              blurRadius: 40,
              spreadRadius: 0,
            ),
            // Outer glow
            BoxShadow(
              color: widget.glowColor.withValues(alpha: glowIntensity * 0.3),
              blurRadius: 60,
              spreadRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.size / 3.5),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.glowColor.withValues(alpha: 0.15),
                    widget.glowColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.size / 3.5),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: widget.child != null ? Center(child: widget.child) : null,
            ),
          ),
        ),
      ),
    );
  }
}
