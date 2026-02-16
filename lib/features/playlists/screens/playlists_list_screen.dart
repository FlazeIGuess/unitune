import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/optimized_liquid_glass.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/mini_playlist.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../widgets/playlist_preview_card.dart';

class PlaylistsListScreen extends ConsumerStatefulWidget {
  const PlaylistsListScreen({super.key});

  @override
  ConsumerState<PlaylistsListScreen> createState() =>
      _PlaylistsListScreenState();
}

class _PlaylistsListScreenState extends ConsumerState<PlaylistsListScreen> {
  int _selectedTabIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleTabChange(int index) {
    debugPrint('PlaylistsList.tabChange index=$index');
    setState(() => _selectedTabIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handlePageChange(int index) {
    debugPrint('PlaylistsList.pageChange index=$index');
    setState(() => _selectedTabIndex = index);
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
              child: Column(
                children: [
                  _buildHeader(context),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.m,
                    ),
                    child: _PlaylistsTabBar(
                      currentIndex: _selectedTabIndex,
                      onTabChanged: _handleTabChange,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.m),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _handlePageChange,
                      children: [
                        _PlaylistsTab(
                          provider: playlistsProvider,
                          emptyIcon: Icons.queue_music,
                          emptyTitle: 'No playlists yet',
                          emptySubtitle:
                              'Create a playlist and share it with friends',
                          showCreateButton: true,
                          onCreatePlaylist: () => _createPlaylist(context),
                          onOpenPlaylist: (playlist) =>
                              _openPlaylist(context, playlist),
                        ),
                        _PlaylistsTab(
                          provider: receivedPlaylistsProvider,
                          emptyIcon: Icons.download_outlined,
                          emptyTitle: 'No playlists received yet',
                          emptySubtitle:
                              'Open a UniTune playlist link from friends',
                          showCreateButton: false,
                          onCreatePlaylist: () {},
                          onOpenPlaylist: (playlist) =>
                              _openPlaylist(context, playlist),
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
      padding: EdgeInsets.all(AppTheme.spacing.l),
      child: Row(
        children: [
          Text(
            'Mini-Playlists',
            style: AppTheme.typography.titleLarge.copyWith(
              color: AppTheme.colors.textPrimary,
              fontFamily: 'ZalandoSansExpanded',
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.help_outline),
            color: AppTheme.colors.textSecondary,
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showInfoDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _createPlaylist(BuildContext context) {
    debugPrint('PlaylistsList.createPlaylist pressed');
    HapticFeedback.mediumImpact();
    context.push('/playlists/create');
    debugPrint('PlaylistsList.createPlaylist navigation pushed');
  }

  void _openPlaylist(BuildContext context, MiniPlaylist playlist) {
    debugPrint('PlaylistsList.openPlaylist id=${playlist.id}');
    HapticFeedback.lightImpact();
    context.push('/playlists/${playlist.id}');
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.colors.backgroundDeep,
        title: Text(
          'Mini-Playlists',
          style: AppTheme.typography.titleMedium.copyWith(
            color: AppTheme.colors.textPrimary,
            fontFamily: 'ZalandoSansExpanded',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create collections of songs and share them with a single link.',
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.textSecondary,
              ),
            ),
            SizedBox(height: AppTheme.spacing.m),
            _buildInfoItem(Icons.music_note, 'Any number of tracks'),
            _buildInfoItem(Icons.share, 'Share with a single link'),
            _buildInfoItem(Icons.qr_code, 'Generate QR codes'),
          ],
        ),
        actions: [
          InlineGlassButton(
            label: 'Got it',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing.s),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.colors.textMuted),
          SizedBox(width: AppTheme.spacing.m),
          Expanded(
            child: Text(
              text,
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistsTab extends ConsumerWidget {
  final FutureProvider<List<MiniPlaylist>> provider;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final bool showCreateButton;
  final VoidCallback onCreatePlaylist;
  final ValueChanged<MiniPlaylist> onOpenPlaylist;

  const _PlaylistsTab({
    required this.provider,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.showCreateButton,
    required this.onCreatePlaylist,
    required this.onOpenPlaylist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(provider);

    return playlistsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error loading playlists',
          style: AppTheme.typography.bodyLarge.copyWith(
            color: AppTheme.colors.textSecondary,
          ),
        ),
      ),
      data: (playlists) {
        if (playlists.isEmpty) {
          return _PlaylistsEmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
            showCreateButton: showCreateButton,
            onCreatePlaylist: onCreatePlaylist,
          );
        }

        final extraCount = showCreateButton ? 1 : 0;
        return ListView.builder(
          padding: EdgeInsets.all(AppTheme.spacing.l),
          itemCount: playlists.length + extraCount,
          itemBuilder: (context, index) {
            if (showCreateButton && index == playlists.length) {
              return Column(
                children: [
                  SizedBox(height: AppTheme.spacing.l),
                  PrimaryButton(
                    label: 'Create New Playlist',
                    onPressed: onCreatePlaylist,
                    icon: Icons.add,
                  ),
                  SizedBox(height: 100),
                ],
              );
            }

            final playlist = playlists[index];
            return Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacing.l),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onOpenPlaylist(playlist),
                child: PlaylistPreviewCard(
                  title: playlist.title,
                  tracks: playlist.tracks,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PlaylistsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showCreateButton;
  final VoidCallback onCreatePlaylist;

  const _PlaylistsEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.showCreateButton,
    required this.onCreatePlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacing.l),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppTheme.colors.textMuted),
          SizedBox(height: AppTheme.spacing.l),
          Text(
            title,
            style: AppTheme.typography.titleMedium.copyWith(
              color: AppTheme.colors.textPrimary,
              fontFamily: 'ZalandoSansExpanded',
            ),
          ),
          SizedBox(height: AppTheme.spacing.s),
          Text(
            subtitle,
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (showCreateButton) ...[
            SizedBox(height: AppTheme.spacing.xl),
            PrimaryButton(
              label: 'Create Your First Playlist',
              onPressed: onCreatePlaylist,
              icon: Icons.add,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaylistsTabBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const _PlaylistsTabBar({
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  State<_PlaylistsTabBar> createState() => _PlaylistsTabBarState();
}

class _PlaylistsTabBarState extends State<_PlaylistsTabBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_PlaylistsTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index != widget.currentIndex) {
      HapticFeedback.selectionClick();
      widget.onTabChanged(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlass.withOwnLayer(
      settings: const LiquidGlassSettings(
        blur: 12,
        ambientStrength: 0.5,
        glassColor: Color(0x18FFFFFF),
        thickness: 12,
        lightIntensity: 0.5,
        saturation: 1.3,
        refractiveIndex: 1.15,
      ),
      shape: LiquidRoundedSuperellipse(borderRadius: 32),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(6.0),
        child: Row(
          children: [
            _buildTab(index: 0, icon: Icons.create_outlined, label: 'Created'),
            _buildTab(index: 1, icon: Icons.download_outlined, label: 'Got'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = widget.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primaryColor.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected ? context.primaryColor : Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? context.primaryColor : Colors.white70,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
