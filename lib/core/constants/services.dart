/// Supported music streaming services with their URL schemes and package names
enum MusicService {
  spotify(
    name: 'Spotify',
    icon: '🎵',
    packageAndroid: 'com.spotify.music',
    urlSchemeIos: 'spotify',
    color: 0xFF1DB954,
  ),
  appleMusic(
    name: 'Apple Music',
    icon: '🎵',
    packageAndroid: 'com.apple.android.music',
    urlSchemeIos: 'music',
    color: 0xFFFA243C,
  ),
  tidal(
    name: 'TIDAL',
    icon: '🎵',
    packageAndroid: 'com.aspiro.tidal',
    urlSchemeIos: 'tidal',
    color: 0xFF000000,
  ),
  youtubeMusic(
    name: 'YouTube Music',
    icon: '🎵',
    packageAndroid: 'com.google.android.apps.youtube.music',
    urlSchemeIos: 'youtubemusic',
    color: 0xFFFF0000,
  ),
  deezer(
    name: 'Deezer',
    icon: '🎵',
    packageAndroid: 'deezer.android.app',
    urlSchemeIos: 'deezer',
    color: 0xFFFF0090,
  ),
  amazonMusic(
    name: 'Amazon Music',
    icon: '🎵',
    packageAndroid: 'com.amazon.mp3',
    urlSchemeIos: 'amznmp3',
    color: 0xFF00A8E1,
  );

  const MusicService({
    required this.name,
    required this.icon,
    required this.packageAndroid,
    required this.urlSchemeIos,
    required this.color,
  });

  final String name;
  final String icon;
  final String packageAndroid;
  final String urlSchemeIos;
  final int color;
}

/// Supported messenger apps for the "bridge" functionality
enum MessengerService {
  whatsapp(
    name: 'WhatsApp',
    icon: '💬',
    packageAndroid: 'com.whatsapp',
    urlScheme: 'whatsapp://send?text=',
    color: 0xFF25D366,
  ),
  telegram(
    name: 'Telegram',
    icon: '✈️',
    packageAndroid: 'org.telegram.messenger',
    urlScheme: 'tg://msg?text=',
    color: 0xFF0088CC,
  ),
  signal(
    name: 'Signal',
    icon: '🔒',
    packageAndroid: 'org.thoughtcrime.securesms',
    urlScheme: 'sgnl://send?text=',
    color: 0xFF3A76F0,
  ),
  sms(
    name: 'SMS / iMessage',
    icon: '💬',
    packageAndroid: 'com.android.mms',
    urlScheme: 'sms:?body=',
    color: 0xFF34C759,
  ),
  systemShare(
    name: 'System Share',
    icon: '📤',
    packageAndroid: '',
    urlScheme: '',
    color: 0xFF757575,
  );

  const MessengerService({
    required this.name,
    required this.icon,
    required this.packageAndroid,
    required this.urlScheme,
    required this.color,
  });

  final String name;
  final String icon;
  final String packageAndroid;
  final String urlScheme;
  final int color;
}

/// API Endpoints
class ApiConstants {
  ApiConstants._();

  /// UniTune API endpoint - converts music links between platforms
  static const String unituneApiBaseUrl =
      'https://api.unitune.art/v1-alpha.1/links';

  static const String unitunePlaylistBaseUrl =
      'https://api.unitune.art/v1/playlists';

  /// UniTune link base
  static const String unituneLinkBase = 'https://unitune.art';
}
