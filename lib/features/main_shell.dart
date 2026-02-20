import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/liquid_glass_bottom_nav.dart';
import '../core/animations/page_transitions.dart';
import 'home/home_screen.dart';
import 'history/history_screen.dart';
import 'playlists/screens/playlists_list_screen.dart';
import 'settings/settings_screen.dart';
import 'version/version_notifier.dart';
import 'version/whats_new_sheet.dart';
import 'version/update_banner.dart';

/// Provider for current navigation index
final mainShellIndexProvider = StateProvider<int>((ref) => 0);

/// Main Shell - Wrapper widget with bottom navigation
///
/// Contains:
/// - HomeScreen (index 0)
/// - HistoryScreen (index 1)
/// - PlaylistsListScreen (index 2)
/// - SettingsScreen (index 3)
/// - LiquidGlassBottomNav for navigation
/// - Smooth page transitions with parallax effect
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _transitionController;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    if (index != ref.read(mainShellIndexProvider)) {
      _previousIndex = ref.read(mainShellIndexProvider);
      ref.read(mainShellIndexProvider.notifier).state = index;
      _transitionController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainShellIndexProvider);

    // Show What's New sheet once after each app update.
    // ref.listen fires whenever the async state transitions and is safe for
    // side effects that show UI (posting frame callbacks to avoid build phase).
    ref.listen<AsyncValue<VersionState>>(versionNotifierProvider, (prev, next) {
      final prevShow = prev?.valueOrNull?.showWhatsNew ?? false;
      final nextShow = next.valueOrNull?.showWhatsNew ?? false;
      if (!prevShow && nextShow) {
        // Defer until after the current frame so build phase is complete.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) WhatsNewSheet.show(context);
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Main content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              // Determine if we're moving forward or backward
              final isForward = currentIndex > _previousIndex;

              // Exiting screen gets parallax effect
              if (child.key != ValueKey(currentIndex)) {
                return LiquidParallaxTransition(
                  animation: animation,
                  child: child,
                );
              }

              // Entering screen gets main transition
              return LiquidPageTransition(
                animation: animation,
                isForward: isForward,
                child: child,
              );
            },
            child: _buildCurrentScreen(currentIndex),
          ),
          // Update banner + bottom navigation stacked together.
          // Placing both in a Column avoids hardcoding the nav bar height.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const UpdateBanner(),
                LiquidGlassBottomNav(
                  currentIndex: currentIndex,
                  onTap: _handleNavigation,
                  items: const [
                    BottomNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: 'Home',
                    ),
                    BottomNavItem(
                      icon: Icons.history_outlined,
                      activeIcon: Icons.history,
                      label: 'History',
                    ),
                    BottomNavItem(
                      icon: Icons.queue_music_outlined,
                      activeIcon: Icons.queue_music,
                      label: 'Playlists',
                    ),
                    BottomNavItem(
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      label: 'Settings',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen(key: ValueKey(0));
      case 1:
        return const HistoryScreen(key: ValueKey(1));
      case 2:
        return const PlaylistsListScreen(key: ValueKey(2));
      case 3:
        return const SettingsScreen(key: ValueKey(3));
      default:
        return const HomeScreen(key: ValueKey(0));
    }
  }
}
