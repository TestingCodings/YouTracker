import 'dart:async';
import 'dart:math';

import 'package:hive/hive.dart';

import 'hive_adapters.dart';

/// Configuration for sync queue retry behavior.
class SyncQueueConfig {
  /// Maximum number of retry attempts before moving to dead letter.
  final int maxRetryAttempts;

  /// Base delay for exponential backoff (in seconds).
  final int backoffBaseSeconds;

  /// Maximum delay between retries (in seconds).
  final int maxBackoffSeconds;

  /// Jitter factor for randomizing retry delays (0.0 to 1.0).
  final double jitterFactor;

  /// Maximum concurrent operations to process.
  final int maxConcurrentOperations;

  /// Whether to enable automatic processing.
  final bool autoProcess;

  const SyncQueueConfig({
    this.maxRetryAttempts = 5,
    this.backoffBaseSeconds = 2,
    this.maxBackoffSeconds = 300,
    this.jitterFactor = 0.25,
    this.maxConcurrentOperations = 3,
    this.autoProcess = true,
  });

  /// Calculate delay for a given attempt with exponential backoff and jitter.
  Duration getDelayForAttempt(int attempt) {
    final baseDelay = backoffBaseSeconds * pow(2, attempt);
    final clampedDelay = min(baseDelay, maxBackoffSeconds).toDouble();
    final jitter = clampedDelay * jitterFactor * (Random().nextDouble() - 0.5);
    return Duration(seconds: (clampedDelay + jitter).round());
  }
}

/// Result of processing a sync operation.
class SyncOperationResult {
  final SyncOperation operation;
  final bool success;
  final String? error;
  final Map<String, dynamic>? response;

  const SyncOperationResult({
    required this.operation,
    required this.success,
    this.error,
    this.response,
  });
}

/// Callback for processing sync operations.
typedef SyncOperationProcessor = Future<SyncOperationResult> Function(
  SyncOperation operation,
);

/// Persistent sync queue for managing offline operations.
class SyncQueue {
  static const String _boxName = 'syncQueueBox';
  static const String _deadLetterBoxName = 'deadLetterBox';

  late Box<SyncOperation> _queueBox;
  late Box<SyncOperation> _deadLetterBox;

  final SyncQueueConfig config;
  SyncOperationProcessor? _processor;

  bool _isInitialized = false;
  bool _isProcessing = false;
  int _activeOperations = 0;

  final _statusController = StreamController<SyncQueueStatus>.broadcast();
  Stream<SyncQueueStatus> get statusStream => _statusController.stream;

  Timer? _processTimer;

  SyncQueue({this.config = const SyncQueueConfig()});

  /// Initializes the sync queue by opening Hive boxes.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _queueBox = await Hive.openBox<SyncOperation>(_boxName);
    _deadLetterBox = await Hive.openBox<SyncOperation>(_deadLetterBoxName);

