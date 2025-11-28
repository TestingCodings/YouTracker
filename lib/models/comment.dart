import 'package:hive/hive.dart';

part 'comment.g.dart';

@HiveType(typeId: 0)
class Comment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String videoId;

  @HiveField(2)
  final String videoTitle;

  @HiveField(3)
  final String videoThumbnailUrl;

  @HiveField(4)
  final String channelId;

  @HiveField(5)
  final String channelName;

  @HiveField(6)
  final String text;

  @HiveField(7)
  final DateTime publishedAt;

  @HiveField(8)
  final DateTime? updatedAt;

  @HiveField(9)
  final int likeCount;

  @HiveField(10)
  final int replyCount;

  @HiveField(11)
  final String? parentId;

  @HiveField(12)
  final bool isReply;

  @HiveField(13)
  final String authorName;

  @HiveField(14)
  final String? authorProfileImageUrl;

  @HiveField(15)
  final bool isBookmarked;

  // Sentiment analysis fields
  @HiveField(16)
  final double? sentimentScore;

  @HiveField(17)
  final String? sentimentLabel;

  @HiveField(18)
  final double? toxicScore;

  @HiveField(19)
  final bool? isToxic;

  @HiveField(20)
  final bool? needsReply;

  @HiveField(21)
  final DateTime? sentimentAnalyzedAt;

  @HiveField(22)
  final String? sentimentProvider;

  Comment({
    required this.id,
    required this.videoId,
    required this.videoTitle,
    required this.videoThumbnailUrl,
    required this.channelId,
    required this.channelName,
    required this.text,
    required this.publishedAt,
    this.updatedAt,
    required this.likeCount,
    required this.replyCount,
    this.parentId,
    required this.isReply,
    required this.authorName,
    this.authorProfileImageUrl,
    this.isBookmarked = false,
    this.sentimentScore,
    this.sentimentLabel,
    this.toxicScore,
    this.isToxic,
    this.needsReply,
    this.sentimentAnalyzedAt,
    this.sentimentProvider,
  });

  Comment copyWith({
    String? id,
    String? videoId,
    String? videoTitle,
    String? videoThumbnailUrl,
    String? channelId,
    String? channelName,
    String? text,
    DateTime? publishedAt,
    DateTime? updatedAt,
    int? likeCount,
    int? replyCount,
    String? parentId,
    bool? isReply,
    String? authorName,
    String? authorProfileImageUrl,
    bool? isBookmarked,
    double? sentimentScore,
    String? sentimentLabel,
    double? toxicScore,
    bool? isToxic,
    bool? needsReply,
    DateTime? sentimentAnalyzedAt,
    String? sentimentProvider,
  }) {
    return Comment(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      videoTitle: videoTitle ?? this.videoTitle,
      videoThumbnailUrl: videoThumbnailUrl ?? this.videoThumbnailUrl,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      text: text ?? this.text,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      parentId: parentId ?? this.parentId,
      isReply: isReply ?? this.isReply,
      authorName: authorName ?? this.authorName,
      authorProfileImageUrl:
          authorProfileImageUrl ?? this.authorProfileImageUrl,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      sentimentLabel: sentimentLabel ?? this.sentimentLabel,
      toxicScore: toxicScore ?? this.toxicScore,
      isToxic: isToxic ?? this.isToxic,
      needsReply: needsReply ?? this.needsReply,
      sentimentAnalyzedAt: sentimentAnalyzedAt ?? this.sentimentAnalyzedAt,
      sentimentProvider: sentimentProvider ?? this.sentimentProvider,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'videoTitle': videoTitle,
      'videoThumbnailUrl': videoThumbnailUrl,
      'channelId': channelId,
      'channelName': channelName,
      'text': text,
      'publishedAt': publishedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'likeCount': likeCount,
      'replyCount': replyCount,
      'parentId': parentId,
      'isReply': isReply,
      'authorName': authorName,
      'authorProfileImageUrl': authorProfileImageUrl,
      'isBookmarked': isBookmarked,
      'sentimentScore': sentimentScore,
      'sentimentLabel': sentimentLabel,
      'toxicScore': toxicScore,
      'isToxic': isToxic,
      'needsReply': needsReply,
      'sentimentAnalyzedAt': sentimentAnalyzedAt?.toIso8601String(),
      'sentimentProvider': sentimentProvider,
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      videoId: json['videoId'] as String,
      videoTitle: json['videoTitle'] as String,
      videoThumbnailUrl: json['videoThumbnailUrl'] as String,
      channelId: json['channelId'] as String,
      channelName: json['channelName'] as String,
      text: json['text'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      likeCount: json['likeCount'] as int,
      replyCount: json['replyCount'] as int,
      parentId: json['parentId'] as String?,
      isReply: json['isReply'] as bool,
      authorName: json['authorName'] as String,
      authorProfileImageUrl: json['authorProfileImageUrl'] as String?,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      sentimentScore: (json['sentimentScore'] as num?)?.toDouble(),
      sentimentLabel: json['sentimentLabel'] as String?,
      toxicScore: (json['toxicScore'] as num?)?.toDouble(),
      isToxic: json['isToxic'] as bool?,
      needsReply: json['needsReply'] as bool?,
      sentimentAnalyzedAt: json['sentimentAnalyzedAt'] != null
          ? DateTime.parse(json['sentimentAnalyzedAt'] as String)
          : null,
      sentimentProvider: json['sentimentProvider'] as String?,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, text: $text, videoTitle: $videoTitle)';
  }
}
