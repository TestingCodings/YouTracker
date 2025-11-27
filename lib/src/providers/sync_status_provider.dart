import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/sync_engine.dart';

/// Provider for the sync engine instance.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine.instance;
});

/// Provider for sync status updates.
final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatusState>((ref) {
  final syncEngine = ref.watch(syncEngineProvider);
  return SyncStatusNotifier(syncEngine);
});

/// State for sync status.
class SyncStatusState {
  final SyncState state;
  final double progress;
  final DateTime? lastSyncedAt;
  final String? lastError;
  final int pendingOperations;
  final int failedOperations;
  final bool isInitialized;

  const SyncStatusState({
    this.state = SyncState.idle,
    this.progress = 0.0,
    this.lastSyncedAt,
    this.lastError,
    this.pendingOperations = 0,
    this.failedOperations = 0,
    this.isInitialized = false,
  });

  SyncStatusState copyWith({
    SyncState? state,
    double? progress,
    DateTime? lastSyncedAt,
    String? lastError,
    int? pendingOperations,
    int? failedOperations,
    bool? isInitialized,
  }) {
    return SyncStatusState(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError ?? this.lastError,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      failedOperations: failedOperations ?? this.failedOperations,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  /// Whether sync is currently in progress.
  bool get isSyncing => state == SyncState.syncing;

  /// Whether there are pending operations to sync.
  bool get hasPendingOperations => pendingOperations > 0;

  /// Whether there are failed operations.
  bool get hasFailedOperations => failedOperations > 0;

  /// Whether the sync is up to date.
  bool get isUpToDate =>
      state == SyncState.upToDate || state == SyncState.idle;

  /// Whether the device is offline.
  bool get isOffline => state == SyncState.offline;

  /// Whether there was a sync error.
  bool get hasError => state == SyncState.error;

  /// Human-readable status text.
  String get statusText {
    switch (state) {
      case SyncState.idle:
        return 'Idle';
      case SyncState.syncing:
        return 'Syncing...';
      case SyncState.error:
        return 'Sync error';
      case SyncState.offline:
        return 'Offline';
      case SyncState.upToDate:
        return 'Up to date';
    }
  }

  @override
  String toString() {
    return 'SyncStatusState(state: $state, pending: $pendingOperations, failed: $failedOperations)';
  }
}

/// Notifier for sync status updates.
class SyncStatusNotifier extends StateNotifier<SyncStatusState> {
  final SyncEngine _syncEngine;
  StreamSubscription<SyncStatus>? _subscription;

  SyncStatusNotifier(this._syncEngine) : super(const SyncStatusState()) {
    _initialize();
  }

  void _initialize() {
    // Subscribe to sync engine status updates
    _subscription = _syncEngine.statusStream.listen((status) {
      state = state.copyWith(
        state: status.state,
        progress: status.progress,
        lastSyncedAt: status.lastSyncedAt,
        lastError: status.lastError,
        pendingOperations: status.pendingOperations,
        failedOperations: status.failedOperations,
        isInitialized: true,
      );
    });

    // Initialize with current status
    final currentStatus = _syncEngine.currentStatus;
    state = state.copyWith(
      state: currentStatus.state,
      progress: currentStatus.progress,
      lastSyncedAt: currentStatus.lastSyncedAt,
      lastError: currentStatus.lastError,
      pendingOperations: currentStatus.pendingOperations,
      failedOperations: currentStatus.failedOperations,
    );
  }

  /// Triggers an immediate sync.
  Future<SyncResult> syncNow() async {
    return _syncEngine.syncNow();
  }

  /// Forces a full sync.
  Future<SyncResult> forceFullSync() async {
    return _syncEngine.forceFullSync();
  }

  /// Gets the sync queue length.
  int get queueLength => _syncEngine.syncQueue.queueLength;

  /// Gets the dead letter queue length.
  int get deadLetterLength => _syncEngine.syncQueue.deadLetterLength;

  /// Retries all failed operations.
  Future<int> retryAllFailed() async {
    return _syncEngine.syncQueue.retryAllDeadLetter();
  }

  /// Clears completed operations from the queue.
  Future<int> clearCompleted() async {
    return _syncEngine.syncQueue.clearCompleted();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for accessing sync queue status.
final syncQueueStatusProvider = Provider<SyncQueueStatusInfo>((ref) {
  final syncStatus = ref.watch(syncStatusProvider);
  return SyncQueueStatusInfo(
    pendingCount: syncStatus.pendingOperations,
    failedCount: syncStatus.failedOperations,
    isSyncing: syncStatus.isSyncing,
  );
});

/// Simplified sync queue status info.
class SyncQueueStatusInfo {
  final int pendingCount;
  final int failedCount;
  final bool isSyncing;

  const SyncQueueStatusInfo({
    this.pendingCount = 0,
    this.failedCount = 0,
    this.isSyncing = false,
  });

  bool get hasOperations => pendingCount > 0 || failedCount > 0;

  @override
  String toString() {
    return 'SyncQueueStatusInfo(pending: $pendingCount, failed: $failedCount)';
  }
}
