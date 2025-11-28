import 'package:flutter_test/flutter_test.dart';

import 'package:you_tracker/src/config/environment.dart';

void main() {
  group('Environment', () {
    setUp(() {
      // Reset environment before each test
      Environment.reset();
    });

    tearDown(() {
      Environment.reset();
    });

    test('should have default development environment', () {
      expect(Environment.type, EnvironmentType.development);
      expect(Environment.isInitialized, false);
    });

    test('should initialize with development type', () async {
      await Environment.initialize(EnvironmentType.development);

      expect(Environment.type, EnvironmentType.development);
      expect(Environment.isInitialized, true);
      expect(Environment.isDevelopment, true);
      expect(Environment.isStaging, false);
      expect(Environment.isProduction, false);
    });

    test('should initialize with staging type', () async {
      await Environment.initialize(EnvironmentType.staging);

      expect(Environment.type, EnvironmentType.staging);
      expect(Environment.isDevelopment, false);
      expect(Environment.isStaging, true);
      expect(Environment.isProduction, false);
    });

    test('should initialize with production type', () async {
      await Environment.initialize(
        EnvironmentType.production,
        config: {'API_BASE_URL': 'https://api.example.com'},
      );

      expect(Environment.type, EnvironmentType.production);
      expect(Environment.isDevelopment, false);
      expect(Environment.isStaging, false);
      expect(Environment.isProduction, true);
    });

    test('should throw in production if required variables missing', () async {
      expect(
        () async => await Environment.initialize(EnvironmentType.production),
        throwsA(isA<EnvironmentException>()),
      );
    });

    test('should not throw in production if required variables present', () async {
      await Environment.initialize(
        EnvironmentType.production,
        config: {'API_BASE_URL': 'https://api.example.com'},
      );

      expect(Environment.apiBaseUrl, 'https://api.example.com');
    });

    test('should use default API URL for development', () async {
      await Environment.initialize(EnvironmentType.development);

      expect(Environment.apiBaseUrl, 'http://localhost:8080');
    });

    test('should use default API URL for staging', () async {
      await Environment.initialize(EnvironmentType.staging);

      expect(Environment.apiBaseUrl, 'https://staging-api.youtracker.example.com');
    });

    test('should use config API URL when provided', () async {
      await Environment.initialize(
        EnvironmentType.development,
        config: {'API_BASE_URL': 'http://custom-api.local'},
      );

      expect(Environment.apiBaseUrl, 'http://custom-api.local');
    });

    test('debug mode should be true in development', () async {
      await Environment.initialize(EnvironmentType.development);

      expect(Environment.isDebugMode, true);
    });

    test('debug mode should be false in production by default', () async {
      await Environment.initialize(
        EnvironmentType.production,
        config: {'API_BASE_URL': 'https://api.example.com'},
      );

      expect(Environment.isDebugMode, false);
    });

    test('debug mode can be enabled in production via config', () async {
      await Environment.initialize(
        EnvironmentType.production,
        config: {
          'API_BASE_URL': 'https://api.example.com',
          'DEBUG_MODE': 'true',
        },
      );

      expect(Environment.isDebugMode, true);
    });

    test('crash reporting should be disabled in development', () async {
      await Environment.initialize(EnvironmentType.development);

      expect(Environment.crashReportingEnabled, false);
    });

    test('crash reporting should be enabled in production by default', () async {
      await Environment.initialize(
        EnvironmentType.production,
        config: {'API_BASE_URL': 'https://api.example.com'},
      );

      expect(Environment.crashReportingEnabled, true);
    });

    test('analytics should be disabled in development', () async {
      await Environment.initialize(EnvironmentType.development);

      expect(Environment.analyticsEnabled, false);
    });

    test('analytics should be enabled in production by default', () async {
      await Environment.initialize(
        EnvironmentType.production,
        config: {'API_BASE_URL': 'https://api.example.com'},
      );

      expect(Environment.analyticsEnabled, true);
    });

    test('should parse boolean config values correctly', () async {
      await Environment.initialize(
        EnvironmentType.development,
        config: {
          'DEBUG_MODE': 'true',
          'CRASH_REPORTING_ENABLED': 'false',
          'ANALYTICS_ENABLED': '1',
          'VERBOSE_LOGGING': 'yes',
        },
      );

      // These use the boolean parsing logic
      expect(Environment.verboseLogging, true);
    });

    test('should parse integer config values correctly', () async {
      await Environment.initialize(
        EnvironmentType.development,
        config: {
          'REQUEST_TIMEOUT_SECONDS': '60',
          'MAX_RETRY_ATTEMPTS': '5',
          'SYNC_INTERVAL_MINUTES': '30',
        },
      );

      expect(Environment.requestTimeoutSeconds, 60);
      expect(Environment.maxRetryAttempts, 5);
      expect(Environment.syncIntervalMinutes, 30);
    });

    test('should use defaults for invalid integer values', () async {
      await Environment.initialize(
        EnvironmentType.development,
        config: {
          'REQUEST_TIMEOUT_SECONDS': 'invalid',
          'MAX_RETRY_ATTEMPTS': 'abc',
        },
      );

      expect(Environment.requestTimeoutSeconds, 30); // default
      expect(Environment.maxRetryAttempts, 3); // default
    });

    test('certificate pinning should be disabled in development', () async {
      await Environment.initialize(EnvironmentType.development);

      expect(Environment.certificatePinningEnabled, false);
    });

    test('certificate pinning should be enabled in production by default', () async {
      await Environment.initialize(
        EnvironmentType.production,
        config: {'API_BASE_URL': 'https://api.example.com'},
      );

      expect(Environment.certificatePinningEnabled, true);
    });

    test('should get YouTube API base URL', () async {
      await Environment.initialize(EnvironmentType.development);

      expect(
        Environment.youtubeApiBaseUrl,
        'https://www.googleapis.com/youtube/v3',
      );
    });

    test('should get raw config value', () async {
      await Environment.initialize(
        EnvironmentType.development,
        config: {'CUSTOM_KEY': 'custom_value'},
      );

      expect(Environment.getValue('CUSTOM_KEY'), 'custom_value');
      expect(Environment.getValue('NON_EXISTENT'), isNull);
    });
  });

  group('Environment.initializeFromString', () {
    tearDown(() {
      Environment.reset();
    });

    test('should parse "development" correctly', () async {
      await Environment.initializeFromString('development');
      expect(Environment.type, EnvironmentType.development);
    });

    test('should parse "dev" correctly', () async {
      await Environment.initializeFromString('dev');
      expect(Environment.type, EnvironmentType.development);
    });

    test('should parse "staging" correctly', () async {
      await Environment.initializeFromString('staging');
      expect(Environment.type, EnvironmentType.staging);
    });

    test('should parse "stage" correctly', () async {
      await Environment.initializeFromString('stage');
      expect(Environment.type, EnvironmentType.staging);
    });

    test('should parse "production" correctly', () async {
      await Environment.initializeFromString(
        'production',
        config: {'API_BASE_URL': 'https://api.example.com'},
      );
      expect(Environment.type, EnvironmentType.production);
    });

    test('should parse "prod" correctly', () async {
      await Environment.initializeFromString(
        'prod',
        config: {'API_BASE_URL': 'https://api.example.com'},
      );
      expect(Environment.type, EnvironmentType.production);
    });

    test('should default to development for unknown values', () async {
      await Environment.initializeFromString('unknown');
      expect(Environment.type, EnvironmentType.development);
    });

    test('should default to development for null', () async {
      await Environment.initializeFromString(null);
      expect(Environment.type, EnvironmentType.development);
    });

    test('should be case-insensitive', () async {
      await Environment.initializeFromString('PRODUCTION', 
        config: {'API_BASE_URL': 'https://api.example.com'});
      expect(Environment.type, EnvironmentType.production);
    });
  });

  group('EnvironmentException', () {
    test('should have correct message', () {
      final exception = EnvironmentException('Test error message');
      expect(exception.message, 'Test error message');
      expect(exception.toString(), 'EnvironmentException: Test error message');
    });
  });

  group('Feature Flags', () {
    tearDown(() {
      Environment.reset();
    });

    test('background sync should be enabled by default', () async {
      await Environment.initialize(EnvironmentType.development);
      expect(Environment.backgroundSyncEnabled, true);
    });

    test('push notifications should be enabled by default', () async {
      await Environment.initialize(EnvironmentType.development);
      expect(Environment.pushNotificationsEnabled, true);
    });

    test('analytics feature should be enabled by default', () async {
      await Environment.initialize(EnvironmentType.development);
      expect(Environment.analyticsFeatureEnabled, true);
    });

    test('feature flags can be disabled via config', () async {
      await Environment.initialize(
        EnvironmentType.development,
        config: {
          'BACKGROUND_SYNC_ENABLED': 'false',
          'PUSH_NOTIFICATIONS_ENABLED': 'false',
          'ANALYTICS_FEATURE_ENABLED': 'false',
        },
      );

      expect(Environment.backgroundSyncEnabled, false);
      expect(Environment.pushNotificationsEnabled, false);
      expect(Environment.analyticsFeatureEnabled, false);
    });
  });
}
