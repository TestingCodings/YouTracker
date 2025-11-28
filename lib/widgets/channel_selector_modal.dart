import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/channel.dart';
import '../providers/channel_provider.dart';

/// Modal for managing and switching between channels.
class ChannelSelectorModal extends ConsumerStatefulWidget {
  const ChannelSelectorModal({super.key});

  @override
  ConsumerState<ChannelSelectorModal> createState() => _ChannelSelectorModalState();
}

class _ChannelSelectorModalState extends ConsumerState<ChannelSelectorModal> {
  bool _isEditing = false;
  String? _editingChannelId;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channelState = ref.watch(channelProvider);

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
                    'Channels',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(width: 8),
                  Badge(
                    label: Text('${channelState.channels.length}'),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddChannelDialog(context),
                    tooltip: 'Add Channel',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _buildChannelsList(
                channelState,
                scrollController,
                theme,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChannelsList(
    ChannelState state,
    ScrollController scrollController,
    ThemeData theme,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: theme.colorScheme.secondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No channels added',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a YouTube channel to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddChannelDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Channel'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.channels.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final channel = state.channels[index];
        final isActive = channel.id == state.activeChannel?.id;

        return _buildChannelTile(channel, isActive, theme);
      },
    );
  }

  Widget _buildChannelTile(Channel channel, bool isActive, ThemeData theme) {
    final isEditing = _isEditing && _editingChannelId == channel.id;

    return ListTile(
      leading: _buildAvatar(channel, isActive, theme),
      title: isEditing
          ? TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _saveChannelName(channel),
            )
          : Text(
              channel.name,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
      subtitle: Row(
        children: [
          _buildConnectionIndicator(channel.connectionState, theme),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              channel.email ?? channel.provider,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: isEditing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => _saveChannelName(channel),
                  tooltip: 'Save',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelEditing,
                  tooltip: 'Cancel',
                ),
              ],
            )
          : PopupMenuButton<String>(
              itemBuilder: (context) => [
                if (!isActive)
                  const PopupMenuItem(
                    value: 'activate',
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline),
                      title: Text('Set as Active'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit Name'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: ListTile(
                    leading: Icon(Icons.refresh),
                    title: Text('Refresh Token'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Remove', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) => _handleMenuAction(value, channel),
            ),
      onTap: isEditing ? null : () => _activateChannel(channel),
      selected: isActive,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
    );
  }

  Widget _buildAvatar(Channel channel, bool isActive, ThemeData theme) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
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
                  ),
                )
              : null,
        ),
        if (isActive)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConnectionIndicator(
    ChannelConnectionState state,
    ThemeData theme,
  ) {
    final (color, icon) = switch (state) {
      ChannelConnectionState.connected => (Colors.green, Icons.cloud_done),
      ChannelConnectionState.connecting => (Colors.orange, Icons.cloud_sync),
      ChannelConnectionState.disconnected => (Colors.grey, Icons.cloud_off),
      ChannelConnectionState.error => (Colors.red, Icons.error_outline),
      ChannelConnectionState.tokenExpired => (Colors.orange, Icons.warning_amber),
    };

    return Icon(icon, size: 14, color: color);
  }

  void _handleMenuAction(String action, Channel channel) {
    switch (action) {
      case 'activate':
        _activateChannel(channel);
        break;
      case 'edit':
        _startEditing(channel);
        break;
      case 'refresh':
        _refreshToken(channel);
        break;
      case 'remove':
        _confirmRemoveChannel(channel);
        break;
    }
  }

  void _activateChannel(Channel channel) {
    ref.read(channelProvider.notifier).setActiveChannel(channel.id);
    Navigator.pop(context);
  }

  void _startEditing(Channel channel) {
    setState(() {
      _isEditing = true;
      _editingChannelId = channel.id;
      _nameController.text = channel.name;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editingChannelId = null;
      _nameController.clear();
    });
  }

  void _saveChannelName(Channel channel) {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != channel.name) {
      ref.read(channelProvider.notifier).updateChannelName(
        channel.id,
        newName,
      );
    }
    _cancelEditing();
  }

  void _refreshToken(Channel channel) {
    ref.read(channelProvider.notifier).refreshChannelToken(channel.id);
  }

  void _confirmRemoveChannel(Channel channel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Channel'),
        content: Text(
          'Are you sure you want to remove "${channel.name}"? '
          'This will delete all local data associated with this channel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(channelProvider.notifier).removeChannel(channel.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddChannelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddChannelDialog(),
    );
  }
}

class _AddChannelDialog extends ConsumerWidget {
  const _AddChannelDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add Channel'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Connect your YouTube channel to track comments and analytics.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ref.read(channelProvider.notifier).addChannelWithGoogle();
            },
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Sign in with Google'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Shows the channel selector modal.
void showChannelSelector(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const ChannelSelectorModal(),
  );
}
