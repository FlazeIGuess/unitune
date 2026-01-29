import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/color_extractor.dart';

/// State for dynamic app colors
///
/// Holds the current primary color set that adapts based on
/// the last shared song's album artwork.
@immutable
class DynamicColorState {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final bool isDefault;

  const DynamicColorState({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    this.isDefault = true,
  });

  /// Default state with UniTune blue colors
  factory DynamicColorState.defaultColors() {
    return const DynamicColorState(
      primary: ColorExtractor.defaultPrimary,
      primaryLight: ColorExtractor.defaultPrimaryLight,
      primaryDark: ColorExtractor.defaultPrimaryDark,
      isDefault: true,
    );
  }

  /// Create from extracted dominant color
  factory DynamicColorState.fromColor(Color dominantColor) {
    final colorSet = ColorExtractor.generateColorSet(dominantColor);
    return DynamicColorState(
      primary: colorSet.primary,
      primaryLight: colorSet.light,
      primaryDark: colorSet.dark,
      isDefault: false,
    );
  }

  /// Create from JSON (for persistence)
  factory DynamicColorState.fromJson(Map<String, dynamic> json) {
    return DynamicColorState(
      primary: Color(json['primary'] as int),
      primaryLight: Color(json['primaryLight'] as int),
      primaryDark: Color(json['primaryDark'] as int),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'primary': primary.toARGB32(),
      'primaryLight': primaryLight.toARGB32(),
      'primaryDark': primaryDark.toARGB32(),
      'isDefault': isDefault,
    };
  }

  DynamicColorState copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    bool? isDefault,
  }) {
    return DynamicColorState(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DynamicColorState &&
        other.primary == primary &&
        other.primaryLight == primaryLight &&
        other.primaryDark == primaryDark &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return Object.hash(primary, primaryLight, primaryDark, isDefault);
  }
}

/// Storage key for persisting color state
const String _colorStateKey = 'dynamic_color_state';

/// Notifier for managing dynamic color state
class DynamicColorNotifier extends StateNotifier<DynamicColorState> {
  DynamicColorNotifier() : super(DynamicColorState.defaultColors()) {
    _loadPersistedColor();
  }

  /// Load persisted color from SharedPreferences
  Future<void> _loadPersistedColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_colorStateKey);

      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        state = DynamicColorState.fromJson(json);
        debugPrint(
          'DynamicColor: Loaded persisted color ${state.primary.toHexString()}',
        );
      }
    } catch (e) {
      debugPrint('DynamicColor: Error loading persisted color: $e');
    }
  }

  /// Persist current color state to SharedPreferences
  Future<void> _persistColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.toJson());
      await prefs.setString(_colorStateKey, jsonString);
      debugPrint(
        'DynamicColor: Persisted color ${state.primary.toHexString()}',
      );
    } catch (e) {
      debugPrint('DynamicColor: Error persisting color: $e');
    }
  }

  /// Update colors from album artwork URL
  ///
  /// Extracts dominant color from the image and updates state.
  /// Falls back to default colors if extraction fails.
  Future<void> updateFromArtwork(String? artworkUrl) async {
    if (artworkUrl == null || artworkUrl.isEmpty) {
      debugPrint('DynamicColor: No artwork URL provided');
      return;
    }

    debugPrint('DynamicColor: Extracting color from $artworkUrl');

    final extractedColor = await ColorExtractor.extractFromUrl(artworkUrl);

    if (extractedColor != null) {
      state = DynamicColorState.fromColor(extractedColor);
      await _persistColor();
      debugPrint('DynamicColor: Updated to ${state.primary.toHexString()}');
    } else {
      debugPrint('DynamicColor: Extraction failed, keeping current color');
    }
  }

  /// Reset to default UniTune blue colors
  Future<void> resetToDefault() async {
    state = DynamicColorState.defaultColors();
    await _persistColor();
    debugPrint('DynamicColor: Reset to default blue');
  }

  /// Directly set a color (for testing or manual override)
  Future<void> setColor(Color color) async {
    state = DynamicColorState.fromColor(color);
    await _persistColor();
  }
  
  /// Sync colors from the topmost shared history entry
  /// 
  /// Call this on app startup or when history changes
  Future<void> syncFromHistory(List<dynamic> historyEntries) async {
    debugPrint('DynamicColor: syncFromHistory called with ${historyEntries.length} entries');
    
    // Find the first (topmost/newest) shared entry with a thumbnail
    for (final entry in historyEntries) {
      // Check if it's a shared entry with thumbnailUrl
      // Entry could be HistoryEntry or a dynamic map
      String? thumbnailUrl;
      bool isShared = false;
      
      if (entry is Map) {
        thumbnailUrl = entry['thumbnailUrl'] as String?;
        isShared = entry['type'] == 'shared';
      } else {
        // Assume it has these properties (duck typing for HistoryEntry)
        try {
          thumbnailUrl = (entry as dynamic).thumbnailUrl as String?;
          isShared = (entry as dynamic).type.toString().contains('shared');
        } catch (e) {
          debugPrint('DynamicColor: Error reading entry: $e');
          continue;
        }
      }
      
      if (isShared && thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        debugPrint('DynamicColor: Found shared entry with thumbnail: $thumbnailUrl');
        await updateFromArtwork(thumbnailUrl);
        return;
      }
    }
    
    debugPrint('DynamicColor: No shared entry with thumbnail found');
  }
}

/// Provider for dynamic color state
final dynamicColorProvider =
    StateNotifierProvider<DynamicColorNotifier, DynamicColorState>((ref) {
      return DynamicColorNotifier();
    });

