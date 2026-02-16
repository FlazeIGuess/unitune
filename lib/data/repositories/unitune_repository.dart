import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../../core/constants/services.dart';
import '../models/music_content_type.dart';

/// UniTune API response model
class UnituneResponse {
  final String? entityUniqueId;
  final String? title;
  final String? artistName;
  final String? albumTitle;
  final String? thumbnailUrl;
  final Map<String, PlatformLink> linksByPlatform;
  final MusicContentType contentType;

  UnituneResponse({
    this.entityUniqueId,
    this.title,
    this.artistName,
    this.albumTitle,
    this.thumbnailUrl,
    required this.linksByPlatform,
    this.contentType = MusicContentType.track,
  });

  factory UnituneResponse.fromJson(Map<String, dynamic> json) {
    final linksMap = <String, PlatformLink>{};
    final linksByPlatform = json['linksByPlatform'] as Map<String, dynamic>?;

    if (linksByPlatform != null) {
      linksByPlatform.forEach((key, value) {
        linksMap[key] = PlatformLink.fromJson(value as Map<String, dynamic>);
      });
    }

    // Extract metadata from entitiesByUniqueId
    String? title;
    String? artistName;
    String? albumTitle;
    String? thumbnailUrl;
    MusicContentType contentType = MusicContentType.track;
    final entities = json['entitiesByUniqueId'] as Map<String, dynamic>?;
    if (entities != null && entities.isNotEmpty) {
      final firstEntity = entities.values.first as Map<String, dynamic>;
      final rawType =
          firstEntity['type'] ??
          firstEntity['entityType'] ??
          firstEntity['kind'];
      if (rawType != null) {
        contentType = _mapContentType(rawType.toString());
      }

      title = (firstEntity['title'] as String?) ??
          (firstEntity['name'] as String?);
      artistName = (firstEntity['artistName'] as String?) ??
          _extractArtistName(firstEntity);
      albumTitle = (firstEntity['albumName'] as String?) ??
          (firstEntity['collectionName'] as String?);
      thumbnailUrl = (firstEntity['thumbnailUrl'] as String?) ??
          (firstEntity['imageUrl'] as String?);

      if (contentType == MusicContentType.artist &&
          title == null &&
          artistName != null) {
        title = artistName;
      }

      if (contentType == MusicContentType.album &&
          albumTitle == null &&
          title != null) {
        albumTitle = title;
      }
    }

    return UnituneResponse(
      entityUniqueId: json['entityUniqueId'] as String?,
      title: title,
      artistName: artistName,
      albumTitle: albumTitle,
      thumbnailUrl: thumbnailUrl,
      linksByPlatform: linksMap,
      contentType: contentType,
    );
  }

  /// Get URL for a specific music service
  String? getUrlForService(MusicService service) {
    final platformKey = _serviceToPlatformKey(service);
    return linksByPlatform[platformKey]?.url;
  }

  static String _serviceToPlatformKey(MusicService service) {
    switch (service) {
      case MusicService.spotify:
        return 'spotify';
      case MusicService.appleMusic:
        return 'appleMusic';
      case MusicService.tidal:
        return 'tidal';
      case MusicService.youtubeMusic:
        return 'youtubeMusic';
      case MusicService.deezer:
        return 'deezer';
      case MusicService.amazonMusic:
        return 'amazonMusic';
    }
  }

  static MusicContentType _mapContentType(String rawType) {
    final normalized = rawType.toLowerCase();
    if (normalized.contains('album')) return MusicContentType.album;
    if (normalized.contains('artist')) return MusicContentType.artist;
    if (normalized.contains('playlist')) return MusicContentType.playlist;
    if (normalized.contains('song') || normalized.contains('track')) {
      return MusicContentType.track;
    }
    return MusicContentType.unknown;
  }

  static String? _extractArtistName(Map<String, dynamic> entity) {
    final artists = entity['artists'];
    if (artists is List && artists.isNotEmpty) {
      final first = artists.first;
      if (first is Map && first['name'] is String) {
        return first['name'] as String;
      }
      if (first is String) {
        return first;
      }
    }
    return null;
  }
}

