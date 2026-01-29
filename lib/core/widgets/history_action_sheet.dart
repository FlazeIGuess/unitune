import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../theme/app_theme.dart';
import '../theme/dynamic_theme.dart';

/// Liquid Glass Action Sheet for History Entry Actions
///
/// Shows a bottom sheet with actions for a history entry:
/// - Share: Re-share the song via messenger
/// - Open: Open the song in preferred music app
///
/// Features:
/// - Liquid Glass background
/// - Smooth slide-up animation
/// - Haptic feedback
/// - Icon + Label for each action
class HistoryActionSheet extends StatelessWidget {
  final String title;
  final String artist;
  final String? thumbnailUrl;
  final VoidCallback onShare;
  final VoidCallback onOpen;

  const HistoryActionSheet({
    super.key,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    required this.onShare,
    required this.onOpen,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String artist,
    String? thumbnailUrl,
    required VoidCallback onShare,
    required VoidCallback onOpen,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => HistoryActionSheet(
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        onShare: onShare,
        onOpen: onOpen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: LiquidGlassLayer(
        settings: AppTheme.liquidGlassDefault,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.colors.textMuted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: AppTheme.spacing.l),

                // Song Info Header
                _buildSongHeader(context),
                SizedBox(height: AppTheme.spacing.xl),

                // Actions
                _buildActionButton(
                  context: context,
                  icon: Icons.share_outlined,
                  label: 'Share Again',
                  subtitle: 'Send to messenger',
                  color: context.primaryColor,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    onShare();
                  },
                ),
                SizedBox(height: AppTheme.spacing.m),
                _buildActionButton(
                  context: context,
                  icon: Icons.music_note_outlined,
                  label: 'Open in Music App',
                  subtitle: 'Listen now',
                  color: AppTheme.colors.accentSuccess,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    onOpen();
                  },
                ),
                SizedBox(height: AppTheme.spacing.m),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongHeader(BuildContext context) {
    return Row(
      children: [
        // Thumbnail
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radii.medium),
            boxShadow: AppTheme.glowSoft(context.primaryColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radii.medium),
            child: thumbnailUrl != null
                ? Image.network(
                    thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
        ),
        SizedBox(width: AppTheme.spacing.m),

        // Title & Artist
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.typography.titleMedium.copyWith(
                  color: AppTheme.colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                artist,
                style: AppTheme.typography.bodyMedium.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.colors.backgroundCard,
      child: Center(
        child: Icon(
          Icons.music_note,
          color: AppTheme.colors.textMuted,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass.withOwnLayer(
        settings: AppTheme.liquidGlassDefault,
        shape: LiquidRoundedSuperellipse(borderRadius: AppTheme.radii.large),
        child: Container(
          padding: EdgeInsets.all(AppTheme.spacing.m),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.colors.glassBorder, width: 1.0),
            borderRadius: BorderRadius.circular(AppTheme.radii.large),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: AppTheme.spacing.m),

              // Label & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTheme.typography.titleMedium.copyWith(
                        color: AppTheme.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.typography.labelMedium.copyWith(
                        color: AppTheme.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.colors.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
