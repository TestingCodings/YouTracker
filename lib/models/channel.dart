import 'package:hive/hive.dart';

part 'channel.g.dart';

/// Represents an authenticated YouTube channel for multi-channel support.
@HiveType(typeId: 3)
class Channel extends HiveObject {
  /// Unique identifier for this channel (typically the YouTube channel ID).
  @HiveField(0)
  final String id;

  /// Display name for the channel.
  @HiveField(1)
  final String name;

  /// Provider type (e.g., 'youtube', 'github', 'slack').
  @HiveField(2)
  final String provider;

  /// OAuth access token for API calls.
  @HiveField(3)
  final String? accessToken;

  /// OAuth refresh token for token renewal.
  @HiveField(4)
  final String? refreshToken;

  /// URL to the channel's avatar/profile image.
  @HiveField(5)
  final String? avatarUrl;

  /// Timestamp when the channel was first added.
  @HiveField(6)
  final DateTime createdAt;

  /// Timestamp of the last successful sync for this channel.
  @HiveField(7)
  final DateTime? lastSyncedAt;

  /// Whether this channel is currently the active one.
  @HiveField(8)
  final bool isActive;

  /// Token expiry time.
  @HiveField(9)
  final DateTime? tokenExpiresAt;

  /// Email associated with the channel (for display purposes).
  @HiveField(10)
  final String? email;

  /// User ID from the auth provider.
  @HiveField(11)
  final String? userId;

  /// Current connection status.
  @HiveField(12)
  final ChannelConnectionState connectionState;

  /// Last error message, if any.
  @HiveField(13)
  final String? lastError;

  Channel({
    required this.id,
    required this.name,
    this.provider = 'youtube',
    this.accessToken,
    this.refreshToken,
    this.avatarUrl,
    DateTime? createdAt,
    this.lastSyncedAt,
    this.isActive = false,
    this.tokenExpiresAt,
    this.email,
    this.userId,
    this.connectionState = ChannelConnectionState.disconnected,
    this.lastError,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a copy of this channel with updated fields.
  Channel copyWith({
    String? id,
    String? name,
    String? provider,
    String? accessToken,
    String? refreshToken,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastSyncedAt,
    bool? isActive,
    DateTime? tokenExpiresAt,
    String? email,
    String? userId,
    ChannelConnectionState? connectionState,
    String? lastError,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isActive: isActive ?? this.isActive,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      email: email ?? this.email,
      userId: userId ?? this.userId,
      connectionState: connectionState ?? this.connectionState,
      lastError: lastError ?? this.lastError,
    );
  }

  /// Whether the access token is expired.
  bool get isTokenExpired {
    if (tokenExpiresAt == null) return true;
    // Add a 5-minute buffer before expiry
    return DateTime.now().isAfter(
      tokenExpiresAt!.subtract(const Duration(minutes: 5)),
    );
  }

  /// Whether the channel has valid authentication credentials.
  bool get hasValidCredentials {
    return accessToken != null && !isTokenExpired;
  }

  /// Whether the channel is connected and authenticated.
  bool get isConnected => connectionState == ChannelConnectionState.connected;

  /// Converts this channel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'isActive': isActive,
      'tokenExpiresAt': tokenExpiresAt?.toIso8601String(),
      'email': email,
      'userId': userId,
      'connectionState': connectionState.name,
      'lastError': lastError,
    };
  }

  /// Creates a Channel from a JSON map.
  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: json['provider'] as String? ?? 'youtube',
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? false,
      tokenExpiresAt: json['tokenExpiresAt'] != null
          ? DateTime.parse(json['tokenExpiresAt'] as String)
          : null,
      email: json['email'] as String?,
      userId: json['userId'] as String?,
      connectionState: ChannelConnectionState.values.firstWhere(
        (e) => e.name == json['connectionState'],
        orElse: () => ChannelConnectionState.disconnected,
      ),
      lastError: json['lastError'] as String?,
    );
  }

  @override
  String toString() {
    return 'Channel(id: $id, name: $name, provider: $provider, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Channel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Connection state for a channel.
@HiveType(typeId: 4)
enum ChannelConnectionState {
  @HiveField(0)
  disconnected,

  @HiveField(1)
  connecting,

  @HiveField(2)
  connected,

  @HiveField(3)
  error,

  @HiveField(4)
  tokenExpired,
}

/// Default channel ID for migration of existing data.
const String defaultChannelId = 'default';
