import 'dart:async';

import '../../models/models.dart';
import '../api_service.dart';
import 'youtube_api_client.dart';

/// Response from YouTube API containing items and pagination info.
class YouTubePaginatedResponse<T> {
  final List<T> items;
  final String? nextPageToken;
  final String? prevPageToken;
  final int? totalResults;
  final int? resultsPerPage;

  YouTubePaginatedResponse({
    required this.items,
    this.nextPageToken,
    this.prevPageToken,
    this.totalResults,
    this.resultsPerPage,
  });

  bool get hasNextPage => nextPageToken != null;
  bool get hasPreviousPage => prevPageToken != null;
}

/// Video data from YouTube API.
class YouTubeVideo {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelId;
  final String channelTitle;
  final DateTime publishedAt;
  final int? viewCount;
  final int? likeCount;
  final int? commentCount;

  YouTubeVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelId,
    required this.channelTitle,
    required this.publishedAt,
    this.viewCount,
    this.likeCount,
    this.commentCount,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final statistics = json['statistics'] as Map<String, dynamic>?;
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    
    // Get best available thumbnail
    String thumbnailUrl = '';
    for (final quality in ['maxres', 'high', 'medium', 'default']) {
      if (thumbnails[quality] != null) {
        thumbnailUrl = thumbnails[quality]['url'] as String? ?? '';
        break;
      }
    }

    // Handle both direct video ID and nested ID structure from search results
    String videoId = '';
    final jsonId = json['id'];
    if (jsonId is String) {
      videoId = jsonId;
    } else if (jsonId is Map<String, dynamic>) {
      videoId = jsonId['videoId'] as String? ?? '';
    }

    return YouTubeVideo(
      id: videoId,
      title: snippet['title'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      thumbnailUrl: thumbnailUrl,
      channelId: snippet['channelId'] as String? ?? '',
      channelTitle: snippet['channelTitle'] as String? ?? '',
      publishedAt: DateTime.tryParse(snippet['publishedAt'] as String? ?? '') ?? DateTime.now(),
      viewCount: statistics != null ? int.tryParse(statistics['viewCount']?.toString() ?? '') : null,
      likeCount: statistics != null ? int.tryParse(statistics['likeCount']?.toString() ?? '') : null,
      commentCount: statistics != null ? int.tryParse(statistics['commentCount']?.toString() ?? '') : null,
    );
  }
}

/// Comment thread from YouTube API.
class YouTubeCommentThread {
  final String id;
  final Comment topLevelComment;
  final int totalReplyCount;
  final List<Comment>? replies;

  YouTubeCommentThread({
    required this.id,
    required this.topLevelComment,
    required this.totalReplyCount,
    this.replies,
  });

  factory YouTubeCommentThread.fromJson(Map<String, dynamic> json, YouTubeVideo video) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final topLevelSnippet = snippet['topLevelComment']?['snippet'] as Map<String, dynamic>? ?? {};
    final repliesData = json['replies'] as Map<String, dynamic>?;

    final topLevelComment = _parseComment(
      json['snippet']['topLevelComment'] as Map<String, dynamic>? ?? {},
      video,
      isReply: false,
    );

    List<Comment>? replies;
    if (repliesData != null && repliesData['comments'] != null) {
      replies = (repliesData['comments'] as List)
          .map((c) => _parseComment(c as Map<String, dynamic>, video, 
              isReply: true, parentId: json['id'] as String?))
          .toList();
    }

    return YouTubeCommentThread(
      id: json['id'] as String? ?? '',
      topLevelComment: topLevelComment,
      totalReplyCount: snippet['totalReplyCount'] as int? ?? 0,
      replies: replies,
    );
  }
}

