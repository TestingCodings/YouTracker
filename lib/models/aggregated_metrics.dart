import 'package:hive/hive.dart';

import '../storage/hive_boxes.dart';

part 'aggregated_metrics.g.dart';

/// Represents a video with high engagement for analytics.
@HiveType(typeId: 10)
class TopVideo extends HiveObject {
  @HiveField(0)
  final String videoId;

  @HiveField(1)
  final String videoTitle;

  @HiveField(2)
  final int commentCount;

  @HiveField(3)
  final int likeCount;

  @HiveField(4)
  final String? thumbnailUrl;

  TopVideo({
    required this.videoId,
    required this.videoTitle,
    required this.commentCount,
    this.likeCount = 0,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'videoTitle': videoTitle,
        'commentCount': commentCount,
        'likeCount': likeCount,
        'thumbnailUrl': thumbnailUrl,
      };

  factory TopVideo.fromJson(Map<String, dynamic> json) => TopVideo(
        videoId: json['videoId'] as String,
        videoTitle: json['videoTitle'] as String,
        commentCount: json['commentCount'] as int,
        likeCount: json['likeCount'] as int? ?? 0,
        thumbnailUrl: json['thumbnailUrl'] as String?,
      );
}

/// Represents a frequent commenter for analytics.
@HiveType(typeId: 11)
class TopCommenter extends HiveObject {
  @HiveField(0)
  final String authorName;

  @HiveField(1)
  final int commentCount;

  @HiveField(2)
  final String? authorProfileImageUrl;

  @HiveField(3)
  final int totalLikes;

  TopCommenter({
    required this.authorName,
    required this.commentCount,
    this.authorProfileImageUrl,
    this.totalLikes = 0,
  });

  Map<String, dynamic> toJson() => {
        'authorName': authorName,
        'commentCount': commentCount,
        'authorProfileImageUrl': authorProfileImageUrl,
        'totalLikes': totalLikes,
      };

  factory TopCommenter.fromJson(Map<String, dynamic> json) => TopCommenter(
        authorName: json['authorName'] as String,
        commentCount: json['commentCount'] as int,
        authorProfileImageUrl: json['authorProfileImageUrl'] as String?,
        totalLikes: json['totalLikes'] as int? ?? 0,
      );
}

/// Engagement distribution data.
@HiveType(typeId: 12)
class EngagementDistribution extends HiveObject {
  @HiveField(0)
  final int totalViews;

  @HiveField(1)
  final int totalLikes;

  @HiveField(2)
  final int totalComments;

  @HiveField(3)
  final int totalReplies;

  /// Hour of day (0-23) to comment count mapping for pattern analysis.
  @HiveField(4)
  final Map<int, int> hourlyCommentPattern;

  /// Day of week (1-7, Monday=1) to comment count mapping.
  @HiveField(5)
  final Map<int, int> weekdayCommentPattern;

  EngagementDistribution({
    this.totalViews = 0,
    this.totalLikes = 0,
    this.totalComments = 0,
    this.totalReplies = 0,
    Map<int, int>? hourlyCommentPattern,
    Map<int, int>? weekdayCommentPattern,
  })  : hourlyCommentPattern = hourlyCommentPattern ?? {},
        weekdayCommentPattern = weekdayCommentPattern ?? {};

  Map<String, dynamic> toJson() => {
        'totalViews': totalViews,
        'totalLikes': totalLikes,
        'totalComments': totalComments,
        'totalReplies': totalReplies,
        'hourlyCommentPattern': hourlyCommentPattern.map(
          (k, v) => MapEntry(k.toString(), v),
        ),
        'weekdayCommentPattern': weekdayCommentPattern.map(
          (k, v) => MapEntry(k.toString(), v),
        ),
      };

  factory EngagementDistribution.fromJson(Map<String, dynamic> json) =>
      EngagementDistribution(
        totalViews: json['totalViews'] as int? ?? 0,
        totalLikes: json['totalLikes'] as int? ?? 0,
        totalComments: json['totalComments'] as int? ?? 0,
        totalReplies: json['totalReplies'] as int? ?? 0,
        hourlyCommentPattern:
            (json['hourlyCommentPattern'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.parse(k), v as int),
        ),
        weekdayCommentPattern:
            (json['weekdayCommentPattern'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.parse(k), v as int),
        ),
      );
}

/// Aggregated metrics for a specific date and period type.
@HiveType(typeId: 13)
class AggregatedMetrics extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final PeriodType periodType;

