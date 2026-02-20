/// RemoteVersionInfo - Data model for /api/version response
///
/// Privacy: This model contains no user-specific data. It only describes
/// the latest available app version and update URLs.
library;

/// Distribution channel the app was built for.
/// Set at build time via --dart-define=DISTRIBUTION_CHANNEL=playstore|github|appstore.
/// Defaults to 'playstore'.
const String kDistributionChannel = String.fromEnvironment(
  'DISTRIBUTION_CHANNEL',
  defaultValue: 'playstore',
);

/// Maps an icon name string from the API to a Flutter [IconData].
/// Falls back to [Icons.star_outline] for unknown names.
class WhatsNewItem {
  final String icon;
  final String title;
  final String body;

  const WhatsNewItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  factory WhatsNewItem.fromJson(Map<String, dynamic> json) {
    return WhatsNewItem(
      icon: json['icon'] as String? ?? 'star_outline',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

/// Per-distribution-channel update URLs returned by the worker.
class UpdateUrls {
  final String playstore;
  final String github;
  final String appstore;

  const UpdateUrls({
    required this.playstore,
    required this.github,
    required this.appstore,
  });

  factory UpdateUrls.fromJson(Map<String, dynamic> json) {
    return UpdateUrls(
      playstore: json['playstore'] as String? ?? '',
      github: json['github'] as String? ?? '',
      appstore: json['appstore'] as String? ?? '',
    );
  }

  /// Returns the correct update URL for the current distribution channel.
  String get forCurrentChannel {
    switch (kDistributionChannel) {
      case 'github':
        return github;
      case 'appstore':
        return appstore;
      case 'playstore':
      default:
        return playstore;
    }
  }
}

/// Full version payload from the worker /api/version endpoint.
class RemoteVersionInfo {
  final String latestVersion;
  final int latestBuild;
  final bool forceUpdate;
  final int minSupportedBuild;
  final List<WhatsNewItem> whatsNew;
  final UpdateUrls updateUrls;
  final String changelogUrl;

  const RemoteVersionInfo({
    required this.latestVersion,
    required this.latestBuild,
    required this.forceUpdate,
    required this.minSupportedBuild,
    required this.whatsNew,
    required this.updateUrls,
    required this.changelogUrl,
  });

  factory RemoteVersionInfo.fromJson(Map<String, dynamic> json) {
    final rawWhatsNew = json['whats_new'] as List<dynamic>? ?? [];
    final rawUrls = json['update_urls'] as Map<String, dynamic>? ?? {};

    return RemoteVersionInfo(
      latestVersion: json['latest_version'] as String? ?? '0.0.0',
      latestBuild: json['latest_build'] as int? ?? 0,
      forceUpdate: json['force_update'] as bool? ?? false,
      minSupportedBuild: json['min_supported_build'] as int? ?? 0,
      whatsNew: rawWhatsNew
          .map((e) => WhatsNewItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      updateUrls: UpdateUrls.fromJson(rawUrls),
      changelogUrl: json['changelog_url'] as String? ?? '',
    );
  }
}
