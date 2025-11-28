/// Environment types for the application.
enum EnvironmentType {
  /// Development environment with relaxed security and verbose logging.
  development,

  /// Staging environment for pre-production testing.
  staging,

  /// Production environment with strict security and minimal logging.
  production,
}

/// Environment configuration for the YouTracker app.
///
/// Loads configuration from environment variables or .env files.
/// Supports development, staging, and production environments.
///
/// ## Setup:
///
/// ### Option 1: Using .env files (recommended for development)
/// Create environment-specific .env files:
/// - `.env.development` - Development settings
/// - `.env.staging` - Staging settings
/// - `.env.production` - Production settings
///
/// ### Option 2: Using --dart-define (recommended for CI/CD)
/// ```bash
/// flutter run --dart-define=ENV=production --dart-define=API_BASE_URL=https://api.example.com
/// ```
///
/// ### Option 3: Using build flavors
/// Configure Android build flavors and iOS schemes for different environments.
///
/// ## Usage:
/// ```dart
/// // Initialize early in main()
/// await Environment.initialize(EnvironmentType.production);
///
/// // Access configuration
/// final apiUrl = Environment.apiBaseUrl;
/// final isDebug = Environment.isDebugMode;
/// ```
class Environment {
  static EnvironmentType _type = EnvironmentType.development;
  static bool _isInitialized = false;
  static Map<String, String> _config = {};

  /// Current environment type.
  static EnvironmentType get type => _type;

  /// Whether the environment has been initialized.
  static bool get isInitialized => _isInitialized;

  /// Whether the app is running in development mode.
  static bool get isDevelopment => _type == EnvironmentType.development;

  /// Whether the app is running in staging mode.
  static bool get isStaging => _type == EnvironmentType.staging;

  /// Whether the app is running in production mode.
  static bool get isProduction => _type == EnvironmentType.production;

  /// Whether debug mode is enabled (development or staging with debug flag).
  static bool get isDebugMode {
    if (isDevelopment) return true;
    return _getBoolOrDefault('DEBUG_MODE', false);
  }

  /// Whether crash reporting is enabled.
  static bool get crashReportingEnabled {
    if (isDevelopment) return false; // Disabled in development
    return _getBoolOrDefault('CRASH_REPORTING_ENABLED', true);
  }

  /// Whether analytics is enabled.
  static bool get analyticsEnabled {
    if (isDevelopment) return false; // Disabled in development
    return _getBoolOrDefault('ANALYTICS_ENABLED', true);
  }

  /// Whether verbose logging is enabled.
  static bool get verboseLogging {
    return _getBoolOrDefault('VERBOSE_LOGGING', isDevelopment);
  }

  // =====================================================================
  // API Configuration
  // =====================================================================

  /// Base URL for the backend API.
  static String get apiBaseUrl {
    final url = _config['API_BASE_URL'];
    if (url != null && url.isNotEmpty) return url;

    // Default URLs per environment
    switch (_type) {
      case EnvironmentType.development:
        return 'http://localhost:8080';
      case EnvironmentType.staging:
        return 'https://staging-api.youtracker.example.com';
      case EnvironmentType.production:
        _throwIfMissing('API_BASE_URL');
        return '';
    }
  }

  /// YouTube Data API base URL.
  static String get youtubeApiBaseUrl {
    return _config['YOUTUBE_API_BASE_URL'] ??
        'https://www.googleapis.com/youtube/v3';
  }

  /// Request timeout in seconds.
  static int get requestTimeoutSeconds {
    return _getIntOrDefault('REQUEST_TIMEOUT_SECONDS', 30);
  }

  /// Maximum retry attempts for API calls.
  static int get maxRetryAttempts {
    return _getIntOrDefault('MAX_RETRY_ATTEMPTS', 3);
  }

  // =====================================================================
  // Sync Configuration
  // =====================================================================

  /// Sync interval in minutes.
  static int get syncIntervalMinutes {
    return _getIntOrDefault('SYNC_INTERVAL_MINUTES', 15);
  }

  /// Maximum concurrent sync operations.
  static int get maxConcurrentSync {
    return _getIntOrDefault('MAX_CONCURRENT_SYNC', 3);
  }

  // =====================================================================
  // Security Configuration
  // =====================================================================

  /// Whether to enable certificate pinning.
  static bool get certificatePinningEnabled {
    return _getBoolOrDefault('CERTIFICATE_PINNING_ENABLED', isProduction);
  }

  /// Session timeout in minutes.
  static int get sessionTimeoutMinutes {
    return _getIntOrDefault('SESSION_TIMEOUT_MINUTES', 60);
  }

  // =====================================================================
  // Feature Flags
  // =====================================================================

  /// Whether background sync is enabled.
  static bool get backgroundSyncEnabled {
    return _getBoolOrDefault('BACKGROUND_SYNC_ENABLED', true);
  }

