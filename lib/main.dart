import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart' show SharedFile;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/dynamic_theme.dart';
import 'core/theme/dynamic_color_provider.dart';
import 'core/security/url_validator.dart';
import 'core/utils/link_encoder.dart';
import 'core/ads/ad_helper.dart';
import 'core/widgets/primary_button.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/onboarding/screens/music_service_selector.dart';
import 'features/onboarding/screens/messenger_selector.dart';
import 'features/settings/preferences_manager.dart';
import 'features/main_shell.dart';
import 'features/sharing/processing_screen.dart';
import 'features/playlists/screens/playlist_creator_screen.dart';
import 'features/playlists/screens/playlist_detail_screen.dart';
import 'features/playlists/screens/playlist_qr_screen.dart';
import 'features/playlists/screens/playlist_import_screen.dart';
import 'features/playlists/screens/playlist_post_create_screen.dart';
import 'features/playlists/state/playlist_creation_state.dart';

/// Provider for incoming shared link
final incomingLinkProvider = StateProvider<String?>((ref) => null);

/// Processing mode - determines what action to take after processing
enum ProcessingMode {
  /// User is sharing a song TO someone (create link, open messenger)
  share,

  /// User is opening a shared link (show song, open in music app)
  open,
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();

  if (AdHelper.adsEnabled) {
    await MobileAds.instance.initialize();
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const UniTuneApp(),
    ),
  );
}

class UniTuneApp extends ConsumerStatefulWidget {
  const UniTuneApp({super.key});

  @override
  ConsumerState<UniTuneApp> createState() => _UniTuneAppState();
}

class _UniTuneAppState extends ConsumerState<UniTuneApp> {
  // Deep links (for UniTune links)
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  // Share intents (for receiving from Spotify/Tidal etc.)
  StreamSubscription<List<SharedFile>>? _sharingSub;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String? _pendingLink;
  String? _lastHandledLink;
  DateTime? _lastHandledAt;
  int _pendingAttempts = 0;

