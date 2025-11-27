import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token storage for YouTube OAuth tokens.
/// Uses flutter_secure_storage to persist tokens securely.
class TokenStorage {
  static const String _accessTokenKey = 'youtube_access_token';
  static const String _refreshTokenKey = 'youtube_refresh_token';
  static const String _expiryKey = 'youtube_token_expiry';
  static const String _scopesKey = 'youtube_token_scopes';
  static const String _userIdKey = 'youtube_user_id';
  static const String _userEmailKey = 'youtube_user_email';
  static const String _userNameKey = 'youtube_user_name';
  static const String _userPhotoUrlKey = 'youtube_user_photo_url';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  /// Saves OAuth tokens and related metadata.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    required DateTime expiry,
    List<String>? scopes,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    await _storage.write(key: _expiryKey, value: expiry.toIso8601String());
    if (scopes != null && scopes.isNotEmpty) {
      await _storage.write(key: _scopesKey, value: jsonEncode(scopes));
    }
  }

  /// Saves user information.
  Future<void> saveUserInfo({
    required String userId,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userEmailKey, value: email);
    await _storage.write(key: _userNameKey, value: name);
    if (photoUrl != null) {
      await _storage.write(key: _userPhotoUrlKey, value: photoUrl);
    }
  }

  /// Retrieves the stored access token.
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Retrieves the stored refresh token.
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Retrieves the token expiry time.
  Future<DateTime?> getTokenExpiry() async {
    final expiryString = await _storage.read(key: _expiryKey);
    if (expiryString == null) return null;
    return DateTime.tryParse(expiryString);
  }

  /// Retrieves the stored scopes.
  Future<List<String>?> getScopes() async {
    final scopesString = await _storage.read(key: _scopesKey);
    if (scopesString == null) return null;
    final List<dynamic> decoded = jsonDecode(scopesString);
    return decoded.cast<String>();
  }

  /// Retrieves stored user ID.
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Retrieves stored user email.
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  /// Retrieves stored user name.
  Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  /// Retrieves stored user photo URL.
  Future<String?> getUserPhotoUrl() async {
    return await _storage.read(key: _userPhotoUrlKey);
  }

  /// Checks if the stored token is expired.
  /// Returns true if expired or if no token exists.
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    // Add a 5-minute buffer before expiry to handle API call latency
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)));
  }

  /// Checks if valid tokens are stored.
  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;
    return !await isTokenExpired();
  }

  /// Gets all stored token data as a map.
  Future<StoredTokenData?> getStoredTokenData() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return null;

    return StoredTokenData(
      accessToken: accessToken,
      refreshToken: await getRefreshToken(),
      expiry: await getTokenExpiry(),
      scopes: await getScopes(),
      userId: await getUserId(),
      email: await getUserEmail(),
      name: await getUserName(),
      photoUrl: await getUserPhotoUrl(),
    );
  }

  /// Clears all stored tokens and user data.
  Future<void> clearAll() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiryKey);
    await _storage.delete(key: _scopesKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userPhotoUrlKey);
  }

  /// Updates only the access token and expiry (for token refresh).
  Future<void> updateAccessToken({
    required String accessToken,
    required DateTime expiry,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _expiryKey, value: expiry.toIso8601String());
  }
}

/// Data class for stored token information.
class StoredTokenData {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiry;
  final List<String>? scopes;
  final String? userId;
  final String? email;
  final String? name;
  final String? photoUrl;

  StoredTokenData({
    required this.accessToken,
    this.refreshToken,
    this.expiry,
    this.scopes,
    this.userId,
    this.email,
    this.name,
    this.photoUrl,
  });

  bool get isExpired {
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry!.subtract(const Duration(minutes: 5)));
  }
}
