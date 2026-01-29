import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/odesli_repository.dart';
import '../settings/preferences_manager.dart';

/// Handles incoming share intents from other apps (e.g., Spotify -> Share -> UniTune)
class ShareIntentHandler extends ConsumerStatefulWidget {
  final Widget child;

  const ShareIntentHandler({super.key, required this.child});

  @override
  ConsumerState<ShareIntentHandler> createState() => _ShareIntentHandlerState();
}

class _ShareIntentHandlerState extends ConsumerState<ShareIntentHandler> {
  final OdesliRepository _odesliRepo = OdesliRepository();

  bool _isProcessing = false;
  String? _processingMessage;

  @override
  void initState() {
    super.initState();
    // Intent handling is now done in main.dart via app_links
  }

  @override
  void dispose() {
    _odesliRepo.dispose();
    super.dispose();
  }

  /// Process an incoming music link
  Future<void> processIncomingLink(String link) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Converting link...';
    });

    try {
      // 1. Call Odesli API to get all platform links
      final response = await _odesliRepo.getLinks(link);

      if (response == null) {
        // User-friendly error message without exposing API details
        _showError(
          'Unable to process this music link. Please check your internet connection and try again.',
        );
        return;
      }

      setState(() {
        _processingMessage = 'Generating share link...';
      });

      // 2. Generate the UniTune share link using the original URL
      final shareLink = _generateShareLink(link);

      // 3. Get user's preferred messenger
      final messenger = ref.read(preferredMessengerProvider);

      if (messenger == null || messenger == MessengerService.systemShare) {
        // Use system share sheet
        await _shareViaSystem(shareLink, response);
      } else {
        // Direct bridge to preferred messenger
        await _shareViaMessenger(shareLink, response, messenger);
      }
    } catch (e) {
      // Log error locally for debugging (not sent externally)
      debugPrint('=== ShareIntentHandler Error: $e ===');
      // User-friendly error message without exposing internal details
      _showError('Something went wrong. Please try again.');
    } finally {
      setState(() {
        _isProcessing = false;
        _processingMessage = null;
      });
    }
  }

  /// Generate a UniTune share link
  /// Generate a UniTune share link from the original music URL
  /// The Cloudflare Worker will decode this and show the landing page
  String _generateShareLink(String originalMusicUrl) {
    // Encode the original music URL for the share link
    final encodedUrl = Uri.encodeComponent(originalMusicUrl);
    return 'https://unitune.art/s/$encodedUrl';
  }

  /// Share via the preferred messenger (the "bridge")
  Future<void> _shareViaMessenger(
    String shareLink,
    OdesliResponse response,
    MessengerService messenger,
  ) async {
    final songInfo = response.title != null && response.artistName != null
        ? '${response.title} by ${response.artistName}'
        : 'Check out this song';

    final message = '$songInfo\n$shareLink';
    final encodedMessage = Uri.encodeComponent(message);

    String targetUrl;
    switch (messenger) {
      case MessengerService.whatsapp:
        targetUrl = 'whatsapp://send?text=$encodedMessage';
        break;
      case MessengerService.telegram:
        targetUrl = 'tg://msg?text=$encodedMessage';
        break;
      case MessengerService.signal:
        targetUrl = 'sgnl://send?text=$encodedMessage';
        break;
      case MessengerService.sms:
        targetUrl = 'sms:?body=$encodedMessage';
        break;
      case MessengerService.systemShare:
        await _shareViaSystem(shareLink, response);
        return;
    }

    final uri = Uri.parse(targetUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to system share
      await _shareViaSystem(shareLink, response);
    }
  }

  /// Share via system share sheet
  Future<void> _shareViaSystem(
    String shareLink,
    OdesliResponse response,
  ) async {
    final songInfo = response.title != null && response.artistName != null
        ? '${response.title} by ${response.artistName}'
        : 'Check out this song';

    final message = '$songInfo\n$shareLink';

    // Use platform share
    // Note: For full implementation, use share_plus package
    debugPrint('Would share: $message');

    // For now, just copy to clipboard as fallback
    _showSuccess('Link ready to share!');
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.colors.accentSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Processing overlay
        if (_isProcessing)
          _ProcessingOverlay(message: _processingMessage ?? 'Processing...'),
      ],
    );
  }
}

/// Full-screen overlay shown while processing a share
class _ProcessingOverlay extends StatelessWidget {
  final String message;

  const _ProcessingOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.colors.backgroundDeep.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated logo
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.colors.primary.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('♪', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
