import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sentiment/sentiment.dart';
import '../services/services.dart';

/// Provider for theme mode.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  /// Initializes the theme from local storage.
  Future<void> initialize() async {
    final localStorage = LocalStorageService.instance;
    final isDarkMode =
        localStorage.getSettingWithDefault<bool>(SettingsKeys.isDarkMode, false);
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggles between light and dark theme.
  Future<void> toggleTheme() async {
    final newMode =
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;

    final localStorage = LocalStorageService.instance;
    await localStorage.saveSetting(
      SettingsKeys.isDarkMode,
      newMode == ThemeMode.dark,
    );
  }

  /// Sets a specific theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;

    if (mode != ThemeMode.system) {
      final localStorage = LocalStorageService.instance;
      await localStorage.saveSetting(
        SettingsKeys.isDarkMode,
        mode == ThemeMode.dark,
      );
    }
  }
}

/// Provider for app settings.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class AppSettings {
  final bool notificationsEnabled;
  final bool syncEnabled;
  final int syncIntervalMinutes;
  final DateTime? lastSyncTime;
  final SentimentConfig sentimentConfig;

  AppSettings({
    this.notificationsEnabled = true,
    this.syncEnabled = true,
    this.syncIntervalMinutes = 15,
    this.lastSyncTime,
    SentimentConfig? sentimentConfig,
  }) : sentimentConfig = sentimentConfig ?? SentimentConfig.defaults();

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? syncEnabled,
    int? syncIntervalMinutes,
    DateTime? lastSyncTime,
    SentimentConfig? sentimentConfig,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      sentimentConfig: sentimentConfig ?? this.sentimentConfig,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings());

  final BackgroundSyncService _syncService = BackgroundSyncService.instance;

  /// Initializes settings from local storage.
  Future<void> initialize() async {
    final localStorage = LocalStorageService.instance;

    state = AppSettings(
      notificationsEnabled: localStorage.getSettingWithDefault<bool>(
        SettingsKeys.notificationsEnabled,
        true,
      ),
      syncEnabled: localStorage.getSettingWithDefault<bool>(
        SettingsKeys.syncEnabled,
        true,
      ),
      syncIntervalMinutes: localStorage.getSettingWithDefault<int>(
        SettingsKeys.syncInterval,
        15,
      ),
      lastSyncTime: _syncService.getLastSyncTime(),
    );

    // Start sync if enabled
    if (state.syncEnabled) {
      _syncService.startPeriodicSync(
        intervalMinutes: state.syncIntervalMinutes,
      );
    }
  }

  /// Toggles notifications.
  Future<void> toggleNotifications() async {
    final newValue = !state.notificationsEnabled;
    state = state.copyWith(notificationsEnabled: newValue);

    final localStorage = LocalStorageService.instance;
    await localStorage.saveSetting(
      SettingsKeys.notificationsEnabled,
      newValue,
    );
  }

  /// Toggles background sync.
  Future<void> toggleSync() async {
    final newValue = !state.syncEnabled;
    state = state.copyWith(syncEnabled: newValue);

    final localStorage = LocalStorageService.instance;
    await localStorage.saveSetting(SettingsKeys.syncEnabled, newValue);

    if (newValue) {
      _syncService.startPeriodicSync(
        intervalMinutes: state.syncIntervalMinutes,
      );
    } else {
      _syncService.stopPeriodicSync();
    }
  }

  /// Sets the sync interval.
  Future<void> setSyncInterval(int minutes) async {
    state = state.copyWith(syncIntervalMinutes: minutes);

    final localStorage = LocalStorageService.instance;
    await localStorage.saveSetting(SettingsKeys.syncInterval, minutes);

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

  /// Updates sentiment analysis configuration.
  Future<void> updateSentimentConfig(SentimentConfig config) async {
    state = state.copyWith(sentimentConfig: config);

    final localStorage = LocalStorageService.instance;
    await localStorage.saveSetting(
      SettingsKeys.sentimentConfig,
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
}
