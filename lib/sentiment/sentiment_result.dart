/// Represents the sentiment analysis result for a piece of text.
class SentimentResult {
  /// Sentiment score from -1.0 (most negative) to 1.0 (most positive).
  final double sentimentScore;

  /// Sentiment label categorizing the sentiment.
  final SentimentLabel sentimentLabel;

  /// Toxicity score from 0.0 (not toxic) to 1.0 (most toxic).
  final double toxicScore;

  /// Whether the content is considered toxic (toxicScore > threshold).
  final bool isToxic;

  /// Whether the comment appears to need a reply (contains question, mention, etc).
  final bool needsReply;

  /// Provider that produced this result.
  final String provider;

  /// Confidence score for the analysis (0.0-1.0).
  final double confidence;

  const SentimentResult({
    required this.sentimentScore,
    required this.sentimentLabel,
    required this.toxicScore,
    required this.isToxic,
    required this.needsReply,
    required this.provider,
    this.confidence = 1.0,
  });

  /// Creates an empty/default result when analysis is disabled or fails.
  factory SentimentResult.empty() {
    return const SentimentResult(
      sentimentScore: 0.0,
      sentimentLabel: SentimentLabel.neutral,
      toxicScore: 0.0,
      isToxic: false,
      needsReply: false,
      provider: 'none',
      confidence: 0.0,
    );
  }

  /// Creates a result from JSON.
  factory SentimentResult.fromJson(Map<String, dynamic> json) {
    return SentimentResult(
      sentimentScore: (json['sentimentScore'] as num?)?.toDouble() ?? 0.0,
      sentimentLabel: SentimentLabel.values.firstWhere(
        (e) => e.name == json['sentimentLabel'],
        orElse: () => SentimentLabel.neutral,
      ),
      toxicScore: (json['toxicScore'] as num?)?.toDouble() ?? 0.0,
      isToxic: json['isToxic'] as bool? ?? false,
      needsReply: json['needsReply'] as bool? ?? false,
      provider: json['provider'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      'sentimentScore': sentimentScore,
      'sentimentLabel': sentimentLabel.name,
      'toxicScore': toxicScore,
      'isToxic': isToxic,
      'needsReply': needsReply,
      'provider': provider,
      'confidence': confidence,
    };
  }

  /// Creates a copy with updated fields.
  SentimentResult copyWith({
    double? sentimentScore,
    SentimentLabel? sentimentLabel,
    double? toxicScore,
    bool? isToxic,
    bool? needsReply,
    String? provider,
    double? confidence,
  }) {
    return SentimentResult(
      sentimentScore: sentimentScore ?? this.sentimentScore,
      sentimentLabel: sentimentLabel ?? this.sentimentLabel,
      toxicScore: toxicScore ?? this.toxicScore,
      isToxic: isToxic ?? this.isToxic,
      needsReply: needsReply ?? this.needsReply,
      provider: provider ?? this.provider,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() {
    return 'SentimentResult(label: $sentimentLabel, score: $sentimentScore, toxic: $isToxic)';
  }
}

/// Sentiment label categories.
enum SentimentLabel {
  positive,
  neutral,
  negative,
  question,
  needsReply;

  /// Get display name for the label.
  String get displayName {
    switch (this) {
      case SentimentLabel.positive:
        return 'Positive';
      case SentimentLabel.neutral:
        return 'Neutral';
      case SentimentLabel.negative:
        return 'Negative';
      case SentimentLabel.question:
        return 'Question';
      case SentimentLabel.needsReply:
        return 'Needs Reply';
    }
  }
}
