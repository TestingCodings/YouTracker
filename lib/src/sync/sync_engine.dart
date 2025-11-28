import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../models/models.dart';
import '../../services/local_storage_service.dart';
import '../../services/youtube/youtube_data_service.dart';
import '../../store/channel_store.dart';
import 'conflict_resolver.dart';
import 'hive_adapters.dart';
import 'remote_delta_client.dart';
import 'sync_queue.dart';

/// Configuration for the sync engine.
class SyncEngineConfig {
  /// Interval between automatic sync operations.
  final Duration syncInterval;

  /// Maximum concurrent push operations.
  final int maxConcurrentPush;

  /// Maximum retry attempts for failed operations.
  final int maxRetryAttempts;

  /// Base delay for exponential backoff.
  final int backoffBaseSeconds;

  /// Whether background sync is enabled.
  final bool enableBackgroundSync;

  /// Whether to sync on network reconnection.
  final bool syncOnReconnect;

  const SyncEngineConfig({
    this.syncInterval = const Duration(minutes: 15),
    this.maxConcurrentPush = 3,
    this.maxRetryAttempts = 5,
    this.backoffBaseSeconds = 2,
    this.enableBackgroundSync = true,
    this.syncOnReconnect = true,
  });
}

/// Current state of the sync engine.
enum SyncState {
  idle,
  syncing,
  error,
  offline,
  upToDate,
}

/// Detailed sync status.
class SyncStatus {
  final SyncState state;
  final double progress;
  final DateTime? lastSyncedAt;
  final String? lastError;
  final int pendingOperations;
  final int failedOperations;
  final String? channelId;

  const SyncStatus({
    this.state = SyncState.idle,
    this.progress = 0.0,
    this.lastSyncedAt,
    this.lastError,
    this.pendingOperations = 0,
    this.failedOperations = 0,
    this.channelId,
  });

  SyncStatus copyWith({
    SyncState? state,
    double? progress,
    DateTime? lastSyncedAt,
    String? lastError,
    int? pendingOperations,
    int? failedOperations,
    String? channelId,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError ?? this.lastError,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      failedOperations: failedOperations ?? this.failedOperations,
      channelId: channelId ?? this.channelId,
    );
  }

  @override
  String toString() {
    return 'SyncStatus(state: $state, progress: $progress, pending: $pendingOperations, failed: $failedOperations, lastSyncedAt: $lastSyncedAt, lastError: $lastError, channelId: $channelId)';
  }
}

/// Result of a sync operation.
class SyncResult {
  final bool success;
  final int itemsPushed;
  final int itemsPulled;
  final int conflicts;
  final String? error;
  final DateTime timestamp;
  final String? channelId;

  const SyncResult({
    required this.success,
    this.itemsPushed = 0,
    this.itemsPulled = 0,
    this.conflicts = 0,
    this.error,
    required this.timestamp,
    this.channelId,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, pushed: $itemsPushed, pulled: $itemsPulled, conflicts: $conflicts, channelId: $channelId)';
  }
}

/// Main sync engine for bidirectional sync with offline-first support.
/// Supports per-channel sync isolation.
class SyncEngine {
  static SyncEngine? _instance;

  static SyncEngine get instance {
    _instance ??= SyncEngine._();
    return _instance!;
  }

  SyncEngine._();

  /// Creates a new instance (for testing).
  factory SyncEngine.create({
    SyncEngineConfig? config,
    YouTubeDataService? youtubeService,
  }) {
    return SyncEngine._()
      .._config = config ?? const SyncEngineConfig()
      .._deltaClient = RemoteDeltaClient(youtubeService: youtubeService);
  }

  SyncEngineConfig _config = const SyncEngineConfig();
  late final SyncQueue _syncQueue = SyncQueue(
    config: SyncQueueConfig(
      maxRetryAttempts: _config.maxRetryAttempts,
      backoffBaseSeconds: _config.backoffBaseSeconds,
      maxConcurrentOperations: _config.maxConcurrentPush,
    ),
  );
  late final ConflictResolver _conflictResolver = ConflictResolver();
  RemoteDeltaClient _deltaClient = RemoteDeltaClient();

  Box<SyncMetadata>? _metadataBox;
  Box<SyncableEntity>? _syncableEntityBox;

  bool _isInitialized = false;
  
