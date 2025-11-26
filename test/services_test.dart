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
      apiService = CommentApiService();
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

    test('should return bookmarked comments', () async {
      final bookmarked = await apiService.getBookmarkedComments();

      for (final comment in bookmarked) {
        expect(comment.isBookmarked, isTrue);
      }
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
}
