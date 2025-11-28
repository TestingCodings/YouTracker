import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/motion_spec.dart';

/// A tile widget for displaying an interaction notification with animations.
class InteractionTile extends StatefulWidget {
  final Interaction interaction;
  final VoidCallback? onTap;

  const InteractionTile({
    super.key,
    required this.interaction,
    this.onTap,
  });

  @override
  State<InteractionTile> createState() => _InteractionTileState();
}

class _InteractionTileState extends State<InteractionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionSpec.durationMedium,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: MotionSpec.curveDecelerate,
    );
    
    // Delay animation for staggered effect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasAnimated) {
        _hasAnimated = true;
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    Widget tile = ListTile(
      onTap: widget.onTap,
      leading: _buildLeadingIcon(context),
      title: Text(
        widget.interaction.displayText,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: widget.interaction.isRead ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: widget.interaction.replyText != null
          ? Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                widget.interaction.replyText!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatDate(widget.interaction.timestamp),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary.withValues(alpha: 0.7),
            ),
          ),
          if (!widget.interaction.isRead)
            AnimatedContainer(
              duration: reduceMotion ? Duration.zero : MotionSpec.durationShort,
              margin: EdgeInsets.only(top: AppSpacing.xs),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      tileColor: widget.interaction.isRead
          ? null
          : theme.colorScheme.primary.withValues(alpha: 0.05),
    );

    if (reduceMotion) {
      return tile;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(_fadeAnimation),
        child: tile,
      ),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;

    switch (widget.interaction.type) {
      case InteractionType.like:
        icon = Icons.thumb_up;
        color = Colors.blue;
        break;
      case InteractionType.reply:
        icon = Icons.reply;
        color = Colors.green;
        break;
      case InteractionType.mention:
        icon = Icons.alternate_email;
        color = Colors.orange;
        break;
      case InteractionType.heart:
        icon = Icons.favorite;
        color = theme.colorScheme.primary;
        break;
    }

    return CircleAvatar(
      radius: AppSpacing.avatarSizeSmall / 2,
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color, size: AppSpacing.iconSizeMedium - 4),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }
}
