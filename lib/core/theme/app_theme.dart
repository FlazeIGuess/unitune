import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// UniTune Unified Theme - Modern Dark Mode Design with Liquid Glass
///
/// Design Principles:
/// - Cohesive color palette with refined, comfortable colors
/// - Liquid Glass morphism for premium feel
/// - Clear typography hierarchy with tight letter-spacing
/// - Consistent spacing based on 8px grid
/// - Smooth animations with standard durations and curves
/// - Dark mode optimized for extended use

// === COLOR PALETTE ===

/// Complete color palette for the UniTune app
class ColorPalette {
  const ColorPalette({
    required this.backgroundDeep,
    required this.backgroundMedium,
    required this.backgroundCard,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accentSuccess,
    required this.accentWarning,
    required this.accentError,
    required this.spotify,
    required this.appleMusic,
    required this.tidal,
    required this.youtubeMusic,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.glassBase,
    required this.glassBorder,
    required this.glassHighlight,
  });

  // Background colors
  final Color backgroundDeep;
  final Color backgroundMedium;
  final Color backgroundCard;

  // Primary colors
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  // Accent colors
  final Color accentSuccess;
  final Color accentWarning;
  final Color accentError;

  // Platform colors
  final Color spotify;
  final Color appleMusic;
  final Color tidal;
  final Color youtubeMusic;

  // Text colors
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Glass colors
  final Color glassBase;
  final Color glassBorder;
  final Color glassHighlight;

  /// Create a copy with overridden primary colors
  /// Used for dynamic color updates based on song artwork
  ColorPalette withPrimaryColors({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
  }) {
    return ColorPalette(
      backgroundDeep: backgroundDeep,
      backgroundMedium: backgroundMedium,
      backgroundCard: backgroundCard,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      accentSuccess: accentSuccess,
      accentWarning: accentWarning,
      accentError: accentError,
      spotify: spotify,
      appleMusic: appleMusic,
      tidal: tidal,
      youtubeMusic: youtubeMusic,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      glassBase: glassBase,
      glassBorder: glassBorder,
      glassHighlight: glassHighlight,
    );
  }
}

// === TYPOGRAPHY SCALE ===

/// Typography scale with all text styles
class TypographyScale {
  const TypographyScale({
    required this.displayLarge,
    required this.displayMedium,
    required this.titleLarge,
    required this.titleMedium,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.labelLarge,
    required this.labelMedium,
  });

  // Display (32-40px) - Hero text, song titles
  final TextStyle displayLarge;
  final TextStyle displayMedium;

  // Title (20-24px) - Section headers
  final TextStyle titleLarge;
  final TextStyle titleMedium;

  // Body (14-16px) - General content
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;

  // Label (12-14px) - Buttons, tags
  final TextStyle labelLarge;
  final TextStyle labelMedium;
}

// === SPACING SYSTEM ===

/// Spacing values based on 8px grid
class Spacing {
  const Spacing({
    required this.xs,
    required this.s,
    required this.m,
    required this.l,
    required this.xl,
    required this.xxl,
  });

  final double xs; // 8px
  final double s; // 12px
  final double m; // 16px
  final double l; // 24px
  final double xl; // 32px
  final double xxl; // 48px
}

// === BORDER RADII ===

/// Border radius values for different component sizes
class BorderRadii {
  const BorderRadii({
    required this.small,
    required this.medium,
    required this.large,
    required this.xLarge,
    required this.pill,
  });

  final double small; // 12px
  final double medium; // 16px
  final double large; // 20px
  final double xLarge; // 24px
  final double pill; // 100px
}

// === ANIMATION CONFIGURATION ===

/// Animation durations, curves, and physics
class AnimationConfig {
  const AnimationConfig({
    required this.durationFast,
    required this.durationNormal,
    required this.durationSlow,
    required this.curveStandard,
    required this.curveDecelerate,
    required this.curveAccelerate,
    required this.springStiffness,
    required this.springDamping,
  });

