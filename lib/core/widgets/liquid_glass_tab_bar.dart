import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../theme/app_theme.dart';
import '../animations/liquid_physics.dart';

/// Liquid Glass Tab Bar with sliding bubble indicator
/// iOS-style segmented control with smooth animations
class LiquidGlassTabBar extends StatefulWidget {
  final List<LiquidTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final Color? accentColor;

  const LiquidGlassTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabChanged,
    this.accentColor,
  });

  @override
  State<LiquidGlassTabBar> createState() => _LiquidGlassTabBarState();
}

class _LiquidGlassTabBarState extends State<LiquidGlassTabBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _stretchAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      duration: LiquidDurations.standard,
      vsync: this,
    );
    _updateAnimations();
  }

  @override
  void didUpdateWidget(LiquidGlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _updateAnimations();
      _controller.forward(from: 0.0);
    }
  }

  void _updateAnimations() {
    _positionAnimation = Tween<double>(
      begin: _previousIndex.toDouble(),
      end: widget.currentIndex.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: LiquidCurves.smooth));

    // Stretch effect during slide
    _stretchAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 0.96),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.96, end: 1.0),
        weight: 30,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (_previousIndex != widget.currentIndex) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index != widget.currentIndex) {
      HapticFeedback.selectionClick();
      widget.onTabChanged(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? AppTheme.colors.primary;

    return LiquidGlass.withOwnLayer(
      settings: const LiquidGlassSettings(
        thickness: 8,
        blur: 12,
        glassColor: Color(0x15FFFFFF),
        lightIntensity: 0.5,
        saturation: 1.2,
        ambientStrength: 0.3,
        refractiveIndex: 1.1,
      ),
      shape: LiquidRoundedSuperellipse(borderRadius: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / widget.tabs.length;

            return Stack(
              children: [
                // Animated sliding indicator
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final position = _positionAnimation.value * tabWidth;
                    return Positioned(
                      left: position,
                      top: 4,
                      bottom: 4,
                      width: tabWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Transform.scale(
                          scaleX: _stretchAnimation.value,
                          child: GlassGlow(
                            glowColor: accentColor.withValues(alpha: 0.2),
                            glowRadius: 0.8,
                            child: LiquidStretch(
                              stretch: 0.2,
                              interactionScale: 1.01,
                              child: LiquidGlass.withOwnLayer(
                                settings: LiquidGlassSettings(
                                  thickness: 10,
                                  blur: 8,
                                  glassColor: accentColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  lightIntensity: 0.6,
                                  saturation: 1.4,
                                  ambientStrength: 0.4,
                                  refractiveIndex: 1.15,
                                ),
                                shape: LiquidRoundedSuperellipse(
                                  borderRadius: 12,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: accentColor.withValues(alpha: 0.08),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Tab buttons
                Row(
                  children: List.generate(widget.tabs.length, (index) {
                    final tab = widget.tabs[index];
                    final isSelected = widget.currentIndex == index;
                    return Expanded(
                      child: Semantics(
                        button: true,
                        label: tab.label,
                        selected: isSelected,
                        hint: isSelected
                            ? 'Currently selected'
                            : 'Tap to switch to ${tab.label}',
                        child: GestureDetector(
                          onTap: () => _handleTap(index),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? accentColor
                                    : AppTheme.colors.textMuted,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (tab.icon != null) ...[
                                    Icon(
                                      tab.icon,
                                      size: 16,
                                      color: isSelected
                                          ? accentColor
                                          : AppTheme.colors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(tab.label),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Tab item for LiquidGlassTabBar
class LiquidTab {
  final String label;
  final IconData? icon;

  const LiquidTab({required this.label, this.icon});
}
