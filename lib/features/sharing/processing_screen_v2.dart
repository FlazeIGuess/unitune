import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/album_art_with_glow.dart';
import '../../core/widgets/service_button.dart';
import '../../core/utils/motion_sensitivity.dart';
import '../../core/utils/link_encoder.dart';
import '../../data/repositories/unitune_repository.dart';
import '../../main.dart' show ProcessingMode;
import '../settings/preferences_manager.dart';

/// Processing Screen V2 - "Immersive Spotlight" Design
/// Matches the Cloudflare Worker landing page aesthetic
class ProcessingScreenV2 extends ConsumerStatefulWidget {
  final String incomingLink;
  final ProcessingMode mode;

  const ProcessingScreenV2({
    super.key,
    required this.incomingLink,
    required this.mode,
  });

  @override
  ConsumerState<ProcessingScreenV2> createState() => _ProcessingScreenV2State();
}

class _ProcessingScreenV2State extends ConsumerState<ProcessingScreenV2>
    with SingleTickerProviderStateMixin {
  final UnituneRepository _unituneRepo = UnituneRepository();

  bool _isLoading = true;
  String _statusMessage = 'Analyzing link...';
  UnituneResponse? _response;
  String? _error;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _processLink();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _unituneRepo.dispose();
    super.dispose();
  }

  Future<void> _processLink() async {
    try {
      debugPrint('=== ProcessingScreenV2: Processing link ===');
      debugPrint('Mode: ${widget.mode}');
      debugPrint('Link: ${widget.incomingLink}');

      if (!mounted) return;
      setState(() => _statusMessage = 'Converting link...');

      final response = await _unituneRepo.getLinks(widget.incomingLink);

      if (!mounted) return;

      if (response == null) {
        // User-friendly error message without exposing API details
        setState(() {
          _error =
              'Unable to process this music link. Please check your internet connection and try again.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _response = response;
        _statusMessage = widget.mode == ProcessingMode.share
            ? 'Ready to share!'
            : 'Opening...';
        _isLoading = false;
      });

      // Trigger fade-in animation
      _fadeController.forward();

      // Auto-forward after delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        if (widget.mode == ProcessingMode.share) {
          await _shareToMessenger();
        } else {
          await _openInMusicApp();
        }
      }
    } catch (e) {
      // Log error locally for debugging (not sent externally)
      debugPrint('=== ProcessingScreenV2 Error: $e ===');
      if (!mounted) return;
      setState(() {
        // User-friendly error message without exposing internal details
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _shareToMessenger() async {
    final response = _response;
    if (response == null) return;

    final messenger = ref.read(preferredMessengerProvider);
    final shareLink = _generateShareLink(response);

    final songInfo = response.title != null && response.artistName != null
        ? '${response.title} by ${response.artistName}'
        : 'Check out this song';

    final message = '$songInfo\n$shareLink';
    final encodedMessage = Uri.encodeComponent(message);

    String? launchUrlString;
    switch (messenger) {
      case MessengerService.whatsapp:
        launchUrlString = 'whatsapp://send?text=$encodedMessage';
        break;
      case MessengerService.telegram:
        launchUrlString = 'tg://msg?text=$encodedMessage';
        break;
      case MessengerService.signal:
        launchUrlString = 'sgnl://send?text=$encodedMessage';
        break;
      case MessengerService.sms:
        launchUrlString = 'sms:?body=$encodedMessage';
        break;
      case MessengerService.systemShare:
      case null:
        launchUrlString = null;
        break;
    }

    if (launchUrlString != null) {
      final uri = Uri.parse(launchUrlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) Navigator.of(context).pop();
        return;
      }
    }

    if (mounted) _showServiceSheet();
  }

  Future<void> _openInMusicApp() async {
    final response = _response;
    if (response == null) return;

    final musicService = ref.read(preferredMusicServiceProvider);

    if (musicService == null) {
      final uri = Uri.parse(widget.incomingLink);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final targetUrl = response.getUrlForService(musicService);

    if (targetUrl != null) {
      final uri = Uri.parse(targetUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.of(context).pop();
    } else {
      if (mounted) {
        setState(() {
          _error = 'Song not available on ${musicService.name}';
        });
      }
    }
  }

  String _generateShareLink(UnituneResponse response) {
    return UniTuneLinkEncoder.createShareLinkFromUrl(widget.incomingLink);
  }

  void _showServiceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ServiceSheet(
        response: _response!,
        shareLink: _generateShareLink(_response!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 24),
                        color: AppTheme.colors.textSecondary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Spacer(),

                    // Content
                    if (_isLoading)
                      _buildLoadingState()
                    else if (_error != null)
                      _buildErrorState()
                    else
                      _buildResultState(),

                    const Spacer(),

                    // Footer
                    _buildFooter(),
                    SizedBox(height: AppTheme.spacing.m),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated loading indicator
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AppTheme.colors.primary),
          ),
        ),
        SizedBox(height: AppTheme.spacing.xxl),
        Text(
          _statusMessage,
          style: AppTheme.typography.titleLarge.copyWith(
            color: AppTheme.colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildShareButton(UnituneResponse response) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => _showServiceSheet(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.colors.primary,
            foregroundColor: AppTheme.colors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.pill),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share, size: 20),
              SizedBox(width: AppTheme.spacing.s),
              Text(
                'Share',
                style: AppTheme.typography.labelLarge.copyWith(
                  color: AppTheme.colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultState() {
    final response = _response!;

    // Check if animations should be shown based on reduce-motion setting
    final shouldAnimate = MotionSensitivity.shouldAnimate(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Album art with glow effect - prominently displayed
        AlbumArtWithGlow(imageUrl: response.thumbnailUrl, size: 240),

        SizedBox(height: AppTheme.spacing.xxl),

        // Song info with proper typography hierarchy
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Song title with display typography
              Text(
                response.title ?? 'Unknown Song',
                style: AppTheme.typography.displayMedium.copyWith(
                  color: AppTheme.colors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppTheme.spacing.s),
              // Artist name with title typography
              Text(
                response.artistName ?? 'Unknown Artist',
                style: AppTheme.typography.titleLarge.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        SizedBox(height: AppTheme.spacing.xxl),

        // "Available on:" label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Available on:',
              style: AppTheme.typography.labelLarge.copyWith(
                color: AppTheme.colors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        SizedBox(height: AppTheme.spacing.m),

        // Service list with staggered animation
        _buildServiceList(response),

        SizedBox(height: AppTheme.spacing.xxl),

        // Share button at bottom
        _buildShareButton(response),
      ],
    );

    // Return with or without fade animation based on reduce-motion setting
    return shouldAnimate
        ? FadeTransition(opacity: _fadeAnimation, child: content)
        : content;
  }

  Widget _buildServiceList(UnituneResponse response) {
    // Build list of available services
    final services = [
      (
        MusicService.spotify,
        Icons.music_note,
        'Spotify',
        AppTheme.colors.spotify,
      ),
      (
        MusicService.appleMusic,
        Icons.music_note,
        'Apple Music',
        AppTheme.colors.appleMusic,
      ),
      (MusicService.tidal, Icons.music_note, 'TIDAL', AppTheme.colors.tidal),
      (
        MusicService.youtubeMusic,
        Icons.play_circle_filled,
        'YouTube Music',
        AppTheme.colors.youtubeMusic,
      ),
    ];

    final availableServices = <Widget>[];
    int index = 0;

    for (final (service, icon, name, color) in services) {
      final url = response.getUrlForService(service);
      if (url != null) {
        // Staggered animation: each service appears with a delay
        final delay = index * 100; // 100ms delay between each
        availableServices.add(
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + delay),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: ServiceButton(
              serviceName: name,
              icon: icon,
              accentColor: color,
              actionLabel: 'Play',
              onTap: () async {
                final uri = Uri.parse(url);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ),
        );
        index++;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          for (int i = 0; i < availableServices.length; i++) ...[
            availableServices[i],
            if (i < availableServices.length - 1)
              SizedBox(height: AppTheme.spacing.s),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('⚠️', style: TextStyle(fontSize: 64)),
        SizedBox(height: AppTheme.spacing.l),
        Text(
          _error ?? 'Something went wrong',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'UniTune',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 13,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            '•',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
        ),
        Text(
          'Privacy',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet with service options
class _ServiceSheet extends StatelessWidget {
  final UnituneResponse response;
  final String shareLink;

  const _ServiceSheet({required this.response, required this.shareLink});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.colors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Share to...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.colors.textPrimary,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 24),

            // Service options
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: MessengerService.values
                  .where((m) => m != MessengerService.systemShare)
                  .map(
                    (m) => _ShareOption(
                      messenger: m,
                      message:
                          '${response.title ?? "Check out this song"}\n$shareLink',
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final MessengerService messenger;
  final String message;

  const _ShareOption({required this.messenger, required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final encodedMessage = Uri.encodeComponent(message);
        String launchUrlString;

        switch (messenger) {
          case MessengerService.whatsapp:
            launchUrlString = 'whatsapp://send?text=$encodedMessage';
            break;
          case MessengerService.telegram:
            launchUrlString = 'tg://msg?text=$encodedMessage';
            break;
          case MessengerService.signal:
            launchUrlString = 'sgnl://send?text=$encodedMessage';
            break;
          case MessengerService.sms:
            launchUrlString = 'sms:?body=$encodedMessage';
            break;
          case MessengerService.systemShare:
            return;
        }

        final uri = Uri.parse(launchUrlString);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Color(messenger.color).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(messenger.icon, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            messenger.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
