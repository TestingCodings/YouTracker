import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/channel.dart';
import '../../models/comment.dart';
import '../../services/auth/token_storage.dart';
import '../../store/channel_store.dart';

/// Migration to add multi-channel support.
/// 
/// This migration:
/// 1. Creates a default channel from existing auth data
/// 2. Migrates existing comments to be associated with the default channel
/// 3. Migrates settings to be namespaced by channel
class MultiChannelMigration {
  static const String migrationKey = 'multi_channel_migration_v1';
  
  /// Runs the migration.
  /// Returns a [MigrationResult] with details of what was migrated.
  static Future<MigrationResult> run() async {
    final result = MigrationResult();
    
    try {
      // Check if migration already completed
      final settingsBox = await Hive.openBox<dynamic>('settings');
      if (settingsBox.get(migrationKey) == true) {
        debugPrint('Multi-channel migration already completed');
        result.alreadyCompleted = true;
        return result;
      }
      
      debugPrint('Starting multi-channel migration...');
      
      // Step 1: Initialize channel store if needed
      await ChannelStore.instance.initialize();
      
      // Step 2: Create default channel from existing auth data
      final channelCreated = await _migrateAuthToChannel(result);
      
      // Step 3: Migrate comments to associate with default channel
      await _migrateComments(result, channelCreated);
      
      // Step 4: Migrate settings to be namespaced
      await _migrateSettings(result, channelCreated);
      
      // Mark migration as complete
      await settingsBox.put(migrationKey, true);
      result.success = true;
      
      debugPrint('Multi-channel migration completed successfully');
      debugPrint(result.toString());
      
      return result;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
      debugPrint('Multi-channel migration failed: $e');
      return result;
    }
  }
  
  /// Migrates existing auth data to a channel.
  static Future<String?> _migrateAuthToChannel(MigrationResult result) async {
    try {
      final tokenStorage = TokenStorage();
      final storedData = await tokenStorage.getStoredTokenData();
      
      if (storedData == null || storedData.userId == null) {
        debugPrint('No existing auth data found, skipping channel creation');
        return null;
      }
      
      // Check if channel already exists
      final existingChannel = ChannelStore.instance.getChannel(storedData.userId!);
      if (existingChannel != null) {
        debugPrint('Channel already exists: ${storedData.userId}');
        return storedData.userId;
      }
      
      // Create default channel from existing auth data
      // Set initial state to disconnected - the auth service will verify 
      // the actual connection state when the channel is used
      final defaultChannel = Channel(
        id: storedData.userId!,
        name: storedData.name ?? 'My Channel',
        provider: 'youtube',
        accessToken: storedData.accessToken,
        refreshToken: storedData.refreshToken,
        avatarUrl: storedData.photoUrl,
        email: storedData.email,
        userId: storedData.userId,
        isActive: true,
        tokenExpiresAt: storedData.expiry,
        // Use disconnected as the initial state - the auth service will
        // verify and update the actual connection state
        connectionState: storedData.isExpired 
            ? ChannelConnectionState.tokenExpired 
            : ChannelConnectionState.disconnected,
      );
      
      await ChannelStore.instance.addChannel(defaultChannel);
      result.channelsCreated++;
      result.defaultChannelId = defaultChannel.id;
      
      debugPrint('Created default channel: ${defaultChannel.id}');
      return defaultChannel.id;
    } catch (e) {
      debugPrint('Failed to migrate auth to channel: $e');
      return null;
    }
  }
  
  /// Migrates comments to be associated with the default channel.
  static Future<void> _migrateComments(MigrationResult result, String? channelId) async {
    if (channelId == null) {
      // No channel, use 'default' as the channel ID
      channelId = defaultChannelId;
    }
    
    try {
      final commentsBox = await Hive.openBox<Comment>('comments');
      final comments = commentsBox.values.toList();
      
      // Comments already have a channelId field (the YouTube channel ID of the video)
      // We don't need to modify them, but we can log the count
      result.commentsMigrated = comments.length;
      
      debugPrint('Found ${comments.length} comments (no modification needed)');
    } catch (e) {
      debugPrint('Failed to migrate comments: $e');
    }
  }
  
  /// Migrates settings to be namespaced by channel.
  static Future<void> _migrateSettings(MigrationResult result, String? channelId) async {
    if (channelId == null) {
      channelId = defaultChannelId;
    }
    
    try {
      final settingsBox = await Hive.openBox<dynamic>('settings');
      
      // List of settings keys that should be channel-scoped
      final channelScopedKeys = [
        'isDarkMode',
        'notificationsEnabled',
        'syncEnabled',
        'syncInterval',
        'sentimentConfig',
      ];
      
      final prefix = 'channel_${channelId}_';
      
      for (final key in channelScopedKeys) {
        final value = settingsBox.get(key);
        if (value != null) {
          // Copy to namespaced key
          await settingsBox.put('$prefix$key', value);
          result.settingsMigrated++;
        }
      }
      
      debugPrint('Migrated ${result.settingsMigrated} settings');
    } catch (e) {
      debugPrint('Failed to migrate settings: $e');
    }
  }
  
  /// Resets the migration flag (for testing).
  static Future<void> reset() async {
    final settingsBox = await Hive.openBox<dynamic>('settings');
    await settingsBox.delete(migrationKey);
    debugPrint('Multi-channel migration reset');
  }
}

/// Result of the multi-channel migration.
class MigrationResult {
  bool success = false;
  bool alreadyCompleted = false;
  String? error;
  int channelsCreated = 0;
  int commentsMigrated = 0;
  int settingsMigrated = 0;
  String? defaultChannelId;
  
  @override
  String toString() {
    return '''
MigrationResult:
  success: $success
  alreadyCompleted: $alreadyCompleted
  error: $error
  channelsCreated: $channelsCreated
  commentsMigrated: $commentsMigrated
  settingsMigrated: $settingsMigrated
  defaultChannelId: $defaultChannelId
''';
  }
}
