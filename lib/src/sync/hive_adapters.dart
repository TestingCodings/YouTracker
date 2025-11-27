import 'package:hive/hive.dart';

part 'hive_adapters.g.dart';

/// Represents the type of sync operation.
@HiveType(typeId: 10)
enum SyncOperationType {
  @HiveField(0)
  create,

  @HiveField(1)
  update,

  @HiveField(2)
  delete,
}

/// Represents the status of a sync operation.
@HiveType(typeId: 11)
enum SyncOperationStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  inProgress,

  @HiveField(2)
  completed,

  @HiveField(3)
  failed,

  @HiveField(4)
  cancelled,

  @HiveField(5)
  deadLetter,
}

/// Represents the type of entity being synced.
@HiveType(typeId: 12)
enum SyncEntityType {
  @HiveField(0)
  comment,

  @HiveField(1)
  interaction,

  @HiveField(2)
  like,

  @HiveField(3)
  reply,
}

/// Represents a sync operation in the queue.
@HiveType(typeId: 13)
class SyncOperation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final SyncOperationType opType;

  @HiveField(2)
  final SyncEntityType entityType;

  @HiveField(3)
  final String entityId;

  @HiveField(4)
  final Map<String, dynamic>? payload;

  @HiveField(5)
  int attempts;

  @HiveField(6)
  DateTime? nextAttemptAt;

  @HiveField(7)
  String? lastError;

  @HiveField(8)
  SyncOperationStatus status;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  DateTime? completedAt;

  @HiveField(11)
  final int priority;

  SyncOperation({
    required this.id,
    required this.opType,
    required this.entityType,
    required this.entityId,
    this.payload,
    this.attempts = 0,
    this.nextAttemptAt,
    this.lastError,
    this.status = SyncOperationStatus.pending,
    DateTime? createdAt,
    this.completedAt,
    this.priority = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  SyncOperation copyWith({
    String? id,
    SyncOperationType? opType,
    SyncEntityType? entityType,
    String? entityId,
    Map<String, dynamic>? payload,
    int? attempts,
    DateTime? nextAttemptAt,
    String? lastError,
    SyncOperationStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    int? priority,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      opType: opType ?? this.opType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'opType': opType.name,
      'entityType': entityType.name,
      'entityId': entityId,
      'payload': payload,
      'attempts': attempts,
      'nextAttemptAt': nextAttemptAt?.toIso8601String(),
      'lastError': lastError,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority,
    };
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      opType: SyncOperationType.values.firstWhere(
        (e) => e.name == json['opType'],
      ),
      entityType: SyncEntityType.values.firstWhere(
        (e) => e.name == json['entityType'],
      ),
      entityId: json['entityId'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
      attempts: json['attempts'] as int? ?? 0,
      nextAttemptAt: json['nextAttemptAt'] != null
          ? DateTime.parse(json['nextAttemptAt'] as String)
          : null,
      lastError: json['lastError'] as String?,
      status: SyncOperationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SyncOperationStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      priority: json['priority'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'SyncOperation(id: $id, opType: $opType, entityType: $entityType, status: $status)';
  }
}

/// Metadata for sync state tracking.
@HiveType(typeId: 14)
class SyncMetadata extends HiveObject {
  @HiveField(0)
  final String key;

  @HiveField(1)
  String? lastSyncToken;

  @HiveField(2)
  DateTime? lastFullSyncTime;

  @HiveField(3)
  DateTime? lastIncrementalSyncTime;

  @HiveField(4)
  String? etag;

  @HiveField(5)
  int syncCount;

  @HiveField(6)
  int failedSyncCount;

  @HiveField(7)
  int itemsSynced;

  @HiveField(8)
  String? lastError;

  @HiveField(9)
  DateTime? lastErrorTime;

  @HiveField(10)
  int schemaVersion;

  @HiveField(11)
  bool migrationCompleted;

  SyncMetadata({
    required this.key,
    this.lastSyncToken,
    this.lastFullSyncTime,
    this.lastIncrementalSyncTime,
    this.etag,
    this.syncCount = 0,
    this.failedSyncCount = 0,
    this.itemsSynced = 0,
    this.lastError,
    this.lastErrorTime,
    this.schemaVersion = 1,
    this.migrationCompleted = false,
  });

  SyncMetadata copyWith({
    String? key,
    String? lastSyncToken,
    DateTime? lastFullSyncTime,
    DateTime? lastIncrementalSyncTime,
    String? etag,
    int? syncCount,
    int? failedSyncCount,
    int? itemsSynced,
    String? lastError,
    DateTime? lastErrorTime,
    int? schemaVersion,
    bool? migrationCompleted,
  }) {
    return SyncMetadata(
      key: key ?? this.key,
      lastSyncToken: lastSyncToken ?? this.lastSyncToken,
      lastFullSyncTime: lastFullSyncTime ?? this.lastFullSyncTime,
      lastIncrementalSyncTime:
          lastIncrementalSyncTime ?? this.lastIncrementalSyncTime,
      etag: etag ?? this.etag,
      syncCount: syncCount ?? this.syncCount,
      failedSyncCount: failedSyncCount ?? this.failedSyncCount,
      itemsSynced: itemsSynced ?? this.itemsSynced,
      lastError: lastError ?? this.lastError,
      lastErrorTime: lastErrorTime ?? this.lastErrorTime,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      migrationCompleted: migrationCompleted ?? this.migrationCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'lastSyncToken': lastSyncToken,
      'lastFullSyncTime': lastFullSyncTime?.toIso8601String(),
      'lastIncrementalSyncTime': lastIncrementalSyncTime?.toIso8601String(),
      'etag': etag,
      'syncCount': syncCount,
      'failedSyncCount': failedSyncCount,
      'itemsSynced': itemsSynced,
      'lastError': lastError,
      'lastErrorTime': lastErrorTime?.toIso8601String(),
      'schemaVersion': schemaVersion,
      'migrationCompleted': migrationCompleted,
    };
  }

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      key: json['key'] as String,
      lastSyncToken: json['lastSyncToken'] as String?,
      lastFullSyncTime: json['lastFullSyncTime'] != null
          ? DateTime.parse(json['lastFullSyncTime'] as String)
          : null,
      lastIncrementalSyncTime: json['lastIncrementalSyncTime'] != null
          ? DateTime.parse(json['lastIncrementalSyncTime'] as String)
          : null,
      etag: json['etag'] as String?,
      syncCount: json['syncCount'] as int? ?? 0,
      failedSyncCount: json['failedSyncCount'] as int? ?? 0,
      itemsSynced: json['itemsSynced'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      lastErrorTime: json['lastErrorTime'] != null
          ? DateTime.parse(json['lastErrorTime'] as String)
          : null,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      migrationCompleted: json['migrationCompleted'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'SyncMetadata(key: $key, lastSyncToken: $lastSyncToken, syncCount: $syncCount)';
  }
}

/// Entity with sync metadata for conflict resolution.
@HiveType(typeId: 15)
class SyncableEntity extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String? etag;

  @HiveField(2)
  DateTime? localUpdatedAt;

  @HiveField(3)
  DateTime? remoteUpdatedAt;

  @HiveField(4)
  DateTime? lastSyncedAt;

  @HiveField(5)
  int version;

  @HiveField(6)
  bool deleted;

  @HiveField(7)
  bool modifiedAfterLastSync;

  @HiveField(8)
  Map<String, dynamic>? conflictData;

  SyncableEntity({
    required this.id,
    this.etag,
    this.localUpdatedAt,
    this.remoteUpdatedAt,
    this.lastSyncedAt,
    this.version = 1,
    this.deleted = false,
    this.modifiedAfterLastSync = false,
    this.conflictData,
  });

  SyncableEntity copyWith({
    String? id,
    String? etag,
    DateTime? localUpdatedAt,
    DateTime? remoteUpdatedAt,
    DateTime? lastSyncedAt,
    int? version,
    bool? deleted,
    bool? modifiedAfterLastSync,
    Map<String, dynamic>? conflictData,
  }) {
    return SyncableEntity(
      id: id ?? this.id,
      etag: etag ?? this.etag,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      version: version ?? this.version,
      deleted: deleted ?? this.deleted,
      modifiedAfterLastSync:
          modifiedAfterLastSync ?? this.modifiedAfterLastSync,
      conflictData: conflictData ?? this.conflictData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'etag': etag,
      'localUpdatedAt': localUpdatedAt?.toIso8601String(),
      'remoteUpdatedAt': remoteUpdatedAt?.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'version': version,
      'deleted': deleted,
      'modifiedAfterLastSync': modifiedAfterLastSync,
      'conflictData': conflictData,
    };
  }

  factory SyncableEntity.fromJson(Map<String, dynamic> json) {
    return SyncableEntity(
      id: json['id'] as String,
      etag: json['etag'] as String?,
      localUpdatedAt: json['localUpdatedAt'] != null
          ? DateTime.parse(json['localUpdatedAt'] as String)
          : null,
      remoteUpdatedAt: json['remoteUpdatedAt'] != null
          ? DateTime.parse(json['remoteUpdatedAt'] as String)
          : null,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      version: json['version'] as int? ?? 1,
      deleted: json['deleted'] as bool? ?? false,
      modifiedAfterLastSync: json['modifiedAfterLastSync'] as bool? ?? false,
      conflictData: json['conflictData'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'SyncableEntity(id: $id, version: $version, deleted: $deleted)';
  }
}
