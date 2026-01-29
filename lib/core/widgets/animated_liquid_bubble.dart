import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../animations/liquid_physics.dart';

/// Animated bubble indicator for bottom navigation
/// Smoothly slides between items with liquid glass effect
class AnimatedLiquidBubble extends StatefulWidget {
  final int itemCount;
  final int selectedIndex;
  final double itemWidth;
  final double height;
  final Color glassColor;
  final List<Widget> itemIcons;
  final List<String> itemLabels;

  const AnimatedLiquidBubble({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    required this.itemWidth,
    this.height = 48.0,
    this.glassColor = const Color(0x30000000),
    required this.itemIcons,
    required this.itemLabels,
  });

  @override
  State<AnimatedLiquidBubble> createState() => _AnimatedLiquidBubbleState();
}

class _AnimatedLiquidBubbleState extends State<AnimatedLiquidBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _stretchAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _controller = AnimationController(
      duration: LiquidDurations.standard,
      vsync: this,
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(AnimatedLiquidBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _updateAnimations();
      _controller.forward(from: 0.0);
    }
  }

  void _updateAnimations() {
    final startPos = _previousIndex * widget.itemWidth;
    final endPos = widget.selectedIndex * widget.itemWidth;

    _positionAnimation = Tween<double>(
      begin: startPos,
      end: endPos,
    ).animate(CurvedAnimation(parent: _controller, curve: LiquidCurves.smooth));

    // Stretch effect during movement
    _stretchAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.95),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        weight: 30,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (_previousIndex != widget.selectedIndex) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Animated bubble
              Positioned(
                left: _positionAnimation.value,
                top: 0,
                bottom: 0,
                child: Transform.scale(
                  scaleX: _stretchAnimation.value,
                  child: LiquidGlass.withOwnLayer(
                    settings: LiquidGlassSettings(
                      blur: 8,
                      ambientStrength: 0.6,
                      glassColor: widget.glassColor,
                      thickness: 10,
                      lightIntensity: 0.5,
                      saturation: 1.3,
                      refractiveIndex: 1.15,
                    ),
                    shape: LiquidRoundedSuperellipse(borderRadius: 26),
                    child: Container(
                      width: widget.itemWidth,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          widget.itemIcons[widget.selectedIndex],
                          const SizedBox(width: 8),
                          Text(
                            widget.itemLabels[widget.selectedIndex],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
