import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/channel.dart';
import '../services/auth/youtube_auth_service.dart';
import '../store/channel_store.dart';

/// Provider for channel state management.
final channelProvider =
    StateNotifierProvider<ChannelNotifier, ChannelState>((ref) {
  return ChannelNotifier();
});

/// State for channel management.
class ChannelState {
  final List<Channel> channels;
  final Channel? activeChannel;
  final bool isLoading;
  final String? error;

  const ChannelState({
    this.channels = const [],
    this.activeChannel,
    this.isLoading = false,
    this.error,
  });

  ChannelState copyWith({
    List<Channel>? channels,
    Channel? activeChannel,
    bool? isLoading,
    String? error,
  }) {
    return ChannelState(
      channels: channels ?? this.channels,
      activeChannel: activeChannel ?? this.activeChannel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Whether there are multiple channels.
  bool get hasMultipleChannels => channels.length > 1;

  /// Whether there are no channels.
  bool get isEmpty => channels.isEmpty;
}

/// Notifier for channel state.
class ChannelNotifier extends StateNotifier<ChannelState> {
  ChannelNotifier() : super(const ChannelState());

  StreamSubscription<ChannelChangeEvent>? _subscription;
  YouTubeAuthService? _authService;

  /// Initializes the channel notifier.
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Initialize channel store
      await ChannelStore.instance.initialize();

      // Subscribe to channel changes
      _subscription = ChannelStore.instance.onChannelChange.listen(_onChannelChange);

      // Load initial state
      _refreshState();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void _refreshState() {
    state = state.copyWith(
      channels: ChannelStore.instance.channels,
      activeChannel: ChannelStore.instance.activeChannel,
    );
  }

  void _onChannelChange(ChannelChangeEvent event) {
    _refreshState();
  }

  /// Sets the active channel.
  Future<void> setActiveChannel(String channelId) async {
    try {
      await ChannelStore.instance.setActiveChannel(channelId);
      _refreshState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Updates the name of a channel.
  Future<void> updateChannelName(String channelId, String name) async {
    try {
      final channel = ChannelStore.instance.getChannel(channelId);
      if (channel != null) {
        await ChannelStore.instance.updateChannel(
          channel.copyWith(name: name),
        );
        _refreshState();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Removes a channel.
  Future<void> removeChannel(String channelId) async {
    try {
      await ChannelStore.instance.removeChannel(channelId);
      _refreshState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Adds a new channel using Google/YouTube sign-in.
  Future<bool> addChannelWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      _authService ??= YouTubeAuthService();
      final result = await _authService!.signIn();

      if (!result.success) {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
        return false;
      }

      if (result.user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to get user information',
        );
        return false;
      }

      // Check if channel already exists
      final existingChannel = ChannelStore.instance.getChannel(result.user!.id);
      if (existingChannel != null) {
        // Update existing channel with new tokens
        await ChannelStore.instance.updateTokens(
          channelId: result.user!.id,
          accessToken: result.accessToken,
          tokenExpiresAt: result.tokenExpiry,
        );
        await ChannelStore.instance.setActiveChannel(result.user!.id);
      } else {
        // Create new channel
        final newChannel = Channel(
          id: result.user!.id,
          name: result.user!.displayName,
          provider: 'youtube',
          accessToken: result.accessToken,
          tokenExpiresAt: result.tokenExpiry,
          avatarUrl: result.user!.photoUrl,
          email: result.user!.email,
          userId: result.user!.id,
          connectionState: ChannelConnectionState.connected,
          isActive: true,
        );
        await ChannelStore.instance.addChannel(newChannel);
      }

      _refreshState();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Refreshes the token for a channel.
  Future<void> refreshChannelToken(String channelId) async {
    try {
      await ChannelStore.instance.updateConnectionState(
        channelId,
        ChannelConnectionState.connecting,
      );

      _authService ??= YouTubeAuthService();
      final newToken = await _authService!.refreshToken();

      if (newToken != null) {
        await ChannelStore.instance.updateTokens(
          channelId: channelId,
          accessToken: newToken,
          tokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        await ChannelStore.instance.updateConnectionState(
          channelId,
          ChannelConnectionState.connected,
        );
      } else {
        await ChannelStore.instance.updateConnectionState(
          channelId,
          ChannelConnectionState.tokenExpired,
          error: 'Token refresh failed. Please re-authenticate.',
        );
      }

      _refreshState();
    } catch (e) {
      await ChannelStore.instance.updateConnectionState(
        channelId,
        ChannelConnectionState.error,
        error: e.toString(),
      );
      _refreshState();
    }
  }

  /// Gets the access token for a specific channel.
  Future<String?> getAccessTokenForChannel(String? channelId) async {
    final channel = channelId != null
        ? ChannelStore.instance.getChannel(channelId)
        : state.activeChannel;

    if (channel == null) return null;

    if (channel.isTokenExpired) {
      await refreshChannelToken(channel.id);
      // Get updated channel
      final updated = ChannelStore.instance.getChannel(channel.id);
      return updated?.accessToken;
    }

    return channel.accessToken;
  }

  /// Clears the error state.
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authService?.dispose();
    super.dispose();
  }
}

/// Provider for the active channel ID (for namespacing).
final activeChannelIdProvider = Provider<String?>((ref) {
  final channelState = ref.watch(channelProvider);
  return channelState.activeChannel?.id;
});

/// Provider for channel-scoped settings key prefix.
final channelSettingsPrefixProvider = Provider<String>((ref) {
  final channelId = ref.watch(activeChannelIdProvider);
  return ChannelStore.instance.getChannelSettingsPrefix(channelId);
});
