import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/history_entry.dart';
import '../../data/models/music_content_type.dart';
import '../theme/app_theme.dart';
import 'liquid_glass_container.dart';
import 'album_art_with_glow.dart';

/// HistoryCard - Card widget displaying a single history entry
///
/// A modern card component that displays music history entries with:
/// - Glass background using LiquidGlassContainer
/// - Album art thumbnail using AlbumArtWithGlow
/// - Song title, artist, and timestamp
/// - Consistent spacing and typography from AppTheme
/// - Tap interaction support
///
/// Design Principles:
/// - Uses LiquidGlassContainer for premium glass effect
/// - AlbumArtWithGlow for album thumbnails (smaller size)
/// - Typography hierarchy: title for song, body for artist, label for timestamp
/// - Consistent spacing using AppTheme.spacing
/// - Clean, minimal layout
///
/// Requirements: 10.3, 10.4, 10.5, 20.3
///
/// Usage:
/// ```dart
/// HistoryCard(
///   historyEntry: entry,
///   onTap: () => handleTap(entry),
/// )
/// ```
class HistoryCard extends StatelessWidget {
  /// The history entry to display
  final HistoryEntry historyEntry;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  const HistoryCard({super.key, required this.historyEntry, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _semanticsLabel(historyEntry),
      hint: 'Tap to view details',
      child: GestureDetector(
        onTap: onTap != null
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        child: LiquidGlassContainer(
          borderRadius: AppTheme.radii.medium,
          padding: EdgeInsets.all(AppTheme.spacing.m),
          child: Row(
            children: [
              // Album art thumbnail (smaller size for history cards)
              AlbumArtWithGlow(
                imageUrl: historyEntry.thumbnailUrl,
                size: 56,
                glowIntensity: 0.3, // Subtle glow for thumbnails
              ),
              SizedBox(width: AppTheme.spacing.m),

              // Song metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Song title
                    Text(
                      _displayTitle(historyEntry),
                      style: AppTheme.typography.titleMedium.copyWith(
                        color: AppTheme.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppTheme.spacing.xs / 2), // 4px
                    // Artist name
                    if (_displaySubtitle(historyEntry).isNotEmpty)
                      Text(
                        _displaySubtitle(historyEntry),
                        style: AppTheme.typography.bodyMedium.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: AppTheme.spacing.xs / 2), // 4px
                    // Timestamp
                    Text(
                      _formatTimestamp(historyEntry.timestamp),
                      style: AppTheme.typography.labelMedium.copyWith(
                        color: AppTheme.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron indicator
              Icon(
                Icons.chevron_right,
                color: AppTheme.colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayTitle(HistoryEntry entry) {
    switch (entry.contentType) {
      case MusicContentType.album:
      case MusicContentType.track:
      case MusicContentType.playlist:
      case MusicContentType.unknown:
        return entry.title;
      case MusicContentType.artist:
        return entry.title.isNotEmpty ? entry.title : entry.artist;
    }
  }

  String _displaySubtitle(HistoryEntry entry) {
    switch (entry.contentType) {
      case MusicContentType.artist:
        return 'Artist';
      case MusicContentType.album:
      case MusicContentType.track:
      case MusicContentType.playlist:
      case MusicContentType.unknown:
        return entry.artist;
    }
  }

  String _semanticsLabel(HistoryEntry entry) {
    final title = _displayTitle(entry);
    final subtitle = _displaySubtitle(entry);
    final headline = subtitle.isNotEmpty ? '$title, $subtitle' : title;
    return '$headline, ${_formatTimestamp(entry.timestamp)}';
  }

  /// Format timestamp as relative time in English
  /// Requirement 17.1: All text in English
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      // Format as date for older entries
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}
