import 'dart:async';

import '../models/models.dart';
import 'mock_data_service.dart';

/// API service for interacting with the YouTube Comments backend.
/// Currently uses mock data, but is structured for future backend integration.
class CommentApiService {
  /// Simulates network delay
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Fetches all comments with pagination support.
  /// [page] - Page number (1-indexed)
  /// [pageSize] - Number of items per page
  /// [searchQuery] - Optional search query to filter comments
  Future<PaginatedResponse<Comment>> getComments({
    int page = 1,
    int pageSize = 10,
    String? searchQuery,
  }) async {
    await _simulateNetworkDelay();

    List<Comment> allComments = MockDataService.getComments();

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
    final totalPages = (totalItems / pageSize).ceil();
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

  /// Fetches a single comment by ID.
  Future<Comment?> getCommentById(String id) async {
    await _simulateNetworkDelay();
    return MockDataService.getCommentById(id);
  }

  /// Fetches bookmarked comments.
  Future<List<Comment>> getBookmarkedComments() async {
    await _simulateNetworkDelay();
    return MockDataService.getComments()
        .where((comment) => comment.isBookmarked)
        .toList();
  }

  /// Toggles bookmark status for a comment.
  Future<Comment> toggleBookmark(String commentId) async {
    await _simulateNetworkDelay();
    final comment = MockDataService.getCommentById(commentId);
    if (comment == null) {
      throw Exception('Comment not found');
    }
    return comment.copyWith(isBookmarked: !comment.isBookmarked);
  }

  /// Fetches replies for a specific comment.
  Future<List<Comment>> getRepliesForComment(String parentId) async {
    await _simulateNetworkDelay();
    return MockDataService.getComments()
        .where((comment) => comment.parentId == parentId)
        .toList();
  }
}

/// API service for interacting with interactions.
class InteractionApiService {
  /// Simulates network delay
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Fetches all interactions.
  Future<List<Interaction>> getInteractions() async {
    await _simulateNetworkDelay();
    return MockDataService.getInteractions();
  }

  /// Fetches interactions for a specific comment.
  Future<List<Interaction>> getInteractionsForComment(String commentId) async {
    await _simulateNetworkDelay();
    return MockDataService.getInteractionsForComment(commentId);
  }

  /// Fetches unread interactions count.
  Future<int> getUnreadInteractionsCount() async {
    await _simulateNetworkDelay();
    return MockDataService.getInteractions()
        .where((i) => !i.isRead)
        .length;
  }

  /// Marks an interaction as read.
  Future<Interaction> markAsRead(String interactionId) async {
    await _simulateNetworkDelay();
    final interactions = MockDataService.getInteractions();
    final interaction = interactions.firstWhere((i) => i.id == interactionId);
    return interaction.copyWith(isRead: true);
  }

  /// Marks all interactions as read.
  Future<void> markAllAsRead() async {
    await _simulateNetworkDelay();
    // In a real implementation, this would update the backend
  }
}

/// Generic paginated response wrapper.
class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });
}
