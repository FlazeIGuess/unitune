import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/services.dart';
import '../../data/models/history_entry.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/link_cache_repository.dart';

/// Keys for SharedPreferences storage
class PrefsKeys {
  PrefsKeys._();
  static const String musicService = 'preferred_music_service';
  static const String messenger = 'preferred_messenger';
  static const String onboardingComplete = 'onboarding_complete';
}

/// Manages local preferences (100% local, no cloud sync)
class PreferencesManager {
  final SharedPreferences _prefs;

  PreferencesManager(this._prefs);

  // === MUSIC SERVICE ===
  MusicService? get preferredMusicService {
    final value = _prefs.getString(PrefsKeys.musicService);
    if (value == null) return null;
    return MusicService.values.firstWhere(
      (s) => s.name == value,
      orElse: () => MusicService.spotify,
    );
  }

  Future<void> setPreferredMusicService(MusicService service) async {
    await _prefs.setString(PrefsKeys.musicService, service.name);
  }

  // === MESSENGER ===
  MessengerService? get preferredMessenger {
    final value = _prefs.getString(PrefsKeys.messenger);
    if (value == null) return null;
    return MessengerService.values.firstWhere(
      (s) => s.name == value,
      orElse: () => MessengerService.whatsapp,
    );
  }

  Future<void> setPreferredMessenger(MessengerService messenger) async {
    await _prefs.setString(PrefsKeys.messenger, messenger.name);
  }

  // === ONBOARDING ===
  bool get isOnboardingComplete {
    return _prefs.getBool(PrefsKeys.onboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(PrefsKeys.onboardingComplete, value);
  }

  // === CLEAR ALL (for testing/reset) ===
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

/// Provider for PreferencesManager
final preferencesManagerProvider = Provider<PreferencesManager>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesManager(prefs);
});

/// Provider for preferred music service (reactive)
final preferredMusicServiceProvider = StateProvider<MusicService?>((ref) {
  return ref.watch(preferencesManagerProvider).preferredMusicService;
});

/// Provider for preferred messenger (reactive)
final preferredMessengerProvider = StateProvider<MessengerService?>((ref) {
  return ref.watch(preferencesManagerProvider).preferredMessenger;
});

/// Provider for onboarding status (reactive)
final isOnboardingCompleteProvider = StateProvider<bool>((ref) {
  return ref.watch(preferencesManagerProvider).isOnboardingComplete;
});

// === HISTORY PROVIDERS ===

/// Provider for HistoryRepository
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HistoryRepository(prefs);
});

/// Provider for all history entries
final allHistoryProvider = FutureProvider<List<HistoryEntry>>((ref) {
  return ref.watch(historyRepositoryProvider).getAll();
});

/// Provider for shared history entries
final sharedHistoryProvider = FutureProvider<List<HistoryEntry>>((ref) {
  return ref.watch(historyRepositoryProvider).getShared();
});

/// Provider for received history entries
final receivedHistoryProvider = FutureProvider<List<HistoryEntry>>((ref) {
  return ref.watch(historyRepositoryProvider).getReceived();
});

// === LINK CACHE PROVIDERS ===

/// Provider for LinkCacheRepository
final linkCacheRepositoryProvider = Provider<LinkCacheRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LinkCacheRepository(prefs);
});
