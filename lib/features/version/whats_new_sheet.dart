import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/dynamic_theme.dart';
import '../../data/models/remote_version_info.dart';
import 'version_notifier.dart';

/// Maps icon name strings from the worker API to Material [IconData].
/// Add new entries here when new icon names are used in version_handler.js.
IconData _iconFromName(String name) {
  const map = <String, IconData>{
    'privacy_tip': Icons.privacy_tip_outlined,
    'text_fields': Icons.text_fields,
    'bug_report': Icons.bug_report_outlined,
    'link': Icons.link,
    'tune': Icons.tune,
    'shield': Icons.shield_outlined,
    'music_note': Icons.music_note_outlined,
    'playlist_add': Icons.playlist_add,
    'speed': Icons.speed_outlined,
    'star': Icons.star_outlined,
    'star_outline': Icons.star_border_outlined,
    'new_releases': Icons.new_releases_outlined,
    'update': Icons.system_update_outlined,
    'security': Icons.security_outlined,
    'design_services': Icons.design_services_outlined,
    'accessibility': Icons.accessibility_new_outlined,
    'notifications': Icons.notifications_outlined,
    'settings': Icons.settings_outlined,
    'palette': Icons.palette_outlined,
    'system_update': Icons.system_update_outlined,
    'auto_awesome': Icons.auto_awesome_outlined,
    'rocket_launch': Icons.rocket_launch_outlined,
    'card_giftcard': Icons.card_giftcard_outlined,
    'translate': Icons.translate_outlined,
    'dark_mode': Icons.dark_mode_outlined,
    'light_mode': Icons.light_mode_outlined,
    'sync': Icons.sync_outlined,
    'history': Icons.history_outlined,
    'share': Icons.share_outlined,
  };
  return map[name] ?? Icons.star_border_outlined;
}

/// Returns a human-readable label for the distribution channel.
String _channelLabel(String channel) {
  switch (channel) {
    case 'github':
      return 'GitHub';
    case 'appstore':
      return 'App Store';
    case 'playstore':
    default:
      return 'Play Store';
  }
}

/// Returns the icon for the distribution channel.
IconData _channelIcon(String channel) {
  switch (channel) {
    case 'github':
      return Icons.code;
    case 'appstore':
      return Icons.apple;
    case 'playstore':
    default:
      return Icons.shop_outlined;
  }
}

/// WhatsNewSheet — bottom sheet shown once after each app update.
///
/// Shows:
/// - 2-4 feature highlights from the worker API.
/// - "View full Changelog" link button.
/// - "Got it, don't show again" dismiss button.
///
/// The sheet is triggered from [MainShell] via a [ref.listen] on
/// [versionNotifierProvider] and never shown more than once per version.
class WhatsNewSheet extends ConsumerWidget {
  const WhatsNewSheet({super.key});

