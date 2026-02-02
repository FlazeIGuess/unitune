import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/dynamic_theme.dart';
import '../../core/theme/dynamic_color_provider.dart';
import '../../core/widgets/liquid_glass_sphere.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/utils/link_encoder.dart';
import '../../data/models/history_entry.dart';
import '../../data/repositories/unitune_repository.dart';
import '../../main.dart' show ProcessingMode;
import '../settings/preferences_manager.dart';

/// Screen shown when processing an incoming share or opening a shared link
/// Modern dark mode design with Liquid Glass sphere
class ProcessingScreen extends ConsumerStatefulWidget {
  final String incomingLink;
  final ProcessingMode mode;

  const ProcessingScreen({
    super.key,
    required this.incomingLink,
    required this.mode,
  });

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  final UnituneRepository _unituneRepo = UnituneRepository();

  bool _isLoading = true;
  String _statusMessage = 'Analyzing link...';
  UnituneResponse? _response;
  String? _error;

  @override
  void initState() {
    super.initState();
    _processLink();
  }

  @override
  void dispose() {
    _unituneRepo.dispose();
    super.dispose();
  }

  Future<void> _processLink() async {
    try {
      debugPrint('=== ProcessingScreen: Starting to process link ===');
      debugPrint('Mode: ${widget.mode}');
      debugPrint('Incoming link: ${widget.incomingLink}');

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

      // Get preferred messenger BEFORE setState to decide on flow
      final messenger = ref.read(preferredMessengerProvider);
      final hasPreferredMessenger =
          messenger != null && messenger != MessengerService.systemShare;

      // For share mode with preferred messenger: skip UI update and share directly
      if (widget.mode == ProcessingMode.share && hasPreferredMessenger) {
        debugPrint(
          '=== Fast SHARE mode: Direct to messenger (${messenger.name}) ===',
        );
        setState(() {
          _response = response;
          _statusMessage = 'Sharing...';
          _isLoading = false;
        });
        // No delay - share immediately
        if (mounted) {
          await _shareToMessenger();
        }
        return;
      }

      setState(() {
        _response = response;
        // Update status based on mode
        _statusMessage = widget.mode == ProcessingMode.share
            ? 'Ready to share!'
            : 'Opening in ${ref.read(preferredMusicServiceProvider)?.name ?? "music app"}...';
        _isLoading = false;
      });

      // Short delay only for system share or open mode (allows UI to render)
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        if (widget.mode == ProcessingMode.share) {
          debugPrint(
            '=== Executing SHARE mode: Creating new unitune.art link ===',
          );
          await _shareToMessenger();
        } else {
          debugPrint(
            '=== Executing OPEN mode: Opening directly in music app ===',
          );
          await _openInMusicApp();
        }
      }
    } catch (e) {
      // Log error locally for debugging (not sent externally)
      debugPrint('=== ProcessingScreen Error: $e ===');
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
        // Will use system share
        launchUrlString = null;
        break;
    }

    if (launchUrlString != null) {
      final uri = Uri.parse(launchUrlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Save to history
        await _saveToHistory(HistoryType.shared, shareLink);

        // Close the processing screen after launching
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
    }

    // Fallback: show manual share options
    if (mounted) {
      _showShareSheet();
    }
  }

