import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:url_launcher/url_launcher.dart';
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

  /// Build About section with version information
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
                        'Version 1.2.0',
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
