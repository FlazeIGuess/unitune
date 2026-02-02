import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../../core/constants/services.dart';

/// UniTune API response model
class UnituneResponse {
  final String? entityUniqueId;
  final String? title;
  final String? artistName;
  final String? thumbnailUrl;
  final Map<String, PlatformLink> linksByPlatform;

  UnituneResponse({
    this.entityUniqueId,
    this.title,
    this.artistName,
    this.thumbnailUrl,
    required this.linksByPlatform,
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
    String? thumbnailUrl;
    final entities = json['entitiesByUniqueId'] as Map<String, dynamic>?;
    if (entities != null && entities.isNotEmpty) {
      final firstEntity = entities.values.first as Map<String, dynamic>;
      title = firstEntity['title'] as String?;
      artistName = firstEntity['artistName'] as String?;
      thumbnailUrl = firstEntity['thumbnailUrl'] as String?;
    }

    return UnituneResponse(
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

/// Repository for UniTune API calls
class UnituneRepository {
  static const String _baseUrl = 'https://api.unitune.art/v1-alpha.1/links';
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(milliseconds: 500);

  final http.Client _client;

  UnituneRepository({http.Client? client}) : _client = client ?? http.Client();

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

        final response = await _client.get(uri);

        developer.log(
          'UniTune API Response',
          name: 'UnituneRepository',
          error:
              'Status: ${response.statusCode}, Body length: ${response.body.length}',
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          return UnituneResponse.fromJson(json);
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
    _client.close();
  }
}
