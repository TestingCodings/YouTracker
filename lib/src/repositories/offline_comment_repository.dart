import 'dart:async';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/local_storage_service.dart';
import '../sync/hive_adapters.dart';
import '../sync/sync_engine.dart';

/// Offline-first repository for comments.
/// Uses Hive as the single source of truth and SyncEngine for remote operations.
class OfflineCommentRepository {
  final LocalStorageService _localStorage;
  final SyncEngine _syncEngine;
  final CommentApiService? _apiService;

  OfflineCommentRepository({
    LocalStorageService? localStorage,
    SyncEngine? syncEngine,
    CommentApiService? apiService,
  })  : _localStorage = localStorage ?? LocalStorageService.instance,
        _syncEngine = syncEngine ?? SyncEngine.instance,
        _apiService = apiService;

  /// Gets all comments from local storage.
  List<Comment> getAllComments() {
    return _localStorage.getAllComments();
  }

  /// Gets a comment by ID from local storage.
  Comment? getComment(String id) {
    return _localStorage.getComment(id);
  }

  /// Gets comments with pagination support.
  PaginatedResponse<Comment> getCommentsPaginated({
    int page = 1,
    int pageSize = 10,
    String? searchQuery,
  }) {
    var allComments = getAllComments();

    // Apply search filter if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      allComments = allComments.where((comment) {
        return comment.text.toLowerCase().contains(query) ||
            comment.videoTitle.toLowerCase().contains(query) ||
            comment.channelName.toLowerCase().contains(query) ||
            comment.authorName.toLowerCase().contains(query);
      }).toList();
    }

    // Sort by published date (newest first)
    allComments.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    // Calculate pagination
    final totalItems = allComments.length;
    final totalPages = totalItems > 0 ? (totalItems / pageSize).ceil() : 1;
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;

    final items = allComments.sublist(
      startIndex.clamp(0, totalItems),
      endIndex.clamp(0, totalItems),
    );

    return PaginatedResponse(
      items: items,
      currentPage: page,
      totalPages: totalPages,
      totalItems: totalItems,
      hasNextPage: page < totalPages,
      hasPreviousPage: page > 1,
    );
  }

  /// Saves a comment locally and enqueues for sync.
  Future<Comment> saveComment(Comment comment, {bool enqueueSync = true}) async {
    final isNew = _localStorage.getComment(comment.id) == null;

    // Save to local storage immediately (offline-first)
    await _localStorage.saveComment(comment);

    // Enqueue sync operation if network sync is needed
    if (enqueueSync) {
      await _syncEngine.enqueueChange(
        opType: isNew ? SyncOperationType.create : SyncOperationType.update,
        entityType: SyncEntityType.comment,
        entityId: comment.id,
        payload: comment.toJson(),
      );
    }

    return comment;
  }

  /// Updates a comment locally and enqueues for sync.
  Future<Comment> updateComment(Comment comment) async {
    // Update local storage immediately
    await _localStorage.saveComment(comment);

    // Enqueue sync operation
    await _syncEngine.enqueueChange(
      opType: SyncOperationType.update,
      entityType: SyncEntityType.comment,
      entityId: comment.id,
      payload: comment.toJson(),
    );

    return comment;
  }

  /// Deletes a comment locally and enqueues for sync.
  Future<void> deleteComment(String id) async {
    // Delete from local storage
    await _localStorage.deleteComment(id);

    // Enqueue sync operation
    await _syncEngine.enqueueChange(
      opType: SyncOperationType.delete,
      entityType: SyncEntityType.comment,
      entityId: id,
    );
  }

  /// Toggles bookmark status for a comment.
  Future<Comment> toggleBookmark(String commentId) async {
    final comment = _localStorage.getComment(commentId);
    if (comment == null) {
      throw Exception('Comment not found: $commentId');
    }

    final updatedComment = comment.copyWith(
      isBookmarked: !comment.isBookmarked,
    );

    // Bookmark is local-only state, no sync needed
    await _localStorage.saveComment(updatedComment);

    return updatedComment;
  }

  /// Gets bookmarked comments.
  List<Comment> getBookmarkedComments() {
    return getAllComments().where((c) => c.isBookmarked).toList();
  }

  /// Gets replies for a specific comment.
  List<Comment> getRepliesForComment(String parentId) {
    return getAllComments().where((c) => c.parentId == parentId).toList();
  }

  /// Refreshes comments from remote and merges with local.
  Future<RefreshResult> refresh() async {
    final result = await _syncEngine.syncNow();

    return RefreshResult(
      success: result.success,
      itemsUpdated: result.itemsPulled,
      conflicts: result.conflicts,
      error: result.error,
    );
  }

  /// Forces a full refresh from remote.
  Future<RefreshResult> forceRefresh() async {
    final result = await _syncEngine.forceFullSync();

    return RefreshResult(
      success: result.success,
      itemsUpdated: result.itemsPulled,
      conflicts: result.conflicts,
      error: result.error,
    );
  }

  /// Gets the current sync status.
  SyncStatus get syncStatus => _syncEngine.currentStatus;

  /// Stream of sync status updates.
  Stream<SyncStatus> get syncStatusStream => _syncEngine.statusStream;

  /// Whether there are pending sync operations.
  bool get hasPendingSync => _syncEngine.syncQueue.queueLength > 0;

  /// The number of pending sync operations.
  int get pendingSyncCount => _syncEngine.syncQueue.queueLength;
}

/// Result of a refresh operation.
class RefreshResult {
  final bool success;
  final int itemsUpdated;
  final int conflicts;
  final String? error;

  const RefreshResult({
    required this.success,
    this.itemsUpdated = 0,
    this.conflicts = 0,
    this.error,
  });

  @override
  String toString() {
    return 'RefreshResult(success: $success, updated: $itemsUpdated, conflicts: $conflicts)';
  }
}
