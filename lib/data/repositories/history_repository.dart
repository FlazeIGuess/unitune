import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';

/// Repository for managing song history (shared and received)
class HistoryRepository {
  static const String _storageKey = 'unitune_song_history';
  static const int _maxEntries = 100; // Limit to prevent storage bloat

  final SharedPreferences _prefs;

  HistoryRepository(this._prefs);

  /// Get all history entries, sorted by timestamp (newest first)
  Future<List<HistoryEntry>> getAll() async {
    try {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> list = jsonDecode(jsonString);
      final entries = list
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      // Sort by timestamp, newest first
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      debugPrint('Error loading history: $e');
      return [];
    }
  }

  /// Get history entries filtered by type
  Future<List<HistoryEntry>> getByType(HistoryType type) async {
    final all = await getAll();
    return all.where((e) => e.type == type).toList();
  }

  /// Get shared history entries
  Future<List<HistoryEntry>> getShared() async {
    return getByType(HistoryType.shared);
  }

  /// Get received history entries
  Future<List<HistoryEntry>> getReceived() async {
    return getByType(HistoryType.received);
  }

  /// Add a new history entry
  Future<void> add(HistoryEntry entry) async {
    try {
      final entries = await getAll();

      // Check for duplicate (same originalUrl within last 5 minutes)
      final isDuplicate = entries.any(
        (e) =>
            e.originalUrl == entry.originalUrl &&
            entry.timestamp.difference(e.timestamp).inMinutes.abs() < 5,
      );

      if (isDuplicate) {
        debugPrint('Skipping duplicate history entry');
        return;
      }

      // Add new entry at the beginning
      entries.insert(0, entry);

      // Trim to max entries
      final trimmed = entries.take(_maxEntries).toList();

      // Save
      await _save(trimmed);
      debugPrint('Added history entry: ${entry.title} (${entry.type.name})');
    } catch (e) {
      debugPrint('Error adding history entry: $e');
    }
  }

  /// Delete a history entry by ID
  Future<void> delete(String id) async {
    try {
      final entries = await getAll();
      entries.removeWhere((e) => e.id == id);
      await _save(entries);
    } catch (e) {
      debugPrint('Error deleting history entry: $e');
    }
  }

  /// Clear all history
  Future<void> clearAll() async {
    await _prefs.remove(_storageKey);
  }

  /// Clear history by type
  Future<void> clearByType(HistoryType type) async {
    final entries = await getAll();
    entries.removeWhere((e) => e.type == type);
    await _save(entries);
  }

  /// Get history count
  Future<int> getCount() async {
    final entries = await getAll();
    return entries.length;
  }

  /// Get count by type
  Future<int> getCountByType(HistoryType type) async {
    final entries = await getByType(type);
    return entries.length;
  }

  /// Save entries to storage
  Future<void> _save(List<HistoryEntry> entries) async {
    final jsonString = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _prefs.setString(_storageKey, jsonString);
  }
}
