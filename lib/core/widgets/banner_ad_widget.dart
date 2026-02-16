import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ads/ad_helper.dart';
import '../theme/app_theme.dart';

/// Banner Ad Widget for Processing Screen
/// Shows a small banner ad at the bottom during link conversion
///
/// Usage:
/// ```dart
/// Positioned(
///   bottom: 0,
///   left: 0,
///   right: 0,
///   child: SafeArea(
///     child: Padding(
///       padding: EdgeInsets.all(AppTheme.spacing.m),
///       child: const BannerAdWidget(),
///     ),
///   ),
/// ),
/// ```
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (AdHelper.adsEnabled) {
      _loadAd();
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _isAdLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner Ad failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdHelper.adsEnabled) {
      return const SizedBox.shrink();
    }
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      decoration: BoxDecoration(
        color: AppTheme.colors.backgroundCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radii.small),
        border: Border.all(color: AppTheme.colors.glassBorder, width: 0.5),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
