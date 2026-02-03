import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/services.dart';

/// Cache entry for a converted music link
class CachedLink {
  final String originalUrl;
  final String musicService;
  final Map<String, String> convertedLinks;
  final String? title;
  final String? artist;
  final String? thumbnailUrl;
  final DateTime cachedAt;

  CachedLink({
    required this.originalUrl,
    required this.musicService,
    required this.convertedLinks,
    this.title,
    this.artist,
    this.thumbnailUrl,
    required this.cachedAt,
  });

  factory CachedLink.fromJson(Map<String, dynamic> json) {
    return CachedLink(
      originalUrl: json['originalUrl'] as String,
      musicService: json['musicService'] as String,
      convertedLinks: Map<String, String>.from(json['convertedLinks'] as Map),
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalUrl': originalUrl,
      'musicService': musicService,
      'convertedLinks': convertedLinks,
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl,
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  bool isExpired({Duration maxAge = const Duration(days: 7)}) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}

/// Repository for caching converted music links
class LinkCacheRepository {
  static const String _storageKey = 'unitune_link_cache';
  static const int _maxEntries = 50;
  static const Duration _cacheMaxAge = Duration(days: 7);

  final SharedPreferences _prefs;

  LinkCacheRepository(this._prefs);

  /// Get cached link for a given original URL and music service
  Future<CachedLink?> get(
    String originalUrl,
    MusicService? musicService,
  ) async {
    try {
      final cache = await _loadCache();
      final key = _generateKey(originalUrl, musicService);

      final cached = cache[key];
      if (cached == null) return null;

      // Check if expired
      if (cached.isExpired(maxAge: _cacheMaxAge)) {
        debugPrint('Cache expired for: $originalUrl');
        await delete(originalUrl, musicService);
        return null;
      }

      debugPrint(
        'Cache hit for: $originalUrl (${musicService?.name ?? "any"})',
      );
      return cached;
    } catch (e) {
      debugPrint('Error loading cache: $e');
      return null;
    }
  }

  /// Save a converted link to cache
  Future<void> save(CachedLink link) async {
    try {
      final cache = await _loadCache();
      final key = _generateKey(
        link.originalUrl,
        MusicService.values.firstWhere(
          (s) => s.name == link.musicService,
          orElse: () => MusicService.spotify,
        ),
      );

      cache[key] = link;

      // Trim old entries if cache is too large
      if (cache.length > _maxEntries) {
        final sortedEntries = cache.entries.toList()
          ..sort((a, b) => b.value.cachedAt.compareTo(a.value.cachedAt));

        cache.clear();
        cache.addAll(Map.fromEntries(sortedEntries.take(_maxEntries)));
      }

      await _saveCache(cache);
      debugPrint('Cached link for: ${link.originalUrl}');
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  /// Delete a cached link
  Future<void> delete(String originalUrl, MusicService? musicService) async {
    try {
      final cache = await _loadCache();
      final key = _generateKey(originalUrl, musicService);
      cache.remove(key);
      await _saveCache(cache);
    } catch (e) {
      debugPrint('Error deleting from cache: $e');
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    await _prefs.remove(_storageKey);
    debugPrint('Cleared all link cache');
  }

  /// Clear expired entries
  Future<void> clearExpired() async {
    try {
      final cache = await _loadCache();
      cache.removeWhere((key, value) => value.isExpired(maxAge: _cacheMaxAge));
      await _saveCache(cache);
    } catch (e) {
      debugPrint('Error clearing expired cache: $e');
    }
  }

  String _generateKey(String originalUrl, MusicService? musicService) {
    return '${originalUrl}_${musicService?.name ?? "any"}';
  }

  Future<Map<String, CachedLink>> _loadCache() async {
    try {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }

      final Map<String, dynamic> json = jsonDecode(jsonString);
      return json.map(
        (key, value) =>
            MapEntry(key, CachedLink.fromJson(value as Map<String, dynamic>)),
      );
    } catch (e) {
      debugPrint('Error loading cache: $e');
      return {};
    }
  }

  Future<void> _saveCache(Map<String, CachedLink> cache) async {
    final json = cache.map((key, value) => MapEntry(key, value.toJson()));
    final jsonString = jsonEncode(json);
    await _prefs.setString(_storageKey, jsonString);
  }
}
