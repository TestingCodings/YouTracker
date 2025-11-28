import 'sentiment_result.dart';

/// Configuration for sentiment analysis.
class SentimentConfig {
  /// The provider to use for sentiment analysis.
  final SentimentProvider provider;

  /// Whether sentiment analysis is enabled.
  final bool enabled;

  /// Threshold for toxicity detection (0.0-1.0).
  final double toxicityThreshold;

  /// Whether to anonymize text before sending to cloud provider.
  final bool anonymizeForCloud;

  /// Maximum batch size for analysis requests.
  final int batchSize;

  /// Rate limit (requests per minute) for cloud provider.
  final int rateLimitPerMinute;

  /// Cloud endpoint URL (for cloud provider).
  final String? cloudEndpoint;

  /// Cloud API key (for cloud provider).
  final String? cloudApiKey;

  /// Path to on-device model (for on-device provider).
  final String? onDeviceModelPath;

  const SentimentConfig({
    this.provider = SentimentProvider.off,
    this.enabled = false,
    this.toxicityThreshold = 0.7,
    this.anonymizeForCloud = true,
    this.batchSize = 10,
    this.rateLimitPerMinute = 60,
    this.cloudEndpoint,
    this.cloudApiKey,
    this.onDeviceModelPath,
  });

  /// Default configuration (off).
  factory SentimentConfig.defaults() {
    return const SentimentConfig();
  }

  /// Creates a configuration from JSON.
  factory SentimentConfig.fromJson(Map<String, dynamic> json) {
    return SentimentConfig(
      provider: SentimentProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => SentimentProvider.off,
      ),
      enabled: json['enabled'] as bool? ?? false,
      toxicityThreshold: (json['toxicityThreshold'] as num?)?.toDouble() ?? 0.7,
      anonymizeForCloud: json['anonymizeForCloud'] as bool? ?? true,
      batchSize: json['batchSize'] as int? ?? 10,
      rateLimitPerMinute: json['rateLimitPerMinute'] as int? ?? 60,
      cloudEndpoint: json['cloudEndpoint'] as String?,
      cloudApiKey: json['cloudApiKey'] as String?,
      onDeviceModelPath: json['onDeviceModelPath'] as String?,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'enabled': enabled,
      'toxicityThreshold': toxicityThreshold,
      'anonymizeForCloud': anonymizeForCloud,
      'batchSize': batchSize,
      'rateLimitPerMinute': rateLimitPerMinute,
      'cloudEndpoint': cloudEndpoint,
      'cloudApiKey': cloudApiKey,
      'onDeviceModelPath': onDeviceModelPath,
    };
  }

  /// Creates a copy with updated fields.
  SentimentConfig copyWith({
    SentimentProvider? provider,
    bool? enabled,
    double? toxicityThreshold,
    bool? anonymizeForCloud,
    int? batchSize,
    int? rateLimitPerMinute,
    String? cloudEndpoint,
    String? cloudApiKey,
    String? onDeviceModelPath,
  }) {
    return SentimentConfig(
      provider: provider ?? this.provider,
      enabled: enabled ?? this.enabled,
      toxicityThreshold: toxicityThreshold ?? this.toxicityThreshold,
      anonymizeForCloud: anonymizeForCloud ?? this.anonymizeForCloud,
      batchSize: batchSize ?? this.batchSize,
      rateLimitPerMinute: rateLimitPerMinute ?? this.rateLimitPerMinute,
      cloudEndpoint: cloudEndpoint ?? this.cloudEndpoint,
      cloudApiKey: cloudApiKey ?? this.cloudApiKey,
      onDeviceModelPath: onDeviceModelPath ?? this.onDeviceModelPath,
    );
  }

  @override
  String toString() {
    return 'SentimentConfig(provider: $provider, enabled: $enabled)';
  }
}

/// Sentiment analysis provider types.
enum SentimentProvider {
  /// Sentiment analysis is disabled.
  off,

  /// Use on-device lightweight model for analysis.
  onDevice,

  /// Use cloud API for analysis.
  cloud;

  /// Get display name for the provider.
  String get displayName {
    switch (this) {
      case SentimentProvider.off:
        return 'Off';
      case SentimentProvider.onDevice:
        return 'On-Device';
      case SentimentProvider.cloud:
        return 'Cloud';
    }
  }

  /// Get description for the provider.
  String get description {
    switch (this) {
      case SentimentProvider.off:
        return 'Sentiment analysis is disabled';
      case SentimentProvider.onDevice:
        return 'Fast, private, works offline';
      case SentimentProvider.cloud:
        return 'More accurate, requires internet';
    }
  }
}
