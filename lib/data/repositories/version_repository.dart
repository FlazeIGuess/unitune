import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/remote_version_info.dart';
import '../../features/settings/preferences_manager.dart'
    show sharedPreferencesProvider;

/// Keys used by VersionRepository in SharedPreferences.
/// Private to this file to avoid collisions.
class _VersionPrefsKeys {
  _VersionPrefsKeys._();

  /// Version string the user last saw the What's New sheet for.
  static const String lastSeenVersion = 'version_last_seen';

  /// Version string the user chose to ignore for the update banner.
  static const String ignoredVersion = 'version_ignored_update';
}

/// Worker endpoint returning version info.
/// No user data is sent — plain GET, no auth, no cookies.
const String _kVersionEndpoint = 'https://unitune.art/api/version';

/// Timeout for the version check network call.
/// Short to avoid blocking app startup.
const Duration _kVersionFetchTimeout = Duration(seconds: 5);

/// VersionRepository — handles remote fetch + local preference storage
/// for update notifications and What's New tracking.
///
/// Privacy: No user data is transmitted. The endpoint is a static JSON
/// document with no query parameters or identifiers.
class VersionRepository {
  final SharedPreferences _prefs;

  VersionRepository(this._prefs);

  // ── Remote ────────────────────────────────────────────────────────────────

  /// Fetches remote version info from the worker.
  /// Returns null on any network or parse error (silent failure — never blocks app).
  Future<RemoteVersionInfo?> fetchRemoteVersion() async {
    try {
      final response = await http
          .get(Uri.parse(_kVersionEndpoint))
          .timeout(_kVersionFetchTimeout);

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return RemoteVersionInfo.fromJson(json);
    } catch (_) {
      // Network unavailable, timeout, or parse error — fail silently.
      return null;
    }
  }

  // ── Local version ─────────────────────────────────────────────────────────

  /// Returns [PackageInfo] for the currently installed app.
  Future<PackageInfo> getLocalPackageInfo() async {
    return PackageInfo.fromPlatform();
  }

  // ── What's New tracking ───────────────────────────────────────────────────

  /// The last version string for which the What's New sheet was shown.
  /// Null means the sheet has never been shown.
  String? get lastSeenVersion =>
      _prefs.getString(_VersionPrefsKeys.lastSeenVersion);

  /// Persist the version the user has just acknowledged.
  Future<void> setLastSeenVersion(String version) async {
    await _prefs.setString(_VersionPrefsKeys.lastSeenVersion, version);
  }

  // ── Update ignore ─────────────────────────────────────────────────────────

  /// The version string the user explicitly ignored in the update banner.
  String? get ignoredVersion =>
      _prefs.getString(_VersionPrefsKeys.ignoredVersion);

  /// Whether the user has ignored [version] in the update banner.
  bool isUpdateIgnored(String version) => ignoredVersion == version;

  /// Persist the version the user wants to ignore.
  Future<void> setIgnoredVersion(String version) async {
    await _prefs.setString(_VersionPrefsKeys.ignoredVersion, version);
  }
}

/// Riverpod provider for [VersionRepository].
final versionRepositoryProvider = Provider<VersionRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return VersionRepository(prefs);
});
