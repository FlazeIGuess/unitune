import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/motion_sensitivity.dart';

/// Content fade-in animation helper for dynamic content loading
/// Duration: 200-300ms (uses AppTheme.animation.durationNormal = 250ms)
/// Curve: ease-out (AppTheme.animation.curveDecelerate)
/// Validates: Requirements 7.2, 7.5

/// A widget that fades in its child content with a smooth animation.
///
/// This widget is designed for dynamic content loading scenarios where
/// content appears after data is fetched or state changes.
///
/// Features:
/// - Automatic fade-in animation on mount
/// - Respects system reduce-motion settings
/// - Uses theme-defined duration and curve
/// - Optional delay for staggered animations
///
/// Example:
/// ```dart
/// ContentFadeIn(
///   child: Text('Hello World'),
/// )
/// ```
///
/// Example with delay for staggered effect:
/// ```dart
/// ContentFadeIn(
///   delay: Duration(milliseconds: 100),
///   child: ServiceButton(...),
/// )
/// ```
class ContentFadeIn extends StatefulWidget {
  /// The child widget to fade in
  final Widget child;

  /// Optional delay before starting the fade-in animation
  /// Useful for creating staggered animations
  final Duration? delay;

  /// Optional custom duration (defaults to AppTheme.animation.durationNormal)
  final Duration? duration;

  /// Optional custom curve (defaults to AppTheme.animation.curveDecelerate)
  final Curve? curve;

  const ContentFadeIn({
    super.key,
    required this.child,
    this.delay,
    this.duration,
    this.curve,
  });

  @override
  State<ContentFadeIn> createState() => _ContentFadeInState();
}

class _ContentFadeInState extends State<ContentFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Create animation controller with theme duration (250ms = 200-300ms range)
    _controller = AnimationController(
      duration: widget.duration ?? AppTheme.animation.durationNormal,
      vsync: this,
    );

    // Create fade animation with ease-out curve
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve ?? AppTheme.animation.curveDecelerate,
    );

    // Start animation after optional delay
    if (widget.delay != null) {
      Future.delayed(widget.delay!, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Adjust duration based on motion sensitivity settings
    final adjustedDuration = MotionSensitivity.getDuration(
      context,
      widget.duration ?? AppTheme.animation.durationNormal,
    );
    _controller.duration = adjustedDuration;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if animations should be shown
    final shouldAnimate = MotionSensitivity.shouldAnimate(context);

    // If reduce-motion is enabled, show content immediately without animation
    if (!shouldAnimate) {
      return widget.child;
    }

    // Otherwise, apply fade-in animation
    return FadeTransition(opacity: _fadeAnimation, child: widget.child);
  }
}

/// Helper function to create a staggered list of fade-in widgets
///
/// This is useful for animating lists of items with a cascading effect.
///
/// Example:
/// ```dart
/// Column(
///   children: createStaggeredFadeIns(
///     children: [
///       ServiceButton(...),
///       ServiceButton(...),
///       ServiceButton(...),
///     ],
///     staggerDelay: Duration(milliseconds: 50),
///   ),
/// )
/// ```
List<Widget> createStaggeredFadeIns({
  required List<Widget> children,
  Duration staggerDelay = const Duration(milliseconds: 50),
  Duration? duration,
  Curve? curve,
}) {
  return List.generate(
    children.length,
    (index) => ContentFadeIn(
      delay: staggerDelay * index,
      duration: duration,
      curve: curve,
      child: children[index],
    ),
  );
}

/// A builder widget that fades in content when a condition is met
///
/// This is useful for fading in content after data is loaded or
/// when a specific state is reached.
///
/// Example:
/// ```dart
/// ConditionalFadeIn(
///   condition: dataLoaded,
///   child: DataDisplay(data),
///   placeholder: LoadingSpinner(),
/// )
/// ```
class ConditionalFadeIn extends StatelessWidget {
  /// The condition that triggers the fade-in
  final bool condition;

  /// The child widget to fade in when condition is true
  final Widget child;

  /// Optional placeholder to show when condition is false
  final Widget? placeholder;

  /// Optional duration (defaults to AppTheme.animation.durationNormal)
  final Duration? duration;

  /// Optional curve (defaults to AppTheme.animation.curveDecelerate)
  final Curve? curve;

  const ConditionalFadeIn({
    super.key,
    required this.condition,
    required this.child,
    this.placeholder,
    this.duration,
    this.curve,
  });

  @override
  Widget build(BuildContext context) {
    if (!condition) {
      return placeholder ?? const SizedBox.shrink();
    }

    return ContentFadeIn(duration: duration, curve: curve, child: child);
  }
}

/// Extension method to easily wrap any widget with a fade-in animation
///
/// Example:
/// ```dart
/// Text('Hello').withFadeIn()
/// Text('Hello').withFadeIn(delay: Duration(milliseconds: 100))
/// ```
extension FadeInExtension on Widget {
  Widget withFadeIn({Duration? delay, Duration? duration, Curve? curve}) {
    return ContentFadeIn(
      delay: delay,
      duration: duration,
      curve: curve,
      child: this,
    );
  }
}
