import 'package:flutter/material.dart';

/// Custom page transitions for MainShell navigation
/// Provides smooth, Apple-style transitions between screens

class LiquidPageTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final bool isForward;

  const LiquidPageTransition({
    super.key,
    required this.child,
    required this.animation,
    this.isForward = true,
  });

  @override
  Widget build(BuildContext context) {
    // Fade animation
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Subtle slide animation
    final slideAnimation = Tween<Offset>(
      begin: Offset(isForward ? 0.03 : -0.03, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    // Scale animation for depth
    final scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(scale: scaleAnimation, child: child),
      ),
    );
  }
}

/// Parallax transition for exiting screen
class LiquidParallaxTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const LiquidParallaxTransition({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    // Slower fade out
    final fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // Subtle parallax movement
    final slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.02, 0.0),
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInCubic));

    // Slight scale down
    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInCubic));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(scale: scaleAnimation, child: child),
      ),
    );
  }
}

/// Custom page route with fade and slide transition
/// Duration: 350ms (within 300-400ms requirement)
/// Curve: ease-in-out
/// Validates: Requirements 7.1, 7.5
class LiquidPageRoute<T> extends PageRouteBuilder<T> {
  LiquidPageRoute({required Widget page, RouteSettings? settings})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Fade animation with ease-in-out curve
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );

          // Subtle slide animation with ease-in-out curve
          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(0.03, 0.0), // Subtle 3% horizontal slide
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              );

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350), // 300-400ms
        reverseTransitionDuration: const Duration(milliseconds: 350),
        settings: settings,
      );
}
