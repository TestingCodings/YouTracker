import 'dart:math';

import '../../models/models.dart';
import 'hive_adapters.dart';

/// Strategy for resolving conflicts between local and remote data.
enum ConflictResolutionStrategy {
  /// Remote data always wins.
  remoteWins,

  /// Local data always wins.
  localWins,

  /// Most recently updated data wins.
  lastWriteWins,

  /// Merge fields intelligently based on timestamps.
  fieldLevelMerge,

  /// User decides manually (for interactive resolution).
  manual,
}

/// Result of a conflict resolution operation.
class ConflictResolutionResult<T> {
  final T resolvedEntity;
  final bool hadConflict;
  final List<String> conflictedFields;
  final String? resolutionNotes;

  const ConflictResolutionResult({
    required this.resolvedEntity,
    this.hadConflict = false,
    this.conflictedFields = const [],
    this.resolutionNotes,
  });
}

/// Conflict resolver for sync operations.
/// Provides pluggable conflict resolution strategies for entities.
class ConflictResolver {
  final ConflictResolutionStrategy defaultStrategy;

  ConflictResolver({
    this.defaultStrategy = ConflictResolutionStrategy.fieldLevelMerge,
  });

  /// Resolves conflicts between local and remote Comment entities.
  ConflictResolutionResult<Comment> resolveComment({
    required Comment local,
    required Comment remote,
    required SyncableEntity localMeta,
    required SyncableEntity remoteMeta,
    ConflictResolutionStrategy? strategy,
  }) {
    final effectiveStrategy = strategy ?? defaultStrategy;

    // No conflict if remote is newer and local hasn't been modified
    if (!localMeta.modifiedAfterLastSync) {
      return ConflictResolutionResult(
        resolvedEntity: remote,
        hadConflict: false,
      );
    }

    // Check if there's actually a conflict
    final remoteIsNewer = remoteMeta.remoteUpdatedAt != null &&
        localMeta.lastSyncedAt != null &&
        remoteMeta.remoteUpdatedAt!.isAfter(localMeta.lastSyncedAt!);

    if (!remoteIsNewer) {
      // Local is newer, keep local
      return ConflictResolutionResult(
        resolvedEntity: local,
        hadConflict: false,
      );
    }

    // We have a real conflict - both sides changed
    switch (effectiveStrategy) {
      case ConflictResolutionStrategy.remoteWins:
        return ConflictResolutionResult(
          resolvedEntity: remote,
          hadConflict: true,
          resolutionNotes: 'Remote data accepted (remoteWins strategy)',
        );

      case ConflictResolutionStrategy.localWins:
        return ConflictResolutionResult(
          resolvedEntity: local,
          hadConflict: true,
          resolutionNotes: 'Local data preserved (localWins strategy)',
        );

      case ConflictResolutionStrategy.lastWriteWins:
        final localTime = localMeta.localUpdatedAt ?? DateTime(1970);
        final remoteTime = remoteMeta.remoteUpdatedAt ?? DateTime(1970);
        final winner = localTime.isAfter(remoteTime) ? local : remote;
        return ConflictResolutionResult(
          resolvedEntity: winner,
          hadConflict: true,
          resolutionNotes:
              '${winner == local ? "Local" : "Remote"} data chosen (lastWriteWins)',
        );

      case ConflictResolutionStrategy.fieldLevelMerge:
        return _mergeCommentFields(local, remote, localMeta, remoteMeta);

      case ConflictResolutionStrategy.manual:
        // For manual resolution, return remote with conflict info
        return ConflictResolutionResult(
          resolvedEntity: remote.copyWith(
            isBookmarked: local.isBookmarked, // Preserve local-only state
          ),
          hadConflict: true,
          conflictedFields: _detectConflictedCommentFields(local, remote),
          resolutionNotes: 'Manual resolution required',
        );
    }
  }

  /// Merges Comment fields at field level.
  ConflictResolutionResult<Comment> _mergeCommentFields(
    Comment local,
    Comment remote,
    SyncableEntity localMeta,
    SyncableEntity remoteMeta,
  ) {
    final conflictedFields = <String>[];

    // Text: User's local edits have priority (last-write-wins with local priority)
    String text = remote.text;
    if (local.text != remote.text && localMeta.modifiedAfterLastSync) {
      text = local.text; // Prefer user's edit
      conflictedFields.add('text');
    }

    // Like count: Use max of both (or additive if we tracked deltas)
    int likeCount = max(local.likeCount, remote.likeCount);
    if (local.likeCount != remote.likeCount) {
      conflictedFields.add('likeCount');
    }

    // Reply count: Use remote as it's authoritative
    int replyCount = remote.replyCount;
    if (local.replyCount != remote.replyCount) {
      conflictedFields.add('replyCount');
    }

    // Updated at: Use the most recent
    DateTime? updatedAt = remote.updatedAt;
    if (local.updatedAt != null &&
        (updatedAt == null || local.updatedAt!.isAfter(updatedAt))) {
      updatedAt = local.updatedAt;
    }

    // Bookmark is local-only state, always preserve
    bool isBookmarked = local.isBookmarked;

    final merged = Comment(
      id: remote.id,
      videoId: remote.videoId,
      videoTitle: remote.videoTitle,
      videoThumbnailUrl: remote.videoThumbnailUrl,
      channelId: remote.channelId,
      channelName: remote.channelName,
      text: text,
      publishedAt: remote.publishedAt,
      updatedAt: updatedAt,
      likeCount: likeCount,
      replyCount: replyCount,
      parentId: remote.parentId,
      isReply: remote.isReply,
      authorName: remote.authorName,
      authorProfileImageUrl: remote.authorProfileImageUrl,
      isBookmarked: isBookmarked,
    );

    return ConflictResolutionResult(
      resolvedEntity: merged,
      hadConflict: conflictedFields.isNotEmpty,
      conflictedFields: conflictedFields,
      resolutionNotes: conflictedFields.isNotEmpty
          ? 'Merged fields: ${conflictedFields.join(", ")}'
          : null,
    );
  }

