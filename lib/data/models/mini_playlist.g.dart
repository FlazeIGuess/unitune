// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mini_playlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MiniPlaylist _$MiniPlaylistFromJson(Map<String, dynamic> json) => MiniPlaylist(
  id: json['id'] as String,
  title: json['title'] as String,
  tracks: (json['tracks'] as List<dynamic>)
      .map((e) => PlaylistTrack.fromJson(e as Map<String, dynamic>))
      .toList(),
  description: json['description'] as String?,
  coverImageUrl: json['coverImageUrl'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  lastModified: json['lastModified'] == null
      ? null
      : DateTime.parse(json['lastModified'] as String),
  isPublic: json['isPublic'] as bool? ?? false,
  creatorNickname: json['creatorNickname'] as String?,
);

Map<String, dynamic> _$MiniPlaylistToJson(MiniPlaylist instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'tracks': instance.tracks,
      'description': instance.description,
      'coverImageUrl': instance.coverImageUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastModified': instance.lastModified?.toIso8601String(),
      'isPublic': instance.isPublic,
      'creatorNickname': instance.creatorNickname,
    };
