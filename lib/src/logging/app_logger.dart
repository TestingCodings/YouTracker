import 'package:flutter/foundation.dart';

import '../config/environment.dart';

/// Log levels for structured logging.
enum LogLevel {
  /// Detailed debug information (only in development).
  debug,

  /// General information about app operations.
  info,

  /// Warning messages for potentially problematic situations.
  warning,

  /// Error messages for failures.
  error,
}

/// Structured logger with sensitive data redaction.
///
/// Features:
/// - Automatic redaction of sensitive data (tokens, passwords, keys)
/// - Environment-aware logging (verbose in dev, minimal in prod)
/// - Structured log format with timestamps and levels
/// - Optional custom redaction patterns
///
/// ## Usage:
/// ```dart
/// final logger = AppLogger('AuthService');
/// logger.info('User logged in', {'userId': 'user_123'});
/// logger.debug('Token received', {'token': 'secret_token'}); // Token is redacted
/// logger.error('Login failed', {'error': 'Invalid credentials'});
/// ```
class AppLogger {
  /// The name/tag for this logger instance.
  final String name;

  /// Optional custom log output handler (for testing or custom log services).
  final void Function(LogEntry entry)? onLog;

  /// Creates an [AppLogger] with the given name.
  AppLogger(this.name, {this.onLog});

  /// Logs a debug message.
  /// Only logged in development mode or when verbose logging is enabled.
  void debug(String message, [Map<String, dynamic>? data]) {
    if (!Environment.isDebugMode && !Environment.verboseLogging) return;
    _log(LogLevel.debug, message, data);
  }

  /// Logs an info message.
  void info(String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.info, message, data);
  }

  /// Logs a warning message.
  void warning(String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.warning, message, data);
  }

  /// Logs an error message.
  void error(String message, [Map<String, dynamic>? data, Object? exception]) {
    _log(LogLevel.error, message, data, exception);
  }

  /// Internal logging method.
  void _log(
    LogLevel level,
    String message,
    Map<String, dynamic>? data, [
    Object? exception,
  ]) {
    final entry = LogEntry(
      level: level,
      name: name,
      message: message,
      data: data != null ? LogRedactor.redact(data) : null,
      exception: exception,
      timestamp: DateTime.now(),
    );

    if (onLog != null) {
      onLog!(entry);
    } else {
      _defaultLogHandler(entry);
    }
  }

  /// Default log handler using Flutter's debugPrint.
  void _defaultLogHandler(LogEntry entry) {
    if (kReleaseMode && entry.level == LogLevel.debug) {
      // Skip debug logs in release mode
      return;
    }

    final output = StringBuffer();
    output.write('[${entry.timestamp.toIso8601String()}]');
    output.write(' [${entry.level.name.toUpperCase()}]');
    output.write(' [$name]');
    output.write(' ${entry.message}');

    if (entry.data != null && entry.data!.isNotEmpty) {
      output.write(' | ${_formatData(entry.data!)}');
    }

    if (entry.exception != null) {
      output.write(' | Exception: ${entry.exception}');
    }

    // Use debugPrint for better output handling in Flutter
    debugPrint(output.toString());
  }

  /// Formats data map as a loggable string.
  String _formatData(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join(', ');
  }
}

/// A log entry with structured data.
class LogEntry {
  final LogLevel level;
  final String name;
  final String message;
  final Map<String, dynamic>? data;
  final Object? exception;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.name,
    required this.message,
    this.data,
    this.exception,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'LogEntry{level: $level, name: $name, message: $message, data: $data, timestamp: $timestamp}';
  }
}

/// Utility class for redacting sensitive data from log messages.
///
/// Automatically detects and redacts:
/// - Tokens (access, refresh, session, auth, bearer)
/// - API keys and secrets
/// - Passwords and credentials
/// - Email addresses (partial redaction)
/// - Phone numbers
/// - Credit card numbers
///
/// ## Usage:
/// ```dart
/// final redacted = LogRedactor.redact({
///   'accessToken': 'secret_token_123',
///   'userId': 'user_456',
/// });
/// // Result: {'accessToken': '[REDACTED]', 'userId': 'user_456'}
/// ```
class LogRedactor {
  /// Keys that should always be redacted (case-insensitive).
  static const Set<String> _sensitiveKeys = {
    'token',
    'access_token',
    'accessToken',
    'refresh_token',
    'refreshToken',
    'session_token',
    'sessionToken',
    'auth_token',
    'authToken',
    'bearer',
    'authorization',
    'api_key',
    'apiKey',
    'api_secret',
    'apiSecret',
    'secret',
    'password',
    'passwd',
    'pwd',
    'credential',
    'credentials',
    'private_key',
    'privateKey',
    'encryption_key',
    'encryptionKey',
    'client_secret',
    'clientSecret',
    'ssn',
    'credit_card',
    'creditCard',
    'cvv',
    'pin',
  };

