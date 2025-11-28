import 'sentiment_config.dart';
import 'sentiment_result.dart';
import 'sentiment_service.dart';

// Static regex patterns for performance optimization
final _whitespacePattern = RegExp(r'\s+');
final _capsPattern = RegExp(r'[A-Z]');
final _excessivePunctuationPattern = RegExp(r'[!?]{3,}');

/// On-device sentiment analysis service using heuristic-based analysis.
///
/// This service provides lightweight, privacy-preserving sentiment analysis
/// that runs entirely on-device without network calls. It uses a weighted
/// wordlist approach with support for negation and context modifiers.
///
/// For production mobile apps, this can be extended to use TensorFlow Lite,
/// Core ML, or other on-device ML frameworks for improved accuracy.
class OnDeviceSentimentService implements SentimentService {
  @override
  final SentimentConfig config;

  bool _isInitialized = false;

  OnDeviceSentimentService({SentimentConfig? config})
      : config = config ?? const SentimentConfig(
          provider: SentimentProvider.onDevice,
          enabled: true,
        );

  @override
  bool get isAvailable => _isInitialized;

  @override
  String get providerName => 'on-device';

  @override
  Future<void> initialize() async {
    // In a production app, this would load the TFLite/CoreML model
    // For now, we use a heuristic-based approach that doesn't require loading
    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }

  @override
  Future<SentimentResult> analyze(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    final sentimentScore = _computeSentimentScore(text);
    final toxicScore = _computeToxicityScore(text);
    final needsReply = _detectNeedsReply(text);
    final isQuestion = _detectQuestion(text);

    SentimentLabel label;
    if (isQuestion) {
      label = SentimentLabel.question;
    } else if (needsReply) {
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
      needsReply: needsReply || isQuestion,
      provider: providerName,
      confidence: 0.7, // Lower confidence for heuristic approach
    );
  }

  @override
  Future<List<SentimentResult>> analyzeBatch(List<String> texts) async {
    // Process sequentially for on-device (already fast enough)
    final results = <SentimentResult>[];
    for (final text in texts) {
      results.add(await analyze(text));
    }
    return results;
  }

  /// Computes sentiment score using weighted wordlists.
  double _computeSentimentScore(String text) {
    if (text.isEmpty) return 0.0;

    final lowerText = text.toLowerCase();
    double score = 0;
    int wordCount = 0;

    // Positive words with weights
    const positiveWords = {
      'great': 1.0,
      'awesome': 1.0,
      'amazing': 1.0,
      'excellent': 1.0,
      'fantastic': 1.0,
      'wonderful': 1.0,
      'love': 0.8,
      'good': 0.6,
      'nice': 0.6,
      'cool': 0.5,
      'like': 0.4,
      'helpful': 0.7,
      'thanks': 0.5,
      'thank': 0.5,
      'perfect': 1.0,
      'best': 0.9,
      'beautiful': 0.8,
      'brilliant': 0.9,
      'superb': 1.0,
      'outstanding': 1.0,
      'impressive': 0.8,
      'incredible': 0.9,
      'happy': 0.7,
      'joy': 0.7,
      'excited': 0.7,
      'fun': 0.6,
      'interesting': 0.5,
      'informative': 0.6,
      'useful': 0.6,
      'recommend': 0.7,
      'loved': 0.8,
      'enjoy': 0.6,
      'enjoyed': 0.6,
      'appreciate': 0.7,
    };

    // Negative words with weights
    const negativeWords = {
      'bad': -0.7,
      'terrible': -1.0,
      'awful': -1.0,
      'horrible': -1.0,
      'hate': -0.9,
      'worst': -1.0,
      'boring': -0.6,
      'poor': -0.6,
      'disappointing': -0.8,
      'disappointed': -0.8,
      'waste': -0.7,
      'stupid': -0.8,
      'dumb': -0.7,
      'annoying': -0.6,
      'ugly': -0.6,
      'useless': -0.8,
      'trash': -0.9,
      'garbage': -0.9,
      'sucks': -0.8,
      'pathetic': -0.9,
      'ridiculous': -0.6,
      'angry': -0.6,
      'sad': -0.5,
      'frustrating': -0.7,
      'confusing': -0.5,
      'wrong': -0.5,
      'false': -0.4,
      'fake': -0.7,
      'scam': -1.0,
      'dislike': -0.5,
      'hated': -0.9,
      'annoyed': -0.6,
    };

    // Check for positive words
    for (final entry in positiveWords.entries) {
      if (lowerText.contains(entry.key)) {
        score += entry.value;
        wordCount++;
      }
    }

    // Check for negative words
    for (final entry in negativeWords.entries) {
      if (lowerText.contains(entry.key)) {
        score += entry.value;
        wordCount++;
      }
    }

    // Check for negation modifiers
    const negations = ['not', "n't", 'never', 'no', 'dont', "don't", 'didnt', "didn't"];
    bool hasNegation = negations.any((n) => lowerText.contains(n));
    if (hasNegation && wordCount > 0) {
      score = -score * 0.5; // Flip and dampen
    }

    // Check for intensifiers
    const intensifiers = ['very', 'really', 'extremely', 'absolutely', 'totally'];
    bool hasIntensifier = intensifiers.any((i) => lowerText.contains(i));
    if (hasIntensifier && wordCount > 0) {
      score *= 1.3; // Amplify
    }

    // Normalize score to -1 to 1 range
    if (wordCount > 0) {
      score = (score / wordCount).clamp(-1.0, 1.0);
    }

    return score;
  }