  final Duration durationFast; // 150ms
  final Duration durationNormal; // 250ms
  final Duration durationSlow; // 400ms
  final Curve curveStandard; // easeInOut
  final Curve curveDecelerate; // easeOut
  final Curve curveAccelerate; // easeIn
  final double springStiffness; // 200.0
  final double springDamping; // 20.0
}

// === UNIFIED APP THEME ===

class AppTheme {
  AppTheme._();

  // Color Palette
  static const ColorPalette colors = ColorPalette(
    // Background colors
    backgroundDeep: Color(0xFF0D1117), // GitHub Dark
    backgroundMedium: Color(0xFF161B22), // Elevated Dark
    backgroundCard: Color(0xFF21262D), // Card Surface
    // Primary colors
    primary: Color(0xFF58A6FF), // Soft Azure Blue
    primaryLight: Color(0xFF79C0FF), // Sky Blue
    primaryDark: Color(0xFF1F6FEB), // Deep Blue
    // Accent colors
    accentSuccess: Color(0xFF7EE787), // Soft Green
    accentWarning: Color(0xFFD29922), // Amber
    accentError: Color(0xFFF85149), // Soft Red
    // Platform colors
    spotify: Color(0xFF1DB954), // Spotify Green
    appleMusic: Color(0xFFFA243C), // Apple Music Red
    tidal: Color(0xFFFFFFFF), // Tidal White
    youtubeMusic: Color(0xFFFF0000), // YouTube Red
    // Text colors
    textPrimary: Color(0xFFF0F6FC), // Soft White
    textSecondary: Color(0xFF8B949E), // Medium Gray
    textMuted: Color(0xFF8B949E), // Muted Gray (updated for WCAG AA compliance)
    // Glass colors
    glassBase: Color(0x0DFFFFFF), // 5% white (13/255 = 0.051)
    glassBorder: Color(0x19FFFFFF), // 10% white (25/255 = 0.098)
    glassHighlight: Color(0x26FFFFFF), // 15% white (38/255 = 0.149)
  );

