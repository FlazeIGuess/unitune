import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:app_settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/optimized_liquid_glass.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/constants/services.dart';
import '../../settings/preferences_manager.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../widgets/onboarding_navigation_buttons.dart';

/// Link Interception Screen - Android only onboarding step
///
/// Explains the music link interception feature and allows users to enable it.
/// Only shown on Android devices.
class LinkInterceptionScreen extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const LinkInterceptionScreen({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<LinkInterceptionScreen> createState() =>
      _LinkInterceptionScreenState();
}

class _LinkInterceptionScreenState extends ConsumerState<LinkInterceptionScreen>
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

  void _handleContinue() async {
    widget.onContinue();
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.colors.backgroundDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.large),
        ),
        title: Text(
          'Setup Tutorial',
          style: AppTheme.typography.titleMedium.copyWith(
            color: AppTheme.colors.textPrimary,
            fontFamily: 'ZalandoSansExpanded',
          ),
        ),
        content: Container(
          padding: EdgeInsets.all(AppTheme.spacing.m),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radii.medium),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.settings, color: context.primaryColor, size: 20),
                  SizedBox(width: AppTheme.spacing.s),
                  Text(
                    'Android Setup Required',
                    style: AppTheme.typography.labelLarge.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing.m),
              Text(
                'Follow these steps to enable link interception:',
                style: AppTheme.typography.bodyMedium.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
              ),
              SizedBox(height: AppTheme.spacing.m),
              _buildStep('1', 'Tap "Open Settings" below'),
              SizedBox(height: AppTheme.spacing.s),
              _buildStep('2', 'Enable "Open supported links"'),
              SizedBox(height: AppTheme.spacing.s),
              _buildStep('3', 'Select music services to intercept'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Text(
              'Later',
              style: TextStyle(color: AppTheme.colors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              await ref
                  .read(preferencesManagerProvider)
                  .setInterceptMusicLinks(true);
              ref.read(interceptMusicLinksProvider.notifier).state = true;
              _openLinkSettings();
            },
            child: Text(
              'Open Settings',
              style: TextStyle(color: context.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _openLinkSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (e) {
      // Silently fail
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
          // Glass layer
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
                    100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress indicator
                      _buildProgressIndicator(),
                      SizedBox(height: AppTheme.spacing.xl),

                      // Title
                      Text(
                        'Open music links directly',
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
                        'UniTune can intercept music links from other apps and convert them automatically',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
                      ),

                      Spacer(),

                      // Visual Example
                      _buildInterceptionExample(context),

                      SizedBox(height: AppTheme.spacing.xl),

                      // How it works
                      _buildHowItWorks(),

                      Spacer(),

                      // Enable Button
                      _buildEnableButton(),

                      SizedBox(height: AppTheme.spacing.m),

                      // Info text
                      Center(
                        child: Text(
                          'You can change this later in settings',
                          style: AppTheme.typography.bodyMedium.copyWith(
                            color: AppTheme.colors.textMuted,
                            fontSize: 13,
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
          // Floating buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _buildFloatingButtons(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    const totalSlides = 4;
    const slideIndex = 2; // Link Interception is step 3 (index 2)

    return OnboardingProgressBar(
      currentStep: slideIndex,
      totalSteps: totalSlides,
    );
  }

  Widget _buildInterceptionExample(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.l),
      decoration: BoxDecoration(
        color: AppTheme.colors.glassBase,
        borderRadius: BorderRadius.circular(AppTheme.radii.large),
        border: Border.all(color: AppTheme.colors.glassBorder, width: 1.0),
      ),
      child: Column(
        children: [
          // Example: Spotify link
          Row(
            children: [
              BrandLogo.music(service: MusicService.spotify, size: 32),
              SizedBox(width: AppTheme.spacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spotify Link',
                      style: AppTheme.typography.bodyLarge.copyWith(
                        color: AppTheme.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'open.spotify.com/track/...',
                      style: AppTheme.typography.bodyMedium.copyWith(
                        color: AppTheme.colors.textMuted,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.m),

          // Arrow down
          Icon(Icons.arrow_downward, color: context.primaryColor, size: 24),
          SizedBox(height: AppTheme.spacing.m),

          // Result: Opens in your app
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.m),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radii.medium),
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: context.primaryColor, size: 20),
                SizedBox(width: AppTheme.spacing.s),
                Expanded(
                  child: Text(
                    'Opens in YOUR music app',
                    style: AppTheme.typography.bodyMedium.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTheme.typography.bodyMedium.copyWith(
                color: context.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
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
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.l),
      decoration: BoxDecoration(
        color: AppTheme.colors.glassBase,
        borderRadius: BorderRadius.circular(AppTheme.radii.large),
        border: Border.all(color: AppTheme.colors.glassBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: context.primaryColor, size: 20),
              SizedBox(width: AppTheme.spacing.s),
              Text(
                'How it works',
                style: AppTheme.typography.labelLarge.copyWith(
                  color: AppTheme.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.m),
          _buildStep('1', 'Android asks which app to use'),
          SizedBox(height: AppTheme.spacing.s),
          _buildStep('2', 'Choose UniTune'),
          SizedBox(height: AppTheme.spacing.s),
          _buildStep('3', 'Link opens in your preferred music app'),
        ],
      ),
    );
  }

  Widget _buildEnableButton() {
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
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showSetupDialog();
        },
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link, color: context.primaryColor, size: 24),
                SizedBox(width: AppTheme.spacing.m),
                Text(
                  'Enable Interception',
                  style: AppTheme.typography.bodyLarge.copyWith(
                    color: context.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return OnboardingNavigationButtons(
      onBack: widget.onBack,
      onContinue: _handleContinue,
    );
  }
}
