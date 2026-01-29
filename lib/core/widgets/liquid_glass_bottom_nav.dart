import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../theme/dynamic_theme.dart';

/// Item for the bottom navigation bar
class BottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// Apple-style Liquid Glass Bottom Navigation Bar
///
/// Features:
/// - Floating pill design at the bottom
/// - Liquid Glass blur effect
/// - Animated transitions between items with sliding indicator
/// - Haptic feedback on tap
/// - Smooth scale and fade animations
class LiquidGlassBottomNav extends StatefulWidget {
  final List<BottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const LiquidGlassBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<LiquidGlassBottomNav> createState() => _LiquidGlassBottomNavState();
}

class _LiquidGlassBottomNavState extends State<LiquidGlassBottomNav> {
  void _handleTap(int index) {
    if (index != widget.currentIndex) {
      HapticFeedback.lightImpact();
      widget.onTap(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LiquidGlass.withOwnLayer(
              settings: const LiquidGlassSettings(
                blur: 12,
                ambientStrength: 0.5,
                glassColor: Color(0x18FFFFFF),
                thickness: 12,
                lightIntensity: 0.5,
                saturation: 1.3,
                refractiveIndex: 1.15,
              ),
              shape: LiquidRoundedSuperellipse(borderRadius: 32),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.all(6.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.items.length, (index) {
                    final isSelected = widget.currentIndex == index;
                    return _BottomNavTab(
                      item: widget.items[index],
                      isSelected: isSelected,
                      onTap: () => _handleTap(index),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavTab extends StatefulWidget {
  final BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavTab({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_BottomNavTab> createState() => _BottomNavTabState();
}

class _BottomNavTabState extends State<_BottomNavTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.isSelected
        ? (widget.item.activeIcon ?? widget.item.icon)
        : widget.item.icon;

    return Semantics(
      button: true,
      label: widget.item.label,
      selected: widget.isSelected,
      hint: widget.isSelected
          ? 'Currently selected'
          : 'Navigate to ${widget.item.label}',
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? context.primaryColor.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    color: widget.isSelected
                        ? context.primaryColor
                        : Colors.white70,
                    size: 22,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: widget.isSelected
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            Text(
                              widget.item.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
