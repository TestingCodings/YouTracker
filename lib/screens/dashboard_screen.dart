import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../src/providers/sync_status_provider.dart';
import '../src/ui/widgets/sync_status_indicator.dart';
import '../theme/motion_spec.dart';
import '../widgets/widgets.dart';

/// Dashboard screen showing comments with search and pagination.
/// Uses sliver-based scrolling for better performance and UX.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize channel provider and fetch comments when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelProvider.notifier).initialize();
      ref.read(commentsProvider.notifier).fetchComments();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger sync and refresh comments
          final syncNotifier = ref.read(syncStatusProvider.notifier);
          await syncNotifier.syncNow();
          await ref.read(commentsProvider.notifier).refresh();
        },
        edgeOffset: kToolbarHeight + MediaQuery.of(context).padding.top,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Sliver app bar with stretch effect
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.fadeTitle,
                ],
                centerTitle: false,
                titlePadding: const EdgeInsets.only(
                  left: AppSpacing.df,
                  bottom: AppSpacing.df,
                ),
                title: Text(
                  'YouTracker',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.08),
                        theme.colorScheme.surface,
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

            // Search bar
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

            // Stats row
            SliverToBoxAdapter(
              child: _buildStatsRow(commentsState),
            ),

            // Comments list
            _buildCommentsSliverList(commentsState),

            // Pagination controls
            if (commentsState.totalPages > 1)
              SliverToBoxAdapter(
                child: PaginationControls(
                  currentPage: commentsState.currentPage,
                  totalPages: commentsState.totalPages,
                  hasNextPage: commentsState.hasNextPage,
                  hasPreviousPage: commentsState.hasPreviousPage,
                  isLoading: commentsState.isLoading,
                  onNextPage: () {
                    ref.read(commentsProvider.notifier).nextPage();
                    // Scroll to top after page change
                    _scrollController.animateTo(
                      0,
                      duration: MotionSpec.durationMedium,
                      curve: MotionSpec.curveStandard,
                    );
                  },
                  onPreviousPage: () {
                    ref.read(commentsProvider.notifier).previousPage();
                    _scrollController.animateTo(
                      0,
                      duration: MotionSpec.durationMedium,
                      curve: MotionSpec.curveStandard,
                    );
                  },
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(CommentsState state) {
    final theme = Theme.of(context);
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : MotionSpec.durationShort,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.df,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : MotionSpec.durationShort,
            child: Text(
              '${state.totalItems} comments',
              key: ValueKey(state.totalItems),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          const Spacer(),
          if (state.searchQuery.isNotEmpty)
            AnimatedOpacity(
              opacity: state.searchQuery.isNotEmpty ? 1.0 : 0.0,
              duration: reduceMotion ? Duration.zero : MotionSpec.durationShort,
              child: Chip(
                label: Text('Search: ${state.searchQuery}'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  ref.read(commentsProvider.notifier).clearSearch();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsSliverList(CommentsState state) {
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

    return SliverList(
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
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.lg)),
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
              margin: EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: AppSpacing.paddingDf,
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: theme.textTheme.titleLarge,
                  ),
                  SizedBox(width: AppSpacing.sm),
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
