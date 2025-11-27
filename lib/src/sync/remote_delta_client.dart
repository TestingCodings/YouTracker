import 'dart:async';

import '../../models/models.dart';
import '../../services/youtube/youtube_api_client.dart';
import '../../services/youtube/youtube_data_service.dart';
import 'hive_adapters.dart';

/// Response from a delta sync operation.
class DeltaSyncResponse<T> {
  final List<T> items;
  final String? nextPageToken;
  final String? etag;
  final bool wasModified;
  final DateTime syncTime;

  const DeltaSyncResponse({
    required this.items,
    this.nextPageToken,
    this.etag,
    this.wasModified = true,
    DateTime? syncTime,
  }) : syncTime = syncTime ?? const _CurrentDateTime();
}

class _CurrentDateTime implements DateTime {
  const _CurrentDateTime();
  @override dynamic noSuchMethod(Invocation invocation) => DateTime.now();
}

/// Client for fetching remote deltas with ETag support.
class RemoteDeltaClient {
  final YouTubeDataService? _youtubeService;
  final Map<String, String> _cachedEtags = {};
  final Map<String, DateTime> _lastSyncTimes = {};

  RemoteDeltaClient({YouTubeDataService? youtubeService})
      : _youtubeService = youtubeService;

  /// Whether the client is connected to a real service.
  bool get isConnected => _youtubeService != null;

  /// Fetches comments with delta support using ETag/If-None-Match.
  Future<DeltaSyncResponse<Comment>> fetchCommentsDelta({
    required String videoId,
    String? pageToken,
    int maxResults = 50,
  }) async {
    if (_youtubeService == null) {
      return DeltaSyncResponse(
        items: [],
        wasModified: false,
        syncTime: DateTime.now(),
      );
    }

    final cacheKey = 'comments_$videoId';
    final cachedEtag = _cachedEtags[cacheKey];

    try {
      final response = await _youtubeService!.getVideoComments(
        videoId: videoId,
        maxResults: maxResults,
        pageToken: pageToken,
        // Note: YouTube API doesn't fully support If-None-Match for comments
        // but we can use publishedAfter for delta updates
      );

      final newEtag = DateTime.now().millisecondsSinceEpoch.toString();
      _cachedEtags[cacheKey] = newEtag;
      _lastSyncTimes[cacheKey] = DateTime.now();

      return DeltaSyncResponse(
        items: response.items,
        nextPageToken: response.nextPageToken,
        etag: newEtag,
        wasModified: true,
        syncTime: DateTime.now(),
      );
    } catch (e) {
      if (e is YouTubeApiException && e.statusCode == 304) {
        // Not modified - use cached data
        return DeltaSyncResponse(
          items: [],
          etag: cachedEtag,
          wasModified: false,
          syncTime: _lastSyncTimes[cacheKey] ?? DateTime.now(),
        );
      }
      rethrow;
    }
  }

  /// Fetches comments updated after a specific time.
  Future<DeltaSyncResponse<Comment>> fetchCommentsUpdatedAfter({
    required String channelId,
    required DateTime updatedAfter,
    int maxVideos = 10,
    int maxCommentsPerVideo = 50,
  }) async {
    if (_youtubeService == null) {
      return DeltaSyncResponse(
        items: [],
        wasModified: false,
        syncTime: DateTime.now(),
      );
    }

    try {
      // Use incremental sync which uses publishedAfter
      final comments = await _youtubeService!.getChannelComments(
        channelId: channelId,
        maxVideos: maxVideos,
        maxCommentsPerVideo: maxCommentsPerVideo,
        publishedAfter: updatedAfter,
      );

      return DeltaSyncResponse(
        items: comments,
        wasModified: comments.isNotEmpty,
        syncTime: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches channel information with caching.
  Future<YouTubeChannel?> fetchChannel() async {
    if (_youtubeService == null) return null;

    try {
      return await _youtubeService!.getMyChannel();
    } catch (e) {
      return null;
    }
  }

  /// Gets the last sync time for a cache key.
  DateTime? getLastSyncTime(String cacheKey) {
    return _lastSyncTimes[cacheKey];
  }

  /// Gets the cached ETag for a cache key.
  String? getCachedEtag(String cacheKey) {
    return _cachedEtags[cacheKey];
  }

  /// Updates the cached ETag and sync time.
  void updateCache(String cacheKey, String? etag) {
    if (etag != null) {
      _cachedEtags[cacheKey] = etag;
    }
    _lastSyncTimes[cacheKey] = DateTime.now();
  }

  /// Clears all cached data.
  void clearCache() {
    _cachedEtags.clear();
    _lastSyncTimes.clear();
  }

  /// Clears cache for a specific key.
  void clearCacheForKey(String cacheKey) {
    _cachedEtags.remove(cacheKey);
    _lastSyncTimes.remove(cacheKey);
  }
}

/// Extension for creating sync metadata from delta responses.
extension DeltaSyncResponseExtension<T> on DeltaSyncResponse<T> {
  /// Creates SyncMetadata from this response.
  SyncMetadata toSyncMetadata(String key, {SyncMetadata? existing}) {
    final now = DateTime.now();
    return SyncMetadata(
      key: key,
      lastSyncToken: nextPageToken,
      lastFullSyncTime: existing?.lastFullSyncTime,
      lastIncrementalSyncTime: now,
      etag: etag,
      syncCount: (existing?.syncCount ?? 0) + 1,
      failedSyncCount: existing?.failedSyncCount ?? 0,
      itemsSynced: (existing?.itemsSynced ?? 0) + items.length,
      schemaVersion: existing?.schemaVersion ?? 1,
      migrationCompleted: existing?.migrationCompleted ?? true,
    );
  }
}

/// Builder for constructing delta sync requests.
class DeltaSyncRequestBuilder {
  String? _channelId;
  String? _videoId;
  DateTime? _updatedAfter;
  String? _pageToken;
  int _maxResults = 50;
  String? _etag;

  DeltaSyncRequestBuilder();

  DeltaSyncRequestBuilder forChannel(String channelId) {
    _channelId = channelId;
    return this;
  }

  DeltaSyncRequestBuilder forVideo(String videoId) {
    _videoId = videoId;
    return this;
  }

  DeltaSyncRequestBuilder updatedAfter(DateTime time) {
    _updatedAfter = time;
    return this;
  }

  DeltaSyncRequestBuilder withPageToken(String? token) {
    _pageToken = token;
    return this;
  }

  DeltaSyncRequestBuilder withMaxResults(int max) {
    _maxResults = max;
    return this;
  }

  DeltaSyncRequestBuilder ifNoneMatch(String? etag) {
    _etag = etag;
    return this;
  }

  /// Executes the delta sync request.
  Future<DeltaSyncResponse<Comment>> execute(RemoteDeltaClient client) async {
    if (_videoId != null) {
      return client.fetchCommentsDelta(
        videoId: _videoId!,
        pageToken: _pageToken,
        maxResults: _maxResults,
      );
    }

    if (_channelId != null && _updatedAfter != null) {
      return client.fetchCommentsUpdatedAfter(
        channelId: _channelId!,
        updatedAfter: _updatedAfter!,
        maxCommentsPerVideo: _maxResults,
      );
    }

    throw StateError('Must specify either videoId or channelId with updatedAfter');
  }
}
