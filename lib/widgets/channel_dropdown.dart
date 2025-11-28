import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/channel.dart';
import '../providers/channel_provider.dart';
import 'channel_selector_modal.dart';

/// Compact dropdown in the header showing the active channel.
/// Tapping opens the Channel Selector Modal.
class ChannelDropdown extends ConsumerWidget {
  const ChannelDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelState = ref.watch(channelProvider);
    final activeChannel = channelState.activeChannel;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => showChannelSelector(context),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(activeChannel, theme),
            const SizedBox(width: 8),
            if (activeChannel != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  activeChannel.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              _buildConnectionIndicator(activeChannel.connectionState),
            ] else
              Text(
                'Select Channel',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              size: 20,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Channel? channel, ThemeData theme) {
    if (channel == null) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.2),
        child: Icon(
          Icons.account_circle_outlined,
          size: 20,
          color: theme.colorScheme.secondary,
        ),
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      backgroundImage: channel.avatarUrl != null
          ? NetworkImage(channel.avatarUrl!)
          : null,
      child: channel.avatarUrl == null
          ? Text(
              channel.name.isNotEmpty ? channel.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            )
          : null,
    );
  }

  Widget _buildConnectionIndicator(ChannelConnectionState state) {
    final (color, icon) = switch (state) {
      ChannelConnectionState.connected => (Colors.green, Icons.cloud_done),
      ChannelConnectionState.connecting => (Colors.orange, Icons.sync),
      ChannelConnectionState.disconnected => (Colors.grey, Icons.cloud_off),
      ChannelConnectionState.error => (Colors.red, Icons.error_outline),
      ChannelConnectionState.tokenExpired => (Colors.orange, Icons.warning_amber),
    };

    return Icon(icon, size: 14, color: color);
  }
}

/// A more compact version of the channel dropdown for smaller spaces.
class ChannelDropdownCompact extends ConsumerWidget {
  const ChannelDropdownCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelState = ref.watch(channelProvider);
    final activeChannel = channelState.activeChannel;
    final theme = Theme.of(context);

    return IconButton(
      onPressed: () => showChannelSelector(context),
      tooltip: activeChannel?.name ?? 'Select Channel',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage: activeChannel?.avatarUrl != null
                ? NetworkImage(activeChannel!.avatarUrl!)
                : null,
            child: activeChannel?.avatarUrl == null
                ? Icon(
                    Icons.account_circle,
                    size: 24,
                    color: theme.colorScheme.primary,
                  )
                : null,
          ),
          if (channelState.channels.length > 1)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${channelState.channels.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
