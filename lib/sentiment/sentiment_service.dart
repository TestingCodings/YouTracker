import 'sentiment_config.dart';
import 'sentiment_result.dart';

/// Abstract interface for sentiment analysis services.
///
/// Implementations should provide sentiment analysis capabilities
/// for text content, supporting batch processing and configurable options.
abstract class SentimentService {
  /// Configuration for this service.
  SentimentConfig get config;

  /// Whether this service is available/ready.
  bool get isAvailable;

  /// Provider name for this service.
  String get providerName;

  /// Analyzes a single text and returns sentiment result.
  Future<SentimentResult> analyze(String text);

  /// Analyzes multiple texts in batch for efficiency.
  Future<List<SentimentResult>> analyzeBatch(List<String> texts);

  /// Initializes the service (load models, establish connections, etc).
  Future<void> initialize();

  /// Disposes resources used by the service.
  Future<void> dispose();
}

/// Factory for creating sentiment service instances.
class SentimentServiceFactory {
  static SentimentService? _instance;

  /// Gets or creates a sentiment service based on configuration.
  static SentimentService createService(SentimentConfig config) {
    // Import implementations here to avoid circular dependencies
    return _createServiceImpl(config);
  }

  /// Gets the current service instance (for singleton pattern).
  static SentimentService? get instance => _instance;

  /// Sets the current service instance.
  static set instance(SentimentService? service) {
    _instance = service;
  }

  static SentimentService _createServiceImpl(SentimentConfig config) {
    // Lazy imports are done in the main files
    throw UnimplementedError(
      'Use OnDeviceSentimentService or CloudSentimentService directly',
    );
  }
}
