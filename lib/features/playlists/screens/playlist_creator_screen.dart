import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/optimized_liquid_glass.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/glass_input_field.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../../core/widgets/liquid_glass_blend_group.dart';
import '../../../core/security/url_validator.dart';
import '../../../data/models/history_entry.dart';
import '../../../data/models/playlist_track.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../data/repositories/playlist_remote_repository.dart';
import '../../../data/repositories/unitune_repository.dart';
import '../../settings/preferences_manager.dart';
import '../../../core/constants/services.dart';
import '../state/playlist_creation_state.dart';
import '../widgets/track_selector_card.dart';
import '../widgets/playlist_preview_card.dart';

class PlaylistCreatorScreen extends ConsumerStatefulWidget {
  const PlaylistCreatorScreen({super.key});

  @override
  ConsumerState<PlaylistCreatorScreen> createState() =>
      _PlaylistCreatorScreenState();
}

class _PlaylistCreatorScreenState extends ConsumerState<PlaylistCreatorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final UnituneRepository _unituneRepo = UnituneRepository();
  final List<PlaylistTrack> _tracks = [];
  late final StateController<bool> _creationActiveController;
  bool _isCreating = false;
  bool _isAddingTrack = false;
  String? _addError;
  bool _showShareTip = true;
  int _addMethodIndex = 0;
  bool _includeNickname = true; // Default: include nickname

  @override
  void initState() {
    super.initState();
    debugPrint('PlaylistCreator.init');
    _creationActiveController = ref.read(
      playlistCreationActiveProvider.notifier,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _creationActiveController.state = true;
      }
    });
    _showShareTip = !ref
        .read(preferencesManagerProvider)
        .isPlaylistShareTipDismissed;
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    debugPrint('PlaylistCreator.dispose');
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _searchController.dispose();
    _unituneRepo.dispose();
    Future.microtask(() {
      _creationActiveController.state = false;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(playlistIncomingLinkProvider, (previous, next) {
      if (next == null) return;
      Future.microtask(() => _handleSharedLink(next));
      ref.read(playlistIncomingLinkProvider.notifier).state = null;
    });

    final canCreate = _tracks.isNotEmpty && _titleController.text.isNotEmpty;
    final titleLength = _titleController.text.length;
    final descriptionLength = _descriptionController.text.length;
    final bottomPadding = AppTheme.spacing.xl * 5;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                    child: Stack(
                      children: [
                        ListView(
                          padding: EdgeInsets.fromLTRB(
                            AppTheme.spacing.l,
                            AppTheme.spacing.m,
                            AppTheme.spacing.l,
                            bottomPadding,
                          ),
                          children: [
                            if (_showShareTip) ...[
                              _buildShareTipBanner(),
                              SizedBox(height: AppTheme.spacing.l),
                            ],
                            _buildInputSection(titleLength, descriptionLength),
                            SizedBox(height: AppTheme.spacing.xl),
                            _buildAddMethodSection(),
                            SizedBox(height: AppTheme.spacing.xl),
                            _buildTracksPreviewSection(),
                            SizedBox(height: AppTheme.spacing.xl),
                          ],
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildStickyCreateBar(canCreate),
                        ),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacing.l,
        AppTheme.spacing.l,
        AppTheme.spacing.l,
        AppTheme.spacing.m,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            color: AppTheme.colors.textSecondary,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: AppTheme.spacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Playlist',
                  style: AppTheme.typography.titleLarge.copyWith(
                    color: AppTheme.colors.textPrimary,
                    fontFamily: 'ZalandoSansExpanded',
                  ),
                ),
                SizedBox(height: AppTheme.spacing.xs),
                Text(
                  'Collect songs and share a mini-playlist',
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

  Widget _buildInputSection(int titleLength, int descriptionLength) {
    final titleError = titleLength > 50;
    final descriptionError = descriptionLength > 200;
    final userNickname = ref.watch(preferencesManagerProvider).userNickname;
    final hasNickname = userNickname != null && userNickname.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Playlist Details',
          style: AppTheme.typography.labelLarge.copyWith(
            color: AppTheme.colors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: AppTheme.spacing.m),
        LiquidGlassCard(
          padding: EdgeInsets.all(AppTheme.spacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Give your playlist a clear name',
                style: AppTheme.typography.bodyMedium.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
              ),
              SizedBox(height: AppTheme.spacing.m),
              GlassInputField(
                controller: _titleController,
                placeholder: 'Playlist name',
                onChanged: (_) => setState(() {}),
                borderColor: titleError
                    ? AppTheme.colors.accentError.withValues(alpha: 0.5)
                    : null,
              ),
              SizedBox(height: AppTheme.spacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (titleError)
                    Text(
                      'Title too long',
                      style: AppTheme.typography.labelMedium.copyWith(
                        color: AppTheme.colors.accentError,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Text(
                    '$titleLength/50',
                    style: AppTheme.typography.labelMedium.copyWith(
                      color: titleError
                          ? AppTheme.colors.accentError
                          : AppTheme.colors.textMuted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing.m),
              GlassInputField(
                controller: _descriptionController,
                placeholder: 'Description (optional)',
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                borderColor: descriptionError
                    ? AppTheme.colors.accentError.withValues(alpha: 0.5)
                    : null,
              ),
              SizedBox(height: AppTheme.spacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$descriptionLength/200',
                  style: AppTheme.typography.labelMedium.copyWith(
                    color: descriptionError
                        ? AppTheme.colors.accentError
                        : AppTheme.colors.textMuted,
                  ),
                ),
              ),
              if (hasNickname) ...[
                SizedBox(height: AppTheme.spacing.l),
                Divider(color: AppTheme.colors.glassBorder, height: 1),
                SizedBox(height: AppTheme.spacing.l),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 20,
                      color: AppTheme.colors.textSecondary,
                    ),
                    SizedBox(width: AppTheme.spacing.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show nickname',
                            style: AppTheme.typography.bodyLarge.copyWith(
                              color: AppTheme.colors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Share as "$userNickname"',
                            style: AppTheme.typography.bodyMedium.copyWith(
                              color: AppTheme.colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _includeNickname,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _includeNickname = value);
                      },
                      activeColor: context.primaryColor,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareTipBanner() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: LiquidGlassCard(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.l,
          vertical: AppTheme.spacing.m,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.colors.textSecondary,
                  size: 20,
                ),
                SizedBox(width: AppTheme.spacing.s),
                Expanded(
                  child: Text(
                    'Tip: You can share songs directly from Spotify, Apple Music, and more.',
                    style: AppTheme.typography.bodyMedium.copyWith(
                      color: AppTheme.colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing.s),
            Align(
              alignment: Alignment.centerRight,
              child: InlineGlassButton(
                label: 'Don\'t show again',
                onPressed: _dismissShareTip,
                icon: Icons.visibility_off_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add songs',
          style: AppTheme.typography.labelLarge.copyWith(
            color: AppTheme.colors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: AppTheme.spacing.m),
        LiquidGlassCard(
          padding: EdgeInsets.all(AppTheme.spacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMethodTabs(),
              SizedBox(height: AppTheme.spacing.l),
              AnimatedSwitcher(
                duration: AppTheme.animation.durationNormal,
                switchInCurve: AppTheme.animation.curveStandard,
                switchOutCurve: AppTheme.animation.curveStandard,
                child: _buildAddMethodContent(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTabs() {
    return LiquidGlassCard(
      padding: EdgeInsets.all(AppTheme.spacing.xs),
      elevated: false,
      child: Row(
        children: [
          _buildMethodTabItem(index: 0, label: 'Link', icon: Icons.link),
          SizedBox(width: AppTheme.spacing.xs),
          _buildMethodTabItem(index: 1, label: 'Share', icon: Icons.share),
          SizedBox(width: AppTheme.spacing.xs),
          _buildMethodTabItem(index: 2, label: 'Search', icon: Icons.search),
        ],
      ),
    );
  }

  Widget _buildMethodTabItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _addMethodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleAddMethodChange(index),
        child: AnimatedContainer(
          duration: AppTheme.animation.durationFast,
          curve: AppTheme.animation.curveStandard,
          padding: EdgeInsets.symmetric(
            vertical: AppTheme.spacing.m,
            horizontal: AppTheme.spacing.s,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primaryColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radii.medium),
            border: Border.all(
              color: isSelected
                  ? context.primaryColor.withValues(alpha: 0.35)
                  : AppTheme.colors.glassBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? context.primaryColor
                    : AppTheme.colors.textSecondary,
              ),
              SizedBox(width: AppTheme.spacing.xs),
              Text(
                label,
                style: AppTheme.typography.labelMedium.copyWith(
                  color: isSelected
                      ? context.primaryColor
                      : AppTheme.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMethodContent() {
    if (_addMethodIndex == 0) {
      return _buildLinkMethod(key: const ValueKey('link'));
    }
    if (_addMethodIndex == 1) {
      return _buildShareMethod(key: const ValueKey('share'));
    }
    return _buildSearchMethod(key: const ValueKey('search'));
  }

  Widget _buildLinkMethod({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassInputField(
          controller: _linkController,
          placeholder: 'https://open.spotify.com/track/...',
          keyboardType: TextInputType.url,
        ),
        if (_addError != null) ...[
          SizedBox(height: AppTheme.spacing.s),
          Text(
            _addError!,
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.accentError,
            ),
          ),
        ],
        SizedBox(height: AppTheme.spacing.m),
        PrimaryButton(
          label: 'Add link',
          onPressed: _isAddingTrack ? () {} : _addTrackFromLinkInput,
          isLoading: _isAddingTrack,
          icon: Icons.add,
        ),
      ],
    );
  }

  Widget _buildShareMethod({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Open your streaming app and share a song to UniTune.',
          style: AppTheme.typography.bodyMedium.copyWith(
            color: AppTheme.colors.textPrimary,
          ),
        ),
        SizedBox(height: AppTheme.spacing.m),
        PrimaryButton(
          label: 'I am ready to share',
          onPressed: _openPreferredMusicService,
          icon: Icons.share,
        ),
        if (_isAddingTrack) ...[
          SizedBox(height: AppTheme.spacing.m),
          Text(
            'Waiting for shared song...',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchMethod({Key? key}) {
    final query = _searchController.text.trim().toLowerCase();
    final historyAsync = ref.watch(allHistoryProvider);

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassInputField(
          controller: _searchController,
          placeholder: 'Search recent songs',
        ),
        SizedBox(height: AppTheme.spacing.m),
        historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text(
            'Unable to load recent songs',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
            ),
          ),
          data: (entries) {
            final filtered = entries
                .where((entry) {
                  if (query.isEmpty) return true;
                  final text = '${entry.title} ${entry.artist}'.toLowerCase();
                  return text.contains(query);
                })
                .take(3)
                .toList();

            if (filtered.isEmpty) {
              return Text(
                'No matches found',
                style: AppTheme.typography.bodyMedium.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
              );
            }

            return Column(children: filtered.map(_buildHistoryRow).toList());
          },
        ),
      ],
    );
  }

  Future<void> _openPreferredMusicService() async {
    HapticFeedback.lightImpact();
    final preferred = ref.read(preferredMusicServiceProvider);
    if (preferred == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Select a preferred music service first'),
          backgroundColor: AppTheme.colors.backgroundCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final target = _musicServiceUri(preferred);
    if (await canLaunchUrl(target)) {
      await launchUrl(target, mode: LaunchMode.externalApplication);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Share a song to UniTune from your music app'),
          backgroundColor: AppTheme.colors.backgroundCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not open ${preferred.name}'),
        backgroundColor: AppTheme.colors.accentError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Uri _musicServiceUri(MusicService preferred) {
    switch (preferred) {
      case MusicService.spotify:
        return Uri.parse('spotify://');
      case MusicService.appleMusic:
        return Uri.parse('music://');
      case MusicService.tidal:
        return Uri.parse('tidal://');
      case MusicService.youtubeMusic:
        return Uri.parse('youtubemusic://');
      case MusicService.deezer:
        return Uri.parse('deezer://');
      case MusicService.amazonMusic:
        return Uri.parse('amznmp3://');
    }
  }

  Widget _buildHistoryRow(HistoryEntry entry) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing.s),
      child: LiquidGlassCard(
        padding: EdgeInsets.all(AppTheme.spacing.m),
        child: Row(
          children: [
            if (entry.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  entry.thumbnailUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.colors.backgroundCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note, size: 20),
              ),
            SizedBox(width: AppTheme.spacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: AppTheme.typography.bodyLarge.copyWith(
                      color: AppTheme.colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    entry.artist,
                    style: AppTheme.typography.bodyMedium.copyWith(
                      color: AppTheme.colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _addTrackFromHistory(entry),
              icon: Icon(Icons.add_circle_outline, color: context.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: AppTheme.typography.labelLarge.copyWith(
            color: AppTheme.colors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: AppTheme.spacing.m),
        PlaylistPreviewCard(
          title: _titleController.text.isEmpty
              ? 'Untitled Playlist'
              : _titleController.text,
          tracks: _tracks,
        ),
      ],
    );
  }

  Widget _buildCreateButton(bool canCreate) {
    return PrimaryButton(
      label: 'Create Playlist',
      onPressed: canCreate
          ? () {
              debugPrint('PlaylistCreator.createButton pressed');
              HapticFeedback.mediumImpact();
              _createPlaylist();
            }
          : () {
              debugPrint('PlaylistCreator.createButton blocked');
              HapticFeedback.lightImpact();
            },
      isLoading: _isCreating,
      icon: Icons.check,
    );
  }

  Widget _buildTracksSection() {
    final tracksValid = _tracks.isNotEmpty;

    return LiquidGlassCard(
      padding: EdgeInsets.all(AppTheme.spacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tracks',
                style: AppTheme.typography.labelLarge.copyWith(
                  color: AppTheme.colors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing.m,
                  vertical: AppTheme.spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: tracksValid
                      ? AppTheme.colors.accentSuccess.withValues(alpha: 0.15)
                      : AppTheme.colors.accentWarning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radii.pill),
                  border: Border.all(
                    color: tracksValid
                        ? AppTheme.colors.accentSuccess.withValues(alpha: 0.3)
                        : AppTheme.colors.accentWarning.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tracksValid ? Icons.check_circle : Icons.info,
                      size: 14,
                      color: tracksValid
                          ? AppTheme.colors.accentSuccess
                          : AppTheme.colors.accentWarning,
                    ),
                    SizedBox(width: AppTheme.spacing.xs),
                    Text(
                      '${_tracks.length}${tracksValid ? '' : ' (min. 1)'}',
                      style: AppTheme.typography.labelMedium.copyWith(
                        color: tracksValid
                            ? AppTheme.colors.accentSuccess
                            : AppTheme.colors.accentWarning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.m),
          if (_tracks.isEmpty) _buildEmptyState() else _buildTrackList(),
        ],
      ),
    );
  }

  Widget _buildTrackList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tracks.length,
      onReorder: _reorderTracks,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return TrackSelectorCard(
          key: ValueKey(track.id),
          track: track,
          index: index,
          onRemove: () => _removeTrack(index),
        );
      },
    );
  }

  void _handleAddMethodChange(int index) {
    if (_addMethodIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _addMethodIndex = index;
      _addError = null;
    });
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.95, end: 1.05),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.queue_music,
                  size: 40,
                  color: context.primaryColor,
                ),
              ),
            );
          },
          onEnd: () {
            if (mounted && _tracks.isEmpty) {
              setState(() {});
            }
          },
        ),
        SizedBox(height: AppTheme.spacing.l),
        Text(
          'No tracks yet',
          style: AppTheme.typography.titleMedium.copyWith(
            color: AppTheme.colors.textPrimary,
            fontFamily: 'ZalandoSansExpanded',
          ),
        ),
        SizedBox(height: AppTheme.spacing.s),
        Text(
          'Add tracks to create your mini-playlist',
          style: AppTheme.typography.bodyMedium.copyWith(
            color: AppTheme.colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppTheme.spacing.l),
        Row(
          children: [
            Expanded(
              child: LiquidGlassCard(
                padding: EdgeInsets.symmetric(
                  vertical: AppTheme.spacing.m,
                  horizontal: AppTheme.spacing.m,
                ),
                onTap: () => _handleAddMethodChange(0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link, size: 18, color: context.primaryColor),
                    SizedBox(width: AppTheme.spacing.s),
                    Text(
                      'Paste link',
                      style: AppTheme.typography.labelMedium.copyWith(
                        color: context.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppTheme.spacing.m),
            Expanded(
              child: LiquidGlassCard(
                padding: EdgeInsets.symmetric(
                  vertical: AppTheme.spacing.m,
                  horizontal: AppTheme.spacing.m,
                ),
                onTap: () => _handleAddMethodChange(2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 18, color: context.primaryColor),
                    SizedBox(width: AppTheme.spacing.s),
                    Text(
                      'Search',
                      style: AppTheme.typography.labelMedium.copyWith(
                        color: context.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTracksPreviewSection() {
    final children = <Widget>[
      _buildTracksSection(),
      if (_tracks.isNotEmpty) _buildPreviewSection(),
    ];
    return LiquidGlassBlendContainer(
      blend: 22,
      spacing: AppTheme.spacing.l,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildStickyCreateBar(bool canCreate) {
    final statusText = canCreate
        ? '${_tracks.length} tracks ready'
        : 'Add a title and at least 1 track';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacing.l,
        AppTheme.spacing.s,
        AppTheme.spacing.l,
        AppTheme.spacing.l,
      ),
      child: LiquidGlassCard(
        padding: EdgeInsets.all(AppTheme.spacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusText,
              style: AppTheme.typography.bodyMedium.copyWith(
                color: canCreate
                    ? AppTheme.colors.textPrimary
                    : AppTheme.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacing.m),
            _buildCreateButton(canCreate),
          ],
        ),
      ),
    );
  }

  Future<void> _dismissShareTip() async {
    await ref
        .read(preferencesManagerProvider)
        .setPlaylistShareTipDismissed(true);
    if (mounted) {
      setState(() => _showShareTip = false);
    }
  }

  void _handleSharedLink(String link) {
    setState(() {
      _addMethodIndex = 1;
    });
    _addTrackFromUrl(link);
  }

  void _addTrackFromLinkInput() {
    final url = _linkController.text.trim();
    if (url.isEmpty) return;
    _addTrackFromUrl(url);
  }

  Future<void> _addTrackFromUrl(String url) async {
    if (_isAddingTrack) return;
    setState(() {
      _isAddingTrack = true;
      _addError = null;
    });

    try {
      final validation = UrlValidator.validateAndSanitize(url);
      if (!validation.isValid) {
        setState(() {
          _addError = validation.errorMessage ?? 'Invalid link';
          _isAddingTrack = false;
        });
        return;
      }

      if (_tracks.any((t) => t.originalUrl == validation.sanitizedUrl)) {
        setState(() => _isAddingTrack = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Song already added'),
            backgroundColor: AppTheme.colors.backgroundCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final response = await _unituneRepo.getLinks(validation.sanitizedUrl);
      if (response == null) {
        setState(() {
          _addError = 'Could not fetch track information';
          _isAddingTrack = false;
        });
        return;
      }

      final convertedLinks = <String, String>{};
      response.linksByPlatform.forEach((key, value) {
        convertedLinks[key] = value.url;
      });

      final track = PlaylistTrack(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: response.title ?? 'Unknown Track',
        artist: response.artistName ?? 'Unknown Artist',
        originalUrl: validation.sanitizedUrl,
        thumbnailUrl: response.thumbnailUrl,
        convertedLinks: convertedLinks,
        addedAt: DateTime.now(),
      );

      _addTrackToList(track);
      _linkController.clear();
    } catch (e) {
      setState(() {
        _addError = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isAddingTrack = false);
      }
    }
  }

  void _addTrackFromHistory(HistoryEntry entry) {
    final track = PlaylistTrack(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: entry.title,
      artist: entry.artist,
      originalUrl: entry.originalUrl,
      thumbnailUrl: entry.thumbnailUrl,
      convertedLinks: const {},
      addedAt: DateTime.now(),
    );
    _addTrackToList(track);
  }

  void _addTrackToList(PlaylistTrack track) {
    final duplicate = _tracks.any((t) => t.originalUrl == track.originalUrl);
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Song already added'),
          backgroundColor: AppTheme.colors.backgroundCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _tracks.add(track);
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _removeTrack(int index) {
    debugPrint('PlaylistCreator.removeTrack index=$index');
    setState(() {
      _tracks.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  void _reorderTracks(int oldIndex, int newIndex) {
    debugPrint(
      'PlaylistCreator.reorderTracks oldIndex=$oldIndex newIndex=$newIndex',
    );
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final track = _tracks.removeAt(oldIndex);
      _tracks.insert(newIndex, track);
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _createPlaylist() async {
    if (_tracks.isEmpty || _titleController.text.isEmpty) return;

    debugPrint(
      'PlaylistCreator.create start title="${_titleController.text}" tracks=${_tracks.length} includeNickname=$_includeNickname',
    );
    setState(() => _isCreating = true);

    try {
      final repo = ref.read(playlistRepositoryProvider);
      final remoteRepo = ref.read(playlistRemoteRepositoryProvider);
      final playlist = await repo.createPlaylist(
        title: _titleController.text,
        tracks: _tracks,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        includeNickname: _includeNickname,
      );
      debugPrint('PlaylistCreator.create local id=${playlist.id}');

      final remote = await remoteRepo.create(playlist);
      if (remote != null) {
        await repo.saveRemotePlaylistMapping(
          playlist.id,
          remote.id,
          remote.deleteToken,
        );
        debugPrint('PlaylistCreator.create remote id=${remote.id}');
      } else {
        debugPrint('PlaylistCreator.create remote failed');
      }

      if (mounted) {
        ref.invalidate(playlistsProvider);
        debugPrint('PlaylistCreator.create invalidate playlistsProvider');
        context.go('/playlists/${playlist.id}/created');
      }
    } catch (e) {
      debugPrint('PlaylistCreator.create error $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating playlist: $e'),
            backgroundColor: AppTheme.colors.accentError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
