import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'sentiment_config.dart';
import 'sentiment_result.dart';
import 'sentiment_service.dart';

/// Cloud-based sentiment analysis service.
///
/// This service calls a cloud API (e.g., Google Cloud Natural Language,
/// Perspective API, or a custom endpoint) for sentiment and toxicity analysis.
/// It supports batching, rate limiting, exponential backoff, and optional
/// text anonymization for privacy.
class CloudSentimentService implements SentimentService {
  @override
  final SentimentConfig config;

  final http.Client _httpClient;
  bool _isInitialized = false;
  
  // Rate limiting
  final List<DateTime> _requestTimestamps = [];
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialBackoff = Duration(seconds: 1);

  CloudSentimentService({
    SentimentConfig? config,
    http.Client? httpClient,
  })  : config = config ?? const SentimentConfig(
          provider: SentimentProvider.cloud,
          enabled: true,
        ),
        _httpClient = httpClient ?? http.Client();

  @override
  bool get isAvailable => 
      _isInitialized && 
      config.cloudEndpoint != null && 
      config.cloudApiKey != null;

  @override
  String get providerName => 'cloud';

  @override
  Future<void> initialize() async {
    if (config.cloudEndpoint == null) {
      throw StateError('Cloud endpoint not configured');
    }
    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    _httpClient.close();
    _isInitialized = false;
  }

  @override
  Future<SentimentResult> analyze(String text) async {
    final results = await analyzeBatch([text]);
    return results.first;
  }

  @override
  Future<List<SentimentResult>> analyzeBatch(List<String> texts) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _waitForRateLimit();

    // Process in batches according to config
    final results = <SentimentResult>[];
    for (var i = 0; i < texts.length; i += config.batchSize) {
      final batch = texts.skip(i).take(config.batchSize).toList();
      final batchResults = await _processBatch(batch);
      results.addAll(batchResults);
    }

    return results;
  }

  Future<List<SentimentResult>> _processBatch(List<String> texts) async {
    // Anonymize if configured
    final processedTexts = config.anonymizeForCloud
        ? texts.map(_anonymizeText).toList()
        : texts;

    // Make API call with retry logic
    final response = await _makeRequestWithRetry(processedTexts);

    if (response == null) {
      // Fallback to empty results on failure
      return texts.map((_) => SentimentResult.empty()).toList();
    }

    return _parseResponse(response, texts.length);
  }

  Future<Map<String, dynamic>?> _makeRequestWithRetry(
    List<String> texts,
  ) async {
    int attempt = 0;
    Duration backoff = _initialBackoff;

    while (attempt < _maxRetries) {
      try {
        _recordRequest();
        
        final response = await _httpClient.post(
          Uri.parse(config.cloudEndpoint!),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.cloudApiKey}',
          },
          body: jsonEncode({
            'texts': texts,
            'features': ['sentiment', 'toxicity'],
          }),
        );

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else if (response.statusCode == 429) {
          // Rate limited - wait and retry
          await Future.delayed(backoff);
          backoff *= 2;
          attempt++;
        } else {
          // Other error - don't retry
          return null;
        }
      } catch (e) {
        // Network error - retry with backoff
        await Future.delayed(backoff);
        backoff *= 2;
        attempt++;
      }
    }

    return null;
  }

  List<SentimentResult> _parseResponse(
    Map<String, dynamic> response,
    int expectedCount,
  ) {
    final results = <SentimentResult>[];
    final analysisResults = response['results'] as List<dynamic>? ?? [];

    for (var i = 0; i < expectedCount; i++) {
      if (i < analysisResults.length) {
        final result = analysisResults[i] as Map<String, dynamic>;
        results.add(_parseResultItem(result));
      } else {
        results.add(SentimentResult.empty());
      }
    }

    return results;
  }

  SentimentResult _parseResultItem(Map<String, dynamic> result) {
    final sentimentScore = (result['sentimentScore'] as num?)?.toDouble() ?? 0.0;
    final toxicScore = (result['toxicScore'] as num?)?.toDouble() ?? 0.0;
    
    // Determine label from score
    SentimentLabel label;
    if (result['isQuestion'] == true) {
      label = SentimentLabel.question;
    } else if (result['needsReply'] == true) {
      label = SentimentLabel.needsReply;
    } else if (sentimentScore > 0.3) {
      label = SentimentLabel.positive;
    } else if (sentimentScore < -0.3) {
      label = SentimentLabel.negative;
    } else {
      label = SentimentLabel.neutral;
    }

    return SentimentResult(
      sentimentScore: sentimentScore,
      sentimentLabel: label,
      toxicScore: toxicScore,
      isToxic: toxicScore > config.toxicityThreshold,
      needsReply: result['needsReply'] as bool? ?? false,
      provider: providerName,
      confidence: (result['confidence'] as num?)?.toDouble() ?? 0.9,
    );
  }

  /// Anonymizes text by replacing potential PII.
  String _anonymizeText(String text) {
    var anonymized = text;
    
    // Replace email addresses
    anonymized = anonymized.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      '[EMAIL]',
    );
    
    // Replace URLs
    anonymized = anonymized.replaceAll(
      RegExp(r'https?://[^\s]+'),
      '[URL]',
    );
    
    // Replace phone numbers (basic pattern)
    anonymized = anonymized.replaceAll(
      RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'),
      '[PHONE]',
    );
    
    // Replace @mentions
    anonymized = anonymized.replaceAll(
      RegExp(r'@\w+'),
      '@[USER]',
    );

    return anonymized;
  }

  /// Waits if rate limit would be exceeded.
  Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    // Clean old timestamps
    _requestTimestamps.removeWhere((t) => t.isBefore(oneMinuteAgo));
    
    // Check if we need to wait
    if (_requestTimestamps.length >= config.rateLimitPerMinute) {
      final oldestInWindow = _requestTimestamps.first;
      final waitTime = oldestInWindow.add(const Duration(minutes: 1)).difference(now);
      if (waitTime.isNegative == false) {
        await Future.delayed(waitTime + const Duration(milliseconds: 100));
      }
    }
  }

  /// Records a request timestamp for rate limiting.
  void _recordRequest() {
    _requestTimestamps.add(DateTime.now());
  }
}

