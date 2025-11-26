// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InteractionTypeAdapter extends TypeAdapter<InteractionType> {
  @override
  final int typeId = 1;

  @override
  InteractionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InteractionType.like;
      case 1:
        return InteractionType.reply;
      case 2:
        return InteractionType.mention;
      case 3:
        return InteractionType.heart;
      default:
        return InteractionType.like;
    }
  }

  @override
  void write(BinaryWriter writer, InteractionType obj) {
    switch (obj) {
      case InteractionType.like:
        writer.writeByte(0);
        break;
      case InteractionType.reply:
        writer.writeByte(1);
        break;
      case InteractionType.mention:
        writer.writeByte(2);
        break;
      case InteractionType.heart:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InteractionAdapter extends TypeAdapter<Interaction> {
  @override
  final int typeId = 2;

  @override
  Interaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Interaction(
      id: fields[0] as String,
      commentId: fields[1] as String,
      type: fields[2] as InteractionType,
      fromUserId: fields[3] as String?,
      fromUserName: fields[4] as String?,
      fromUserProfileImageUrl: fields[5] as String?,
      timestamp: fields[6] as DateTime,
      replyText: fields[7] as String?,
      isRead: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Interaction obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.commentId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.fromUserId)
      ..writeByte(4)
      ..write(obj.fromUserName)
      ..writeByte(5)
      ..write(obj.fromUserProfileImageUrl)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.replyText)
      ..writeByte(8)
      ..write(obj.isRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
