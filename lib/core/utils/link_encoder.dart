import 'dart:convert';

/// Encodes music links into UniTune's new Base64 format
///
/// New format: https://unitune.art/s/{base64}
/// Where base64 encodes: platform:type:id
///
/// Example:
/// - spotify:track:3n3Ppam7vgaVa1iaRUc9Lp
/// - Encoded: c3BvdGlmeTp0cmFjazozbjNQcGFtN3ZnYVZhMWlhUlVjOUxw
/// - Final: https://unitune.art/s/c3BvdGlmeTp0cmFjazozbjNQcGFtN3ZnYVZhMWlhUlVjOUxw
class UniTuneLinkEncoder {
  static const String _baseUrl = 'https://unitune.art';

  /// Creates a share link from platform and track ID
  ///
  /// Parameters:
  /// - platform: e.g., 'spotify', 'tidal', 'appleMusic'
  /// - trackId: The track identifier
  /// - type: Content type (default: 'track')
  /// - baseUrl: Base URL for the share link (default: 'https://unitune.art')
  static String createShareLink(
    String platform,
    String trackId, {
    String type = 'track',
    String baseUrl = _baseUrl,
  }) {
    // Format: platform:type:id
    final identifier = '$platform:$type:$trackId';

    // Base64 encode (URL-safe)
    String encoded = base64Url.encode(utf8.encode(identifier));

    // Remove padding
    encoded = encoded.replaceAll('=', '');

    return '$baseUrl/s/$encoded';
  }

  /// Creates a share link from a full music URL
  ///
  /// Extracts platform and track ID from the URL and encodes it.
  /// Throws UnsupportedError if URL cannot be parsed.
  static String createShareLinkFromUrl(
    String musicUrl, {
    String baseUrl = _baseUrl,
  }) {
    print('=== UniTuneLinkEncoder.createShareLinkFromUrl ===');
    print('Input URL: $musicUrl');

    final parsed = _parseMusicUrl(musicUrl);

    if (parsed != null) {
      print(
        '✅ Parsed successfully: ${parsed.platform}:${parsed.type}:${parsed.trackId}',
      );
      final link = createShareLink(
        parsed.platform,
        parsed.trackId,
        type: parsed.type,
        baseUrl: baseUrl,
      );
      print('Generated Base64 link: $link');
      return link;
    }

    // Parse failed - throw error
    print('❌ Parsing failed - URL not supported');
    throw UnsupportedError(
      'Could not parse music URL. Platform might not be supported or URL format is invalid: $musicUrl',
    );
  }

  /// Decodes a UniTune share link path to extract the music URL
  ///
  /// Supports Base64 encoded format (platform:type:id)
  ///
  /// Returns the decoded music URL or null if decoding fails
  static String? decodeShareLinkPath(String encodedPath) {
    try {
      // Add padding if needed
      String padded = encodedPath;
      while (padded.length % 4 != 0) {
        padded += '=';
      }

      final decoded = utf8.decode(base64Url.decode(padded));

      // Check if it's in platform:type:id format
      if (decoded.contains(':') && !decoded.startsWith('http')) {
        // It's the new format - reconstruct the URL
        final parts = decoded.split(':');
        if (parts.length >= 3) {
          final platform = parts[0];
          final type = parts[1];
          final id = parts.sublist(2).join(':'); // Handle IDs with colons

          return _reconstructMusicUrl(platform, type, id);
        }
      }

      // Invalid format
      return null;
    } catch (e) {
      print('❌ Failed to decode share link: $e');
      return null;
    }
  }

  /// Reconstructs a music URL from platform, type, and ID
  static String? _reconstructMusicUrl(String platform, String type, String id) {
    switch (platform.toLowerCase()) {
      case 'spotify':
        return 'https://open.spotify.com/$type/$id';
      case 'applemusic':
        // Apple Music URLs are complex, return a search URL
        return 'https://music.apple.com/us/song/$id';
      case 'tidal':
        return 'https://tidal.com/browse/$type/$id';
      case 'youtubemusic':
        return 'https://music.youtube.com/watch?v=$id';
      case 'deezer':
        return 'https://www.deezer.com/$type/$id';
      case 'amazonmusic':
        return 'https://music.amazon.com/tracks/$id';
      default:
        return null;
    }
  }

  /// Parses a music URL to extract platform, type, and ID
  static _MusicUrlParts? _parseMusicUrl(String url) {
    print('  Parsing URL: $url');
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      final path = uri.path;
      print('  Host: $host, Path: $path');

      // Spotify: https://open.spotify.com/track/3n3Ppam7vgaVa1iaRUc9Lp
      if (host.contains('spotify.com')) {
        final match = RegExp(r'/(\w+)/([a-zA-Z0-9]+)').firstMatch(path);
        if (match != null) {
          return _MusicUrlParts(
            platform: 'spotify',
            type: match.group(1)!,
            trackId: match.group(2)!,
          );
        }
      }

      // Apple Music: https://music.apple.com/us/album/song-name/1234567890?i=987654321
      if (host.contains('music.apple.com')) {
        final trackId = uri.queryParameters['i'];
        if (trackId != null) {
          return _MusicUrlParts(
            platform: 'appleMusic',
            type: 'song',
            trackId: trackId,
          );
        }
      }

      // Tidal: https://tidal.com/browse/track/258735410
      // or: https://listen.tidal.com/track/258735410
      // or: https://tidal.com/track/258735410/u (from share intent)
      if (host.contains('tidal.com')) {
        print('  Detected Tidal URL');
        // Try to match: /track/123 or /browse/track/123 or /track/123/u
        final match = RegExp(r'/(?:browse/)?(\w+)/(\d+)').firstMatch(path);
        if (match != null) {
          print(
            '  ✅ Tidal match: type=${match.group(1)}, id=${match.group(2)}',
          );
          return _MusicUrlParts(
            platform: 'tidal',
            type: match.group(1)!,
            trackId: match.group(2)!,
          );
        } else {
          print('  ❌ Tidal regex did not match');
        }
      }

      // YouTube Music: https://music.youtube.com/watch?v=dQw4w9WgXcQ
      if (host.contains('music.youtube.com')) {
        final videoId = uri.queryParameters['v'];
        if (videoId != null) {
          return _MusicUrlParts(
            platform: 'youtubeMusic',
            type: 'video',
            trackId: videoId,
          );
        }
      }

      // Deezer: https://www.deezer.com/track/123456789
      if (host.contains('deezer.com')) {
        final match = RegExp(r'/(\w+)/(\d+)').firstMatch(path);
        if (match != null) {
          return _MusicUrlParts(
            platform: 'deezer',
            type: match.group(1)!,
            trackId: match.group(2)!,
          );
        }
      }

      // Amazon Music: https://music.amazon.com/albums/B08X6JQF7V?trackAsin=B08X6K1234
      if (host.contains('music.amazon.com')) {
        final trackAsin = uri.queryParameters['trackAsin'];
        if (trackAsin != null) {
          return _MusicUrlParts(
            platform: 'amazonMusic',
            type: 'track',
            trackId: trackAsin,
          );
        }
      }

      return null;
    } catch (e) {
      print('  ❌ Exception while parsing: $e');
      return null;
    }
  }
}

/// Internal class to hold parsed music URL parts
class _MusicUrlParts {
  final String platform;
  final String type;
  final String trackId;

  _MusicUrlParts({
    required this.platform,
    required this.type,
    required this.trackId,
  });
}
