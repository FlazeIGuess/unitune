import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/optimized_liquid_glass.dart';
import '../../../data/models/mini_playlist.dart';
import '../../../data/models/playlist_track.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../data/repositories/playlist_remote_repository.dart';
import '../../main_shell.dart';
import '../../settings/preferences_manager.dart';
import '../services/playlist_share_service.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  bool _syncStarted = false;

  @override
  Widget build(BuildContext context) {
    final createdAsync = ref.watch(playlistsProvider);
    final receivedAsync = ref.watch(receivedPlaylistsProvider);

    if (createdAsync.isLoading || receivedAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (createdAsync.hasError || receivedAsync.hasError) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error loading playlist',
            style: AppTheme.typography.bodyLarge.copyWith(
              color: AppTheme.colors.textSecondary,
            ),
          ),
        ),
      );
    }

    final created = createdAsync.value ?? [];
    final received = receivedAsync.value ?? [];
    MiniPlaylist? playlist;

    for (final item in created) {
      if (item.id == widget.playlistId) {
        playlist = item;
        break;
      }
    }
    if (playlist == null) {
      for (final item in received) {
        if (item.id == widget.playlistId) {
          playlist = item;
          break;
        }
      }
    }

    if (playlist == null) {
      debugPrint(
        'PlaylistDetail.notFound id=${widget.playlistId} created=${created.length} received=${received.length}',
      );
      return Scaffold(
        body: Center(
          child: Text(
            'Playlist not found',
            style: AppTheme.typography.bodyLarge.copyWith(
              color: AppTheme.colors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (!_syncStarted) {
      _syncStarted = true;
      debugPrint('PlaylistDetail.ensureRemote id=${playlist.id}');
      _ensureRemotePlaylist(playlist);
    }

    return _buildContent(context, ref, playlist);
  }

  Future<void> _ensureRemotePlaylist(MiniPlaylist playlist) async {
    final repo = ref.read(playlistRepositoryProvider);
    final existing = await repo.getRemotePlaylistId(playlist.id);
    if (existing != null && existing.isNotEmpty) {
      debugPrint(
        'PlaylistDetail.ensureRemote alreadyMapped id=${playlist.id} remoteId=$existing',
      );
      return;
    }
    final remoteRepo = ref.read(playlistRemoteRepositoryProvider);
    final remote = await remoteRepo.create(playlist);
    if (remote != null) {
      await repo.saveRemotePlaylistMapping(
        playlist.id,
        remote.id,
        remote.deleteToken,
      );
      debugPrint(
        'PlaylistDetail.ensureRemote created id=${playlist.id} remoteId=${remote.id}',
      );
    } else {
      debugPrint('PlaylistDetail.ensureRemote failed id=${playlist.id}');
    }
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    MiniPlaylist playlist,
  ) {
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
              child: Column(
                children: [
                  _buildHeader(context, ref, playlist),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.all(AppTheme.spacing.l),
                          sliver: SliverToBoxAdapter(
                            child: _buildCoverSection(playlist),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: AppTheme.spacing.m),
                        ),
                        SliverToBoxAdapter(
                          child: _buildShareButtons(context, ref, playlist),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: AppTheme.spacing.l),
                        ),
                        SliverToBoxAdapter(child: _buildInfoSection(playlist)),
                        SliverToBoxAdapter(
                          child: SizedBox(height: AppTheme.spacing.l),
                        ),
                        ..._buildTracksSlivers(playlist),
                        SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    MiniPlaylist playlist,
  ) {
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacing.l),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppTheme.colors.textSecondary,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                ref.read(mainShellIndexProvider.notifier).state = 2;
                context.go('/home');
              }
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppTheme.colors.accentError,
            onPressed: () => _deletePlaylist(context, ref, playlist),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverSection(MiniPlaylist playlist) {
    final coverUrls = playlist.tracks
        .where((t) => t.thumbnailUrl != null)
        .take(4)
        .map((t) => t.thumbnailUrl!)
        .toList();

    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radii.large),
          boxShadow: AppTheme.shadowMedium,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radii.large),
          child: coverUrls.isEmpty
              ? Container(
                  color: AppTheme.colors.backgroundCard,
                  child: const Icon(Icons.queue_music, size: 80),
                )
              : coverUrls.length == 1
              ? Image.network(
                  coverUrls[0],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppTheme.colors.backgroundCard,
                    child: const Icon(Icons.music_note, size: 80),
                  ),
                )
              : _buildCoverGrid(coverUrls),
        ),
      ),
    );
  }

  Widget _buildCoverGrid(List<String> urls) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        if (index < urls.length) {
          return Image.network(
            urls[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: AppTheme.colors.backgroundCard),
          );
        }
        return Container(color: AppTheme.colors.backgroundCard);
      },
    );
  }

  Widget _buildInfoSection(MiniPlaylist playlist) {
    return Column(
      children: [
        Text(
          playlist.title,
          style: AppTheme.typography.displayMedium.copyWith(
            color: AppTheme.colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppTheme.spacing.s),
        Text(
          '${playlist.tracks.length} ${playlist.tracks.length == 1 ? 'track' : 'tracks'}',
          style: AppTheme.typography.bodyLarge.copyWith(
            color: AppTheme.colors.textSecondary,
          ),
        ),
        if (playlist.description != null) ...[
          SizedBox(height: AppTheme.spacing.m),
          Text(
            playlist.description!,
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildTracksSlivers(MiniPlaylist playlist) {
    if (playlist.tracks.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.l),
            child: Text(
              'No tracks added yet',
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.l),
          child: Text(
            'Tracks',
            style: AppTheme.typography.titleMedium.copyWith(
              color: AppTheme.colors.textPrimary,
              fontFamily: 'ZalandoSansExpanded',
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacing.m)),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.l),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final track = playlist.tracks[index];
            final isLast = index == playlist.tracks.length - 1;
            return _buildTrackTile(context, track, index, isLast);
          }, childCount: playlist.tracks.length),
        ),
      ),
    ];
  }

  Widget _buildTrackPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.colors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, size: 24),
    );
  }

  Widget _buildTrackTile(
    BuildContext context,
    PlaylistTrack track,
    int index,
    bool isLast,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : AppTheme.spacing.s),
      decoration: BoxDecoration(
        color: AppTheme.colors.glassBase,
        borderRadius: BorderRadius.circular(AppTheme.radii.large),
        border: Border.all(color: AppTheme.colors.glassBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openTrack(context, track),
          borderRadius: BorderRadius.circular(AppTheme.radii.large),
          splashColor: context.primaryColor.withValues(alpha: 0.12),
          highlightColor: context.primaryColor.withValues(alpha: 0.08),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.m),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: AppTheme.typography.bodyMedium.copyWith(
                      color: AppTheme.colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacing.m),
                if (track.thumbnailUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      track.thumbnailUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildTrackPlaceholder(),
                    ),
                  )
                else
                  _buildTrackPlaceholder(),
                SizedBox(width: AppTheme.spacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: AppTheme.typography.bodyLarge.copyWith(
                          color: AppTheme.colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        track.artist,
                        style: AppTheme.typography.bodyMedium.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_arrow,
                  size: 20,
                  color: AppTheme.colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButtons(
    BuildContext context,
    WidgetRef ref,
    MiniPlaylist playlist,
  ) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildShareIconButton(
            icon: Icons.share,
            onTap: () => _sharePlaylist(context, ref, playlist),
          ),
          SizedBox(width: AppTheme.spacing.m),
          _buildShareIconButton(
            icon: Icons.qr_code,
            onTap: () => _generateQRCode(context, playlist),
          ),
        ],
      ),
    );
  }

  Widget _buildShareIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 24, height: 24),
        iconSize: 18,
        color: AppTheme.colors.textSecondary,
        splashRadius: 20,
        icon: Icon(icon),
      ),
    );
  }

  Future<void> _openTrack(BuildContext context, PlaylistTrack track) async {
    HapticFeedback.lightImpact();
    final musicService = ref.read(preferredMusicServiceProvider);
    final targetUrl = _resolveTrackUrl(track, musicService);
    final urlToOpen = targetUrl ?? track.originalUrl;
    debugPrint(
      'PlaylistDetail.openTrack id=${track.id} service=${musicService?.name ?? "none"}',
    );

    if (musicService != null && targetUrl == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Song not available on ${musicService.name}'),
            backgroundColor: AppTheme.colors.backgroundCard,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }

    final uri = Uri.tryParse(urlToOpen);
    if (uri == null) {
      debugPrint('PlaylistDetail.openTrack invalidUrl id=${track.id}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid link'),
            backgroundColor: AppTheme.colors.accentError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final canOpen = await canLaunchUrl(uri);
    if (!canOpen) {
      debugPrint('PlaylistDetail.openTrack cannotLaunch id=${track.id}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open link'),
            backgroundColor: AppTheme.colors.accentError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
    debugPrint('PlaylistDetail.openTrack launched id=${track.id}');
  }

  String? _resolveTrackUrl(PlaylistTrack track, MusicService? service) {
    if (service == null) return null;
    final key = _serviceToPlatformKey(service);
    return track.convertedLinks[key];
  }

  String _serviceToPlatformKey(MusicService service) {
    switch (service) {
      case MusicService.spotify:
        return 'spotify';
      case MusicService.appleMusic:
        return 'appleMusic';
      case MusicService.tidal:
        return 'tidal';
      case MusicService.youtubeMusic:
        return 'youtubeMusic';
      case MusicService.deezer:
        return 'deezer';
      case MusicService.amazonMusic:
        return 'amazonMusic';
    }
  }

  Future<void> _sharePlaylist(
    BuildContext context,
    WidgetRef ref,
    MiniPlaylist playlist,
  ) async {
    HapticFeedback.mediumImpact();
    debugPrint('PlaylistDetail.share start id=${playlist.id}');

    final shareService = ref.read(playlistShareServiceProvider);
    final shareLink = await shareService.resolveShareLink(ref, playlist);
    if (shareLink == null) {
      debugPrint('PlaylistDetail.share failed id=${playlist.id}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create share link'),
            backgroundColor: AppTheme.colors.accentError,
          ),
        );
      }
      return;
    }

    final message =
        '${playlist.title}\n'
        '${playlist.tracks.length} tracks\n'
        '$shareLink';

    await Share.share(message, subject: playlist.title);
    debugPrint('PlaylistDetail.share shared id=${playlist.id}');

    final repo = ref.read(playlistRepositoryProvider);
    await repo.saveSharedPlaylist(playlist);
    ref.invalidate(sharedPlaylistsHistoryProvider);
    debugPrint('PlaylistDetail.share stored history id=${playlist.id}');
  }

  void _generateQRCode(BuildContext context, MiniPlaylist playlist) {
    HapticFeedback.mediumImpact();
    debugPrint('PlaylistDetail.generateQr id=${playlist.id}');
    context.push('/playlists/${playlist.id}/qr');
  }

  Future<void> _deletePlaylist(
    BuildContext context,
    WidgetRef ref,
    MiniPlaylist playlist,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.colors.backgroundDeep,
        title: Text(
          'Delete Playlist',
          style: AppTheme.typography.titleMedium.copyWith(
            color: AppTheme.colors.textPrimary,
            fontFamily: 'ZalandoSansExpanded',
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${playlist.title}"?',
          style: AppTheme.typography.bodyMedium.copyWith(
            color: AppTheme.colors.textSecondary,
          ),
        ),
        actions: [
          InlineGlassButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
            color: AppTheme.colors.textMuted,
          ),
          InlineGlassButton(
            label: 'Delete',
            onPressed: () => Navigator.of(context).pop(true),
            color: AppTheme.colors.accentError,
            icon: Icons.delete_outline,
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      debugPrint('PlaylistDetail.delete confirmed id=${playlist.id}');
      await ref.read(playlistRepositoryProvider).delete(playlist.id);
      ref.invalidate(playlistsProvider);
      ref.invalidate(receivedPlaylistsProvider);
      if (context.mounted) {
        ref.read(mainShellIndexProvider.notifier).state = 2;
        context.go('/home');
      }
    }
  }
}
