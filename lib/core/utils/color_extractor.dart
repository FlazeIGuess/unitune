import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:palette_generator/palette_generator.dart';

/// Service for extracting dominant colors from images (album artwork)
///
/// Provides color extraction with:
/// - Fallback to default blue for invalid URLs or extraction failures
/// - Filtering of colors that are too dark or too light
/// - Generation of harmonious color variants (primary, light, dark)
class ColorExtractor {
  // Default primary blue (UniTune brand color)
  static const Color defaultPrimary = Color(0xFF58A6FF);
  static const Color defaultPrimaryLight = Color(0xFF79C0FF);
  static const Color defaultPrimaryDark = Color(0xFF1F6FEB);

  // Luminance thresholds for fallback detection
  static const double _minLuminance =
      0.35; // Increased for better visibility on dark theme
  static const double _maxLuminance = 0.85; // Too light

  // Cache for extracted colors (URL -> Color)
  static final Map<String, Color> _cache = {};

  /// Extract dominant color from an image URL
  ///
  /// Returns the dominant color if extraction succeeds and the color
  /// meets luminance requirements. Otherwise returns null.
  static Future<Color?> extractFromUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      debugPrint('ColorExtractor: No image URL provided');
      return null;
    }

    // Check cache first
    if (_cache.containsKey(imageUrl)) {
      debugPrint('ColorExtractor: Using cached color for $imageUrl');
      return _cache[imageUrl];
    }

    try {
      // Download image
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint(
          'ColorExtractor: Failed to download image: ${response.statusCode}',
        );
        return null;
      }

      // Decode image
      final bytes = response.bodyBytes;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Generate palette
      final palette = await PaletteGenerator.fromImage(
        image,
        maximumColorCount: 16,
      );

      // Priority 1: Light Vibrant (Best for dark theme contrast)
      Color? selectedColor = palette.lightVibrantColor?.color;

      // Priority 2: Vibrant
      selectedColor ??= palette.vibrantColor?.color;

      // Priority 3: Light Muted
      selectedColor ??= palette.lightMutedColor?.color;

      // Priority 4: Dominant
      selectedColor ??= palette.dominantColor?.color;

      // Final fallback to any color
      if (selectedColor == null && palette.colors.isNotEmpty) {
        selectedColor = palette.colors.first;
      }

      if (selectedColor == null) {
        debugPrint('ColorExtractor: No suitable color found in palette');
        return null;
      }

      // Adjust color if too dark or too light (instead of rejecting)
      selectedColor = _adjustColorLuminance(selectedColor);

      // Cache the result
      _cache[imageUrl] = selectedColor;

      debugPrint(
        'ColorExtractor: Extracted color ${selectedColor.toHexString()} from $imageUrl',
      );
      return selectedColor;
    } catch (e) {
      debugPrint('ColorExtractor: Error extracting color: $e');
      return null;
    }
  }

  /// Adjust color luminance to ensure it's visible on dark backgrounds
  static Color _adjustColorLuminance(Color color) {
    final luminance = color.computeLuminance();
    final hsl = HSLColor.fromColor(color);

    if (luminance < _minLuminance) {
      // Too dark - lighten it significantly to reach at least mid-brightness
      // Target lightness around 0.5 - 0.6
      debugPrint(
        'ColorExtractor: Color too dark (luminance: $luminance), lightening',
      );
      return hsl
          .withLightness((hsl.lightness + 0.3).clamp(0.40, 0.8))
          .toColor();
    } else if (luminance > _maxLuminance) {
      // Too light - darken it slightly
      debugPrint(
        'ColorExtractor: Color too light (luminance: $luminance), darkening',
      );
      return hsl
          .withLightness((hsl.lightness - 0.2).clamp(0.15, 0.8))
          .toColor();
    }

    // Also check saturation - if it's too gray, boost saturation
    if (hsl.saturation < 0.15) {
      debugPrint('ColorExtractor: Color too gray, boosting saturation');
      return hsl.withSaturation(0.3).toColor();
    }

    return color;
  }

  /// Generate a lighter variant of the color
  static Color generateLightVariant(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 0.85)).toColor();
  }

  /// Generate a darker variant of the color
  static Color generateDarkVariant(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.15, 1.0)).toColor();
  }

  /// Generate complete color set from a base color
  static ({Color primary, Color light, Color dark}) generateColorSet(
    Color baseColor,
  ) {
    return (
      primary: baseColor,
      light: generateLightVariant(baseColor),
      dark: generateDarkVariant(baseColor),
    );
  }

  /// Clear the cache (for testing or memory management)
  static void clearCache() {
    _cache.clear();
  }
}

/// Extension to get hex string from Color
extension ColorHexExtension on Color {
  String toHexString() {
    return '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
