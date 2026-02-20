import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/optimized_liquid_glass.dart';
import '../../../core/constants/services.dart';
import '../../settings/preferences_manager.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../widgets/onboarding_navigation_buttons.dart';

/// Music Service Selection Screen - Step 2 of onboarding
///
/// Lets users select their preferred music streaming service.
/// All text in English.
///
/// Validates: Requirements 12.1, 12.2, 12.3, 12.5, 17.1
class MusicServiceSelector extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const MusicServiceSelector({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<MusicServiceSelector> createState() =>
      _MusicServiceSelectorState();
}

class _MusicServiceSelectorState extends ConsumerState<MusicServiceSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  MusicService? _selectedService;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.animation.durationSlow,
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppTheme.animation.curveDecelerate,
      ),
    );

    _controller.forward();

    // Load current preference if exists
    _selectedService = ref
        .read(preferencesManagerProvider)
        .preferredMusicService;
    _detectInstalledService();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_selectedService != null) {
      ref
          .read(preferencesManagerProvider)
          .setPreferredMusicService(_selectedService!)
          .then((_) {
            ref.read(preferredMusicServiceProvider.notifier).state =
                _selectedService;
            widget.onContinue();
          });
    }
  }

  Future<void> _detectInstalledService() async {
    if (_selectedService != null) return;
    for (final service in MusicService.values) {
      final uri = _serviceUri(service);
      if (uri == null) continue;
      final canOpen = await canLaunchUrl(uri);
      if (canOpen && mounted) {
        setState(() {
          _selectedService = service;
        });
        return;
      }
    }
  }

  Uri? _serviceUri(MusicService service) {
    switch (service) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
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
              child: FadeTransition(
                opacity: _fadeIn,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spacing.xl,
                    AppTheme.spacing.xl,
                    AppTheme.spacing.xl,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress indicator
                      _buildProgressIndicator(),
                      SizedBox(height: AppTheme.spacing.xl),

                      // Title
                      Text(
                        'Which music app do you use?',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ZalandoSansExpanded',
                            ),
                      ),
                      SizedBox(height: AppTheme.spacing.s),

                      // Description
                      Text(
                        'We\'ll convert all shared links to open in your app',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacing.xl),

                      // Service options with scrolling
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Column(
                            children: [
                              for (
                                int i = 0;
                                i < MusicService.values.length;
                                i++
                              ) ...[
                                _buildServiceOption(MusicService.values[i]),
                                if (i < MusicService.values.length - 1)
                                  SizedBox(height: AppTheme.spacing.m),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Floating Navigation Buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: OnboardingNavigationButtons(
                  onBack: widget.onBack,
                  onContinue: _handleContinue,
                  isEnabled: _selectedService != null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalSlides = Platform.isAndroid ? 4 : 3;
    const slideIndex = 1; // Music Service is step 2 (index 1)

    return OnboardingProgressBar(
      currentStep: slideIndex,
      totalSteps: totalSlides,
    );
  }

  Widget _buildServiceOption(MusicService service) {
    final isSelected = _selectedService == service;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedService = service;
        });
      },
      child: LiquidGlassContainer(
        borderRadius: AppTheme.radii.large,
        blurSigma: isSelected ? 20 : 10,
        glassColor: isSelected
            ? AppTheme.colors.glassBase.withValues(alpha: 0.15)
            : AppTheme.colors.glassBase.withValues(alpha: 0.08),
        borderColor: isSelected
            ? AppTheme.colors.glassBorder.withValues(alpha: 0.3)
            : AppTheme.colors.glassBorder.withValues(alpha: 0.15),
        child: Container(
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.m),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: context.primaryColor, width: 2)
                : null,
            borderRadius: BorderRadius.circular(AppTheme.radii.large),
          ),
          child: Row(
            children: [
              BrandLogo.music(service: service, size: 40),
              SizedBox(width: AppTheme.spacing.m),
              Expanded(
                child: Text(
                  service.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.colors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontFamily: 'ZalandoSansExpanded',
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: context.primaryColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
