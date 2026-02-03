# Changelog

All notable changes to UniTune will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


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

[Unreleased]: https://github.com/FlazeIGuess/unitune/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/FlazeIGuess/unitune/releases/tag/v1.2.0
[1.1.0]: https://github.com/FlazeIGuess/unitune/releases/tag/v1.1.0
[1.0.0]: https://github.com/FlazeIGuess/unitune/releases/tag/v1.0.0
