import 'package:flutter_test/flutter_test.dart';
import 'package:you_tracker/services/services.dart';

void main() {
  group('MockDataService', () {
    test('should return list of comments', () {
      final comments = MockDataService.getComments();

      expect(comments, isNotEmpty);
      expect(comments.first.id, isNotEmpty);
      expect(comments.first.text, isNotEmpty);
    });

    test('should return list of interactions', () {
      final interactions = MockDataService.getInteractions();

      expect(interactions, isNotEmpty);
      expect(interactions.first.id, isNotEmpty);
    });

    test('should return comment by ID', () {
      final comments = MockDataService.getComments();
      final firstCommentId = comments.first.id;

      final comment = MockDataService.getCommentById(firstCommentId);

      expect(comment, isNotNull);
      expect(comment!.id, firstCommentId);
    });

    test('should return null for non-existent comment ID', () {
      final comment = MockDataService.getCommentById('non_existent_id');

      expect(comment, isNull);
    });

    test('should return interactions for specific comment', () {
      final interactions = MockDataService.getInteractions();
      if (interactions.isNotEmpty) {
        final commentId = interactions.first.commentId;
        final commentInteractions =
            MockDataService.getInteractionsForComment(commentId);

        expect(commentInteractions, isNotEmpty);
        expect(
          commentInteractions.every((i) => i.commentId == commentId),
          isTrue,
        );
      }
    });
  });

  group('CommentApiService', () {
    late CommentApiService apiService;

    setUp(() {
      apiService = CommentApiService(useMockData: true);
    });

    test('should fetch paginated comments', () async {
      final response = await apiService.getComments(page: 1, pageSize: 5);

      expect(response.items, isNotEmpty);
      expect(response.currentPage, 1);
      expect(response.items.length, lessThanOrEqualTo(5));
    });

    test('should filter comments by search query', () async {
      final response = await apiService.getComments(
        page: 1,
        pageSize: 10,
        searchQuery: 'Flutter',
      );

      // Search results should contain the query in text, title, channel, or author
      for (final comment in response.items) {
        final containsQuery = comment.text.toLowerCase().contains('flutter') ||
            comment.videoTitle.toLowerCase().contains('flutter') ||
            comment.channelName.toLowerCase().contains('flutter') ||
            comment.authorName.toLowerCase().contains('flutter');
        expect(containsQuery, isTrue);
      }
    });

    test('should toggle bookmark status', () async {
      final comments = MockDataService.getComments();
      final firstCommentId = comments.first.id;

      // Toggle bookmark on
      final toggledOn = await apiService.toggleBookmark(firstCommentId);
      expect(toggledOn.isBookmarked, isTrue);

      // Toggle bookmark off
      final toggledOff = await apiService.toggleBookmark(firstCommentId);
      expect(toggledOff.isBookmarked, isFalse);
    });

    test('should be using mock data', () {
      expect(apiService.isUsingMockData, isTrue);
    });
  });

  group('InteractionApiService', () {
    late InteractionApiService apiService;

    setUp(() {
      apiService = InteractionApiService();
    });

    test('should fetch interactions', () async {
      final interactions = await apiService.getInteractions();

      expect(interactions, isNotEmpty);
    });

    test('should return unread interactions count', () async {
      final count = await apiService.getUnreadInteractionsCount();

      expect(count, greaterThanOrEqualTo(0));
    });
  });

  group('PaginatedResponse', () {
    test('should correctly represent paginated data', () {
      final response = PaginatedResponse<String>(
        items: ['a', 'b', 'c'],
        currentPage: 1,
        totalPages: 3,
        totalItems: 9,
        hasNextPage: true,
        hasPreviousPage: false,
      );

      expect(response.items.length, 3);
      expect(response.currentPage, 1);
      expect(response.totalPages, 3);
      expect(response.hasNextPage, isTrue);
      expect(response.hasPreviousPage, isFalse);
    });
  });

  group('StoredTokenData', () {
    test('should correctly identify expired tokens', () {
      final expiredData = StoredTokenData(
        accessToken: 'test_token',
        expiry: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(expiredData.isExpired, isTrue);

      final validData = StoredTokenData(
        accessToken: 'test_token',
        expiry: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(validData.isExpired, isFalse);
    });

    test('should be expired when no expiry is set', () {
      final noExpiryData = StoredTokenData(
        accessToken: 'test_token',
      );
      expect(noExpiryData.isExpired, isTrue);
    });
  });

  group('YouTubeScopes', () {
    test('should have correct scope URLs', () {
      expect(
        YouTubeScopes.youtubeReadonly,
        'https://www.googleapis.com/auth/youtube.readonly',
      );
      expect(
        YouTubeScopes.youtube,
        'https://www.googleapis.com/auth/youtube',
      );
      expect(
        YouTubeScopes.youtubeForceSsl,
        'https://www.googleapis.com/auth/youtube.force-ssl',
      );
    });

    test('should have default scopes', () {
      expect(YouTubeScopes.defaultScopes, isNotEmpty);
      expect(
        YouTubeScopes.defaultScopes,
        contains(YouTubeScopes.youtubeReadonly),
      );
    });
  });

  group('RetryConfig', () {
    test('should calculate delay with exponential backoff', () {
      const config = RetryConfig(
        initialDelay: Duration(seconds: 1),
        maxDelay: Duration(seconds: 32),
        backoffMultiplier: 2.0,
      );

      // First attempt: ~1 second (with jitter)
      final delay0 = config.getDelayForAttempt(0);
      expect(delay0.inMilliseconds, inInclusiveRange(750, 1250));

      // Second attempt: ~2 seconds (with jitter)
      final delay1 = config.getDelayForAttempt(1);
      expect(delay1.inMilliseconds, inInclusiveRange(1500, 2500));

      // Third attempt: ~4 seconds (with jitter)
      final delay2 = config.getDelayForAttempt(2);
      expect(delay2.inMilliseconds, inInclusiveRange(3000, 5000));
    });

    test('should cap delay at maxDelay', () {
      const config = RetryConfig(
        initialDelay: Duration(seconds: 1),
        maxDelay: Duration(seconds: 2),
        backoffMultiplier: 10.0,
      );

      // Should be capped at 2 seconds even with high multiplier
      final delay = config.getDelayForAttempt(5);
      expect(delay.inMilliseconds, lessThanOrEqualTo(2500)); // 2s + 25% jitter
    });
  });

  group('YouTubeApiException', () {
    test('should identify rate limit errors', () {
      final rateLimitException = YouTubeApiException(
        statusCode: 429,
        message: 'Rate limit exceeded',
        isRateLimitError: true,
        isRetryable: true,
      );
      expect(rateLimitException.isRateLimitError, isTrue);
      expect(rateLimitException.isRetryable, isTrue);
    });

    test('should identify auth errors', () {
      final authException = YouTubeApiException(
        statusCode: 401,
        message: 'Unauthorized',
        isAuthError: true,
      );
      expect(authException.isAuthError, isTrue);
    });

    test('should format toString correctly', () {
      final exception = YouTubeApiException(
        statusCode: 403,
        message: 'Quota exceeded',
        reason: 'quotaExceeded',
      );
      expect(
        exception.toString(),
        'YouTubeApiException(403): Quota exceeded (quotaExceeded)',
      );
    });
  });

  group('SyncState', () {
    test('should serialize to JSON', () {
      final syncState = SyncState(
        channelId: 'channel123',
        lastSyncTime: DateTime(2024, 1, 15, 10, 30),
        lastVideoId: 'video123',
        videoLastSync: {
          'video1': DateTime(2024, 1, 14),
          'video2': DateTime(2024, 1, 15),
        },
      );

      final json = syncState.toJson();
      expect(json['channelId'], 'channel123');
      expect(json['lastVideoId'], 'video123');
      expect(json['videoLastSync'], isA<Map>());
    });

    test('should deserialize from JSON', () {
      final json = {
        'channelId': 'channel123',
        'lastSyncTime': '2024-01-15T10:30:00.000',
        'lastVideoId': 'video123',
        'videoLastSync': {
          'video1': '2024-01-14T00:00:00.000',
        },
      };

      final syncState = SyncState.fromJson(json);
      expect(syncState.channelId, 'channel123');
      expect(syncState.lastVideoId, 'video123');
      expect(syncState.videoLastSync, hasLength(1));
    });

    test('should create with copyWith', () {
      final original = SyncState(channelId: 'channel1');
      final updated = original.copyWith(channelId: 'channel2');

      expect(original.channelId, 'channel1');
      expect(updated.channelId, 'channel2');
    });
  });

  group('YouTubeAuthResult', () {
    test('should create success result', () {
      final user = YouTubeUser(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      final result = YouTubeAuthResult.success(
        user: user,
        accessToken: 'token123',
        tokenExpiry: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(result.success, isTrue);
      expect(result.user, isNotNull);
      expect(result.accessToken, 'token123');
    });

    test('should create failure result', () {
      final result = YouTubeAuthResult.failure('Sign-in was cancelled');

      expect(result.success, isFalse);
      expect(result.message, 'Sign-in was cancelled');
      expect(result.user, isNull);
    });
  });

  group('YouTubeVideo', () {
    test('should parse from JSON', () {
      final json = {
        'id': 'video123',
        'snippet': {
          'title': 'Test Video',
          'description': 'A test video',
          'channelId': 'channel123',
          'channelTitle': 'Test Channel',
          'publishedAt': '2024-01-15T10:00:00.000Z',
          'thumbnails': {
            'high': {'url': 'https://example.com/thumb.jpg'},
          },
        },
        'statistics': {
          'viewCount': '1000',
          'likeCount': '50',
          'commentCount': '10',
        },
      };

      final video = YouTubeVideo.fromJson(json);
      expect(video.id, 'video123');
      expect(video.title, 'Test Video');
      expect(video.channelTitle, 'Test Channel');
      expect(video.viewCount, 1000);
      expect(video.likeCount, 50);
      expect(video.commentCount, 10);
    });

    test('should handle missing statistics', () {
      final json = {
        'id': 'video123',
        'snippet': {
          'title': 'Test Video',
          'description': 'A test video',
          'channelId': 'channel123',
          'channelTitle': 'Test Channel',
          'publishedAt': '2024-01-15T10:00:00.000Z',
        },
      };

      final video = YouTubeVideo.fromJson(json);
      expect(video.viewCount, isNull);
      expect(video.likeCount, isNull);
    });
  });

  group('YouTubeChannel', () {
    test('should parse from JSON', () {
      final json = {
        'id': 'channel123',
        'snippet': {
          'title': 'Test Channel',
          'description': 'A test channel',
          'thumbnails': {
            'high': {'url': 'https://example.com/avatar.jpg'},
          },
        },
        'contentDetails': {
          'relatedPlaylists': {
            'uploads': 'UUchannel123',
          },
        },
        'statistics': {
          'subscriberCount': '10000',
          'videoCount': '50',
        },
      };

      final channel = YouTubeChannel.fromJson(json);
      expect(channel.id, 'channel123');
      expect(channel.title, 'Test Channel');
      expect(channel.uploadsPlaylistId, 'UUchannel123');
      expect(channel.subscriberCount, 10000);
      expect(channel.videoCount, 50);
    });
  });

  group('YouTubePaginatedResponse', () {
    test('should correctly report pagination state', () {
      final responseWithNext = YouTubePaginatedResponse<String>(
        items: ['a', 'b', 'c'],
        nextPageToken: 'next_token',
        totalResults: 100,
      );
      expect(responseWithNext.hasNextPage, isTrue);
      expect(responseWithNext.hasPreviousPage, isFalse);

      final responseWithPrev = YouTubePaginatedResponse<String>(
        items: ['a', 'b', 'c'],
        prevPageToken: 'prev_token',
      );
      expect(responseWithPrev.hasPreviousPage, isTrue);
      expect(responseWithPrev.hasNextPage, isFalse);
    });
  });
}
