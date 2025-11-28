import 'package:flutter_test/flutter_test.dart';
import 'package:you_tracker/sentiment/sentiment.dart';

void main() {
  group('OnDeviceSentimentService', () {
    late OnDeviceSentimentService service;

    setUp(() async {
      service = OnDeviceSentimentService();
      await service.initialize();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('should initialize correctly', () {
      expect(service.isAvailable, isTrue);
      expect(service.providerName, equals('on-device'));
    });

    test('should detect positive sentiment', () async {
      final result = await service.analyze('This is a great video! I love it!');

      expect(result.sentimentLabel, equals(SentimentLabel.positive));
      expect(result.sentimentScore, greaterThan(0.3));
      expect(result.provider, equals('on-device'));
    });

    test('should detect negative sentiment', () async {
      final result = await service.analyze('This is terrible. I hate this content.');

      expect(result.sentimentLabel, equals(SentimentLabel.negative));
      expect(result.sentimentScore, lessThan(-0.3));
    });

    test('should detect neutral sentiment', () async {
      final result = await service.analyze('This is a video about programming.');

      expect(result.sentimentLabel, equals(SentimentLabel.neutral));
      expect(result.sentimentScore, inInclusiveRange(-0.3, 0.3));
    });

    test('should detect questions', () async {
      final result = await service.analyze('How do I subscribe to this channel?');

      expect(result.sentimentLabel, equals(SentimentLabel.question));
      expect(result.needsReply, isTrue);
    });

    test('should detect needs reply', () async {
      final result = await service.analyze('Can you help me with this problem?');

      expect(result.needsReply, isTrue);
    });

    test('should detect toxic content', () async {
      final result = await service.analyze('You are an idiot and a moron!');

      expect(result.toxicScore, greaterThan(0.5));
      expect(result.isToxic, isTrue);
    });

    test('should not flag non-toxic content', () async {
      final result = await service.analyze('Thanks for sharing this helpful tutorial.');

      expect(result.toxicScore, lessThan(0.7));
      expect(result.isToxic, isFalse);
    });

    test('should handle empty text', () async {
      final result = await service.analyze('');

      expect(result.sentimentScore, equals(0.0));
      expect(result.sentimentLabel, equals(SentimentLabel.neutral));
    });

    test('should handle negation', () async {
      final result = await service.analyze('This is not good at all.');

      // Negation should flip the sentiment
      expect(result.sentimentScore, lessThan(0.0));
    });

    test('should process batch correctly', () async {
      final results = await service.analyzeBatch([
        'Great video!',
        'Terrible content.',
        'How do I do this?',
      ]);

      expect(results.length, equals(3));
      expect(results[0].sentimentLabel, equals(SentimentLabel.positive));
      expect(results[1].sentimentLabel, equals(SentimentLabel.negative));
      expect(results[2].sentimentLabel, equals(SentimentLabel.question));
    });

    test('should detect @mentions as needing reply', () async {
      final result = await service.analyze('@creator please respond to this');

      expect(result.needsReply, isTrue);
    });
  });

  group('SentimentResult', () {
    test('should serialize to JSON', () {
      final result = const SentimentResult(
        sentimentScore: 0.8,
        sentimentLabel: SentimentLabel.positive,
        toxicScore: 0.1,
        isToxic: false,
        needsReply: false,
        provider: 'test',
        confidence: 0.9,
      );

      final json = result.toJson();

      expect(json['sentimentScore'], equals(0.8));
      expect(json['sentimentLabel'], equals('positive'));
      expect(json['toxicScore'], equals(0.1));
      expect(json['isToxic'], isFalse);
      expect(json['provider'], equals('test'));
    });

    test('should deserialize from JSON', () {
      final json = {
        'sentimentScore': -0.5,
        'sentimentLabel': 'negative',
        'toxicScore': 0.3,
        'isToxic': false,
        'needsReply': true,
        'provider': 'cloud',
        'confidence': 0.85,
      };

      final result = SentimentResult.fromJson(json);

      expect(result.sentimentScore, equals(-0.5));
      expect(result.sentimentLabel, equals(SentimentLabel.negative));
      expect(result.needsReply, isTrue);
    });

    test('should create empty result', () {
      final empty = SentimentResult.empty();

      expect(empty.sentimentScore, equals(0.0));
      expect(empty.sentimentLabel, equals(SentimentLabel.neutral));
      expect(empty.confidence, equals(0.0));
      expect(empty.provider, equals('none'));
    });
  });

  group('SentimentConfig', () {
    test('should create with defaults', () {
      final config = SentimentConfig.defaults();

      expect(config.provider, equals(SentimentProvider.off));
      expect(config.enabled, isFalse);
      expect(config.toxicityThreshold, equals(0.7));
      expect(config.anonymizeForCloud, isTrue);
    });

    test('should serialize to JSON', () {
      final config = const SentimentConfig(
        provider: SentimentProvider.onDevice,
        enabled: true,
        toxicityThreshold: 0.6,
      );

      final json = config.toJson();

      expect(json['provider'], equals('onDevice'));
      expect(json['enabled'], isTrue);
      expect(json['toxicityThreshold'], equals(0.6));
    });

    test('should deserialize from JSON', () {
      final json = {
        'provider': 'cloud',
        'enabled': true,
        'toxicityThreshold': 0.8,
        'anonymizeForCloud': false,
        'cloudEndpoint': 'https://api.example.com',
      };

      final config = SentimentConfig.fromJson(json);

      expect(config.provider, equals(SentimentProvider.cloud));
      expect(config.enabled, isTrue);
      expect(config.toxicityThreshold, equals(0.8));
      expect(config.anonymizeForCloud, isFalse);
      expect(config.cloudEndpoint, equals('https://api.example.com'));
    });

    test('should copy with updated fields', () {
      final original = const SentimentConfig(
        provider: SentimentProvider.off,
        enabled: false,
      );

      final updated = original.copyWith(
        provider: SentimentProvider.onDevice,
        enabled: true,
      );

      expect(original.provider, equals(SentimentProvider.off));
      expect(updated.provider, equals(SentimentProvider.onDevice));
      expect(updated.enabled, isTrue);
    });
  });

  group('SentimentLabel', () {
    test('should have correct display names', () {
      expect(SentimentLabel.positive.displayName, equals('Positive'));
      expect(SentimentLabel.neutral.displayName, equals('Neutral'));
      expect(SentimentLabel.negative.displayName, equals('Negative'));
      expect(SentimentLabel.question.displayName, equals('Question'));
      expect(SentimentLabel.needsReply.displayName, equals('Needs Reply'));
    });
  });

  group('SentimentProvider', () {
    test('should have correct display names', () {
      expect(SentimentProvider.off.displayName, equals('Off'));
      expect(SentimentProvider.onDevice.displayName, equals('On-Device'));
      expect(SentimentProvider.cloud.displayName, equals('Cloud'));
    });

    test('should have descriptions', () {
      expect(SentimentProvider.off.description, isNotEmpty);
      expect(SentimentProvider.onDevice.description, isNotEmpty);
      expect(SentimentProvider.cloud.description, isNotEmpty);
    });
  });

  group('MockCloudSentimentService', () {
    late MockCloudSentimentService service;

    setUp(() async {
      service = MockCloudSentimentService();
      await service.initialize();
    });

    test('should analyze text', () async {
      final result = await service.analyze('Great video!');

      expect(result.provider, equals('mock-cloud'));
      expect(result.confidence, greaterThan(0.8));
    });

    test('should detect positive sentiment in mock', () async {
      final result = await service.analyze('I love this awesome content!');

      expect(result.sentimentLabel, equals(SentimentLabel.positive));
    });

    test('should detect questions in mock', () async {
      final result = await service.analyze('How does this work?');

      expect(result.sentimentLabel, equals(SentimentLabel.question));
    });
  });
}