  // CRITICAL: GoRouter must be created ONCE, not on every build().
  // Creating it in build() causes navigation state to reset on every rebuild,
  // which breaks deep link / share intent handling.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
    _initDeepLinks();
    _initShareIntent();
    _syncDynamicColorFromHistory();
  }

  bool _shouldSkipDuplicate(String link) {
    if (_lastHandledLink == null || _lastHandledAt == null) {
      debugPrint('=== Duplicate check: No previous link, allowing ===');
      return false;
    }
    final isSame = _lastHandledLink == link;
    final isRecent = DateTime.now().difference(_lastHandledAt!).inSeconds < 3;
    final shouldSkip = isSame && isRecent;

    debugPrint('=== Duplicate check ===');
    debugPrint('Current link: $link');
    debugPrint('Last handled: $_lastHandledLink');
    debugPrint('Same link: $isSame');
    debugPrint('Recent (< 3s): $isRecent');
    debugPrint('Should skip: $shouldSkip');

    return shouldSkip;
  }

  void _markHandled(String link) {
    debugPrint('=== Marking link as handled: $link ===');
    _lastHandledLink = link;
    _lastHandledAt = DateTime.now();
  }

  /// Sync app colors from the topmost shared history entry
  Future<void> _syncDynamicColorFromHistory() async {
    // Small delay to ensure providers are ready
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final historyEntries = await ref.read(sharedHistoryProvider.future);
      if (historyEntries.isNotEmpty) {
        debugPrint(
          'Syncing dynamic color from ${historyEntries.length} shared entries',
        );
        await ref
            .read(dynamicColorProvider.notifier)
            .syncFromHistory(historyEntries);
      }
    } catch (e) {
      debugPrint('Error syncing dynamic color: $e');
    }
  }

  // === DEEP LINKS (for unitune:// and https://unitune-link.* URLs) ===
  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check for initial link (app opened via link)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen for links while app is running
    _linkSub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('DeepLink error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');

    // Check if it's a UniTune deep link with a url parameter
    // This means someone is OPENING a shared link
    if (uri.scheme == 'unitune') {
      // Extract the music URL and optional metadata from query parameters
      final musicUrl = uri.queryParameters['url'];
      final title = uri.queryParameters['title'];
      final artist = uri.queryParameters['artist'];
      final source = uri.queryParameters['source'];

      final playlistId = uri.queryParameters['id'];
      if (uri.host == 'playlist' &&
          playlistId != null &&
          playlistId.isNotEmpty) {
        debugPrint('DeepLink.playlist scheme id=$playlistId');
        _navigateToPlaylistImport(playlistId);
        return;
      }

      if (musicUrl != null && musicUrl.isNotEmpty) {
        debugPrint(
          'OPEN mode: Extracted music URL from unitune:// scheme: $musicUrl',
        );
        debugPrint('Metadata: title=$title, artist=$artist, source=$source');

        // FAST PATH: If source=web, the link comes from the UniTune website
        // The website already validated everything, so skip all validation
        // and just open the URL directly. This avoids false "Invalid URL" errors.
        if (source == 'web') {
          debugPrint(
            '=== FAST OPEN: Link from website (source=web), opening directly ===',
          );

          // Decode the URL if needed and extract actual music URL
          String urlToOpen = musicUrl;
          try {
            // If the URL is a unitune.art link, extract the actual music URL
            if (musicUrl.contains('unitune')) {
              urlToOpen = _extractMusicUrlFromUnituneLink(musicUrl);
            }
          } catch (e) {
            debugPrint('Error extracting URL, using original: $e');
          }

          // Basic safety check only (no whitelist check for web source)
          final sanitized = UrlValidator.sanitizeUrl(urlToOpen);
          if (UrlValidator.isSafeUrl(sanitized)) {
            _openDirectlyInMusicApp(sanitized);
          } else {
            _showErrorDialog('Invalid URL format');
          }
          return;
        }

        // For non-web sources, do full validation
        // IMPORTANT: Check if the URL itself is a unitune.art link
        // If yes, extract the actual music URL from it
        final actualMusicUrl = _extractMusicUrlFromUnituneLink(musicUrl);

        // Validate the URL before processing
        final validationResult = UrlValidator.validateAndSanitize(
          actualMusicUrl,
        );
        if (!validationResult.isValid) {
          // Log URL parsing failure locally (not sent externally)
          developer.log(
            'URL validation failed',
            name: 'URLValidation',
            error: validationResult.errorMessage,
          );
          debugPrint('Invalid URL rejected: ${validationResult.errorMessage}');
          _showErrorDialog(validationResult.errorMessage ?? 'Invalid URL');
          return;
        }

        // If metadata is available, open directly without API call
        final hasMetadata =
            title != null &&
            title.isNotEmpty &&
            artist != null &&
            artist.isNotEmpty;
        if (hasMetadata) {
          debugPrint(
            '=== FAST OPEN: Metadata available, skipping API call ===',
          );
          _openDirectlyInMusicApp(validationResult.sanitizedUrl);
          return;
        }

        // No metadata and not from web - need to call API via ProcessingScreen
        if (_shouldSkipDuplicate(validationResult.sanitizedUrl)) {
          return;
        }
        _markHandled(validationResult.sanitizedUrl);
        _navigateToProcessing(
          validationResult.sanitizedUrl,
          ProcessingMode.open,
        );
        return;
      }
    }

    if (uri.host.contains('unitune') && uri.path.startsWith('/p/')) {
      final playlistId = uri.path.replaceFirst('/p/', '');
      if (playlistId.isNotEmpty) {
        debugPrint('DeepLink.playlist https id=$playlistId');
        _navigateToPlaylistImport(playlistId);
        return;
      }
    }

    // For https:// links (unitune.art/s/...) - also OPENING a shared link
    if (uri.host.contains('unitune') && uri.path.startsWith('/s/')) {
      // Extract the encoded path from the URL
      final encodedPath = uri.path.replaceFirst('/s/', '');

      // Decode using the new encoder (supports both Base64 and legacy formats)
      final musicUrl = UniTuneLinkEncoder.decodeShareLinkPath(encodedPath);

      if (musicUrl != null && musicUrl.isNotEmpty) {
        debugPrint(
          'OPEN mode: Extracted music URL from unitune.art path: $musicUrl',
        );

        // Validate the URL before processing
        final validationResult = UrlValidator.validateAndSanitize(musicUrl);
        if (!validationResult.isValid) {
          // Log URL parsing failure locally (not sent externally)
          developer.log(
            'URL validation failed',
            name: 'URLValidation',
            error: validationResult.errorMessage,
          );
          debugPrint('Invalid URL rejected: ${validationResult.errorMessage}');
          _showErrorDialog(validationResult.errorMessage ?? 'Invalid URL');
          return;
        }

        // CRITICAL FIX: Add duplicate check here too
        if (_shouldSkipDuplicate(validationResult.sanitizedUrl)) {
          debugPrint('=== Skipping duplicate deep link ===');
          return;
        }
        _markHandled(validationResult.sanitizedUrl);

        _navigateToProcessing(
          validationResult.sanitizedUrl,
          ProcessingMode.open,
        );
        return;
      }
    }

    // Direct music link (intercepted from Spotify/Tidal/etc.)
    final link = uri.toString();
    if (_isMusicLink(link)) {
      // Music links via deep link are ALWAYS in OPEN mode
      // Because if the user didn't want UniTune to handle it,
      // they would have chosen the music app in Android's app picker
      debugPrint('OPEN mode: Intercepted music link: $link');

      // Validate the URL before processing
      final validationResult = UrlValidator.validateAndSanitize(link);
      if (!validationResult.isValid) {
        developer.log(
          'URL validation failed',
          name: 'URLValidation',
          error: validationResult.errorMessage,
        );
        debugPrint('Invalid URL rejected: ${validationResult.errorMessage}');
        _showErrorDialog(validationResult.errorMessage ?? 'Invalid URL');
        return;
      }

      // OPEN mode: Get link for preferred service and open
      if (_shouldSkipDuplicate(validationResult.sanitizedUrl)) {
        return;
      }
      _markHandled(validationResult.sanitizedUrl);
      _navigateToProcessing(validationResult.sanitizedUrl, ProcessingMode.open);
    }
  }

  void _navigateToPlaylistImport(String playlistId) {
    debugPrint('DeepLink.navigate playlist import id=$playlistId');
    _router.go('/playlists/import?id=$playlistId');
  }

  /// Extracts the actual music URL from a UniTune share link
  /// Supports Base64 share links and legacy encoded URLs.
  String _extractMusicUrlFromUnituneLink(String url) {
    try {
      final uri = Uri.parse(url);

      if (uri.scheme == 'unitune') {
        final nestedUrl = uri.queryParameters['url'];
        if (nestedUrl != null && nestedUrl.isNotEmpty) {
          return _extractMusicUrlFromUnituneLink(nestedUrl);
        }
      }

      // Check if it's a unitune.art link
      if (uri.host.contains('unitune') && uri.path.startsWith('/s/')) {
        final encodedPath = uri.path.replaceFirst('/s/', '');
        final decodedUrl = UniTuneLinkEncoder.decodeShareLinkPath(encodedPath);
        if (decodedUrl != null && decodedUrl.isNotEmpty) {
          debugPrint('Decoded unitune.art share link: $decodedUrl');
          return decodedUrl;
        }

        final legacyDecoded = Uri.decodeComponent(encodedPath);
        debugPrint('Decoded legacy unitune.art link: $legacyDecoded');
        if (legacyDecoded.contains('unitune')) {
          return _extractMusicUrlFromUnituneLink(legacyDecoded);
        }
        return legacyDecoded;
      }

      // Not a unitune.art URL, return original
      return url;
    } catch (e) {
      debugPrint('Error extracting music URL: $e');
      return url;
    }
  }

  // === SHARE INTENTS (for receiving from other apps like Spotify) ===
  void _initShareIntent() {
    // Check for initial shared content (app opened via share)
    FlutterSharingIntent.instance.getInitialSharing().then((
      List<SharedFile>? files,
    ) {
      if (files != null && files.isNotEmpty) {
        _handleSharedFiles(files);
      }
    });

    // Listen for shares while app is running
    _sharingSub = FlutterSharingIntent.instance.getMediaStream().listen(
      (List<SharedFile> files) {
        _handleSharedFiles(files);
      },
      onError: (err) {
        debugPrint('ShareIntent error: $err');
      },
    );
  }

  void _handleSharedFiles(List<SharedFile> files) {
    for (final file in files) {
      // Check for text content (usually contains the link)
      final text = file.value;
      if (text != null && text.isNotEmpty) {
        // IMPORTANT: Skip unitune:// deep links - they are handled by _handleDeepLink
        // The share intent plugin sometimes captures deep links as shared text
        if (text.contains('unitune://')) {
          debugPrint(
            'Skipping unitune:// deep link in share intent (handled by _handleDeepLink): $text',
          );
          return;
        }

        // Extract URL from text (Spotify shares include extra text)
        final link = _extractMusicLink(text);
        if (link != null) {
          // IMPORTANT: Check if it's a unitune.art HTTPS link (NOT unitune:// deep link)
          // If yes, treat it as OPEN mode (someone shared a unitune link)
          if (link.contains('unitune.art')) {
            debugPrint(
              'OPEN mode: Received unitune.art link via share intent: $link',
            );
            if (link.contains('/p/')) {
              try {
                final uri = Uri.parse(link);
                final playlistId = uri.path.replaceFirst('/p/', '');
                if (playlistId.isNotEmpty) {
                  _navigateToPlaylistImport(playlistId);
                  return;
                }
              } catch (_) {
                _showErrorDialog('Invalid playlist link');
                return;
              }
            }
            final actualMusicUrl = _extractMusicUrlFromUnituneLink(link);

            // Validate the URL before processing
            final validationResult = UrlValidator.validateAndSanitize(
              actualMusicUrl,
            );
            if (!validationResult.isValid) {
              // Log URL parsing failure locally (not sent externally)
              developer.log(
                'URL validation failed',
                name: 'URLValidation',
                error: validationResult.errorMessage,
              );
              debugPrint(
                'Invalid URL rejected: ${validationResult.errorMessage}',
              );
              _showErrorDialog(validationResult.errorMessage ?? 'Invalid URL');
              return;
            }

            if (_shouldSkipDuplicate(validationResult.sanitizedUrl)) {
              return;
            }
            _markHandled(validationResult.sanitizedUrl);
            _navigateToProcessing(
              validationResult.sanitizedUrl,
              ProcessingMode.open,
            );
          } else if (_isMusicLink(link)) {
            // Music link - always process as SHARE mode
            // (User wants to share this song to someone else)
            debugPrint(
              'SHARE mode: Received music link via share intent: $link',
            );

            // Validate the URL before processing
            final validationResult = UrlValidator.validateAndSanitize(link);
            if (!validationResult.isValid) {
              // Log URL parsing failure locally (not sent externally)
              developer.log(
                'URL validation failed',
                name: 'URLValidation',
                error: validationResult.errorMessage,
              );
              debugPrint(
                'Invalid URL rejected: ${validationResult.errorMessage}',
              );
              _showErrorDialog(validationResult.errorMessage ?? 'Invalid URL');
              return;
            }

            if (ref.read(playlistCreationActiveProvider)) {
              debugPrint(
                'PlaylistCreator.active received link: ${validationResult.sanitizedUrl}',
              );
              ref.read(playlistIncomingLinkProvider.notifier).state =
                  validationResult.sanitizedUrl;
              return;
            }

            if (_shouldSkipDuplicate(validationResult.sanitizedUrl)) {
              return;
            }
            _markHandled(validationResult.sanitizedUrl);
            _navigateToProcessing(
              validationResult.sanitizedUrl,
              ProcessingMode.share,
            );
          }
          return;
        }
      }
    }
  }

  /// Extract music link from shared text (handles "Check out this song: https://...")
  String? _extractMusicLink(String text) {
    // Find URL in text using regex
    final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);

    final match = urlPattern.firstMatch(text);
    if (match != null) {
      final url = match.group(0)!;
      // Check for unitune.art links OR music links
      if (url.toLowerCase().contains('unitune') || _isMusicLink(url)) {
        return url;
      }
    }

    // Maybe the entire text is a URL
    final trimmed = text.trim();
    if (trimmed.toLowerCase().contains('unitune') || _isMusicLink(trimmed)) {
      return trimmed;
    }

    return null;
  }

  bool _isMusicLink(String link) {
    final lowerLink = link.toLowerCase();

    // IMPORTANT: unitune.art links are NOT music links!
    // They are UniTune share links and should be treated as OPEN
    if (lowerLink.contains('unitune')) {
      return false;
    }

    final musicDomains = [
      'open.spotify.com',
      'spotify.link',
      'music.apple.com',
      'tidal.com',
      'listen.tidal.com',
      'music.youtube.com',
      'youtu.be',
      'deezer.page.link',
      'deezer.com',
      'music.amazon',
      'amazon.com/music',
    ];

    return musicDomains.any((domain) => lowerLink.contains(domain));
  }

  void _navigateToProcessing(String link, ProcessingMode mode) {
    debugPrint('=== _navigateToProcessing called ===');
    debugPrint('Link: $link');
    debugPrint('Mode: $mode');

    ref.read(incomingLinkProvider.notifier).state = link;

    final modeParam = mode == ProcessingMode.open ? 'open' : 'share';
    final target = '/process?link=${Uri.encodeComponent(link)}&mode=$modeParam';

    debugPrint('Target route: $target');

    _pendingLink = link;
    _pendingAttempts = 0;
    _tryNavigatePending(target);
  }

  void _tryNavigatePending(String target) {
    debugPrint(
      '=== _tryNavigatePending called (attempt $_pendingAttempts) ===',
    );

    if (_pendingLink == null) {
      debugPrint('Pending link is null, aborting navigation');
      return;
    }

    // ALWAYS use addPostFrameCallback to ensure navigation happens AFTER
    // the current frame is complete. This is critical when the app resumes
    // from background: the intent arrives during the resume rebuild, and
    // calling go() immediately gets lost because the framework is still
    // rebuilding the widget tree / recreating the Surface.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingLink == null) {
        debugPrint('Pending link cleared before post-frame callback');
        return;
      }

      // Use _router.go() directly instead of GoRouter.of(context).go()
      // to avoid context lookup issues during app resume lifecycle.
      debugPrint('Using _router.go() to navigate (post-frame): $target');
      _router.go(target);
      _pendingLink = null;
      _pendingAttempts = 0;
    });
  }

  /// Opens music directly in preferred app without API call
  /// Used when metadata is already available from web landing page
  Future<void> _openDirectlyInMusicApp(String musicUrl) async {
    final musicService = ref.read(preferredMusicServiceProvider);

    debugPrint('=== _openDirectlyInMusicApp: Opening directly ===');
    debugPrint('Music URL: $musicUrl');
    debugPrint('Preferred service: ${musicService?.name ?? "none"}');

    try {
      final uri = Uri.parse(musicUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening music URL: $e');
      _showErrorDialog('Could not open the music link. Please try again.');
    }
  }

  /// Shows an error dialog to the user when URL validation fails
  void _showErrorDialog(String message) {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      debugPrint('Cannot show error dialog: no context available');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid URL'),
        content: Text(message),
        actions: [
          InlineGlassButton(
            label: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _sharingSub?.cancel();
    _router.dispose();
    super.dispose();
  }

  /// Creates the GoRouter ONCE. Must not be called in build().
  GoRouter _createRouter() {
    final isOnboardingComplete = ref.read(isOnboardingCompleteProvider);

    return GoRouter(
      navigatorKey: _navigatorKey,
      debugLogDiagnostics: true,
      observers: [_RouteLogger()],
      initialLocation: isOnboardingComplete ? '/home' : '/onboarding/welcome',
      routes: [
        // Onboarding flow
        GoRoute(
          path: '/onboarding/welcome',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: WelcomeScreen(
              onContinue: () => context.go('/onboarding/music'),
            ),
            transitionsBuilder: _fadeSlideTransition,
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ),
        GoRoute(
          path: '/onboarding/music',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: MusicServiceSelector(
              onContinue: () => context.go('/onboarding/messenger'),
            ),
            transitionsBuilder: _slideTransition,
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ),
        GoRoute(
          path: '/onboarding/messenger',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: MessengerSelector(
              onContinue: () {
                // Mark onboarding complete
                ref
                    .read(preferencesManagerProvider)
                    .setOnboardingComplete(true);
                ref.read(isOnboardingCompleteProvider.notifier).state = true;
                context.go('/home');
              },
            ),
            transitionsBuilder: _slideTransition,
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ),
        // Main app
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const MainShell(),
            transitionsBuilder: _fadeSlideTransition,
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ),
        // Processing screen (for share intents)
        GoRoute(
          path: '/process',
          pageBuilder: (context, state) {
            debugPrint('=== GoRoute /process pageBuilder called ===');
            debugPrint('Query parameters: ${state.uri.queryParameters}');

            final linkParam = state.uri.queryParameters['link'] ?? '';
            final link = Uri.decodeComponent(linkParam);
            final modeParam =
                state.uri.queryParameters['mode']?.toLowerCase() ?? 'share';
            final mode = modeParam == 'open'
                ? ProcessingMode.open
                : ProcessingMode.share;

            debugPrint('Decoded link: $link');
            debugPrint('Mode: $mode');

            return CustomTransitionPage(
              key: state.pageKey,
              child: ProcessingScreen(incomingLink: link, mode: mode),
              transitionsBuilder: _fadeSlideTransition,
              transitionDuration: const Duration(milliseconds: 350),
            );
          },
        ),
        // Playlist routes
        GoRoute(
          path: '/playlists/create',
          pageBuilder: (context, state) {
            debugPrint('=== GoRoute /playlists/create pageBuilder called ===');
            return CustomTransitionPage(
              key: state.pageKey,
              child: const PlaylistCreatorScreen(),
              transitionsBuilder: _fadeSlideTransition,
              transitionDuration: const Duration(milliseconds: 350),
            );
          },
        ),
        GoRoute(
          path: '/playlists/:id/created',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: PlaylistPostCreateScreen(playlistId: id),
              transitionsBuilder: _fadeSlideTransition,
              transitionDuration: const Duration(milliseconds: 350),
            );
          },
        ),
        GoRoute(
          path: '/playlists/import',
          pageBuilder: (context, state) {
            final id = state.uri.queryParameters['id'];
            debugPrint(
              '=== GoRoute /playlists/import pageBuilder called id=$id ===',
            );
            if (id == null || id.isEmpty) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const MainShell(),
                transitionsBuilder: _fadeSlideTransition,
                transitionDuration: const Duration(milliseconds: 350),
              );
            }
            return CustomTransitionPage(
              key: state.pageKey,
              child: PlaylistImportScreen(playlistId: id),
              transitionsBuilder: _fadeSlideTransition,
              transitionDuration: const Duration(milliseconds: 350),
            );
          },
        ),
        GoRoute(
          path: '/playlists/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            debugPrint('=== GoRoute /playlists/:id pageBuilder id=$id ===');
            return CustomTransitionPage(
              key: state.pageKey,
              child: PlaylistDetailScreen(playlistId: id),
              transitionsBuilder: _fadeSlideTransition,
              transitionDuration: const Duration(milliseconds: 350),
            );
          },
        ),
        GoRoute(
          path: '/playlists/:id/qr',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: PlaylistQRScreen(playlistId: id),
              transitionsBuilder: _fadeSlideTransition,
              transitionDuration: const Duration(milliseconds: 350),
            );
          },
        ),
      ],
      // Handle deep links that don't match routes - redirect to home
      // (the actual deep link handling is done by app_links in _handleDeepLink)
      redirect: (context, state) {
        debugPrint('GoRouter.redirect uri=${state.uri}');
        final uri = state.uri;
        // If it's a unitune:// deep link, redirect to home
        // The actual processing is handled by _handleDeepLink via app_links
        if (uri.scheme == 'unitune') {
          debugPrint('GoRouter.redirect to /home for unitune scheme');
          return '/home';
        }
        if ((uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.contains('unitune') &&
            uri.path.startsWith('/p/')) {
          final playlistId = uri.path.replaceFirst('/p/', '');
          if (playlistId.isNotEmpty) {
            debugPrint(
              'GoRouter.redirect to /playlists/import for playlist link',
            );
            return '/playlists/import?id=$playlistId';
          }
        }
        if ((uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.contains('unitune') &&
            uri.path.startsWith('/s/')) {
          debugPrint('GoRouter.redirect to /home for share link');
          return '/home';
        }
        return null;
      },
      errorBuilder: (context, state) {
        debugPrint('GoRouter.error ${state.error}');
        // For any unhandled routes, go to home
        return const MainShell();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with DynamicThemeBuilder to provide dynamic colors
    // Colors automatically update based on last shared song's album artwork
    return DynamicThemeBuilder(
      child: MaterialApp.router(
        title: 'UniTune',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }

  // Smooth fade and slide transition with 300-400ms duration and ease-in-out curve
  // Meets requirements 7.1 and 7.5 for page transitions
  static Widget _fadeSlideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade animation with ease-in-out curve
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

    // Subtle slide animation with ease-in-out curve
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.03, 0.0), // Subtle 3% horizontal slide
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }

  // Slide from right transition for onboarding flow
  static Widget _slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade animation with ease-in-out curve
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

    // Slide from right with ease-in-out curve
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0), // Slide from 30% right
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }
}

class _RouteLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint(
      'Route.didPush new=${route.settings.name ?? route.settings} prev=${previousRoute?.settings.name ?? previousRoute?.settings}',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint(
      'Route.didPop popped=${route.settings.name ?? route.settings} prev=${previousRoute?.settings.name ?? previousRoute?.settings}',
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint(
      'Route.didReplace new=${newRoute?.settings.name ?? newRoute?.settings} old=${oldRoute?.settings.name ?? oldRoute?.settings}',
    );
  }
}
