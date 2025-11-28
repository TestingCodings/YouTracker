import 'package:flutter/material.dart';

import '../models/models.dart';
import '../src/design_tokens.dart';

/// A card widget for displaying a comment in a list.
/// Wrapped with Hero for smooth transitions to detail screen.
class CommentCard extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;
  final bool showSentimentBadge;
  
  /// Whether to enable Hero transitions for this card.
  final bool enableHero;

  const CommentCard({
    super.key,
    required this.comment,
    this.onTap,
    this.onBookmarkTap,
    this.showSentimentBadge = true,
    this.enableHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToxic = comment.isToxic ?? false;

    Widget cardContent = Card(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
      shape: isToxic
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.lg),
              side: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video info row
              Row(
                children: [
                  // Video thumbnail placeholder
                  Container(
                    width: 80,
                    height: 45,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Icon(
                      Icons.play_circle_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.videoTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          comment.channelName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Animated bookmark button
                  _AnimatedBookmarkButton(
                    isBookmarked: comment.isBookmarked,
                    onPressed: onBookmarkTap,
                    primaryColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              const Divider(height: 1),
              const SizedBox(height: Spacing.md),
              // Sentiment badge row (if enabled and available)
              if (showSentimentBadge && comment.sentimentLabel != null) ...[
                Row(
                  children: [
                    _SentimentBadge(
                      label: comment.sentimentLabel!,
                      score: comment.sentimentScore,
                    ),
                    if (isToxic) ...[
                      const SizedBox(width: Spacing.sm),
                      _ToxicWarningBadge(score: comment.toxicScore),
                    ],
                    if (comment.needsReply == true) ...[
                      const SizedBox(width: Spacing.sm),
                      _NeedsReplyBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: Spacing.sm),
              ],
              // Comment text
              Text(
                comment.text,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.md),
              // Stats row
              Row(
                children: [
                  _buildStatItem(
                    context,
                    Icons.thumb_up_outlined,
                    comment.likeCount.toString(),
                  ),
                  const SizedBox(width: Spacing.lg),
                  _buildStatItem(
                    context,
                    Icons.comment_outlined,
                    comment.replyCount.toString(),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(comment.publishedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap with Hero for smooth transitions
    if (enableHero) {
      return Hero(
        tag: 'comment-${comment.id}',
        flightShuttleBuilder: _heroFlightShuttleBuilder,
        child: Material(
          type: MaterialType.transparency,
          child: cardContent,
        ),
      );
    }

    return cardContent;
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
            child: flightDirection == HeroFlightDirection.push
                ? toHeroContext.widget
                : fromHeroContext.widget,
          ),
        );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.secondary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Animated bookmark button with scale and icon transition.
class _AnimatedBookmarkButton extends StatelessWidget {
  final bool isBookmarked;
  final VoidCallback? onPressed;
  final Color primaryColor;

  const _AnimatedBookmarkButton({
    required this.isBookmarked,
    this.onPressed,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: Icon(
          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          key: ValueKey(isBookmarked),
          color: isBookmarked ? primaryColor : null,
        ),
      ),
    );
  }
}

/// Badge widget displaying sentiment label with appropriate color.
class _SentimentBadge extends StatelessWidget {
  final String label;
  final double? score;

  const _SentimentBadge({
    required this.label,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon) = _getLabelStyle(label, theme);
    
    // Format score for display: show as percentage for positive, absolute for negative
    String scoreText = '';
    if (score != null) {
      final absScore = score!.abs();
      scoreText = ' (${(absScore * 100).toStringAsFixed(0)}%)';
    }

    return Tooltip(
      message: score != null 
          ? 'Sentiment: ${label.capitalize()}$scoreText'
          : 'Sentiment: ${label.capitalize()}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label.capitalize(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, IconData) _getLabelStyle(String label, ThemeData theme) {
    switch (label.toLowerCase()) {
      case 'positive':
        return (Colors.green, Icons.sentiment_satisfied);
      case 'negative':
        return (Colors.red, Icons.sentiment_dissatisfied);
      case 'question':
        return (Colors.blue, Icons.help_outline);
      case 'needsreply':
      case 'needs_reply':
        return (Colors.orange, Icons.reply);
      case 'neutral':
      default:
        return (Colors.grey, Icons.sentiment_neutral);
    }
  }
}

/// Badge widget for toxic comment warning.
class _ToxicWarningBadge extends StatelessWidget {
  final double? score;

  const _ToxicWarningBadge({this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: score != null
          ? 'Toxic content detected (${(score! * 100).toStringAsFixed(0)}%)'
          : 'Toxic content detected',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Toxic',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge widget for comments that need a reply.
class _NeedsReplyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: 'This comment may need a reply',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.reply, size: 14, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              'Needs Reply',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to capitalize first letter of string.
extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
