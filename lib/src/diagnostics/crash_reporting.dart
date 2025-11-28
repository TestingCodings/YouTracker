import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/environment.dart';
import '../logging/app_logger.dart';

/// Abstract interface for crash reporting services.
///
/// Implement this interface to integrate with your crash reporting service
/// (e.g., Firebase Crashlytics, Sentry, Bugsnag).
abstract class CrashReporter {
  /// Initializes the crash reporter.
  Future<void> initialize();

  /// Records a non-fatal error.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal,
  });

  /// Records a custom message/event.
  Future<void> log(String message);

  /// Sets a custom key-value pair for context.
  Future<void> setCustomKey(String key, dynamic value);

  /// Sets the user identifier.
  Future<void> setUserId(String? userId);

  /// Enables or disables crash collection.
  Future<void> setCrashCollectionEnabled(bool enabled);
}

/// A stub implementation of [CrashReporter] for development and testing.
///
/// In production, replace this with your actual crash reporting service
/// (e.g., FirebaseCrashlytics, Sentry).
class StubCrashReporter implements CrashReporter {
  final AppLogger _logger = AppLogger('CrashReporter');
  bool _enabled = true;

  @override
  Future<void> initialize() async {
    _logger.info('CrashReporter initialized (stub implementation)');
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (!_enabled) return;

    _logger.error(
      'Error recorded: ${reason ?? exception.toString()}',
      {
        'fatal': fatal,
        'exception': exception.runtimeType.toString(),
      },
      exception,
    );

    if (kDebugMode) {
      debugPrint('CRASH REPORT: ${reason ?? exception}');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }

  @override
  Future<void> log(String message) async {
    if (!_enabled) return;
    _logger.debug('Crash reporter log: $message');
  }

  @override
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_enabled) return;
    _logger.debug('Set custom key: $key = $value');
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!_enabled) return;
    _logger.debug('Set user ID: ${userId ?? 'null'}');
  }

  @override
  Future<void> setCrashCollectionEnabled(bool enabled) async {
    _enabled = enabled;
    _logger.info('Crash collection ${enabled ? 'enabled' : 'disabled'}');
  }
}

/// Crash reporting service that respects environment settings.
///
/// Features:
/// - Disabled in development mode by default
/// - Enabled in production and staging
/// - User opt-out support
/// - Automatic error recording via zone handling
///
/// ## Setup:
/// ```dart
/// // In main.dart
/// await CrashReportingService.instance.initialize();
///
/// runZonedGuarded(
///   () => runApp(MyApp()),
///   CrashReportingService.instance.recordZoneError,
/// );
///
/// FlutterError.onError = CrashReportingService.instance.recordFlutterError;
/// ```
class CrashReportingService {
  static CrashReportingService? _instance;
  static CrashReportingService get instance {
    _instance ??= CrashReportingService._();
    return _instance!;
  }

  CrashReportingService._();

  /// Factory constructor for testing with custom reporter.
  factory CrashReportingService.withReporter(CrashReporter reporter) {
    final service = CrashReportingService._();
    service._reporter = reporter;
    return service;
  }

  CrashReporter? _reporter;
  bool _isInitialized = false;

  /// Whether crash reporting is initialized.
  bool get isInitialized => _isInitialized;

  /// The underlying crash reporter implementation.
  CrashReporter get reporter {
    _reporter ??= StubCrashReporter();
    return _reporter!;
  }

  /// Sets a custom crash reporter implementation.
  set reporter(CrashReporter value) {
    _reporter = value;
  }

  /// Initializes crash reporting based on environment.
  ///
  /// [enableInDebug] - Force enable in debug mode (default: false)
  Future<void> initialize({bool enableInDebug = false}) async {
    if (_isInitialized) return;

    await reporter.initialize();

    // Configure based on environment
    if (Environment.isDevelopment && !enableInDebug) {
      await reporter.setCrashCollectionEnabled(false);
    } else {
      await reporter.setCrashCollectionEnabled(
        Environment.crashReportingEnabled,
      );
    }

    _isInitialized = true;
  }

  /// Records a non-fatal error.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    await reporter.recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Handler for runZonedGuarded errors.
  void recordZoneError(Object error, StackTrace stackTrace) {
    reporter.recordError(error, stackTrace, fatal: true);
  }

  /// Handler for FlutterError.onError.
  void recordFlutterError(FlutterErrorDetails details) {
    reporter.recordError(
      details.exception,
      details.stack,
      reason: details.summary.toString(),
      fatal: details.silent ? false : true,
    );
  }

  /// Records a custom log message.
  Future<void> log(String message) async {
    await reporter.log(message);
  }

  /// Sets user identifier for crash reports.
  Future<void> setUserId(String? userId) async {
    await reporter.setUserId(userId);
  }

  /// Sets a custom key for additional context.
  Future<void> setCustomKey(String key, dynamic value) async {
    await reporter.setCustomKey(key, value);
  }

  /// Enables or disables crash collection.
  Future<void> setCrashCollectionEnabled(bool enabled) async {
    await reporter.setCrashCollectionEnabled(enabled);
  }
}

/// Example integration with Firebase Crashlytics.
///
/// To use Firebase Crashlytics, create an implementation like this:
///
/// ```dart
/// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
///
/// class FirebaseCrashReporter implements CrashReporter {
///   @override
///   Future<void> initialize() async {
///     // Firebase initialization is typically done in main.dart
///   }
///
///   @override
///   Future<void> recordError(
///     dynamic exception,
///     StackTrace? stackTrace, {
///     String? reason,
///     bool fatal = false,
///   }) async {
///     await FirebaseCrashlytics.instance.recordError(
///       exception,
///       stackTrace,
///       reason: reason,
///       fatal: fatal,
///     );
///   }
///
///   @override
///   Future<void> log(String message) async {
///     await FirebaseCrashlytics.instance.log(message);
///   }
///
///   @override
///   Future<void> setCustomKey(String key, dynamic value) async {
///     await FirebaseCrashlytics.instance.setCustomKey(key, value);
///   }
///
///   @override
///   Future<void> setUserId(String? userId) async {
///     await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
///   }
///
///   @override
///   Future<void> setCrashCollectionEnabled(bool enabled) async {
///     await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
///   }
/// }
/// ```
///
/// Then in main.dart:
/// ```dart
/// CrashReportingService.instance.reporter = FirebaseCrashReporter();
/// await CrashReportingService.instance.initialize();
/// ```
class _CrashlyticsExample {
  _CrashlyticsExample._();
}
