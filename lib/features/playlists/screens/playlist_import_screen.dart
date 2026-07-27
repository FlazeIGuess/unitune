import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/optimized_liquid_glass.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/playlist_remote_repository.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../main_shell.dart';

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

    // The whole import runs inside a try/catch: `fetch` performs a bare HTTP
    // call, so a dropped connection or a malformed payload throws. Without
    // this the screen would sit on its spinner forever.
    try {
      debugPrint('PlaylistImport.fetch id=${widget.playlistId}');
      final remote = await remoteRepo.fetch(widget.playlistId);
      if (remote == null) {
        debugPrint('PlaylistImport.fetch failed id=${widget.playlistId}');
        _fail(
          'This playlist could not be found. The link may have expired or '
          'the playlist was deleted by its creator.',
        );
        return;
      }

      debugPrint(
        'PlaylistImport.fetch success title="${remote.title}" tracks=${remote.tracks.length}',
      );

      // Re-opening the same link must not pile up duplicates in "Got".
      // If we already imported this remote id, jump straight to it.
      final existingLocalId = await localRepo.findLocalIdForRemote(remote.id);
      if (existingLocalId != null) {
        debugPrint(
          'PlaylistImport.alreadyImported remoteId=${remote.id} localId=$existingLocalId',
        );
        if (!mounted) return;
        context.pushReplacement('/playlists/$existingLocalId');
        return;
      }

      final playlist = await localRepo.createReceivedPlaylist(
        title: remote.title,
        tracks: remote.tracks,
        description: remote.description,
        creatorNickname: remote.creatorNickname,
      );

      await localRepo.saveRemotePlaylistMapping(playlist.id, remote.id, '');
      await localRepo.saveReceivedPlaylist(playlist);
      debugPrint(
        'PlaylistImport.store localId=${playlist.id} remoteId=${remote.id}',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      ref.invalidate(receivedPlaylistsProvider);
      debugPrint('PlaylistImport.navigate id=${playlist.id}');
      // pushReplacement, not go: keeps whatever was underneath (e.g. the main
      // shell) on the stack so the detail screen still has a place to pop to.
      context.pushReplacement('/playlists/${playlist.id}');
    } catch (e) {
      debugPrint('PlaylistImport.error id=${widget.playlistId} error=$e');
      _fail(
        'Could not load this playlist. Please check your internet connection '
        'and try again.',
      );
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = message;
    });
  }

  void _retry() {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _importPlaylist();
  }

  /// Leaves the import screen. Deep links land here with an empty navigation
  /// stack, so falling back to the Playlists tab is the only way out.
  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    ref.read(mainShellIndexProvider.notifier).state = 2;
    context.go('/home');
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
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing.xl),
                child: Center(
                  child: _isLoading ? _buildLoading() : _buildError(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        SizedBox(height: AppTheme.spacing.l),
        Text(
          'Loading playlist...',
          style: AppTheme.typography.bodyLarge.copyWith(
            color: AppTheme.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_off, size: 56, color: AppTheme.colors.textMuted),
          SizedBox(height: AppTheme.spacing.l),
          Text(
            'Playlist unavailable',
            style: AppTheme.typography.titleMedium.copyWith(
              color: AppTheme.colors.textPrimary,
              fontFamily: 'ZalandoSansExpanded',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spacing.s),
          Text(
            _error ?? 'Something went wrong.',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spacing.xl),
          PrimaryButton(
            label: 'Try Again',
            onPressed: _retry,
            icon: Icons.refresh,
          ),
          SizedBox(height: AppTheme.spacing.m),
          InlineGlassButton(
            label: 'Back to Playlists',
            onPressed: _goBack,
            color: AppTheme.colors.textMuted,
          ),
        ],
      ),
    );
  }
}
