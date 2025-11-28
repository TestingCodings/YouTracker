import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sentiment/sentiment.dart';
import '../services/services.dart';
import '../store/channel_store.dart';

/// Provider for theme mode with per-channel support.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;
  StreamSubscription<ChannelChangeEvent>? _channelSubscription;
  
  ThemeModeNotifier(this._ref) : super(ThemeMode.system) {
    _setupChannelListener();
  }
  
  void _setupChannelListener() {
    try {
      if (ChannelStore.instance.isInitialized) {
        _channelSubscription = ChannelStore.instance.onChannelChange.listen((event) {
          if (event.type == ChannelChangeType.activated) {
            // Reload theme for the new active channel
            _loadThemeForChannel(event.channel.id);
          }
        });
      }
    } catch (e) {
      // ChannelStore may not be initialized yet
    }
  }

  /// Initializes the theme from local storage for the active channel.
  Future<void> initialize() async {
    final channelId = ChannelStore.instance.activeChannel?.id;
    await _loadThemeForChannel(channelId);
  }
  
  Future<void> _loadThemeForChannel(String? channelId) async {
    final localStorage = LocalStorageService.instance;
    final settingsKey = _getSettingsKey(SettingsKeys.isDarkMode, channelId);
    final isDarkMode = localStorage.getSettingWithDefault<bool>(settingsKey, false);
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
  
  String _getSettingsKey(String baseKey, String? channelId) {
    if (channelId != null) {
      return 'channel_${channelId}_$baseKey';
    }
    return baseKey;
  }

  /// Toggles between light and dark theme for the active channel.
  Future<void> toggleTheme() async {
    final newMode =
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;

    final localStorage = LocalStorageService.instance;
    final channelId = ChannelStore.instance.activeChannel?.id;
    final settingsKey = _getSettingsKey(SettingsKeys.isDarkMode, channelId);
    await localStorage.saveSetting(
      settingsKey,
      newMode == ThemeMode.dark,
    );
  }

  /// Sets a specific theme mode for the active channel.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;

    if (mode != ThemeMode.system) {
      final localStorage = LocalStorageService.instance;
      final channelId = ChannelStore.instance.activeChannel?.id;
      final settingsKey = _getSettingsKey(SettingsKeys.isDarkMode, channelId);
      await localStorage.saveSetting(
        settingsKey,
        mode == ThemeMode.dark,
      );
    }
  }
  
  @override
  void dispose() {
    _channelSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for app settings with per-channel support.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref);
});

class AppSettings {
  final bool notificationsEnabled;
  final bool syncEnabled;
  final int syncIntervalMinutes;
  final DateTime? lastSyncTime;
  final SentimentConfig sentimentConfig;
  final String? channelId;

  AppSettings({
    this.notificationsEnabled = true,
    this.syncEnabled = true,
    this.syncIntervalMinutes = 15,
    this.lastSyncTime,
    SentimentConfig? sentimentConfig,
    this.channelId,
  }) : sentimentConfig = sentimentConfig ?? SentimentConfig.defaults();

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? syncEnabled,
    int? syncIntervalMinutes,
    DateTime? lastSyncTime,
    SentimentConfig? sentimentConfig,
    String? channelId,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      sentimentConfig: sentimentConfig ?? this.sentimentConfig,
      channelId: channelId ?? this.channelId,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final Ref _ref;
  StreamSubscription<ChannelChangeEvent>? _channelSubscription;
  
  SettingsNotifier(this._ref) : super(AppSettings()) {
    _setupChannelListener();
  }

  final BackgroundSyncService _syncService = BackgroundSyncService.instance;
  
  void _setupChannelListener() {
    try {
      if (ChannelStore.instance.isInitialized) {
        _channelSubscription = ChannelStore.instance.onChannelChange.listen((event) {
          if (event.type == ChannelChangeType.activated) {
            // Reload settings for the new active channel
            _loadSettingsForChannel(event.channel.id);
          }
        });
      }
    } catch (e) {
      // ChannelStore may not be initialized yet
    }
  }
  
