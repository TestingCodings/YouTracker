import 'package:hive_flutter/hive_flutter.dart';

import '../models/aggregated_metrics.dart';
import '../models/comment.dart';
import '../storage/hive_adapters.dart';
import '../storage/hive_boxes.dart';
import 'local_storage_service.dart';

/// Service for computing and storing analytics metrics.
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  AnalyticsService._();

  Box<AggregatedMetrics>? _metricsBox;
  bool _isInitialized = false;

  /// Initializes the analytics service and opens the metrics box.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Register adapters
    registerAnalyticsAdapters();

    // Open the metrics box
    _metricsBox = await Hive.openBox<AggregatedMetrics>(
      HiveBoxNames.aggregatedMetrics,
    );

    _isInitialized = true;
  }

  /// Ensures the service is initialized.
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // ============ Aggregation Methods ============

  /// Aggregates metrics for a given date range and period type.
  Future<List<AggregatedMetrics>> aggregateForRange(
    DateTime start,
    DateTime end,
    PeriodType periodType,
  ) async {
    await _ensureInitialized();

    final comments = LocalStorageService.instance.getAllComments();
    final results = <AggregatedMetrics>[];

    // Filter comments within the range
    final filteredComments = comments.where((c) {
      return c.publishedAt.isAfter(start.subtract(const Duration(days: 1))) &&
          c.publishedAt.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    switch (periodType) {
      case PeriodType.daily:
        // Group by day
        for (var date = start;
            !date.isAfter(end);
            date = date.add(const Duration(days: 1))) {
          final dayComments = filteredComments.where((c) {
            return c.publishedAt.year == date.year &&
                c.publishedAt.month == date.month &&
                c.publishedAt.day == date.day;
          }).toList();
          final metrics = _computeMetrics(dayComments, date, periodType);
          await _storeMetrics(metrics);
          results.add(metrics);
        }
        break;

      case PeriodType.weekly:
        // Group by week (start from Monday)
        var weekStart = start;
        while (!weekStart.isAfter(end)) {
          final weekEnd = weekStart.add(const Duration(days: 6));
          final weekComments = filteredComments.where((c) {
            return !c.publishedAt.isBefore(weekStart) &&
                !c.publishedAt.isAfter(weekEnd);
          }).toList();
          final metrics = _computeMetrics(weekComments, weekStart, periodType);
          await _storeMetrics(metrics);
          results.add(metrics);
          weekStart = weekStart.add(const Duration(days: 7));
        }
        break;

      case PeriodType.monthly:
        // Group by month
        var monthDate = DateTime(start.year, start.month, 1);
        while (!monthDate.isAfter(end)) {
          final nextMonth = DateTime(monthDate.year, monthDate.month + 1, 1);
          final monthComments = filteredComments.where((c) {
            return c.publishedAt.year == monthDate.year &&
                c.publishedAt.month == monthDate.month;
          }).toList();
          final metrics = _computeMetrics(monthComments, monthDate, periodType);
          await _storeMetrics(metrics);
          results.add(metrics);
          monthDate = nextMonth;
        }
        break;
    }

    return results;
  }

  /// Computes metrics for a list of comments.
  AggregatedMetrics _computeMetrics(
    List<Comment> comments,
    DateTime date,
    PeriodType periodType,
  ) {
    if (comments.isEmpty) {
      return AggregatedMetrics(
        date: date,
        periodType: periodType,
      );
    }

    // Total comments and replies
    final totalComments = comments.where((c) => !c.isReply).length;
    final totalReplies = comments.where((c) => c.isReply).length;

    // Compute sentiment score
    double totalSentiment = 0;
    for (final comment in comments) {
      totalSentiment += computeSentiment(comment.text);
    }
    final avgSentiment = comments.isNotEmpty ? totalSentiment / comments.length : 0.0;

    // Compute average reply time
    final avgReplyTime = computeAvgReplyTime(comments);

    // Compute top videos
    final videoStats = <String, _VideoStats>{};
    for (final comment in comments) {
      videoStats.putIfAbsent(
        comment.videoId,
        () => _VideoStats(
          videoId: comment.videoId,
          videoTitle: comment.videoTitle,
          thumbnailUrl: comment.videoThumbnailUrl,
        ),
      );
      videoStats[comment.videoId]!.commentCount++;
      videoStats[comment.videoId]!.likeCount += comment.likeCount;
    }
    final topVideos = videoStats.values
        .map((v) => TopVideo(
              videoId: v.videoId,
              videoTitle: v.videoTitle,
              commentCount: v.commentCount,
              likeCount: v.likeCount,
              thumbnailUrl: v.thumbnailUrl,
            ))
        .toList()
      ..sort((a, b) => b.commentCount.compareTo(a.commentCount));

    // Compute top commenters
    final commenterStats = <String, _CommenterStats>{};
    for (final comment in comments) {
      commenterStats.putIfAbsent(
        comment.authorName,
        () => _CommenterStats(
          authorName: comment.authorName,
          authorProfileImageUrl: comment.authorProfileImageUrl,
        ),
      );
      commenterStats[comment.authorName]!.commentCount++;
      commenterStats[comment.authorName]!.totalLikes += comment.likeCount;
    }
    final topCommenters = commenterStats.values
        .map((c) => TopCommenter(
              authorName: c.authorName,
              commentCount: c.commentCount,
              authorProfileImageUrl: c.authorProfileImageUrl,
              totalLikes: c.totalLikes,
            ))
        .toList()
      ..sort((a, b) => b.commentCount.compareTo(a.commentCount));

    // Compute engagement patterns
    final hourlyPattern = <int, int>{};
    final weekdayPattern = <int, int>{};
    int totalLikes = 0;

    for (final comment in comments) {
      final hour = comment.publishedAt.hour;
      final weekday = comment.publishedAt.weekday;
      
      hourlyPattern[hour] = (hourlyPattern[hour] ?? 0) + 1;
      weekdayPattern[weekday] = (weekdayPattern[weekday] ?? 0) + 1;
      totalLikes += comment.likeCount;
    }

    final engagement = EngagementDistribution(
      totalViews: 0, // Views would come from video data
      totalLikes: totalLikes,
      totalComments: totalComments,
      totalReplies: totalReplies,
      hourlyCommentPattern: hourlyPattern,
      weekdayCommentPattern: weekdayPattern,
    );

    return AggregatedMetrics(
      date: date,
      periodType: periodType,
      totalComments: totalComments,
      totalReplies: totalReplies,
      avgReplyTimeSeconds: avgReplyTime,
      sentimentScore: avgSentiment,
      topVideos: topVideos.take(10).toList(),
      topCommenters: topCommenters.take(10).toList(),
      engagement: engagement,
      lastUpdated: DateTime.now(),
    );
  }

  /// Stores metrics to the Hive box.
  Future<void> _storeMetrics(AggregatedMetrics metrics) async {
    final key = HiveBoxNames.metricsKey(metrics.periodType, metrics.date);
    await _metricsBox?.put(key, metrics);
  }

  /// Gets aggregated metrics for a period type and date range.
  Future<List<AggregatedMetrics>> getAggregatedMetrics(
    PeriodType periodType,
    DateTime start,
    DateTime end,
  ) async {
    await _ensureInitialized();

    final results = <AggregatedMetrics>[];

    switch (periodType) {
      case PeriodType.daily:
        for (var date = start;
            !date.isAfter(end);
            date = date.add(const Duration(days: 1))) {
          final key = HiveBoxNames.metricsKey(periodType, date);
          final metrics = _metricsBox?.get(key);
          if (metrics != null) {
            results.add(metrics);
          }
        }
        break;

      case PeriodType.weekly:
        var weekStart = start;
        while (!weekStart.isAfter(end)) {
          final key = HiveBoxNames.metricsKey(periodType, weekStart);
          final metrics = _metricsBox?.get(key);
          if (metrics != null) {
            results.add(metrics);
          }
          weekStart = weekStart.add(const Duration(days: 7));
        }
        break;

      case PeriodType.monthly:
        var monthDate = DateTime(start.year, start.month, 1);
        while (!monthDate.isAfter(end)) {
          final key = HiveBoxNames.metricsKey(periodType, monthDate);
          final metrics = _metricsBox?.get(key);
          if (metrics != null) {
            results.add(metrics);
          }
          monthDate = DateTime(monthDate.year, monthDate.month + 1, 1);
        }
        break;
    }

    return results;
  }

  /// Clears all aggregated metrics.
  Future<void> clearMetrics() async {
    await _ensureInitialized();
    await _metricsBox?.clear();
  }

  /// Clears metrics for a specific period type.
  Future<void> clearMetricsForPeriod(PeriodType periodType) async {
    await _ensureInitialized();

    final keysToRemove = <String>[];
    String prefix;

    switch (periodType) {
      case PeriodType.daily:
        prefix = HiveBoxNames.dailyPrefix;
        break;
      case PeriodType.weekly:
        prefix = HiveBoxNames.weeklyPrefix;
        break;
      case PeriodType.monthly:
        prefix = HiveBoxNames.monthlyPrefix;
        break;
    }

    for (final key in _metricsBox?.keys ?? []) {
      if (key.toString().startsWith(prefix)) {
        keysToRemove.add(key.toString());
      }
    }

    for (final key in keysToRemove) {
      await _metricsBox?.delete(key);
    }
  }

  // ============ Sentiment Analysis ============

  /// Simple sentiment scoring based on weighted wordlists.
  /// Returns a score from -1.0 (negative) to 1.0 (positive).
  double computeSentiment(String text) {
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
    const negations = ['not', "n't", 'never', 'no'];
    bool hasNegation = negations.any((n) => lowerText.contains(n));
    if (hasNegation && wordCount > 0) {
      score = -score * 0.5; // Flip and dampen
    }

    // Normalize score to -1 to 1 range
    if (wordCount > 0) {
      score = (score / wordCount).clamp(-1.0, 1.0);
    }

    return score;
  }

  /// Computes average reply time in seconds.
  /// Uses the time difference between a reply and its parent comment.
  double computeAvgReplyTime(List<Comment> comments) {
    final parentComments = <String, Comment>{};
    final replies = <Comment>[];

    for (final comment in comments) {
      if (!comment.isReply) {
        parentComments[comment.id] = comment;
      } else {
        replies.add(comment);
      }
    }

    if (replies.isEmpty) return 0.0;

    double totalSeconds = 0;
    int validReplies = 0;

    for (final reply in replies) {
      if (reply.parentId != null && parentComments.containsKey(reply.parentId)) {
        final parent = parentComments[reply.parentId]!;
        final diff = reply.publishedAt.difference(parent.publishedAt);
        if (diff.inSeconds > 0) {
          totalSeconds += diff.inSeconds;
          validReplies++;
        }
      }
    }

    return validReplies > 0 ? totalSeconds / validReplies : 0.0;
  }

  /// Gets the latest metrics summary for display.
  Future<AggregatedMetrics?> getLatestMetrics(PeriodType periodType) async {
    await _ensureInitialized();

    final today = DateTime.now();
    DateTime startDate;

    switch (periodType) {
      case PeriodType.daily:
        startDate = DateTime(today.year, today.month, today.day);
        break;
      case PeriodType.weekly:
        startDate = today.subtract(Duration(days: today.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case PeriodType.monthly:
        startDate = DateTime(today.year, today.month, 1);
        break;
    }

    final key = HiveBoxNames.metricsKey(periodType, startDate);
    return _metricsBox?.get(key);
  }

  /// Re-aggregates all metrics for a given date range.
  Future<void> recomputeMetrics(DateTime start, DateTime end) async {
    // Clear existing metrics for the range
    await clearMetrics();

    // Recompute for all period types
    await aggregateForRange(start, end, PeriodType.daily);
    await aggregateForRange(start, end, PeriodType.weekly);
    await aggregateForRange(start, end, PeriodType.monthly);
  }

  /// Closes the metrics box.
  Future<void> close() async {
    await _metricsBox?.close();
    _isInitialized = false;
  }
}

/// Helper class for video statistics aggregation.
class _VideoStats {
  final String videoId;
  final String videoTitle;
  final String? thumbnailUrl;
  int commentCount = 0;
  int likeCount = 0;

  _VideoStats({
    required this.videoId,
    required this.videoTitle,
    this.thumbnailUrl,
  });
}

/// Helper class for commenter statistics aggregation.
class _CommenterStats {
  final String authorName;
  final String? authorProfileImageUrl;
  int commentCount = 0;
  int totalLikes = 0;

  _CommenterStats({
    required this.authorName,
    this.authorProfileImageUrl,
  });
}
