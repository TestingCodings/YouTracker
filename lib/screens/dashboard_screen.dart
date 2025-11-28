import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../src/design_tokens.dart';
import '../src/providers/sync_status_provider.dart';
import '../src/ui/widgets/sync_status_indicator.dart';
import '../widgets/widgets.dart';

/// Dashboard screen showing comments with sliver-based scrolling.
/// Uses CustomScrollView with SliverAppBar for smooth, stretchy scroll effects.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize channel provider and fetch comments when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelProvider.notifier).initialize();
      ref.read(commentsProvider.notifier).fetchComments();
    });
  }

  Future<void> _handleRefresh() async {
    // Trigger sync and refresh comments
    final syncNotifier = ref.read(syncStatusProvider.notifier);
    await syncNotifier.syncNow();
    await ref.read(commentsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        edgeOffset: kToolbarHeight + MediaQuery.of(context).padding.top,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Sliver App Bar with stretch effect
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('YouTracker'),
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.fadeTitle,
                ],
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        Theme.of(context).colorScheme.surface,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                // Channel dropdown
                const ChannelDropdownCompact(),
                // Sync status indicator
                SyncStatusIndicator(
                  onTap: () => context.push('/sync-status'),
                ),
                IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  onPressed: () => context.push('/analytics'),
                  tooltip: 'Analytics Dashboard',
                ),
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

            // Search bar as sliver
            SliverToBoxAdapter(
              child: SearchBarWidget(
                initialValue: commentsState.searchQuery,
                onSearch: (query) {
                  ref.read(commentsProvider.notifier).search(query);
                },
                onClear: () {
                  ref.read(commentsProvider.notifier).clearSearch();
                },
              ),
            ),

            // Stats row as sliver
            SliverToBoxAdapter(
              child: _buildStatsRow(commentsState),
            ),

            // Comments list as sliver
            _buildCommentsSliver(commentsState),

            // Bottom padding
            const SliverPadding(
              padding: EdgeInsets.only(bottom: Spacing.lg),
            ),
          ],
        ),
      ),
      // Pagination controls at bottom
      bottomNavigationBar: commentsState.totalPages > 1
          ? SafeArea(
              child: PaginationControls(
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
            )
          : null,
    );
  }

  Widget _buildStatsRow(CommentsState state) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
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

  Widget _buildCommentsSliver(CommentsState state) {
    if (state.isLoading && state.comments.isEmpty) {
      return const SliverFillRemaining(
        child: LoadingIndicator(message: 'Loading comments...'),
      );
    }

    if (state.error != null && state.comments.isEmpty) {
      return SliverFillRemaining(
        child: ErrorMessage(
          message: state.error!,
          onRetry: () {
            ref.read(commentsProvider.notifier).refresh();
          },
        ),
      );
    }

    if (state.comments.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          icon: Icons.comment_outlined,
          title: state.searchQuery.isNotEmpty
              ? 'No comments found'
              : 'No comments yet',
          subtitle: state.searchQuery.isNotEmpty
              ? 'Try a different search term'
              : 'Your comments will appear here',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
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
          childCount: state.comments.length,
        ),
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
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
