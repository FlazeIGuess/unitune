import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/services.dart';
import '../../../data/models/mini_playlist.dart';
import '../../../data/repositories/playlist_remote_repository.dart';
import '../../../data/repositories/playlist_repository.dart';

class PlaylistShareService {
  const PlaylistShareService();

  Future<String?> resolveShareLink(WidgetRef ref, MiniPlaylist playlist) async {
    debugPrint('PlaylistShareService.resolve start id=${playlist.id}');
    final localRepo = ref.read(playlistRepositoryProvider);
    final remoteRepo = ref.read(playlistRemoteRepositoryProvider);
    final existing = await localRepo.getRemotePlaylistId(playlist.id);
    if (existing != null && existing.isNotEmpty) {
      debugPrint(
        'PlaylistShareService.resolve cached id=${playlist.id} remoteId=$existing',
      );
      return '${ApiConstants.unituneLinkBase}/p/$existing';
    }

    final result = await remoteRepo.create(playlist);
    if (result == null) {
      debugPrint('PlaylistShareService.resolve failed id=${playlist.id}');
      return null;
    }
    await localRepo.saveRemotePlaylistMapping(
      playlist.id,
      result.id,
      result.deleteToken,
    );
    debugPrint(
      'PlaylistShareService.resolve created id=${playlist.id} remoteId=${result.id}',
    );
    return '${ApiConstants.unituneLinkBase}/p/${result.id}';
  }
}

final playlistShareServiceProvider = Provider<PlaylistShareService>((ref) {
  return const PlaylistShareService();
});
