import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/liquid_glass_sphere.dart';

/// Onboarding Illustrations
///
/// Visual demonstrations of key features for onboarding slides.
/// Uses liquid glass effects and platform colors.
///
/// Validates: Requirements 12.2

/// Welcome illustration - App logo in glass sphere
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSphere(
      size: 180,
      child: SvgPicture.asset(
        'assets/icon/app_icon.svg',
        width: 100, // Slightly improved size balance for sphere
        height: 100,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(context.primaryColor, BlendMode.srcIn),
        placeholderBuilder: (context) {
          return Center(
            child: Text(
              '♪',
              style: TextStyle(
                fontSize: 80,
                color: AppTheme.colors.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Cross-platform sharing illustration
class CrossPlatformIllustration extends StatelessWidget {
  const CrossPlatformIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center music icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor,
                  context.primaryColor.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radii.large),
              boxShadow: AppTheme.glowMedium(context.primaryColor),
            ),
            child: const Icon(Icons.music_note, size: 40, color: Colors.white),
          ),

          // Platform icons arranged in circle
          ..._buildPlatformIcons(),
        ],
      ),
    );
  }

  List<Widget> _buildPlatformIcons() {
    final platforms = [
      (Icons.music_note, AppTheme.colors.spotify, 0.0), // Spotify
      (
        Icons.music_note,
        AppTheme.colors.appleMusic,
        1.5708,
      ), // Apple Music (90°)
      (Icons.music_note, AppTheme.colors.tidal, 3.14159), // Tidal (180°)
      (
        Icons.music_note,
        AppTheme.colors.youtubeMusic,
        4.71239,
      ), // YouTube (270°)
    ];

    return platforms.map((platform) {
      final icon = platform.$1;
      final color = platform.$2;
      final angle = platform.$3;

      // Calculate position on circle
      final radius = 110.0;
      final x = radius * cos(angle);
      final y = radius * sin(angle);

      return Transform.translate(
        offset: Offset(x, y),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppTheme.radii.medium),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          ),
          child: Icon(icon, size: 28, color: color),
        ),
      );
    }).toList();
  }

  double cos(double radians) => radians == 0
      ? 1
      : radians == 1.5708
      ? 0
      : radians == 3.14159
      ? -1
      : 0;

  double sin(double radians) => radians == 0
      ? 0
      : radians == 1.5708
      ? 1
      : radians == 3.14159
      ? 0
      : -1;
}

/// Messenger sharing illustration
class MessengerIllustration extends StatelessWidget {
  const MessengerIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Large message bubble
          Positioned(
            top: 20,
            left: 20,
            child: _buildMessageBubble(
              context: context,
              width: 160,
              height: 100,
              color: context.primaryColor,
              alignment: Alignment.centerLeft,
            ),
          ),

          // Small message bubble
          Positioned(
            bottom: 40,
            right: 30,
            child: _buildMessageBubble(
              context: context,
              width: 120,
              height: 80,
              color: AppTheme.colors.accentSuccess,
              alignment: Alignment.centerRight,
            ),
          ),

          // Music note icon
          Positioned(
            bottom: 60,
            left: 60,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.primaryColor,
                    context.primaryColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radii.small),
                boxShadow: AppTheme.glowSoft(context.primaryColor),
              ),
              child: const Icon(
                Icons.music_note,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required BuildContext context,
    required double width,
    required double height,
    required Color color,
    required Alignment alignment,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radii.large),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing.m),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: alignment == Alignment.centerLeft
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Container(
              width: width * 0.6,
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: AppTheme.spacing.xs),
            Container(
              width: width * 0.4,
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
