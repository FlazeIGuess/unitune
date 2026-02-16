// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistTrack _$PlaylistTrackFromJson(Map<String, dynamic> json) =>
    PlaylistTrack(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      originalUrl: json['originalUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      convertedLinks: Map<String, String>.from(json['convertedLinks'] as Map),
      addedAt: json['addedAt'] == null
          ? null
          : DateTime.parse(json['addedAt'] as String),
    );

Map<String, dynamic> _$PlaylistTrackToJson(PlaylistTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'originalUrl': instance.originalUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'convertedLinks': instance.convertedLinks,
      'addedAt': instance.addedAt?.toIso8601String(),
    };
