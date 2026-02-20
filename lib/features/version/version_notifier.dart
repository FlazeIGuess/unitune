import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/models/remote_version_info.dart';
import '../../data/repositories/version_repository.dart';

/// Immutable state produced by [VersionNotifier].
class VersionState {
  /// Locally installed version string (e.g. '1.4.5').
  final String localVersion;

  /// Locally installed build number (e.g. 16).
  final int localBuild;

  /// Remote version data. Null when offline or fetch failed.
  final RemoteVersionInfo? remote;

  /// True when the app was just updated and the user has not yet seen
  /// the What's New sheet for the current version.
  final bool showWhatsNew;

  /// True when a newer build is available AND the user has not ignored it.
  final bool showUpdateAvailable;

  const VersionState({
    required this.localVersion,
    required this.localBuild,
    required this.remote,
    required this.showWhatsNew,
    required this.showUpdateAvailable,
  });

  /// Convenience copy with selective overrides.
  VersionState copyWith({bool? showWhatsNew, bool? showUpdateAvailable}) {
    return VersionState(
      localVersion: localVersion,
      localBuild: localBuild,
      remote: remote,
      showWhatsNew: showWhatsNew ?? this.showWhatsNew,
      showUpdateAvailable: showUpdateAvailable ?? this.showUpdateAvailable,
    );
  }
}

/// Manages version checking, What's New display, and update banner state.
///
/// On first build:
///  1. Reads local [PackageInfo].
///  2. Reads [VersionRepository.lastSeenVersion].
///  3. Fetches [RemoteVersionInfo] from the worker (best-effort, silent on failure).
///  4. Computes [VersionState.showWhatsNew] and [VersionState.showUpdateAvailable].
///
/// Privacy: The version check sends no user identifiers. It is a plain GET
/// to a static JSON endpoint.
class VersionNotifier extends AsyncNotifier<VersionState> {
  @override
  Future<VersionState> build() async {
    final repo = ref.read(versionRepositoryProvider);

    // Load local version info from the OS package manager.
    final PackageInfo packageInfo = await repo.getLocalPackageInfo();
    final localVersion = packageInfo.version; // e.g. '1.4.5'
    final localBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

    // Fetch remote info (returns null silently on error).
    final remote = await repo.fetchRemoteVersion();

    // Check if the What's New sheet should be shown:
    // Show it when the installed version differs from the last acknowledged version.
    final lastSeen = repo.lastSeenVersion;
    final showWhatsNew =
        lastSeen != localVersion && (remote?.whatsNew.isNotEmpty ?? false);

    // Check if an update banner should be shown:
    // Show it when the remote build is newer AND not ignored.
    bool showUpdateAvailable = false;
    if (remote != null) {
      final isNewer = remote.latestBuild > localBuild;
      final isIgnored = repo.isUpdateIgnored(remote.latestVersion);
      showUpdateAvailable = isNewer && !isIgnored;
    }

    return VersionState(
      localVersion: localVersion,
      localBuild: localBuild,
      remote: remote,
      showWhatsNew: showWhatsNew,
      showUpdateAvailable: showUpdateAvailable,
    );
  }

  /// Called after the user dismisses the What's New sheet.
  /// Persists the current version so the sheet is not shown again until next update.
  Future<void> dismissWhatsNew() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final repo = ref.read(versionRepositoryProvider);
    await repo.setLastSeenVersion(current.localVersion);

    state = AsyncData(current.copyWith(showWhatsNew: false));
  }

  /// Called when the user ignores the update banner for the current remote version.
  Future<void> ignoreUpdate() async {
    final current = state.valueOrNull;
    if (current == null || current.remote == null) return;

    final repo = ref.read(versionRepositoryProvider);
    await repo.setIgnoredVersion(current.remote!.latestVersion);

    state = AsyncData(current.copyWith(showUpdateAvailable: false));
  }
}

/// Riverpod provider for [VersionNotifier].
final versionNotifierProvider =
    AsyncNotifierProvider<VersionNotifier, VersionState>(VersionNotifier.new);
