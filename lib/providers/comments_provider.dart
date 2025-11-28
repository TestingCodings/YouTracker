import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';

/// Filter type for comments based on sentiment.
enum CommentSentimentFilter {
  all,
  positive,
  negative,
  neutral,
  questions,
  needsReply,
  toxic;

  String get displayName {
    switch (this) {
      case CommentSentimentFilter.all:
        return 'All';
      case CommentSentimentFilter.positive:
        return 'Positive';
      case CommentSentimentFilter.negative:
        return 'Negative';
      case CommentSentimentFilter.neutral:
        return 'Neutral';
      case CommentSentimentFilter.questions:
        return 'Questions';
      case CommentSentimentFilter.needsReply:
        return 'Needs Reply';
      case CommentSentimentFilter.toxic:
        return 'Toxic';
    }
  }
}

/// Provider for comments with pagination and search support.
final commentsProvider =
    StateNotifierProvider<CommentsNotifier, CommentsState>((ref) {
  return CommentsNotifier();
});

class CommentsState {
  final List<Comment> comments;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final CommentSentimentFilter sentimentFilter;

  CommentsState({
    this.comments = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.sentimentFilter = CommentSentimentFilter.all,
  });

  /// Returns filtered comments based on sentiment filter.
  List<Comment> get filteredComments {
    if (sentimentFilter == CommentSentimentFilter.all) {
      return comments;
    }
    return comments.where((comment) {
      switch (sentimentFilter) {
        case CommentSentimentFilter.all:
          return true;
        case CommentSentimentFilter.positive:
          return comment.sentimentLabel?.toLowerCase() == 'positive';
        case CommentSentimentFilter.negative:
          return comment.sentimentLabel?.toLowerCase() == 'negative';
        case CommentSentimentFilter.neutral:
          return comment.sentimentLabel?.toLowerCase() == 'neutral';
        case CommentSentimentFilter.questions:
          return comment.sentimentLabel?.toLowerCase() == 'question';
        case CommentSentimentFilter.needsReply:
          return comment.needsReply == true;
        case CommentSentimentFilter.toxic:
          return comment.isToxic == true;
      }
    }).toList();
  }

  CommentsState copyWith({
    List<Comment>? comments,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    bool? hasPreviousPage,
    bool? isLoading,
    String? error,
    String? searchQuery,
    CommentSentimentFilter? sentimentFilter,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      sentimentFilter: sentimentFilter ?? this.sentimentFilter,
    );
  }
}

class CommentsNotifier extends StateNotifier<CommentsState> {
  CommentsNotifier() : super(CommentsState());

  final CommentApiService _apiService = CommentApiService();

  /// Fetches comments from the API.
  Future<void> fetchComments({
    int page = 1,
    String? searchQuery,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      searchQuery: searchQuery ?? state.searchQuery,
    );

    try {
      final response = await _apiService.getComments(
        page: page,
        pageSize: 10,
        searchQuery: searchQuery ?? state.searchQuery,
      );

      state = state.copyWith(
        comments: response.items,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
        totalItems: response.totalItems,
        hasNextPage: response.hasNextPage,
        hasPreviousPage: response.hasPreviousPage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Goes to the next page of comments.
  Future<void> nextPage() async {
    if (state.hasNextPage && !state.isLoading) {
      await fetchComments(page: state.currentPage + 1);
    }
  }

  /// Goes to the previous page of comments.
  Future<void> previousPage() async {
    if (state.hasPreviousPage && !state.isLoading) {
      await fetchComments(page: state.currentPage - 1);
    }
  }

  /// Searches for comments.
  Future<void> search(String query) async {
    await fetchComments(page: 1, searchQuery: query);
  }

  /// Clears the search and refreshes.
  Future<void> clearSearch() async {
    await fetchComments(page: 1, searchQuery: '');
  }

  /// Refreshes the current page.
  Future<void> refresh() async {
    await fetchComments(page: state.currentPage);
  }

  /// Toggles bookmark status for a comment.
  Future<void> toggleBookmark(String commentId) async {
    try {
      final updatedComment = await _apiService.toggleBookmark(commentId);
      final updatedComments = state.comments.map((c) {
        if (c.id == commentId) {
          return updatedComment;
        }
        return c;
      }).toList();
      state = state.copyWith(comments: updatedComments);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Sets the sentiment filter.
  void setSentimentFilter(CommentSentimentFilter filter) {
    state = state.copyWith(sentimentFilter: filter);
  }

  /// Clears the sentiment filter.
  void clearSentimentFilter() {
    state = state.copyWith(sentimentFilter: CommentSentimentFilter.all);
  }
}

/// Provider for a single comment detail.
final commentDetailProvider =
    FutureProvider.family<Comment?, String>((ref, commentId) async {
  final apiService = CommentApiService();
  return apiService.getCommentById(commentId);
});

/// Provider for bookmarked comments.
final bookmarkedCommentsProvider = FutureProvider<List<Comment>>((ref) async {
  final apiService = CommentApiService();
  return apiService.getBookmarkedComments();
});
