import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/dynamic_theme.dart';
import '../../data/models/remote_version_info.dart';
import 'version_notifier.dart';

/// Returns a human-readable store label for the distribution channel.
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

/// Returns the appropriate icon for the distribution channel.
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

/// UpdateBanner — slim glass card shown above the bottom nav when a
/// newer version is available.
///
/// - "Update" opens the distribution-channel-specific store listing.
/// - "Ignore" hides the banner permanently for this remote version.
///
/// The banner slides in smoothly using [AnimatedContainer] and is
/// driven purely by [versionNotifierProvider] — no local state needed.
///
/// Usage: place directly inside the MainShell [Stack], positioned above
/// the bottom navigation widget.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(versionNotifierProvider);

    final show = versionAsync.valueOrNull?.showUpdateAvailable ?? false;
    final remote = versionAsync.valueOrNull?.remote;

    // Animate with ClipRect + AnimatedAlign so height collapses smoothly.
    return ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        heightFactor: show ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.m,
            vertical: AppTheme.spacing.s,
          ),
          child: remote == null
              ? const SizedBox.shrink()
              : _BannerCard(
                  remoteVersion: remote.latestVersion,
                  updateUrl: remote.updateUrls.forCurrentChannel,
                  channel: kDistributionChannel,
                  onIgnore: () {
                    HapticFeedback.selectionClick();
                    ref.read(versionNotifierProvider.notifier).ignoreUpdate();
                  },
                ),
        ),
      ),
    );
  }
}

/// The actual glass card content of the update banner.
class _BannerCard extends StatelessWidget {
  final String remoteVersion;
  final String updateUrl;
  final String channel;
  final VoidCallback onIgnore;

  const _BannerCard({
    required this.remoteVersion,
    required this.updateUrl,
    required this.channel,
    required this.onIgnore,
  });

  Future<void> _openStore() async {
    final uri = Uri.tryParse(updateUrl);
    if (uri == null) return;
    HapticFeedback.lightImpact();
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;

    return LiquidGlassLayer(
      settings: AppTheme.liquidGlassDefault,
      child: LiquidGlass.withOwnLayer(
        settings: const LiquidGlassSettings(
          blur: 20,
          ambientStrength: 0.45,
          glassColor: Color(0x15FFFFFF),
          thickness: 14,
          lightIntensity: 0.5,
          saturation: 1.1,
          refractiveIndex: 1.15,
        ),
        shape: LiquidRoundedSuperellipse(borderRadius: AppTheme.radii.large),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radii.large),
            border: Border.all(
              color: accent.withValues(alpha: 0.25),
              width: 1.0,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.m,
            vertical: AppTheme.spacing.s,
          ),
          child: Row(
            children: [
              // Channel icon + version badge
              Icon(_channelIcon(channel), color: accent, size: 20),
              SizedBox(width: AppTheme.spacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'v$remoteVersion available',
                      style: AppTheme.typography.bodyMedium.copyWith(
                        color: AppTheme.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Update on ${_channelLabel(channel)}',
                      style: AppTheme.typography.labelMedium.copyWith(
                        color: AppTheme.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Ignore button
              _BannerAction(
                label: 'Ignore',
                color: AppTheme.colors.textMuted,
                onPressed: onIgnore,
              ),
              SizedBox(width: AppTheme.spacing.s),

              // Update button
              _BannerAction(
                label: 'Update',
                color: accent,
                filled: true,
                onPressed: _openStore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact inline action button used inside the update banner.
class _BannerAction extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onPressed;

  const _BannerAction({
    required this.label,
    required this.color,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton.custom(
      onTap: onPressed,
      height: 34,
      useOwnLayer: true,
      shape: LiquidRoundedSuperellipse(borderRadius: AppTheme.radii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radii.pill),
          border: filled
              ? Border.all(color: color.withValues(alpha: 0.35), width: 1.0)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.typography.labelLarge.copyWith(
              color: color,
              fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