  /// Patterns for partial redaction in values.
  static final List<_RedactionPattern> _valuePatterns = [
    // Email addresses - show first 2 chars and domain
    _RedactionPattern(
      RegExp(r'^([a-zA-Z0-9._%+-]{2})[a-zA-Z0-9._%+-]*(@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})$'),
      (match) => '${match.group(1)}***${match.group(2)}',
    ),
    // Phone numbers - show last 4 digits
    _RedactionPattern(
      RegExp(r'^(\+?[\d\s\-\(\)]{6,})(\d{4})$'),
      (match) => '***-***-${match.group(2)}',
    ),
    // Credit card numbers - show last 4 digits
    _RedactionPattern(
      RegExp(r'^\d{12,16}$'),
      (match) => '****-****-****-${match.group(0)!.substring(match.group(0)!.length - 4)}',
    ),
    // Bearer tokens in values
    _RedactionPattern(
      RegExp(r'^Bearer\s+.+$', caseSensitive: false),
      (match) => 'Bearer [REDACTED]',
    ),
    // Long alphanumeric strings that look like tokens (32+ chars)
    _RedactionPattern(
      RegExp(r'^[a-zA-Z0-9_\-]{32,}$'),
      (match) => '[REDACTED_TOKEN]',
    ),
  ];

  /// The redacted placeholder text.
  static const String redactedPlaceholder = '[REDACTED]';

  /// Redacts sensitive data from a map.
  ///
  /// Returns a new map with sensitive values replaced with [redactedPlaceholder].
  static Map<String, dynamic> redact(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (_isSensitiveKey(key)) {
        return MapEntry(key, redactedPlaceholder);
      }

      if (value is String) {
        return MapEntry(key, _redactValue(value));
      }

      if (value is Map<String, dynamic>) {
        return MapEntry(key, redact(value));
      }

      if (value is List) {
        return MapEntry(key, _redactList(value));
      }

      return MapEntry(key, value);
    });
  }

  /// Checks if a key is sensitive (case-insensitive).
  static bool _isSensitiveKey(String key) {
    final lowerKey = key.toLowerCase();
    return _sensitiveKeys.any((sensitive) => 
      lowerKey.contains(sensitive.toLowerCase()));
  }

  /// Redacts a single string value if it matches sensitive patterns.
  static String _redactValue(String value) {
    for (final pattern in _valuePatterns) {
      final match = pattern.regex.firstMatch(value);
      if (match != null) {
        return pattern.replacer(match);
      }
    }
    return value;
  }

  /// Redacts a list, handling nested structures.
  static List<dynamic> _redactList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        return _redactValue(item);
      }
      if (item is Map<String, dynamic>) {
        return redact(item);
      }
      if (item is List) {
        return _redactList(item);
      }
      return item;
    }).toList();
  }

  /// Redacts a single string for logging.
  static String redactString(String input) {
    return _redactValue(input);
  }

  /// Adds a custom sensitive key to the redaction list.
  /// Note: This is a runtime addition and won't persist across app restarts.
  static void addSensitiveKey(String key) {
    _sensitiveKeys.add(key.toLowerCase());
  }

  /// Prevent instantiation.
  LogRedactor._();
}

/// Internal class for pattern-based redaction.
class _RedactionPattern {
  final RegExp regex;
  final String Function(Match match) replacer;

  const _RedactionPattern(this.regex, this.replacer);
}

/// Global logger instances for common modules.
class Loggers {
  /// Logger for authentication operations.
  static final auth = AppLogger('Auth');

  /// Logger for sync operations.
  static final sync = AppLogger('Sync');

  /// Logger for API operations.
  static final api = AppLogger('API');

  /// Logger for storage operations.
  static final storage = AppLogger('Storage');

  /// Logger for navigation.
  static final navigation = AppLogger('Navigation');

  /// Logger for analytics.
  static final analytics = AppLogger('Analytics');

  /// Prevent instantiation.
  Loggers._();
}
