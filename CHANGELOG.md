# Changelog

All notable changes to UniTune will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.3] - 2026-02-18

### Added

- Link Interception onboarding step: dedicated screen during first launch explaining the feature with enable toggle (Android only)
- Reusable onboarding navigation buttons widget for consistent back/continue flow
- Onboarding progress bar widget showing current step across all onboarding screens
- Brand logo widget for consistent platform logo rendering across the app
- Dynamic processing messages: rotating status text during link analysis and conversion instead of static string

### Changed

- Home screen layout and interaction improvements
- Onboarding screens refactored to use shared navigation and progress widgets
- Settings screen restructured for clarity

### Fixed

- Processing screen duplicate link handling now checks both link AND mode, allowing the same link to correctly route as SHARE or OPEN depending on intent

## [1.4.2] - 2026-02-17

### Added

- Native Android intent listener via `MethodChannel` in MainActivity
- Smart processing mode detection: `ACTION_SEND` intents correctly route to SHARE mode, `ACTION_VIEW` intents to OPEN mode
- Playlists list screen improvements and additional track display options

### Fixed

- UniTune no longer confuses share intents and deep link opens when both occur within the same session
- Processing screen correctly determines user intent when link interception and direct share are used together

### Technical

- Added `MethodChannel('de.unitune.unitune/intent')` bridge for native Android intent data
- `_determineMode()` reads native action within a 2-second window to resolve SHARE vs. OPEN ambiguity
- Extended `AndroidManifest.xml` intent filters to support additional music link patterns

## [1.4.1] - 2026-02-15

### Changed

- Replaced all button styles with liquid_glass_widgets for clean glassmorphism
- Updated inline action buttons to match glass button styling
- Initialized liquid_glass_widgets at app startup to avoid shader flicker

## [1.4.0] - 2026-02-12

### Added

- Mini-Playlists feature: Create collections of 3-10 songs
- Playlist creator with drag-and-drop track reordering
- Visual playlist preview with cover grid (1-4 album arts)
- QR code generation for playlists with save and share options
- Visual share cards with album art collage and track list
- Batch conversion API endpoint for processing multiple URLs
- Content type detection (track, album, artist, playlist)
- New Playlists tab in bottom navigation
- Playlist detail view with track list and sharing options
- Local playlist storage with Base64 encoding for sharing
- Cover collage generator for multi-track playlists
- Playlist share links stored on server with short IDs
- Playlist import flow from unitune.art playlist links

### Changed

- Bottom navigation now has 4 tabs (Home, History, Playlists, Settings)
- Updated dependencies: freezed 3.0.0, freezed_annotation 3.0.0
- QR code styling updated to use eyeStyle and dataModuleStyle
- Updated privacy policy disclosures for server-side playlists and no-ads support model
- Removed playlist size limits in UI and storage
- Share links now use server-side playlist IDs

### Technical

- Added qr_flutter 4.1.0 for QR code generation
- Added screenshot 2.3.0 for widget-to-image conversion
- Added image 4.1.7 for cover collage processing
- Added path_provider 2.1.2 for file system access
- Added uuid 4.3.3 for unique playlist IDs
- Implemented PlaylistRepository with CRUD operations
- Implemented BatchConversionService for multi-URL processing
- Implemented CoverCollageGenerator for visual previews
- Implemented ShareCardGenerator for social media cards
- Added playlist remote repository for server API integration

## [1.3.4] - 2026-02-12

### Added

- Smart paste from clipboard for valid music links on Home
- Inline link validation feedback with success/error states

### Changed

- Share CTA now guides users before invalid submissions

## [1.3.3] - 2026-02-12

### Added

- Paste-to-share card on Home for direct link input
- Error recovery actions in Processing: open in browser, copy link, alternate services
- History filters by service with summary badge for top platform
- Auto-detection of installed music and messenger apps during onboarding

### Changed

- Processing navigation unified through GoRouter with mode-based routing
- Liquid glass layers upgraded to performance-optimized rendering on key screens

### Fixed

- Base64 unitune.art share links now decode correctly in share intents
- URL normalization handles missing schemes more reliably

## [1.3.2] - 2026-02-10

### Added

- AdMob integration with Native Ads in History Screen (every 6th entry)
- AdMob Banner Ads in Processing Screen
- Comprehensive AdMob documentation and setup guide
- Test mode for AdMob with Google test ad units

### Improved

- AdMob helper class with clear production/testing toggle
- Ad placement optimized for user experience
- Liquid Glass design integration for ad containers

## [1.3.1] - 2026-02-03

### Fixed

- Share intent not processing music links when shared directly to UniTune
- Music links shared to UniTune now always work regardless of interception settings
- Removed overly complex interception logic that was blocking direct shares

### Changed

- Simplified share intent handling logic for better reliability
- Music links shared to UniTune are always processed in SHARE mode
- UniTune.art links shared to UniTune are processed in OPEN mode

## [1.3.0] - 2026-02-03

### Added

- **Music Link Interception (Android only)**: UniTune can now intercept Spotify, Tidal, Apple Music, YouTube Music, Deezer, and Amazon Music links
- Settings toggle for Music Link Interception (disabled by default, Android only)
- Info dialog explaining how link interception works
- Support for direct deep linking from unitune.art URLs (bypasses browser)
- Button to open Android link handling settings directly from app
- Comprehensive error handling for disposed widgets during async operations

### Changed

- Android App Links verification now properly configured with SHA256 fingerprint
- iOS Universal Links configuration updated (requires Team ID)
- Intent filters added for all major music streaming platforms
- "Get UniTune" button on web landing page now links to GitHub repository
- Advanced settings section only visible on Android devices
- Improved processing flow to handle widget disposal during API calls

