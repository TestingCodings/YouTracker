import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import 'secure_storage.dart';

/// Helper for creating and managing encrypted Hive boxes.
///
/// Uses HiveAesCipher for encryption with keys stored securely via [SecureStorage].
/// Provides helper methods to migrate existing unencrypted boxes to encrypted ones.
///
/// ## Security Notes:
/// - NEVER commit the encryption key to version control
/// - Store the key using flutter_secure_storage (via [SecureStorage])
/// - For production, consider fetching the key from a secure backend on first launch
///
/// ## Usage:
/// ```dart
/// final helper = HiveCryptoHelper();
/// await helper.initialize();
///
/// // Open an encrypted box
/// final box = await helper.openEncryptedBox<String>('my_secure_box');
/// await box.put('key', 'secret_value');
/// ```
class HiveCryptoHelper {
  final SecureStorage _secureStorage;
  HiveAesCipher? _cipher;
  bool _isInitialized = false;

  /// Creates a [HiveCryptoHelper] instance.
  ///
  /// [secureStorage] - Optional custom secure storage for testing
  HiveCryptoHelper({SecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorage();

  /// Whether the helper has been initialized.
  bool get isInitialized => _isInitialized;

  /// The cipher used for encryption (null if not initialized).
  HiveAesCipher? get cipher => _cipher;

  /// Initializes the crypto helper by loading or generating the encryption key.
  ///
  /// This must be called before using any encrypted box operations.
  /// The key is stored securely using [SecureStorage].
  Future<void> initialize() async {
    if (_isInitialized) return;

    final key = await _loadOrGenerateKey();
    _cipher = HiveAesCipher(key);
    _isInitialized = true;
  }

  /// Loads the encryption key from secure storage, or generates a new one.
  Future<Uint8List> _loadOrGenerateKey() async {
    final storedKey = await _secureStorage.read(
      key: SecureStorageKeys.hiveEncryptionKey,
    );

    if (storedKey != null) {
      try {
        return base64Decode(storedKey);
      } catch (e) {
        // Invalid stored key, generate new one
      }
    }

    // Generate a new 256-bit key
    final key = _generateSecureKey();
    await _secureStorage.write(
      key: SecureStorageKeys.hiveEncryptionKey,
      value: base64Encode(key),
    );
    return key;
  }

  /// Generates a cryptographically secure 256-bit key.
  Uint8List _generateSecureKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
  }

  /// Opens an encrypted Hive box.
  ///
  /// [name] - The name of the box
  /// [path] - Optional path for the box file
  ///
  /// Throws [StateError] if the helper is not initialized.
  Future<Box<T>> openEncryptedBox<T>(
    String name, {
    String? path,
  }) async {
    _ensureInitialized();

    return await Hive.openBox<T>(
      name,
      encryptionCipher: _cipher,
      path: path,
    );
  }

  /// Opens an encrypted lazy Hive box.
  ///
  /// [name] - The name of the box
  /// [path] - Optional path for the box file
  ///
  /// Throws [StateError] if the helper is not initialized.
  Future<LazyBox<T>> openEncryptedLazyBox<T>(
    String name, {
    String? path,
  }) async {
    _ensureInitialized();

    return await Hive.openLazyBox<T>(
      name,
      encryptionCipher: _cipher,
      path: path,
    );
  }

  /// Migrates an unencrypted box to an encrypted one.
  ///
  /// [unencryptedBoxName] - Name of the existing unencrypted box
  /// [encryptedBoxName] - Name for the new encrypted box
  /// [deleteOriginal] - Whether to delete the original box after migration
  ///
  /// Returns the number of entries migrated.
  ///
  /// WARNING: This is a destructive operation if [deleteOriginal] is true.
  /// Ensure you have backups before running in production.
  Future<int> migrateToEncrypted<T>({
    required String unencryptedBoxName,
    required String encryptedBoxName,
    bool deleteOriginal = false,
  }) async {
    _ensureInitialized();

    // Open the unencrypted box
    final unencryptedBox = await Hive.openBox<T>(unencryptedBoxName);
    final entries = unencryptedBox.toMap();

    if (entries.isEmpty) {
      await unencryptedBox.close();
      return 0;
    }

    // Open the encrypted box
    final encryptedBox = await openEncryptedBox<T>(encryptedBoxName);

    // Copy all entries
    for (final entry in entries.entries) {
      await encryptedBox.put(entry.key, entry.value);
    }

    await unencryptedBox.close();
    await encryptedBox.close();

    // Optionally delete the original box
    if (deleteOriginal) {
      await Hive.deleteBoxFromDisk(unencryptedBoxName);
    }

    return entries.length;
  }

  /// Checks if a box exists on disk.
  Future<bool> boxExists(String name) async {
    return await Hive.boxExists(name);
  }

  /// Deletes an encrypted box from disk.
  Future<void> deleteEncryptedBox(String name) async {
    if (await Hive.boxExists(name)) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).close();
      }
      await Hive.deleteBoxFromDisk(name);
    }
  }

  /// Ensures the helper is initialized.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'HiveCryptoHelper is not initialized. Call initialize() first.',
      );
    }
  }

  /// Re-encrypts all boxes with a new key.
  ///
  /// This is useful when you need to rotate encryption keys.
  /// Pass a list of box names and their types.
  ///
  /// WARNING: This is a potentially destructive operation.
  /// Ensure you have backups before running in production.
  Future<void> reEncryptWithNewKey<T>({
    required List<String> boxNames,
  }) async {
    _ensureInitialized();

    // Store all data
    final Map<String, Map<dynamic, T>> allData = {};
    for (final name in boxNames) {
      if (await Hive.boxExists(name)) {
        final box = await openEncryptedBox<T>(name);
        allData[name] = Map<dynamic, T>.from(box.toMap());
        await box.close();
      }
    }

    // Generate new key
    final newKey = _generateSecureKey();
    await _secureStorage.write(
      key: SecureStorageKeys.hiveEncryptionKey,
      value: base64Encode(newKey),
    );
    _cipher = HiveAesCipher(newKey);

    // Re-encrypt all boxes with new key
    for (final entry in allData.entries) {
      await Hive.deleteBoxFromDisk(entry.key);
      final box = await openEncryptedBox<T>(entry.key);
      for (final dataEntry in entry.value.entries) {
        await box.put(dataEntry.key, dataEntry.value);
      }
      await box.close();
    }
  }
}

/// Names for encrypted Hive boxes.
/// Use these constants to ensure consistency across the app.
class EncryptedBoxNames {
  /// Box for storing sensitive user data
  static const String sensitiveUserData = 'encrypted_user_data';

  /// Box for storing cached credentials
  static const String credentials = 'encrypted_credentials';

  /// Box for storing sync tokens and metadata
  static const String syncMetadata = 'encrypted_sync_metadata';

  /// Prevent instantiation
  EncryptedBoxNames._();
}