  Future<void> _openInMusicApp() async {
    final response = _response;
    if (response == null) return;

    final musicService = ref.read(preferredMusicServiceProvider);

    debugPrint('=== _openInMusicApp: Opening music app ===');
    debugPrint('Preferred service: ${musicService?.name ?? "none"}');
    debugPrint('Original link: ${widget.incomingLink}');

    // If no preference set, show error or ask user (for now, use system default via browser)
    if (musicService == null) {
      // Just open the original link if no service preferred
      debugPrint(
        'No preference set, opening original link: ${widget.incomingLink}',
      );
      final uri = Uri.parse(widget.incomingLink);
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Save to history as received
      await _saveToHistory(HistoryType.received, null);

      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Get the link for the preferred service
    final targetUrl = response.getUrlForService(musicService);

    debugPrint('Target URL for ${musicService.name}: $targetUrl');

    if (targetUrl != null) {
      final uri = Uri.parse(targetUrl);
      // Launch in external app (Spotify, Tidal, etc.)
      debugPrint('Launching URL: $targetUrl');
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Save to history as received
      await _saveToHistory(HistoryType.received, null);

      if (mounted) Navigator.of(context).pop();
    } else {
      // Service link not found for this song
      debugPrint('ERROR: Song not available on ${musicService.name}');
      if (mounted) {
        setState(() {
          _error = 'Song not available on ${musicService.name}';
        });
      }
    }
  }

  /// Save the current song to history
  Future<void> _saveToHistory(HistoryType type, String? uniTuneUrl) async {
    final response = _response;
    if (response == null) return;

    try {
      final entry = HistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: response.title ?? 'Unknown Song',
        artist: response.artistName ?? 'Unknown Artist',
        thumbnailUrl: response.thumbnailUrl,
        originalUrl: widget.incomingLink,
        uniTuneUrl: uniTuneUrl,
        type: type,
        timestamp: DateTime.now(),
      );

      await ref.read(historyRepositoryProvider).add(entry);

      // Invalidate providers to refresh history screens
      ref.invalidate(sharedHistoryProvider);
      ref.invalidate(receivedHistoryProvider);

      // Extract and update dynamic app colors from album artwork
      // Only update colors when sharing (not receiving)
      if (type == HistoryType.shared && response.thumbnailUrl != null) {
        debugPrint('=== DYNAMIC COLOR UPDATE START ===');
        debugPrint(
          'Updating app colors from album artwork: ${response.thumbnailUrl}',
        );
        await ref
            .read(dynamicColorProvider.notifier)
            .updateFromArtwork(response.thumbnailUrl);
        debugPrint('=== DYNAMIC COLOR UPDATE COMPLETE ===');
      } else {
        debugPrint(
          'Skipping color update: type=$type, thumbnailUrl=${response.thumbnailUrl}',
        );
      }

      debugPrint('Saved to history: ${entry.title} (${type.name})');
    } catch (e) {
      debugPrint('Error saving to history: $e');
    }
  }

  String _generateShareLink(UnituneResponse response) {
    return UniTuneLinkEncoder.createShareLinkFromUrl(widget.incomingLink);
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.colors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ShareOptionsSheet(
        response: _response!,
        shareLink: _generateShareLink(_response!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        color: AppTheme.colors.textSecondary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Spacer(),
                    // Content
                    if (_isLoading)
                      _buildLoadingState()
                    else
                      _buildResultState(),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated Liquid Glass sphere
        LiquidGlassSphere(
          size: 140,
          child: Text(
            '♪',
            style: TextStyle(fontSize: 64, color: AppTheme.colors.textPrimary),
          ),
        ),
        SizedBox(height: AppTheme.spacing.xl),
        Text(
          _statusMessage,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResultState() {
    if (_error != null) {
      return _buildErrorState();
    }

    final response = _response;
    if (response == null) {
      return _buildErrorState();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Album art
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radii.large),
            boxShadow: AppTheme.glowMedium(context.primaryColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radii.large),
            child: response.thumbnailUrl != null
                ? Image.network(
                    response.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderArt(),
                  )
                : _buildPlaceholderArt(),
          ),
        ),
        SizedBox(height: AppTheme.spacing.xl),
        // Song title
        Text(
          response.title ?? 'Unknown Song',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: AppTheme.spacing.s),
        // Artist
        Text(
          response.artistName ?? 'Unknown Artist',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.colors.textSecondary),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: AppTheme.spacing.xl),
        // Primary action button
        if (widget.mode == ProcessingMode.share)
          PrimaryButton(
            label:
                'Share via ${ref.read(preferredMessengerProvider)?.name ?? "Messenger"}',
            onPressed: _shareToMessenger,
            icon: Icons.send,
          )
        else
          PrimaryButton(
            label:
                'Open in ${ref.read(preferredMusicServiceProvider)?.name ?? "Music App"}',
            onPressed: _openInMusicApp,
            icon: Icons.music_note,
          ),
        SizedBox(height: AppTheme.spacing.m),
        // Alternative action
        TextButton(
          onPressed: _showShareSheet,
          child: Text(
            'More options',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      color: AppTheme.colors.backgroundCard,
      child: const Center(child: Text('♪', style: TextStyle(fontSize: 64))),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
        const SizedBox(height: 24),
        Text(
          _error ?? 'Something went wrong',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Bottom sheet with share options for different messengers
class _ShareOptionsSheet extends StatelessWidget {
  final UnituneResponse response;
  final String shareLink;

  const _ShareOptionsSheet({required this.response, required this.shareLink});

  @override
  Widget build(BuildContext context) {
    final songInfo = response.title != null && response.artistName != null
        ? '${response.title} by ${response.artistName}'
        : 'Check out this song';
    final message = '$songInfo\n$shareLink';

    return Padding(
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
          Text('Share to...', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          // Messenger options
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: MessengerService.values
                .where((m) => m != MessengerService.systemShare)
                .map(
                  (messenger) =>
                      _ShareOption(messenger: messenger, message: message),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
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
          if (context.mounted) {
            Navigator.of(context).pop();
          }
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
