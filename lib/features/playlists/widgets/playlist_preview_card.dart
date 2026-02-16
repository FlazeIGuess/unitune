import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../../data/models/playlist_track.dart';

class PlaylistPreviewCard extends StatelessWidget {
  final String title;
  final List<PlaylistTrack> tracks;

  const PlaylistPreviewCard({
    super.key,
    required this.title,
    required this.tracks,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      tintColor: context.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCoverGrid(context),
              SizedBox(width: AppTheme.spacing.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.typography.titleMedium.copyWith(
                        color: AppTheme.colors.textPrimary,
                        fontFamily: 'ZalandoSansExpanded',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppTheme.spacing.s),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.m,
                        vertical: AppTheme.spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radii.pill,
                        ),
                      ),
                      child: Text(
                        '${tracks.length} ${tracks.length == 1 ? 'track' : 'tracks'}',
                        style: AppTheme.typography.labelMedium.copyWith(
                          color: context.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (tracks.isNotEmpty) ...[
                      SizedBox(height: AppTheme.spacing.s),
                      Text(
                        _buildArtistSummary(tracks),
                        style: AppTheme.typography.bodyMedium.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverGrid(BuildContext context) {
    final coverUrls = tracks
        .where((t) => t.thumbnailUrl != null)
        .take(4)
        .map((t) => t.thumbnailUrl!)
        .toList();

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radii.medium),
        color: context.primaryColor.withValues(alpha: 0.1),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radii.medium),
        child: coverUrls.isEmpty
            ? Icon(Icons.queue_music, size: 40, color: context.primaryColor)
            : coverUrls.length == 1
            ? Image.network(
                coverUrls[0],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.music_note,
                  size: 40,
                  color: context.primaryColor,
                ),
              )
            : _buildGrid(context, coverUrls),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<String> urls) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        if (index < urls.length) {
          return Image.network(
            urls[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: context.primaryColor.withValues(alpha: 0.1)),
          );
        }
        return Container(color: context.primaryColor.withValues(alpha: 0.1));
      },
    );
  }

  String _buildArtistSummary(List<PlaylistTrack> tracks) {
    final artists = tracks
        .map((track) => track.artist.trim())
        .where((artist) => artist.isNotEmpty)
        .toSet()
        .toList();

    if (artists.isEmpty) {
      return 'Various artists';
    }

    if (artists.length <= 2) {
      return artists.join(' • ');
    }

    final visible = artists.take(2).join(' • ');
    return '$visible +${artists.length - 2}';
  }
}
