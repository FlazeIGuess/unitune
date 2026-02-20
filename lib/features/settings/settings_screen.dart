import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_settings/app_settings.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/ads/ad_helper.dart';
import '../../core/ads/consent_helper.dart';
import '../../core/constants/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/dynamic_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/optimized_liquid_glass.dart';
import '../../core/widgets/unitune_logo.dart';
import '../../core/widgets/unitune_header.dart';
import '../../core/widgets/brand_logo.dart';
import 'preferences_manager.dart';
import '../version/whats_new_sheet.dart';

/// Settings Screen - allows users to change their preferences
/// Modern dark mode design with Liquid Glass effects
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.6, 17.1
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedMusicService = ref.watch(preferredMusicServiceProvider);
    final selectedMessenger = ref.watch(preferredMessengerProvider);

    return Scaffold(
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
              child: Column(
                children: [
                  // Header
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.spacing.l,
                      AppTheme.spacing.l,
                      AppTheme.spacing.l,
                      AppTheme.spacing.s, // Smaller bottom padding
                    ),
                    child: const UniTuneHeader(
                      // No action button for settings, or could add help here
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.m,
                      ),
                      children: [
                        SizedBox(height: AppTheme.spacing.m),
                        _SupportButton(),
                        SizedBox(height: AppTheme.spacing.xl),

                        // DEFAULT PLATFORMS SECTION
                        _SectionHeader(title: 'Default Platforms'),
                        SizedBox(height: AppTheme.spacing.s),
                        _buildDefaultPlatformsSection(
                          context,
                          ref,
                          selectedMusicService,
                          selectedMessenger,
                        ),

                        SizedBox(height: AppTheme.spacing.xl),

                        // ADVANCED SECTION (Android only)
                        if (Platform.isAndroid) ...[
                          _SectionHeader(title: 'Advanced'),
                          SizedBox(height: AppTheme.spacing.s),
                          _buildAdvancedSection(context, ref),
                          SizedBox(height: AppTheme.spacing.xl),
                        ],

                        // ABOUT SECTION
                        // Requirement 11.6: Display version information
                        _SectionHeader(title: 'About'),
                        SizedBox(height: AppTheme.spacing.s),
                        _buildAboutSection(context),

                        SizedBox(height: AppTheme.spacing.xl),

                        // Extra bottom padding for floating navigation bar
                        SizedBox(height: 60),
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

  /// Build Default Platforms section
  /// Requirement 11.1: Group settings into sections
  Widget _buildDefaultPlatformsSection(
    BuildContext context,
    WidgetRef ref,
    MusicService? selectedMusicService,
    MessengerService? selectedMessenger,
  ) {
    return Column(
      children: [
        // Music Service
        LiquidGlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(AppTheme.spacing.m),
                child: Text(
                  'Music Service',
                  style: AppTheme.typography.labelLarge.copyWith(
                    color: AppTheme.colors.textMuted,
                  ),
                ),
              ),
              ...MusicService.values.map((service) {
                final isSelected = selectedMusicService == service;
                final isLast = service == MusicService.values.last;
                return _MusicServiceTile(
                  service: service,
                  isSelected: isSelected,
                  showDivider: !isLast,
                  onTap: () async {
                    await ref
                        .read(preferencesManagerProvider)
                        .setPreferredMusicService(service);
                    ref.read(preferredMusicServiceProvider.notifier).state =
                        service;
                  },
                );
              }),
            ],
          ),
        ),

        SizedBox(height: AppTheme.spacing.m),

        // Messenger Service
        LiquidGlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(AppTheme.spacing.m),
                child: Text(
                  'Messenger',
                  style: AppTheme.typography.labelLarge.copyWith(
                    color: AppTheme.colors.textMuted,
                  ),
                ),
              ),
              ...MessengerService.values.map((messenger) {
                final isSelected = selectedMessenger == messenger;
                final isLast = messenger == MessengerService.values.last;
                return _MessengerServiceTile(
                  service: messenger,
                  isSelected: isSelected,
                  showDivider: !isLast,
                  onTap: () async {
                    await ref
                        .read(preferencesManagerProvider)
                        .setPreferredMessenger(messenger);
                    ref.read(preferredMessengerProvider.notifier).state =
                        messenger;
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// Build Advanced section with Music Link Interception configuration.
  /// Android only — always shows the configure button regardless of onboarding state.
  Widget _buildAdvancedSection(BuildContext context, WidgetRef ref) {
    return LiquidGlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _openLinkSettings(context);
        },
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing.m),
          child: Row(
            children: [
              Icon(
                Icons.settings_applications,
                color: AppTheme.colors.textSecondary,
                size: 24,
              ),
              SizedBox(width: AppTheme.spacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configure Link Handling',
                      style: AppTheme.typography.bodyLarge.copyWith(
                        color: AppTheme.colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage which music links UniTune intercepts',
                      style: AppTheme.typography.bodyMedium.copyWith(
                        color: AppTheme.colors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                color: AppTheme.colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Open Android link settings for this app
  void _openLinkSettings(BuildContext context) async {
    try {
      // Open app settings using app_settings package
      await AppSettings.openAppSettings();
    } catch (e) {
      // Fallback: Show manual instructions
      if (context.mounted) {
        _showManualInstructions(context);
      }
    }
  }

  /// Show manual instructions dialog
  void _showManualInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.colors.backgroundDeep,
        title: Text(
          'Configure Link Handling',
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
              'Follow these steps to intercept music links:',
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.textSecondary,
              ),
            ),
            SizedBox(height: 16),
            _buildSetupStep('1', 'Open Android Settings'),
            SizedBox(height: 8),
            _buildSetupStep('2', 'Go to Apps > UniTune'),
            SizedBox(height: 8),
            _buildSetupStep('3', 'Tap "Open by default"'),
            SizedBox(height: 8),
            _buildSetupStep('4', 'Enable "Open supported links"'),
            SizedBox(height: 8),
            _buildSetupStep('5', 'Select music services to intercept'),
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

  /// Build setup step widget
  Widget _buildSetupStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.colors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
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

  /// Show info dialog explaining music link interception
  /// Requirement 11.6: Display version information in About section
  /// Requirement 17.1: Ensure all text is in English
  Widget _buildAboutSection(BuildContext context) {
    return Column(
      children: [
        LiquidGlassCard(
          tintColor: context.primaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UniTuneLogo(size: 48, showText: false),
                  SizedBox(width: AppTheme.spacing.m),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UniTune',
                        style: AppTheme.typography.titleMedium.copyWith(
                          color: AppTheme.colors.textPrimary,
                          fontFamily: 'ZalandoSansExpanded',
                        ),
                      ),
                      Text(
                        'Version 1.5.0',
                        style: AppTheme.typography.bodyMedium.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing.m),
              Text(
                'Share music universally across streaming platforms.',
                style: AppTheme.typography.bodyMedium.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppTheme.spacing.m),
        _ChangelogButton(),
        SizedBox(height: AppTheme.spacing.m),
        _ReportBugButton(),
        SizedBox(height: AppTheme.spacing.m),
        _PrivacyPolicyButton(),
        SizedBox(height: AppTheme.spacing.m),
        _ManageConsentButton(),
      ],
    );
  }
}

/// Section header widget
/// Requirement 11.4: Use consistent typography for all labels
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTheme.typography.labelLarge.copyWith(
        color: AppTheme.colors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Music Service Tile with Brand Logo
class _MusicServiceTile extends StatelessWidget {
  final MusicService service;
  final bool isSelected;
  final bool showDivider;
  final VoidCallback onTap;

  const _MusicServiceTile({
    required this.service,
    required this.isSelected,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.m,
              vertical: 14,
            ),
            child: Row(
              children: [
                BrandLogo.music(service: service, size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    service.name,
                    style: AppTheme.typography.bodyLarge.copyWith(
                      color: isSelected
                          ? AppTheme.colors.textPrimary
                          : AppTheme.colors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: context.primaryColor,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 66,
            color: Colors.white.withValues(alpha: 0.08),
          ),
      ],
    );
  }
}

/// Messenger Service Tile with Brand Logo
class _MessengerServiceTile extends StatelessWidget {
  final MessengerService service;
  final bool isSelected;
  final bool showDivider;
  final VoidCallback onTap;

  const _MessengerServiceTile({
    required this.service,
    required this.isSelected,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.m,
              vertical: 14,
            ),
            child: Row(
              children: [
                BrandLogo.messenger(service: service, size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    service.name,
                    style: AppTheme.typography.bodyLarge.copyWith(
                      color: isSelected
                          ? AppTheme.colors.textPrimary
                          : AppTheme.colors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: context.primaryColor,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 66,
            color: Colors.white.withValues(alpha: 0.08),
          ),
      ],
    );
  }
}

class _ChangelogButton extends StatelessWidget {
  const _ChangelogButton();

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          WhatsNewSheet.show(context);
        },
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing.m),
          child: Row(
            children: [
              Icon(
                Icons.history_outlined,
                color: AppTheme.colors.textSecondary,
                size: 24,
              ),
              SizedBox(width: AppTheme.spacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What's New",
                      style: AppTheme.typography.bodyLarge.copyWith(
                        color: AppTheme.colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'See what changed in this update',
                      style: AppTheme.typography.labelMedium.copyWith(
                        color: AppTheme.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Privacy Policy Button Widget
/// Opens the app privacy policy in the browser
class _ReportBugButton extends StatelessWidget {
  const _ReportBugButton();

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          final uri = Uri.parse(
            'https://github.com/FlazeIGuess/unitune/issues',
          );
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing.m),
          child: Row(
            children: [
              Icon(
                Icons.bug_report_outlined,
                color: AppTheme.colors.textSecondary,
                size: 24,
              ),
              SizedBox(width: AppTheme.spacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report a Bug',
                      style: AppTheme.typography.bodyLarge.copyWith(
                        color: AppTheme.colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Opens GitHub Issues',
                      style: AppTheme.typography.labelMedium.copyWith(
                        color: AppTheme.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                color: AppTheme.colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyPolicyButton extends StatelessWidget {
  const _PrivacyPolicyButton();
  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          final uri = Uri.parse('https://unitune.art/privacy-app');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing.m),
          child: Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: AppTheme.colors.textSecondary,
                size: 24,
              ),
              SizedBox(width: AppTheme.spacing.m),
              Expanded(
                child: Text(
                  'Privacy Policy',
                  style: AppTheme.typography.bodyLarge.copyWith(
                    color: AppTheme.colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.open_in_new,
                color: AppTheme.colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Manage Ad Consent Button — GDPR requirement.
/// Shown only when the user is in EEA/UK and a consent form is available.
/// Allows re-opening the Google UMP consent dialog at any time.
class _ManageConsentButton extends StatelessWidget {
  const _ManageConsentButton();

  @override
  Widget build(BuildContext context) {
    // Only render the button if a privacy options form is required
    // (i.e. user is EEA/UK and has previously seen the consent dialog)
    if (!ConsentHelper.shouldShowPrivacyOptionsButton()) {
      return const SizedBox.shrink();
    }

    return LiquidGlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          await ConsentHelper.showPrivacyOptionsForm();
        },
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing.m),
          child: Row(
            children: [
              Icon(
                Icons.manage_accounts_outlined,
                color: AppTheme.colors.textSecondary,
                size: 24,
              ),
              SizedBox(width: AppTheme.spacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Ad Consent',
                      style: AppTheme.typography.bodyLarge.copyWith(
                        color: AppTheme.colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Update your advertising preferences',
                      style: AppTheme.typography.bodyMedium.copyWith(
                        color: AppTheme.colors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportButton extends ConsumerStatefulWidget {
  const _SupportButton();

  @override
  ConsumerState<_SupportButton> createState() => _SupportButtonState();
}

class _SupportButtonState extends ConsumerState<_SupportButton> {
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

  void _loadRewardedAd() async {
    if (!AdHelper.adsEnabled) return;
    if (_isAdLoading) return;
    // GDPR: Only load ads if consent has been given (or user is non-EEA).
    if (!await ConsentHelper.canRequestAds()) return;
    _isAdLoading = true;
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: AdHelper.defaultRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _rewardedAd = ad;
              _isAdLoading = false;
            });
          }
        },
        onAdFailedToLoad: (error) {
          if (mounted) {
            setState(() {
              _rewardedAd = null;
              _isAdLoading = false;
            });
          }
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  void _showSupportDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.colors.backgroundDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.large),
        ),
        title: Text(
          'Support UniTune',
          style: AppTheme.typography.titleMedium.copyWith(
            color: AppTheme.colors.textPrimary,
            fontFamily: 'ZalandoSansExpanded',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Help us keep UniTune free and ad-free for everyone',
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacing.l),

            // Watch Ad Button (always show, even if ads disabled)
            LiquidGlassCard(
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                  _showRewardedAd();
                },
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.m),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: AppTheme.colors.textSecondary,
                        size: 24,
                      ),
                      SizedBox(width: AppTheme.spacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Watch a short video',
                              style: AppTheme.typography.bodyLarge.copyWith(
                                color: AppTheme.colors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _rewardedAd != null
                                  ? 'Support us by watching an ad'
                                  : AdHelper.adsEnabled
                                  ? 'Loading...'
                                  : 'Ads currently disabled',
                              style: AppTheme.typography.bodyMedium.copyWith(
                                color: AppTheme.colors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: AppTheme.spacing.m),

            // Ko-fi Button
            LiquidGlassCard(
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                  final uri = Uri.parse('https://ko-fi.com/unitune');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.m),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite_border,
                        color: AppTheme.colors.textSecondary,
                        size: 24,
                      ),
                      SizedBox(width: AppTheme.spacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buy us a coffee',
                              style: AppTheme.typography.bodyLarge.copyWith(
                                color: AppTheme.colors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Support us on Ko-fi',
                              style: AppTheme.typography.bodyMedium.copyWith(
                                color: AppTheme.colors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new,
                        color: AppTheme.colors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Text(
              'Close',
              style: TextStyle(color: AppTheme.colors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _showRewardedAd() {
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
        setState(() => _rewardedAd = null);
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        setState(() => _rewardedAd = null);
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
    setState(() => _rewardedAd = null);
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: _showSupportDialog,
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing.m),
          child: Row(
            children: [
              Icon(
                Icons.favorite_border,
                color: AppTheme.colors.textSecondary,
                size: 24,
              ),
              SizedBox(width: AppTheme.spacing.m),
              Expanded(
                child: Text(
                  'Support UniTune',
                  style: AppTheme.typography.bodyLarge.copyWith(
                    color: AppTheme.colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