  /// Whether push notifications are enabled.
  static bool get pushNotificationsEnabled {
    return _getBoolOrDefault('PUSH_NOTIFICATIONS_ENABLED', true);
  }

  /// Whether analytics dashboard is enabled.
  static bool get analyticsFeatureEnabled {
    return _getBoolOrDefault('ANALYTICS_FEATURE_ENABLED', true);
  }

  // =====================================================================
  // Initialization
  // =====================================================================

  /// Initializes the environment with the specified type.
  ///
  /// [type] - The environment type
  /// [config] - Optional configuration map (for testing or custom config)
  ///
  /// If [config] is not provided, configuration is loaded from:
  /// 1. Compile-time --dart-define values
  /// 2. Platform environment variables
  ///
  /// Throws [EnvironmentException] in production if required variables are missing.
  static Future<void> initialize(
    EnvironmentType type, {
    Map<String, String>? config,
  }) async {
    _type = type;
    _config = config ?? _loadFromCompileTimeDefines();
    _isInitialized = true;

    // Validate required production variables
    if (type == EnvironmentType.production) {
      _validateProductionConfig();
    }
  }

  /// Initializes from a string environment name.
  ///
  /// [envName] - Environment name ('development', 'staging', 'production')
  /// [config] - Optional configuration map
  static Future<void> initializeFromString(
    String? envName, {
    Map<String, String>? config,
  }) async {
    final type = _parseEnvironmentType(envName);
    await initialize(type, config: config);
  }

  /// Parses environment type from string.
  static EnvironmentType _parseEnvironmentType(String? value) {
    switch (value?.toLowerCase()) {
      case 'prod':
      case 'production':
        return EnvironmentType.production;
      case 'staging':
      case 'stage':
        return EnvironmentType.staging;
      case 'dev':
      case 'development':
      default:
        return EnvironmentType.development;
    }
  }

  /// Loads configuration from compile-time defines.
  static Map<String, String> _loadFromCompileTimeDefines() {
    // These are populated via --dart-define flags
    // In a real app, you'd use String.fromEnvironment for each key
    return {
      'ENV': const String.fromEnvironment('ENV', defaultValue: 'development'),
      'API_BASE_URL': const String.fromEnvironment('API_BASE_URL'),
      'DEBUG_MODE': const String.fromEnvironment('DEBUG_MODE'),
      'CRASH_REPORTING_ENABLED':
          const String.fromEnvironment('CRASH_REPORTING_ENABLED'),
      'ANALYTICS_ENABLED': const String.fromEnvironment('ANALYTICS_ENABLED'),
      'VERBOSE_LOGGING': const String.fromEnvironment('VERBOSE_LOGGING'),
      'REQUEST_TIMEOUT_SECONDS':
          const String.fromEnvironment('REQUEST_TIMEOUT_SECONDS'),
      'MAX_RETRY_ATTEMPTS': const String.fromEnvironment('MAX_RETRY_ATTEMPTS'),
      'SYNC_INTERVAL_MINUTES':
          const String.fromEnvironment('SYNC_INTERVAL_MINUTES'),
      'CERTIFICATE_PINNING_ENABLED':
          const String.fromEnvironment('CERTIFICATE_PINNING_ENABLED'),
      'SESSION_TIMEOUT_MINUTES':
          const String.fromEnvironment('SESSION_TIMEOUT_MINUTES'),
      'BACKGROUND_SYNC_ENABLED':
          const String.fromEnvironment('BACKGROUND_SYNC_ENABLED'),
      'PUSH_NOTIFICATIONS_ENABLED':
          const String.fromEnvironment('PUSH_NOTIFICATIONS_ENABLED'),
    };
  }

  /// Validates required production configuration.
  static void _validateProductionConfig() {
    final requiredKeys = ['API_BASE_URL'];

    for (final key in requiredKeys) {
      final value = _config[key];
      if (value == null || value.isEmpty) {
        throw EnvironmentException(
          'Required environment variable $key is missing in production mode',
        );
      }
    }
  }

  /// Gets a boolean value from config with default.
  static bool _getBoolOrDefault(String key, bool defaultValue) {
    final value = _config[key]?.toLowerCase();
    if (value == null || value.isEmpty) return defaultValue;
    return value == 'true' || value == '1' || value == 'yes';
  }

  /// Gets an integer value from config with default.
  static int _getIntOrDefault(String key, int defaultValue) {
    final value = _config[key];
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  /// Throws an exception if a required value is missing in production.
  static Never _throwIfMissing(String key) {
    throw EnvironmentException(
      'Required environment variable $key is not set',
    );
  }

  /// Gets a raw config value by key.
  static String? getValue(String key) => _config[key];

  /// Resets the environment (primarily for testing).
  static void reset() {
    _isInitialized = false;
    _type = EnvironmentType.development;
    _config = {};
  }
}

/// Exception thrown when environment configuration is invalid.
class EnvironmentException implements Exception {
  final String message;

  EnvironmentException(this.message);

  @override
  String toString() => 'EnvironmentException: $message';
}
