import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/dynamic_theme.dart';
import '../../core/theme/dynamic_color_provider.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/unitune_logo.dart';
import '../../core/utils/link_encoder.dart';
import '../../data/models/history_entry.dart';
import '../../data/repositories/unitune_repository.dart';
import '../../data/repositories/link_cache_repository.dart';
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

      final musicService = ref.read(preferredMusicServiceProvider);

      // Check cache first
      final cached = await ref
          .read(linkCacheRepositoryProvider)
          .get(widget.incomingLink, musicService);

      if (cached != null && !cached.isExpired()) {
        debugPrint('=== Using cached link data ===');

        // Create response from cache
        final linksByPlatform = <String, PlatformLink>{};
        cached.convertedLinks.forEach((key, value) {
          linksByPlatform[key] = PlatformLink(url: value);
        });

        final response = UnituneResponse(
          title: cached.title,
          artistName: cached.artist,
          thumbnailUrl: cached.thumbnailUrl,
          linksByPlatform: linksByPlatform,
        );

        if (!mounted) return;

        // Get preferred messenger BEFORE setState to decide on flow
        final messenger = ref.read(preferredMessengerProvider);

        // For share mode: ALWAYS share directly, never show UI
        if (widget.mode == ProcessingMode.share) {
          debugPrint(
            '=== SHARE mode: Direct share (${messenger?.name ?? "system"}) ===',
          );
          // Keep loading state and share directly - NO UI shown
          _response = response;
          await _shareToMessenger();
          return;
        }

        // For open mode: check if music app is installed
        if (widget.mode == ProcessingMode.open) {
          final isInstalled = await _isMusicAppInstalled(musicService);
          if (isInstalled) {
            debugPrint(
              '=== Fast OPEN mode: Direct to music app (${musicService?.name ?? "default"}) ===',
            );
            // Keep loading state and open directly - NO UI shown
            _response = response;
            await _openInMusicApp();
            return;
          }
        }

        setState(() {
          _response = response;
          _statusMessage = widget.mode == ProcessingMode.share
              ? 'Ready to share!'
              : 'Opening in ${musicService?.name ?? "music app"}...';
          _isLoading = false;
        });

        // Short delay for UI
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          if (widget.mode == ProcessingMode.share) {
            await _shareToMessenger();
          } else {
            await _openInMusicApp();
          }
        }
        return;
      }

      // No cache - fetch from API
      if (!mounted) return;
      setState(() => _statusMessage = 'Converting link...');

      final response = await _unituneRepo.getLinks(widget.incomingLink);

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _error =
              'Unable to process this music link. Please check your internet connection and try again.';
          _isLoading = false;
        });
        return;
      }

      // Cache the response
      await _cacheResponse(response, musicService);

      // Get preferred messenger BEFORE setState to decide on flow
      final messenger = ref.read(preferredMessengerProvider);

      // For share mode: ALWAYS share directly, never show UI
      if (widget.mode == ProcessingMode.share) {
        debugPrint(
          '=== SHARE mode: Direct share (${messenger?.name ?? "system"}) ===',
        );
        // Keep loading state and share directly - NO UI shown
        _response = response;
        await _shareToMessenger();
        return;
      }

      // For open mode: check if music app is installed
      if (widget.mode == ProcessingMode.open) {
        final isInstalled = await _isMusicAppInstalled(musicService);
        if (isInstalled) {
          debugPrint(
            '=== Fast OPEN mode: Direct to music app (${musicService?.name ?? "default"}) ===',
          );
          // Keep loading state and open directly - NO UI shown
          _response = response;
          await _openInMusicApp();
          return;
        }
      }

      setState(() {
        _response = response;
        _statusMessage = widget.mode == ProcessingMode.share
            ? 'Ready to share!'
            : 'Opening in ${musicService?.name ?? "music app"}...';
        _isLoading = false;
      });

      // Short delay only for system share or open mode
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
      debugPrint('=== ProcessingScreen Error: $e ===');
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Cache the API response
  Future<void> _cacheResponse(
    UnituneResponse response,
    MusicService? musicService,
  ) async {
    try {
      final convertedLinks = <String, String>{};
      response.linksByPlatform.forEach((key, value) {
        convertedLinks[key] = value.url;
      });

      final cached = CachedLink(
        originalUrl: widget.incomingLink,
        musicService: musicService?.name ?? 'any',
        convertedLinks: convertedLinks,
        title: response.title,
        artist: response.artistName,
        thumbnailUrl: response.thumbnailUrl,
        cachedAt: DateTime.now(),
      );

      await ref.read(linkCacheRepositoryProvider).save(cached);
    } catch (e) {
      debugPrint('Error caching response: $e');
    }
  }

  /// Check if a music app is installed
  Future<bool> _isMusicAppInstalled(MusicService? musicService) async {
    if (musicService == null) return true; // Will use original link

    String urlScheme;
    switch (musicService) {
      case MusicService.spotify:
        urlScheme = 'spotify://';
        break;
      case MusicService.appleMusic:
        urlScheme = 'music://';
        break;
      case MusicService.tidal:
        urlScheme = 'tidal://';
        break;
      case MusicService.youtubeMusic:
        urlScheme = 'youtubemusic://';
        break;
      case MusicService.deezer:
        urlScheme = 'deezer://';
        break;
      case MusicService.amazonMusic:
        urlScheme = 'amznmp3://';
        break;
    }

    try {
      final uri = Uri.parse(urlScheme);
      return await canLaunchUrl(uri);
    } catch (e) {
      debugPrint('Error checking music app availability: $e');
      return false;
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
        HapticFeedback.mediumImpact();
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Save to history
        await _saveToHistory(HistoryType.shared, shareLink);

        // Invalidate statistics providers to refresh chart
        ref.invalidate(sharedHistoryProvider);

        // Close the processing screen after launching
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      } else {
        // App not installed - fallback to system share
        debugPrint('=== Messenger app not installed, using system share ===');
      }
    }

    // Fallback: use system share (no intermediate screen)
    if (mounted) {
      HapticFeedback.mediumImpact();
      // Save to history before sharing
      await _saveToHistory(HistoryType.shared, shareLink);

      // Invalidate statistics providers to refresh chart
      ref.invalidate(sharedHistoryProvider);

      // Use system share - AWAIT the async function
      await _showSystemShare(message);
    }
  }

  /// Show system share dialog
  Future<void> _showSystemShare(String message) async {
    try {
      debugPrint('=== Opening system share dialog ===');

      // Use share_plus to trigger native OS share dialog
      // IMPORTANT: Don't close the screen before sharing
      final result = await Share.share(
        message,
        subject: 'Check out this song on UniTune',
      );

      debugPrint('Share result: ${result.status}');
    } catch (e) {
      debugPrint('Error showing system share: $e');
    } finally {
      // Close processing screen after share dialog is dismissed
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _openInMusicApp() async {
    final response = _response;
    if (response == null) return;

    final musicService = ref.read(preferredMusicServiceProvider);

    debugPrint('=== _openInMusicApp: Opening music app ===');
    debugPrint('Preferred service: ${musicService?.name ?? "none"}');
    debugPrint('Original link: ${widget.incomingLink}');

    // If no preference set, open original link
    if (musicService == null) {
      debugPrint(
        'No preference set, opening original link: ${widget.incomingLink}',
      );
      final uri = Uri.parse(widget.incomingLink);

      // Check if app is available
      final canOpen = await canLaunchUrl(uri);
      if (canOpen) {
        HapticFeedback.mediumImpact();
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await _saveToHistory(HistoryType.received, null);

        // Invalidate statistics providers to refresh chart
        ref.invalidate(receivedHistoryProvider);

        if (mounted) Navigator.of(context).pop();
      } else {
        if (mounted) {
          setState(() {
            _error = 'Cannot open this link. Please install the music app.';
          });
        }
      }
      return;
    }

    // Get the link for the preferred service
    final targetUrl = response.getUrlForService(musicService);

    debugPrint('Target URL for ${musicService.name}: $targetUrl');

    if (targetUrl != null) {
      final uri = Uri.parse(targetUrl);

      // Check if the music app is installed
      final canOpen = await canLaunchUrl(uri);
      if (canOpen) {
        HapticFeedback.mediumImpact();
        debugPrint('Launching URL: $targetUrl');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await _saveToHistory(HistoryType.received, null);

        // Invalidate statistics providers to refresh chart
        ref.invalidate(receivedHistoryProvider);

        if (mounted) Navigator.of(context).pop();
      } else {
        // App not installed - show error
        debugPrint('ERROR: ${musicService.name} app not installed');
        if (mounted) {
          setState(() {
            _error =
                '${musicService.name} is not installed. Please install it or change your preferred music service in settings.';
          });
        }
      }
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
        // Animated UniTune Logo with pulsing effect
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.1),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: UniTuneLogo(size: 140, showText: false),
              ),
            );
          },
          onEnd: () {
            // Loop the animation
            if (mounted && _isLoading) {
              setState(() {});
            }
          },
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
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderArt(),
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
            onPressed: () {
              HapticFeedback.mediumImpact();
              _shareToMessenger();
            },
            icon: Icons.send,
          )
        else
          PrimaryButton(
            label:
                'Open in ${ref.read(preferredMusicServiceProvider)?.name ?? "Music App"}',
            onPressed: () {
              HapticFeedback.mediumImpact();
              _openInMusicApp();
            },
            icon: Icons.music_note,
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
