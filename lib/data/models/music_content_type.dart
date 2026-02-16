import 'package:flutter/material.dart';

/// Type of music content being shared
enum MusicContentType {
  track,
  album,
  artist,
  playlist,
  unknown;

  String get displayName {
    switch (this) {
      case MusicContentType.track:
        return 'Track';
      case MusicContentType.album:
        return 'Album';
      case MusicContentType.artist:
        return 'Artist';
      case MusicContentType.playlist:
        return 'Playlist';
      case MusicContentType.unknown:
        return 'Unknown';
    }
  }

  IconData get icon {
    switch (this) {
      case MusicContentType.track:
        return Icons.music_note;
      case MusicContentType.album:
        return Icons.album;
      case MusicContentType.artist:
        return Icons.person;
      case MusicContentType.playlist:
        return Icons.queue_music;
      case MusicContentType.unknown:
        return Icons.help_outline;
    }
  }
}