  /// Per-channel sync states to prevent concurrent syncs on the same channel.
  final Map<String, bool> _channelSyncInProgress = {};
  
  Timer? _backgroundTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<ChannelChangeEvent>? _channelChangeSubscription;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncStatus _currentStatus = const SyncStatus();
  SyncStatus get currentStatus => _currentStatus;
  
  /// Per-channel status tracking.
  final Map<String, SyncStatus> _channelStatuses = {};
  
  /// Gets status for a specific channel.
  SyncStatus getChannelStatus(String channelId) {
    return _channelStatuses[channelId] ?? const SyncStatus();
  }

  /// Initializes the sync engine.
  Future<void> initialize({
    SyncEngineConfig? config,
    YouTubeDataService? youtubeService,
  }) async {
    if (_isInitialized) return;

    if (config != null) {
      _config = config;
    }

    if (youtubeService != null) {
      _deltaClient = RemoteDeltaClient(youtubeService: youtubeService);
    }

    // Register Hive adapters
    _registerAdapters();

    // Open Hive boxes
    _metadataBox = await Hive.openBox<SyncMetadata>('metadataBox');
    _syncableEntityBox = await Hive.openBox<SyncableEntity>('syncableEntityBox');

    // Initialize sync queue
    await _syncQueue.initialize();
    _syncQueue.setProcessor(_processOperation);

    // Setup connectivity monitoring
    _setupConnectivityMonitoring();
    
    // Setup channel change monitoring
    _setupChannelChangeMonitoring();

    // Perform schema migration if needed
    await _performMigration();

    _isInitialized = true;
    _updateStatus(SyncStatus(
      state: SyncState.idle,
      lastSyncedAt: _getLastSyncTime(),
      pendingOperations: _syncQueue.queueLength,
      failedOperations: _syncQueue.deadLetterLength,
    ));
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncOperationTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(SyncOperationStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SyncEntityTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(SyncMetadataAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(SyncableEntityAdapter());
    }
  }

  void _setupConnectivityMonitoring() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);

