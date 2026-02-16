import 'package:json_annotation/json_annotation.dart';

part 'playlist_track.g.dart';

@JsonSerializable()
class PlaylistTrack {
  final String id;
  final String title;
  final String artist;
  final String originalUrl;
  final String? thumbnailUrl;
  final Map<String, String> convertedLinks;
  final DateTime? addedAt;

  const PlaylistTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.originalUrl,
    this.thumbnailUrl,
    required this.convertedLinks,
    this.addedAt,
  });

  factory PlaylistTrack.fromJson(Map<String, dynamic> json) =>
      _$PlaylistTrackFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistTrackToJson(this);

  PlaylistTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? originalUrl,
    String? thumbnailUrl,
    Map<String, String>? convertedLinks,
    DateTime? addedAt,
  }) {
    return PlaylistTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      originalUrl: originalUrl ?? this.originalUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      convertedLinks: convertedLinks ?? this.convertedLinks,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
