import 'package:hive/hive.dart';

import '../models/aggregated_metrics.dart';
import 'hive_boxes.dart';

/// Hive adapter for PeriodType enum.
class PeriodTypeAdapter extends TypeAdapter<PeriodType> {
  @override
  final int typeId = 14;

  @override
  PeriodType read(BinaryReader reader) {
    final index = reader.readByte();
    return PeriodType.values[index];
  }

  @override
  void write(BinaryWriter writer, PeriodType obj) {
    writer.writeByte(obj.index);
  }
}

/// Hive adapter for TopVideo.
class TopVideoAdapter extends TypeAdapter<TopVideo> {
  @override
  final int typeId = 10;

  @override
  TopVideo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return TopVideo(
      videoId: fields[0] as String,
      videoTitle: fields[1] as String,
      commentCount: fields[2] as int,
      likeCount: fields[3] as int? ?? 0,
      thumbnailUrl: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TopVideo obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.videoId)
      ..writeByte(1)
      ..write(obj.videoTitle)
      ..writeByte(2)
      ..write(obj.commentCount)
      ..writeByte(3)
      ..write(obj.likeCount)
      ..writeByte(4)
      ..write(obj.thumbnailUrl);
  }
}

/// Hive adapter for TopCommenter.
class TopCommenterAdapter extends TypeAdapter<TopCommenter> {
  @override
  final int typeId = 11;

  @override
  TopCommenter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return TopCommenter(
      authorName: fields[0] as String,
      commentCount: fields[1] as int,
      authorProfileImageUrl: fields[2] as String?,
      totalLikes: fields[3] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, TopCommenter obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.authorName)
      ..writeByte(1)
      ..write(obj.commentCount)
      ..writeByte(2)
      ..write(obj.authorProfileImageUrl)
      ..writeByte(3)
      ..write(obj.totalLikes);
  }
}

/// Hive adapter for EngagementDistribution.
class EngagementDistributionAdapter extends TypeAdapter<EngagementDistribution> {
  @override
  final int typeId = 12;

  @override
  EngagementDistribution read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return EngagementDistribution(
      totalViews: fields[0] as int? ?? 0,
      totalLikes: fields[1] as int? ?? 0,
      totalComments: fields[2] as int? ?? 0,
      totalReplies: fields[3] as int? ?? 0,
      hourlyCommentPattern: (fields[4] as Map?)?.cast<int, int>(),
      weekdayCommentPattern: (fields[5] as Map?)?.cast<int, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, EngagementDistribution obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.totalViews)
      ..writeByte(1)
      ..write(obj.totalLikes)
      ..writeByte(2)
      ..write(obj.totalComments)
      ..writeByte(3)
      ..write(obj.totalReplies)
      ..writeByte(4)
      ..write(obj.hourlyCommentPattern)
      ..writeByte(5)
      ..write(obj.weekdayCommentPattern);
  }
}

/// Hive adapter for AggregatedMetrics.
class AggregatedMetricsAdapter extends TypeAdapter<AggregatedMetrics> {
  @override
  final int typeId = 13;

  @override
  AggregatedMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return AggregatedMetrics(
      date: fields[0] as DateTime,
      periodType: fields[1] as PeriodType,
      totalComments: fields[2] as int? ?? 0,
      totalReplies: fields[3] as int? ?? 0,
      avgReplyTimeSeconds: fields[4] as double? ?? 0.0,
      sentimentScore: fields[5] as double? ?? 0.0,
      topVideos: (fields[6] as List?)?.cast<TopVideo>(),
      topCommenters: (fields[7] as List?)?.cast<TopCommenter>(),
      engagement: fields[8] as EngagementDistribution?,
      lastUpdated: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AggregatedMetrics obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.periodType)
      ..writeByte(2)
      ..write(obj.totalComments)
      ..writeByte(3)
      ..write(obj.totalReplies)
      ..writeByte(4)
      ..write(obj.avgReplyTimeSeconds)
      ..writeByte(5)
      ..write(obj.sentimentScore)
      ..writeByte(6)
      ..write(obj.topVideos)
      ..writeByte(7)
      ..write(obj.topCommenters)
      ..writeByte(8)
      ..write(obj.engagement)
      ..writeByte(9)
      ..write(obj.lastUpdated);
  }
}

/// Registers all analytics-related Hive adapters.
void registerAnalyticsAdapters() {
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(TopVideoAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(TopCommenterAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(EngagementDistributionAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(AggregatedMetricsAdapter());
  }
  if (!Hive.isAdapterRegistered(14)) {
    Hive.registerAdapter(PeriodTypeAdapter());
  }
}
