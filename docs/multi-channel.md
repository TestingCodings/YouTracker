# Multi-Channel Support

This document describes the multi-channel support feature in YouTracker, which allows users to authenticate and manage multiple YouTube channels from a single app installation.

## Overview

Multi-channel support enables:
- **Multiple authenticated channels**: Users can add and manage multiple YouTube accounts/channels
- **Channel switching**: Quickly switch between channels from the dashboard
- **Per-channel data isolation**: Comments, settings, and sync state are isolated per channel
- **Per-channel themes**: Theme preferences can be set independently for each channel

## Architecture

### Channel Model

The `Channel` model (`lib/models/channel.dart`) represents an authenticated channel:

```dart
class Channel {
  final String id;           // Unique identifier (YouTube channel ID)
  final String name;         // Display name
  final String provider;     // Auth provider (e.g., 'youtube')
  final String? accessToken; // OAuth access token
  final String? refreshToken;// OAuth refresh token
  final String? avatarUrl;   // Profile image URL
  final DateTime createdAt;  // When channel was added
  final DateTime? lastSyncedAt; // Last sync timestamp
  final bool isActive;       // Whether this is the active channel
  final DateTime? tokenExpiresAt; // Token expiry time
  final String? email;       // Associated email
  final ChannelConnectionState connectionState; // Connection status
}
```

### Channel Store

The `ChannelStore` (`lib/store/channel_store.dart`) manages channel state:

```dart
// Initialize the store
await ChannelStore.instance.initialize();

// Add a new channel
await ChannelStore.instance.addChannel(channel);

// Switch active channel
await ChannelStore.instance.setActiveChannel(channelId);

// Get active channel
final active = ChannelStore.instance.activeChannel;

// Listen to channel changes
ChannelStore.instance.onChannelChange.listen((event) {
  if (event.type == ChannelChangeType.activated) {
    // Handle channel switch
  }
});
```

### Provider Integration

Use the `channelProvider` for Riverpod state management:

```dart
// Watch channel state
final channelState = ref.watch(channelProvider);

// Access active channel
final activeChannel = channelState.activeChannel;

// Switch channel
ref.read(channelProvider.notifier).setActiveChannel(channelId);

// Add new channel with Google OAuth
await ref.read(channelProvider.notifier).addChannelWithGoogle();
```

## Persistence Format

### Channel Storage

Channels are stored in a Hive box named `channels`:
- Box type: `Box<Channel>`
- Key: Channel ID (String)
- Active channel ID stored in `channel_settings` box under `active_channel_id`

### Per-Channel Settings

Settings are namespaced by channel ID using the prefix `channel_{channelId}_`:

```dart
// Get the settings prefix for the active channel
final prefix = ChannelStore.instance.getChannelSettingsPrefix(null);
// Returns: "channel_UC123456_"

// Store channel-specific setting
await settingsBox.put('${prefix}isDarkMode', true);
```

Settings that are channel-scoped:
- `isDarkMode` - Theme preference
- `notificationsEnabled` - Push notification toggle
- `syncEnabled` - Background sync toggle
- `syncInterval` - Sync frequency
- `sentimentConfig` - Sentiment analysis settings

### Per-Channel Sync Metadata

Sync metadata is stored per-channel using keys:
- `channel_{channelId}` - Per-channel sync state
- `global` - Global sync metadata (fallback)

## Migration

When upgrading from single-channel to multi-channel, the migration:

1. **Creates default channel**: Existing auth tokens are migrated to a new channel
2. **Preserves comments**: Existing comments remain accessible
3. **Copies settings**: Settings are copied to the new channel namespace

Run migration manually:

```dart
import 'package:you_tracker/storage/migrations/multi_channel_migration.dart';

final result = await MultiChannelMigration.run();
print(result.toString());
```

Migration output:
```
MigrationResult:
  success: true
  channelsCreated: 1
  commentsMigrated: 150
  settingsMigrated: 5
  defaultChannelId: UC123456789
```

## UI Components

### Channel Selector Modal

Located in `lib/widgets/channel_selector_modal.dart`:
- Lists all saved channels with avatars
- Shows connection state for each channel
- Allows switching, editing, and removing channels
- Opens the add channel flow

Usage:
```dart
import 'package:you_tracker/widgets/channel_selector_modal.dart';

// Show the modal
showChannelSelector(context);
```

### Channel Dropdown

Located in `lib/widgets/channel_dropdown.dart`:
- Compact dropdown for the app bar
- Shows active channel avatar and name
- Opens the channel selector on tap

Usage:
```dart
import 'package:you_tracker/widgets/channel_dropdown.dart';

AppBar(
  actions: [
    const ChannelDropdownCompact(),
    // other actions...
  ],
)
```

## Sync Engine Integration

The sync engine supports per-channel sync:

```dart
// Sync specific channel
await SyncEngine.instance.syncNow(channelId: 'UC123456');

// Get channel-specific sync status
final status = SyncEngine.instance.getChannelStatus('UC123456');

// Enqueue change for specific channel
await SyncEngine.instance.enqueueChange(
  opType: SyncOperationType.update,
  entityType: SyncEntityType.comment,
  entityId: commentId,
  channelId: 'UC123456',
);
```

## Adding a New Channel (Code)

```dart
// Using the channel provider
final channelNotifier = ref.read(channelProvider.notifier);
final success = await channelNotifier.addChannelWithGoogle();

if (success) {
  // Channel added successfully
  final activeChannel = ref.read(channelProvider).activeChannel;
  print('Added channel: ${activeChannel?.name}');
}
```

## Testing Multi-Channel Locally

1. **Add first channel**:
   - Launch the app
   - Sign in with Google
   - Verify channel appears in the dropdown

2. **Add second channel**:
   - Tap the channel dropdown
   - Tap "Add Channel"
   - Sign in with a different Google account

3. **Switch between channels**:
   - Tap the channel dropdown
   - Select a different channel
   - Verify comments and settings update

4. **Verify data isolation**:
   - Change theme in channel 1
   - Switch to channel 2
   - Verify theme is different
   - Switch back to channel 1
   - Verify original theme is restored

## Error Handling

Channel errors are exposed through:
- `channel.connectionState` - Current connection state
- `channel.lastError` - Last error message

Handle token expiration:
```dart
if (channel.connectionState == ChannelConnectionState.tokenExpired) {
  await channelNotifier.refreshChannelToken(channel.id);
}
```

## Backward Compatibility

If no channels exist:
- The migration creates a "default" channel
- Single-channel behavior is preserved
- Existing data remains accessible

## Related Files

- `lib/models/channel.dart` - Channel model
- `lib/models/channel.g.dart` - Hive adapters
- `lib/store/channel_store.dart` - Channel state management
- `lib/providers/channel_provider.dart` - Riverpod provider
- `lib/widgets/channel_selector_modal.dart` - Selector UI
- `lib/widgets/channel_dropdown.dart` - Header dropdown
- `lib/storage/migrations/multi_channel_migration.dart` - Migration script
- `lib/src/sync/sync_engine.dart` - Per-channel sync support
