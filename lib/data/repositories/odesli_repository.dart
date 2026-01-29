import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../../core/constants/services.dart';

/// Odesli (Songlink) API response model
class OdesliResponse {
  final String? entityUniqueId;
  final String? title;
  final String? artistName;
  final String? thumbnailUrl;
  final Map<String, PlatformLink> linksByPlatform;

  OdesliResponse({
    this.entityUniqueId,
    this.title,
    this.artistName,
    this.thumbnailUrl,
    required this.linksByPlatform,
  });

  factory OdesliResponse.fromJson(Map<String, dynamic> json) {
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
    String? thumbnailUrl;
    final entities = json['entitiesByUniqueId'] as Map<String, dynamic>?;
    if (entities != null && entities.isNotEmpty) {
      final firstEntity = entities.values.first as Map<String, dynamic>;
      title = firstEntity['title'] as String?;
      artistName = firstEntity['artistName'] as String?;
      thumbnailUrl = firstEntity['thumbnailUrl'] as String?;
    }

    return OdesliResponse(
      entityUniqueId: json['entityUniqueId'] as String?,
      title: title,
      artistName: artistName,
      thumbnailUrl: thumbnailUrl,
      linksByPlatform: linksMap,
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

/// Repository for Odesli API calls
class OdesliRepository {
  static const String _baseUrl = 'https://api.song.link/v1-alpha.1/links';
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(milliseconds: 500);

  final http.Client _client;

  OdesliRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Convert a music URL to get links for all platforms
  /// Returns null if the API call fails or the URL is not recognized
  ///
  /// Implements exponential backoff retry logic:
  /// - Attempt 1: immediate
  /// - Attempt 2: 500ms delay
  /// - Attempt 3: 1000ms delay
  Future<OdesliResponse?> getLinks(String musicUrl) async {
    int attempt = 0;
    Duration delay = _initialDelay;

    while (attempt < _maxRetries) {
      attempt++;

      try {
        final uri = Uri.parse(
          _baseUrl,
        ).replace(queryParameters: {'url': musicUrl});

        final response = await _client.get(uri);

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          return OdesliResponse.fromJson(json);
        } else if (response.statusCode == 429) {
          // Rate limited - log locally but don't expose to user
          developer.log(
            'Odesli API rate limit exceeded (429)',
            name: 'OdesliRepository',
            error: 'Status: ${response.statusCode}',
          );

          // If not last attempt, retry with backoff
          if (attempt < _maxRetries) {
            await Future.delayed(delay);
            delay *= 2; // Exponential backoff
            continue;
          }
          return null;
        } else if (response.statusCode >= 500) {
          // Server error - log locally and retry
          developer.log(
            'Odesli API server error',
            name: 'OdesliRepository',
            error: 'Status: ${response.statusCode}',
          );

          // If not last attempt, retry with backoff
          if (attempt < _maxRetries) {
            await Future.delayed(delay);
            delay *= 2; // Exponential backoff
            continue;
          }
          return null;
        } else {
          // Client error (4xx) - don't retry, log locally
          developer.log(
            'Odesli API client error',
            name: 'OdesliRepository',
            error: 'Status: ${response.statusCode}',
          );
          return null;
        }
      } catch (e) {
        // Network or parsing error - log locally
        developer.log(
          'Odesli API request failed',
          name: 'OdesliRepository',
          error: e.toString(),
        );

        // If not last attempt, retry with backoff
        if (attempt < _maxRetries) {
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff
          continue;
        }
        return null;
      }
    }

    // All retries exhausted
    return null;
  }

  void dispose() {
    _client.close();
  }
}
