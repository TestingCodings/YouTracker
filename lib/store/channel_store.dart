import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/channel.dart';
import '../services/auth/token_storage.dart';

/// Centralized state management for channels.
/// 
/// This store manages the list of authenticated channels, 
/// tracks the active channel, and notifies listeners of changes.
class ChannelStore {
  static const String _channelsBoxName = 'channels';
  static const String _activeChannelKey = 'active_channel_id';

  static ChannelStore? _instance;
  static ChannelStore get instance {
    _instance ??= ChannelStore._();
    return _instance!;
  }

  ChannelStore._();

  /// Factory constructor for testing.
  factory ChannelStore.forTest() => ChannelStore._();

  Box<Channel>? _channelsBox;
  Box<dynamic>? _settingsBox;
  bool _isInitialized = false;

  final _channelChangeController = StreamController<ChannelChangeEvent>.broadcast();
  
  /// Stream of channel change events.
  Stream<ChannelChangeEvent> get onChannelChange => _channelChangeController.stream;

  Channel? _activeChannel;

  /// Gets the currently active channel.
  Channel? get activeChannel => _activeChannel;

  /// Gets all stored channels.
  List<Channel> get channels => _channelsBox?.values.toList() ?? [];

  /// Gets channels count.
  int get channelCount => _channelsBox?.length ?? 0;

