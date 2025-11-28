import 'package:flutter_test/flutter_test.dart';
import 'package:you_tracker/models/channel.dart';

void main() {
  group('Channel Model', () {
    test('should create a Channel with required fields', () {
      final channel = Channel(
        id: 'test_channel_id',
        name: 'Test Channel',
        provider: 'youtube',
      );

      expect(channel.id, 'test_channel_id');
      expect(channel.name, 'Test Channel');
      expect(channel.provider, 'youtube');
      expect(channel.isActive, false);
      expect(channel.connectionState, ChannelConnectionState.disconnected);
    });

    test('should create Channel with all fields', () {
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 1));

      final channel = Channel(
        id: 'channel_123',
        name: 'My YouTube Channel',
        provider: 'youtube',
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_123',
        avatarUrl: 'https://example.com/avatar.jpg',
        createdAt: now,
        lastSyncedAt: now,
        isActive: true,
        tokenExpiresAt: expiry,
        email: 'test@example.com',
        userId: 'user_123',
        connectionState: ChannelConnectionState.connected,
      );

      expect(channel.id, 'channel_123');
      expect(channel.name, 'My YouTube Channel');
      expect(channel.accessToken, 'access_token_123');
      expect(channel.refreshToken, 'refresh_token_123');
      expect(channel.avatarUrl, 'https://example.com/avatar.jpg');
      expect(channel.isActive, true);
      expect(channel.tokenExpiresAt, expiry);
      expect(channel.email, 'test@example.com');
      expect(channel.connectionState, ChannelConnectionState.connected);
    });

    test('should detect expired tokens', () {
      final expiredChannel = Channel(
        id: 'channel_1',
        name: 'Expired Channel',
        tokenExpiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(expiredChannel.isTokenExpired, true);
      expect(expiredChannel.hasValidCredentials, false);

      final validChannel = Channel(
        id: 'channel_2',
        name: 'Valid Channel',
        accessToken: 'valid_token',
        tokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(validChannel.isTokenExpired, false);
      expect(validChannel.hasValidCredentials, true);
    });

    test('should handle null token expiry as expired', () {
      final channel = Channel(
        id: 'channel_1',
        name: 'No Expiry Channel',
        accessToken: 'token',
      );
      expect(channel.isTokenExpired, true);
      expect(channel.hasValidCredentials, false);
    });

    test('copyWith should update specified fields', () {
      final original = Channel(
        id: 'channel_1',
        name: 'Original Name',
        isActive: false,
        connectionState: ChannelConnectionState.disconnected,
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        isActive: true,
        connectionState: ChannelConnectionState.connected,
      );

      expect(updated.id, 'channel_1'); // Unchanged
      expect(updated.name, 'Updated Name');
      expect(updated.isActive, true);
      expect(updated.connectionState, ChannelConnectionState.connected);
    });

    test('should convert Channel to JSON', () {
      final channel = Channel(
        id: 'channel_123',
        name: 'Test Channel',
        provider: 'youtube',
        email: 'test@example.com',
        isActive: true,
      );

      final json = channel.toJson();

      expect(json['id'], 'channel_123');
      expect(json['name'], 'Test Channel');
      expect(json['provider'], 'youtube');
      expect(json['email'], 'test@example.com');
      expect(json['isActive'], true);
    });

    test('should create Channel from JSON', () {
      final json = {
        'id': 'channel_123',
        'name': 'Test Channel',
        'provider': 'youtube',
        'email': 'test@example.com',
        'isActive': true,
        'connectionState': 'connected',
        'createdAt': '2024-01-15T10:00:00.000',
      };

      final channel = Channel.fromJson(json);

      expect(channel.id, 'channel_123');
      expect(channel.name, 'Test Channel');
      expect(channel.provider, 'youtube');
      expect(channel.email, 'test@example.com');
      expect(channel.isActive, true);
      expect(channel.connectionState, ChannelConnectionState.connected);
    });

    test('should use default values for missing JSON fields', () {
      final json = {
        'id': 'channel_123',
        'name': 'Test Channel',
      };

      final channel = Channel.fromJson(json);

      expect(channel.id, 'channel_123');
      expect(channel.name, 'Test Channel');
      expect(channel.provider, 'youtube');
      expect(channel.isActive, false);
      expect(channel.connectionState, ChannelConnectionState.disconnected);
    });

    test('should compare channels by ID', () {
      final channel1 = Channel(id: 'channel_1', name: 'Channel 1');
      final channel2 = Channel(id: 'channel_1', name: 'Channel 1 Copy');
      final channel3 = Channel(id: 'channel_2', name: 'Channel 2');

      expect(channel1 == channel2, true);
      expect(channel1.hashCode == channel2.hashCode, true);
      expect(channel1 == channel3, false);
    });

    test('isConnected should return true only when connected', () {
      expect(
        Channel(id: '1', name: 'C', connectionState: ChannelConnectionState.connected).isConnected,
        true,
      );
      expect(
        Channel(id: '1', name: 'C', connectionState: ChannelConnectionState.disconnected).isConnected,
        false,
      );
      expect(
        Channel(id: '1', name: 'C', connectionState: ChannelConnectionState.error).isConnected,
        false,
      );
      expect(
        Channel(id: '1', name: 'C', connectionState: ChannelConnectionState.connecting).isConnected,
        false,
      );
    });
  });

  group('ChannelConnectionState', () {
    test('should have all expected states', () {
      expect(ChannelConnectionState.values.length, 5);
      expect(ChannelConnectionState.values, contains(ChannelConnectionState.disconnected));
      expect(ChannelConnectionState.values, contains(ChannelConnectionState.connecting));
      expect(ChannelConnectionState.values, contains(ChannelConnectionState.connected));
      expect(ChannelConnectionState.values, contains(ChannelConnectionState.error));
      expect(ChannelConnectionState.values, contains(ChannelConnectionState.tokenExpired));
    });
  });

  group('defaultChannelId', () {
    test('should be defined', () {
      expect(defaultChannelId, 'default');
    });
  });
}
