import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/motion_spec.dart';

/// A card widget for displaying a comment in a list with Hero animation support.
class CommentCard extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;
  final bool showSentimentBadge;
  final bool enableHeroAnimation;

  const CommentCard({
    super.key,
    required this.comment,
    this.onTap,
    this.onBookmarkTap,
    this.showSentimentBadge = true,
    this.enableHeroAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToxic = comment.isToxic ?? false;
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    Widget cardContent = _CommentCardContent(
      comment: comment,
      onTap: onTap,
      onBookmarkTap: onBookmarkTap,
      showSentimentBadge: showSentimentBadge,
      isToxic: isToxic,
      theme: theme,
    );

    // Wrap with Hero for smooth transitions
    if (enableHeroAnimation && !reduceMotion) {
      cardContent = Hero(
        tag: 'comment-${comment.id}',
        flightShuttleBuilder: (
          BuildContext flightContext,
          Animation<double> animation,
          HeroFlightDirection flightDirection,
          BuildContext fromHeroContext,
          BuildContext toHeroContext,
        ) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.cardBorderRadius,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(
                          alpha: 0.1 * animation.value,
                        ),
                        blurRadius: 8 * animation.value,
                        offset: Offset(0, 4 * animation.value),
                      ),
                    ],
                  ),
                  child: toHeroContext.widget,
                ),
              );
            },
          );
        },
        child: cardContent,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.df,
        vertical: AppSpacing.sm,
      ),
      child: cardContent,
    );
  }
}

class _CommentCardContent extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;
  final bool showSentimentBadge;
  final bool isToxic;
  final ThemeData theme;

  const _CommentCardContent({
    required this.comment,
    this.onTap,
    this.onBookmarkTap,
    required this.showSentimentBadge,
    required this.isToxic,
    required this.theme,
  });

  @override
  State<_CommentCardContent> createState() => _CommentCardContentState();
}

class _CommentCardContentState extends State<_CommentCardContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: MotionSpec.durationShort,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: MotionSpec.curveStandard,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    Widget card = Card(
      margin: EdgeInsets.zero,
      shape: widget.isToxic
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardBorderRadius),
              side: BorderSide(
                color: widget.theme.colorScheme.error,
                width: 2,
              ),
            )
          : null,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: reduceMotion ? null : _handleTapDown,
        onTapUp: reduceMotion ? null : _handleTapUp,
        onTapCancel: reduceMotion ? null : _handleTapCancel,
        borderRadius: BorderRadius.circular(AppSpacing.cardBorderRadius),
        child: Padding(
          padding: AppSpacing.paddingDf,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video info row with Hero for avatar
              Row(
                children: [
                  // Video thumbnail placeholder
                  Container(
                    width: 80,
                    height: 45,
                    decoration: BoxDecoration(
                      color: widget.theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    child: Icon(
                      Icons.play_circle_outline,
                      color: widget.theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.comment.videoTitle,
                          style: widget.theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          widget.comment.channelName,
                          style: widget.theme.textTheme.bodySmall?.copyWith(
                            color: widget.theme.colorScheme.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Animated bookmark icon
                  _AnimatedBookmarkButton(
                    isBookmarked: widget.comment.isBookmarked,
                    onTap: widget.onBookmarkTap,
                    primaryColor: widget.theme.colorScheme.primary,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              SizedBox(height: AppSpacing.md),
              // Sentiment badge row
              if (widget.showSentimentBadge && widget.comment.sentimentLabel != null) ...[
                Row(
                  children: [
                    _SentimentBadge(
                      label: widget.comment.sentimentLabel!,
                      score: widget.comment.sentimentScore,
                    ),
                    if (widget.isToxic) ...[
                      SizedBox(width: AppSpacing.sm),
                      _ToxicWarningBadge(score: widget.comment.toxicScore),
                    ],
                    if (widget.comment.needsReply == true) ...[
                      SizedBox(width: AppSpacing.sm),
                      _NeedsReplyBadge(),
                    ],
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
              ],
              // Comment text
              Text(
                widget.comment.text,
                style: widget.theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.md),
              // Stats row
              Row(
                children: [
                  _buildStatItem(
                    context,
                    Icons.thumb_up_outlined,
                    widget.comment.likeCount.toString(),
                  ),
                  SizedBox(width: AppSpacing.df),
                  _buildStatItem(
                    context,
                    Icons.comment_outlined,
                    widget.comment.replyCount.toString(),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(widget.comment.publishedAt),
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      color: widget.theme.colorScheme.secondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (reduceMotion) {
      return card;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: card,
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppSpacing.iconSizeSmall,
          color: widget.theme.colorScheme.secondary.withValues(alpha: 0.7),
        ),
        SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: widget.theme.textTheme.bodySmall?.copyWith(
            color: widget.theme.colorScheme.secondary.withValues(alpha: 0.7),
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

/// Animated bookmark button with bounce effect.
class _AnimatedBookmarkButton extends StatefulWidget {
  final bool isBookmarked;
  final VoidCallback? onTap;
  final Color primaryColor;

  const _AnimatedBookmarkButton({
    required this.isBookmarked,
    this.onTap,
    required this.primaryColor,
  });

  @override
  State<_AnimatedBookmarkButton> createState() => _AnimatedBookmarkButtonState();
}

class _AnimatedBookmarkButtonState extends State<_AnimatedBookmarkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionSpec.durationMedium,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.4),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 0.9),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.0),
        weight: 30,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: MotionSpec.curveEmphasized,
    ));
  }

  @override
  void didUpdateWidget(_AnimatedBookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBookmarked && !oldWidget.isBookmarked) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MotionSpec.shouldReduceMotion(context);
    
    Widget icon = AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : MotionSpec.durationShort,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Icon(
        widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        key: ValueKey(widget.isBookmarked),
        color: widget.isBookmarked ? widget.primaryColor : null,
      ),
    );

    if (!reduceMotion) {
      icon = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: icon,
      );
    }

    return IconButton(
      icon: icon,
      onPressed: widget.onTap,
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
