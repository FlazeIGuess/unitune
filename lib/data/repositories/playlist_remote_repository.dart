import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/playlist_track.dart';
import '../models/mini_playlist.dart';
import '../../core/constants/services.dart';

class PlaylistRemoteCreateResult {
  final String id;
  final String deleteToken;
  final DateTime? expiresAt;

  PlaylistRemoteCreateResult({
    required this.id,
    required this.deleteToken,
    this.expiresAt,
  });
}

class PlaylistRemoteData {
  final String id;
  final String title;
  final String? description;
  final List<PlaylistTrack> tracks;
  final String? creatorNickname;

  PlaylistRemoteData({
    required this.id,
    required this.title,
    required this.description,
    required this.tracks,
    this.creatorNickname,
  });
}

class PlaylistRemoteRepository {
  /// Every remote call is bounded. Without a timeout a stalled connection
  /// leaves the caller's spinner running indefinitely.
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  PlaylistRemoteRepository({http.Client? client})
    : _client = client ?? http.Client();

  /// Creates the playlist on the backend.
  ///
  /// Returns null on any failure (network error, non-201 status, malformed
  /// payload). Callers must treat null as "no share link is possible yet"
  /// and tell the user — never silently continue.
  Future<PlaylistRemoteCreateResult?> create(MiniPlaylist playlist) async {
    final uri = Uri.parse(ApiConstants.unitunePlaylistBaseUrl);
    final body = {
      'title': playlist.title,
      'description': playlist.description,
      'creatorNickname': playlist.creatorNickname,
      'tracks': playlist.tracks
          .map(
            (track) => {
              'title': track.title,
              'artist': track.artist,
              'originalUrl': track.originalUrl,
              'thumbnailUrl': track.thumbnailUrl,
              'addedAt': track.addedAt?.toIso8601String(),
            },
          )
          .toList(),
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode != 201) {
        debugPrint(
          'PlaylistRemoteRepository.create failed status=${response.statusCode}',
        );
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final id = json['id'] as String?;
      final deleteToken = json['deleteToken'] as String?;
      if (id == null || deleteToken == null) {
        debugPrint('PlaylistRemoteRepository.create malformed response');
        return null;
      }

      final expiresAtRaw = json['expiresAt'] as String?;
      return PlaylistRemoteCreateResult(
        id: id,
        deleteToken: deleteToken,
        expiresAt: expiresAtRaw != null
            ? DateTime.tryParse(expiresAtRaw)
            : null,
      );
    } catch (e) {
      debugPrint('PlaylistRemoteRepository.create error: $e');
      return null;
    }
  }

  /// Loads a shared playlist by its remote id.
  ///
  /// Returns null when the playlist does not exist, has expired, or the
  /// request failed. Throws nothing — callers render an error state instead.
  Future<PlaylistRemoteData?> fetch(String playlistId) async {
    final uri = Uri.parse('${ApiConstants.unitunePlaylistBaseUrl}/$playlistId');
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        debugPrint(
          'PlaylistRemoteRepository.fetch failed status=${response.statusCode}',
        );
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final id = json['id'] as String?;
      final title = json['title'] as String?;
      if (id == null || title == null) {
        debugPrint('PlaylistRemoteRepository.fetch malformed response');
        return null;
      }

      final tracksJson = (json['tracks'] as List<dynamic>? ?? []);
      final tracks = tracksJson.asMap().entries.map((entry) {
        final map = entry.value as Map<String, dynamic>;
        return PlaylistTrack(
          id: '${DateTime.now().microsecondsSinceEpoch}_${entry.key}',
          title: (map['title'] as String?) ?? 'Unknown Track',
          artist: (map['artist'] as String?) ?? 'Unknown Artist',
          originalUrl: (map['originalUrl'] as String?) ?? '',
          thumbnailUrl: map['thumbnailUrl'] as String?,
          // The backend stores only the creator's original URL. Per-platform
          // links are resolved lazily on first open and cached locally.
          convertedLinks: const {},
          addedAt: map['addedAt'] != null
              ? DateTime.tryParse(map['addedAt'] as String)
              : null,
        );
      }).toList();

      return PlaylistRemoteData(
        id: id,
        title: title,
        description: json['description'] as String?,
        tracks: tracks,
        creatorNickname: json['creatorNickname'] as String?,
      );
    } catch (e) {
      debugPrint('PlaylistRemoteRepository.fetch error: $e');
      return null;
    }
  }
}

final playlistRemoteRepositoryProvider = Provider<PlaylistRemoteRepository>((
  ref,
) {
  return PlaylistRemoteRepository();
});
