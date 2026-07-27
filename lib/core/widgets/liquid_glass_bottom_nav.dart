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
/// - A single highlight pill that can be **dragged** between items, in
///   addition to tapping
/// - Haptic detents as the pill passes each item
/// - Smooth spring-like settle to the nearest item on release
///
/// ## Geometry
///
/// The pill is a real, separately positioned element driven by a continuous
/// [_position] in the range `0 .. items.length - 1`. Every item occupies a
/// collapsed slot of [_collapsedWidth]; the pill adds a fixed expansion budget
/// on top, distributed between the two items the pill currently straddles.
/// Because exactly one unit of expansion is distributed at any time, the total
/// width stays constant and nothing reflows while dragging — which is what
/// makes the gesture feel stable.
///
/// That yields two clean identities used throughout:
///   pill left  = position * collapsedWidth
///   pill width = expandedWidth
/// Both are exact at integer positions and interpolate smoothly in between.
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

class _LiquidGlassBottomNavState extends State<LiquidGlassBottomNav>
    with SingleTickerProviderStateMixin {
  static const double _iconSize = 22;
  static const double _hPadding = 16;
  static const double _labelGap = 8;
  static const double _barPadding = 6;
  static const double _pillRadius = 26;

  /// Width of an item that is not under the pill.
  static const double _collapsedWidth = _iconSize + _hPadding * 2;

  static const TextStyle _labelStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  late final AnimationController _controller;
  Animation<double>? _settle;

  /// Continuous pill position, `0 .. items.length - 1`.
  late double _position;

  bool _isDragging = false;

  /// Nearest item at the last haptic tick, so each detent fires only once.
  late int _lastDetent;

  /// Item the pill is currently settling towards. Notifying the parent makes
  /// [currentIndex] change, which calls [didUpdateWidget] right back — without
  /// this the settle animation would restart mid-flight and visibly stutter.
  late double _animationTarget;

  /// Widest label across all items, measured once per text-scale change.
  /// Every item expands to the same width so the bar cannot resize mid-drag.
  double _maxLabelWidth = 0;

  @override
  void initState() {
    super.initState();
    _position = widget.currentIndex.toDouble();
    _animationTarget = _position;
    _lastDetent = widget.currentIndex;
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 320),
        )..addListener(() {
          final settle = _settle;
          if (settle != null) setState(() => _position = settle.value);
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measureLabels();
  }

  @override
  void didUpdateWidget(LiquidGlassBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) _measureLabels();

    // The index can also change from outside — e.g. the system back gesture
    // returning to Home, or a screen jumping to the Playlists tab. Follow it.
    if (oldWidget.currentIndex != widget.currentIndex &&
        !_isDragging &&
        _animationTarget != widget.currentIndex) {
      _animateTo(widget.currentIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _measureLabels() {
    final scaler = MediaQuery.textScalerOf(context);
    var maxWidth = 0.0;
    for (final item in widget.items) {
      final painter = TextPainter(
        text: TextSpan(text: item.label, style: _labelStyle),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > maxWidth) maxWidth = painter.width;
      painter.dispose();
    }
    if (maxWidth != _maxLabelWidth) {
      setState(() => _maxLabelWidth = maxWidth);
    }
  }

  double get _maxIndex => (widget.items.length - 1).toDouble();

  void _animateTo(double target) {
    _animationTarget = target;
    _settle = Tween<double>(
      begin: _position,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0);
  }

  void _handleTap(int index) {
    if (index == widget.currentIndex && _position == index) return;
    HapticFeedback.lightImpact();
    _lastDetent = index;
    _animateTo(index.toDouble());
    if (index != widget.currentIndex) widget.onTap(index);
  }

  void _handleDragStart(DragStartDetails _) {
    _controller.stop();
    _animationTarget = _position;
    _isDragging = true;
    _lastDetent = _position.round();
  }

  void _handleDragUpdate(DragUpdateDetails details, double collapsedWidth) {
    setState(() {
      _position = (_position + details.delta.dx / collapsedWidth).clamp(
        0.0,
        _maxIndex,
      );
    });

    // Detent feedback: one tick each time a new item becomes the nearest.
    final nearest = _position.round();
    if (nearest != _lastDetent) {
      _lastDetent = nearest;
      HapticFeedback.selectionClick();
    }
  }

  void _handleDragEnd(DragEndDetails details, double collapsedWidth) {
    _isDragging = false;

    // A flick carries to the neighbouring item; otherwise snap to nearest.
    final velocity = details.velocity.pixelsPerSecond.dx;
    var target = _position.round();
    if (velocity.abs() > 320) {
      target = velocity > 0 ? _position.ceil() : _position.floor();
    }
    target = target.clamp(0, widget.items.length - 1);

    _animateTo(target.toDouble());
    if (target != widget.currentIndex) {
      HapticFeedback.lightImpact();
      widget.onTap(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final count = widget.items.length;

            // Preferred geometry, then shrunk to fit narrow screens. The label
            // is clipped rather than wrapped, so a smaller expansion budget
            // simply reveals less of it.
            final preferredExpanded =
                _hPadding * 2 + _iconSize + _labelGap + _maxLabelWidth;
            final available =
                constraints.maxWidth -
                _barPadding * 2 -
                (count - 1) * _collapsedWidth;
            final expandedWidth = preferredExpanded
                .clamp(
                  _collapsedWidth,
                  available.clamp(_collapsedWidth, double.infinity),
                )
                .toDouble();

            final trackWidth = (count - 1) * _collapsedWidth + expandedWidth;

            return Row(
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
                    padding: const EdgeInsets.all(_barPadding),
                    child: GestureDetector(
                      // Drag anywhere on the bar moves the pill. Taps on the
                      // items still win the gesture arena when there is no
                      // horizontal movement, so tapping keeps working.
                      onHorizontalDragStart: _handleDragStart,
                      onHorizontalDragUpdate: (d) =>
                          _handleDragUpdate(d, _collapsedWidth),
                      onHorizontalDragEnd: (d) =>
                          _handleDragEnd(d, _collapsedWidth),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: trackWidth,
                        child: Stack(
                          children: [
                            _buildPill(expandedWidth),
                            _buildItems(expandedWidth),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The single highlight pill. Its left edge is exactly
  /// `position * collapsedWidth` — see the class docs for why that holds.
  Widget _buildPill(double expandedWidth) {
    return Positioned(
      left: _position * _collapsedWidth,
      top: 0,
      bottom: 0,
      width: expandedWidth,
      child: Container(
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(_pillRadius),
        ),
      ),
    );
  }

  Widget _buildItems(double expandedWidth) {
    return Row(
      children: List.generate(widget.items.length, (index) {
        // How much of the expansion budget this item currently holds.
        // Non-zero only for the one or two items the pill straddles, and the
        // values always sum to 1 — which keeps the total width constant.
        final t = (1.0 - (_position - index).abs()).clamp(0.0, 1.0);
        return _BottomNavTab(
          item: widget.items[index],
          expansion: t,
          width: _collapsedWidth + (expandedWidth - _collapsedWidth) * t,
          labelStyle: _labelStyle,
          onTap: () => _handleTap(index),
        );
      }),
    );
  }
}

class _BottomNavTab extends StatelessWidget {
  final BottomNavItem item;

  /// 0 = fully collapsed (icon only), 1 = fully under the pill (icon + label).
  final double expansion;
  final double width;
  final TextStyle labelStyle;
  final VoidCallback onTap;

  const _BottomNavTab({
    required this.item,
    required this.expansion,
    required this.width,
    required this.labelStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = expansion > 0.5;
    final icon = isSelected ? (item.activeIcon ?? item.icon) : item.icon;
    final color = Color.lerp(Colors.white70, context.primaryColor, expansion)!;

    return Semantics(
      button: true,
      label: item.label,
      selected: isSelected,
      hint: isSelected
          ? 'Currently selected'
          : 'Navigate to ${item.label}. You can also drag the highlight.',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  icon,
                  key: ValueKey(icon),
                  color: color,
                  size: _LiquidGlassBottomNavState._iconSize,
                ),
              ),
              // Reveals horizontally with the expansion instead of reflowing,
              // so the text never wraps or jumps while the pill moves.
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: expansion,
                  child: Opacity(
                    opacity: expansion,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: _LiquidGlassBottomNavState._labelGap,
                      ),
                      child: Text(
                        item.label,
                        style: labelStyle,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
