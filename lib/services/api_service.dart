import 'dart:async';

import '../models/models.dart';
import 'local_storage_service.dart';
import 'mock_data_service.dart';
import 'youtube/youtube_api_client.dart';
import 'youtube/youtube_data_service.dart';

/// API service for interacting with the YouTube Comments backend.
/// Supports both mock data (for testing/development) and real YouTube API.
class CommentApiService {
  final YouTubeDataService? _youtubeService;
  final bool _useMockData;
  
  /// Cached comments for pagination and search.
  List<Comment> _cachedComments = [];
  
  /// Map of bookmarked comment IDs.
  final Set<String> _bookmarkedIds = {};

  /// Creates a CommentApiService.
  /// 
  /// If [youtubeDataService] is provided, uses real YouTube API.
  /// Otherwise, falls back to mock data.
  CommentApiService({
    YouTubeDataService? youtubeDataService,
    bool useMockData = true,
  })  : _youtubeService = youtubeDataService,
        _useMockData = useMockData || youtubeDataService == null;

  /// Whether using mock data or real API.
  bool get isUsingMockData => _useMockData;

  /// Simulates network delay (only for mock data)
  Future<void> _simulateNetworkDelay() async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Fetches all comments with pagination support.
  /// [page] - Page number (1-indexed)
  /// [pageSize] - Number of items per page
  /// [searchQuery] - Optional search query to filter comments
  /// [videoId] - Optional video ID to filter comments by video
  /// [forceRefresh] - Force fetch from API instead of using cache
  Future<PaginatedResponse<Comment>> getComments({
    int page = 1,
    int pageSize = 10,
    String? searchQuery,
    String? videoId,
    bool forceRefresh = false,
  }) async {
    if (_useMockData) {
      return _getMockComments(page: page, pageSize: pageSize, searchQuery: searchQuery);
    }

    return _getYouTubeComments(
      page: page,
      pageSize: pageSize,
      searchQuery: searchQuery,
      videoId: videoId,
      forceRefresh: forceRefresh,
    );
  }