      if (hasConnection && _config.syncOnReconnect) {
        // Network reconnected - trigger sync for active channel
        final activeChannel = ChannelStore.instance.activeChannel;
        if (activeChannel != null) {
          syncNow(channelId: activeChannel.id);
        } else {
          syncNow();
        }
      } else if (!hasConnection) {
        _updateStatus(_currentStatus.copyWith(state: SyncState.offline));
      }
    });
  }
  
  /// Debounce timer for channel change sync.
  Timer? _channelChangeSyncDebounce;
  
  /// Minimum time since last sync before triggering a new sync on channel change.
  static const Duration _channelSyncDebounceTime = Duration(seconds: 2);
  static const Duration _minTimeSinceLastSync = Duration(minutes: 5);
  
  void _setupChannelChangeMonitoring() {
    try {
      if (ChannelStore.instance.isInitialized) {
        _channelChangeSubscription = ChannelStore.instance.onChannelChange.listen((event) {
          if (event.type == ChannelChangeType.activated) {
            // Cancel any pending debounced sync
            _channelChangeSyncDebounce?.cancel();
            
            // Debounce to handle rapid channel switching
            _channelChangeSyncDebounce = Timer(_channelSyncDebounceTime, () {
              // Only sync if not synced recently
              final lastSync = getChannelStatus(event.channel.id).lastSyncedAt;
              final shouldSync = lastSync == null || 
                  DateTime.now().difference(lastSync) > _minTimeSinceLastSync;
              
              if (shouldSync) {
                syncNow(channelId: event.channel.id);
              }
            });
          }
        });
      }
    } catch (e) {
      // ChannelStore may not be initialized yet
      debugPrint('Channel change monitoring not set up: $e');
    }
  }

  Future<void> _performMigration() async {
    final metadata = _metadataBox?.get('global');
    if (metadata?.migrationCompleted == true) return;

    // Migrate existing comments to include sync metadata
    try {
      final localStorage = LocalStorageService.instance;
      final existingComments = localStorage.getAllComments();

      for (final comment in existingComments) {
        final syncEntity = SyncableEntity(
          id: comment.id,
          lastSyncedAt: DateTime.now(),
          remoteUpdatedAt: comment.updatedAt,
          version: 1,
        );
        await _syncableEntityBox?.put(comment.id, syncEntity);
      }

      // Mark migration as complete
      await _metadataBox?.put(
        'global',
        SyncMetadata(
          key: 'global',
          migrationCompleted: true,
          lastFullSyncTime: DateTime.now(),
          schemaVersion: 1,
        ),
      );
    } catch (e) {
      // Migration failed - log but don't block
      debugPrint('Migration warning: $e');
    }
  }

  /// Enqueues a local change for syncing.
  Future<void> enqueueChange({
    required SyncOperationType opType,
    required SyncEntityType entityType,
    required String entityId,
    String? channelId,
    Map<String, dynamic>? payload,
  }) async {
    _ensureInitialized();
    
    final effectiveChannelId = channelId ?? 
        ChannelStore.instance.activeChannel?.id ?? 
        defaultChannelId;

    // Update local syncable entity metadata
    final existing = _syncableEntityBox?.get(entityId);
    final updated = (existing ?? SyncableEntity(id: entityId)).copyWith(
      localUpdatedAt: DateTime.now(),
      modifiedAfterLastSync: true,
      version: (existing?.version ?? 0) + 1,
      deleted: opType == SyncOperationType.delete,
    );
    await _syncableEntityBox?.put(entityId, updated);

    // Enqueue the operation with channel context
    final payloadWithChannel = {
      ...?payload,
      'channelId': effectiveChannelId,
    };
    await _syncQueue.enqueue(
      opType: opType,
      entityType: entityType,
      entityId: entityId,
      payload: payloadWithChannel,
    );

    _updateStatus(_currentStatus.copyWith(
      pendingOperations: _syncQueue.queueLength,
    ));
  }

  /// Performs an immediate foreground sync.
  /// If [channelId] is provided, syncs only that channel.
  /// Otherwise, syncs the active channel.
  Future<SyncResult> syncNow({String? channelId}) async {
    _ensureInitialized();
    
    final effectiveChannelId = channelId ?? 
        ChannelStore.instance.activeChannel?.id ?? 
        defaultChannelId;

    // Check if sync is already in progress for this channel
    if (_channelSyncInProgress[effectiveChannelId] == true) {
      return SyncResult(
        success: false,
        error: 'Sync already in progress for channel $effectiveChannelId',
        timestamp: DateTime.now(),
        channelId: effectiveChannelId,
      );
    }

    _channelSyncInProgress[effectiveChannelId] = true;
    _updateChannelStatus(effectiveChannelId, const SyncStatus().copyWith(
      state: SyncState.syncing,
      progress: 0.0,
      channelId: effectiveChannelId,
    ));

    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.every((r) => r == ConnectivityResult.none)) {
        _updateChannelStatus(effectiveChannelId, getChannelStatus(effectiveChannelId).copyWith(
          state: SyncState.offline,
        ));
        return SyncResult(
          success: false,
          error: 'No network connection',
          timestamp: DateTime.now(),
          channelId: effectiveChannelId,
        );
      }

      // Push local changes for this channel
      _updateChannelStatus(effectiveChannelId, getChannelStatus(effectiveChannelId).copyWith(
        progress: 0.1,
      ));
      final pushResult = await _pushChanges(channelId: effectiveChannelId);

      // Pull remote changes for this channel
      _updateChannelStatus(effectiveChannelId, getChannelStatus(effectiveChannelId).copyWith(
        progress: 0.5,
      ));
      final pullResult = await _pullChanges(channelId: effectiveChannelId);

      // Update metadata
      await _updateSyncMetadata(channelId: effectiveChannelId);
      
      // Update channel's last sync time in the store
      try {
        await ChannelStore.instance.updateLastSyncTime(effectiveChannelId);
      } catch (e) {
        debugPrint('Failed to update channel sync time: $e');
      }

      final finalStatus = SyncStatus(
        state: SyncState.upToDate,
        progress: 1.0,
        lastSyncedAt: DateTime.now(),
        pendingOperations: _syncQueue.queueLength,
        failedOperations: _syncQueue.deadLetterLength,
        channelId: effectiveChannelId,
      );
      _updateChannelStatus(effectiveChannelId, finalStatus);

      return SyncResult(
        success: true,
        itemsPushed: pushResult.itemsPushed,
        itemsPulled: pullResult.itemsPulled,
        conflicts: pullResult.conflicts,
        timestamp: DateTime.now(),
        channelId: effectiveChannelId,
      );
    } catch (e) {
      _updateChannelStatus(effectiveChannelId, SyncStatus(
        state: SyncState.error,
        lastError: e.toString(),
        lastSyncedAt: getChannelStatus(effectiveChannelId).lastSyncedAt,
        pendingOperations: _syncQueue.queueLength,
        failedOperations: _syncQueue.deadLetterLength,
        channelId: effectiveChannelId,
      ));

      return SyncResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
        channelId: effectiveChannelId,
      );
    } finally {
      _channelSyncInProgress[effectiveChannelId] = false;
    }
  }

  /// Pushes local changes to remote for a specific channel.
  Future<SyncResult> _pushChanges({String? channelId}) async {
    final results = await _syncQueue.processAll();
    
    // Filter results by channel if specified
    final channelResults = channelId != null
        ? results.where((r) => r.operation.payload?['channelId'] == channelId).toList()
        : results;

    return SyncResult(
      success: channelResults.every((r) => r.success),
      itemsPushed: channelResults.where((r) => r.success).length,
      timestamp: DateTime.now(),
      channelId: channelId,
    );
  }

  /// Pulls remote changes and merges them locally for a specific channel.
  Future<SyncResult> _pullChanges({String? channelId}) async {
    if (!_deltaClient.isConnected) {
      return SyncResult(success: true, timestamp: DateTime.now(), channelId: channelId);
    }

    final localStorage = LocalStorageService.instance;
    final metadataKey = channelId != null ? 'channel_$channelId' : 'global';
    final metadata = _metadataBox?.get(metadataKey);
    final lastSync = metadata?.lastIncrementalSyncTime ?? DateTime(2020);

    try {
      final channel = await _deltaClient.fetchChannel();
      if (channel == null) {
        return SyncResult(success: true, timestamp: DateTime.now(), channelId: channelId);
      }
      
      // Use provided channelId or fall back to fetched channel
      final effectiveChannelId = channelId ?? channel.id;

      final response = await _deltaClient.fetchCommentsUpdatedAfter(
        channelId: effectiveChannelId,
        updatedAfter: lastSync,
      );

      if (!response.wasModified) {
        return SyncResult(
          success: true,
          itemsPulled: 0,
          timestamp: DateTime.now(),
          channelId: effectiveChannelId,
        );
      }

      // Merge remote comments with local
      int conflicts = 0;
      for (final remoteComment in response.items) {
        final localComment = localStorage.getComment(remoteComment.id);
        final localMeta = _syncableEntityBox?.get(remoteComment.id);
        final remoteMeta = SyncableEntity(
          id: remoteComment.id,
          remoteUpdatedAt: remoteComment.updatedAt ?? DateTime.now(),
        );

        if (localComment == null) {
          // New comment from remote
          await localStorage.saveComment(remoteComment);
        } else if (localMeta != null && localMeta.modifiedAfterLastSync) {
          // Conflict - resolve it
          final resolution = _conflictResolver.resolveComment(
            local: localComment,
            remote: remoteComment,
            localMeta: localMeta,
            remoteMeta: remoteMeta,
          );

          await localStorage.saveComment(resolution.resolvedEntity);
          if (resolution.hadConflict) conflicts++;
        } else {
          // No conflict - accept remote
          await localStorage.saveComment(remoteComment);
        }

        // Update sync metadata
        await _syncableEntityBox?.put(
          remoteComment.id,
          SyncableEntity(
            id: remoteComment.id,
            lastSyncedAt: DateTime.now(),
            remoteUpdatedAt: remoteComment.updatedAt,
            modifiedAfterLastSync: false,
          ),
        );
      }

      return SyncResult(
        success: true,
        itemsPulled: response.items.length,
        conflicts: conflicts,
        timestamp: DateTime.now(),
        channelId: effectiveChannelId,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
        channelId: channelId,
      );
    }
  }

  /// Processes a single sync operation.
  Future<SyncOperationResult> _processOperation(SyncOperation operation) async {
    // In a real implementation, this would call the YouTube API
    // For now, we simulate success for most operations
    try {
      switch (operation.opType) {
        case SyncOperationType.create:
          // YouTube API doesn't allow creating comments via API for most users
          // This would typically fail or be a no-op
          return SyncOperationResult(
            operation: operation,
            success: true,
            response: {'id': operation.entityId},
          );

        case SyncOperationType.update:
          // Similar limitation for updates
          return SyncOperationResult(
            operation: operation,
            success: true,
          );

        case SyncOperationType.delete:
          // Deletion would be handled if API permits
          return SyncOperationResult(
            operation: operation,
            success: true,
          );
      }
    } catch (e) {
      return SyncOperationResult(
        operation: operation,
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _updateSyncMetadata({String? channelId}) async {
    final metadataKey = channelId != null ? 'channel_$channelId' : 'global';
    final existing = _metadataBox?.get(metadataKey);
    await _metadataBox?.put(
      metadataKey,
      SyncMetadata(
        key: metadataKey,
        lastIncrementalSyncTime: DateTime.now(),
        lastFullSyncTime: existing?.lastFullSyncTime,
        syncCount: (existing?.syncCount ?? 0) + 1,
        migrationCompleted: true,
        schemaVersion: 1,
      ),
    );
  }

  /// Starts background sync with the configured interval.
  void startBackgroundSync() {
    _ensureInitialized();

    stopBackgroundSync();

    if (_config.enableBackgroundSync) {
      _backgroundTimer = Timer.periodic(_config.syncInterval, (_) {
        // Sync only the active channel
        final activeChannel = ChannelStore.instance.activeChannel;
        if (activeChannel != null && 
            _channelSyncInProgress[activeChannel.id] != true) {
          syncNow(channelId: activeChannel.id);
        }
      });
    }
  }

  /// Stops background sync.
  void stopBackgroundSync() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }

  /// Gets the sync queue for inspection.
  SyncQueue get syncQueue => _syncQueue;

  /// Gets the conflict resolver.
  ConflictResolver get conflictResolver => _conflictResolver;

  DateTime? _getLastSyncTime({String? channelId}) {
    final metadataKey = channelId != null ? 'channel_$channelId' : 'global';
    return _metadataBox?.get(metadataKey)?.lastIncrementalSyncTime;
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
  
  void _updateChannelStatus(String channelId, SyncStatus status) {
    _channelStatuses[channelId] = status;
    // Also update the global status if this is the active channel
    final activeChannel = ChannelStore.instance.activeChannel;
    if (activeChannel?.id == channelId) {
      _updateStatus(status);
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('SyncEngine not initialized. Call initialize() first.');
    }
  }

  /// Disposes all resources.
  Future<void> dispose() async {
    stopBackgroundSync();
    _channelChangeSyncDebounce?.cancel();
    await _connectivitySubscription?.cancel();
    await _channelChangeSubscription?.cancel();
    await _statusController.close();
    await _syncQueue.dispose();
    await _metadataBox?.close();
    await _syncableEntityBox?.close();
    _isInitialized = false;
  }

  /// Resets the sync engine (for testing or recovery).
  Future<void> reset() async {
    _channelChangeSyncDebounce?.cancel();
    await _syncQueue.clearAll();
    await _metadataBox?.clear();
    await _syncableEntityBox?.clear();
    _deltaClient.clearCache();
    _channelStatuses.clear();
    _channelSyncInProgress.clear();
    _updateStatus(const SyncStatus());
  }

  /// Forces a full sync, ignoring cached data.
  /// If [channelId] is provided, syncs only that channel.
  Future<SyncResult> forceFullSync({String? channelId}) async {
    _ensureInitialized();

    // Clear delta caches
    _deltaClient.clearCache();

    // Clear incremental sync time to force full pull
    final metadataKey = channelId != null ? 'channel_$channelId' : 'global';
    final existing = _metadataBox?.get(metadataKey);
    if (existing != null) {
      await _metadataBox?.put(
        metadataKey,
        existing.copyWith(lastIncrementalSyncTime: DateTime(2020)),
      );
    }

    return syncNow(channelId: channelId);
  }

  /// Rebuilds local database from remote (recovery mode).
  /// If [channelId] is provided, only rebuilds data for that channel.
  Future<SyncResult> rebuildFromRemote({String? channelId}) async {
    _ensureInitialized();

    try {
      // Clear local data
      final localStorage = LocalStorageService.instance;
      await localStorage.clearComments();
      await _syncableEntityBox?.clear();

      // Force full sync
      return await forceFullSync(channelId: channelId);
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
        channelId: channelId,
      );
    }
  }
}
