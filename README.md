# UniTune

UniTune is a music link sharing application that enables users to share music links universally across different streaming platforms. Share a song from Spotify, and your friends can open it in Apple Music, TIDAL, YouTube Music, or any other supported platform.

## Features

- 🎵 Universal music link conversion
- 🔗 Deep linking support (Android App Links & iOS Universal Links)
- 🌐 Web-based share pages
- 🔒 Security-first design with URL validation and XSS protection
- 🛡️ GDPR-compliant consent management
- ⚡ Fast and responsive with Cloudflare Workers backend

## Supported Music Services

- Spotify
- Apple Music
- TIDAL
- YouTube Music
- Deezer
- Amazon Music

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio with Android SDK
- Xcode (for iOS development, macOS only)
- Java Development Kit (JDK) for Android signing

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/unitune.git
   cd unitune
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Environment Variables

### Cloudflare Worker Configuration

The UniTune Cloudflare Worker requires the following environment variables to be configured in `web/cloudflare-worker/wrangler.toml`:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `ADSENSE_PUBLISHER_ID` | Google AdSense publisher ID | `ca-pub-8547021258440704` | Yes |
| `ODESLI_API_ENDPOINT` | Odesli API endpoint URL | `https://api.song.link/v1-alpha.1/links` | Yes |
| `WORKER_VERSION` | Worker version for debugging | `2.2.0` | No |
| `ENVIRONMENT` | Environment name (development/staging/production) | `production` | No |

**Example wrangler.toml configuration:**

```toml
[vars]
ADSENSE_PUBLISHER_ID = "ca-pub-8547021258440704"
ODESLI_API_ENDPOINT = "https://api.song.link/v1-alpha.1/links"
WORKER_VERSION = "2.2.0"
ENVIRONMENT = "production"
```

For detailed environment variable documentation, see [ENVIRONMENT_VARIABLES.md](web/cloudflare-worker/ENVIRONMENT_VARIABLES.md).

## Deployment

### Production Deployment

For comprehensive deployment instructions, including:
- Environment variable configuration
- Android release signing setup
- Deep link verification
- Testing procedures
- Rollback procedures

See the [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) in the project root.

### Quick Deployment Steps

1. **Configure Environment Variables** (see above)
2. **Generate Android Release Keystore** (see [KEYSTORE_SETUP_GUIDE.md](../KEYSTORE_SETUP_GUIDE.md))
3. **Deploy Cloudflare Worker:**
   ```bash
   cd web/cloudflare-worker
   wrangler deploy
   ```
4. **Build Release Apps:**
   ```bash
   # Android
   flutter build appbundle --release
   
   # iOS
   flutter build ios --release
   ```

## Deep Link Configuration

UniTune supports verified deep links for seamless app opening:

### Android App Links
- Configuration: `web/cloudflare-worker/.well-known/assetlinks.json`
- Package name: `de.unitune.unitune`
- Requires SHA256 fingerprint from release keystore

### iOS Universal Links
- Configuration: `web/cloudflare-worker/.well-known/apple-app-site-association`
- Bundle identifier: `com.example.unitune`
- Requires Apple Developer Team ID

### Custom URL Scheme
- Scheme: `unitune://`
- Example: `unitune://open?url=https://open.spotify.com/track/example`

## Testing

Run all tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter test integration_test/
```

Test Cloudflare Worker:
```bash
cd web/cloudflare-worker
npm test
```

## Security

UniTune implements multiple security layers:
- ✅ URL validation against whitelisted music service domains
- ✅ XSS protection with HTML escaping
- ✅ Rate limiting (60 requests/minute per IP)
- ✅ Security headers (CSP, HSTS, X-Frame-Options, etc.)
- ✅ GDPR-compliant consent management
- ✅ Secure error handling without sensitive data exposure

## Privacy

- GDPR-compliant cookie consent banner
- Clear privacy descriptions for iOS permissions
- User-friendly permission rationales for Android
- Privacy policy: [Link to your privacy policy]

## Documentation

- [Deployment Guide](../DEPLOYMENT_GUIDE.md) - Complete deployment instructions
- [Keystore Setup Guide](../KEYSTORE_SETUP_GUIDE.md) - Android signing setup
- [Environment Variables](web/cloudflare-worker/ENVIRONMENT_VARIABLES.md) - Configuration reference
- [Requirements](.kiro/specs/pre-deployment-security-compliance/requirements.md) - Security requirements
- [Design](.kiro/specs/pre-deployment-security-compliance/design.md) - Technical design

## License

[Your License Here]

## Support

For issues, questions, or contributions, please [open an issue](https://github.com/yourusername/unitune/issues) on GitHub.
