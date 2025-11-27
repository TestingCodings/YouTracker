// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncOperationTypeAdapter extends TypeAdapter<SyncOperationType> {
  @override
  final int typeId = 10;

  @override
  SyncOperationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncOperationType.create;
      case 1:
        return SyncOperationType.update;
      case 2:
        return SyncOperationType.delete;
      default:
        return SyncOperationType.create;
    }
  }

  @override
  void write(BinaryWriter writer, SyncOperationType obj) {
    switch (obj) {
      case SyncOperationType.create:
        writer.writeByte(0);
      case SyncOperationType.update:
        writer.writeByte(1);
      case SyncOperationType.delete:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncOperationStatusAdapter extends TypeAdapter<SyncOperationStatus> {
  @override
  final int typeId = 11;

  @override
  SyncOperationStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncOperationStatus.pending;
      case 1:
        return SyncOperationStatus.inProgress;
      case 2:
        return SyncOperationStatus.completed;
      case 3:
        return SyncOperationStatus.failed;
      case 4:
        return SyncOperationStatus.cancelled;
      case 5:
        return SyncOperationStatus.deadLetter;
      default:
        return SyncOperationStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SyncOperationStatus obj) {
    switch (obj) {
      case SyncOperationStatus.pending:
        writer.writeByte(0);
      case SyncOperationStatus.inProgress:
        writer.writeByte(1);
      case SyncOperationStatus.completed:
        writer.writeByte(2);
      case SyncOperationStatus.failed:
        writer.writeByte(3);
      case SyncOperationStatus.cancelled:
        writer.writeByte(4);
      case SyncOperationStatus.deadLetter:
        writer.writeByte(5);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncEntityTypeAdapter extends TypeAdapter<SyncEntityType> {
  @override
  final int typeId = 12;

  @override
  SyncEntityType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncEntityType.comment;
      case 1:
        return SyncEntityType.interaction;
      case 2:
        return SyncEntityType.like;
      case 3:
        return SyncEntityType.reply;
      default:
        return SyncEntityType.comment;
    }
  }

  @override
  void write(BinaryWriter writer, SyncEntityType obj) {
    switch (obj) {
      case SyncEntityType.comment:
        writer.writeByte(0);
      case SyncEntityType.interaction:
        writer.writeByte(1);
      case SyncEntityType.like:
        writer.writeByte(2);
      case SyncEntityType.reply:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncEntityTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncOperationAdapter extends TypeAdapter<SyncOperation> {
  @override
  final int typeId = 13;

  @override
  SyncOperation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncOperation(
      id: fields[0] as String,
      opType: fields[1] as SyncOperationType,
      entityType: fields[2] as SyncEntityType,
      entityId: fields[3] as String,
      payload: (fields[4] as Map?)?.cast<String, dynamic>(),
      attempts: fields[5] as int,
      nextAttemptAt: fields[6] as DateTime?,
      lastError: fields[7] as String?,
      status: fields[8] as SyncOperationStatus,
      createdAt: fields[9] as DateTime,
      completedAt: fields[10] as DateTime?,
      priority: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SyncOperation obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.opType)
      ..writeByte(2)
      ..write(obj.entityType)
      ..writeByte(3)
      ..write(obj.entityId)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.attempts)
      ..writeByte(6)
      ..write(obj.nextAttemptAt)
      ..writeByte(7)
      ..write(obj.lastError)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.completedAt)
      ..writeByte(11)
      ..write(obj.priority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncMetadataAdapter extends TypeAdapter<SyncMetadata> {
  @override
  final int typeId = 14;

  @override
  SyncMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncMetadata(
      key: fields[0] as String,
      lastSyncToken: fields[1] as String?,
      lastFullSyncTime: fields[2] as DateTime?,
      lastIncrementalSyncTime: fields[3] as DateTime?,
      etag: fields[4] as String?,
      syncCount: fields[5] as int,
      failedSyncCount: fields[6] as int,
      itemsSynced: fields[7] as int,
      lastError: fields[8] as String?,
      lastErrorTime: fields[9] as DateTime?,
      schemaVersion: fields[10] as int,
      migrationCompleted: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SyncMetadata obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.lastSyncToken)
      ..writeByte(2)
      ..write(obj.lastFullSyncTime)
      ..writeByte(3)
      ..write(obj.lastIncrementalSyncTime)
      ..writeByte(4)
      ..write(obj.etag)
      ..writeByte(5)
      ..write(obj.syncCount)
      ..writeByte(6)
      ..write(obj.failedSyncCount)
      ..writeByte(7)
      ..write(obj.itemsSynced)
      ..writeByte(8)
      ..write(obj.lastError)
      ..writeByte(9)
      ..write(obj.lastErrorTime)
      ..writeByte(10)
      ..write(obj.schemaVersion)
      ..writeByte(11)
      ..write(obj.migrationCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncableEntityAdapter extends TypeAdapter<SyncableEntity> {
  @override
  final int typeId = 15;

  @override
  SyncableEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncableEntity(
      id: fields[0] as String,
      etag: fields[1] as String?,
      localUpdatedAt: fields[2] as DateTime?,
      remoteUpdatedAt: fields[3] as DateTime?,
      lastSyncedAt: fields[4] as DateTime?,
      version: fields[5] as int,
      deleted: fields[6] as bool,
      modifiedAfterLastSync: fields[7] as bool,
      conflictData: (fields[8] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, SyncableEntity obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.etag)
      ..writeByte(2)
      ..write(obj.localUpdatedAt)
      ..writeByte(3)
      ..write(obj.remoteUpdatedAt)
      ..writeByte(4)
      ..write(obj.lastSyncedAt)
      ..writeByte(5)
      ..write(obj.version)
      ..writeByte(6)
      ..write(obj.deleted)
      ..writeByte(7)
      ..write(obj.modifiedAfterLastSync)
      ..writeByte(8)
      ..write(obj.conflictData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncableEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
