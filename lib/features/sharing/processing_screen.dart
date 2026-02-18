import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/dynamic_theme.dart';
import '../../core/theme/dynamic_color_provider.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/unitune_logo.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/widgets/service_button.dart';
import '../../core/widgets/optimized_liquid_glass.dart';
import '../../core/utils/link_encoder.dart';
import '../../data/models/history_entry.dart';
import '../../data/models/music_content_type.dart';
import '../../data/repositories/unitune_repository.dart';
import '../../data/repositories/link_cache_repository.dart';
import '../../main.dart' show ProcessingMode;
import '../settings/preferences_manager.dart';

/// Dynamic messages for processing states
class ProcessingMessages {
  static const List<String> analyzing = [
    'Reading music link...',
    'Identifying song details...',
    'Checking platform compatibility...',
  ];

  static const List<String> converting = [
    'Searching across 6 music platforms...',
    'Finding your song everywhere...',
    'Creating universal share link...',
  ];

  static const List<String> success = [
    'Found on {count} platforms!',
    'Ready to share with anyone!',
    'Your universal link is ready!',
  ];

  static String getRandomMessage(List<String> messages) {
    return messages[DateTime.now().millisecond % messages.length];
  }

  static String getSuccessMessage(int platformCount) {
    final msg = success[DateTime.now().millisecond % success.length];
    return msg.replaceAll('{count}', platformCount.toString());
  }
}

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
  String _statusMessage = 'Reading music link...';
  UnituneResponse? _response;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('=== ProcessingScreen.initState() called ===');
    debugPrint('Incoming link: ${widget.incomingLink}');
    debugPrint('Mode: ${widget.mode}');
    debugPrint('Timestamp: ${DateTime.now().millisecondsSinceEpoch}');
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
          contentType: cached.contentType,
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
          final platformCount = response.linksByPlatform.length;
          _statusMessage = ProcessingMessages.getSuccessMessage(platformCount);
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
      setState(
        () => _statusMessage = ProcessingMessages.getRandomMessage(
          ProcessingMessages.converting,
        ),
      );

      debugPrint('=== Calling API: ${widget.incomingLink} ===');
      final response = await _unituneRepo.getLinks(widget.incomingLink);
      debugPrint(
        '=== API call completed, response: ${response != null ? "SUCCESS" : "NULL"} ===',
      );

      // IMPORTANT: Set response BEFORE checking mounted
      if (response != null) {
        _response = response;
      }

      debugPrint('=== Checking mounted state: $mounted ===');
      if (!mounted) {
        debugPrint(
          '=== Widget unmounted, but continuing with music app launch ===',
        );
        // Don't return early - we can still launch the music app
      }

      if (response == null) {
        debugPrint('=== API returned null, showing error ===');
        if (mounted) {
          setState(() {
            _error =
                'Unable to process this music link. Please check your internet connection and try again.';
            _isLoading = false;
          });
        }
        return;
      }

      debugPrint(
        '=== Response received, title: ${response.title}, artist: ${response.artistName} ===',
      );
      debugPrint(
        '=== Available platforms: ${response.linksByPlatform.keys.join(", ")} ===',
      );

      // Cache the response
      debugPrint('=== Starting cache operation ===');
      try {
        await _cacheResponse(response, musicService);
        debugPrint('=== Cache operation completed ===');
      } catch (e) {
        debugPrint('=== Cache operation failed: $e ===');
        // Continue even if caching fails
      }

      debugPrint('=== Reading preferred messenger ===');
      // Get preferred messenger - handle disposed widget
      MessengerService? messenger;
      try {
        messenger = ref.read(preferredMessengerProvider);
        debugPrint('=== Preferred messenger: ${messenger?.name ?? "null"} ===');
      } catch (e) {
        debugPrint(
          '=== Cannot read messenger (widget disposed), using null ===',
        );
        messenger = null;
      }

      // For share mode: ALWAYS share directly, never show UI
      if (widget.mode == ProcessingMode.share) {
        debugPrint(
          '=== SHARE mode: Direct share (${messenger?.name ?? "system"}) ===',
        );
        // Keep loading state and share directly - NO UI shown
        _response = response;
        debugPrint('=== Calling _shareToMessenger ===');
        await _shareToMessenger();
        debugPrint('=== _shareToMessenger completed ===');
        return;
      }

      // For open mode: check if music app is installed
      if (widget.mode == ProcessingMode.open) {
        debugPrint('=== OPEN mode: Checking if music app is installed ===');
        final isInstalled = await _isMusicAppInstalled(musicService);
        debugPrint('=== Music app installed: $isInstalled ===');
        if (isInstalled) {
          debugPrint(
            '=== Fast OPEN mode: Direct to music app (${musicService?.name ?? "default"}) ===',
          );
          // Keep loading state and open directly - NO UI shown
          _response = response;
          debugPrint('=== Calling _openInMusicApp ===');
          await _openInMusicApp();
          debugPrint('=== _openInMusicApp completed ===');
          return;
        }
      }

      setState(() {
        _response = response;
        final platformCount = response.linksByPlatform.length;
        _statusMessage = ProcessingMessages.getSuccessMessage(platformCount);
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
        contentType: response.contentType,
        thumbnailUrl: response.thumbnailUrl,
        cachedAt: DateTime.now(),
      );

      // Don't use ref if widget is disposed
      try {
        await ref.read(linkCacheRepositoryProvider).save(cached);
      } catch (e) {
        debugPrint('Cannot access ref (widget disposed): $e');
        // Can't cache if widget is disposed, but that's okay
      }
    } catch (e) {
      debugPrint('Error caching response: $e');
    }
  }

  /// Check if a music app is installed
  Future<bool> _isMusicAppInstalled(MusicService? musicService) async {
    debugPrint('=== _isMusicAppInstalled START ===');
    debugPrint('Checking for service: ${musicService?.name ?? "null"}');

    if (musicService == null) {
      debugPrint('=== Service is null, returning true ===');
      return true; // Will use original link
    }

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
      debugPrint('=== Checking URL scheme: $urlScheme ===');
      final uri = Uri.parse(urlScheme);
      final result = await canLaunchUrl(uri);
      debugPrint('=== canLaunchUrl result: $result ===');
      debugPrint('=== _isMusicAppInstalled END ===');
      return result;
    } catch (e) {
      debugPrint('=== ERROR in _isMusicAppInstalled: $e ===');
      debugPrint('=== _isMusicAppInstalled END (error) ===');
      return false;
    }
  }

  Future<void> _shareToMessenger() async {
    debugPrint('=== _shareToMessenger START ===');
    final response = _response;
    if (response == null) {
      debugPrint('=== _shareToMessenger: response is null, returning ===');
      return;
    }

    MessengerService? messenger;
    try {
      messenger = ref.read(preferredMessengerProvider);
      debugPrint('=== Preferred messenger: ${messenger?.name ?? "system"} ===');
    } catch (e) {
      debugPrint(
        '=== Cannot read messenger (widget disposed), using system share ===',
      );
      messenger = null;
    }

    debugPrint('=== Generating share link ===');
    final shareLink = _generateShareLink(response);
    debugPrint('=== Share link: $shareLink ===');

    final message = _buildShareMessage(response, shareLink);
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
      debugPrint('=== Attempting to launch messenger: $launchUrlString ===');
      try {
        final uri = Uri.parse(launchUrlString);
        final canLaunch = await canLaunchUrl(uri);
        debugPrint('=== canLaunchUrl result: $canLaunch ===');

        if (canLaunch) {
          HapticFeedback.mediumImpact();
          debugPrint('=== Launching messenger app ===');
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          // Save to history
          debugPrint('=== Saving to history ===');
          await _saveToHistory(HistoryType.shared, shareLink);

          // Invalidate statistics providers to refresh chart
          try {
            ref.invalidate(sharedHistoryProvider);
          } catch (e) {
            debugPrint('Cannot invalidate provider (widget disposed)');
          }

          // Close the processing screen after launching
          debugPrint('=== Scheduling navigation pop ===');
          if (mounted) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }
          debugPrint('=== _shareToMessenger END (messenger launched) ===');
          return;
        } else {
          // App not installed - fallback to system share
          debugPrint('=== Messenger app not installed, using system share ===');
        }
      } catch (e) {
        debugPrint('=== ERROR launching messenger: $e ===');
        // Fallback to system share
      }
    }

    // Fallback: use system share (no intermediate screen)
    if (mounted) {
      debugPrint('=== Using system share ===');
      HapticFeedback.mediumImpact();
      // Save to history before sharing
      await _saveToHistory(HistoryType.shared, shareLink);

      // Invalidate statistics providers to refresh chart
      try {
        ref.invalidate(sharedHistoryProvider);
      } catch (e) {
        debugPrint('Cannot invalidate provider (widget disposed)');
      }

      // Use system share - AWAIT the async function
      await _showSystemShare(message, response);
    }
    debugPrint('=== _shareToMessenger END ===');
  }

  /// Show system share dialog
  Future<void> _showSystemShare(
    String message,
    UnituneResponse response,
  ) async {
    try {
      debugPrint('=== Opening system share dialog ===');

      // Use share_plus to trigger native OS share dialog
      // IMPORTANT: Don't close the screen before sharing
      final result = await Share.share(
        message,
        subject: 'Check out this ${_contentLabel(response)} on UniTune',
      );

      debugPrint('Share result: ${result.status}');
    } catch (e) {
      debugPrint('Error showing system share: $e');
    } finally {
      // Close processing screen after share dialog is dismissed
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  Future<void> _openInMusicApp() async {
    debugPrint('=== _openInMusicApp START ===');
    final response = _response;
    if (response == null) {
      debugPrint('=== _openInMusicApp: response is null, returning ===');
      return;
    }

    MusicService? musicService;
    try {
      musicService = ref.read(preferredMusicServiceProvider);
      debugPrint('Preferred service: ${musicService?.name ?? "none"}');
    } catch (e) {
      debugPrint(
        '=== Cannot read music service (widget disposed), using null ===',
      );
      musicService = null;
    }

    debugPrint('=== _openInMusicApp: Opening music app ===');
    debugPrint('Original link: ${widget.incomingLink}');

    // If no preference set, open original link
    if (musicService == null) {
      debugPrint(
        'No preference set, opening original link: ${widget.incomingLink}',
      );
      try {
        final uri = Uri.parse(widget.incomingLink);
        debugPrint('=== Checking if can launch URL ===');

        // Check if app is available
        final canOpen = await canLaunchUrl(uri);
        debugPrint('=== canLaunchUrl result: $canOpen ===');

        if (canOpen) {
          HapticFeedback.mediumImpact();
          debugPrint('=== Launching URL ===');

          // CRITICAL FIX: Save to history BEFORE launching URL
          // This ensures history is saved even if widget gets disposed during launch
          debugPrint('=== Saving to history BEFORE launch ===');
          await _saveToHistory(HistoryType.received, null);
          debugPrint('=== History saved ===');

          // Invalidate statistics providers to refresh chart
          try {
            ref.invalidate(receivedHistoryProvider);
          } catch (e) {
            debugPrint('Cannot invalidate provider (widget disposed)');
          }

          // Launch URL - this may cause the widget to be disposed
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('=== URL launched ===');

          // Pop navigation only if still mounted
          debugPrint('=== Scheduling navigation pop ===');
          if (mounted) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }
        } else {
          debugPrint('=== Cannot launch URL, showing error ===');
          if (mounted) {
            setState(() {
              _error = 'Cannot open this link. Please install the music app.';
            });
          }
        }
      } catch (e) {
        debugPrint('=== ERROR in _openInMusicApp (no preference): $e ===');
        if (mounted) {
          setState(() {
            _error = 'Error opening link: $e';
          });
        }
      }
      return;
    }

    // Get the link for the preferred service
    try {
      debugPrint('=== Getting URL for service: ${musicService.name} ===');
      final targetUrl = response.getUrlForService(musicService);

      debugPrint('Target URL for ${musicService.name}: $targetUrl');

      if (targetUrl != null) {
        final uri = Uri.parse(targetUrl);

        debugPrint('=== Checking if can launch target URL ===');
        // Check if the music app is installed
        final canOpen = await canLaunchUrl(uri);
        debugPrint('=== canLaunchUrl result: $canOpen ===');

        if (canOpen) {
          HapticFeedback.mediumImpact();
          debugPrint('Launching URL: $targetUrl');

          // CRITICAL FIX: Save to history BEFORE launching URL
          debugPrint('=== Saving to history BEFORE launch ===');
          await _saveToHistory(HistoryType.received, null);
          debugPrint('=== History saved ===');

          // Invalidate statistics providers to refresh chart
          try {
            ref.invalidate(receivedHistoryProvider);
          } catch (e) {
            debugPrint('Cannot invalidate provider (widget disposed)');
          }

          // Launch URL - this may cause the widget to be disposed
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('=== URL launched ===');

          // Pop navigation only if still mounted
          debugPrint('=== Scheduling navigation pop ===');
          if (mounted) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }
        } else {
          // App not installed - show error
          final serviceName = musicService.name;
          debugPrint('ERROR: $serviceName not installed');
          if (mounted) {
            setState(() {
              _error =
                  '$serviceName is not installed. Please install it or change your preferred music service in settings.';
            });
          }
        }
      } else {
        // Service link not found for this song
        final serviceName = musicService.name;
        debugPrint(
          'ERROR: ${_contentLabel(response)} not available on $serviceName',
        );
        if (mounted) {
          setState(() {
            _error = '${_contentLabel(response)} not available on $serviceName';
          });
        }
      }
    } catch (e) {
      debugPrint('=== ERROR in _openInMusicApp (with preference): $e ===');
      if (mounted) {
        setState(() {
          _error = 'Error opening link: $e';
        });
      }
    }
    debugPrint('=== _openInMusicApp END ===');
  }

  /// Save the current song to history
  Future<void> _saveToHistory(HistoryType type, String? uniTuneUrl) async {
    final response = _response;
    if (response == null) return;

    try {
      final entry = HistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _displayTitle(response),
        artist: _displaySubtitle(response),
        thumbnailUrl: response.thumbnailUrl,
        originalUrl: widget.incomingLink,
        uniTuneUrl: uniTuneUrl,
        type: type,
        contentType: response.contentType,
        timestamp: DateTime.now(),
      );

      await ref.read(historyRepositoryProvider).add(entry);

      // Invalidate providers to refresh history screens
      try {
        ref.invalidate(sharedHistoryProvider);
        ref.invalidate(receivedHistoryProvider);
      } catch (e) {
        debugPrint('Cannot invalidate providers (widget disposed)');
      }

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
    try {
      return UniTuneLinkEncoder.createShareLinkFromUrl(widget.incomingLink);
    } catch (e) {
      debugPrint('=== Error generating share link: $e ===');
      // Fallback: return the original link
      return widget.incomingLink;
    }
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
          OptimizedLiquidGlassLayer(
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
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
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
          // Banner Ad at bottom (only during loading)
          if (_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.m),
                  child: const BannerAdWidget(),
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
            fontFamily: 'ZalandoSansExpanded',
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
          _displayTitle(response),
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: AppTheme.spacing.s),
        // Artist
        if (_displaySubtitle(response).isNotEmpty)
          Text(
            _displaySubtitle(response),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.colors.textSecondary,
            ),
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

  String _displayTitle(UnituneResponse response) {
    switch (response.contentType) {
      case MusicContentType.album:
        return response.albumTitle ?? response.title ?? 'Unknown Album';
      case MusicContentType.artist:
        return response.artistName ?? response.title ?? 'Unknown Artist';
      case MusicContentType.track:
        return response.title ?? 'Unknown Song';
      case MusicContentType.playlist:
        return response.title ?? 'Unknown Playlist';
      case MusicContentType.unknown:
        return response.title ?? 'Unknown';
    }
  }

  String _displaySubtitle(UnituneResponse response) {
    switch (response.contentType) {
      case MusicContentType.artist:
        return 'Artist';
      case MusicContentType.album:
      case MusicContentType.track:
        return response.artistName ?? 'Unknown Artist';
      case MusicContentType.playlist:
        return response.artistName ?? '';
      case MusicContentType.unknown:
        return response.artistName ?? '';
    }
  }

  String _contentLabel(UnituneResponse response) {
    switch (response.contentType) {
      case MusicContentType.album:
        return 'album';
      case MusicContentType.artist:
        return 'artist';
      case MusicContentType.track:
        return 'song';
      case MusicContentType.playlist:
        return 'playlist';
      case MusicContentType.unknown:
        return 'music';
    }
  }

  String _buildShareMessage(UnituneResponse response, String shareLink) {
    final title = _displayTitle(response);
    final artist = _displaySubtitle(response);

    // Branded message with social proof
    return '''
${artist.isNotEmpty ? '$artist - $title' : title}

Listen on YOUR music platform:
$shareLink

Shared via UniTune
Music that works for everyone - unitune.art
''';
  }

  Widget _buildPlaceholderArt() {
    return Container(
      color: AppTheme.colors.backgroundCard,
      child: const Center(child: Text('♪', style: TextStyle(fontSize: 64))),
    );
  }

  Widget _buildErrorState() {
    final response = _response;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
        const SizedBox(height: 24),
        Text(
          _error ?? 'Something went wrong',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.colors.textSecondary,
            fontFamily: 'ZalandoSansExpanded',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Open in Browser',
          onPressed: () => _openInBrowser(widget.incomingLink),
          icon: Icons.open_in_new,
        ),
        const SizedBox(height: 8),
        InlineGlassButton(
          label: 'Copy Link',
          onPressed: _copyLinkToClipboard,
          icon: Icons.copy,
        ),
        if (response != null && response.linksByPlatform.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Try another service',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildAvailableServiceButtons(response),
        ],
        const SizedBox(height: 16),
        InlineGlassButton(
          label: 'Close',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          color: AppTheme.colors.textMuted,
        ),
      ],
    );
  }

  List<Widget> _buildAvailableServiceButtons(UnituneResponse response) {
    final buttons = <Widget>[];
    response.linksByPlatform.forEach((key, value) {
      final button = _buildPlatformButton(key, value.url);
      if (button != null) {
        buttons.add(button);
        buttons.add(const SizedBox(height: 10));
      }
    });
    if (buttons.isNotEmpty) {
      buttons.removeLast();
    }
    return buttons;
  }

  Widget? _buildPlatformButton(String platformKey, String url) {
    switch (platformKey) {
      case 'spotify':
        return ServiceButton(
          serviceName: 'Spotify',
          icon: Icons.music_note,
          accentColor: AppTheme.colors.spotify,
          onTap: () => _openUrl(url),
          actionLabel: 'Open',
        );
      case 'appleMusic':
        return ServiceButton(
          serviceName: 'Apple Music',
          icon: Icons.music_note,
          accentColor: AppTheme.colors.appleMusic,
          onTap: () => _openUrl(url),
          actionLabel: 'Open',
        );
      case 'tidal':
        return ServiceButton(
          serviceName: 'Tidal',
          icon: Icons.music_note,
          accentColor: AppTheme.colors.tidal,
          onTap: () => _openUrl(url),
          actionLabel: 'Open',
        );
      case 'youtubeMusic':
        return ServiceButton(
          serviceName: 'YouTube Music',
          icon: Icons.play_arrow,
          accentColor: AppTheme.colors.youtubeMusic,
          onTap: () => _openUrl(url),
          actionLabel: 'Open',
        );
      case 'deezer':
        return ServiceButton(
          serviceName: 'Deezer',
          icon: Icons.music_note,
          accentColor: AppTheme.colors.primaryLight,
          onTap: () => _openUrl(url),
          actionLabel: 'Open',
        );
      case 'amazonMusic':
        return ServiceButton(
          serviceName: 'Amazon Music',
          icon: Icons.music_note,
          accentColor: AppTheme.colors.accentWarning,
          onTap: () => _openUrl(url),
          actionLabel: 'Open',
        );
      default:
        return null;
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cannot open this link'),
            backgroundColor: AppTheme.colors.accentError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to open link'),
            backgroundColor: AppTheme.colors.accentError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openInBrowser(String link) async {
    await _openUrl(link);
  }

  Future<void> _copyLinkToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.incomingLink));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Link copied to clipboard'),
          backgroundColor: AppTheme.colors.backgroundCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
