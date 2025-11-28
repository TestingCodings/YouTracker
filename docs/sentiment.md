# Sentiment Analysis

YouTracker's sentiment analysis feature provides automatic detection of comment sentiment and toxicity, helping you understand audience engagement and identify potentially harmful content.

## Overview

The sentiment analysis module analyzes comments to detect:

- **Sentiment**: Positive, Neutral, Negative
- **Questions**: Comments that ask questions
- **Needs Reply**: Comments that may need a response
- **Toxicity**: Potentially harmful or abusive content

## Features

### Sentiment Badges

Each comment displays a sentiment badge indicating its detected sentiment:

- 🟢 **Positive**: Comments with positive sentiment (praise, appreciation, etc.)
- ⚪ **Neutral**: Comments with neutral sentiment
- 🔴 **Negative**: Comments with negative sentiment (complaints, criticism, etc.)
- 🔵 **Question**: Comments containing questions
- 🟠 **Needs Reply**: Comments that may need a response

### Toxic Content Detection

Comments detected as toxic are visually highlighted with:
- Red border around the comment card
- Warning badge with toxicity score
- Visible in the "Toxic" filter view

### Comment Filters

Filter your comment list by sentiment:
- All comments
- Positive comments only
- Negative comments only  
- Questions only
- Comments needing reply
- Toxic comments only

### Analytics Integration

The analytics dashboard includes:
- Sentiment distribution pie chart
- Toxicity trend over time
- Count of each sentiment category

## Configuration

### Enabling Sentiment Analysis

1. Go to **Settings**
2. Find the **Sentiment Analysis** section
3. Toggle **Enable Analysis** to on

### Provider Selection

Choose between two analysis providers:

#### On-Device (Recommended for Privacy)

- **Pros**: 
  - Fast, works offline
  - Privacy-preserving (no data sent externally)
  - Lower battery usage
- **Cons**: 
  - Lower accuracy than cloud
  - Limited language support

#### Cloud Provider

- **Pros**: 
  - Higher accuracy
  - Better language support
  - More sophisticated toxicity detection
- **Cons**: 
  - Requires internet connection
  - Data sent to external service
  - May incur API costs

### Privacy Options

When using the cloud provider:
- **Anonymize Text**: Removes emails, URLs, phone numbers, and @mentions before sending to cloud API
- Configure in `SentimentConfig.anonymizeForCloud`

## Technical Details

### SentimentResult

Each analyzed comment receives a `SentimentResult` containing:

```dart
class SentimentResult {
  final double sentimentScore;    // -1.0 to 1.0
  final SentimentLabel sentimentLabel;
  final double toxicScore;        // 0.0 to 1.0
  final bool isToxic;
  final bool needsReply;
  final String provider;
  final double confidence;
}
```

### Sentiment Labels

```dart
enum SentimentLabel {
  positive,   // Score > 0.3
  neutral,    // Score between -0.3 and 0.3
  negative,   // Score < -0.3
  question,   // Contains question indicators
  needsReply, // Needs response
}
```

### Configuration Options

```dart
class SentimentConfig {
  final SentimentProvider provider;
  final bool enabled;
  final double toxicityThreshold;  // Default: 0.7
  final bool anonymizeForCloud;    // Default: true
  final int batchSize;             // Default: 10
  final int rateLimitPerMinute;    // Default: 60
  final String? cloudEndpoint;
  final String? cloudApiKey;
}
```

## Mobile Optimization

The on-device provider is optimized for mobile:

- **Lightweight**: Uses heuristic-based analysis with small memory footprint
- **Fast**: No network latency
- **Battery Efficient**: No background network calls
- **Privacy First**: All analysis happens on device

For production mobile apps, the on-device service can be extended to use:
- TensorFlow Lite (Android/iOS)
- Core ML (iOS)
- TensorFlow.js (Web)

## API Reference

### OnDeviceSentimentService

```dart
final service = OnDeviceSentimentService();
await service.initialize();

final result = await service.analyze("This is a great video!");
// result.sentimentLabel == SentimentLabel.positive
// result.sentimentScore ≈ 0.8
```

### CloudSentimentService

```dart
final service = CloudSentimentService(
  config: SentimentConfig(
    cloudEndpoint: 'https://api.example.com/sentiment',
    cloudApiKey: 'your-api-key',
    anonymizeForCloud: true,
  ),
);
await service.initialize();

final results = await service.analyzeBatch([
  "Great content!",
  "This is terrible",
  "How do I subscribe?",
]);
```

### Batch Processing

For efficiency, analyze multiple comments at once:

```dart
final texts = comments.map((c) => c.text).toList();
final results = await service.analyzeBatch(texts);
```

## Troubleshooting

### Analysis Not Running

1. Check that sentiment analysis is enabled in Settings
2. Verify the selected provider is available
3. For cloud provider, ensure API key is configured

### Inaccurate Results

- On-device analysis uses heuristics and may be less accurate
- Consider switching to cloud provider for better accuracy
- Report persistent issues to help improve the algorithm

### High Battery Usage

- Switch to on-device provider
- Reduce analysis frequency
- Disable analysis when not needed

## Future Enhancements

Planned improvements:
- Multi-language support
- Custom sentiment training
- Real-time analysis streaming
- Sentiment trends notifications
- Export sentiment reports
