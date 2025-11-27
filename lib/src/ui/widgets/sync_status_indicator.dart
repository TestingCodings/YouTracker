import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_status_provider.dart';
import '../sync/sync_engine.dart';

/// Compact sync status indicator for AppBar.
class SyncStatusIndicator extends ConsumerWidget {
  /// Whether to show the sync count badge.
  final bool showBadge;

  /// Callback when tapped.
  final VoidCallback? onTap;

  const SyncStatusIndicator({
    super.key,
    this.showBadge = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            _buildIcon(context, syncStatus),
            if (showBadge && syncStatus.hasPendingOperations)
              Positioned(
                right: 0,
                top: 0,
                child: _buildBadge(context, syncStatus.pendingOperations),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, SyncStatusState status) {
    final theme = Theme.of(context);

    if (status.isSyncing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: status.progress > 0 ? status.progress : null,
          color: theme.colorScheme.primary,
        ),
      );
    }

    IconData icon;
    Color color;

    switch (status.state) {
      case SyncState.idle:
      case SyncState.upToDate:
        icon = Icons.cloud_done_outlined;
        color = theme.colorScheme.primary;
      case SyncState.error:
        icon = Icons.cloud_off_outlined;
        color = theme.colorScheme.error;
      case SyncState.offline:
        icon = Icons.cloud_off_outlined;
        color = theme.colorScheme.outline;
      case SyncState.syncing:
        icon = Icons.sync;
        color = theme.colorScheme.primary;
    }

    return Icon(icon, color: color, size: 24);
  }

  Widget _buildBadge(BuildContext context, int count) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(
        minWidth: 14,
        minHeight: 14,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Animated sync indicator that shows during sync operations.
class AnimatedSyncIndicator extends ConsumerStatefulWidget {
  final double size;

  const AnimatedSyncIndicator({
    super.key,
    this.size = 24,
  });

  @override
  ConsumerState<AnimatedSyncIndicator> createState() =>
      _AnimatedSyncIndicatorState();
}

class _AnimatedSyncIndicatorState extends ConsumerState<AnimatedSyncIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(syncStatusProvider);
    final theme = Theme.of(context);

    if (syncStatus.isSyncing) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.reset();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Icon(
            Icons.sync,
            size: widget.size,
            color: syncStatus.isSyncing
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        );
      },
    );
  }
}

/// Sync status chip for inline display.
class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (syncStatus.state) {
      case SyncState.idle:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        label = 'Idle';
        icon = Icons.cloud_outlined;
      case SyncState.syncing:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        label = 'Syncing...';
        icon = Icons.sync;
      case SyncState.error:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        label = 'Error';
        icon = Icons.error_outline;
      case SyncState.offline:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.outline;
        label = 'Offline';
        icon = Icons.cloud_off_outlined;
      case SyncState.upToDate:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        label = 'Up to date';
        icon = Icons.cloud_done_outlined;
    }

    return Chip(
      avatar: syncStatus.isSyncing
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            )
          : Icon(icon, size: 16, color: textColor),
      label: Text(label, style: TextStyle(color: textColor)),
      backgroundColor: backgroundColor,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

/// Simple text display of last sync time.
class LastSyncedText extends ConsumerWidget {
  final TextStyle? style;

  const LastSyncedText({super.key, this.style});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final theme = Theme.of(context);

    final lastSynced = syncStatus.lastSyncedAt;
    final text = lastSynced != null
        ? 'Last synced: ${_formatTime(lastSynced)}'
        : 'Never synced';

    return Text(
      text,
      style: style ??
          theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
