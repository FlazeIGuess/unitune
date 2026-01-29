# UniTune

Universal music link sharing application for Android and iOS. Share songs across different music streaming platforms with a single link.

[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%203.0-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.27.1-02569B?logo=flutter)](https://flutter.dev)
[![Build Status](https://github.com/FlazeIGuess/unitune/workflows/Build%20Android%20APK/badge.svg)](https://github.com/FlazeIGuess/unitune/actions)

## Overview

UniTune converts music links between different streaming platforms, allowing users to share songs with friends regardless of which music service they use. The app features a modern liquid glass UI design and prioritizes user privacy with local-only data storage.

## Features

- **Universal Link Conversion**: Convert links between Spotify, Apple Music, YouTube Music, Deezer, TIDAL, and Amazon Music
- **Direct Sharing**: Share converted links via WhatsApp, Telegram, Signal, SMS, or system share
- **History Tracking**: View your sharing history with statistics and trends
- **Dynamic Theming**: App colors adapt to album artwork
- **Privacy-Focused**: All data stored locally, no tracking or analytics
- **Modern UI**: Liquid glass design with smooth animations

## Supported Services

### Music Platforms
- Spotify
- Apple Music
- YouTube Music
- Deezer
- TIDAL
- Amazon Music

### Messaging Apps
- WhatsApp
- Telegram
- Signal
- SMS / iMessage
- System Share

## Installation

### Requirements
- Android 5.0 (API 21) or higher
- iOS 12.0 or higher (coming soon)

### Download
- **GitHub Releases**: [Download APK](https://github.com/FlazeIGuess/unitune/releases)
- **F-Droid**: Coming soon
- **Google Play Store**: Coming soon
- **Apple App Store**: Coming soon

## Development

### Prerequisites
- Flutter SDK 3.27.1 or higher
- Dart SDK 3.10.7 or higher
- Android Studio / Xcode for platform-specific development

### Setup

```bash
# Clone the repository
git clone https://github.com/FlazeIGuess/unitune.git
cd unitune

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build

```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Build iOS (macOS only)
flutter build ios --release
```

## Architecture

The app follows a feature-first architecture with Riverpod for state management:

```
lib/
├── core/           # Shared utilities, themes, widgets
├── data/           # Data models and repositories
└── features/       # Feature modules (home, history, settings, etc.)
```

### Key Technologies
- Flutter 3.27.1
- Riverpod 2.6.1 (State Management)
- GoRouter 14.8.1 (Navigation & Deep Links)
- SharedPreferences (Local Storage)
- FL Chart (Statistics Visualization)

## Privacy

UniTune is designed with privacy in mind:
- No user accounts or authentication required
- All data stored locally on device
- No analytics or tracking
- No data collection or sharing
- Open source and auditable

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Write tests for new features
- Update documentation as needed
- Ensure all CI checks pass

## Related Projects

- [unitune-api](https://github.com/FlazeIGuess/unitune-api) - Backend API for link conversion
- [unitune-worker](https://github.com/FlazeIGuess/unitune-worker) - Cloudflare Worker for web interface

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0).

See [LICENSE](LICENSE) for details.

### Attribution Requirement
Any use, modification, or distribution of this software must include proper attribution to the original author and project.

## Acknowledgments

- Music link conversion powered by custom API
- UI design inspired by modern glassmorphism trends
- Built with Flutter and Riverpod

## Support

- **Issues**: [GitHub Issues](https://github.com/FlazeIGuess/unitune/issues)
- **Discussions**: [GitHub Discussions](https://github.com/FlazeIGuess/unitune/discussions)

---

Made with Flutter