    _isInitialized = true;
    _emitStatus();
  }

  /// Sets the processor for sync operations.
  void setProcessor(SyncOperationProcessor processor) {
    _processor = processor;
  }

  /// Enqueues a new sync operation.
  Future<SyncOperation> enqueue({
    required SyncOperationType opType,
    required SyncEntityType entityType,
    required String entityId,
    Map<String, dynamic>? payload,
    int priority = 0,
  }) async {
    _ensureInitialized();

    // Check for contradictory operations and cancel them
    await _cancelContradictoryOperations(opType, entityType, entityId);

    final operation = SyncOperation(
      id: _generateId(),
      opType: opType,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      priority: priority,
    );

    await _queueBox.put(operation.id, operation);
    _emitStatus();

    if (config.autoProcess) {
      _scheduleProcessing();
    }

    return operation;
  }

  /// Cancels contradictory operations (e.g., create then delete).
  Future<void> _cancelContradictoryOperations(
    SyncOperationType newOpType,
    SyncEntityType entityType,
    String entityId,
  ) async {
    final pending = getPendingOperations()
        .where((op) =>
            op.entityType == entityType &&
            op.entityId == entityId &&
            op.status == SyncOperationStatus.pending)
        .toList();

    for (final op in pending) {
      bool shouldCancel = false;

      // Create then delete = cancel both
      if (op.opType == SyncOperationType.create &&
          newOpType == SyncOperationType.delete) {
        shouldCancel = true;
      }

      // Delete then create = cancel delete (create is resurrection)
      if (op.opType == SyncOperationType.delete &&
          newOpType == SyncOperationType.create) {
        shouldCancel = true;
      }

      // Multiple updates = cancel older one
      if (op.opType == SyncOperationType.update &&
          newOpType == SyncOperationType.update) {
        shouldCancel = true;
      }

      if (shouldCancel) {
        op.status = SyncOperationStatus.cancelled;
        op.completedAt = DateTime.now();
        await _queueBox.put(op.id, op);
      }
    }
  }

  /// Gets all pending operations sorted by priority and creation time.
  List<SyncOperation> getPendingOperations() {
    final operations = _queueBox.values
        .where((op) =>
            op.status == SyncOperationStatus.pending &&
            (op.nextAttemptAt == null ||
                op.nextAttemptAt!.isBefore(DateTime.now())))
        .toList();

    operations.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.createdAt.compareTo(b.createdAt);
    });

    return operations;
  }

  /// Gets all operations with a specific status.
  List<SyncOperation> getOperationsByStatus(SyncOperationStatus status) {
    return _queueBox.values.where((op) => op.status == status).toList();
  }

  /// Gets the dead letter queue.
  List<SyncOperation> getDeadLetterOperations() {
    return _deadLetterBox.values.toList();
  }

  /// Gets the current queue length.
  int get queueLength =>
      _queueBox.values.where((op) => op.status == SyncOperationStatus.pending).length;

  /// Gets the dead letter queue length.
  int get deadLetterLength => _deadLetterBox.length;

  /// Gets whether the queue is currently processing.
  bool get isProcessing => _isProcessing;

  /// Processes all pending operations.
  Future<List<SyncOperationResult>> processAll() async {
    _ensureInitialized();

    if (_processor == null) {
      throw StateError('No processor set. Call setProcessor() first.');
    }

    if (_isProcessing) {
      return [];
    }

    _isProcessing = true;
    _emitStatus();

    final results = <SyncOperationResult>[];
    final pending = getPendingOperations();

    // Process in batches respecting concurrency limit
    for (var i = 0; i < pending.length; i += config.maxConcurrentOperations) {
      final batch = pending.skip(i).take(config.maxConcurrentOperations);
      final batchResults = await Future.wait(
        batch.map((op) => _processOperation(op)),
      );
      results.addAll(batchResults);
    }

    _isProcessing = false;
    _emitStatus();

    return results;
  }

  /// Processes a single operation.
  Future<SyncOperationResult> _processOperation(SyncOperation operation) async {
    _activeOperations++;
    _emitStatus();

    try {
      // Mark as in progress
      operation.status = SyncOperationStatus.inProgress;
      await _queueBox.put(operation.id, operation);

      // Process the operation
      final result = await _processor!(operation);

      if (result.success) {
        // Mark as completed
        operation.status = SyncOperationStatus.completed;
        operation.completedAt = DateTime.now();
        operation.lastError = null;
        await _queueBox.put(operation.id, operation);
      } else {
        // Handle failure
        await _handleFailure(operation, result.error ?? 'Unknown error');
      }

      return result;
    } catch (e) {
      await _handleFailure(operation, e.toString());
      return SyncOperationResult(
        operation: operation,
        success: false,
        error: e.toString(),
      );
    } finally {
      _activeOperations--;
      _emitStatus();
    }
  }

  /// Handles operation failure with retry logic.
  Future<void> _handleFailure(SyncOperation operation, String error) async {
    operation.attempts++;
    operation.lastError = error;

    if (operation.attempts >= config.maxRetryAttempts) {
      // Move to dead letter queue
      operation.status = SyncOperationStatus.deadLetter;
      operation.completedAt = DateTime.now();
      await _deadLetterBox.put(operation.id, operation);
      await _queueBox.delete(operation.id);
    } else {
      // Schedule retry with backoff
      operation.status = SyncOperationStatus.pending;
      operation.nextAttemptAt =
          DateTime.now().add(config.getDelayForAttempt(operation.attempts));
      await _queueBox.put(operation.id, operation);
    }
  }

  /// Retries a specific failed or dead-lettered operation.
  Future<void> retryOperation(String operationId) async {
    _ensureInitialized();

    // Check in main queue first
    var operation = _queueBox.get(operationId);

    // Check dead letter queue
    if (operation == null) {
      operation = _deadLetterBox.get(operationId);
      if (operation != null) {
        // Move back to main queue
        await _deadLetterBox.delete(operationId);
      }
    }

    if (operation == null) {
      throw ArgumentError('Operation not found: $operationId');
    }

    // Reset for retry
    operation.status = SyncOperationStatus.pending;
    operation.attempts = 0;
    operation.nextAttemptAt = null;
    operation.lastError = null;

    await _queueBox.put(operation.id, operation);
    _emitStatus();

    if (config.autoProcess) {
      _scheduleProcessing();
    }
  }

  /// Retries all dead-lettered operations.
  Future<int> retryAllDeadLetter() async {
    _ensureInitialized();

    final deadLetterOps = getDeadLetterOperations();
    int count = 0;

    for (final op in deadLetterOps) {
      op.status = SyncOperationStatus.pending;
      op.attempts = 0;
      op.nextAttemptAt = null;
      op.lastError = null;

      await _queueBox.put(op.id, op);
      await _deadLetterBox.delete(op.id);
      count++;
    }

    _emitStatus();

    if (config.autoProcess && count > 0) {
      _scheduleProcessing();
    }

    return count;
  }

  /// Cancels a pending operation.
  Future<void> cancelOperation(String operationId) async {
    _ensureInitialized();

    final operation = _queueBox.get(operationId);
    if (operation == null) return;

    if (operation.status == SyncOperationStatus.inProgress) {
      throw StateError('Cannot cancel in-progress operation');
    }

    operation.status = SyncOperationStatus.cancelled;
    operation.completedAt = DateTime.now();
    await _queueBox.put(operation.id, operation);

    _emitStatus();
  }

  /// Clears completed and cancelled operations from the queue.
  Future<int> clearCompleted() async {
    _ensureInitialized();

    final toRemove = _queueBox.values
        .where((op) =>
            op.status == SyncOperationStatus.completed ||
            op.status == SyncOperationStatus.cancelled)
        .map((op) => op.id)
        .toList();

    for (final id in toRemove) {
      await _queueBox.delete(id);
    }

    _emitStatus();
    return toRemove.length;
  }

  /// Clears the dead letter queue.
  Future<int> clearDeadLetter() async {
    _ensureInitialized();
    final count = _deadLetterBox.length;
    await _deadLetterBox.clear();
    _emitStatus();
    return count;
  }

  /// Clears all queues.
  Future<void> clearAll() async {
    _ensureInitialized();
    await _queueBox.clear();
    await _deadLetterBox.clear();
    _emitStatus();
  }

  /// Gets the current queue status.
  SyncQueueStatus getStatus() {
    return SyncQueueStatus(
      pendingCount: queueLength,
      processingCount: _activeOperations,
      completedCount:
          getOperationsByStatus(SyncOperationStatus.completed).length,
      failedCount: getOperationsByStatus(SyncOperationStatus.failed).length,
      deadLetterCount: deadLetterLength,
      isProcessing: _isProcessing,
    );
  }

  /// Schedules processing for the next tick.
  void _scheduleProcessing() {
    _processTimer?.cancel();
    _processTimer = Timer(Duration.zero, () => processAll());
  }

  /// Starts automatic periodic processing.
  void startAutoProcessing({Duration interval = const Duration(seconds: 30)}) {
    _processTimer?.cancel();
    _processTimer = Timer.periodic(interval, (_) {
      if (!_isProcessing && queueLength > 0) {
        processAll();
      }
    });
  }

  /// Stops automatic processing.
  void stopAutoProcessing() {
    _processTimer?.cancel();
    _processTimer = null;
  }

  void _emitStatus() {
    if (!_statusController.isClosed) {
      _statusController.add(getStatus());
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('SyncQueue not initialized. Call initialize() first.');
    }
  }

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'sync_${timestamp}_$random';
  }

  /// Disposes resources.
  Future<void> dispose() async {
    _processTimer?.cancel();
    await _statusController.close();
    await _queueBox.close();
    await _deadLetterBox.close();
  }
}

/// Status of the sync queue.
class SyncQueueStatus {
  final int pendingCount;
  final int processingCount;
  final int completedCount;
  final int failedCount;
  final int deadLetterCount;
  final bool isProcessing;

  const SyncQueueStatus({
    this.pendingCount = 0,
    this.processingCount = 0,
    this.completedCount = 0,
    this.failedCount = 0,
    this.deadLetterCount = 0,
    this.isProcessing = false,
  });

  int get totalCount =>
      pendingCount + processingCount + completedCount + failedCount;

  bool get isEmpty => totalCount == 0;

  bool get hasErrors => failedCount > 0 || deadLetterCount > 0;

  @override
  String toString() {
    return 'SyncQueueStatus(pending: $pendingCount, processing: $processingCount, '
        'completed: $completedCount, failed: $failedCount, deadLetter: $deadLetterCount)';
  }
}