  /// Computes toxicity score based on keyword detection.
  double _computeToxicityScore(String text) {
    if (text.isEmpty) return 0.0;

    final lowerText = text.toLowerCase();
    double score = 0;

    // Toxic/offensive words with weights
    const toxicWords = {
      'hate': 0.4,
      'stupid': 0.3,
      'idiot': 0.6,
      'dumb': 0.3,
      'moron': 0.6,
      'loser': 0.4,
      'kill': 0.5,
      'die': 0.4,
      'trash': 0.3,
      'garbage': 0.3,
      'pathetic': 0.4,
      'disgusting': 0.4,
      'worthless': 0.5,
      'shut up': 0.4,
      'ugly': 0.3,
    };

    // All caps detection (shouting)
    final words = text.split(_whitespacePattern);
    final capsWords = words.where((w) => 
      w.length > 2 && w == w.toUpperCase() && _capsPattern.hasMatch(w)
    ).length;
    if (capsWords > 2 || (words.length > 3 && capsWords / words.length > 0.5)) {
      score += 0.2;
    }

    // Check for toxic words
    for (final entry in toxicWords.entries) {
      if (lowerText.contains(entry.key)) {
        score += entry.value;
      }
    }

    // Excessive punctuation (!!!, ???)
    if (_excessivePunctuationPattern.hasMatch(text)) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Detects if the comment needs a reply.
  bool _detectNeedsReply(String text) {
    final lowerText = text.toLowerCase();

    // Direct questions/requests
    final requestPatterns = [
      RegExp(r'\bplease\b.*\b(help|explain|show|tell)\b'),
      RegExp(r'\bcan you\b'),
      RegExp(r'\bcould you\b'),
      RegExp(r'\bwould you\b'),
      RegExp(r'\bhow (do|can|to)\b'),
      RegExp(r'\b(help me|need help)\b'),
      RegExp(r'@\w+'), // Mentions
    ];

    for (final pattern in requestPatterns) {
      if (pattern.hasMatch(lowerText)) {
        return true;
      }
    }

    return false;
  }

  /// Detects if the text is a question.
  bool _detectQuestion(String text) {
    // Simple question mark detection
    if (text.contains('?')) return true;

    final lowerText = text.toLowerCase();
    
    // Question words at the start
    final questionStarters = [
      'who ', 'what ', 'when ', 'where ', 'why ', 'how ',
      'is ', 'are ', 'do ', 'does ', 'did ', 'can ', 'could ',
      'would ', 'should ', 'will ', 'have ', 'has ',
    ];

    for (final starter in questionStarters) {
      if (lowerText.startsWith(starter)) {
        return true;
      }
    }

    return false;
  }
}
