import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../src/design_tokens.dart';
import '../widgets/bookmark_button.dart';
import '../widgets/widgets.dart';

/// Screen showing details of a specific comment.
/// Uses Hero animations for smooth transitions from the comment list.
class CommentDetailScreen extends ConsumerWidget {
  final String commentId;

  const CommentDetailScreen({
    super.key,
    required this.commentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentAsync = ref.watch(commentDetailProvider(commentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comment Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share - Coming soon')),
              );
            },
          ),
        ],
      ),
      body: commentAsync.when(
        data: (comment) {
          if (comment == null) {
            return const ErrorMessage(
              message: 'Comment not found',
            );
          }
          return _CommentDetailContent(comment: comment);
        },
        loading: () => const LoadingIndicator(message: 'Loading comment...'),
        error: (error, _) => ErrorMessage(
          message: error.toString(),
          onRetry: () => ref.invalidate(commentDetailProvider(commentId)),
        ),
      ),
    );
  }
}

class _CommentDetailContent extends ConsumerWidget {
  final Comment comment;

  const _CommentDetailContent({required this.comment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final interactionsAsync =
        ref.watch(commentInteractionsProvider(comment.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Row(
                children: [
                  // Video thumbnail placeholder
                  Container(
                    width: 120,
                    height: 68,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Icon(
                      Icons.play_circle_outline,
                      color: theme.colorScheme.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: Spacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.videoTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          comment.channelName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Comment card - wrapped with Hero for transition
          Hero(
            tag: 'comment-${comment.id}',
            flightShuttleBuilder: _heroFlightShuttleBuilder,
            child: Material(
              type: MaterialType.transparency,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author info with Hero avatar
                      Row(
                        children: [
                          // Avatar with Hero
                          Hero(
                            tag: 'avatar-${comment.id}',
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  theme.colorScheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                comment.authorName[0].toUpperCase(),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.authorName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _formatDate(comment.publishedAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Animated bookmark button
                          AnimatedBookmarkButton(
                            isBookmarked: comment.isBookmarked,
                            onPressed: () {
                              ref
                                  .read(commentsProvider.notifier)
                                  .toggleBookmark(comment.id);
                            },
                            primaryColor: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.lg),
                      const Divider(),
                      const SizedBox(height: Spacing.lg),

                      // Comment text
                      Text(
                        comment.text,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: Spacing.lg),

                      // Stats
                      Row(
                        children: [
                          _buildStatChip(
                            context,
                            Icons.thumb_up,
                            '${comment.likeCount} likes',
                          ),
                          const SizedBox(width: Spacing.md),
                          _buildStatChip(
                            context,
                            Icons.comment,
                            '${comment.replyCount} replies',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // Interactions section
          Text(
            'Recent Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),

          interactionsAsync.when(
            data: (interactions) {
              if (interactions.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.xl),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.timeline_outlined,
                            size: 48,
                            color: theme.colorScheme.secondary
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: Spacing.md),
                          Text(
                            'No recent activity',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: interactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return InteractionTile(
                      interaction: interactions[index],
                    );
                  },
                ),
              );
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(Spacing.xl),
                child: LoadingIndicator(),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xl),
                child: Text('Error loading activity: $error'),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('View on YouTube - Coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View on YouTube'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Custom flight shuttle builder for smooth hero transitions.
  Widget _heroFlightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Animate border radius during transition
        final borderRadius = BorderRadiusTween(
          begin: BorderRadius.circular(Radii.lg),
          end: BorderRadius.circular(Radii.lg),
        ).evaluate(animation)!;

        return ClipRRect(
          borderRadius: borderRadius,
          child: Material(
            elevation: Tween<double>(begin: 2.0, end: 0.0).evaluate(animation),
            borderRadius: borderRadius,
            child: flightDirection == HeroFlightDirection.pop
                ? fromHeroContext.widget
                : toHeroContext.widget,
          ),
        );
      },
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm - 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: Spacing.sm - 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