  // Typography Scale
  static const TypographyScale typography = TypographyScale(
    // Display (32-40px) - Hero text, song titles
    displayLarge: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      height: 1.1,
    ),
    displayMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      height: 1.1,
    ),

    // Title (20-24px) - Section headers
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    titleMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.3,
    ),

    // Body (14-16px) - General content
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),

    // Label (12-14px) - Buttons, tags
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: 1.4,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: 1.4,
    ),
  );

  // Spacing System (8px base grid)
  static const Spacing spacing = Spacing(
    xs: 8.0,
    s: 12.0,
    m: 16.0,
    l: 24.0,
    xl: 32.0,
    xxl: 48.0,
  );

  // Border Radius
  static const BorderRadii radii = BorderRadii(
    small: 12.0,
    medium: 16.0,
    large: 20.0,
    xLarge: 24.0,
    pill: 100.0,
  );

  // Animation Configuration
  static const AnimationConfig animation = AnimationConfig(
    durationFast: Duration(milliseconds: 150),
    durationNormal: Duration(milliseconds: 250),
    durationSlow: Duration(milliseconds: 400),
    curveStandard: Curves.easeInOut,
    curveDecelerate: Curves.easeOut,
    curveAccelerate: Curves.easeIn,
    springStiffness: 200.0,
    springDamping: 20.0,
  );

  // === LIQUID GLASS SETTINGS ===
  /// Default Liquid Glass settings for cards and containers
  static const LiquidGlassSettings liquidGlassDefault = LiquidGlassSettings(
    thickness: 15,
    blur: 12,
    glassColor: Color(0x0DFFFFFF), // 5% white
    lightIntensity: 0.6,
    saturation: 1.3,
    ambientStrength: 0.3,
    refractiveIndex: 1.15,
  );

  /// Liquid Glass settings for buttons (more prominent)
  static const LiquidGlassSettings liquidGlassButton = LiquidGlassSettings(
    thickness: 10,
    blur: 8,
    glassColor: Color(0x1AFFFFFF), // 10% white
    lightIntensity: 0.7,
    saturation: 1.4,
    ambientStrength: 0.35,
    refractiveIndex: 1.2,
  );

  /// Liquid Glass settings for spheres (subtle, elegant)
  static const LiquidGlassSettings liquidGlassSphere = LiquidGlassSettings(
    thickness: 20,
    blur: 15,
    glassColor: Color(0x08FFFFFF), // 3% white
    lightIntensity: 0.65,
    saturation: 1.35,
    ambientStrength: 0.4,
    refractiveIndex: 1.25,
  );

  // === GRADIENTS ===
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1117), Color(0xFF161B22)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF58A6FF), Color(0xFF79C0FF)],
  );

  /// Dynamic primary gradient based on extracted colors
  /// Use this when you have dynamic color state available
  static LinearGradient dynamicPrimaryGradient(
    Color primary,
    Color primaryLight,
  ) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, primaryLight],
    );
  }

  // === SHADOWS ===
  static List<BoxShadow> get shadowSoft => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get shadowStrong => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 40,
      offset: const Offset(0, 12),
    ),
  ];

  // === GLOW EFFECTS ===
  static List<BoxShadow> glowSoft(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.2),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> glowMedium(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 40,
      spreadRadius: 5,
    ),
  ];

  static List<BoxShadow> glowStrong(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.4),
      blurRadius: 60,
      spreadRadius: 10,
    ),
  ];

  // === THEME DATA ===
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.backgroundDeep,
      colorScheme: ColorScheme.dark(
        primary: colors.primary,
        secondary: colors.primaryLight,
        surface: colors.backgroundCard,
        error: colors.accentError,
        onPrimary: colors.backgroundDeep,
        onSecondary: colors.backgroundDeep,
        onSurface: colors.textPrimary,
      ),
      textTheme: TextTheme(
        // Display (32-40px)
        // Display (32-40px)
        displayLarge: typography.displayLarge.copyWith(
          color: colors.textPrimary,
          fontFamily: 'ZalandoSansExpanded',
        ),
        displayMedium: typography.displayMedium.copyWith(
          color: colors.textPrimary,
          fontFamily: 'ZalandoSansExpanded',
        ),
        // Title (20-24px)
        titleLarge: typography.titleLarge.copyWith(
          color: colors.textPrimary,
          fontFamily: 'ZalandoSansExpanded',
        ),
        titleMedium: typography.titleMedium.copyWith(
          color: colors.textPrimary,
          fontFamily: 'ZalandoSansExpanded',
        ),
        // Body (14-16px) - Montserrat (local asset, no external requests)
        bodyLarge: typography.bodyLarge.copyWith(
          color: colors.textSecondary,
          fontFamily: 'Montserrat',
        ),
        bodyMedium: typography.bodyMedium.copyWith(
          color: colors.textSecondary,
          fontFamily: 'Montserrat',
        ),
        // Label (12-14px) - Montserrat
        labelLarge: typography.labelLarge.copyWith(
          color: colors.textPrimary,
          fontFamily: 'Montserrat',
        ),
        labelMedium: typography.labelMedium.copyWith(
          color: colors.textSecondary,
          fontFamily: 'Montserrat',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.backgroundDeep,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.pill),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.backgroundCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.large),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: colors.textPrimary,
      ),
    );
  }
}

// === HELPER FUNCTIONS ===

/// Glassmorphism decoration for cards (Dark Mode)
BoxDecoration glassDecoration({
  double opacity = 0.05,
  double borderRadius = 20.0,
  Color? borderColor,
}) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: borderColor ?? Colors.white.withValues(alpha: 0.1),
      width: 1,
    ),
  );
}

/// Dark card decoration (elevated)
BoxDecoration darkCardDecoration({
  double borderRadius = 20.0,
  List<BoxShadow>? shadows,
}) {
  return BoxDecoration(
    color: AppTheme.colors.backgroundCard,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: shadows ?? AppTheme.shadowSoft,
  );
}

/// Glassmorphism with backdrop blur
Widget glassContainer({
  required Widget child,
  double opacity = 0.05,
  double borderRadius = 20.0,
  EdgeInsets? padding,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: padding,
        decoration: glassDecoration(
          opacity: opacity,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    ),
  );
}
