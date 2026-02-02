import 'link_encoder.dart';

/// Example usage of UniTuneLinkEncoder
///
/// This file demonstrates how to use the new Base64 link format
void main() {
  // Example 1: Create a share link from platform and track ID
  final spotifyLink = UniTuneLinkEncoder.createShareLink(
    'spotify',
    '3n3Ppam7vgaVa1iaRUc9Lp',
    type: 'track',
  );
  print('Spotify link: $spotifyLink');
  // Output: https://unitune.art/s/c3BvdGlmeTp0cmFjazozbjNQcGFtN3ZnYVZhMWlhUlVjOUxw

  // Example 2: Create a share link from a full music URL
  final tidalUrl = 'https://tidal.com/browse/track/258735410';
  final tidalLink = UniTuneLinkEncoder.createShareLinkFromUrl(tidalUrl);
  print('Tidal link: $tidalLink');
  // Output: https://unitune.art/s/dGlkYWw6dHJhY2s6MjU4NzM1NDEw

  // Example 3: Decode a Base64 share link
  final encodedPath = 'c3BvdGlmeTp0cmFjazozbjNQcGFtN3ZnYVZhMWlhUlVjOUxw';
  final decodedUrl = UniTuneLinkEncoder.decodeShareLinkPath(encodedPath);
  print('Decoded URL: $decodedUrl');
  // Output: https://open.spotify.com/track/3n3Ppam7vgaVa1iaRUc9Lp

  // Example 4: Decode a legacy URL-encoded share link (backward compatible)
  final legacyPath = 'https%3A%2F%2Ftidal.com%2Fbrowse%2Ftrack%2F258735410';
  final legacyDecoded = UniTuneLinkEncoder.decodeShareLinkPath(legacyPath);
  print('Legacy decoded URL: $legacyDecoded');
  // Output: https://tidal.com/browse/track/258735410

  // Example 5: Test various music platforms
  final testUrls = [
    'https://open.spotify.com/track/3n3Ppam7vgaVa1iaRUc9Lp',
    'https://music.apple.com/us/album/song/123?i=456',
    'https://tidal.com/browse/track/258735410',
    'https://music.youtube.com/watch?v=dQw4w9WgXcQ',
    'https://www.deezer.com/track/123456789',
  ];

  print('\n=== Testing multiple platforms ===');
  for (final url in testUrls) {
    final shareLink = UniTuneLinkEncoder.createShareLinkFromUrl(url);
    print('Original: $url');
    print('Share link: $shareLink');
    print('---');
  }
}
