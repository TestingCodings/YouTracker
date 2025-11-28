import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/motion_spec.dart';
import '../widgets/widgets.dart';

/// Screen showing details of a specific comment with Hero animation support.
class CommentDetailScreen extends ConsumerWidget {
  final String commentId;

  const CommentDetailScreen({
    super.key,
    required this.commentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentAsync = ref.watch(commentDetailProvider(commentId));
    final theme = Theme.of(context);

    return Scaffold(
      body: commentAsync.when(
        data: (comment) {
          if (comment == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Comment Details'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              ),
              body: const ErrorMessage(
                message: 'Comment not found',
              ),
            );
          }
          return _CommentDetailContent(comment: comment, commentId: commentId);
        },
        loading: () => Scaffold(
          appBar: AppBar(
            title: const Text('Comment Details'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: const LoadingIndicator(message: 'Loading comment...'),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Comment Details'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: ErrorMessage(
            message: error.toString(),
            onRetry: () => ref.invalidate(commentDetailProvider(commentId)),
          ),
        ),
      ),
    );
  }
}

class _CommentDetailContent extends ConsumerWidget {
  final Comment comment;
  final String commentId;

  const _CommentDetailContent({
    required this.comment,
    required this.commentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final interactionsAsync =
        ref.watch(commentInteractionsProvider(comment.id));
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // Sliver app bar
        SliverAppBar(
          expandedHeight: 100,
          floating: false,
          pinned: true,
          stretch: true,
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
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.fadeTitle,
            ],
            centerTitle: false,
            titlePadding: EdgeInsets.only(
              left: AppSpacing.df + 48, // Account for back button
              bottom: AppSpacing.df,
            ),
            title: Text(
              'Comment Details',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.06),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: AppSpacing.paddingDf,
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Video info card
              _buildVideoInfoCard(theme),
              SizedBox(height: AppSpacing.df),

              // Comment card with Hero
              _buildCommentCard(context, ref, theme, reduceMotion),
              SizedBox(height: AppSpacing.lg),

              // Interactions section
              Text(
                'Recent Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.md),

              interactionsAsync.when(
                data: (interactions) => _buildInteractionsCard(
                  context,
                  theme,
                  interactions,
                ),
                loading: () => Card(
                  child: Padding(
                    padding: AppSpacing.paddingLg,
                    child: const LoadingIndicator(),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: AppSpacing.paddingLg,
                    child: Text('Error loading activity: $error'),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // Actions
              _buildActionsRow(context, theme),
              SizedBox(height: AppSpacing.xl),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingDf,
        child: Row(
          children: [
            // Video thumbnail placeholder
            Container(
              width: 120,
              height: 68,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(
                Icons.play_circle_outline,
                color: theme.colorScheme.primary,
                size: 40,
              ),
            ),
            SizedBox(width: AppSpacing.df),
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
                  SizedBox(height: AppSpacing.xs),
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
    );
  }

  Widget _buildCommentCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool reduceMotion,
  ) {
    Widget cardContent = Card(
      child: Padding(
        padding: AppSpacing.paddingDf,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info with Hero for avatar
            Row(
              children: [
                // Hero-wrapped avatar
                Hero(
                  tag: 'comment-avatar-${comment.id}',
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
                SizedBox(width: AppSpacing.md),
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
                AnimatedToggleIconButton(
                  inactiveIcon: Icons.bookmark_border,
                  activeIcon: Icons.bookmark,
                  isActive: comment.isBookmarked,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (isActive) {
                    ref
                        .read(commentsProvider.notifier)
                        .toggleBookmark(comment.id);
                  },
                ),
              ],
            ),
            SizedBox(height: AppSpacing.df),
            const Divider(),
            SizedBox(height: AppSpacing.df),

            // Comment text
            Text(
              comment.text,
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: AppSpacing.df),

            // Stats with animated appearance
            Row(
              children: [
                _buildStatChip(
                  context,
                  Icons.thumb_up,
                  '${comment.likeCount} likes',
                ),
                SizedBox(width: AppSpacing.md),
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
    );

    // Wrap entire card with Hero for smooth transition
    if (!reduceMotion) {
      cardContent = Hero(
        tag: 'comment-${comment.id}',
        flightShuttleBuilder: (
          BuildContext flightContext,
          Animation<double> animation,
          HeroFlightDirection flightDirection,
          BuildContext fromHeroContext,
          BuildContext toHeroContext,
        ) {
          return Material(
            color: Colors.transparent,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.cardBorderRadius,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(
                          alpha: 0.15 * animation.value,
                        ),
                        blurRadius: 12 * animation.value,
                        offset: Offset(0, 4 * animation.value),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: cardContent,
            ),
          );
        },
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildInteractionsCard(
    BuildContext context,
    ThemeData theme,
    List<Interaction> interactions,
  ) {
    if (interactions.isEmpty) {
      return Card(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.timeline_outlined,
                  size: 48,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                ),
                SizedBox(height: AppSpacing.md),
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
  }

  Widget _buildActionsRow(BuildContext context, ThemeData theme) {
    return Row(
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
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm - 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.chipBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppSpacing.iconSizeSmall,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: AppSpacing.sm - 2),
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