/// Parses a YouTube comment from API response.
Comment _parseComment(
  Map<String, dynamic> json,
  YouTubeVideo video, {
  required bool isReply,
  String? parentId,
}) {
  final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
  
  return Comment(
    id: json['id'] as String? ?? '',
    videoId: video.id,
    videoTitle: video.title,
    videoThumbnailUrl: video.thumbnailUrl,
    channelId: video.channelId,
    channelName: video.channelTitle,
    text: snippet['textDisplay'] as String? ?? snippet['textOriginal'] as String? ?? '',
    publishedAt: DateTime.tryParse(snippet['publishedAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(snippet['updatedAt'] as String? ?? ''),
    likeCount: snippet['likeCount'] as int? ?? 0,
    replyCount: isReply ? 0 : (snippet['totalReplyCount'] as int? ?? 0),
    parentId: parentId,
    isReply: isReply,
    authorName: snippet['authorDisplayName'] as String? ?? 'Unknown',
    authorProfileImageUrl: snippet['authorProfileImageUrl'] as String?,
    isBookmarked: false,
  );
}

/// Channel data from YouTube API.
class YouTubeChannel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String? uploadsPlaylistId;
  final int? subscriberCount;
  final int? videoCount;

  YouTubeChannel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    this.uploadsPlaylistId,
    this.subscriberCount,
    this.videoCount,
  });

  factory YouTubeChannel.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final contentDetails = json['contentDetails'] as Map<String, dynamic>?;
    final statistics = json['statistics'] as Map<String, dynamic>?;
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    
    String thumbnailUrl = '';
    for (final quality in ['high', 'medium', 'default']) {
      if (thumbnails[quality] != null) {
        thumbnailUrl = thumbnails[quality]['url'] as String? ?? '';
        break;
      }
    }

    return YouTubeChannel(
      id: json['id'] as String? ?? '',
      title: snippet['title'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      thumbnailUrl: thumbnailUrl,
      uploadsPlaylistId: contentDetails?['relatedPlaylists']?['uploads'] as String?,
      subscriberCount: statistics != null ? int.tryParse(statistics['subscriberCount']?.toString() ?? '') : null,
      videoCount: statistics != null ? int.tryParse(statistics['videoCount']?.toString() ?? '') : null,
    );
  }
}

/// Sync state for tracking incremental sync.
class SyncState {
  final String? channelId;
  final DateTime? lastSyncTime;
  final String? lastVideoId;
  final Map<String, DateTime> videoLastSync;

  SyncState({
    this.channelId,
    this.lastSyncTime,
    this.lastVideoId,
    this.videoLastSync = const {},
  });

  SyncState copyWith({
    String? channelId,
    DateTime? lastSyncTime,
    String? lastVideoId,
    Map<String, DateTime>? videoLastSync,
  }) {
    return SyncState(
      channelId: channelId ?? this.channelId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastVideoId: lastVideoId ?? this.lastVideoId,
      videoLastSync: videoLastSync ?? this.videoLastSync,
    );
  }

  Map<String, dynamic> toJson() => {
    'channelId': channelId,
    'lastSyncTime': lastSyncTime?.toIso8601String(),
    'lastVideoId': lastVideoId,
    'videoLastSync': videoLastSync.map((k, v) => MapEntry(k, v.toIso8601String())),
  };

  factory SyncState.fromJson(Map<String, dynamic> json) {
    return SyncState(
      channelId: json['channelId'] as String?,
      lastSyncTime: json['lastSyncTime'] != null 
          ? DateTime.tryParse(json['lastSyncTime'] as String) 
          : null,
      lastVideoId: json['lastVideoId'] as String?,
      videoLastSync: json['videoLastSync'] != null
          ? (json['videoLastSync'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, DateTime.parse(v as String)))
          : {},
    );
  }
}

/// Service for interacting with YouTube Data API v3.
class YouTubeDataService {
  final YouTubeApiClient _apiClient;
  SyncState _syncState = SyncState();

  YouTubeDataService({required YouTubeApiClient apiClient})
      : _apiClient = apiClient;

  /// Gets the current sync state.
  SyncState get syncState => _syncState;

  /// Updates the sync state.
  void updateSyncState(SyncState state) {
    _syncState = state;
  }

  /// Gets the authenticated user's channel information.
  Future<YouTubeChannel?> getMyChannel() async {
    final response = await _apiClient.get('channels', queryParameters: {
      'part': 'snippet,contentDetails,statistics',
      'mine': 'true',
    });

    final items = response['items'] as List?;
    if (items == null || items.isEmpty) return null;

    return YouTubeChannel.fromJson(items.first as Map<String, dynamic>);
  }

