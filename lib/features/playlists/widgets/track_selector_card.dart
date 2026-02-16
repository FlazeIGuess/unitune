import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../../data/models/playlist_track.dart';

class TrackSelectorCard extends StatelessWidget {
  final PlaylistTrack track;
  final int index;
  final VoidCallback onRemove;

  const TrackSelectorCard({
    super.key,
    required this.track,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing.m),
      child: LiquidGlassCard(
        padding: EdgeInsets.all(AppTheme.spacing.m),
        child: Row(
          children: [
            Icon(Icons.drag_handle, color: AppTheme.colors.textMuted, size: 20),
            SizedBox(width: AppTheme.spacing.m),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radii.small),
              child: track.thumbnailUrl != null
                  ? Image.network(
                      track.thumbnailUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(context),
                    )
                  : _buildPlaceholder(context),
            ),
            SizedBox(width: AppTheme.spacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track.title,
                    style: AppTheme.typography.bodyLarge.copyWith(
                      color: AppTheme.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    track.artist,
                    style: AppTheme.typography.bodyMedium.copyWith(
                      color: AppTheme.colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              color: AppTheme.colors.textMuted,
              iconSize: 20,
              onPressed: () {
                HapticFeedback.lightImpact();
                onRemove();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radii.small),
      ),
      child: Icon(Icons.music_note, size: 24, color: context.primaryColor),
    );
  }
}
