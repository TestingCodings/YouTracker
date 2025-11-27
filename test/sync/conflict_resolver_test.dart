import 'package:flutter_test/flutter_test.dart';
import 'package:you_tracker/models/models.dart';
import 'package:you_tracker/src/sync/conflict_resolver.dart';
import 'package:you_tracker/src/sync/hive_adapters.dart';

void main() {
  group('ConflictResolver', () {
    late ConflictResolver resolver;

    setUp(() {
      resolver = ConflictResolver();
    });

    group('resolveComment', () {
      test('should accept remote when local has not been modified', () {
        final local = _createComment(id: '1', text: 'Local text', likeCount: 5);
        final remote = _createComment(id: '1', text: 'Remote text', likeCount: 10);
        final localMeta = SyncableEntity(
          id: '1',
          lastSyncedAt: DateTime(2024, 1, 1),
          modifiedAfterLastSync: false,
        );
        final remoteMeta = SyncableEntity(
          id: '1',
          remoteUpdatedAt: DateTime(2024, 1, 2),
        );

        final result = resolver.resolveComment(
          local: local,
          remote: remote,
          localMeta: localMeta,
          remoteMeta: remoteMeta,
        );

        expect(result.resolvedEntity.text, 'Remote text');
        expect(result.resolvedEntity.likeCount, 10);
        expect(result.hadConflict, false);
      });

      test('should keep local when remote is not newer', () {
        final local = _createComment(id: '1', text: 'Local text', likeCount: 5);
        final remote = _createComment(id: '1', text: 'Remote text', likeCount: 10);
        final localMeta = SyncableEntity(
          id: '1',
          lastSyncedAt: DateTime(2024, 1, 3),
          modifiedAfterLastSync: true,
        );
        final remoteMeta = SyncableEntity(
          id: '1',
          remoteUpdatedAt: DateTime(2024, 1, 1),
        );

        final result = resolver.resolveComment(
          local: local,
          remote: remote,
          localMeta: localMeta,
          remoteMeta: remoteMeta,
        );

        expect(result.resolvedEntity.text, 'Local text');
        expect(result.resolvedEntity.likeCount, 5);
        expect(result.hadConflict, false);
      });

      test('should merge fields on conflict with fieldLevelMerge strategy', () {
        final local = _createComment(
          id: '1',
          text: 'User edited text',
          likeCount: 5,
          isBookmarked: true,
        );
        final remote = _createComment(
          id: '1',
          text: 'Original text',
          likeCount: 15,
        );
        final localMeta = SyncableEntity(
          id: '1',
          lastSyncedAt: DateTime(2024, 1, 1),
          modifiedAfterLastSync: true,
          localUpdatedAt: DateTime(2024, 1, 2),
        );
        final remoteMeta = SyncableEntity(
          id: '1',
          remoteUpdatedAt: DateTime(2024, 1, 3),
        );

        final result = resolver.resolveComment(
          local: local,
          remote: remote,
          localMeta: localMeta,
          remoteMeta: remoteMeta,
          strategy: ConflictResolutionStrategy.fieldLevelMerge,
        );

        // User's text edit should be preserved
        expect(result.resolvedEntity.text, 'User edited text');
        // Like count should use max
        expect(result.resolvedEntity.likeCount, 15);
        // Bookmark state should be preserved
        expect(result.resolvedEntity.isBookmarked, true);
        expect(result.hadConflict, true);
        expect(result.conflictedFields, contains('text'));
        expect(result.conflictedFields, contains('likeCount'));
      });

      test('should use remoteWins strategy when specified', () {
        final local = _createComment(id: '1', text: 'Local text');
        final remote = _createComment(id: '1', text: 'Remote text');
        final localMeta = SyncableEntity(
          id: '1',
          lastSyncedAt: DateTime(2024, 1, 1),
          modifiedAfterLastSync: true,
        );
        final remoteMeta = SyncableEntity(
          id: '1',
          remoteUpdatedAt: DateTime(2024, 1, 2),
        );

        final result = resolver.resolveComment(
          local: local,
          remote: remote,
          localMeta: localMeta,
          remoteMeta: remoteMeta,
          strategy: ConflictResolutionStrategy.remoteWins,
        );

        expect(result.resolvedEntity.text, 'Remote text');
        expect(result.hadConflict, true);
        expect(result.resolutionNotes, contains('remoteWins'));
      });

      test('should use localWins strategy when specified', () {
        final local = _createComment(id: '1', text: 'Local text');
        final remote = _createComment(id: '1', text: 'Remote text');
        final localMeta = SyncableEntity(
          id: '1',
          lastSyncedAt: DateTime(2024, 1, 1),
          modifiedAfterLastSync: true,
        );
        final remoteMeta = SyncableEntity(
          id: '1',
          remoteUpdatedAt: DateTime(2024, 1, 2),
        );

        final result = resolver.resolveComment(
          local: local,
          remote: remote,
          localMeta: localMeta,
          remoteMeta: remoteMeta,
          strategy: ConflictResolutionStrategy.localWins,
        );

        expect(result.resolvedEntity.text, 'Local text');
        expect(result.hadConflict, true);
        expect(result.resolutionNotes, contains('localWins'));
      });

      test('should use lastWriteWins strategy correctly', () {
        final local = _createComment(id: '1', text: 'Local text');
        final remote = _createComment(id: '1', text: 'Remote text');

        // Test when local is newer
        var localMeta = SyncableEntity(
          id: '1',
          lastSyncedAt: DateTime(2024, 1, 1),
          modifiedAfterLastSync: true,
          localUpdatedAt: DateTime(2024, 1, 5),
        );
        var remoteMeta = SyncableEntity(
          id: '1',
          remoteUpdatedAt: DateTime(2024, 1, 2),
        );

        var result = resolver.resolveComment(
          local: local,
          remote: remote,
          localMeta: localMeta,
          remoteMeta: remoteMeta,
          strategy: ConflictResolutionStrategy.lastWriteWins,
        );

        expect(result.resolvedEntity.text, 'Local text');

        // Test when remote is newer
        localMeta = SyncableEntity(
          id: '1',
          lastSyncedAt: DateTime(2024, 1, 1),
          modifiedAfterLastSync: true,
          localUpdatedAt: DateTime(2024, 1, 2),
        );
        remoteMeta = SyncableEntity(
          id: '1',
          remoteUpdatedAt: DateTime(2024, 1, 5),
        );

        result = resolver.resolveComment(
          local: local,
          remote: remote,
          localMeta: localMeta,
          remoteMeta: remoteMeta,
          strategy: ConflictResolutionStrategy.lastWriteWins,
        );

        expect(result.resolvedEntity.text, 'Remote text');
      });
    });

    group('resolveDeleteConflict', () {
      test('should apply tombstone when remote is deleted', () {
        final local = _createComment(id: '1', text: 'Local text');
        final localMeta = SyncableEntity(id: '1');
        final remoteMeta = SyncableEntity(id: '1', deleted: true);

        final result = resolver.resolveDeleteConflict(
          local: local,
          remote: null,
          localMeta: localMeta,
          remoteMeta: remoteMeta,
        );

        expect(result.resolvedEntity, isNull);
        expect(result.hadConflict, true);
        expect(result.resolutionNotes, contains('tombstone'));
      });

      test('should resurrect when remote is newer than local delete', () {
        final remote = _createComment(id: '1', text: 'Remote text');
        final localMeta = SyncableEntity(
          id: '1',
          deleted: true,
          localUpdatedAt: DateTime(2024, 1, 1),
        );
        final remoteMeta = SyncableEntity(
          id: '1',
          remoteUpdatedAt: DateTime(2024, 1, 5),
        );

        final result = resolver.resolveDeleteConflict(
          local: null,
          remote: remote,
          localMeta: localMeta,
          remoteMeta: remoteMeta,
        );

        expect(result.resolvedEntity, isNotNull);
        expect(result.resolvedEntity?.text, 'Remote text');
        expect(result.hadConflict, true);
        expect(result.resolutionNotes, contains('resurrected'));
      });
    });

    group('resolveInteraction', () {
      test('should merge read status correctly', () {
        final local = Interaction(
          id: '1',
          commentId: 'c1',
          type: InteractionType.like,
          timestamp: DateTime(2024, 1, 1),
          isRead: true,
        );
        final remote = Interaction(
          id: '1',
          commentId: 'c1',
          type: InteractionType.like,
          timestamp: DateTime(2024, 1, 1),
          isRead: false,
        );

        final result = resolver.resolveInteraction(
          local: local,
          remote: remote,
        );

        // If either is read, should be marked as read
        expect(result.resolvedEntity.isRead, true);
      });
    });

    group('resolveCommentBatch', () {
      test('should handle batch resolution correctly', () {
        final localComments = {
          '1': _createComment(id: '1', text: 'Local 1'),
          '2': _createComment(id: '2', text: 'Local 2'),
        };
        final remoteComments = {
          '1': _createComment(id: '1', text: 'Remote 1'),
          '3': _createComment(id: '3', text: 'Remote 3'),
        };
        final localMetadata = {
          '1': SyncableEntity(id: '1'),
          '2': SyncableEntity(id: '2'),
        };
        final remoteMetadata = {
          '1': SyncableEntity(id: '1'),
          '3': SyncableEntity(id: '3'),
        };

        final results = resolver.resolveCommentBatch(
          localComments: localComments,
          remoteComments: remoteComments,
          localMetadata: localMetadata,
          remoteMetadata: remoteMetadata,
        );

        expect(results.length, 3);
        
        // ID 1: Both exist
        final result1 = results.firstWhere((r) => r.resolvedEntity.id == '1');
        expect(result1.resolvedEntity, isNotNull);
        
        // ID 2: Local only
        final result2 = results.firstWhere((r) => r.resolvedEntity.id == '2');
        expect(result2.resolutionNotes, contains('pending'));
        
        // ID 3: Remote only
        final result3 = results.firstWhere((r) => r.resolvedEntity.id == '3');
        expect(result3.resolutionNotes, contains('remote'));
      });
    });
  });

  group('SyncableEntityConflictCheck', () {
    test('should detect conflict correctly', () {
      final local = SyncableEntity(
        id: '1',
        lastSyncedAt: DateTime(2024, 1, 1),
        modifiedAfterLastSync: true,
      );
      final remote = SyncableEntity(
        id: '1',
        remoteUpdatedAt: DateTime(2024, 1, 5),
      );

      expect(local.hasConflictWith(remote), true);
    });

    test('should not detect conflict when local not modified', () {
      final local = SyncableEntity(
        id: '1',
        lastSyncedAt: DateTime(2024, 1, 1),
        modifiedAfterLastSync: false,
      );
      final remote = SyncableEntity(
        id: '1',
        remoteUpdatedAt: DateTime(2024, 1, 5),
      );

      expect(local.hasConflictWith(remote), false);
    });
  });
}

Comment _createComment({
  required String id,
  String text = 'Test comment',
  int likeCount = 0,
  int replyCount = 0,
  bool isBookmarked = false,
}) {
  return Comment(
    id: id,
    videoId: 'v1',
    videoTitle: 'Test Video',
    videoThumbnailUrl: 'https://example.com/thumb.jpg',
    channelId: 'c1',
    channelName: 'Test Channel',
    text: text,
    publishedAt: DateTime(2024, 1, 1),
    likeCount: likeCount,
    replyCount: replyCount,
    isReply: false,
    authorName: 'Test Author',
    isBookmarked: isBookmarked,
  );
}