  /// Convenience method to show the sheet as a centered dialog.
  static void show(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: false,
      builder: (_) => const WhatsNewSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(versionNotifierProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(AppTheme.spacing.m),
      child: versionAsync.when(
        loading: () => const _SheetSkeleton(),
        error: (_, __) => const SizedBox.shrink(),
        data: (state) {
          final remote = state.remote;
          if (remote == null) return const SizedBox.shrink();

          return _SheetContent(
            version: remote.latestVersion,
            items: remote.whatsNew,
            changelogUrl: remote.changelogUrl,
            updateUrl: remote.updateUrls.forCurrentChannel,
            channel: kDistributionChannel,
            onDismiss: () async {
              await ref
                  .read(versionNotifierProvider.notifier)
                  .dismissWhatsNew();
              if (context.mounted) Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _SheetContent extends StatelessWidget {
  final String version;
  final List<WhatsNewItem> items;
  final String changelogUrl;
  final String updateUrl;
  final String channel;
  final VoidCallback onDismiss;

  const _SheetContent({
    required this.version,
    required this.items,
    required this.changelogUrl,
    required this.updateUrl,
    required this.channel,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;

    return LiquidGlassLayer(
      settings: AppTheme.liquidGlassDefault,
      child: LiquidGlass.withOwnLayer(
        settings: const LiquidGlassSettings(
          blur: 24,
          ambientStrength: 0.5,
          glassColor: Color(0x1AFFFFFF),
          thickness: 18,
          lightIntensity: 0.55,
          saturation: 1.1,
          refractiveIndex: 1.2,
        ),
        shape: LiquidRoundedSuperellipse(borderRadius: AppTheme.radii.xLarge),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radii.xLarge),
            border: Border.all(color: AppTheme.colors.glassBorder, width: 1.0),
          ),
          padding: EdgeInsets.all(AppTheme.spacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: title + version left, changelog + close right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's New",
                          style: AppTheme.typography.titleLarge.copyWith(
                            color: AppTheme.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version $version',
                          style: AppTheme.typography.labelMedium.copyWith(
                            color: AppTheme.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.s),
                  TextButton.icon(
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      final uri = Uri.tryParse(changelogUrl);
                      if (uri != null) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: AppTheme.colors.textSecondary,
                    ),
                    label: Text(
                      'Changelog',
                      style: AppTheme.typography.labelMedium.copyWith(
                        color: AppTheme.colors.textSecondary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radii.pill,
                        ),
                        side: BorderSide(color: AppTheme.colors.glassBorder),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing.l),

              // Feature highlights list
              ...items.map((item) => _FeatureTile(item: item, accent: accent)),
              SizedBox(height: AppTheme.spacing.l),

              // Distribution channel note
              _ChannelNote(channel: channel),
              SizedBox(height: AppTheme.spacing.l),

              // Got it — full width
              SizedBox(
                width: double.infinity,
                child: _PrimarySheetButton(
                  label: 'Got it',
                  onPressed: onDismiss,
                ),
              ),

              // "Don't show again" note
              SizedBox(height: AppTheme.spacing.s),
              Center(
                child: Text(
                  "Won't be shown again for this version",
                  style: AppTheme.typography.labelMedium.copyWith(
                    color: AppTheme.colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single feature highlight row inside the What's New sheet.
class _FeatureTile extends StatelessWidget {
  final WhatsNewItem item;
  final Color accent;

  const _FeatureTile({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radii.medium),
              border: Border.all(
                color: accent.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Icon(_iconFromName(item.icon), color: accent, size: 20),
          ),
          SizedBox(width: AppTheme.spacing.m),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTheme.typography.bodyLarge.copyWith(
                    color: AppTheme.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  style: AppTheme.typography.bodyMedium.copyWith(
                    color: AppTheme.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small note showing which distribution channel the app was installed from.
class _ChannelNote extends StatelessWidget {
  final String channel;

  const _ChannelNote({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_channelIcon(channel), size: 14, color: AppTheme.colors.textMuted),
        const SizedBox(width: 6),
        Text(
          'Installed via ${_channelLabel(channel)}',
          style: AppTheme.typography.labelMedium.copyWith(
            color: AppTheme.colors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Ghost (outlined) button for secondary actions.
class _GhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double height;
  final VoidCallback onPressed;

  const _GhostButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton.custom(
      onTap: onPressed,
      height: height,
      useOwnLayer: true,
      shape: LiquidRoundedSuperellipse(borderRadius: AppTheme.radii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radii.pill),
          border: Border.all(color: AppTheme.colors.glassBorder, width: 1.0),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppTheme.colors.textSecondary),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTheme.typography.labelLarge.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary filled button styled in the app's glass design language.
class _PrimarySheetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimarySheetButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    return GlassButton.custom(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      height: 48,
      useOwnLayer: true,
      shape: LiquidRoundedSuperellipse(borderRadius: AppTheme.radii.pill),
      child: Container(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radii.pill),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.0),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.typography.labelLarge.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton shown while version data loads (unlikely but handles edge case).
class _SheetSkeleton extends StatelessWidget {
  const _SheetSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacing.m),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.colors.glassBase,
          borderRadius: BorderRadius.circular(AppTheme.radii.xLarge),
        ),
      ),
    );
  }
}
