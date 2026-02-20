import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ads/ad_helper.dart';
import '../theme/app_theme.dart';
import 'liquid_glass_container.dart';

/// Native Ad Card that matches the Liquid Glass design
/// Blends seamlessly with History Cards
///
/// Usage:
/// ```dart
/// ListView.builder(
///   itemBuilder: (context, index) {
///     if (index % 6 == 5) {
///       return const NativeAdCard();
///     }
///     return HistoryCard(...);
///   },
/// );
/// ```
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (AdHelper.adsEnabled) {
      _loadAd();
    }
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      factoryId:
          'liquidGlassNative', // Custom template (defined in native code)
      request: AdHelper.defaultRequest,
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _isAdLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native Ad failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdHelper.adsEnabled) {
      return const SizedBox.shrink();
    }
    // Don't show anything if ad isn't loaded (no placeholder)
    if (!_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return LiquidGlassCard(
      padding: EdgeInsets.zero,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radii.medium),
        ),
        clipBehavior: Clip.antiAlias,
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
