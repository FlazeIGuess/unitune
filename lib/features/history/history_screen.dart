import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/dynamic_theme.dart';
import '../../core/widgets/history_item_card.dart';
import '../../core/widgets/unitune_header.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/history_action_sheet.dart';
import '../../core/widgets/liquid_glass_dialog.dart';
import '../../core/widgets/native_ad_card.dart';
import '../../core/widgets/optimized_liquid_glass.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/utils/link_encoder.dart';
import '../../data/models/history_entry.dart';
import '../../data/models/music_content_type.dart';
import '../../data/repositories/unitune_repository.dart';
import '../settings/preferences_manager.dart';
import '../../core/constants/services.dart';

/// History Screen with Shared/Received tabs
///
/// Features:
/// - Liquid Glass TabBar with sliding indicator
/// - Separate lists for shared and received songs
/// - Empty state with helpful message in English
/// - Pull to refresh
/// - Smooth page transitions with consistent spacing
/// - Uses HistoryCard components for display
///
/// Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 17.1
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();
  MusicService? _serviceFilter;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleTabChange(int index) {
    setState(() => _selectedTabIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handlePageChange(int index) {
    setState(() => _selectedTabIndex = index);
  }

  void _handleServiceFilter(MusicService? service) {
    setState(() {
      _serviceFilter = service;
    });
  }

  Future<void> _refreshHistory() async {
    // Invalidate the provider to force refresh
    ref.invalidate(sharedHistoryProvider);
    ref.invalidate(receivedHistoryProvider);
  }

  Future<void> _onEntryTap(HistoryEntry entry) async {
    // Show action sheet with Share and Open options
    await HistoryActionSheet.show(
      context: context,
      title: entry.title,
      artist: entry.artist,
      contentType: entry.contentType,
      thumbnailUrl: entry.thumbnailUrl,
      onShare: () => _shareEntry(entry),
      onOpen: () => _openEntry(entry),
    );
  }

  /// Share the entry again - re-convert the link and share via messenger
  Future<void> _shareEntry(HistoryEntry entry) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Converting link...'),
          backgroundColor: AppTheme.colors.backgroundCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Re-convert the link using UniTune API
      final unituneRepo = UnituneRepository();
      final response = await unituneRepo.getLinks(entry.originalUrl);
      unituneRepo.dispose();

      if (response == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to convert link'),
            backgroundColor: AppTheme.colors.accentError,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Generate UniTune share link
      final shareLink = UniTuneLinkEncoder.createShareLinkFromUrl(
        entry.originalUrl,
      );

      // Get preferred messenger
      final messenger = ref.read(preferredMessengerProvider);

      // Prepare message
      final message = _buildShareMessage(entry, shareLink);
      final encodedMessage = Uri.encodeComponent(message);

      // Launch messenger
      String? launchUrlString;
      switch (messenger) {
        case MessengerService.whatsapp:
          launchUrlString = 'whatsapp://send?text=$encodedMessage';
          break;
        case MessengerService.telegram:
          launchUrlString = 'tg://msg?text=$encodedMessage';
          break;
        case MessengerService.signal:
          launchUrlString = 'sgnl://send?text=$encodedMessage';
          break;
        case MessengerService.sms:
          launchUrlString = 'sms:?body=$encodedMessage';
          break;
        case MessengerService.systemShare:
        case null:
          // Use system share
          launchUrlString = null;
          break;
      }

      if (launchUrlString != null) {
        final uri = Uri.parse(launchUrlString);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        } else {
          // App not installed - fallback to system share
          debugPrint('=== Messenger app not installed, using system share ===');
        }
      }

      // Fallback: use system share
      if (!mounted) return;
      try {
        await Share.share(
          message,
          subject: 'Check out this ${_contentLabel(entry)} on UniTune',
        );
      } catch (e) {
        debugPrint('Error showing system share: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to share'),
            backgroundColor: AppTheme.colors.accentError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sharing entry: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to share'),
          backgroundColor: AppTheme.colors.accentError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _displayTitle(HistoryEntry entry) {
    switch (entry.contentType) {
      case MusicContentType.artist:
        return entry.title.isNotEmpty ? entry.title : entry.artist;
      case MusicContentType.album:
      case MusicContentType.track:
      case MusicContentType.playlist:
      case MusicContentType.unknown:
        return entry.title;
    }
  }

  String _displaySubtitle(HistoryEntry entry) {
    switch (entry.contentType) {
      case MusicContentType.artist:
        return 'Artist';
      case MusicContentType.album:
      case MusicContentType.track:
      case MusicContentType.playlist:
      case MusicContentType.unknown:
        return entry.artist;
    }
  }

  String _contentLabel(HistoryEntry entry) {
    switch (entry.contentType) {
      case MusicContentType.album:
        return 'album';
      case MusicContentType.artist:
        return 'artist';
      case MusicContentType.track:
        return 'song';
      case MusicContentType.playlist:
        return 'playlist';
      case MusicContentType.unknown:
        return 'music';
    }
  }

  String _buildShareMessage(HistoryEntry entry, String shareLink) {
    final title = _displayTitle(entry);
    final subtitle = _displaySubtitle(entry);
    final headline = entry.contentType == MusicContentType.artist
        ? 'Artist: $title'
        : subtitle.isNotEmpty
        ? '$title by $subtitle'
        : title;
    return '$headline\n$shareLink';
  }

  /// Open the entry in the preferred music app
  Future<void> _openEntry(HistoryEntry entry) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Opening...'),
          backgroundColor: AppTheme.colors.backgroundCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );

      // Get the links from UniTune API
      final unituneRepo = UnituneRepository();
      final response = await unituneRepo.getLinks(entry.originalUrl);
      unituneRepo.dispose();

      if (response == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open link'),
            backgroundColor: AppTheme.colors.accentError,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Get preferred music service
      final musicService = ref.read(preferredMusicServiceProvider);

      if (musicService == null) {
        // No preference set, open original link
        final uri = Uri.parse(entry.originalUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }

      // Get the URL for the preferred service
      final targetUrl = response.getUrlForService(musicService);

      if (targetUrl != null) {
        final uri = Uri.parse(targetUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not available on ${musicService.name}'),
            backgroundColor: AppTheme.colors.accentError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening entry: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to open'),
          backgroundColor: AppTheme.colors.accentError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onEntryDelete(HistoryEntry entry) async {
    await ref.read(historyRepositoryProvider).delete(entry.id);
    await _refreshHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${entry.title} deleted'),
          backgroundColor: AppTheme.colors.backgroundCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.small),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
        ),
        // Glass layer for all glass elements
        OptimizedLiquidGlassLayer(
          settings: AppTheme.liquidGlassDefault,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                _buildHeader(context),
                const SizedBox(height: 16),
                // Tab Bar
                _buildTabBar(),
                const SizedBox(height: 16),
                _buildFilterBar(),
                const SizedBox(height: 16),
                // Tab Content with PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _handlePageChange,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _HistoryTab(
                        provider: sharedHistoryProvider,
                        emptyIcon: Icons.share_outlined,
                        emptyTitle: 'No shares yet',
                        emptySubtitle: 'Share music from your app',
                        serviceFilter: _serviceFilter,
                        resolveService: _resolveServiceFromUrl,
                        onEntryTap: _onEntryTap,
                        onEntryDelete: _onEntryDelete,
                        onRefresh: _refreshHistory,
                      ),
                      _HistoryTab(
                        provider: receivedHistoryProvider,
                        emptyIcon: Icons.download_outlined,
                        emptyTitle: 'No items received yet',
                        emptySubtitle: 'Open a UniTune link from friends',
                        serviceFilter: _serviceFilter,
                        resolveService: _resolveServiceFromUrl,
                        onEntryTap: _onEntryTap,
                        onEntryDelete: _onEntryDelete,
                        onRefresh: _refreshHistory,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final sharedHistory = ref.watch(sharedHistoryProvider);
    final receivedHistory = ref.watch(receivedHistoryProvider);

    // Check if there's any history to clear
    final hasHistory =
        sharedHistory.maybeWhen(
          data: (entries) => entries.isNotEmpty,
          orElse: () => false,
        ) ||
        receivedHistory.maybeWhen(
          data: (entries) => entries.isNotEmpty,
          orElse: () => false,
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacing.l,
        AppTheme.spacing.l,
        AppTheme.spacing.l,
        AppTheme.spacing.s,
      ),
      child: Row(
        children: [
          Expanded(child: UniTuneHeader()),
          if (hasHistory)
            DangerButton(
              label: 'Clear All',
              icon: Icons.delete_outline,
              onPressed: () => _showClearAllDialog(context),
            ),
        ],
      ),
    );
  }

  Future<void> _showClearAllDialog(BuildContext context) async {
    final confirmed = await LiquidGlassDialog.show(
      context: context,
      title: 'Clear all history?',
      content:
          'This will permanently delete all shared and received items from your history.',
      confirmText: 'Clear All',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(historyRepositoryProvider).clearAll();
      await _refreshHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('History cleared'),
            backgroundColor: AppTheme.colors.backgroundCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.small),
            ),
          ),
        );
      }
    }
  }

  Widget _buildTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.m),
      child: _HistoryTabBar(
        currentIndex: _selectedTabIndex,
        onTabChanged: _handleTabChange,
      ),
    );
  }

  Widget _buildFilterBar() {
    final chips = <Widget>[
      _buildFilterChip(
        label: 'All',
        isSelected: _serviceFilter == null,
        onTap: () => _handleServiceFilter(null),
      ),
    ];
    for (final service in MusicService.values) {
      chips.add(
        _buildFilterChip(
          label: service.name,
          isSelected: _serviceFilter == service,
          onTap: () => _handleServiceFilter(service),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.m),
      child: Row(
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            chips[i],
            if (i != chips.length - 1) SizedBox(width: AppTheme.spacing.s),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: context.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: context.primaryColor,
      labelStyle: TextStyle(
        color: isSelected
            ? context.primaryColor
            : AppTheme.colors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      backgroundColor: AppTheme.colors.backgroundCard,
      side: BorderSide(
        color: isSelected
            ? context.primaryColor.withValues(alpha: 0.4)
            : AppTheme.colors.glassBorder,
      ),
    );
  }

  MusicService? _resolveServiceFromUrl(HistoryEntry entry) {
    final lower = entry.originalUrl.toLowerCase();
    if (lower.contains('open.spotify.com') || lower.contains('spotify.link')) {
      return MusicService.spotify;
    }
    if (lower.contains('music.apple.com')) {
      return MusicService.appleMusic;
    }
    if (lower.contains('tidal.com') || lower.contains('listen.tidal.com')) {
      return MusicService.tidal;
    }
    if (lower.contains('music.youtube.com') || lower.contains('youtu.be')) {
      return MusicService.youtubeMusic;
    }
    if (lower.contains('deezer.page.link') || lower.contains('deezer.com')) {
      return MusicService.deezer;
    }
    if (lower.contains('music.amazon') || lower.contains('amazon.com/music')) {
      return MusicService.amazonMusic;
    }
    return null;
  }
}

/// Individual tab content showing history entries
class _HistoryTab extends ConsumerWidget {
  final FutureProvider<List<HistoryEntry>> provider;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final MusicService? serviceFilter;
  final MusicService? Function(HistoryEntry entry) resolveService;
  final Function(HistoryEntry) onEntryTap;
  final Function(HistoryEntry) onEntryDelete;
  final Future<void> Function() onRefresh;

  const _HistoryTab({
    required this.provider,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.serviceFilter,
    required this.resolveService,
    required this.onEntryTap,
    required this.onEntryDelete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(provider);

    return historyAsync.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: context.primaryColor)),
      error: (error, stack) => Center(
        child: Text(
          'Error loading history',
          style: TextStyle(color: AppTheme.colors.textSecondary),
        ),
      ),
      data: (entries) {
        final filteredEntries = serviceFilter == null
            ? entries
            : entries.where((e) => resolveService(e) == serviceFilter).toList();

        if (filteredEntries.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          color: context.primaryColor,
          backgroundColor: AppTheme.colors.backgroundCard,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              AppTheme.spacing.m,
              AppTheme.spacing.xs,
              AppTheme.spacing.m,
              120, // Bottom padding for floating navigation bar
            ),
            itemCount:
                filteredEntries.length + (filteredEntries.length ~/ 5) + 1,
            // Consistent spacing between cards (Requirement 10.5)
            separatorBuilder: (_, __) => SizedBox(height: AppTheme.spacing.s),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSummaryCard(context, filteredEntries);
              }

              final entryPosition = index - 1;
              if (entryPosition > 0 && (entryPosition + 1) % 6 == 0) {
                return const NativeAdCard();
              }

              // Calculate actual entry index (accounting for ads)
              final adCount = (entryPosition + 1) ~/ 6;
              final entryIndex = entryPosition - adCount;

              if (entryIndex >= filteredEntries.length) {
                return const SizedBox.shrink();
              }

              final entry = filteredEntries[entryIndex];
              return HistoryCard(
                historyEntry: entry,
                onTap: () => onEntryTap(entry),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radii.xLarge),
              ),
              child: Icon(
                emptyIcon,
                size: 40,
                color: context.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: AppTheme.spacing.l),
            Text(
              emptyTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.colors.textSecondary,
                fontFamily: 'ZalandoSansExpanded',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacing.xs),
            Text(
              emptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.colors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<HistoryEntry> entries) {
    final topService = _getTopService(entries);
    final total = entries.length;
    final topLabel = topService?.name;
    final topCount = topService == null
        ? null
        : entries.where((e) => resolveService(e) == topService).length;

    return LiquidGlassCard(
      child: Row(
        children: [
          Icon(Icons.analytics_outlined, color: context.primaryColor, size: 24),
          SizedBox(width: AppTheme.spacing.m),
          Expanded(
            child: Text(
              topLabel == null
                  ? 'Total: $total'
                  : 'Total: $total • Top service: $topLabel ($topCount)',
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  MusicService? _getTopService(List<HistoryEntry> entries) {
    if (entries.isEmpty) return null;
    final counts = <MusicService, int>{};
    for (final entry in entries) {
      final service = resolveService(entry);
      if (service == null) continue;
      counts[service] = (counts[service] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}

/// Custom Tab Bar matching bottom navigation style
class _HistoryTabBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const _HistoryTabBar({
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  State<_HistoryTabBar> createState() => _HistoryTabBarState();
}

class _HistoryTabBarState extends State<_HistoryTabBar>
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
  void didUpdateWidget(_HistoryTabBar oldWidget) {
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
            _buildTab(index: 0, icon: Icons.arrow_outward, label: 'Shared'),
            _buildTab(index: 1, icon: Icons.arrow_downward, label: 'Received'),
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
