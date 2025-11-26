import 'package:flutter/material.dart';

import '../models/models.dart';

/// A tile widget for displaying an interaction notification.
class InteractionTile extends StatelessWidget {
  final Interaction interaction;
  final VoidCallback? onTap;

  const InteractionTile({
    super.key,
    required this.interaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: _buildLeadingIcon(context),
      title: Text(
        interaction.displayText,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: interaction.isRead ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: interaction.replyText != null
          ? Text(
              interaction.replyText!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatDate(interaction.timestamp),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary.withValues(alpha: 0.7),
            ),
          ),
          if (!interaction.isRead)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      tileColor: interaction.isRead
          ? null
          : theme.colorScheme.primary.withValues(alpha: 0.05),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;

    switch (interaction.type) {
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
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color, size: 20),
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
