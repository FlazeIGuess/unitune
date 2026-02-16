import 'dart:convert';
import 'music_content_type.dart';

/// Type of history entry - shared or received
enum HistoryType {
  /// Song was shared BY the user to someone else
  shared,

  /// Song was received/opened FROM someone else via UniTune link
  received,
}

/// A single history entry representing a shared or received song
class HistoryEntry {
  final String id;
  final String title;
  final String artist;
  final String? thumbnailUrl;
  final String originalUrl;
  final String? uniTuneUrl;
  final HistoryType type;
  final MusicContentType contentType;
  final DateTime timestamp;

  const HistoryEntry({
    required this.id,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    required this.originalUrl,
    this.uniTuneUrl,
    required this.type,
    this.contentType = MusicContentType.track,
    required this.timestamp,
  });

  /// Create from JSON map
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      originalUrl: json['originalUrl'] as String,
      uniTuneUrl: json['uniTuneUrl'] as String?,
      type: HistoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HistoryType.shared,
      ),
      contentType: MusicContentType.values.firstWhere(
        (e) => e.name == json['contentType'],
        orElse: () => MusicContentType.track,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert to JSON map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl,
      'originalUrl': originalUrl,
      'uniTuneUrl': uniTuneUrl,
      'type': type.name,
      'contentType': contentType.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  HistoryEntry copyWith({
    String? id,
    String? title,
    String? artist,
    String? thumbnailUrl,
    String? originalUrl,
    String? uniTuneUrl,
    HistoryType? type,
    MusicContentType? contentType,
    DateTime? timestamp,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      originalUrl: originalUrl ?? this.originalUrl,
      uniTuneUrl: uniTuneUrl ?? this.uniTuneUrl,
      type: type ?? this.type,
      contentType: contentType ?? this.contentType,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'HistoryEntry(id: $id, title: $title, artist: $artist, type: $type, contentType: $contentType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Extension for JSON list conversion
extension HistoryEntryListExtension on List<HistoryEntry> {
  String toJsonString() {
    return jsonEncode(map((e) => e.toJson()).toList());
  }

  static List<HistoryEntry> fromJsonString(String json) {
    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