class PlatformLink {
  final String url;
  final String? entityUniqueId;

  PlatformLink({required this.url, this.entityUniqueId});

  factory PlatformLink.fromJson(Map<String, dynamic> json) {
    return PlatformLink(
      url: json['url'] as String,
      entityUniqueId: json['entityUniqueId'] as String?,
    );
  }
}

/// Repository for UniTune API calls
class UnituneRepository {
  static const String _baseUrl = 'https://api.unitune.art/v1-alpha.1/links';
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(milliseconds: 500);

  // Shared HTTP client - don't close it
  static final http.Client _sharedClient = http.Client();

  final http.Client _client;
  final bool _isSharedClient;

  UnituneRepository({http.Client? client})
    : _client = client ?? _sharedClient,
      _isSharedClient = client == null;

  /// Convert a music URL to get links for all platforms
  /// Returns null if the API call fails or the URL is not recognized
  ///
  /// Implements exponential backoff retry logic:
  /// - Attempt 1: immediate
  /// - Attempt 2: 500ms delay
  /// - Attempt 3: 1000ms delay
  Future<UnituneResponse?> getLinks(String musicUrl) async {
    int attempt = 0;
    Duration delay = _initialDelay;

    while (attempt < _maxRetries) {
      attempt++;

      try {
        final uri = Uri.parse(
          _baseUrl,
        ).replace(queryParameters: {'url': musicUrl});

        developer.log(
          'UniTune API Request',
          name: 'UnituneRepository',
          error: 'Attempt $attempt: $uri',
        );

        final response = await _client
            .get(uri)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                developer.log(
                  'UniTune API request timed out',
                  name: 'UnituneRepository',
                );
                throw TimeoutException(
                  'API request timed out after 10 seconds',
                );
              },
            );

        developer.log(
          'UniTune API Response',
          name: 'UnituneRepository',
          error:
              'Status: ${response.statusCode}, Body length: ${response.body.length}',
        );

        if (response.statusCode == 200) {
          try {
            developer.log('Parsing JSON response', name: 'UnituneRepository');
            final json = jsonDecode(response.body) as Map<String, dynamic>;
            developer.log(
              'JSON parsed successfully',
              name: 'UnituneRepository',
            );
            final result = UnituneResponse.fromJson(json);
            developer.log(
              'UnituneResponse created successfully',
              name: 'UnituneRepository',
            );
            return result;
          } catch (e, stackTrace) {
            developer.log(
              'Error parsing API response',
              name: 'UnituneRepository',
              error: e,
              stackTrace: stackTrace,
            );
            developer.log(
              'Response body',
              name: 'UnituneRepository',
              error: response.body,
            );
            return null;
          }
        } else if (response.statusCode == 404) {
          developer.log(
            'UniTune API endpoint not found (404)',
            name: 'UnituneRepository',
            error: 'URL: $uri\nResponse: ${response.body}',
          );
          return null;
        } else if (response.statusCode == 429) {
          developer.log(
            'UniTune API rate limit exceeded (429)',
            name: 'UnituneRepository',
            error: 'Status: ${response.statusCode}',
          );

          if (attempt < _maxRetries) {
            await Future.delayed(delay);
            delay *= 2;
            continue;
          }
          return null;
        } else if (response.statusCode >= 500) {
          developer.log(
            'UniTune API server error',
            name: 'UnituneRepository',
            error: 'Status: ${response.statusCode}',
          );

          if (attempt < _maxRetries) {
            await Future.delayed(delay);
            delay *= 2;
            continue;
          }
          return null;
        } else {
          developer.log(
            'UniTune API client error',
            name: 'UnituneRepository',
            error: 'Status: ${response.statusCode}\nResponse: ${response.body}',
          );
          return null;
        }
      } catch (e) {
        developer.log(
          'UniTune API request failed',
          name: 'UnituneRepository',
          error: e.toString(),
        );

        if (attempt < _maxRetries) {
          await Future.delayed(delay);
          delay *= 2;
          continue;
        }
        return null;
      }
    }

    return null;
  }

  void dispose() {
    // Only close client if it's not the shared one
    if (!_isSharedClient) {
      _client.close();
    }
  }
}