### Fixed

- App hanging/crashing after successful API response when opening music links
- "Cannot use ref after widget disposed" errors during link processing
- Widget unmounting during API calls causing incomplete operations
- Null safety issues when accessing music service preferences after disposal
- Apple Music URL parsing for `/song/name/ID` format
- HTTP client disposal errors by using shared static client
- Processing continues even if widget unmounts (music app still launches)

### Technical

- Added intent filters for music service domains in AndroidManifest.xml
- Extended PreferencesManager with interceptMusicLinks setting
- Updated .well-known/apple-app-site-association with correct bundle ID
- Improved deep link handling for music platform URLs
- Added Platform.isAndroid checks for Android-specific features
- Protected all ref.read() and ref.invalidate() calls with try-catch blocks
- Added 10-second timeout to API requests
- Comprehensive debug logging for troubleshooting
- JSON parsing error handling with stack traces

## [1.2.0] - 2026-02-03

### Added

- Link caching system to reduce API calls and improve performance
- Haptic feedback on help button and action buttons
- UniTune logo loading animation during link conversion
- Pan gesture support for chart scrubbing (immediate drag without hold)
- **share_plus package for native OS share dialog support**

### Changed

- **All UI elements now use dynamic theme colors from album artwork**
- **Completely removed intermediate share screen - always shares directly**
- Onboarding buttons now use dynamic theme colors
- Removed obsolete share options sheet for cleaner UX
- Direct sharing to messenger apps when installed
- System share opens OS share dialog when messenger not installed or systemShare selected
- Direct opening in music apps when installed (skips intermediate screen)
- Chart automatically refreshes after sharing/receiving songs
- Loading animation shows only logo icon without "UniTune" text

### Fixed

- Already shared songs now use cached data instead of new API requests
- Graphical border bug when pressing share/open buttons
- Chart scrubbing now works on first touch (no need to release and hold again)
- Chart not updating after sharing until manual reload
- **"Open in Tidal" (and other music apps) screen no longer shows - opens directly when app is installed**
- **Share screen no longer shows when messenger is selected - goes directly to messenger app**
- **System share now properly opens OS share dialog when messenger not installed or systemShare selected**
- **History screen now uses system share fallback when messenger not installed**
- App availability checks before attempting to open music/messenger apps
- Deprecated withOpacity() calls replaced with withValues()

### Technical

- Implemented LinkCacheRepository with 7-day expiration
- Cache keys include both URL and preferred music service
- Automatic provider invalidation for real-time UI updates
- Better error handling with user-friendly messages
- Removed unused code and imports

## [1.1.0] - 2026-02-02

### Added

- Metadata caching for improved performance
- Cover image previews in messaging apps (WhatsApp, Telegram, Signal, etc.)
- Actual song metadata in Open Graph tags for better link previews

### Changed

- Migrated to Base64 link encoding (prevents browser phishing warnings)
- Removed legacy URL-encoded link format
- Updated privacy policy with metadata caching disclosure
- Improved Tidal URL parsing (now handles /u and /uLog suffixes)

### Fixed

- Cover images not showing in messaging app previews
- Tidal URLs with trailing suffixes not being recognized
- Browser phishing warnings on shared links

### Technical

- Worker: Implemented `fetchAndCacheMetadata()` function
- Worker: Cache uses Base64 share link ID as key (efficient)
- Worker: Simplified server-side rendering (removed duplicate caching)
- Backend: Improved Tidal URL regex patterns
- Backend: Better error logging for debugging
- App: Removed legacy link format fallback
- App: Throws `UnsupportedError` on parse failures instead of fallback
- GDPR compliant: Only public song data cached (no personal information)
- Cache expires automatically after 24 hours

### Breaking Changes

- Old URL-encoded share links (format: `https%3A%2F%2F...`) no longer work
- Only Base64-encoded links are supported (format: `dGlkYWw6dHJhY2s6MTIz`)

## [1.0.0] - 2026-01-29

### Added

- Universal music link conversion between 6 platforms:
  - Spotify
  - Apple Music
  - YouTube Music
  - Deezer
  - TIDAL
  - Amazon Music
- Share via 5 messaging options:
  - WhatsApp
  - Telegram
  - Signal
  - SMS
  - System Share
- Sharing statistics with interactive graphs
- History tracking with search and filtering
- Dynamic color theming based on album artwork
- Liquid glass UI effects
- Dark theme optimized design
- Onboarding flow for first-time users
- Settings for preferred services
- URL validation and security features

### Technical

- Flutter 3.38.6 with Dart 3.10.7
- Riverpod state management
- Go Router navigation
- Local storage with SharedPreferences
- HTTP networking
- Deep linking support
- Share intent handling

[Unreleased]: https://github.com/FlazeIGuess/unitune/compare/v1.4.3...HEAD
[1.4.3]: https://github.com/FlazeIGuess/unitune/compare/v1.4.2...v1.4.3
[1.4.2]: https://github.com/FlazeIGuess/unitune/compare/v1.4.1...v1.4.2
[1.4.1]: https://github.com/FlazeIGuess/unitune/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/FlazeIGuess/unitune/compare/v1.3.4...v1.4.0
[1.3.4]: https://github.com/FlazeIGuess/unitune/compare/v1.3.3...v1.3.4
[1.3.3]: https://github.com/FlazeIGuess/unitune/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/FlazeIGuess/unitune/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/FlazeIGuess/unitune/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/FlazeIGuess/unitune/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/FlazeIGuess/unitune/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/FlazeIGuess/unitune/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/FlazeIGuess/unitune/releases/tag/v1.0.0
