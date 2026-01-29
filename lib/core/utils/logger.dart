import 'dart:developer' as developer;

/// Simple logger utility for UniTune
///
/// Usage:
/// ```dart
/// Logger.debug('Processing link...');
/// Logger.info('User action completed');
/// Logger.error('API call failed', error: e);
/// ```
class Logger {
  static const String _tag = 'UniTune';

  /// Log debug messages (only in debug mode)
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _tag,
      level: 500, // Debug level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log info messages
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _tag,
      level: 800, // Info level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log warning messages
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _tag,
      level: 900, // Warning level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error messages
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _tag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }
}
