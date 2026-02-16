import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/mini_playlist.dart';
import '../models/playlist_track.dart';
import '../../features/settings/preferences_manager.dart';

const String _playlistsKey = 'mini_playlists';
const String _sharedPlaylistsKey = 'shared_playlists_history';
const String _receivedPlaylistsKey = 'received_playlists_history';
const String _remotePlaylistsKey = 'remote_playlists_map';

class PlaylistRepository {
  final SharedPreferences _prefs;
  final Uuid _uuid = const Uuid();

  PlaylistRepository(this._prefs);

  Future<MiniPlaylist> createPlaylist({
    required String title,
    required List<PlaylistTrack> tracks,
    String? description,
  }) async {
    debugPrint(
      'PlaylistRepository.createPlaylist title="$title" tracks=${tracks.length}',
    );
    final playlist = MiniPlaylist(
      id: _uuid.v4(),
      title: title,
      tracks: tracks,
      description: description,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );

    await savePlaylist(playlist);
    debugPrint('PlaylistRepository.createPlaylist saved id=${playlist.id}');
    return playlist;
  }

  Future<MiniPlaylist> createReceivedPlaylist({
    required String title,
    required List<PlaylistTrack> tracks,
    String? description,
  }) async {
    debugPrint(
      'PlaylistRepository.createReceivedPlaylist title="$title" tracks=${tracks.length}',
    );
    final playlist = MiniPlaylist(
      id: _uuid.v4(),
      title: title,
      tracks: tracks,
      description: description,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );

    await saveReceivedPlaylist(playlist);
    debugPrint(
      'PlaylistRepository.createReceivedPlaylist saved id=${playlist.id}',
    );
    return playlist;
  }

  Future<void> savePlaylist(MiniPlaylist playlist) async {
    debugPrint(
      'PlaylistRepository.savePlaylist id=${playlist.id} tracks=${playlist.tracks.length}',
    );
    final playlists = await getAll();
    final index = playlists.indexWhere((p) => p.id == playlist.id);

    if (index >= 0) {
      playlists[index] = playlist.copyWith(lastModified: DateTime.now());
    } else {
      playlists.add(playlist);
    }

    await _savePlaylists(playlists);
    debugPrint(
      'PlaylistRepository.savePlaylist stored count=${playlists.length}',
    );
  }

  Future<List<MiniPlaylist>> getAll() async {
    final jsonString = _prefs.getString(_playlistsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final playlists = jsonList
          .map((json) => MiniPlaylist.fromJson(json as Map<String, dynamic>))
          .toList();
      debugPrint('PlaylistRepository.getAll count=${playlists.length}');
      return playlists;
    } catch (e) {
      debugPrint('Error loading playlists: $e');
      return [];
    }
  }

  Future<MiniPlaylist?> getById(String id) async {
    debugPrint('PlaylistRepository.getById id=$id');
    final playlists = await getAll();
    try {
      return playlists.firstWhere((p) => p.id == id);
    } catch (e) {
      debugPrint('PlaylistRepository.getById not found id=$id');
      return null;
    }
  }

  Future<void> delete(String id) async {
    debugPrint('PlaylistRepository.delete id=$id');
    final playlists = await getAll();
    playlists.removeWhere((p) => p.id == id);
    await _savePlaylists(playlists);
    final received = await getReceivedHistory();
    received.removeWhere((p) => p.id == id);
    await _saveReceivedHistory(received);
    debugPrint(
      'PlaylistRepository.delete stored playlists=${playlists.length} received=${received.length}',
    );
  }

  Future<void> addTrack(String playlistId, PlaylistTrack track) async {
    debugPrint(
      'PlaylistRepository.addTrack playlistId=$playlistId trackId=${track.id}',
    );
    final playlist = await getById(playlistId);
    if (playlist == null) throw Exception('Playlist not found');

    final updatedPlaylist = playlist.copyWith(
      tracks: [...playlist.tracks, track],
      lastModified: DateTime.now(),
    );

    await savePlaylist(updatedPlaylist);
    debugPrint(
      'PlaylistRepository.addTrack updated playlistId=$playlistId tracks=${updatedPlaylist.tracks.length}',
    );
  }

  Future<void> removeTrack(String playlistId, String trackId) async {
    debugPrint(
      'PlaylistRepository.removeTrack playlistId=$playlistId trackId=$trackId',
    );
    final playlist = await getById(playlistId);
    if (playlist == null) throw Exception('Playlist not found');

    final updatedTracks = playlist.tracks
        .where((t) => t.id != trackId)
        .toList();

    final updatedPlaylist = playlist.copyWith(
      tracks: updatedTracks,
      lastModified: DateTime.now(),
    );

    await savePlaylist(updatedPlaylist);
    debugPrint(
      'PlaylistRepository.removeTrack updated playlistId=$playlistId tracks=${updatedPlaylist.tracks.length}',
    );
  }

  Future<void> reorderTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    debugPrint(
      'PlaylistRepository.reorderTracks playlistId=$playlistId oldIndex=$oldIndex newIndex=$newIndex',
    );
    final playlist = await getById(playlistId);
    if (playlist == null) throw Exception('Playlist not found');

    final tracks = List<PlaylistTrack>.from(playlist.tracks);
    final track = tracks.removeAt(oldIndex);
    tracks.insert(newIndex, track);

    final updatedPlaylist = playlist.copyWith(
      tracks: tracks,
      lastModified: DateTime.now(),
    );

