import 'dart:async';
import 'dart:io' show Platform;
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'core/ads/consent_helper.dart';
import 'core/widgets/primary_button.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/onboarding/screens/music_service_selector.dart';
import 'features/onboarding/screens/messenger_selector.dart';
import 'features/onboarding/screens/link_interception_screen.dart';
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
    // GDPR: Request consent via Google UMP SDK BEFORE initializing the ad SDK.
    // For EEA/UK users this shows a native consent dialog (Art. 6(1)(a) GDPR).
    // Non-EEA users skip the dialog and proceed immediately.
    final canShowAds = await ConsentHelper.requestConsentAndCheck();
    if (canShowAds) {
      await MobileAds.instance.initialize();
    }
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
  // Native intent channel for Android
  static const platform = MethodChannel('de.unitune.unitune/intent');

  // Deep links (for UniTune links)
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  // Share intents (for receiving from Spotify/Tidal etc.)
  StreamSubscription<List<SharedFile>>? _sharingSub;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String? _pendingLink;
  String? _lastHandledLink;
  DateTime? _lastHandledAt;
  ProcessingMode? _lastHandledMode;
  int _pendingAttempts = 0;

  // Track the last native intent action to determine correct mode
  String? _lastNativeAction;
  DateTime? _lastNativeActionAt;

  // CRITICAL: GoRouter must be created ONCE, not on every build().
  // Creating it in build() causes navigation state to reset on every rebuild,
  // which breaks deep link / share intent handling.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
    _initNativeIntentListener();
    _initDeepLinks();
    _initShareIntent();
    _syncDynamicColorFromHistory();
  }

  bool _shouldSkipDuplicate(String link, ProcessingMode mode) {
    if (_lastHandledLink == null ||
        _lastHandledAt == null ||
        _lastHandledMode == null) {
      debugPrint('=== Duplicate check: No previous link, allowing ===');
      return false;
    }
    final isSame = _lastHandledLink == link;
    final isSameMode = _lastHandledMode == mode;
    final isRecent =
        DateTime.now().difference(_lastHandledAt!).inMilliseconds < 1000;

    // CRITICAL: Only skip if BOTH link AND mode are the same
    // This allows share intent (SHARE mode) and deep link (OPEN mode) to coexist
    final shouldSkip = isSame && isSameMode && isRecent;

    debugPrint('=== Duplicate check ===');
    debugPrint('Current link: $link');
    debugPrint('Current mode: $mode');
    debugPrint('Last handled: $_lastHandledLink');
    debugPrint('Last mode: $_lastHandledMode');
    debugPrint('Same link: $isSame');
    debugPrint('Same mode: $isSameMode');
    debugPrint('Recent (< 1s): $isRecent');
    debugPrint('Should skip: $shouldSkip');

    return shouldSkip;
  }

  void _markHandled(String link, ProcessingMode mode) {
    debugPrint('=== Marking link as handled: $link (mode: $mode) ===');
    _lastHandledLink = link;
    _lastHandledMode = mode;
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

  // === NATIVE INTENT LISTENER (Android only) ===
  void _initNativeIntentListener() {
    if (!Platform.isAndroid) return;

    platform.setMethodCallHandler((call) async {
      if (call.method == 'onIntent') {
        final args = call.arguments as Map<dynamic, dynamic>;
        final action = args['action'] as String? ?? '';
        final data = args['data'] as String? ?? '';
        final type = args['type'] as String? ?? '';

        debugPrint('=== Native Intent Received ===');
        debugPrint('Action: $action');
        debugPrint('Data: $data');
        debugPrint('Type: $type');

        // Store the native action for later use
        _lastNativeAction = action;
        _lastNativeActionAt = DateTime.now();

        // The actual link handling is done by flutter_sharing_intent and app_links
        // We just store the action here to determine the correct mode later
      }
    });
  }

  /// Determines the correct processing mode based on native intent action
  /// ACTION_SEND = SHARE mode (user wants to share TO someone)
  /// ACTION_VIEW = OPEN mode (user wants to open a link)
  ProcessingMode _determineMode(String link) {
    // Check if we have recent native intent info
    if (_lastNativeAction != null &&
        _lastNativeActionAt != null &&
        DateTime.now().difference(_lastNativeActionAt!).inMilliseconds < 2000) {
      debugPrint('=== Determining mode from native action ===');
      debugPrint('Native action: $_lastNativeAction');
      debugPrint('Link: $link');

      // ACTION_SEND = User is sharing FROM another app TO UniTune
      // This means they want to create a UniTune link (SHARE mode)
      if (_lastNativeAction == 'android.intent.action.SEND') {
        debugPrint('Mode: SHARE (ACTION_SEND detected)');
        return ProcessingMode.share;
      }

      // ACTION_VIEW = User clicked a link
      // This means they want to open it (OPEN mode)
      if (_lastNativeAction == 'android.intent.action.VIEW') {
        debugPrint('Mode: OPEN (ACTION_VIEW detected)');
        return ProcessingMode.open;
      }
    }

    // Fallback: Determine mode based on link type
    // UniTune links = OPEN mode (someone shared a UniTune link)
    // Music links = Could be either, default to SHARE for safety
    if (link.contains('unitune')) {
      debugPrint('Mode: OPEN (unitune link, no native action)');
      return ProcessingMode.open;
    }

    debugPrint('Mode: SHARE (fallback default)');
    return ProcessingMode.share;
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

    // Filter unitune.art links - only handle /s/* and /p/*
    // All other paths (landing page, content pages) should open in browser
    if (uri.host.contains('unitune') &&
        (uri.scheme == 'https' || uri.scheme == 'http')) {
      if (!_shouldOpenInApp(uri)) {
        debugPrint('Opening unitune.art link in browser: $uri');
        _openInBrowser(uri);
        return;
      }
    }

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
        if (_shouldSkipDuplicate(
          validationResult.sanitizedUrl,
          ProcessingMode.open,
        )) {
          return;
        }
        _markHandled(validationResult.sanitizedUrl, ProcessingMode.open);
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
      final (musicUrl, nickname) = UniTuneLinkEncoder.decodeShareLinkPath(
        encodedPath,
      );

      if (musicUrl != null && musicUrl.isNotEmpty) {
        debugPrint(
          'OPEN mode: Extracted music URL from unitune.art path: $musicUrl (nickname: ${nickname ?? "none"})',
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
        if (_shouldSkipDuplicate(
          validationResult.sanitizedUrl,
          ProcessingMode.open,
        )) {
          debugPrint('=== Skipping duplicate deep link ===');
          return;
        }
        _markHandled(validationResult.sanitizedUrl, ProcessingMode.open);

        _navigateToProcessing(
          validationResult.sanitizedUrl,
          ProcessingMode.open,
          sharedByNickname: nickname,
        );
        return;
      }
    }

    // Direct music link (intercepted from Spotify/Tidal/etc.)
    final link = uri.toString();
    if (_isMusicLink(link)) {
      // CRITICAL: Determine mode based on native intent action
      // ACTION_VIEW = OPEN mode (user clicked link in WhatsApp/Browser)
      // ACTION_SEND would have been handled by _handleSharedFiles already
      final mode = _determineMode(link);

      debugPrint('Deep link music URL: $link');
      debugPrint('Determined mode: $mode');

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

      // Check duplicate with the determined mode
      if (_shouldSkipDuplicate(validationResult.sanitizedUrl, mode)) {
        debugPrint('=== Skipping duplicate deep link ($mode mode) ===');
        return;
      }

      // Mark as handled and navigate
      _markHandled(validationResult.sanitizedUrl, mode);
      _navigateToProcessing(validationResult.sanitizedUrl, mode);
    }
  }

  void _navigateToPlaylistImport(String playlistId) {
    debugPrint('DeepLink.navigate playlist import id=$playlistId');
    _router.go('/playlists/import?id=$playlistId');
  }

  /// Check if a unitune.art link should open in the app
  /// Only /s/* (share links) and /p/* (playlist links) open in app
  /// Everything else (landing page, content pages) opens in browser
  bool _shouldOpenInApp(Uri uri) {
    if (uri.path.startsWith('/s/')) return true; // Share links
    if (uri.path.startsWith('/p/')) return true; // Playlist links
    return false; // Everything else opens in browser
  }

  /// Opens a URL in the external browser
  /// Uses platformBrowserWithTitle to avoid Android re-intercepting the link
  Future<void> _openInBrowser(Uri uri) async {
    try {
      // Use platformBrowserWithTitle mode to force opening in browser
      // This prevents Android from showing the app picker again
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
    } catch (e) {
      debugPrint('Error opening URL in browser: $e');
      // Fallback: try external application mode
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e2) {
        debugPrint('Fallback also failed: $e2');
      }
    }
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
        final (decodedUrl, _) = UniTuneLinkEncoder.decodeShareLinkPath(
          encodedPath,
        );
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
          debugPrint('=== Share intent extracted link: $link ===');

          // CRITICAL: Determine mode based on native intent action
          final mode = _determineMode(link);
          debugPrint('Determined mode: $mode');

          // Handle playlist links
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

          // Extract actual music URL if it's a unitune link
          final actualMusicUrl = link.contains('unitune')
              ? _extractMusicUrlFromUnituneLink(link)
              : link;

          // Validate the URL before processing
          final validationResult = UrlValidator.validateAndSanitize(
            actualMusicUrl,
          );
          if (!validationResult.isValid) {
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

          // Check if playlist creator is active
          if (mode == ProcessingMode.share &&
              ref.read(playlistCreationActiveProvider)) {
            debugPrint(
              'PlaylistCreator.active received link: ${validationResult.sanitizedUrl}',
            );
            ref.read(playlistIncomingLinkProvider.notifier).state =
                validationResult.sanitizedUrl;
            return;
          }

          // Check for duplicates
          if (_shouldSkipDuplicate(validationResult.sanitizedUrl, mode)) {
            debugPrint('=== Skipping duplicate share intent ($mode mode) ===');
            return;
          }

          // Mark as handled and navigate
          _markHandled(validationResult.sanitizedUrl, mode);
          _navigateToProcessing(validationResult.sanitizedUrl, mode);
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

    // unitune.art links are NOT music links
    // They are handled separately by _shouldOpenInApp()
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

  void _navigateToProcessing(
    String link,
    ProcessingMode mode, {
    String? sharedByNickname,
  }) {
    debugPrint('=== _navigateToProcessing called ===');
    debugPrint('Link: $link');
    debugPrint('Mode: $mode');
    debugPrint('sharedByNickname: ${sharedByNickname ?? "none"}');
    debugPrint('Current _pendingLink: $_pendingLink');

    // CRITICAL: If there's already a pending navigation for this link,
    // don't start another one. This prevents SHARE and OPEN mode from
    // racing and clearing each other's pending navigation.
    if (_pendingLink == link) {
      debugPrint('=== Navigation already pending for this link, skipping ===');
      return;
    }

    ref.read(incomingLinkProvider.notifier).state = link;

    final modeParam = mode == ProcessingMode.open ? 'open' : 'share';
    String target =
        '/process?link=${Uri.encodeComponent(link)}&mode=$modeParam';
    if (sharedByNickname != null && sharedByNickname.isNotEmpty) {
      target += '&nickname=${Uri.encodeComponent(sharedByNickname)}';
    }

    debugPrint('Target route: $target');

    _pendingLink = link;
    _pendingAttempts = 0;
    _tryNavigatePending(target);
  }

  void _tryNavigatePending(String target) {
    debugPrint(
      '=== _tryNavigatePending called (attempt $_pendingAttempts) ===',
    );
    debugPrint('Pending link: $_pendingLink');
    debugPrint('Target: $target');

    if (_pendingLink == null) {
      debugPrint('Pending link is null, aborting navigation');
      return;
    }

    // ALWAYS use addPostFrameCallback to ensure navigation happens AFTER
    // the current frame is complete. This is critical when the app resumes
    // from background: the intent arrives during the resume rebuild, and
    // calling push() immediately gets lost because the framework is still
    // rebuilding the widget tree / recreating the Surface.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('=== Post-frame callback executing ===');
      debugPrint('Pending link in callback: $_pendingLink');

      if (_pendingLink == null) {
        debugPrint('Pending link cleared before post-frame callback');
        return;
      }

      // Use _router.push() instead of go() to maintain navigation stack
      // This allows ProcessingScreen to properly pop back to previous screen
      debugPrint('Using _router.push() to navigate (post-frame): $target');
      _router.push(target);

      debugPrint('=== Clearing pending link after navigation ===');
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
      // CRITICAL: Override onException to prevent GoRouter from trying to route external URLs
      // When the app is opened via an external music link, GoRouter tries to interpret it as a route
      // This causes the errorBuilder to be called, which shows MainShell instead of ProcessingScreen
      onException: (context, state, router) {
        debugPrint('=== GoRouter.onException called ===');
        debugPrint('Error: ${state.error}');
        debugPrint('URI: ${state.uri}');

        // If it's an external URL (not a /path), ignore it completely
        // The actual handling is done by _handleDeepLink
        if (state.uri.scheme == 'https' || state.uri.scheme == 'http') {
          if (!state.uri.host.contains('unitune')) {
            debugPrint(
              'Ignoring external URL exception - handled by _handleDeepLink',
            );
            // Don't navigate anywhere - let _handleDeepLink handle it
            return;
          }
        }

        // For actual routing errors, go to home
        debugPrint('Navigating to /home due to routing error');
        router.go('/home');
      },
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
              onBack: () => context.go('/onboarding/welcome'),
              onContinue: () {
                // Conditional navigation based on platform
                if (Platform.isAndroid) {
                  context.go('/onboarding/link-interception');
                } else {
                  context.go('/onboarding/messenger');
                }
              },
            ),
            transitionsBuilder: _slideTransition,
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ),
        GoRoute(
          path: '/onboarding/link-interception',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: LinkInterceptionScreen(
              onBack: () => context.go('/onboarding/music'),
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
              onBack: () {
                // Conditional back navigation based on platform
                if (Platform.isAndroid) {
                  context.go('/onboarding/link-interception');
                } else {
                  context.go('/onboarding/music');
                }
              },
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
            debugPrint('Full URI: ${state.uri}');

            final linkParam = state.uri.queryParameters['link'] ?? '';
            final link = Uri.decodeComponent(linkParam);
            final modeParam =
                state.uri.queryParameters['mode']?.toLowerCase() ?? 'share';
            final mode = modeParam == 'open'
                ? ProcessingMode.open
                : ProcessingMode.share;
            final nicknameParam = state.uri.queryParameters['nickname'];
            final nickname = nicknameParam != null && nicknameParam.isNotEmpty
                ? Uri.decodeComponent(nicknameParam)
                : null;

            debugPrint('Decoded link: $link');
            debugPrint('Mode: $mode');
            debugPrint('sharedByNickname: ${nickname ?? "none"}');
            debugPrint('Creating ProcessingScreen widget...');

            final screen = ProcessingScreen(
              incomingLink: link,
              mode: mode,
              sharedByNickname: nickname,
            );
            debugPrint('ProcessingScreen widget created');

            return CustomTransitionPage(
              key: state.pageKey,
              child: screen,
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

        // CRITICAL FIX: Ignore external music links - they are handled by _handleDeepLink
        // GoRouter should NOT try to route these URLs
        if ((uri.scheme == 'https' || uri.scheme == 'http') &&
            !uri.host.contains('unitune')) {
          debugPrint(
            'GoRouter.redirect: Ignoring external music link (handled by _handleDeepLink)',
          );
          return null; // Let _handleDeepLink handle it
        }

        // If it's a unitune:// deep link, redirect to home
        // The actual processing is handled by _handleDeepLink via app_links
        if (uri.scheme == 'unitune') {
          debugPrint('GoRouter.redirect to /home for unitune scheme');
          return '/home';
        }

        // Handle unitune.art HTTPS links
        if ((uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.contains('unitune')) {
          // Playlist links - open in app
          if (uri.path.startsWith('/p/')) {
            final playlistId = uri.path.replaceFirst('/p/', '');
            if (playlistId.isNotEmpty) {
              debugPrint(
                'GoRouter.redirect to /playlists/import for playlist link',
              );
              return '/playlists/import?id=$playlistId';
            }
          }

          // Share links - open in app
          if (uri.path.startsWith('/s/')) {
            debugPrint('GoRouter.redirect to /home for share link');
            return '/home';
          }

          // All other unitune.art paths - open in browser
          debugPrint('Opening in browser: ${uri.toString()}');
          launchUrl(uri, mode: LaunchMode.externalApplication);
          return '/home';
        }

        return null;
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
