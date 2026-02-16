import 'dart:convert';
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

  PlaylistRemoteData({
    required this.id,
    required this.title,
    required this.description,
    required this.tracks,
  });
}

class PlaylistRemoteRepository {
  final http.Client _client;

  PlaylistRemoteRepository({http.Client? client})
    : _client = client ?? http.Client();

  Future<PlaylistRemoteCreateResult?> create(MiniPlaylist playlist) async {
    final uri = Uri.parse(ApiConstants.unitunePlaylistBaseUrl);
    final body = {
      'title': playlist.title,
      'description': playlist.description,
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

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      return null;
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final expiresAtRaw = json['expiresAt'] as String?;
    return PlaylistRemoteCreateResult(
      id: json['id'] as String,
      deleteToken: json['deleteToken'] as String,
      expiresAt: expiresAtRaw != null ? DateTime.tryParse(expiresAtRaw) : null,
    );
  }

  Future<PlaylistRemoteData?> fetch(String playlistId) async {
    final uri = Uri.parse('${ApiConstants.unitunePlaylistBaseUrl}/$playlistId');
    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final tracksJson = (json['tracks'] as List<dynamic>? ?? []);
    final tracks = tracksJson.asMap().entries.map((entry) {
      final map = entry.value as Map<String, dynamic>;
      return PlaylistTrack(
        id: '${DateTime.now().microsecondsSinceEpoch}_${entry.key}',
        title: (map['title'] as String?) ?? 'Unknown Track',
        artist: (map['artist'] as String?) ?? 'Unknown Artist',
        originalUrl: (map['originalUrl'] as String?) ?? '',
        thumbnailUrl: map['thumbnailUrl'] as String?,
        convertedLinks: const {},
        addedAt: map['addedAt'] != null
            ? DateTime.tryParse(map['addedAt'] as String)
            : null,
      );
    }).toList();

    return PlaylistRemoteData(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      tracks: tracks,
    );
  }
}

final playlistRemoteRepositoryProvider = Provider<PlaylistRemoteRepository>((
  ref,
) {
  return PlaylistRemoteRepository();
});