    await savePlaylist(updatedPlaylist);
    debugPrint(
      'PlaylistRepository.reorderTracks updated playlistId=$playlistId',
    );
  }

  Future<void> saveSharedPlaylist(MiniPlaylist playlist) async {
    debugPrint('PlaylistRepository.saveSharedPlaylist id=${playlist.id}');
    final history = await getSharedHistory();
    history.insert(0, playlist);

    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    final jsonString = jsonEncode(history.map((p) => p.toJson()).toList());
    await _prefs.setString(_sharedPlaylistsKey, jsonString);
    debugPrint(
      'PlaylistRepository.saveSharedPlaylist stored count=${history.length}',
    );
  }

  Future<List<MiniPlaylist>> getSharedHistory() async {
    final jsonString = _prefs.getString(_sharedPlaylistsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final playlists = jsonList
          .map((json) => MiniPlaylist.fromJson(json as Map<String, dynamic>))
          .toList();
      debugPrint(
        'PlaylistRepository.getSharedHistory count=${playlists.length}',
      );
      return playlists;
    } catch (e) {
      debugPrint('Error loading shared playlists: $e');
      return [];
    }
  }

  Future<void> saveReceivedPlaylist(MiniPlaylist playlist) async {
    debugPrint('PlaylistRepository.saveReceivedPlaylist id=${playlist.id}');
    final history = await getReceivedHistory();
    history.removeWhere((p) => p.id == playlist.id);
    history.insert(0, playlist);

    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    await _saveReceivedHistory(history);
    debugPrint(
      'PlaylistRepository.saveReceivedPlaylist stored count=${history.length}',
    );
  }

  Future<List<MiniPlaylist>> getReceivedHistory() async {
    final jsonString = _prefs.getString(_receivedPlaylistsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final playlists = jsonList
          .map((json) => MiniPlaylist.fromJson(json as Map<String, dynamic>))
          .toList();
      debugPrint(
        'PlaylistRepository.getReceivedHistory count=${playlists.length}',
      );
      return playlists;
    } catch (e) {
      debugPrint('Error loading received playlists: $e');
      return [];
    }
  }

  Future<void> _savePlaylists(List<MiniPlaylist> playlists) async {
    final jsonString = jsonEncode(playlists.map((p) => p.toJson()).toList());
    await _prefs.setString(_playlistsKey, jsonString);
    debugPrint('PlaylistRepository._savePlaylists stored=${playlists.length}');
  }

  Future<void> _saveReceivedHistory(List<MiniPlaylist> playlists) async {
    final jsonString = jsonEncode(playlists.map((p) => p.toJson()).toList());
    await _prefs.setString(_receivedPlaylistsKey, jsonString);
    debugPrint(
      'PlaylistRepository._saveReceivedHistory stored=${playlists.length}',
    );
  }

  Future<Map<String, dynamic>> _getRemoteMap() async {
    final jsonString = _prefs.getString(_remotePlaylistsKey);
    if (jsonString == null) return {};
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      debugPrint('PlaylistRepository._getRemoteMap size=${map.length}');
      return map;
    } catch (e) {
      debugPrint('Error loading remote playlist map: $e');
      return {};
    }
  }

  Future<String?> getRemotePlaylistId(String localId) async {
    debugPrint('PlaylistRepository.getRemotePlaylistId localId=$localId');
    final map = await _getRemoteMap();
    final entry = map[localId] as Map<String, dynamic>?;
    return entry?['remoteId'] as String?;
  }

  Future<String?> getRemotePlaylistDeleteToken(String localId) async {
    debugPrint(
      'PlaylistRepository.getRemotePlaylistDeleteToken localId=$localId',
    );
    final map = await _getRemoteMap();
    final entry = map[localId] as Map<String, dynamic>?;
    return entry?['deleteToken'] as String?;
  }

  Future<void> saveRemotePlaylistMapping(
    String localId,
    String remoteId,
    String deleteToken,
  ) async {
    debugPrint(
      'PlaylistRepository.saveRemotePlaylistMapping localId=$localId remoteId=$remoteId',
    );
    final map = await _getRemoteMap();
    map[localId] = {
      'remoteId': remoteId,
      'deleteToken': deleteToken,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await _prefs.setString(_remotePlaylistsKey, jsonEncode(map));
    debugPrint('PlaylistRepository.saveRemotePlaylistMapping stored');
  }

  String encodeForSharing(MiniPlaylist playlist) {
    debugPrint('PlaylistRepository.encodeForSharing id=${playlist.id}');
    final json = playlist.toJson();
    final jsonString = jsonEncode(json);
    final bytes = utf8.encode(jsonString);
    return base64Url.encode(bytes);
  }

  MiniPlaylist? decodeSharedPlaylist(String encoded) {
    try {
      final bytes = base64Url.decode(encoded);
      final jsonString = utf8.decode(bytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final playlist = MiniPlaylist.fromJson(json);
      debugPrint('PlaylistRepository.decodeSharedPlaylist id=${playlist.id}');
      return playlist;
    } catch (e) {
      debugPrint('Error decoding playlist: $e');
      return null;
    }
  }
}

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PlaylistRepository(prefs);
});

final playlistsProvider = FutureProvider<List<MiniPlaylist>>((ref) async {
  final repo = ref.watch(playlistRepositoryProvider);
  return repo.getAll();
});

final sharedPlaylistsHistoryProvider = FutureProvider<List<MiniPlaylist>>((
  ref,
) async {
  final repo = ref.watch(playlistRepositoryProvider);
  return repo.getSharedHistory();
});

final receivedPlaylistsProvider = FutureProvider<List<MiniPlaylist>>((
  ref,
) async {
  final repo = ref.watch(playlistRepositoryProvider);
  return repo.getReceivedHistory();
});
