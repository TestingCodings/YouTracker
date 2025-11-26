import 'dart:async';

import 'api_service.dart';
import 'local_storage_service.dart';

/// Service for handling background data synchronization.
/// This is a stub implementation for future backend integration.
class BackgroundSyncService {
  static BackgroundSyncService? _instance;
  static BackgroundSyncService get instance {
    _instance ??= BackgroundSyncService._();
    return _instance!;
  }

  BackgroundSyncService._();

  final CommentApiService _commentApiService = CommentApiService();
  final InteractionApiService _interactionApiService = InteractionApiService();

  Timer? _syncTimer;
  bool _isSyncing = false;

  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  /// Stream of sync status updates.
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Current sync status.
  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  /// Initializes the background sync service.
  Future<void> initialize() async {
    print('BackgroundSyncService initialized (stub)');
  }

  /// Starts periodic background sync.
  /// [intervalMinutes] - Interval between syncs in minutes.
  void startPeriodicSync({int intervalMinutes = 15}) {
    stopPeriodicSync();

    _syncTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => syncNow(),
    );

    print('Started periodic sync every $intervalMinutes minutes (stub)');
  }

  /// Stops periodic background sync.
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('Stopped periodic sync (stub)');
  }

  /// Performs a sync operation immediately.
  Future<SyncResult> syncNow() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        itemsSynced: 0,
      );
    }

    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    try {
      // Fetch latest comments from API
      final commentsResponse = await _commentApiService.getComments(
        page: 1,
        pageSize: 50,
      );

      // Save to local storage
      final localStorage = LocalStorageService.instance;
      await localStorage.saveComments(commentsResponse.items);

      // Fetch latest interactions
      final interactions = await _interactionApiService.getInteractions();
      await localStorage.saveInteractions(interactions);

      // Update last sync time
      await localStorage.saveSetting(
        SettingsKeys.lastSyncTime,
        DateTime.now().toIso8601String(),
      );

      _updateStatus(SyncStatus.success);
      _isSyncing = false;

      print('Sync completed successfully (stub)');
      return SyncResult(
        success: true,
        message: 'Sync completed successfully',
        itemsSynced:
            commentsResponse.items.length + interactions.length,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      _updateStatus(SyncStatus.error);
      _isSyncing = false;

      print('Sync failed: $e (stub)');
      return SyncResult(
        success: false,
        message: 'Sync failed: ${e.toString()}',
        itemsSynced: 0,
      );
    }
  }

  /// Gets the last sync time.
  DateTime? getLastSyncTime() {
    final localStorage = LocalStorageService.instance;
    final lastSyncString =
        localStorage.getSetting<String>(SettingsKeys.lastSyncTime);
    if (lastSyncString != null) {
      return DateTime.parse(lastSyncString);
    }
    return null;
  }

  /// Updates the sync status and notifies listeners.
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }

  /// Disposes of resources.
  void dispose() {
    stopPeriodicSync();
    _syncStatusController.close();
  }
}

/// Enum representing the current sync status.
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Result of a sync operation.
class SyncResult {
  final bool success;
  final String message;
  final int itemsSynced;
  final DateTime? timestamp;

  SyncResult({
    required this.success,
    required this.message,
    required this.itemsSynced,
    this.timestamp,
  });
}
