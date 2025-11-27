import 'package:flutter_test/flutter_test.dart';
import 'package:you_tracker/src/sync/sync_queue.dart';
import 'package:you_tracker/src/sync/hive_adapters.dart';

void main() {
  group('SyncQueueConfig', () {
    test('should calculate exponential backoff correctly', () {
      const config = SyncQueueConfig(
        backoffBaseSeconds: 2,
        maxBackoffSeconds: 300,
        jitterFactor: 0.0, // No jitter for predictable testing
      );

      // First attempt: 2^0 * 2 = 2 seconds
      expect(config.getDelayForAttempt(0).inSeconds, 2);

      // Second attempt: 2^1 * 2 = 4 seconds
      expect(config.getDelayForAttempt(1).inSeconds, 4);

      // Third attempt: 2^2 * 2 = 8 seconds
      expect(config.getDelayForAttempt(2).inSeconds, 8);
    });

    test('should cap delay at maxBackoffSeconds', () {
      const config = SyncQueueConfig(
        backoffBaseSeconds: 2,
        maxBackoffSeconds: 10,
        jitterFactor: 0.0,
      );

      // 10th attempt would be 2^10 * 2 = 2048, but should be capped at 10
      expect(config.getDelayForAttempt(10).inSeconds, 10);
    });

    test('should apply jitter correctly', () {
      const config = SyncQueueConfig(
        backoffBaseSeconds: 4,
        maxBackoffSeconds: 300,
        jitterFactor: 0.25,
      );

      // With 25% jitter, delay should be within ±12.5% of base
      final delays = List.generate(100, (_) => config.getDelayForAttempt(0));
      final baseDelay = 4;
      final minExpected = baseDelay * 0.875; // 4 - 12.5%
      final maxExpected = baseDelay * 1.125; // 4 + 12.5%

      for (final delay in delays) {
        expect(
          delay.inSeconds,
          inInclusiveRange(minExpected.floor(), maxExpected.ceil()),
        );
      }
    });

    test('should use default values correctly', () {
      const config = SyncQueueConfig();

      expect(config.maxRetryAttempts, 5);
      expect(config.backoffBaseSeconds, 2);
      expect(config.maxBackoffSeconds, 300);
      expect(config.maxConcurrentOperations, 3);
      expect(config.autoProcess, true);
    });
  });

  group('SyncOperation', () {
    test('should create with required fields', () {
      final op = SyncOperation(
        id: 'op1',
        opType: SyncOperationType.create,
        entityType: SyncEntityType.comment,
        entityId: 'entity1',
      );

      expect(op.id, 'op1');
      expect(op.opType, SyncOperationType.create);
      expect(op.entityType, SyncEntityType.comment);
      expect(op.entityId, 'entity1');
      expect(op.status, SyncOperationStatus.pending);
      expect(op.attempts, 0);
    });

    test('should serialize to JSON correctly', () {
      final op = SyncOperation(
        id: 'op1',
        opType: SyncOperationType.update,
        entityType: SyncEntityType.comment,
        entityId: 'entity1',
        payload: {'text': 'Updated text'},
        attempts: 2,
        lastError: 'Network error',
        status: SyncOperationStatus.failed,
        createdAt: DateTime(2024, 1, 1, 12, 0),
        priority: 5,
      );

      final json = op.toJson();

      expect(json['id'], 'op1');
      expect(json['opType'], 'update');
      expect(json['entityType'], 'comment');
      expect(json['entityId'], 'entity1');
      expect(json['payload'], {'text': 'Updated text'});
      expect(json['attempts'], 2);
      expect(json['lastError'], 'Network error');
      expect(json['status'], 'failed');
      expect(json['priority'], 5);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'op1',
        'opType': 'delete',
        'entityType': 'interaction',
        'entityId': 'entity1',
        'attempts': 3,
        'status': 'deadLetter',
        'createdAt': '2024-01-01T12:00:00.000',
        'priority': 10,
      };

      final op = SyncOperation.fromJson(json);

      expect(op.id, 'op1');
      expect(op.opType, SyncOperationType.delete);
      expect(op.entityType, SyncEntityType.interaction);
      expect(op.entityId, 'entity1');
      expect(op.attempts, 3);
      expect(op.status, SyncOperationStatus.deadLetter);
      expect(op.priority, 10);
    });

    test('should copy with modifications correctly', () {
      final original = SyncOperation(
        id: 'op1',
        opType: SyncOperationType.create,
        entityType: SyncEntityType.comment,
        entityId: 'entity1',
        status: SyncOperationStatus.pending,
      );

      final modified = original.copyWith(
        status: SyncOperationStatus.completed,
        attempts: 1,
        completedAt: DateTime(2024, 1, 2),
      );

      expect(modified.id, 'op1');
      expect(modified.status, SyncOperationStatus.completed);
      expect(modified.attempts, 1);
      expect(modified.completedAt, DateTime(2024, 1, 2));
      expect(original.status, SyncOperationStatus.pending);
    });
  });

  group('SyncMetadata', () {
    test('should create with required fields', () {
      final metadata = SyncMetadata(key: 'global');

      expect(metadata.key, 'global');
      expect(metadata.syncCount, 0);
      expect(metadata.failedSyncCount, 0);
      expect(metadata.migrationCompleted, false);
    });

    test('should serialize to JSON correctly', () {
      final metadata = SyncMetadata(
        key: 'global',
        lastSyncToken: 'token123',
        lastFullSyncTime: DateTime(2024, 1, 1),
        syncCount: 10,
        itemsSynced: 100,
        schemaVersion: 2,
        migrationCompleted: true,
      );

      final json = metadata.toJson();

      expect(json['key'], 'global');
      expect(json['lastSyncToken'], 'token123');
      expect(json['syncCount'], 10);
      expect(json['itemsSynced'], 100);
      expect(json['schemaVersion'], 2);
      expect(json['migrationCompleted'], true);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'key': 'comments',
        'lastSyncToken': 'abc123',
        'lastFullSyncTime': '2024-01-01T00:00:00.000',
        'syncCount': 5,
        'failedSyncCount': 1,
        'schemaVersion': 1,
        'migrationCompleted': true,
      };

      final metadata = SyncMetadata.fromJson(json);

      expect(metadata.key, 'comments');
      expect(metadata.lastSyncToken, 'abc123');
      expect(metadata.syncCount, 5);
      expect(metadata.failedSyncCount, 1);
      expect(metadata.migrationCompleted, true);
    });

    test('should copy with modifications correctly', () {
      final original = SyncMetadata(
        key: 'global',
        syncCount: 5,
      );

      final modified = original.copyWith(
        syncCount: 6,
        lastIncrementalSyncTime: DateTime(2024, 1, 1),
      );

      expect(modified.key, 'global');
      expect(modified.syncCount, 6);
      expect(modified.lastIncrementalSyncTime, DateTime(2024, 1, 1));
      expect(original.syncCount, 5);
    });
  });

  group('SyncableEntity', () {
    test('should create with required fields', () {
      final entity = SyncableEntity(id: 'entity1');

      expect(entity.id, 'entity1');
      expect(entity.version, 1);
      expect(entity.deleted, false);
      expect(entity.modifiedAfterLastSync, false);
    });

    test('should serialize to JSON correctly', () {
      final entity = SyncableEntity(
        id: 'entity1',
        etag: 'etag123',
        localUpdatedAt: DateTime(2024, 1, 1),
        remoteUpdatedAt: DateTime(2024, 1, 2),
        version: 3,
        deleted: false,
        modifiedAfterLastSync: true,
      );

      final json = entity.toJson();

      expect(json['id'], 'entity1');
      expect(json['etag'], 'etag123');
      expect(json['version'], 3);
      expect(json['deleted'], false);
      expect(json['modifiedAfterLastSync'], true);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'entity1',
        'etag': 'etag123',
        'localUpdatedAt': '2024-01-01T00:00:00.000',
        'version': 5,
        'deleted': true,
      };

      final entity = SyncableEntity.fromJson(json);

      expect(entity.id, 'entity1');
      expect(entity.etag, 'etag123');
      expect(entity.version, 5);
      expect(entity.deleted, true);
    });
  });

  group('SyncQueueStatus', () {
    test('should calculate totals correctly', () {
      const status = SyncQueueStatus(
        pendingCount: 5,
        processingCount: 2,
        completedCount: 10,
        failedCount: 1,
        deadLetterCount: 0,
      );

      expect(status.totalCount, 18);
      expect(status.isEmpty, false);
      expect(status.hasErrors, true);
    });

    test('should detect empty queue', () {
      const status = SyncQueueStatus();

      expect(status.isEmpty, true);
      expect(status.hasErrors, false);
    });

    test('should detect errors correctly', () {
      const statusWithFailed = SyncQueueStatus(failedCount: 1);
      expect(statusWithFailed.hasErrors, true);

      const statusWithDeadLetter = SyncQueueStatus(deadLetterCount: 1);
      expect(statusWithDeadLetter.hasErrors, true);

      const statusClean = SyncQueueStatus(pendingCount: 5);
      expect(statusClean.hasErrors, false);
    });
  });

  group('SyncOperationResult', () {
    test('should create success result correctly', () {
      final op = SyncOperation(
        id: 'op1',
        opType: SyncOperationType.create,
        entityType: SyncEntityType.comment,
        entityId: 'entity1',
      );

      final result = SyncOperationResult(
        operation: op,
        success: true,
        response: {'id': 'newId'},
      );

      expect(result.success, true);
      expect(result.error, isNull);
      expect(result.response, {'id': 'newId'});
    });

    test('should create failure result correctly', () {
      final op = SyncOperation(
        id: 'op1',
        opType: SyncOperationType.update,
        entityType: SyncEntityType.comment,
        entityId: 'entity1',
      );

      final result = SyncOperationResult(
        operation: op,
        success: false,
        error: 'Network timeout',
      );

      expect(result.success, false);
      expect(result.error, 'Network timeout');
      expect(result.response, isNull);
    });
  });
}