  /// Detects which fields are in conflict between local and remote.
  List<String> _detectConflictedCommentFields(Comment local, Comment remote) {
    final fields = <String>[];

    if (local.text != remote.text) fields.add('text');
    if (local.likeCount != remote.likeCount) fields.add('likeCount');
    if (local.replyCount != remote.replyCount) fields.add('replyCount');
    if (local.updatedAt != remote.updatedAt) fields.add('updatedAt');
    if (local.authorName != remote.authorName) fields.add('authorName');
    if (local.authorProfileImageUrl != remote.authorProfileImageUrl) {
      fields.add('authorProfileImageUrl');
    }

    return fields;
  }

  /// Resolves deletion conflicts (tombstone handling).
  ConflictResolutionResult<Comment?> resolveDeleteConflict({
    required Comment? local,
    required Comment? remote,
    required SyncableEntity localMeta,
    required SyncableEntity? remoteMeta,
  }) {
    // If remote is deleted (tombstone), only resurrect via explicit remote create
    if (remoteMeta?.deleted == true && remote == null) {
      // Remote deleted - accept deletion even if we have local
      return const ConflictResolutionResult(
        resolvedEntity: null,
        hadConflict: true,
        resolutionNotes: 'Entity deleted remotely (tombstone applied)',
      );
    }

    // If local is deleted but remote exists and is newer
    if (localMeta.deleted && remote != null) {
      final remoteTime = remoteMeta?.remoteUpdatedAt ?? DateTime(1970);
      final localDeleteTime = localMeta.localUpdatedAt ?? DateTime(1970);

      if (remoteTime.isAfter(localDeleteTime)) {
        // Remote was updated after local delete - resurrect
        return ConflictResolutionResult(
          resolvedEntity: remote,
          hadConflict: true,
          resolutionNotes: 'Entity resurrected from remote (newer than local delete)',
        );
      }
    }

    // Return local state (or null if deleted)
    return ConflictResolutionResult(
      resolvedEntity: localMeta.deleted ? null : local,
      hadConflict: false,
    );
  }

  /// Resolves conflicts for Interaction entities.
  ConflictResolutionResult<Interaction> resolveInteraction({
    required Interaction local,
    required Interaction remote,
    ConflictResolutionStrategy? strategy,
  }) {
    final effectiveStrategy = strategy ?? defaultStrategy;

    // Interactions are mostly immutable, prefer remote for consistency
    if (effectiveStrategy == ConflictResolutionStrategy.localWins) {
      return ConflictResolutionResult(
        resolvedEntity: local,
        hadConflict: local.id == remote.id && local.timestamp != remote.timestamp,
      );
    }

    // Merge read status (local might have marked as read)
    final merged = Interaction(
      id: remote.id,
      commentId: remote.commentId,
      type: remote.type,
      fromUserId: remote.fromUserId,
      fromUserName: remote.fromUserName,
      fromUserProfileImageUrl: remote.fromUserProfileImageUrl,
      timestamp: remote.timestamp,
      replyText: remote.replyText,
      isRead: local.isRead || remote.isRead, // If either is read, mark as read
    );

    return ConflictResolutionResult(
      resolvedEntity: merged,
      hadConflict: false,
    );
  }

  /// Applies conflict resolution to a list of entities.
  List<ConflictResolutionResult<Comment>> resolveCommentBatch({
    required Map<String, Comment> localComments,
    required Map<String, Comment> remoteComments,
    required Map<String, SyncableEntity> localMetadata,
    required Map<String, SyncableEntity> remoteMetadata,
    ConflictResolutionStrategy? strategy,
  }) {
    final results = <ConflictResolutionResult<Comment>>[];

    // Get all unique IDs
    final allIds = <String>{
      ...localComments.keys,
      ...remoteComments.keys,
    };

    for (final id in allIds) {
      final local = localComments[id];
      final remote = remoteComments[id];
      final localMeta = localMetadata[id];
      final remoteMeta = remoteMetadata[id];

      if (remote == null && local != null) {
        // Only in local - keep as pending sync
        results.add(ConflictResolutionResult(
          resolvedEntity: local,
          hadConflict: false,
          resolutionNotes: 'Local-only entity, pending push',
        ));
      } else if (local == null && remote != null) {
        // Only in remote - accept
        results.add(ConflictResolutionResult(
          resolvedEntity: remote,
          hadConflict: false,
          resolutionNotes: 'New entity from remote',
        ));
      } else if (local != null && remote != null) {
        // Both exist - resolve conflict
        results.add(resolveComment(
          local: local,
          remote: remote,
          localMeta: localMeta ?? SyncableEntity(id: id),
          remoteMeta: remoteMeta ?? SyncableEntity(id: id),
          strategy: strategy,
        ));
      }
    }

    return results;
  }
}

/// Extension to check if sync metadata indicates a conflict.
extension SyncableEntityConflictCheck on SyncableEntity {
  bool hasConflictWith(SyncableEntity other) {
    if (lastSyncedAt == null) return false;
    if (other.remoteUpdatedAt == null) return false;

    // Conflict if remote changed after our last sync AND we have local changes
    return other.remoteUpdatedAt!.isAfter(lastSyncedAt!) &&
        modifiedAfterLastSync;
  }
}
