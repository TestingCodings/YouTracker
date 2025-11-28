import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A wrapper over [FlutterSecureStorage] for platform-secure storage of OAuth tokens,
/// refresh tokens, and small secrets.
///
/// Features:
/// - Key namespacing to avoid collisions
/// - iOS Keychain with configurable accessibility
/// - Android EncryptedSharedPreferences
/// - Read/write/delete operations with type safety
///
/// Usage:
/// ```dart
/// final storage = SecureStorage();
/// await storage.write(key: 'my_key', value: 'secret_value');
/// final value = await storage.read(key: 'my_key');
/// await storage.delete(key: 'my_key');
/// ```
class SecureStorage {
  /// Namespace prefix for all keys to avoid collisions with other storage users.
  final String namespace;

  final FlutterSecureStorage _storage;

  /// Creates a [SecureStorage] instance with the given namespace.
  ///
  /// [namespace] - Prefix for all keys (default: 'you_tracker')
  /// [storage] - Optional custom [FlutterSecureStorage] for testing
  SecureStorage({
    this.namespace = 'you_tracker',
    FlutterSecureStorage? storage,
  }) : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                sharedPreferencesName: 'you_tracker_secure_prefs',
                preferencesKeyPrefix: 'you_tracker_',
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
                accountName: 'YouTrackerSecureStorage',
              ),
              lOptions: LinuxOptions(),
              wOptions: WindowsOptions(),
              mOptions: MacOsOptions(),
              webOptions: WebOptions(
                dbName: 'YouTrackerSecureStorage',
                publicKey: 'YouTrackerSecureStorage',
              ),
            );

  /// Generates a namespaced key.
  String _namespacedKey(String key) => '${namespace}_$key';

  /// Writes a string value to secure storage.
  ///
  /// [key] - The key to store the value under
  /// [value] - The string value to store
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: _namespacedKey(key), value: value);
  }

  /// Reads a string value from secure storage.
  ///
  /// Returns null if the key doesn't exist.
  Future<String?> read({required String key}) async {
    return await _storage.read(key: _namespacedKey(key));
  }

  /// Deletes a value from secure storage.
  Future<void> delete({required String key}) async {
    await _storage.delete(key: _namespacedKey(key));
  }

  /// Checks if a key exists in secure storage.
  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(key: _namespacedKey(key));
  }

  /// Writes a JSON-serializable object to secure storage.
  ///
  /// [key] - The key to store the value under
  /// [value] - A JSON-serializable Map
  Future<void> writeJson({
    required String key,
    required Map<String, dynamic> value,
  }) async {
    final jsonString = jsonEncode(value);
    await write(key: key, value: jsonString);
  }

  /// Reads a JSON object from secure storage.
  ///
  /// Returns null if the key doesn't exist or if JSON parsing fails.
  Future<Map<String, dynamic>?> readJson({required String key}) async {
    final jsonString = await read(key: key);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // JSON parsing failed, return null
      return null;
    }
  }

  /// Deletes all values in the current namespace.
  ///
  /// WARNING: This will delete all keys that start with the namespace prefix.
  Future<void> deleteAll() async {
    final allKeys = await _storage.readAll();
    for (final key in allKeys.keys) {
      if (key.startsWith('${namespace}_')) {
        await _storage.delete(key: key);
      }
    }
  }

  /// Returns all keys in the current namespace (without the namespace prefix).
  Future<List<String>> getAllKeys() async {
    final allEntries = await _storage.readAll();
    final prefix = '${namespace}_';
    return allEntries.keys
        .where((key) => key.startsWith(prefix))
        .map((key) => key.substring(prefix.length))
        .toList();
  }
}

/// Pre-defined key constants for token storage.
/// Use these constants to ensure consistency across the app.
class SecureStorageKeys {
  /// OAuth access token
  static const String accessToken = 'access_token';

  /// OAuth refresh token
  static const String refreshToken = 'refresh_token';

  /// Token expiry timestamp (ISO 8601)
  static const String tokenExpiry = 'token_expiry';

  /// Session token for backend communication
  static const String sessionToken = 'session_token';

  /// User ID
  static const String userId = 'user_id';

  /// Hive encryption key (base64 encoded)
  static const String hiveEncryptionKey = 'hive_encryption_key';

  /// API key (if needed for any external services)
  static const String apiKey = 'api_key';

  /// Prevent instantiation
  SecureStorageKeys._();
}

/// Extension methods for [SecureStorage] to provide convenience methods
/// for common token operations.
extension SecureStorageTokenExtensions on SecureStorage {
  /// Stores OAuth tokens with expiry.
  Future<void> storeTokens({
    required String accessToken,
    String? refreshToken,
    required DateTime expiry,
  }) async {
    await write(key: SecureStorageKeys.accessToken, value: accessToken);
    if (refreshToken != null) {
      await write(key: SecureStorageKeys.refreshToken, value: refreshToken);
    }
    await write(
      key: SecureStorageKeys.tokenExpiry,
      value: expiry.toIso8601String(),
    );
  }

  /// Retrieves the stored access token.
  Future<String?> getAccessToken() async {
    return await read(key: SecureStorageKeys.accessToken);
  }

  /// Retrieves the stored refresh token.
  Future<String?> getRefreshToken() async {
    return await read(key: SecureStorageKeys.refreshToken);
  }

  /// Retrieves the token expiry.
  Future<DateTime?> getTokenExpiry() async {
    final expiryString = await read(key: SecureStorageKeys.tokenExpiry);
    if (expiryString == null) return null;
    return DateTime.tryParse(expiryString);
  }

  /// Checks if the token is expired (with 5-minute buffer).
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)));
  }

  /// Clears all stored tokens.
  Future<void> clearTokens() async {
    await delete(key: SecureStorageKeys.accessToken);
    await delete(key: SecureStorageKeys.refreshToken);
    await delete(key: SecureStorageKeys.tokenExpiry);
    await delete(key: SecureStorageKeys.sessionToken);
  }
}
