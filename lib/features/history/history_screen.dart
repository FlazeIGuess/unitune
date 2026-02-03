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
import '../../core/utils/link_encoder.dart';
import '../../data/models/history_entry.dart';
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
      final songInfo = '${entry.title} by ${entry.artist}';
      final message = '$songInfo\n$shareLink';
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
        await Share.share(message, subject: 'Check out this song on UniTune');
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
        LiquidGlassLayer(
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
                        emptyTitle: 'No songs shared yet',
                        emptySubtitle: 'Share a song from your music app',
                        onEntryTap: _onEntryTap,
                        onEntryDelete: _onEntryDelete,
                        onRefresh: _refreshHistory,
                      ),
                      _HistoryTab(
                        provider: receivedHistoryProvider,
                        emptyIcon: Icons.download_outlined,
                        emptyTitle: 'No songs received yet',
                        emptySubtitle: 'Open a UniTune link from friends',
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
          'This will permanently delete all shared and received songs from your history.',
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
}

/// Individual tab content showing history entries
class _HistoryTab extends ConsumerWidget {
  final FutureProvider<List<HistoryEntry>> provider;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final Function(HistoryEntry) onEntryTap;
  final Function(HistoryEntry) onEntryDelete;
  final Future<void> Function() onRefresh;

  const _HistoryTab({
    required this.provider,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
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
        if (entries.isEmpty) {
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
            itemCount: entries.length,
            // Consistent spacing between cards (Requirement 10.5)
            separatorBuilder: (_, __) => SizedBox(height: AppTheme.spacing.s),
            itemBuilder: (context, index) {
              final entry = entries[index];
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
