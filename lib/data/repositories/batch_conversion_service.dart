import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/playlist_track.dart';
import '../../core/constants/services.dart';

class BatchConversionResult {
  final List<PlaylistTrack> tracks;
  final int successCount;
  final int failedCount;
  final List<String> errors;

  BatchConversionResult({
    required this.tracks,
    required this.successCount,
    required this.failedCount,
    required this.errors,
  });
}

class BatchConversionService {
  static const String _baseUrl = 'https://unitune-api.onrender.com';
  static const Duration _timeout = Duration(seconds: 30);

  final http.Client _client;

  BatchConversionService({http.Client? client})
    : _client = client ?? http.Client();

  Future<BatchConversionResult> convertBatch(
    List<String> urls, {
    MusicService? preferredService,
  }) async {
    if (urls.isEmpty || urls.length > 10) {
      throw ArgumentError('Must provide 1-10 URLs');
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/v1/batch'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'urls': urls}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseResponse(data);
      } else {
        throw Exception('Batch conversion failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Batch conversion error: $e');
      rethrow;
    }
  }

  BatchConversionResult _parseResponse(Map<String, dynamic> data) {
    final tracksData = data['tracks'] as List<dynamic>? ?? [];
    final tracks = <PlaylistTrack>[];

    for (final trackData in tracksData) {
      try {
        final track = _parseTrack(trackData as Map<String, dynamic>);
        if (track != null) {
          tracks.add(track);
        }
      } catch (e) {
        debugPrint('Error parsing track: $e');
      }
    }

    final errors =
        (data['errors'] as List<dynamic>?)
            ?.map((e) => e['error']?.toString() ?? 'Unknown error')
            .toList() ??
        [];

    return BatchConversionResult(
      tracks: tracks,
      successCount: data['success_count'] as int? ?? tracks.length,
      failedCount: data['failed_count'] as int? ?? 0,
      errors: errors,
    );
  }

  PlaylistTrack? _parseTrack(Map<String, dynamic> data) {
    try {
      final links = data['links'] as Map<String, dynamic>? ?? {};
      final convertedLinks = <String, String>{};

      links.forEach((key, value) {
        if (value is Map && value.containsKey('url')) {
          convertedLinks[key] = value['url'] as String;
        }
      });

      return PlaylistTrack(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: data['title'] as String? ?? 'Unknown Track',
        artist: data['artist'] as String? ?? 'Unknown Artist',
        originalUrl: data['original_url'] as String? ?? '',
        thumbnailUrl: data['thumbnail_url'] as String?,
        convertedLinks: convertedLinks,
        addedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing track data: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