/// Mock cloud service for testing purposes.
class MockCloudSentimentService extends CloudSentimentService {
  final Random _random = Random();

  MockCloudSentimentService() : super(
    config: const SentimentConfig(
      provider: SentimentProvider.cloud,
      enabled: true,
      cloudEndpoint: 'https://mock.api/sentiment',
      cloudApiKey: 'mock-key',
    ),
  );

  @override
  Future<void> initialize() async {
    // No-op for mock
  }

  @override
  Future<SentimentResult> analyze(String text) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 50 + _random.nextInt(100)));
    
    // Generate mock result based on text content
    final score = _mockSentimentScore(text);
    final toxicScore = _mockToxicScore(text);
    final isQuestion = text.contains('?');
    
    SentimentLabel label;
    if (isQuestion) {
      label = SentimentLabel.question;
    } else if (score > 0.3) {
      label = SentimentLabel.positive;
    } else if (score < -0.3) {
      label = SentimentLabel.negative;
    } else {
      label = SentimentLabel.neutral;
    }

    return SentimentResult(
      sentimentScore: score,
      sentimentLabel: label,
      toxicScore: toxicScore,
      isToxic: toxicScore > 0.7,
      needsReply: isQuestion || text.toLowerCase().contains('help'),
      provider: 'mock-cloud',
      confidence: 0.85 + _random.nextDouble() * 0.1,
    );
  }

  double _mockSentimentScore(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('great') || lower.contains('awesome') || lower.contains('love')) {
      return 0.5 + _random.nextDouble() * 0.4;
    } else if (lower.contains('bad') || lower.contains('hate') || lower.contains('terrible')) {
      return -0.5 - _random.nextDouble() * 0.4;
    }
    return (_random.nextDouble() - 0.5) * 0.4;
  }

  double _mockToxicScore(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('hate') || lower.contains('stupid') || lower.contains('idiot')) {
      return 0.6 + _random.nextDouble() * 0.3;
    }
    return _random.nextDouble() * 0.3;
  }
}
