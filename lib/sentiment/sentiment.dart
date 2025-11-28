/// Sentiment analysis module for YouTracker.
///
/// This module provides sentiment analysis and toxicity detection
/// for comments, with support for both on-device and cloud-based providers.
library sentiment;

export 'sentiment_config.dart';
export 'sentiment_result.dart';
export 'sentiment_service.dart';
export 'on_device_sentiment_service.dart';
export 'cloud_sentiment_service.dart';
