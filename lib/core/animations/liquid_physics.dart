import 'package:flutter/material.dart';

/// Spring physics configurations for liquid glass animations
/// Provides natural, organic motion

class LiquidPhysics {
  LiquidPhysics._();

  /// Gentle spring for smooth transitions
  static const SpringDescription gentle = SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 20.0,
  );

  /// Bouncy spring for playful interactions
  static const SpringDescription bouncy = SpringDescription(
    mass: 1.0,
    stiffness: 200.0,
    damping: 15.0,
  );

  /// Snappy spring for quick responses
  static const SpringDescription snappy = SpringDescription(
    mass: 0.8,
    stiffness: 250.0,
    damping: 22.0,
  );

  /// Elastic spring with overshoot
  static const SpringDescription elastic = SpringDescription(
    mass: 1.2,
    stiffness: 150.0,
    damping: 12.0,
  );

  /// Smooth spring without overshoot
  static const SpringDescription smooth = SpringDescription(
    mass: 1.0,
    stiffness: 200.0,
    damping: 25.0,
  );
}

/// Animation durations for consistent timing
class LiquidDurations {
  LiquidDurations._();

  /// Quick interactions (tap, press)
  static const Duration quick = Duration(milliseconds: 150);

  /// Standard transitions
  static const Duration standard = Duration(milliseconds: 300);

  /// Smooth page transitions
  static const Duration smooth = Duration(milliseconds: 400);

  /// Ambient animations (breathing, glow)
  static const Duration ambient = Duration(milliseconds: 3000);

  /// Long ambient animations
  static const Duration ambientLong = Duration(milliseconds: 4000);
}

/// Animation curves for liquid glass effects
class LiquidCurves {
  LiquidCurves._();

  /// Smooth ease in and out
  static const Curve smooth = Curves.easeInOutCubic;

  /// Quick ease out
  static const Curve quickOut = Curves.easeOutCubic;

  /// Elastic overshoot
  static const Curve elastic = Curves.elasticOut;

  /// Gentle bounce
  static const Curve bounce = Curves.easeOutBack;

  /// Sharp snap
  static const Curve snap = Curves.easeOutExpo;
}
