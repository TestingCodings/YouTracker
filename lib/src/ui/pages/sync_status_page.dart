import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/sync_status_provider.dart';
import '../sync/sync_engine.dart';
import '../widgets/sync_status_indicator.dart';

/// Detailed sync status page with queue info and controls.
class SyncStatusPage extends ConsumerStatefulWidget {
  const SyncStatusPage({super.key});

  @override
  ConsumerState<SyncStatusPage> createState() => _SyncStatusPageState();
}

class _SyncStatusPageState extends ConsumerState<SyncStatusPage> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syncStatus = ref.watch(syncStatusProvider);
    final queueStatus = ref.watch(syncQueueStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Card
            _buildStatusCard(context, syncStatus),

            const SizedBox(height: 16),

            // Queue Stats Card
            _buildQueueStatsCard(context, queueStatus, syncStatus),

            const SizedBox(height: 16),

            // Last Sync Info Card
            _buildLastSyncCard(context, syncStatus),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(context, syncStatus),

            if (syncStatus.hasError) ...[
              const SizedBox(height: 16),
              _buildErrorCard(context, syncStatus),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, SyncStatusState status) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status.state) {
      case SyncState.idle:
        statusColor = theme.colorScheme.outline;
        statusIcon = Icons.cloud_outlined;
        statusText = 'Idle';
      case SyncState.syncing:
        statusColor = theme.colorScheme.primary;
        statusIcon = Icons.sync;
        statusText = 'Syncing...';
      case SyncState.error:
        statusColor = theme.colorScheme.error;
        statusIcon = Icons.error_outline;
        statusText = 'Sync Error';
      case SyncState.offline:
        statusColor = theme.colorScheme.outline;
        statusIcon = Icons.cloud_off_outlined;
        statusText = 'Offline';
      case SyncState.upToDate:
        statusColor = theme.colorScheme.primary;
        statusIcon = Icons.cloud_done_outlined;
        statusText = 'Up to Date';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: status.isSyncing
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        value: status.progress > 0 ? status.progress : null,
                        strokeWidth: 4,
                        color: statusColor,
                      ),
                    )
                  : Icon(
                      statusIcon,
                      size: 40,
                      color: statusColor,
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (status.isSyncing && status.progress > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${(status.progress * 100).toInt()}%',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: statusColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQueueStatsCard(
    BuildContext context,
    SyncQueueStatusInfo queueStatus,
    SyncStatusState syncStatus,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Queue',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    context,
                    icon: Icons.pending_outlined,
                    label: 'Pending',
                    value: syncStatus.pendingOperations.toString(),
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatTile(
                    context,
                    icon: Icons.error_outline,
                    label: 'Failed',
                    value: syncStatus.failedOperations.toString(),
                    color: syncStatus.failedOperations > 0
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastSyncCard(BuildContext context, SyncStatusState status) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Sync',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.schedule_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                status.lastSyncedAt != null
                    ? _formatDateTime(status.lastSyncedAt!)
                    : 'Never synced',
              ),
              subtitle: status.lastSyncedAt != null
                  ? Text(_formatRelativeTime(status.lastSyncedAt!))
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SyncStatusState status) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: status.isSyncing || _isSyncing ? null : _onSyncNow,
          icon: _isSyncing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.sync),
          label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: status.isSyncing ? null : _onForceSync,
          icon: const Icon(Icons.refresh),
          label: const Text('Force Full Sync'),
        ),
        if (status.failedOperations > 0) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: status.isSyncing ? null : _onRetryFailed,
            icon: const Icon(Icons.replay),
            label: Text('Retry Failed (${status.failedOperations})'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context, SyncStatusState status) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Last Error',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              status.lastError ?? 'Unknown error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await _onSyncNow();
  }

  Future<void> _onSyncNow() async {
    setState(() => _isSyncing = true);

    try {
      final notifier = ref.read(syncStatusProvider.notifier);
      final result = await notifier.syncNow();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? 'Sync completed successfully'
                  : 'Sync failed: ${result.error}',
            ),
            backgroundColor: result.success ? null : Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _onForceSync() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Full Sync'),
        content: const Text(
          'This will re-download all data from the server. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(syncStatusProvider.notifier);
      await notifier.forceFullSync();
    }
  }

  Future<void> _onRetryFailed() async {
    final notifier = ref.read(syncStatusProvider.notifier);
    final count = await notifier.retryAllFailed();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Retrying $count failed operations')),
      );
    }
  }

  String _formatDateTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