  @HiveField(2)
  final int totalComments;

  @HiveField(3)
  final int totalReplies;

  @HiveField(4)
  final double avgReplyTimeSeconds;

  /// Sentiment score from -1.0 (negative) to 1.0 (positive).
  @HiveField(5)
  final double sentimentScore;

  @HiveField(6)
  final List<TopVideo> topVideos;

  @HiveField(7)
  final List<TopCommenter> topCommenters;

  @HiveField(8)
  final EngagementDistribution engagement;

  @HiveField(9)
  final DateTime lastUpdated;

  AggregatedMetrics({
    required this.date,
    required this.periodType,
    this.totalComments = 0,
    this.totalReplies = 0,
    this.avgReplyTimeSeconds = 0.0,
    this.sentimentScore = 0.0,
    List<TopVideo>? topVideos,
    List<TopCommenter>? topCommenters,
    EngagementDistribution? engagement,
    DateTime? lastUpdated,
  })  : topVideos = topVideos ?? [],
        topCommenters = topCommenters ?? [],
        engagement = engagement ?? EngagementDistribution(),
        lastUpdated = lastUpdated ?? DateTime.now();

  /// Creates a copy with updated fields.
  AggregatedMetrics copyWith({
    DateTime? date,
    PeriodType? periodType,
    int? totalComments,
    int? totalReplies,
    double? avgReplyTimeSeconds,
    double? sentimentScore,
    List<TopVideo>? topVideos,
    List<TopCommenter>? topCommenters,
    EngagementDistribution? engagement,
    DateTime? lastUpdated,
  }) {
    return AggregatedMetrics(
      date: date ?? this.date,
      periodType: periodType ?? this.periodType,
      totalComments: totalComments ?? this.totalComments,
      totalReplies: totalReplies ?? this.totalReplies,
      avgReplyTimeSeconds: avgReplyTimeSeconds ?? this.avgReplyTimeSeconds,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      topVideos: topVideos ?? this.topVideos,
      topCommenters: topCommenters ?? this.topCommenters,
      engagement: engagement ?? this.engagement,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'periodType': periodType.name,
        'totalComments': totalComments,
        'totalReplies': totalReplies,
        'avgReplyTimeSeconds': avgReplyTimeSeconds,
        'sentimentScore': sentimentScore,
        'topVideos': topVideos.map((v) => v.toJson()).toList(),
        'topCommenters': topCommenters.map((c) => c.toJson()).toList(),
        'engagement': engagement.toJson(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory AggregatedMetrics.fromJson(Map<String, dynamic> json) =>
      AggregatedMetrics(
        date: DateTime.parse(json['date'] as String),
        periodType: PeriodType.values.firstWhere(
          (e) => e.name == json['periodType'],
          orElse: () => PeriodType.daily,
        ),
        totalComments: json['totalComments'] as int? ?? 0,
        totalReplies: json['totalReplies'] as int? ?? 0,
        avgReplyTimeSeconds:
            (json['avgReplyTimeSeconds'] as num?)?.toDouble() ?? 0.0,
        sentimentScore: (json['sentimentScore'] as num?)?.toDouble() ?? 0.0,
        topVideos: (json['topVideos'] as List<dynamic>?)
                ?.map((v) => TopVideo.fromJson(v as Map<String, dynamic>))
                .toList() ??
            [],
        topCommenters: (json['topCommenters'] as List<dynamic>?)
                ?.map((c) => TopCommenter.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        engagement: json['engagement'] != null
            ? EngagementDistribution.fromJson(
                json['engagement'] as Map<String, dynamic>)
            : null,
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'] as String)
            : null,
      );

  @override
  String toString() {
    return 'AggregatedMetrics(date: $date, periodType: $periodType, totalComments: $totalComments)';
  }
}
