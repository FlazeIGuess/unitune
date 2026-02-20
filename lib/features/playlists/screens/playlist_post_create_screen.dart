import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/ads/ad_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/optimized_liquid_glass.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/mini_playlist.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../services/playlist_share_service.dart';

class PlaylistPostCreateScreen extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistPostCreateScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistPostCreateScreen> createState() =>
      _PlaylistPostCreateScreenState();
}

class _PlaylistPostCreateScreenState
    extends ConsumerState<PlaylistPostCreateScreen> {
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _loadRewardedAd() {
    if (!AdHelper.adsEnabled) return;
    if (_isAdLoading) return;
    _isAdLoading = true;
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: AdHelper.defaultRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isAdLoading = false;
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  Future<void> _sharePlaylist(
    BuildContext context,
    MiniPlaylist playlist,
  ) async {
    HapticFeedback.mediumImpact();
    final shareService = ref.read(playlistShareServiceProvider);
    final shareLink = await shareService.resolveShareLink(ref, playlist);
    if (shareLink == null) {
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
    await ref.read(playlistRepositoryProvider).saveSharedPlaylist(playlist);
    ref.invalidate(sharedPlaylistsHistoryProvider);
  }

  void _openPlaylist(BuildContext context) {
    HapticFeedback.lightImpact();
    context.go('/playlists/${widget.playlistId}');
  }

  void _supportUniTune(BuildContext context) {
    HapticFeedback.lightImpact();
    if (!AdHelper.adsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Support is currently unavailable'),
          backgroundColor: AppTheme.colors.backgroundCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ad = _rewardedAd;
    if (ad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Support video is not ready yet'),
          backgroundColor: AppTheme.colors.backgroundCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadRewardedAd();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (_, reward) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Thanks for supporting UniTune'),
              backgroundColor: AppTheme.colors.backgroundCard,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
    _rewardedAd = null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MiniPlaylist?>(
      future: ref.read(playlistRepositoryProvider).getById(widget.playlistId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final playlist = snapshot.data;
        if (playlist == null) {
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

        return _buildContent(context, playlist);
      },
    );
  }

  Widget _buildContent(BuildContext context, MiniPlaylist playlist) {
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
                  _buildHeader(context),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(AppTheme.spacing.l),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Playlist ready',
                              style: AppTheme.typography.displayMedium.copyWith(
                                color: AppTheme.colors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: AppTheme.spacing.m),
                            Text(
                              'Share it now or open it later',
                              style: AppTheme.typography.bodyLarge.copyWith(
                                color: AppTheme.colors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: AppTheme.spacing.xl),
                            _buildShareCard(context, playlist),
                            SizedBox(height: AppTheme.spacing.xl),
                            PrimaryButton(
                              label: 'Share Playlist',
                              onPressed: () =>
                                  _sharePlaylist(context, playlist),
                              icon: Icons.share,
                            ),
                            SizedBox(height: AppTheme.spacing.m),
                            PrimaryButton(
                              label: 'Open Playlist',
                              onPressed: () => _openPlaylist(context),
                              icon: Icons.queue_music,
                            ),
                            SizedBox(height: AppTheme.spacing.m),
                            PrimaryButton(
                              label: 'Support UniTune',
                              onPressed: () => _supportUniTune(context),
                              icon: Icons.favorite_border,
                            ),
                            SizedBox(height: AppTheme.spacing.xl),
                          ],
                        ),
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacing.l),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            color: AppTheme.colors.textSecondary,
            onPressed: () => context.go('/home'),
          ),
          SizedBox(width: AppTheme.spacing.m),
          Text(
            'Share Playlist',
            style: AppTheme.typography.titleLarge.copyWith(
              color: AppTheme.colors.textPrimary,
              fontFamily: 'ZalandoSansExpanded',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard(BuildContext context, MiniPlaylist playlist) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.l),
      decoration: BoxDecoration(
        color: AppTheme.colors.glassBase,
        borderRadius: BorderRadius.circular(AppTheme.radii.large),
        border: Border.all(color: AppTheme.colors.glassBorder, width: 1),
      ),
      child: Row(
        children: [
          _buildCoverGrid(context, playlist),
          SizedBox(width: AppTheme.spacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.title,
                  style: AppTheme.typography.titleLarge.copyWith(
                    color: AppTheme.colors.textPrimary,
                    fontFamily: 'ZalandoSansExpanded',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppTheme.spacing.s),
                Text(
                  '${playlist.tracks.length} tracks',
                  style: AppTheme.typography.bodyMedium.copyWith(
                    color: AppTheme.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverGrid(BuildContext context, MiniPlaylist playlist) {
    final coverUrls = <String>[
      if (playlist.coverImageUrl != null) playlist.coverImageUrl!,
      ...playlist.tracks
          .where((t) => t.thumbnailUrl != null)
          .map((t) => t.thumbnailUrl!)
          .take(4),
    ];

    final urls = coverUrls.take(4).toList();

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radii.medium),
        color: context.primaryColor.withValues(alpha: 0.1),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radii.medium),
        child: urls.isEmpty
            ? Icon(Icons.queue_music, size: 36, color: context.primaryColor)
            : urls.length == 1
            ? Image.network(
                urls[0],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.music_note,
                  size: 36,
                  color: context.primaryColor,
                ),
              )
            : GridView.builder(
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
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: context.primaryColor.withValues(alpha: 0.1),
                      ),
                    );
                  }
                  return Container(
                    color: context.primaryColor.withValues(alpha: 0.1),
                  );
                },
              ),
      ),
    );
  }
}
