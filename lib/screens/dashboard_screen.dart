import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/widgets.dart';

/// Dashboard screen showing comments with search and pagination.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch comments when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentsProvider.notifier).fetchComments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotificationsBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          SearchBarWidget(
            initialValue: commentsState.searchQuery,
            onSearch: (query) {
              ref.read(commentsProvider.notifier).search(query);
            },
            onClear: () {
              ref.read(commentsProvider.notifier).clearSearch();
            },
          ),

          // Stats row
          _buildStatsRow(commentsState),

          // Comments list
          Expanded(
            child: _buildCommentsList(commentsState),
          ),

          // Pagination controls
          if (commentsState.totalPages > 1)
            PaginationControls(
              currentPage: commentsState.currentPage,
              totalPages: commentsState.totalPages,
              hasNextPage: commentsState.hasNextPage,
              hasPreviousPage: commentsState.hasPreviousPage,
              isLoading: commentsState.isLoading,
              onNextPage: () {
                ref.read(commentsProvider.notifier).nextPage();
              },
              onPreviousPage: () {
                ref.read(commentsProvider.notifier).previousPage();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(CommentsState state) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${state.totalItems} comments',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const Spacer(),
          if (state.searchQuery.isNotEmpty)
            Chip(
              label: Text('Search: ${state.searchQuery}'),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                ref.read(commentsProvider.notifier).clearSearch();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(CommentsState state) {
    if (state.isLoading && state.comments.isEmpty) {
      return const LoadingIndicator(message: 'Loading comments...');
    }

    if (state.error != null && state.comments.isEmpty) {
      return ErrorMessage(
        message: state.error!,
        onRetry: () {
          ref.read(commentsProvider.notifier).refresh();
        },
      );
    }

    if (state.comments.isEmpty) {
      return EmptyState(
        icon: Icons.comment_outlined,
        title: state.searchQuery.isNotEmpty
            ? 'No comments found'
            : 'No comments yet',
        subtitle: state.searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Your comments will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(commentsProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: state.comments.length,
        itemBuilder: (context, index) {
          final comment = state.comments[index];
          return CommentCard(
            comment: comment,
            onTap: () {
              context.push('/comment/${comment.id}');
            },
            onBookmarkTap: () {
              ref.read(commentsProvider.notifier).toggleBookmark(comment.id);
            },
          );
        },
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _NotificationsBottomSheet(),
    );
  }
}

class _NotificationsBottomSheet extends ConsumerStatefulWidget {
  const _NotificationsBottomSheet();

  @override
  ConsumerState<_NotificationsBottomSheet> createState() =>
      _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState
    extends ConsumerState<_NotificationsBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(interactionsProvider.notifier).fetchInteractions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final interactionsState = ref.watch(interactionsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(width: 8),
                  if (interactionsState.unreadCount > 0)
                    Badge(
                      label: Text('${interactionsState.unreadCount}'),
                    ),
                  const Spacer(),
                  if (interactionsState.unreadCount > 0)
                    TextButton(
                      onPressed: () {
                        ref
                            .read(interactionsProvider.notifier)
                            .markAllAsRead();
                      },
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _buildNotificationsList(
                interactionsState,
                scrollController,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationsList(
    InteractionsState state,
    ScrollController scrollController,
  ) {
    if (state.isLoading && state.interactions.isEmpty) {
      return const LoadingIndicator(message: 'Loading notifications...');
    }

    if (state.interactions.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'No notifications',
        subtitle: "You're all caught up!",
      );
    }

    return ListView.separated(
      controller: scrollController,
      itemCount: state.interactions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final interaction = state.interactions[index];
        return InteractionTile(
          interaction: interaction,
          onTap: () {
            ref
                .read(interactionsProvider.notifier)
                .markAsRead(interaction.id);
            Navigator.pop(context);
            context.push('/comment/${interaction.commentId}');
          },
        );
      },
    );
  }
}
