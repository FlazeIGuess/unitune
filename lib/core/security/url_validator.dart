/// URL validation and sanitization for security purposes.
///
/// This component validates incoming URLs to prevent URL injection attacks
/// and ensures only legitimate music service links are processed.
class UrlValidator {
  /// List of whitelisted music service domains
  static const List<String> whitelistedDomains = [
    'open.spotify.com',
    'spotify.link',
    'music.apple.com',
    'tidal.com',
    'listen.tidal.com',
    'music.youtube.com',
    'youtu.be',
    'deezer.page.link',
    'deezer.com',
    'music.amazon.com',
    'amazon.com',
    'unitune.art',
  ];

  /// List of dangerous protocols that should be rejected
  static const List<String> dangerousProtocols = [
    'javascript:',
    'data:',
    'file:',
  ];

  /// Validates if a URL is from a whitelisted music service domain.
  ///
  /// Returns true if the URL's domain is in the whitelist, false otherwise.
  /// Also returns false if the URL is malformed or cannot be parsed.
  ///
  /// Example:
  /// ```dart
  /// UrlValidator.isValidMusicUrl('https://open.spotify.com/track/123'); // true
  /// UrlValidator.isValidMusicUrl('https://evil.com/track/123'); // false
  /// ```
  static bool isValidMusicUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      // Check if the host matches any whitelisted domain
      for (final domain in whitelistedDomains) {
        // Skip amazon.com in this loop - it needs special handling
        if (domain == 'amazon.com') continue;

        if (host == domain || host.endsWith('.$domain')) {
          return true;
        }
      }

      // Special case for amazon.com/music - check both host and path
      if (host == 'amazon.com' || host.endsWith('.amazon.com')) {
        if (uri.path.startsWith('/music')) {
          return true;
        }
        // If it's amazon.com but not /music path, return false
        return false;
      }

      return false;
    } catch (e) {
      // If URL parsing fails, consider it invalid
      return false;
    }
  }

  /// Validates if a URL is safe (no dangerous protocols).
  ///
  /// Returns true if the URL doesn't use dangerous protocols like
  /// javascript:, data:, or file:. Returns false otherwise.
  ///
  /// Example:
  /// ```dart
  /// UrlValidator.isSafeUrl('https://open.spotify.com/track/123'); // true
  /// UrlValidator.isSafeUrl('javascript:alert("xss")'); // false
  /// ```
  static bool isSafeUrl(String url) {
    final lowerUrl = url.toLowerCase().trim();

    // Check for dangerous protocols
    for (final protocol in dangerousProtocols) {
      if (lowerUrl.startsWith(protocol)) {
        return false;
      }
    }

    return true;
  }

  /// Sanitizes a URL by removing dangerous characters and normalizing it.
  ///
  /// This method:
  /// - Trims whitespace
  /// - Removes null bytes
  /// - Removes control characters
  /// - Normalizes the URL
  ///
  /// Returns the sanitized URL string.
  ///
  /// Example:
  /// ```dart
  /// UrlValidator.sanitizeUrl('  https://spotify.com/track  ');
  /// // Returns: 'https://spotify.com/track'
  /// ```
  static String sanitizeUrl(String url) {
    // Trim whitespace
    String sanitized = url.trim();

    // Remove null bytes
    sanitized = sanitized.replaceAll('\x00', '');

    // Remove control characters (ASCII 0-31 except tab, newline, carriage return)
    sanitized = sanitized.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'),
      '',
    );

    // Remove any remaining newlines and carriage returns
    sanitized = sanitized.replaceAll('\n', '');
    sanitized = sanitized.replaceAll('\r', '');
    sanitized = sanitized.replaceAll('\t', '');

    return sanitized;
  }

  /// Validates a URL completely (both whitelist and safety checks).
  ///
  /// This is a convenience method that combines [isValidMusicUrl] and [isSafeUrl].
  /// Returns true only if the URL passes both checks.
  ///
  /// Example:
  /// ```dart
  /// UrlValidator.isValid('https://open.spotify.com/track/123'); // true
  /// UrlValidator.isValid('javascript:alert("xss")'); // false
  /// UrlValidator.isValid('https://evil.com/track/123'); // false
  /// ```
  static bool isValid(String url) {
    return isSafeUrl(url) && isValidMusicUrl(url);
  }

  /// Validates and sanitizes a URL in one step.
  ///
  /// Returns a [UrlValidationResult] containing:
  /// - isValid: whether the URL passed validation
  /// - sanitizedUrl: the sanitized version of the URL
  /// - errorMessage: a user-friendly error message if validation failed
  ///
  /// Example:
  /// ```dart
  /// final result = UrlValidator.validateAndSanitize('  https://spotify.com/track  ');
  /// if (result.isValid) {
  ///   // Use result.sanitizedUrl
  /// } else {
  ///   // Show result.errorMessage
  /// }
  /// ```
  static UrlValidationResult validateAndSanitize(String url) {
    // First sanitize the URL
    var sanitized = sanitizeUrl(url);
    sanitized = _normalizeUrl(sanitized);

    // Check if it's safe (no dangerous protocols)
    if (!isSafeUrl(sanitized)) {
      return UrlValidationResult(
        isValid: false,
        sanitizedUrl: sanitized,
        errorMessage:
            'This URL uses a dangerous protocol and cannot be processed.',
      );
    }

    // Check if it's from a whitelisted domain
    if (!isValidMusicUrl(sanitized)) {
      return UrlValidationResult(
        isValid: false,
        sanitizedUrl: sanitized,
        errorMessage: 'This URL is not from a supported music service.',
      );
    }

    // All checks passed
    return UrlValidationResult(
      isValid: true,
      sanitizedUrl: sanitized,
      errorMessage: null,
    );
  }

  static String _normalizeUrl(String url) {
    if (url.contains('://')) return url;
    final candidate = 'https://$url';
    if (isValidMusicUrl(candidate)) {
      return candidate;
    }
    return url;
  }
}

/// Result of URL validation and sanitization.
class UrlValidationResult {
  /// Whether the URL passed validation
  final bool isValid;

  /// The sanitized version of the URL
  final String sanitizedUrl;

  /// User-friendly error message if validation failed (null if valid)
  final String? errorMessage;

  UrlValidationResult({
    required this.isValid,
    required this.sanitizedUrl,
    this.errorMessage,
  });
}
