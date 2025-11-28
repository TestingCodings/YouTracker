import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:you_tracker/models/channel.dart';
import 'package:you_tracker/store/channel_store.dart';

void main() {
  group('Multi-Channel Integration Tests', () {
    late ChannelStore channelStore;

    setUpAll(() async {
      // Initialize Hive with a temporary directory
      Hive.init('./test_hive');
      
      // Register adapters
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ChannelAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(ChannelConnectionStateAdapter());
      }
    });

    setUp(() async {
      channelStore = ChannelStore.forTest();
      await channelStore.initialize();
    });

    tearDown(() async {
      await channelStore.clearAll();
      await channelStore.dispose();
    });

    tearDownAll(() async {
      await Hive.deleteFromDisk();
    });

    group('Channel CRUD Operations', () {
      test('should add a channel', () async {
        final channel = Channel(
          id: 'channel_1',
          name: 'Test Channel 1',
          provider: 'youtube',
          email: 'test1@example.com',
        );

        await channelStore.addChannel(channel);

        expect(channelStore.channelCount, 1);
        expect(channelStore.channels.first.id, 'channel_1');
      });

      test('should add multiple channels', () async {
        final channel1 = Channel(id: 'channel_1', name: 'Channel 1');
        final channel2 = Channel(id: 'channel_2', name: 'Channel 2');

        await channelStore.addChannel(channel1);
        await channelStore.addChannel(channel2);

        expect(channelStore.channelCount, 2);
      });

      test('should get channel by ID', () async {
        final channel = Channel(id: 'channel_1', name: 'Test Channel');
        await channelStore.addChannel(channel);

        final retrieved = channelStore.getChannel('channel_1');

        expect(retrieved, isNotNull);
        expect(retrieved!.name, 'Test Channel');
      });

      test('should update a channel', () async {
        final channel = Channel(id: 'channel_1', name: 'Original Name');
        await channelStore.addChannel(channel);

        final updated = channel.copyWith(name: 'Updated Name');
        await channelStore.updateChannel(updated);

        final retrieved = channelStore.getChannel('channel_1');
        expect(retrieved!.name, 'Updated Name');
      });

      test('should remove a channel', () async {
        final channel = Channel(id: 'channel_1', name: 'Test Channel');
        await channelStore.addChannel(channel);
        expect(channelStore.channelCount, 1);

        await channelStore.removeChannel('channel_1');

        expect(channelStore.channelCount, 0);
      });
    });

    group('Active Channel Management', () {
      test('should set first channel as active automatically', () async {
        final channel = Channel(id: 'channel_1', name: 'First Channel');
        await channelStore.addChannel(channel);

        expect(channelStore.activeChannel, isNotNull);
        expect(channelStore.activeChannel!.id, 'channel_1');
        expect(channelStore.activeChannel!.isActive, true);
      });

      test('should switch active channel', () async {
        final channel1 = Channel(id: 'channel_1', name: 'Channel 1');
        final channel2 = Channel(id: 'channel_2', name: 'Channel 2');

        await channelStore.addChannel(channel1);
        await channelStore.addChannel(channel2);

        // First channel should be active by default
        expect(channelStore.activeChannel!.id, 'channel_1');

        // Switch to second channel
        await channelStore.setActiveChannel('channel_2');

        expect(channelStore.activeChannel!.id, 'channel_2');
        expect(channelStore.activeChannel!.isActive, true);

        // First channel should no longer be active
        final firstChannel = channelStore.getChannel('channel_1');
        expect(firstChannel!.isActive, false);
      });

      test('should switch to another channel when active is removed', () async {
        final channel1 = Channel(id: 'channel_1', name: 'Channel 1');
        final channel2 = Channel(id: 'channel_2', name: 'Channel 2');

        await channelStore.addChannel(channel1);
        await channelStore.addChannel(channel2);

        expect(channelStore.activeChannel!.id, 'channel_1');

        await channelStore.removeChannel('channel_1');

        expect(channelStore.activeChannel!.id, 'channel_2');
      });

      test('should have no active channel when all are removed', () async {
        final channel = Channel(id: 'channel_1', name: 'Only Channel');
        await channelStore.addChannel(channel);

        await channelStore.removeChannel('channel_1');

        expect(channelStore.activeChannel, isNull);
        expect(channelStore.channelCount, 0);
      });
    });

    group('Channel Settings Prefix', () {
      test('should generate correct settings prefix for active channel', () async {
        final channel = Channel(id: 'my_channel_id', name: 'My Channel');
        await channelStore.addChannel(channel);

        final prefix = channelStore.getChannelSettingsPrefix(null);

        expect(prefix, 'channel_my_channel_id_');
      });

      test('should generate correct settings prefix for specific channel', () async {
        final prefix = channelStore.getChannelSettingsPrefix('specific_channel');

        expect(prefix, 'channel_specific_channel_');
      });

      test('should use default channel ID when no active channel', () async {
        final prefix = channelStore.getChannelSettingsPrefix(null);

        expect(prefix, 'channel_default_');
      });
    });

    group('Channel State Updates', () {
      test('should update connection state', () async {
        final channel = Channel(
          id: 'channel_1',
          name: 'Channel',
          connectionState: ChannelConnectionState.disconnected,
        );
        await channelStore.addChannel(channel);

        await channelStore.updateConnectionState(
          'channel_1',
          ChannelConnectionState.connected,
        );

        final updated = channelStore.getChannel('channel_1');
        expect(updated!.connectionState, ChannelConnectionState.connected);
      });

      test('should update connection state with error', () async {
        final channel = Channel(id: 'channel_1', name: 'Channel');
        await channelStore.addChannel(channel);

        await channelStore.updateConnectionState(
          'channel_1',
          ChannelConnectionState.error,
          error: 'Connection failed',
        );

        final updated = channelStore.getChannel('channel_1');
        expect(updated!.connectionState, ChannelConnectionState.error);
        expect(updated.lastError, 'Connection failed');
      });

      test('should update last sync time', () async {
        final channel = Channel(id: 'channel_1', name: 'Channel');
        await channelStore.addChannel(channel);

        final before = channelStore.getChannel('channel_1')!.lastSyncedAt;
        expect(before, isNull);

        await channelStore.updateLastSyncTime('channel_1');

        final after = channelStore.getChannel('channel_1')!.lastSyncedAt;
        expect(after, isNotNull);
      });

      test('should update tokens', () async {
        final channel = Channel(
          id: 'channel_1',
          name: 'Channel',
          accessToken: 'old_token',
        );
        await channelStore.addChannel(channel);

        final newExpiry = DateTime.now().add(const Duration(hours: 1));
        await channelStore.updateTokens(
          channelId: 'channel_1',
          accessToken: 'new_token',
          tokenExpiresAt: newExpiry,
        );

        final updated = channelStore.getChannel('channel_1');
        expect(updated!.accessToken, 'new_token');
        expect(updated.tokenExpiresAt, newExpiry);
        expect(updated.connectionState, ChannelConnectionState.connected);
      });
    });

    group('Channel Change Events', () {
      test('should emit event when channel is added', () async {
        final events = <ChannelChangeEvent>[];
        final subscription = channelStore.onChannelChange.listen(events.add);

        final channel = Channel(id: 'channel_1', name: 'New Channel');
        await channelStore.addChannel(channel);

        await Future.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(events.length, greaterThanOrEqualTo(1));
        expect(events.any((e) => e.type == ChannelChangeType.added), true);
      });

      test('should emit event when channel is updated', () async {
        final channel = Channel(id: 'channel_1', name: 'Channel');
        await channelStore.addChannel(channel);

        final events = <ChannelChangeEvent>[];
        final subscription = channelStore.onChannelChange.listen(events.add);

        await channelStore.updateChannel(channel.copyWith(name: 'Updated'));

        await Future.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(events.any((e) => e.type == ChannelChangeType.updated), true);
      });

      test('should emit event when active channel changes', () async {
        final channel1 = Channel(id: 'channel_1', name: 'Channel 1');
        final channel2 = Channel(id: 'channel_2', name: 'Channel 2');
        await channelStore.addChannel(channel1);
        await channelStore.addChannel(channel2);

        final events = <ChannelChangeEvent>[];
        final subscription = channelStore.onChannelChange.listen(events.add);

        await channelStore.setActiveChannel('channel_2');

        await Future.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(events.any((e) => e.type == ChannelChangeType.activated), true);
      });
    });
  });
}