  /// Gets comments from mock data.
  Future<PaginatedResponse<Comment>> _getMockComments({
    int page = 1,
    int pageSize = 10,
    String? searchQuery,
  }) async {
    await _simulateNetworkDelay();

    List<Comment> allComments = MockDataService.getComments();

    // Apply bookmarks from local state
    allComments = allComments.map((c) => 
      c.copyWith(isBookmarked: _bookmarkedIds.contains(c.id))
    ).toList();

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

  /// Gets comments from YouTube API.
  Future<PaginatedResponse<Comment>> _getYouTubeComments({
    int page = 1,
    int pageSize = 10,
    String? searchQuery,
    String? videoId,
    bool forceRefresh = false,
  }) async {
    // If we have a video ID, fetch comments for that video
    if (videoId != null) {
      final response = await _youtubeService!.getVideoComments(
        videoId: videoId,
        maxResults: pageSize,
        searchTerms: searchQuery,
      );

      // Apply bookmarks
      final items = response.items.map((c) => 
        c.copyWith(isBookmarked: _bookmarkedIds.contains(c.id))
      ).toList();

      return PaginatedResponse(
        items: items,
        currentPage: page,
        totalPages: response.totalResults != null 
            ? (response.totalResults! / pageSize).ceil() 
            : 1,
        totalItems: response.totalResults ?? items.length,
        hasNextPage: response.hasNextPage,
        hasPreviousPage: response.hasPreviousPage,
      );
    }

    // Use cached comments for general browsing
    if (_cachedComments.isEmpty || forceRefresh) {
      await refreshCommentsCache();
    }

    return _youtubeService!.toPaginatedResponse(
      _cachedComments.map((c) => 
        c.copyWith(isBookmarked: _bookmarkedIds.contains(c.id))
      ).toList(),
      page: page,
      pageSize: pageSize,
      searchQuery: searchQuery,
    );
  }

  /// Refreshes the comments cache from YouTube API.
  /// This fetches comments from the user's channel.
  Future<void> refreshCommentsCache() async {
    if (_youtubeService == null) return;

    try {
      final channel = await _youtubeService!.getMyChannel();
      if (channel == null) return;

      _cachedComments = await _youtubeService!.getChannelComments(
        channelId: channel.id,
        maxVideos: 10,
        maxCommentsPerVideo: 50,
      );

      // Store in local storage for offline access
      try {
        final localStorage = LocalStorageService.instance;
        await localStorage.saveComments(_cachedComments);
      } catch (e) {
        // Storage might not be initialized in tests
      }
    } catch (e) {
      // Fall back to local storage if API fails
      try {
        final localStorage = LocalStorageService.instance;
        _cachedComments = localStorage.getAllComments();
      } catch (e) {
        // Storage might not be initialized
      }
    }
  }

  /// Performs incremental sync to fetch only new comments.
  Future<List<Comment>> incrementalSync() async {
    if (_youtubeService == null) return [];

    try {
      final channel = await _youtubeService!.getMyChannel();
      if (channel == null) return [];

      final newComments = await _youtubeService!.incrementalSync(
        channelId: channel.id,
      );

      // Merge with cached comments
      final existingIds = _cachedComments.map((c) => c.id).toSet();
      final uniqueNewComments = newComments.where((c) => !existingIds.contains(c.id)).toList();
      _cachedComments.insertAll(0, uniqueNewComments);

      // Store in local storage
      try {
        final localStorage = LocalStorageService.instance;
        await localStorage.saveComments(_cachedComments);
      } catch (e) {
        // Storage might not be initialized
      }

      return uniqueNewComments;
    } catch (e) {
      return [];
    }
  }

  /// Fetches a single comment by ID.
  Future<Comment?> getCommentById(String id) async {
    await _simulateNetworkDelay();
    
    // Check cache first
    final cached = _cachedComments.where((c) => c.id == id).firstOrNull;
    if (cached != null) {
      return cached.copyWith(isBookmarked: _bookmarkedIds.contains(cached.id));
    }
    
    if (_useMockData) {
      final comment = MockDataService.getCommentById(id);
      return comment?.copyWith(isBookmarked: _bookmarkedIds.contains(id));
    }
    
    return null;
  }

  /// Fetches bookmarked comments.
  Future<List<Comment>> getBookmarkedComments() async {
    await _simulateNetworkDelay();
    
    List<Comment> allComments;
    if (_useMockData) {
      allComments = MockDataService.getComments();
    } else {
      allComments = _cachedComments;
    }
    
    return allComments
        .where((comment) => _bookmarkedIds.contains(comment.id))
        .map((c) => c.copyWith(isBookmarked: true))
        .toList();
  }

  /// Toggles bookmark status for a comment.
  Future<Comment> toggleBookmark(String commentId) async {
    await _simulateNetworkDelay();
    
    Comment? comment;
    if (_useMockData) {
      comment = MockDataService.getCommentById(commentId);
    } else {
      comment = _cachedComments.where((c) => c.id == commentId).firstOrNull;
    }
    
    if (comment == null) {
      throw Exception('Comment not found');
    }
    
    final isCurrentlyBookmarked = _bookmarkedIds.contains(commentId);
    if (isCurrentlyBookmarked) {
      _bookmarkedIds.remove(commentId);
    } else {
      _bookmarkedIds.add(commentId);
    }
    
    return comment.copyWith(isBookmarked: !isCurrentlyBookmarked);
  }

  /// Fetches replies for a specific comment.
  Future<List<Comment>> getRepliesForComment(String parentId) async {
    await _simulateNetworkDelay();
    
    if (_useMockData) {
      return MockDataService.getComments()
          .where((comment) => comment.parentId == parentId)
          .toList();
    }
    
    // In real API, replies are included in comment threads
    return _cachedComments
        .where((comment) => comment.parentId == parentId)
        .toList();
  }

  /// Clears the comments cache.
  void clearCache() {
    _cachedComments.clear();
  }

  /// Gets the current sync state.
  SyncState? get syncState => _youtubeService?.syncState;
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
