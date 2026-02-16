import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/security/url_validator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/dynamic_theme.dart';
import '../../core/widgets/unitune_logo.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/glass_input_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/optimized_liquid_glass.dart';
import '../../core/utils/motion_sensitivity.dart';
import '../../core/constants/services.dart';
import '../settings/preferences_manager.dart';
import 'widgets/statistics_card.dart';
import 'services/statistics_service.dart';

/// Home Screen - Simple welcome screen
/// Shows UniTune branding and waits for shared links
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _linkController = TextEditingController();
  final FocusNode _linkFocusNode = FocusNode();
  bool _isSharingLink = false;
  bool _isLinkValid = false;
  String? _validationMessage;
  bool _showPasteHint = false;
  String _lastValidatedText = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppTheme.animation.durationNormal,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppTheme.animation.curveDecelerate,
    );
    _fadeController.forward();
    _linkFocusNode.addListener(_handleLinkFocusChange);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _linkController.dispose();
    _linkFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = MotionSensitivity.shouldAnimate(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          // Glass layer - static, doesn't scroll
          const Positioned.fill(
            child: OptimizedLiquidGlassLayer(
              settings: AppTheme.liquidGlassDefault,
              child: SizedBox.expand(),
            ),
          ),
          // Scrollable content on top
          SafeArea(
            child: shouldAnimate
                ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildContent(context),
                  )
                : _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final preferredService = ref.watch(preferredMusicServiceProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // Invalidate providers to reload data
        ref.invalidate(statisticsProvider);
        ref.invalidate(chartDataProvider);
        ref.invalidate(receivedStatisticsProvider);
        ref.invalidate(receivedChartDataProvider);

        // Wait a bit for the refresh animation
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: context.primaryColor,
      backgroundColor: AppTheme.colors.backgroundCard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppTheme.spacing.l),
        child: Column(
          children: [
            // Header with help button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const UniTuneLogo(),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  color: AppTheme.colors.textSecondary,
                  iconSize: 24,
                  tooltip: 'Show tutorial',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    // Navigate to onboarding welcome screen
                    context.go('/onboarding/welcome');
                  },
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing.xl),

            // Statistics Card
            const StatisticsCard(),
            SizedBox(height: AppTheme.spacing.l),

            _buildPasteToShareCard(context),
            SizedBox(height: AppTheme.spacing.l),

            // Instructions Card
            Container(
              width: double.infinity, // Ensure full width
              padding: EdgeInsets.all(AppTheme.spacing.l),
              decoration: BoxDecoration(
                color: AppTheme.colors.glassBase,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.colors.glassBorder,
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.share, size: 48, color: context.primaryColor),
                  SizedBox(height: AppTheme.spacing.m),
                  Text(
                    'Share a song from any music app',
                    style: AppTheme.typography.titleMedium.copyWith(
                      color: AppTheme.colors.textPrimary,
                      fontFamily: 'ZalandoSansExpanded',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppTheme.spacing.s),
                  Text(
                    'UniTune will convert it to your preferred platform',
                    style: AppTheme.typography.bodyMedium.copyWith(
                      color: AppTheme.colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Button to open preferred music service
                  if (preferredService != null) ...[
                    SizedBox(height: AppTheme.spacing.l),
                    _buildOpenAppButton(preferredService),
                  ],
                ],
              ),
            ),

            // Bottom padding for navigation
            SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildPasteToShareCard(BuildContext context) {
    final trimmed = _linkController.text.trim();
    final hasInput = trimmed.isNotEmpty;
    final statusColor = _isLinkValid
        ? AppTheme.colors.accentSuccess
        : AppTheme.colors.accentError;
    final borderColor = hasInput ? statusColor.withValues(alpha: 0.5) : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppTheme.spacing.l),
      decoration: BoxDecoration(
        color: AppTheme.colors.glassBase,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.colors.glassBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paste a music link',
            style: AppTheme.typography.titleMedium.copyWith(
              color: AppTheme.colors.textPrimary,
              fontFamily: 'ZalandoSansExpanded',
            ),
          ),
          SizedBox(height: AppTheme.spacing.s),
          Text(
            'Paste a Spotify, Apple Music, Tidal, YouTube Music, Deezer, or Amazon Music link.',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
            ),
          ),
          SizedBox(height: AppTheme.spacing.m),
          GlassInputField(
            placeholder: 'https://open.spotify.com/track/...',
            controller: _linkController,
            focusNode: _linkFocusNode,
            borderColor: borderColor,
            keyboardType: TextInputType.url,
            onChanged: (value) {
              if (_isSharingLink) return;
              _updateValidation(value);
            },
          ),
          AnimatedSwitcher(
            duration: AppTheme.animation.durationFast,
            child: _showPasteHint
                ? Padding(
                    padding: EdgeInsets.only(top: AppTheme.spacing.s),
                    child: Row(
                      key: const ValueKey('paste_hint'),
                      children: [
                        Icon(
                          Icons.content_paste,
                          size: 16,
                          color: AppTheme.colors.textSecondary,
                        ),
                        SizedBox(width: AppTheme.spacing.s),
                        Text(
                          'Pasted from clipboard',
                          style: AppTheme.typography.labelMedium.copyWith(
                            color: AppTheme.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          AnimatedSwitcher(
            duration: AppTheme.animation.durationFast,
            child: hasInput
                ? Padding(
                    padding: EdgeInsets.only(top: AppTheme.spacing.s),
                    child: Row(
                      key: ValueKey('validation_$_isLinkValid'),
                      children: [
                        Icon(
                          _isLinkValid ? Icons.check_circle : Icons.error,
                          size: 16,
                          color: statusColor,
                        ),
                        SizedBox(width: AppTheme.spacing.s),
                        Expanded(
                          child: Text(
                            _isLinkValid
                                ? 'Valid link detected'
                                : (_validationMessage ??
                                      'Invalid or unsupported link'),
                            style: AppTheme.typography.labelMedium.copyWith(
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(height: AppTheme.spacing.m),
          PrimaryButton(
            label: 'Share Link',
            isLoading: _isSharingLink,
            onPressed: _isLinkValid
                ? _handleShareLink
                : _handleInvalidShareAttempt,
            icon: Icons.send,
          ),
        ],
      ),
    );
  }

  void _handleLinkFocusChange() {
    if (_linkFocusNode.hasFocus) {
      _attemptSmartPaste();
    }
  }

  Future<void> _attemptSmartPaste() async {
    if (_linkController.text.trim().isNotEmpty) {
      return;
    }

    final data = await Clipboard.getData('text/plain');
    final clipboardText = data?.text?.trim();
    if (clipboardText == null || clipboardText.isEmpty) {
      return;
    }

    final validation = UrlValidator.validateAndSanitize(clipboardText);
    if (!validation.isValid) {
      return;
    }

    _linkController.text = validation.sanitizedUrl;
    _linkController.selection = TextSelection.collapsed(
      offset: _linkController.text.length,
    );
    _updateValidation(_linkController.text, triggerHaptic: false);
    if (!mounted) return;
    setState(() => _showPasteHint = true);
    HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _showPasteHint = false);
  }

  void _updateValidation(String input, {bool triggerHaptic = true}) {
    final trimmed = input.trim();
    if (trimmed == _lastValidatedText) {
      return;
    }
    _lastValidatedText = trimmed;

    if (trimmed.isEmpty) {
      setState(() {
        _isLinkValid = false;
        _validationMessage = null;
      });
      return;
    }

    final validation = UrlValidator.validateAndSanitize(trimmed);
    final wasValid = _isLinkValid;
    setState(() {
      _isLinkValid = validation.isValid;
      _validationMessage = validation.isValid
          ? 'Valid link detected'
          : (validation.errorMessage ?? 'Invalid or unsupported link');
    });

    if (validation.isValid && validation.sanitizedUrl != trimmed) {
      final sanitized = validation.sanitizedUrl;
      _linkController.value = _linkController.value.copyWith(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
        composing: TextRange.empty,
      );
      _lastValidatedText = sanitized;
    }

    if (triggerHaptic && wasValid != _isLinkValid) {
      if (_isLinkValid) {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handleInvalidShareAttempt() {
    final input = _linkController.text.trim();
    if (input.isEmpty) {
      HapticFeedback.lightImpact();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_validationMessage ?? 'Invalid or unsupported link'),
        backgroundColor: AppTheme.colors.accentError,
        behavior: SnackBarBehavior.floating,
      ),
    );
    HapticFeedback.lightImpact();
  }

  Future<void> _handleShareLink() async {
    final input = _linkController.text.trim();
    if (input.isEmpty || _isSharingLink) {
      return;
    }

    setState(() => _isSharingLink = true);

    final validation = UrlValidator.validateAndSanitize(input);
    if (!validation.isValid) {
      _updateValidation(input, triggerHaptic: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.errorMessage ?? 'Invalid link'),
            backgroundColor: AppTheme.colors.accentError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _isSharingLink = false);
      return;
    }

    final target =
        '/process?link=${Uri.encodeComponent(validation.sanitizedUrl)}&mode=share';
    if (mounted) {
      context.push(target);
    }
    setState(() => _isSharingLink = false);
  }

  Widget _buildOpenAppButton(MusicService service) {
    return GestureDetector(
      onTap: () => _openMusicService(service),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.l,
          vertical: AppTheme.spacing.m,
        ),
        decoration: BoxDecoration(
          color: AppTheme.colors.glassBase,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTheme.colors.glassBorder, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo.music(service: service, size: 32),
            SizedBox(width: AppTheme.spacing.m),
            Text(
              'Open ${service.name}',
              style: AppTheme.typography.bodyLarge.copyWith(
                color: AppTheme.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: AppTheme.spacing.s),
            Icon(
              Icons.open_in_new,
              size: 18,
              color: AppTheme.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMusicService(MusicService service) async {
    HapticFeedback.lightImpact();

    // Try to open the app with its URL scheme
    final Uri appUri;

    switch (service) {
      case MusicService.spotify:
        appUri = Uri.parse('spotify://');
        break;
      case MusicService.appleMusic:
        appUri = Uri.parse('music://');
        break;
      case MusicService.tidal:
        appUri = Uri.parse('tidal://');
        break;
      case MusicService.youtubeMusic:
        appUri = Uri.parse('youtubemusic://');
        break;
      case MusicService.deezer:
        appUri = Uri.parse('deezer://');
        break;
      case MusicService.amazonMusic:
        appUri = Uri.parse('amznmp3://');
        break;
    }

    try {
      final canLaunch = await canLaunchUrl(appUri);
      if (canLaunch) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else {
        // If app is not installed, show a message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${service.name} is not installed'),
              backgroundColor: AppTheme.colors.backgroundCard,
            ),
          );
        }
      }
    } catch (e) {
      // Handle error silently or show message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${service.name}'),
            backgroundColor: AppTheme.colors.backgroundCard,
          ),
        );
      }
    }
  }
}
