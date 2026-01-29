import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/dynamic_theme.dart';
import '../../core/widgets/unitune_logo.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/utils/motion_sensitivity.dart';
import '../../core/constants/services.dart';
import '../settings/preferences_manager.dart';
import 'widgets/statistics_card.dart';
import 'services/statistics_service.dart';

/// Home Screen - Simple welcome screen
/// Shows UniTune branding and waits for shared links
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppTheme.animation.durationNormal,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppTheme.animation.curveDecelerate,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = MotionSensitivity.shouldAnimate(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          // Glass layer - static, doesn't scroll
          const Positioned.fill(
            child: LiquidGlassLayer(
              settings: AppTheme.liquidGlassDefault,
              child: SizedBox.expand(),
            ),
          ),
          // Scrollable content on top
          SafeArea(
            child: shouldAnimate
                ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildContent(context),
                  )
                : _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final preferredService = ref.watch(preferredMusicServiceProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // Invalidate providers to reload data
        ref.invalidate(statisticsProvider);
        ref.invalidate(chartDataProvider);
        ref.invalidate(receivedStatisticsProvider);
        ref.invalidate(receivedChartDataProvider);

        // Wait a bit for the refresh animation
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: context.primaryColor,
      backgroundColor: AppTheme.colors.backgroundCard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppTheme.spacing.l),
        child: Column(
          children: [
            // Header with help button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const UniTuneLogo(),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  color: AppTheme.colors.textSecondary,
                  iconSize: 24,
                  tooltip: 'Show tutorial',
                  onPressed: () {
                    // Navigate to onboarding welcome screen
                    context.go('/onboarding/welcome');
                  },
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing.xl),

            // Statistics Card
            const StatisticsCard(),
            SizedBox(height: AppTheme.spacing.l),

            // Instructions Card
            Container(
              width: double.infinity, // Ensure full width
              padding: EdgeInsets.all(AppTheme.spacing.l),
              decoration: BoxDecoration(
                color: AppTheme.colors.glassBase,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.colors.glassBorder,
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.share, size: 48, color: context.primaryColor),
                  SizedBox(height: AppTheme.spacing.m),
                  Text(
                    'Share a song from any music app',
                    style: AppTheme.typography.titleMedium.copyWith(
                      color: AppTheme.colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppTheme.spacing.s),
                  Text(
                    'UniTune will convert it to your preferred platform',
                    style: AppTheme.typography.bodyMedium.copyWith(
                      color: AppTheme.colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Button to open preferred music service
                  if (preferredService != null) ...[
                    SizedBox(height: AppTheme.spacing.l),
                    _buildOpenAppButton(preferredService),
                  ],
                ],
              ),
            ),

            // Bottom padding for navigation
            SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenAppButton(MusicService service) {
    return GestureDetector(
      onTap: () => _openMusicService(service),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.l,
          vertical: AppTheme.spacing.m,
        ),
        decoration: BoxDecoration(
          color: AppTheme.colors.glassBase,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTheme.colors.glassBorder, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo.music(service: service, size: 32),
            SizedBox(width: AppTheme.spacing.m),
            Text(
              'Open ${service.name}',
              style: AppTheme.typography.bodyLarge.copyWith(
                color: AppTheme.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: AppTheme.spacing.s),
            Icon(
              Icons.open_in_new,
              size: 18,
              color: AppTheme.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMusicService(MusicService service) async {
    HapticFeedback.lightImpact();

    // Try to open the app with its URL scheme
    final Uri appUri;

    switch (service) {
      case MusicService.spotify:
        appUri = Uri.parse('spotify://');
        break;
      case MusicService.appleMusic:
        appUri = Uri.parse('music://');
        break;
      case MusicService.tidal:
        appUri = Uri.parse('tidal://');
        break;
      case MusicService.youtubeMusic:
        appUri = Uri.parse('youtubemusic://');
        break;
      case MusicService.deezer:
        appUri = Uri.parse('deezer://');
        break;
      case MusicService.amazonMusic:
        appUri = Uri.parse('amznmp3://');
        break;
    }

    try {
      final canLaunch = await canLaunchUrl(appUri);
      if (canLaunch) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else {
        // If app is not installed, show a message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${service.name} is not installed'),
              backgroundColor: AppTheme.colors.backgroundCard,
            ),
          );
        }
      }
    } catch (e) {
      // Handle error silently or show message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${service.name}'),
            backgroundColor: AppTheme.colors.backgroundCard,
          ),
        );
      }
    }
  }
}
