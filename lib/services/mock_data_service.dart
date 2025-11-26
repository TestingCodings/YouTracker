import '../models/models.dart';

/// Mock data service that provides sample data for development and testing.
/// This will be replaced with actual API calls in production.
class MockDataService {
  static final List<Comment> _mockComments = [
    Comment(
      id: 'comment_1',
      videoId: 'video_1',
      videoTitle: 'How to Build a Flutter App in 2024',
      videoThumbnailUrl: 'https://i.ytimg.com/vi/sample/maxresdefault.jpg',
      channelId: 'channel_1',
      channelName: 'Flutter Dev',
      text: 'Great tutorial! This really helped me understand state management.',
      publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      likeCount: 45,
      replyCount: 3,
      isReply: false,
      authorName: 'John Doe',
      authorProfileImageUrl: 'https://ui-avatars.com/api/?name=John+Doe',
      isBookmarked: true,
    ),
    Comment(
      id: 'comment_2',
      videoId: 'video_2',
      videoTitle: 'Advanced Riverpod Patterns',
      videoThumbnailUrl: 'https://i.ytimg.com/vi/sample2/maxresdefault.jpg',
      channelId: 'channel_2',
      channelName: 'Code With Andrea',
      text:
          'I have been using this pattern for a while now and it works perfectly!',
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      likeCount: 23,
      replyCount: 1,
      isReply: false,
      authorName: 'Jane Smith',
      authorProfileImageUrl: 'https://ui-avatars.com/api/?name=Jane+Smith',
    ),
    Comment(
      id: 'comment_3',
      videoId: 'video_3',
      videoTitle: 'Building a REST API with Node.js',
      videoThumbnailUrl: 'https://i.ytimg.com/vi/sample3/maxresdefault.jpg',
      channelId: 'channel_3',
      channelName: 'Traversy Media',
      text: 'Can you do a follow-up video on authentication?',
      publishedAt: DateTime.now().subtract(const Duration(days: 3)),
      likeCount: 89,
      replyCount: 12,
      isReply: false,
      authorName: 'Mike Johnson',
      authorProfileImageUrl: 'https://ui-avatars.com/api/?name=Mike+Johnson',
    ),
    Comment(
      id: 'comment_4',
      videoId: 'video_1',
      videoTitle: 'How to Build a Flutter App in 2024',
      videoThumbnailUrl: 'https://i.ytimg.com/vi/sample/maxresdefault.jpg',
      channelId: 'channel_1',
      channelName: 'Flutter Dev',
      text: 'Thanks for the great content!',
      publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
      likeCount: 12,
      replyCount: 0,
      isReply: true,
      parentId: 'comment_1',
      authorName: 'Sarah Lee',
      authorProfileImageUrl: 'https://ui-avatars.com/api/?name=Sarah+Lee',
    ),
    Comment(
      id: 'comment_5',
      videoId: 'video_4',
      videoTitle: 'Docker for Beginners',
      videoThumbnailUrl: 'https://i.ytimg.com/vi/sample4/maxresdefault.jpg',
      channelId: 'channel_4',
      channelName: 'TechWorld with Nana',
      text: 'This is exactly what I needed for my project. Subscribed!',
      publishedAt: DateTime.now().subtract(const Duration(days: 7)),
      likeCount: 156,
      replyCount: 5,
      isReply: false,
      authorName: 'Alex Chen',
      authorProfileImageUrl: 'https://ui-avatars.com/api/?name=Alex+Chen',
      isBookmarked: true,
    ),
    Comment(
      id: 'comment_6',
      videoId: 'video_5',
      videoTitle: 'Clean Architecture in Flutter',
      videoThumbnailUrl: 'https://i.ytimg.com/vi/sample5/maxresdefault.jpg',
      channelId: 'channel_5',
      channelName: 'Reso Coder',
      text:
          'Would love to see more examples with different state management solutions.',
      publishedAt: DateTime.now().subtract(const Duration(days: 14)),
      likeCount: 78,
      replyCount: 8,
      isReply: false,
      authorName: 'Emily Davis',
      authorProfileImageUrl: 'https://ui-avatars.com/api/?name=Emily+Davis',
    ),
    Comment(
      id: 'comment_7',
      videoId: 'video_6',
      videoTitle: 'AWS Lambda Tutorial',
      videoThumbnailUrl: 'https://i.ytimg.com/vi/sample6/maxresdefault.jpg',
      channelId: 'channel_6',
      channelName: 'Be A Better Dev',
      text: 'Perfect explanation! Finally understood the cold start issue.',
      publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      likeCount: 34,
      replyCount: 2,
      isReply: false,
      authorName: 'David Wilson',
      authorProfileImageUrl: 'https://ui-avatars.com/api/?name=David+Wilson',
    ),
    Comment(
      id: 'comment_8',
      videoId: 'video_7',
      videoTitle: 'Kubernetes 101',
      videoThumbnailUrl: 'https://i.ytimg.com/vi/sample7/maxresdefault.jpg',
      channelId: 'channel_7',
      channelName: 'NetworkChuck',
      text: 'Mind blown! 🤯 Great video!',
      publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
      likeCount: 234,
      replyCount: 15,
      isReply: false,
      authorName: 'Chris Martin',
      authorProfileImageUrl: 'https://ui-avatars.com/api/?name=Chris+Martin',
    ),
  ];

  static final List<Interaction> _mockInteractions = [
    Interaction(
      id: 'interaction_1',
      commentId: 'comment_1',
      type: InteractionType.like,
      fromUserId: 'user_2',
      fromUserName: 'Flutter Fan',
      fromUserProfileImageUrl: 'https://ui-avatars.com/api/?name=Flutter+Fan',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    Interaction(
      id: 'interaction_2',
      commentId: 'comment_1',
      type: InteractionType.reply,
      fromUserId: 'user_3',
      fromUserName: 'Tech Guru',
      fromUserProfileImageUrl: 'https://ui-avatars.com/api/?name=Tech+Guru',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      replyText: 'I agree! This is amazing content.',
    ),
    Interaction(
      id: 'interaction_3',
      commentId: 'comment_3',
      type: InteractionType.heart,
      fromUserId: 'channel_3',
      fromUserName: 'Traversy Media',
      fromUserProfileImageUrl: 'https://ui-avatars.com/api/?name=Traversy',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Interaction(
      id: 'interaction_4',
      commentId: 'comment_5',
      type: InteractionType.like,
      fromUserId: 'user_4',
      fromUserName: 'Code Lover',
      fromUserProfileImageUrl: 'https://ui-avatars.com/api/?name=Code+Lover',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Interaction(
      id: 'interaction_5',
      commentId: 'comment_2',
      type: InteractionType.mention,
      fromUserId: 'user_5',
      fromUserName: 'Andrea',
      fromUserProfileImageUrl: 'https://ui-avatars.com/api/?name=Andrea',
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      replyText: '@JaneSmith check out my latest video on this topic!',
    ),
  ];

  static List<Comment> getComments() => List.from(_mockComments);

  static List<Interaction> getInteractions() => List.from(_mockInteractions);

  static Comment? getCommentById(String id) {
    try {
      return _mockComments.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Interaction> getInteractionsForComment(String commentId) {
    return _mockInteractions.where((i) => i.commentId == commentId).toList();
  }
}
