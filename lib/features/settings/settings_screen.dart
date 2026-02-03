import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_settings/app_settings.dart';
import '../../core/constants/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/dynamic_theme.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/unitune_logo.dart';
import '../../core/widgets/unitune_header.dart';
import '../../core/widgets/brand_logo.dart';
import 'preferences_manager.dart';

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
          LiquidGlassLayer(
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

  /// Build Advanced section with Music Link Interception toggle
  /// Android only feature - allows UniTune to intercept music links
  Widget _buildAdvancedSection(BuildContext context, WidgetRef ref) {
    final interceptEnabled = ref.watch(interceptMusicLinksProvider);

    return Column(
      children: [
        LiquidGlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final newValue = !interceptEnabled;
                  await ref
                      .read(preferencesManagerProvider)
                      .setInterceptMusicLinks(newValue);
                  ref.read(interceptMusicLinksProvider.notifier).state =
                      newValue;

                  // Show setup dialog on first enable
                  if (newValue && context.mounted) {
                    _showInterceptionSetupDialog(context);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.m),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link,
                        color: AppTheme.colors.textSecondary,
                        size: 24,
                      ),
                      SizedBox(width: AppTheme.spacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Intercept Music Links',
                              style: AppTheme.typography.bodyLarge.copyWith(
                                color: AppTheme.colors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Open Spotify, Tidal, etc. links with UniTune (Android only)',
                              style: AppTheme.typography.bodyMedium.copyWith(
                                color: AppTheme.colors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: interceptEnabled,
                        onChanged: (value) async {
                          HapticFeedback.lightImpact();
                          await ref
                              .read(preferencesManagerProvider)
                              .setInterceptMusicLinks(value);
                          ref.read(interceptMusicLinksProvider.notifier).state =
                              value;

                          // Show setup dialog on first enable
                          if (value && context.mounted) {
                            _showInterceptionSetupDialog(context);
                          }
                        },
                        activeColor: context.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (interceptEnabled) ...[
          SizedBox(height: AppTheme.spacing.s),
          LiquidGlassCard(
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
                      child: Text(
                        'Configure Link Handling',
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
          ),
        ],
      ],
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyle(color: context.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Show setup dialog with instructions
  void _showInterceptionSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.colors.backgroundDeep,
        title: Text(
          'Music Link Interception',
          style: AppTheme.typography.titleMedium.copyWith(
            color: AppTheme.colors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To intercept music links, you need to configure Android link handling:',
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.textSecondary,
              ),
            ),
            SizedBox(height: 16),
            _buildSetupStep('1', 'Tap "Configure Link Handling" below'),
            SizedBox(height: 8),
            _buildSetupStep('2', 'Enable "Open supported links"'),
            SizedBox(height: 8),
            _buildSetupStep('3', 'Select music services to intercept'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.colors.textMuted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.colors.textMuted,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Android will ask you to choose between UniTune and the music app each time',
                      style: AppTheme.typography.bodyMedium.copyWith(
                        color: AppTheme.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Later',
              style: TextStyle(color: AppTheme.colors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openLinkSettings(context);
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
                        ),
                      ),
                      Text(
                        'Version 1.3.1',
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
                'Share music universally across streaming platforms. No accounts, no tracking, completely private.',
                style: AppTheme.typography.bodyMedium.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppTheme.spacing.m),
        _PrivacyPolicyButton(),
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

/// Privacy Policy Button Widget
/// Opens the app privacy policy in the browser
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
