import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Album art component with saturated glow effect
///
/// Displays album artwork with a blurred, saturated duplicate layer
/// underneath to create a glowing effect. Handles loading states and
/// errors with a placeholder.
///
/// Design Principles:
/// - Glow layer uses blurred, saturated duplicate of the image
/// - Main album art has rounded corners
/// - Placeholder shown for null/error states
/// - Configurable size and glow intensity
///
/// Usage:
/// ```dart
/// AlbumArtWithGlow(
///   imageUrl: 'https://example.com/album.jpg',
///   size: 240,
///   glowIntensity: 0.5,
/// )
/// ```
class AlbumArtWithGlow extends StatelessWidget {
  /// URL of the album art image
  final String? imageUrl;

  /// Size of the album art (width and height)
  final double size;

  /// Optional custom glow color (if null, uses image colors)
  final Color? glowColor;

  /// Intensity of the glow effect (0.0 to 1.0)
  final double glowIntensity;

  const AlbumArtWithGlow({
    super.key,
    this.imageUrl,
    this.size = 240,
    this.glowColor,
    this.glowIntensity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate proportional border radius based on size
    // For 56px thumbnails: 8px radius (medium/2)
    // For 240px album art: 24px radius (xLarge)
    final borderRadius = size <= 60
        ? AppTheme.radii.medium /
              2 // Small thumbnails: 8px
        : AppTheme.radii.xLarge; // Large album art: 24px

    return Semantics(
      image: true,
      label: imageUrl != null ? 'Album artwork' : 'Album artwork placeholder',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow layer (blurred, saturated duplicate)
            if (imageUrl != null)
              Positioned.fill(
                child: Transform.scale(
                  scale: 0.85,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix([
                          1.8, 0, 0, 0, 0, // Saturate red
                          0, 1.8, 0, 0, 0, // Saturate green
                          0, 0, 1.8, 0, 0, // Saturate blue
                          0, 0, 0, glowIntensity, 0, // Alpha
                        ]),
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Main album art
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildPlaceholder(isLoading: true);
                        },
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds placeholder widget for loading/error states
  Widget _buildPlaceholder({bool isLoading = false}) {
    return Container(
      color: AppTheme.colors.backgroundCard,
      child: Center(
        child: isLoading
            ? CircularProgressIndicator(
                color: AppTheme.colors.primary,
                strokeWidth: 2,
              )
            : Icon(
                Icons.music_note,
                size: 64,
                color: AppTheme.colors.textMuted,
              ),
      ),
    );
  }
}
