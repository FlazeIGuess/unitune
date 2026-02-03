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

import 'core/theme/app_theme.dart';
import 'core/theme/dynamic_theme.dart';
import 'core/theme/dynamic_color_provider.dart';
import 'core/security/url_validator.dart';
import 'core/utils/link_encoder.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/onboarding/screens/music_service_selector.dart';
import 'features/onboarding/screens/messenger_selector.dart';
import 'features/settings/preferences_manager.dart';
import 'features/main_shell.dart';
import 'features/sharing/processing_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _initShareIntent();
    _syncDynamicColorFromHistory();
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
              urlToOpen = _extractActualMusicUrl(musicUrl);
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
        final actualMusicUrl = _extractActualMusicUrl(musicUrl);

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
        _navigateToProcessing(
          validationResult.sanitizedUrl,
          ProcessingMode.open,
        );
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
      _navigateToProcessing(validationResult.sanitizedUrl, ProcessingMode.open);
    }
  }

  /// Extracts the actual music URL from a possibly nested unitune.art link
  /// Example: "https://unitune.art/s/https%3A%2F%2Ftidal.com%2F..." -> "https://tidal.com/..."
  String _extractActualMusicUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Check if it's a unitune.art link
      if (uri.host.contains('unitune') && uri.path.startsWith('/s/')) {
        final encodedUrl = uri.path.replaceFirst('/s/', '');
        final decodedUrl = Uri.decodeComponent(encodedUrl);
        debugPrint('Extracted nested unitune.art link: $decodedUrl');

        // Recursively check if nested multiple times
        return _extractActualMusicUrl(decodedUrl);
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
            final actualMusicUrl = _extractActualMusicUrl(link);

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

            _navigateToProcessing(
              validationResult.sanitizedUrl,
              ProcessingMode.open,
            );
          } else if (_isMusicLink(link)) {
            // Check if Music Link Interception is enabled
            final interceptEnabled = ref.read(interceptMusicLinksProvider);

            if (interceptEnabled) {
              // Music link interception is ON - this link came via deep link
              // Skip it here, let _handleDeepLink handle it
              debugPrint(
                'Skipping music link in share intent (will be handled by deep link): $link',
              );
              return;
            }

            // Music link interception is OFF - this is a real share from music app
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
    ref.read(incomingLinkProvider.notifier).state = link;

    // Navigate to processing screen with the appropriate mode
    // Using custom page route with fade and slide transition (300-400ms, ease-in-out)
    _navigatorKey.currentState?.push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProcessingScreen(incomingLink: link, mode: mode),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _fadeSlideTransition(
            context,
            animation,
            secondaryAnimation,
            child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350), // 300-400ms
      ),
    );
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _sharingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnboardingComplete = ref.watch(isOnboardingCompleteProvider);

    final router = GoRouter(
      navigatorKey: _navigatorKey,
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
            transitionDuration: const Duration(milliseconds: 350), // 300-400ms
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
            transitionDuration: const Duration(milliseconds: 350), // 300-400ms
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
            transitionDuration: const Duration(milliseconds: 350), // 300-400ms
          ),
        ),
        // Main app
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const MainShell(),
            transitionsBuilder: _fadeSlideTransition,
            transitionDuration: const Duration(milliseconds: 350), // 300-400ms
          ),
        ),
        // Processing screen (for share intents)
        GoRoute(
          path: '/process',
          pageBuilder: (context, state) {
            final link = state.uri.queryParameters['link'] ?? '';
            return CustomTransitionPage(
              key: state.pageKey,
              child: ProcessingScreen(
                incomingLink: link,
                mode: ProcessingMode.share,
              ),
              transitionsBuilder: _fadeSlideTransition,
              transitionDuration: const Duration(
                milliseconds: 350,
              ), // 300-400ms
            );
          },
        ),
      ],
      // Handle deep links that don't match routes - redirect to home
      // (the actual deep link handling is done by app_links in _handleDeepLink)
      redirect: (context, state) {
        final uri = state.uri;
        // If it's a unitune:// deep link, redirect to home
        // The actual processing is handled by _handleDeepLink via app_links
        if (uri.scheme == 'unitune') {
          return '/home';
        }
        return null;
      },
      errorBuilder: (context, state) {
        // For any unhandled routes, go to home
        return const MainShell();
      },
    );

    // Wrap with DynamicThemeBuilder to provide dynamic colors
    // Colors automatically update based on last shared song's album artwork
    return DynamicThemeBuilder(
      child: MaterialApp.router(
        title: 'UniTune',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: router,
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
