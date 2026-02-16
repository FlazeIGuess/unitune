import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unitune/data/models/playlist_track.dart';
import 'package:unitune/data/repositories/playlist_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  PlaylistTrack buildTrack(String id) {
    return PlaylistTrack(
      id: id,
      title: 'Track $id',
      artist: 'Artist $id',
      originalUrl: 'https://example.com/$id',
      thumbnailUrl: null,
      convertedLinks: const {},
      addedAt: DateTime.now(),
    );
  }

  test('createPlaylist stores playlist and can be read', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = PlaylistRepository(prefs);

    final playlist = await repo.createPlaylist(
      title: 'My Playlist',
      tracks: [buildTrack('1')],
      description: 'Desc',
    );

    final all = await repo.getAll();
    final byId = await repo.getById(playlist.id);

    expect(all.length, 1);
    expect(byId, isNotNull);
    expect(byId!.title, 'My Playlist');
  });

  test('received playlists are stored separately from shared history', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = PlaylistRepository(prefs);

    final playlist = await repo.createPlaylist(
      title: 'Imported',
      tracks: [buildTrack('2')],
    );
    await repo.saveReceivedPlaylist(playlist);
    await repo.saveSharedPlaylist(playlist);

    final received = await repo.getReceivedHistory();
    final shared = await repo.getSharedHistory();
    final created = await repo.getAll();

    expect(received.length, 1);
    expect(shared.length, 1);
    expect(created.length, 1);
  });

  test('delete removes playlist from created and received lists', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = PlaylistRepository(prefs);

    final playlist = await repo.createPlaylist(
      title: 'Delete Me',
      tracks: [buildTrack('3')],
    );
    await repo.saveReceivedPlaylist(playlist);

    await repo.delete(playlist.id);

    final created = await repo.getAll();
    final received = await repo.getReceivedHistory();

    expect(created, isEmpty);
    expect(received, isEmpty);
  });
}
