// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommentAdapter extends TypeAdapter<Comment> {
  @override
  final int typeId = 0;

  @override
  Comment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Comment(
      id: fields[0] as String,
      videoId: fields[1] as String,
      videoTitle: fields[2] as String,
      videoThumbnailUrl: fields[3] as String,
      channelId: fields[4] as String,
      channelName: fields[5] as String,
      text: fields[6] as String,
      publishedAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime?,
      likeCount: fields[9] as int,
      replyCount: fields[10] as int,
      parentId: fields[11] as String?,
      isReply: fields[12] as bool,
      authorName: fields[13] as String,
      authorProfileImageUrl: fields[14] as String?,
      isBookmarked: fields[15] as bool,
      sentimentScore: fields[16] as double?,
      sentimentLabel: fields[17] as String?,
      toxicScore: fields[18] as double?,
      isToxic: fields[19] as bool?,
      needsReply: fields[20] as bool?,
      sentimentAnalyzedAt: fields[21] as DateTime?,
      sentimentProvider: fields[22] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Comment obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.videoId)
      ..writeByte(2)
      ..write(obj.videoTitle)
      ..writeByte(3)
      ..write(obj.videoThumbnailUrl)
      ..writeByte(4)
      ..write(obj.channelId)
      ..writeByte(5)
      ..write(obj.channelName)
      ..writeByte(6)
      ..write(obj.text)
      ..writeByte(7)
      ..write(obj.publishedAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.likeCount)
      ..writeByte(10)
      ..write(obj.replyCount)
      ..writeByte(11)
      ..write(obj.parentId)
      ..writeByte(12)
      ..write(obj.isReply)
      ..writeByte(13)
      ..write(obj.authorName)
      ..writeByte(14)
      ..write(obj.authorProfileImageUrl)
      ..writeByte(15)
      ..write(obj.isBookmarked)
      ..writeByte(16)
      ..write(obj.sentimentScore)
      ..writeByte(17)
      ..write(obj.sentimentLabel)
      ..writeByte(18)
      ..write(obj.toxicScore)
      ..writeByte(19)
      ..write(obj.isToxic)
      ..writeByte(20)
      ..write(obj.needsReply)
      ..writeByte(21)
      ..write(obj.sentimentAnalyzedAt)
      ..writeByte(22)
      ..write(obj.sentimentProvider);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
