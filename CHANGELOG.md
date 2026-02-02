# Changelog

All notable changes to UniTune will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Future features will be listed here

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

[Unreleased]: https://github.com/FlazeIGuess/unitune/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/FlazeIGuess/unitune/releases/tag/v1.1.0
[1.0.0]: https://github.com/FlazeIGuess/unitune/releases/tag/v1.0.0
