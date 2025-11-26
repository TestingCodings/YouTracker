import 'package:flutter_test/flutter_test.dart';
import 'package:you_tracker/models/models.dart';

void main() {
  group('Comment Model', () {
    test('should create a Comment with required fields', () {
      final comment = Comment(
        id: 'test_id',
        videoId: 'video_1',
        videoTitle: 'Test Video',
        videoThumbnailUrl: 'https://example.com/thumb.jpg',
        channelId: 'channel_1',
        channelName: 'Test Channel',
        text: 'This is a test comment',
        publishedAt: DateTime(2024, 1, 1),
        likeCount: 10,
        replyCount: 2,
        isReply: false,
        authorName: 'Test User',
      );

      expect(comment.id, 'test_id');
      expect(comment.text, 'This is a test comment');
      expect(comment.isBookmarked, false);
    });

    test('should create Comment from JSON', () {
      final json = {
        'id': 'test_id',
        'videoId': 'video_1',
        'videoTitle': 'Test Video',
        'videoThumbnailUrl': 'https://example.com/thumb.jpg',
        'channelId': 'channel_1',
        'channelName': 'Test Channel',
        'text': 'This is a test comment',
        'publishedAt': '2024-01-01T00:00:00.000',
        'likeCount': 10,
        'replyCount': 2,
        'isReply': false,
        'authorName': 'Test User',
      };

      final comment = Comment.fromJson(json);

      expect(comment.id, 'test_id');
      expect(comment.videoTitle, 'Test Video');
    });

    test('should convert Comment to JSON', () {
      final comment = Comment(
        id: 'test_id',
        videoId: 'video_1',
        videoTitle: 'Test Video',
        videoThumbnailUrl: 'https://example.com/thumb.jpg',
        channelId: 'channel_1',
        channelName: 'Test Channel',
        text: 'This is a test comment',
        publishedAt: DateTime(2024, 1, 1),
        likeCount: 10,
        replyCount: 2,
        isReply: false,
        authorName: 'Test User',
      );

      final json = comment.toJson();

      expect(json['id'], 'test_id');
      expect(json['text'], 'This is a test comment');
    });

    test('copyWith should update specified fields', () {
      final comment = Comment(
        id: 'test_id',
        videoId: 'video_1',
        videoTitle: 'Test Video',
        videoThumbnailUrl: 'https://example.com/thumb.jpg',
        channelId: 'channel_1',
        channelName: 'Test Channel',
        text: 'This is a test comment',
        publishedAt: DateTime(2024, 1, 1),
        likeCount: 10,
        replyCount: 2,
        isReply: false,
        authorName: 'Test User',
        isBookmarked: false,
      );

      final updatedComment = comment.copyWith(isBookmarked: true, likeCount: 15);

      expect(updatedComment.isBookmarked, true);
      expect(updatedComment.likeCount, 15);
      expect(updatedComment.id, 'test_id'); // Unchanged field
    });
  });

  group('Interaction Model', () {
    test('should create an Interaction with required fields', () {
      final interaction = Interaction(
        id: 'interaction_1',
        commentId: 'comment_1',
        type: InteractionType.like,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(interaction.id, 'interaction_1');
      expect(interaction.type, InteractionType.like);
      expect(interaction.isRead, false);
    });

    test('should display correct text for like interaction', () {
      final interaction = Interaction(
        id: 'interaction_1',
        commentId: 'comment_1',
        type: InteractionType.like,
        fromUserName: 'John',
        timestamp: DateTime(2024, 1, 1),
      );

      expect(interaction.displayText, 'John liked your comment');
    });

    test('should display correct text for reply interaction', () {
      final interaction = Interaction(
        id: 'interaction_1',
        commentId: 'comment_1',
        type: InteractionType.reply,
        fromUserName: 'Jane',
        timestamp: DateTime(2024, 1, 1),
        replyText: 'Great comment!',
      );

      expect(interaction.displayText, 'Jane replied to your comment');
    });

    test('should display correct text for heart interaction', () {
      final interaction = Interaction(
        id: 'interaction_1',
        commentId: 'comment_1',
        type: InteractionType.heart,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(interaction.displayText, 'The creator hearted your comment');
    });

    test('should create Interaction from JSON', () {
      final json = {
        'id': 'interaction_1',
        'commentId': 'comment_1',
        'type': 'like',
        'fromUserId': 'user_1',
        'fromUserName': 'Test User',
        'timestamp': '2024-01-01T00:00:00.000',
        'isRead': false,
      };

      final interaction = Interaction.fromJson(json);

      expect(interaction.id, 'interaction_1');
      expect(interaction.type, InteractionType.like);
    });

    test('should convert Interaction to JSON', () {
      final interaction = Interaction(
        id: 'interaction_1',
        commentId: 'comment_1',
        type: InteractionType.reply,
        fromUserId: 'user_1',
        fromUserName: 'Test User',
        timestamp: DateTime(2024, 1, 1),
        replyText: 'Nice!',
      );

      final json = interaction.toJson();

      expect(json['id'], 'interaction_1');
      expect(json['type'], 'reply');
      expect(json['replyText'], 'Nice!');
    });
  });
}
