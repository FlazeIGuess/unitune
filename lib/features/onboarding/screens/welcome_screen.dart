import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/optimized_liquid_glass.dart';
import '../../../core/widgets/unitune_logo.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/constants/services.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../widgets/onboarding_navigation_buttons.dart';

/// Welcome Screen - First onboarding step
///
/// Full-screen slide with clear hierarchy, illustration, and glass container.
/// All text in English.
///
/// Validates: Requirements 12.1, 12.2, 12.3, 12.5, 17.1
class WelcomeScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({super.key, required this.onContinue});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildConversionExample(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.l),
      decoration: BoxDecoration(
        color: AppTheme.colors.glassBase,
        borderRadius: BorderRadius.circular(AppTheme.radii.large),
        border: Border.all(color: AppTheme.colors.glassBorder, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Spotify Icon
          BrandLogo.music(service: MusicService.spotify, size: 32),
          SizedBox(width: AppTheme.spacing.m),

          // Arrow
          Icon(Icons.arrow_forward, color: context.primaryColor, size: 24),
          SizedBox(width: AppTheme.spacing.m),

          // UniTune Icon
          const UniTuneLogo(size: 32, showText: false),
          SizedBox(width: AppTheme.spacing.m),

          // Arrow
          Icon(Icons.arrow_forward, color: context.primaryColor, size: 24),
          SizedBox(width: AppTheme.spacing.m),

          // Apple Music Icon
          BrandLogo.music(service: MusicService.appleMusic, size: 32),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalSlides = Platform.isAndroid ? 4 : 3;
    const slideIndex = 0; // Welcome is step 1 (index 0)

    return OnboardingProgressBar(
      currentStep: slideIndex,
      totalSteps: totalSlides,
    );
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
                  padding: EdgeInsets.all(AppTheme.spacing.l),
                  child: Column(
                    children: [
                      // Progress indicator
                      _buildProgressIndicator(),

                      const Spacer(),

                      // Logo
                      const UniTuneLogo(size: 80),
                      SizedBox(height: AppTheme.spacing.xl),

                      // Problem Statement (emotional hook)
                      Text(
                        'Ever received a music link\nyou couldn\'t open?',
                        style: AppTheme.typography.displayMedium.copyWith(
                          color: AppTheme.colors.textPrimary,
                          fontFamily: 'ZalandoSansExpanded',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppTheme.spacing.m),

                      // Solution
                      Text(
                        'UniTune converts any music link to work\non YOUR preferred platform',
                        style: AppTheme.typography.bodyLarge.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppTheme.spacing.xl),

                      // Visual Example
                      _buildConversionExample(context),
                      SizedBox(height: AppTheme.spacing.xl),

                      // Social Proof
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing.l,
                          vertical: AppTheme.spacing.m,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.colors.glassBase,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radii.pill,
                          ),
                          border: Border.all(
                            color: AppTheme.colors.glassBorder,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              color: context.primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: AppTheme.spacing.s),
                            Text(
                              'Join thousands of music lovers',
                              style: AppTheme.typography.labelMedium.copyWith(
                                color: AppTheme.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Privacy Note
                      Padding(
                        padding: EdgeInsets.only(bottom: AppTheme.spacing.m),
                        child: Text(
                          'No account needed • Your data stays private',
                          style: AppTheme.typography.labelMedium.copyWith(
                            color: AppTheme.colors.textMuted,
                          ),
                          textAlign: TextAlign.center,
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
                  onContinue: widget.onContinue,
                  continueLabel: 'Get Started',
                  // No back button on first screen
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