  /// Whether the store is initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the channel store.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ChannelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ChannelConnectionStateAdapter());
    }

    // Open boxes
    _channelsBox = await Hive.openBox<Channel>(_channelsBoxName);
    _settingsBox = await Hive.openBox<dynamic>('channel_settings');

    // Load active channel
    await _loadActiveChannel();

    // Migrate existing data if needed
    await _migrateIfNeeded();

    _isInitialized = true;
  }

  /// Loads the active channel from storage.
  Future<void> _loadActiveChannel() async {
    final activeId = _settingsBox?.get(_activeChannelKey) as String?;
    
    if (activeId != null && _channelsBox != null) {
      _activeChannel = _channelsBox!.get(activeId);
    }

    // If no active channel but channels exist, activate the first one
    if (_activeChannel == null && _channelsBox != null && _channelsBox!.isNotEmpty) {
      final firstChannel = _channelsBox!.values.first;
      await setActiveChannel(firstChannel.id);
    }
  }

  /// Migrates existing single-channel data to multi-channel format.
  Future<void> _migrateIfNeeded() async {
    final migrationDone = _settingsBox?.get('migration_completed') as bool? ?? false;
    if (migrationDone) return;

    // Check if we have existing auth data but no channels
    if (_channelsBox != null && _channelsBox!.isEmpty) {
      try {
        final tokenStorage = TokenStorage();
        final storedData = await tokenStorage.getStoredTokenData();
        
        if (storedData != null && storedData.userId != null) {
          // Create default channel from existing auth data
          final defaultChannel = Channel(
            id: storedData.userId ?? defaultChannelId,
            name: storedData.name ?? 'Default Channel',
            provider: 'youtube',
            accessToken: storedData.accessToken,
            refreshToken: storedData.refreshToken,
            avatarUrl: storedData.photoUrl,
            email: storedData.email,
            userId: storedData.userId,
            isActive: true,
            tokenExpiresAt: storedData.expiry,
            connectionState: storedData.isExpired 
                ? ChannelConnectionState.tokenExpired 
                : ChannelConnectionState.connected,
          );
          
          await addChannel(defaultChannel);
          debugPrint('Migrated existing auth data to channel: ${defaultChannel.id}');
        }
      } catch (e) {
        debugPrint('Migration warning: $e');
      }
    }

    await _settingsBox?.put('migration_completed', true);
  }

  /// Adds a new channel.
  Future<void> addChannel(Channel channel) async {
    _ensureInitialized();
    
    await _channelsBox!.put(channel.id, channel);
    
    // If this is the first channel or it's marked as active, make it active
    if (_activeChannel == null || channel.isActive) {
      await setActiveChannel(channel.id);
    }

    _notifyChannelChange(ChannelChangeType.added, channel);
  }

  /// Updates an existing channel.
  Future<void> updateChannel(Channel channel) async {
    _ensureInitialized();
    
    await _channelsBox!.put(channel.id, channel);
    
    // Update active channel reference if this is the active one
    if (_activeChannel?.id == channel.id) {
      _activeChannel = channel;
    }

    _notifyChannelChange(ChannelChangeType.updated, channel);
  }

  /// Removes a channel.
  Future<void> removeChannel(String channelId) async {
    _ensureInitialized();
    
    final channel = _channelsBox!.get(channelId);
    if (channel == null) return;

    await _channelsBox!.delete(channelId);
    
    // If we removed the active channel, switch to another one
    if (_activeChannel?.id == channelId) {
      _activeChannel = null;
      await _settingsBox?.delete(_activeChannelKey);
      
      // Switch to another channel if available
      if (_channelsBox!.isNotEmpty) {
        await setActiveChannel(_channelsBox!.values.first.id);
      }
    }

    _notifyChannelChange(ChannelChangeType.removed, channel);
  }

  /// Sets the active channel.
  Future<void> setActiveChannel(String channelId) async {
    _ensureInitialized();
    
    final channel = _channelsBox!.get(channelId);
    if (channel == null) {
      throw ArgumentError('Channel not found: $channelId');
    }

    // Deactivate current active channel
    if (_activeChannel != null && _activeChannel!.id != channelId) {
      final oldChannel = _activeChannel!.copyWith(isActive: false);
      await _channelsBox!.put(oldChannel.id, oldChannel);
    }

    // Activate new channel
    final newActiveChannel = channel.copyWith(isActive: true);
    await _channelsBox!.put(newActiveChannel.id, newActiveChannel);
    
    _activeChannel = newActiveChannel;
    await _settingsBox?.put(_activeChannelKey, channelId);

    _notifyChannelChange(ChannelChangeType.activated, newActiveChannel);
  }

  /// Gets a channel by ID.
  Channel? getChannel(String channelId) {
    _ensureInitialized();
    return _channelsBox!.get(channelId);
  }

  /// Gets a channel by its settings key prefix.
  String getChannelSettingsPrefix(String? channelId) {
    final id = channelId ?? _activeChannel?.id ?? defaultChannelId;
    return 'channel_${id}_';
  }

  /// Updates the connection state for a channel.
  Future<void> updateConnectionState(
    String channelId,
    ChannelConnectionState state, {
    String? error,
  }) async {
    _ensureInitialized();
    
    final channel = _channelsBox!.get(channelId);
    if (channel == null) return;

    final updated = channel.copyWith(
      connectionState: state,
      lastError: error,
    );
    await updateChannel(updated);
  }

  /// Updates the last sync time for a channel.
  Future<void> updateLastSyncTime(String channelId) async {
    _ensureInitialized();
    
    final channel = _channelsBox!.get(channelId);
    if (channel == null) return;

    final updated = channel.copyWith(lastSyncedAt: DateTime.now());
    await updateChannel(updated);
  }

  /// Updates tokens for a channel.
  Future<void> updateTokens({
    required String channelId,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
  }) async {
    _ensureInitialized();
    
    final channel = _channelsBox!.get(channelId);
    if (channel == null) return;

    final updated = channel.copyWith(
      accessToken: accessToken ?? channel.accessToken,
      refreshToken: refreshToken ?? channel.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? channel.tokenExpiresAt,
      connectionState: ChannelConnectionState.connected,
    );
    await updateChannel(updated);
  }

  /// Clears all channels.
  Future<void> clearAll() async {
    _ensureInitialized();
    
    await _channelsBox!.clear();
    await _settingsBox?.delete(_activeChannelKey);
    _activeChannel = null;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('ChannelStore not initialized. Call initialize() first.');
    }
  }

  void _notifyChannelChange(ChannelChangeType type, Channel channel) {
    if (!_channelChangeController.isClosed) {
      _channelChangeController.add(ChannelChangeEvent(type: type, channel: channel));
    }
  }

  /// Disposes resources.
  Future<void> dispose() async {
    await _channelChangeController.close();
    await _channelsBox?.close();
    await _settingsBox?.close();
    _isInitialized = false;
  }
}

/// Types of channel changes.
enum ChannelChangeType {
  added,
  updated,
  removed,
  activated,
}

/// Event fired when a channel changes.
class ChannelChangeEvent {
  final ChannelChangeType type;
  final Channel channel;

  const ChannelChangeEvent({
    required this.type,
    required this.channel,
  });

  @override
  String toString() => 'ChannelChangeEvent(type: $type, channel: ${channel.id})';
}
