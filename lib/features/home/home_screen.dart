import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math' as math;
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

  // Random service rotation for when no songs received
  Timer? _serviceRotationTimer;
  int _currentRandomServiceIndex = 0;
  final _random = math.Random();

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
    _startServiceRotation();
  }

  @override
  void dispose() {
    _serviceRotationTimer?.cancel();
    _fadeController.dispose();
    _linkController.dispose();
    _linkFocusNode.dispose();
    super.dispose();
  }

  /// Start rotating through random services every 3 seconds
  void _startServiceRotation() {
    _serviceRotationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _currentRandomServiceIndex = _random.nextInt(
            MusicService.values.length,
          );
        });
      }
    });
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
    final mostReceivedServiceAsync = ref.watch(_mostReceivedServiceProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // Invalidate providers to reload data
        ref.invalidate(statisticsProvider);
        ref.invalidate(chartDataProvider);
        ref.invalidate(receivedStatisticsProvider);
        ref.invalidate(receivedChartDataProvider);
        ref.invalidate(_mostReceivedServiceProvider);

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

            // Welcome greeting
            _buildWelcomeGreeting(),
            SizedBox(height: AppTheme.spacing.m),

            // Statistics Card
            const StatisticsCard(),
            SizedBox(height: AppTheme.spacing.l),

            _buildPasteToShareCard(context),
            SizedBox(height: AppTheme.spacing.l),

            // Instructions Card
            mostReceivedServiceAsync.when(
              data: (mostReceivedService) => _buildInstructionsCard(
                context,
                preferredService,
                mostReceivedService,
              ),
              loading: () =>
                  _buildInstructionsCard(context, preferredService, null),
              error: (_, __) =>
                  _buildInstructionsCard(context, preferredService, null),
            ),

            // Bottom padding for navigation
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeGreeting() {
    final nickname = ref.watch(userNicknameProvider);
    final displayName = (nickname != null && nickname.trim().isNotEmpty)
        ? nickname.trim()
        : 'User';

    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTheme.typography.titleLarge.copyWith(
                color: AppTheme.colors.textPrimary,
                fontFamily: 'ZalandoSansExpanded',
              ),
              children: [
                const TextSpan(text: 'Welcome, '),
                TextSpan(
                  text: displayName,
                  style: AppTheme.typography.titleLarge.copyWith(
                    color: context.primaryColor,
                    fontFamily: 'ZalandoSansExpanded',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          color: AppTheme.colors.textMuted,
          tooltip: 'Edit nickname',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showNicknameEditDialog();
          },
        ),
      ],
    );
  }

  Future<void> _showNicknameEditDialog() async {
    final currentNickname = ref.read(userNicknameProvider) ?? '';
    await showDialog<void>(
      context: context,
      builder: (ctx) => _NicknameEditDialog(
        initialNickname: currentNickname,
        onSave: (newValue) async {
          await ref
              .read(preferencesManagerProvider)
              .setUserNickname(newValue.isEmpty ? null : newValue);
          ref.read(userNicknameProvider.notifier).state = newValue.isEmpty
              ? null
              : newValue;
        },
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
            'Convert any music link',
            style: AppTheme.typography.titleMedium.copyWith(
              color: AppTheme.colors.textPrimary,
              fontFamily: 'ZalandoSansExpanded',
            ),
          ),
          SizedBox(height: AppTheme.spacing.s),
          Text(
            'Works with Spotify, Apple Music, Tidal, YouTube Music, Deezer & Amazon Music',
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

  Widget _buildInstructionsCard(
    BuildContext context,
    MusicService? preferredService,
    MusicService? mostReceivedService,
  ) {
    // Determine which service to show for "Friend uses..."
    final friendService =
        mostReceivedService ?? MusicService.values[_currentRandomServiceIndex];

    // Determine which service to show for "you use..."
    final yourService = preferredService ?? MusicService.spotify;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppTheme.spacing.l),
      decoration: BoxDecoration(
        color: AppTheme.colors.glassBase,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.colors.glassBorder, width: 1.0),
      ),
      child: Column(
        children: [
          Icon(Icons.share, size: 48, color: context.primaryColor),
          SizedBox(height: AppTheme.spacing.m),

          // Dynamic text with service names
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Friend uses ',
                style: AppTheme.typography.titleMedium.copyWith(
                  color: AppTheme.colors.textPrimary,
                  fontFamily: 'ZalandoSansExpanded',
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  friendService.name,
                  key: ValueKey(friendService),
                  style: AppTheme.typography.titleMedium.copyWith(
                    color: context.primaryColor,
                    fontFamily: 'ZalandoSansExpanded',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                ',',
                style: AppTheme.typography.titleMedium.copyWith(
                  color: AppTheme.colors.textPrimary,
                  fontFamily: 'ZalandoSansExpanded',
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'but you use ',
                style: AppTheme.typography.titleMedium.copyWith(
                  color: AppTheme.colors.textPrimary,
                  fontFamily: 'ZalandoSansExpanded',
                ),
              ),
              Text(
                yourService.name,
                style: AppTheme.typography.titleMedium.copyWith(
                  color: context.primaryColor,
                  fontFamily: 'ZalandoSansExpanded',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '?',
                style: AppTheme.typography.titleMedium.copyWith(
                  color: AppTheme.colors.textPrimary,
                  fontFamily: 'ZalandoSansExpanded',
                ),
              ),
            ],
          ),

          SizedBox(height: AppTheme.spacing.s),
          Text(
            'Share songs that work for everyone',
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

/// Provider for most received streaming service
final _mostReceivedServiceProvider = FutureProvider<MusicService?>((ref) async {
  final repository = ref.watch(historyRepositoryProvider);
  final received = await repository.getReceived();

  if (received.isEmpty) {
    return null;
  }

  // Helper function to extract service from URL
  MusicService? extractService(String url) {
    final lowerUrl = url.toLowerCase();

    if (lowerUrl.contains('spotify')) {
      return MusicService.spotify;
    } else if (lowerUrl.contains('apple') || lowerUrl.contains('music.apple')) {
      return MusicService.appleMusic;
    } else if (lowerUrl.contains('tidal')) {
      return MusicService.tidal;
    } else if (lowerUrl.contains('youtube')) {
      return MusicService.youtubeMusic;
    } else if (lowerUrl.contains('deezer')) {
      return MusicService.deezer;
    } else if (lowerUrl.contains('amazon')) {
      return MusicService.amazonMusic;
    }

    return null;
  }

  // Count services
  final serviceCounts = <MusicService, int>{};
  for (final entry in received) {
    final service = extractService(entry.originalUrl);
    if (service != null) {
      serviceCounts[service] = (serviceCounts[service] ?? 0) + 1;
    }
  }

  if (serviceCounts.isEmpty) {
    return null;
  }

  // Find most common
  var mostCommon = serviceCounts.entries.first;
  for (final entry in serviceCounts.entries) {
    if (entry.value > mostCommon.value) {
      mostCommon = entry;
    }
  }

  return mostCommon.key;
});

/// Dialog for editing the user nickname.
/// Owns its own [TextEditingController] so it is disposed via [State.dispose]
/// after the close animation completes — never while the widget tree is still
/// alive.
class _NicknameEditDialog extends StatefulWidget {
  final String initialNickname;
  final Future<void> Function(String newValue) onSave;

  const _NicknameEditDialog({
    required this.initialNickname,
    required this.onSave,
  });

  @override
  State<_NicknameEditDialog> createState() => _NicknameEditDialogState();
}

class _NicknameEditDialogState extends State<_NicknameEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNickname);
  }

  @override
  void dispose() {
    // Disposed by the framework AFTER the dialog's exit animation completes.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.colors.backgroundDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radii.large),
        side: BorderSide(color: AppTheme.colors.glassBorder, width: 1),
      ),
      title: Text(
        'Your Nickname',
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
            'Shown to friends when you share songs.',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textMuted,
            ),
          ),
          SizedBox(height: AppTheme.spacing.m),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 20,
            style: AppTheme.typography.bodyLarge.copyWith(
              color: AppTheme.colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Alex',
              hintStyle: AppTheme.typography.bodyLarge.copyWith(
                color: AppTheme.colors.textMuted,
              ),
              counterStyle: AppTheme.typography.labelMedium.copyWith(
                color: AppTheme.colors.textMuted,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radii.medium),
                borderSide: BorderSide(color: AppTheme.colors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radii.medium),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppTheme.colors.glassBase,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppTheme.typography.labelLarge.copyWith(
              color: AppTheme.colors.textMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            final newValue = _controller.text.trim();
            await widget.onSave(newValue);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(
            'Save',
            style: AppTheme.typography.labelLarge.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
