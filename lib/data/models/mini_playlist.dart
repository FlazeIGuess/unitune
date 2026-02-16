import 'package:json_annotation/json_annotation.dart';
import 'playlist_track.dart';

part 'mini_playlist.g.dart';

@JsonSerializable()
class MiniPlaylist {
  final String id;
  final String title;
  final List<PlaylistTrack> tracks;
  final String? description;
  final String? coverImageUrl;
  final DateTime createdAt;
  final DateTime? lastModified;
  final bool isPublic;

  const MiniPlaylist({
    required this.id,
    required this.title,
    required this.tracks,
    this.description,
    this.coverImageUrl,
    required this.createdAt,
    this.lastModified,
    this.isPublic = false,
  });

  factory MiniPlaylist.fromJson(Map<String, dynamic> json) =>
      _$MiniPlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$MiniPlaylistToJson(this);

  bool get isValid => tracks.isNotEmpty;

  String get shareLink => 'https://unitune.art/p/$id';

  Duration? get totalDuration => null;

  List<String> get artists {
    return tracks.map((t) => t.artist).toSet().toList();
  }

  MiniPlaylist copyWith({
    String? id,
    String? title,
    List<PlaylistTrack>? tracks,
    String? description,
    String? coverImageUrl,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isPublic,
  }) {
    return MiniPlaylist(
      id: id ?? this.id,
      title: title ?? this.title,
      tracks: tracks ?? this.tracks,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