  String _getSettingsKey(String baseKey, String? channelId) {
    if (channelId != null) {
      return 'channel_${channelId}_$baseKey';
    }
    return baseKey;
  }

  /// Initializes settings from local storage for the active channel.
  Future<void> initialize() async {
    final channelId = ChannelStore.instance.activeChannel?.id;
    await _loadSettingsForChannel(channelId);
  }
  
  Future<void> _loadSettingsForChannel(String? channelId) async {
    final localStorage = LocalStorageService.instance;

    state = AppSettings(
      notificationsEnabled: localStorage.getSettingWithDefault<bool>(
        _getSettingsKey(SettingsKeys.notificationsEnabled, channelId),
        true,
      ),
      syncEnabled: localStorage.getSettingWithDefault<bool>(
        _getSettingsKey(SettingsKeys.syncEnabled, channelId),
        true,
      ),
      syncIntervalMinutes: localStorage.getSettingWithDefault<int>(
        _getSettingsKey(SettingsKeys.syncInterval, channelId),
        15,
      ),
      lastSyncTime: _syncService.getLastSyncTime(),
      channelId: channelId,
    );

    // Start sync if enabled
    if (state.syncEnabled) {
      _syncService.startPeriodicSync(
        intervalMinutes: state.syncIntervalMinutes,
      );
    }
  }

  /// Toggles notifications for the active channel.
  Future<void> toggleNotifications() async {
    final newValue = !state.notificationsEnabled;
    state = state.copyWith(notificationsEnabled: newValue);

    final localStorage = LocalStorageService.instance;
    await localStorage.saveSetting(
      _getSettingsKey(SettingsKeys.notificationsEnabled, state.channelId),
      newValue,
    );
  }

  /// Toggles background sync for the active channel.
  Future<void> toggleSync() async {
    final newValue = !state.syncEnabled;
    state = state.copyWith(syncEnabled: newValue);

    final localStorage = LocalStorageService.instance;
    await localStorage.saveSetting(
      _getSettingsKey(SettingsKeys.syncEnabled, state.channelId),
      newValue,
    );

    if (newValue) {
      _syncService.startPeriodicSync(
        intervalMinutes: state.syncIntervalMinutes,
      );
    } else {
      _syncService.stopPeriodicSync();
    }
  }

  /// Sets the sync interval for the active channel.
  Future<void> setSyncInterval(int minutes) async {
    state = state.copyWith(syncIntervalMinutes: minutes);

    final localStorage = LocalStorageService.instance;
    await localStorage.saveSetting(
      _getSettingsKey(SettingsKeys.syncInterval, state.channelId),
      minutes,
    );

    if (state.syncEnabled) {
      _syncService.startPeriodicSync(intervalMinutes: minutes);
    }
  }

  /// Triggers a manual sync.
  Future<SyncResult> syncNow() async {
    final result = await _syncService.syncNow();
    if (result.success) {
      state = state.copyWith(lastSyncTime: result.timestamp);
    }
    return result;
  }

  /// Updates sentiment analysis configuration for the active channel.
  Future<void> updateSentimentConfig(SentimentConfig config) async {
    state = state.copyWith(sentimentConfig: config);

    final localStorage = LocalStorageService.instance;
    await localStorage.saveSetting(
      _getSettingsKey(SettingsKeys.sentimentConfig, state.channelId),
      config.toJson(),
    );
  }

  /// Enables or disables sentiment analysis.
  Future<void> setSentimentEnabled(bool enabled) async {
    await updateSentimentConfig(
      state.sentimentConfig.copyWith(enabled: enabled),
    );
  }

  /// Sets the sentiment analysis provider.
  Future<void> setSentimentProvider(SentimentProvider provider) async {
    await updateSentimentConfig(
      state.sentimentConfig.copyWith(
        provider: provider,
        enabled: provider != SentimentProvider.off,
      ),
    );
  }
  
  @override
  void dispose() {
    _channelSubscription?.cancel();
    super.dispose();
  }
}
