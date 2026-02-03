<div align="center">
  <img src="assets/icon/app_icon.svg" alt="UniTune Logo" width="120" height="120">
  
  # UniTune
  
  **Universal Music Link Sharing**
  
  Share your favorite music across all streaming platforms with a single tap
  
  [![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%203.0-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
  [![Flutter](https://img.shields.io/badge/Flutter-3.27.1-02569B?logo=flutter)](https://flutter.dev)
  [![Build Status](https://github.com/FlazeIGuess/unitune/workflows/Build%20Android%20APK/badge.svg)](https://github.com/FlazeIGuess/unitune/actions)
  [![Version](https://img.shields.io/badge/version-1.3.1-brightgreen.svg)](https://github.com/FlazeIGuess/unitune/releases)
</div>

---

## What is UniTune?

UniTune eliminates the frustration of incompatible music links. When a friend shares a Spotify link but you use Apple Music, UniTune instantly converts it to your preferred platform. Built with Flutter and featuring a stunning liquid glass design, UniTune makes cross-platform music sharing effortless while keeping your data completely private.

## Key Features

### Universal Link Conversion
Convert music links seamlessly between all major streaming platforms. Paste any music link and get instant access across Spotify, Apple Music, YouTube Music, Deezer, TIDAL, and Amazon Music.

### Smart Sharing Integration
Share directly to your favorite messaging apps with intelligent platform detection. UniTune integrates with WhatsApp, Telegram, Signal, SMS, and system share functionality for one-tap sharing.

### Privacy-First Architecture
Your data stays on your device. No accounts, no tracking, no cloud storage. UniTune operates entirely locally with zero data collection or external analytics.

### Dynamic Visual Experience
Watch the app transform with every song. Album artwork automatically influences the color scheme, creating a unique visual experience that adapts to your music taste.

### Comprehensive History & Analytics
Track your sharing patterns with detailed statistics and trend graphs. View your most shared songs, favorite platforms, and sharing frequency over customizable time periods.

### Modern Liquid Glass Design
Experience a premium interface with smooth animations and glassmorphism effects. The fluid design language creates an immersive, Apple-inspired aesthetic across every screen.

## Supported Platforms

<table>
<tr>
<td width="50%" valign="top">

### Music Streaming Services

| Platform | Status |
|----------|--------|
| Spotify | ✓ Supported |
| Apple Music | ✓ Supported |
| YouTube Music | ✓ Supported |
| Deezer | ✓ Supported |
| TIDAL | ✓ Supported |
| Amazon Music | ✓ Supported |

</td>
<td width="50%" valign="top">

### Sharing Channels

| Channel | Status |
|---------|--------|
| WhatsApp | ✓ Supported |
| Telegram | ✓ Supported |
| Signal | ✓ Supported |
| SMS / iMessage | ✓ Supported |
| System Share | ✓ Supported |

</td>
</tr>
</table>

## Getting Started

### Download & Install

<table>
<tr>
<td width="25%"><strong>Platform</strong></td>
<td width="50%"><strong>Download</strong></td>
<td width="25%"><strong>Requirements</strong></td>
</tr>
<tr>
<td>Android</td>
<td><a href="https://github.com/FlazeIGuess/unitune/releases">GitHub Releases (APK)</a></td>
<td>Android 5.0+</td>
</tr>
<tr>
<td>iOS</td>
<td>Coming Soon</td>
<td>iOS 12.0+</td>
</tr>
<tr>
<td>F-Droid</td>
<td>Coming Soon</td>
<td>-</td>
</tr>
<tr>
<td>Google Play</td>
<td>Coming Soon</td>
<td>-</td>
</tr>
<tr>
<td>App Store</td>
<td>Coming Soon</td>
<td>-</td>
</tr>
</table>

### Quick Start

1. Download and install UniTune from GitHub Releases
2. Open the app and complete the onboarding flow
3. Select your preferred music streaming service
4. Choose your favorite messaging apps for sharing
5. Start converting and sharing music links

## Development Setup

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Flutter SDK | 3.27.1+ | Framework |
| Dart SDK | 3.10.7+ | Language |
| Android Studio | Latest | Android development |
| Xcode | Latest | iOS development (macOS only) |

### Local Development

```bash
# Clone the repository
git clone https://github.com/FlazeIGuess/unitune.git
cd unitune/unitune-app

# Install dependencies
flutter pub get

# Generate code (Riverpod)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app in debug mode
flutter run

# Run with specific device
flutter run -d <device-id>
```

### Building for Production

```bash
# Android APK (for direct distribution)
flutter build apk --release

# Android App Bundle (for Google Play Store)
flutter build appbundle --release

# iOS (macOS only, requires Apple Developer account)
flutter build ios --release

# Generate app icons
flutter pub run flutter_launcher_icons
```

### Code Generation

UniTune uses code generation for Riverpod providers:

```bash
# Watch mode (auto-regenerate on changes)
flutter pub run build_runner watch

# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs
```

## Technical Architecture

### Project Structure

```
lib/
├── core/                    # Shared foundation
│   ├── animations/         # Page transitions, fade effects
│   ├── constants/          # Service definitions, app constants
│   ├── security/           # URL validation, input sanitization
│   ├── theme/              # Dynamic theming, color extraction
│   ├── utils/              # Helpers, logging, responsive utilities
│   └── widgets/            # Reusable UI components (liquid glass, buttons)
│
├── data/                    # Data layer
│   ├── models/             # Data models (HistoryEntry, etc.)
│   └── repositories/       # Data access (History, Cache, API)
│
└── features/                # Feature modules
    ├── home/               # Main conversion screen
    ├── history/            # Sharing history & statistics
    ├── settings/           # App preferences & configuration
    ├── onboarding/         # First-run experience
    └── sharing/            # Share intent handling
```

### Technology Stack

| Category | Technology | Purpose |
|----------|-----------|---------|
| Framework | Flutter 3.27.1 | Cross-platform UI |
| Language | Dart 3.10.7 | Programming language |
| State Management | Riverpod 2.6.1 | Reactive state management |
| Navigation | GoRouter 14.8.1 | Declarative routing & deep links |
| Local Storage | SharedPreferences 2.3.5 | Persistent key-value storage |
| Networking | HTTP 1.3.0 | API communication |
| UI Effects | Liquid Glass Renderer 0.2.0 | Glassmorphism effects |
| Charts | FL Chart 0.69.0 | Statistics visualization |
| Color Extraction | Palette Generator 0.3.3 | Dynamic theming from images |

### Design Patterns

- **Feature-First Architecture**: Organized by features rather than layers
- **Repository Pattern**: Abstracted data access layer
- **Provider Pattern**: Riverpod for dependency injection and state
- **Responsive Design**: Adaptive layouts for different screen sizes
- **Dynamic Theming**: Runtime color scheme generation from album art

## Privacy & Security

UniTune is built with privacy as a core principle:

### Data Storage
- **100% Local Storage**: All data remains on your device
- **No Cloud Sync**: No external servers store your information
- **No User Accounts**: No registration or authentication required
- **No Tracking**: Zero analytics, telemetry, or usage tracking

### Security Measures
- **URL Validation**: All input URLs are validated and sanitized
- **Secure Communication**: HTTPS-only API communication
- **No Data Collection**: We don't collect, store, or share any user data
- **Open Source**: Fully auditable codebase under AGPL-3.0

### Permissions

| Permission | Purpose | Required |
|------------|---------|----------|
| Internet | Convert music links via API | Yes |
| Query Installed Apps | Detect available music/messaging apps | Yes |
| Read/Write Storage | Save sharing history locally | Yes |

UniTune requests only essential permissions and never accesses sensitive data like contacts, location, or camera.

## Contributing

We welcome contributions from the community! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

### How to Contribute

1. **Fork the Repository**: Create your own fork of the project
2. **Create a Branch**: `git checkout -b feature/your-feature-name`
3. **Make Changes**: Implement your feature or fix
4. **Test Thoroughly**: Ensure all existing tests pass and add new ones
5. **Follow Style Guidelines**: Use Flutter/Dart conventions
6. **Commit Changes**: Write clear, descriptive commit messages
7. **Push to Fork**: `git push origin feature/your-feature-name`
8. **Open Pull Request**: Submit a PR with detailed description

### Development Guidelines

- Follow Flutter and Dart style guidelines
- Write unit tests for new features
- Update documentation for API changes
- Ensure CI/CD checks pass
- Use English for all code, comments, and documentation
- No emojis in code or documentation (use icons where appropriate)
- Maintain the liquid glass design language

### Code Style

```dart
// Good: Clear naming, proper formatting
Future<List<HistoryEntry>> fetchHistory({
  required int limit,
  DateTime? startDate,
}) async {
  // Implementation
}

// Bad: Unclear naming, poor formatting
Future<List<HistoryEntry>> getStuff(int l,DateTime? d)async{
  // Implementation
}
```

### Reporting Issues

Found a bug or have a feature request? Open an issue on GitHub with:
- Clear description of the problem or feature
- Steps to reproduce (for bugs)
- Expected vs actual behavior
- Device and OS version
- Screenshots or logs (if applicable)

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

Made with Love ❤️
