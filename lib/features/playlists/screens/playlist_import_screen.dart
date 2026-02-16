import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/optimized_liquid_glass.dart';
import '../../../data/repositories/playlist_remote_repository.dart';
import '../../../data/repositories/playlist_repository.dart';

class PlaylistImportScreen extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistImportScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistImportScreen> createState() =>
      _PlaylistImportScreenState();
}

class _PlaylistImportScreenState extends ConsumerState<PlaylistImportScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('PlaylistImport.init id=${widget.playlistId}');
    _importPlaylist();
  }

  Future<void> _importPlaylist() async {
    final remoteRepo = ref.read(playlistRemoteRepositoryProvider);
    final localRepo = ref.read(playlistRepositoryProvider);

    debugPrint('PlaylistImport.fetch id=${widget.playlistId}');
    final remote = await remoteRepo.fetch(widget.playlistId);
    if (remote == null) {
      debugPrint('PlaylistImport.fetch failed id=${widget.playlistId}');
      setState(() {
        _isLoading = false;
        _error = 'Playlist not found';
      });
      return;
    }

    debugPrint(
      'PlaylistImport.fetch success title="${remote.title}" tracks=${remote.tracks.length}',
    );
    final playlist = await localRepo.createReceivedPlaylist(
      title: remote.title,
      tracks: remote.tracks,
      description: remote.description,
    );

    await localRepo.saveRemotePlaylistMapping(playlist.id, remote.id, '');
    await localRepo.saveReceivedPlaylist(playlist);
    debugPrint(
      'PlaylistImport.store localId=${playlist.id} remoteId=${remote.id}',
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    ref.invalidate(receivedPlaylistsProvider);
    debugPrint('PlaylistImport.navigate id=${playlist.id}');
    context.go('/playlists/${playlist.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          OptimizedLiquidGlassLayer(
            settings: AppTheme.liquidGlassDefault,
            child: SafeArea(
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        _error ?? 'Imported',
                        style: AppTheme.typography.bodyLarge.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
