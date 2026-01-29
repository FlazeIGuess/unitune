import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../theme/app_theme.dart';
import '../utils/motion_sensitivity.dart';

/// Modal animations with scale and fade effects using spring physics
/// Duration: Controlled by spring physics (natural feel)
/// Curve: Spring physics for natural motion
/// Validates: Requirements 7.3, 7.4, 7.6

/// A custom modal route that animates with scale and fade effects using spring physics.
///
/// This route provides a natural-feeling modal presentation with:
/// - Scale animation from 0.9 to 1.0
/// - Fade animation from 0.0 to 1.0
/// - Spring physics for natural motion
/// - Non-blocking interactions (barrier is dismissible)
/// - Respects system reduce-motion settings
///
/// The spring physics parameters are defined in AppTheme.animation:
/// - springStiffness: 200.0 (controls how quickly the spring responds)
/// - springDamping: 20.0 (controls the oscillation/bounce)
///
/// Example:
/// ```dart
/// Navigator.of(context).push(
///   AnimatedModalRoute(
///     builder: (context) => MyModalContent(),
///   ),
/// );
/// ```
class AnimatedModalRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final bool isDismissible;
  final Color? modalBarrierColor;
  final String? modalBarrierLabel;

  AnimatedModalRoute({
    required this.builder,
    this.isDismissible = true,
    this.modalBarrierColor,
    this.modalBarrierLabel,
    super.settings,
  });

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  Color? get barrierColor => modalBarrierColor ?? Colors.black54;

  @override
  String? get barrierLabel => modalBarrierLabel;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ModalTransition(animation: animation, child: child);
  }
}

/// The modal transition widget that applies scale and fade animations.
///
/// This widget uses spring physics for natural motion and respects
/// system reduce-motion settings.
class ModalTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const ModalTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Check if animations should be shown
    final shouldAnimate = MotionSensitivity.shouldAnimate(context);

    // If reduce-motion is enabled, show content immediately without animation
    if (!shouldAnimate) {
      return child;
    }

    // Create spring simulation for natural motion
    final springDescription = SpringDescription(
      mass: 1.0,
      stiffness: AppTheme.animation.springStiffness,
      damping: AppTheme.animation.springDamping,
    );

    // Scale animation from 0.9 to 1.0 with spring physics
    final scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: _SpringCurve(springDescription),
      ),
    );

    // Fade animation from 0.0 to 1.0 with ease-out curve
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: AppTheme.animation.curveDecelerate,
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(scale: scaleAnimation, child: child),
    );
  }
}

/// A custom curve that uses spring physics for natural motion.
///
/// This curve simulates a spring with the given spring description,
/// providing a natural-feeling animation with potential overshoot
/// and settling behavior.
class _SpringCurve extends Curve {
  final SpringDescription spring;

  const _SpringCurve(this.spring);

  @override
  double transformInternal(double t) {
    // Create a spring simulation from 0 to 1
    final simulation = SpringSimulation(
      spring,
      0.0, // start position
      1.0, // end position
      0.0, // initial velocity
    );

    // The spring simulation is time-based, so we need to convert
    // our normalized time (0-1) to actual time in seconds
    // We use 400ms as the base duration (matching transitionDuration)
    final time = t * 0.4; // 0.4 seconds = 400ms

    return simulation.x(time);
  }
}

/// A helper function to show a modal with scale and fade animation.
///
/// This is a convenience function that wraps showDialog with our custom
/// modal route and animations.
///
/// Example:
/// ```dart
/// showAnimatedModal(
///   context: context,
///   builder: (context) => AlertDialog(
///     title: Text('Confirm'),
///     content: Text('Are you sure?'),
///     actions: [
///       TextButton(
///         onPressed: () => Navigator.pop(context),
///         child: Text('Cancel'),
///       ),
///       TextButton(
///         onPressed: () => Navigator.pop(context, true),
///         child: Text('Confirm'),
///       ),
///     ],
///   ),
/// );
/// ```
Future<T?> showAnimatedModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
}) {
  return Navigator.of(context).push<T>(
    AnimatedModalRoute<T>(
      builder: builder,
      isDismissible: barrierDismissible,
      modalBarrierColor: barrierColor,
      modalBarrierLabel: barrierLabel,
    ),
  );
}

/// A helper function to show a bottom sheet modal with scale and fade animation.
///
/// This provides a custom animated bottom sheet that slides up from the bottom
/// with scale and fade effects.
///
/// Example:
/// ```dart
/// showAnimatedBottomSheet(
///   context: context,
///   builder: (context) => Container(
///     padding: EdgeInsets.all(24),
///     child: Column(
///       mainAxisSize: MainAxisSize.min,
///       children: [
///         Text('Bottom Sheet Content'),
///         ElevatedButton(
///           onPressed: () => Navigator.pop(context),
///           child: Text('Close'),
///         ),
///       ],
///     ),
///   ),
/// );
/// ```
Future<T?> showAnimatedBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  Color? backgroundColor,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: backgroundColor ?? Colors.transparent,
    barrierColor: barrierColor,
    isDismissible: isDismissible,
    isScrollControlled: true,
    builder: (context) {
      return AnimatedBottomSheet(child: builder(context));
    },
  );
}

/// A widget that wraps bottom sheet content with scale and fade animations.
class AnimatedBottomSheet extends StatefulWidget {
  final Widget child;

  const AnimatedBottomSheet({super.key, required this.child});

  @override
  State<AnimatedBottomSheet> createState() => _AnimatedBottomSheetState();
}

class _AnimatedBottomSheetState extends State<AnimatedBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Create spring simulation for scale
    final springDescription = SpringDescription(
      mass: 1.0,
      stiffness: AppTheme.animation.springStiffness,
      damping: AppTheme.animation.springDamping,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: _SpringCurve(springDescription),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppTheme.animation.curveDecelerate,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppTheme.animation.curveDecelerate,
          ),
        );

    _controller.forward();
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}

/// Extension method to easily show a widget as an animated modal.
///
/// Example:
/// ```dart
/// MyModalContent().showAsModal(context)
/// ```
extension ModalExtension on Widget {
  Future<T?> showAsModal<T>(
    BuildContext context, {
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    return showAnimatedModal<T>(
      context: context,
      builder: (context) => this,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
    );
  }

  Future<T?> showAsBottomSheet<T>(
    BuildContext context, {
    bool isDismissible = true,
    Color? backgroundColor,
    Color? barrierColor,
  }) {
    return showAnimatedBottomSheet<T>(
      context: context,
      builder: (context) => this,
      isDismissible: isDismissible,
      backgroundColor: backgroundColor,
      barrierColor: barrierColor,
    );
  }
}