  /// Gets videos from a channel's uploads playlist.
  Future<YouTubePaginatedResponse<YouTubeVideo>> getChannelVideos({
    required String uploadsPlaylistId,
    int maxResults = 25,
    String? pageToken,
    DateTime? publishedAfter,
  }) async {
    final queryParams = {
      'part': 'snippet,contentDetails',
      'playlistId': uploadsPlaylistId,
      'maxResults': maxResults.toString(),
    };

    if (pageToken != null) {
      queryParams['pageToken'] = pageToken;
    }

    final response = await _apiClient.get('playlistItems', queryParameters: queryParams);

    final items = response['items'] as List? ?? [];
    final pageInfo = response['pageInfo'] as Map<String, dynamic>?;

    // Get video IDs to fetch additional details
    final videoIds = items
        .map((item) => (item as Map<String, dynamic>)['contentDetails']?['videoId'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    // Fetch video statistics
    List<YouTubeVideo> videos = [];
    if (videoIds.isNotEmpty) {
      final videosResponse = await _apiClient.get('videos', queryParameters: {
        'part': 'snippet,statistics',
        'id': videoIds.join(','),
      });

      videos = (videosResponse['items'] as List? ?? [])
          .map((v) => YouTubeVideo.fromJson(v as Map<String, dynamic>))
          .toList();

      // Filter by publishedAfter if specified
      if (publishedAfter != null) {
        videos = videos.where((v) => v.publishedAt.isAfter(publishedAfter)).toList();
      }
    }

    return YouTubePaginatedResponse(
      items: videos,
      nextPageToken: response['nextPageToken'] as String?,
      prevPageToken: response['prevPageToken'] as String?,
      totalResults: pageInfo?['totalResults'] as int?,
      resultsPerPage: pageInfo?['resultsPerPage'] as int?,
    );
  }

  /// Gets a single video by ID.
  Future<YouTubeVideo?> getVideo(String videoId) async {
    final response = await _apiClient.get('videos', queryParameters: {
      'part': 'snippet,statistics',
      'id': videoId,
    });

    final items = response['items'] as List?;
    if (items == null || items.isEmpty) return null;

    return YouTubeVideo.fromJson(items.first as Map<String, dynamic>);
  }

  /// Gets comment threads for a video.
  Future<YouTubePaginatedResponse<YouTubeCommentThread>> getVideoCommentThreads({
    required String videoId,
    int maxResults = 20,
    String? pageToken,
    String? searchTerms,
    String order = 'time', // 'time' or 'relevance'
  }) async {
    // First get the video details
    final video = await getVideo(videoId);
    if (video == null) {
      return YouTubePaginatedResponse(items: []);
    }

    final queryParams = {
      'part': 'snippet,replies',
      'videoId': videoId,
      'maxResults': maxResults.toString(),
      'order': order,
      'textFormat': 'plainText',
    };

    if (pageToken != null) {
      queryParams['pageToken'] = pageToken;
    }

    if (searchTerms != null && searchTerms.isNotEmpty) {
      queryParams['searchTerms'] = searchTerms;
    }

    final response = await _apiClient.get('commentThreads', queryParameters: queryParams);

    final items = response['items'] as List? ?? [];
    final pageInfo = response['pageInfo'] as Map<String, dynamic>?;

    final threads = items
        .map((t) => YouTubeCommentThread.fromJson(t as Map<String, dynamic>, video))
        .toList();

    return YouTubePaginatedResponse(
      items: threads,
      nextPageToken: response['nextPageToken'] as String?,
      prevPageToken: response['prevPageToken'] as String?,
      totalResults: pageInfo?['totalResults'] as int?,
      resultsPerPage: pageInfo?['resultsPerPage'] as int?,
    );
  }

  /// Gets all comments for a video (flattened from threads).
  Future<YouTubePaginatedResponse<Comment>> getVideoComments({
    required String videoId,
    int maxResults = 20,
    String? pageToken,
    String? searchTerms,
    String order = 'time',
    bool includeReplies = true,
  }) async {
    final threadsResponse = await getVideoCommentThreads(
      videoId: videoId,
      maxResults: maxResults,
      pageToken: pageToken,
      searchTerms: searchTerms,
      order: order,
    );

    final comments = <Comment>[];
    for (final thread in threadsResponse.items) {
      comments.add(thread.topLevelComment);
      if (includeReplies && thread.replies != null) {
        comments.addAll(thread.replies!);
      }
    }

    return YouTubePaginatedResponse(
      items: comments,
      nextPageToken: threadsResponse.nextPageToken,
      prevPageToken: threadsResponse.prevPageToken,
      totalResults: threadsResponse.totalResults,
      resultsPerPage: threadsResponse.resultsPerPage,
    );
  }

  /// Gets all comment threads for a channel (across all videos).
  /// Uses the channel's uploads playlist to iterate through videos.
  Future<List<Comment>> getChannelComments({
    required String channelId,
    int maxVideos = 10,
    int maxCommentsPerVideo = 50,
    DateTime? publishedAfter,
    void Function(int current, int total)? onProgress,
  }) async {
    // Get channel info to get uploads playlist
    final channelResponse = await _apiClient.get('channels', queryParameters: {
      'part': 'contentDetails',
      'id': channelId,
    });

    final items = channelResponse['items'] as List?;
    if (items == null || items.isEmpty) return [];

    final uploadsPlaylistId = items.first['contentDetails']?['relatedPlaylists']?['uploads'] as String?;
    if (uploadsPlaylistId == null) return [];

    // Get videos from uploads playlist
    final videosResponse = await getChannelVideos(
      uploadsPlaylistId: uploadsPlaylistId,
      maxResults: maxVideos,
      publishedAfter: publishedAfter,
    );

    final allComments = <Comment>[];
    final videos = videosResponse.items;

    for (int i = 0; i < videos.length; i++) {
      onProgress?.call(i + 1, videos.length);
      
      try {
        final commentsResponse = await getVideoComments(
          videoId: videos[i].id,
          maxResults: maxCommentsPerVideo,
          includeReplies: true,
        );
        allComments.addAll(commentsResponse.items);

        // Update sync state
        _syncState = _syncState.copyWith(
          videoLastSync: {
            ..._syncState.videoLastSync,
            videos[i].id: DateTime.now(),
          },
        );
      } catch (e) {
        // Comments might be disabled for some videos - continue
        continue;
      }
    }

    // Update overall sync state
    _syncState = _syncState.copyWith(
      channelId: channelId,
      lastSyncTime: DateTime.now(),
    );

    return allComments;
  }

  /// Performs incremental sync, only fetching new comments since last sync.
  Future<List<Comment>> incrementalSync({
    required String channelId,
    int maxVideos = 10,
    int maxCommentsPerVideo = 50,
    void Function(int current, int total)? onProgress,
  }) async {
    final publishedAfter = _syncState.lastSyncTime;
    
    return getChannelComments(
      channelId: channelId,
      maxVideos: maxVideos,
      maxCommentsPerVideo: maxCommentsPerVideo,
      publishedAfter: publishedAfter,
      onProgress: onProgress,
    );
  }

  /// Searches for comments containing specific text (client-side filtering).
  List<Comment> filterComments(
    List<Comment> comments,
    String query,
  ) {
    if (query.isEmpty) return comments;
    
    final lowerQuery = query.toLowerCase();
    return comments.where((comment) {
      return comment.text.toLowerCase().contains(lowerQuery) ||
          comment.videoTitle.toLowerCase().contains(lowerQuery) ||
          comment.channelName.toLowerCase().contains(lowerQuery) ||
          comment.authorName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Converts YouTube comments to PaginatedResponse for compatibility.
  PaginatedResponse<Comment> toPaginatedResponse(
    List<Comment> comments, {
    int page = 1,
    int pageSize = 10,
    String? searchQuery,
  }) {
    var filteredComments = searchQuery != null && searchQuery.isNotEmpty
        ? filterComments(comments, searchQuery)
        : comments;

    // Sort by published date (newest first)
    filteredComments.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    final totalItems = filteredComments.length;
    final totalPages = (totalItems / pageSize).ceil();
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;

    final items = filteredComments.sublist(
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
}
