// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChannelAdapter extends TypeAdapter<Channel> {
  @override
  final int typeId = 3;

  @override
  Channel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Channel(
      id: fields[0] as String,
      name: fields[1] as String,
      provider: fields[2] as String? ?? 'youtube',
      accessToken: fields[3] as String?,
      refreshToken: fields[4] as String?,
      avatarUrl: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      lastSyncedAt: fields[7] as DateTime?,
      isActive: fields[8] as bool? ?? false,
      tokenExpiresAt: fields[9] as DateTime?,
      email: fields[10] as String?,
      userId: fields[11] as String?,
      connectionState: fields[12] as ChannelConnectionState? ??
          ChannelConnectionState.disconnected,
      lastError: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Channel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.provider)
      ..writeByte(3)
      ..write(obj.accessToken)
      ..writeByte(4)
      ..write(obj.refreshToken)
      ..writeByte(5)
      ..write(obj.avatarUrl)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastSyncedAt)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.tokenExpiresAt)
      ..writeByte(10)
      ..write(obj.email)
      ..writeByte(11)
      ..write(obj.userId)
      ..writeByte(12)
      ..write(obj.connectionState)
      ..writeByte(13)
      ..write(obj.lastError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChannelConnectionStateAdapter extends TypeAdapter<ChannelConnectionState> {
  @override
  final int typeId = 4;

  @override
  ChannelConnectionState read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChannelConnectionState.disconnected;
      case 1:
        return ChannelConnectionState.connecting;
      case 2:
        return ChannelConnectionState.connected;
      case 3:
        return ChannelConnectionState.error;
      case 4:
        return ChannelConnectionState.tokenExpired;
      default:
        return ChannelConnectionState.disconnected;
    }
  }

  @override
  void write(BinaryWriter writer, ChannelConnectionState obj) {
    switch (obj) {
      case ChannelConnectionState.disconnected:
        writer.writeByte(0);
        break;
      case ChannelConnectionState.connecting:
        writer.writeByte(1);
        break;
      case ChannelConnectionState.connected:
        writer.writeByte(2);
        break;
      case ChannelConnectionState.error:
        writer.writeByte(3);
        break;
      case ChannelConnectionState.tokenExpired:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelConnectionStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
