import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:you_tracker/src/security/hive_crypto_helper.dart';
import 'package:you_tracker/src/security/secure_storage.dart';

/// Mock SecureStorage for testing HiveCryptoHelper.
class MockSecureStorage extends SecureStorage {
  final Map<String, String> _storage = {};

  MockSecureStorage() : super(namespace: 'test');

  @override
  Future<void> write({required String key, required String value}) async {
    _storage['${namespace}_$key'] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage['${namespace}_$key'];
  }

  @override
  Future<void> delete({required String key}) async {
    _storage.remove('${namespace}_$key');
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey('${namespace}_$key');
  }

  @override
  Future<void> deleteAll() async {
    final keysToRemove = _storage.keys
        .where((key) => key.startsWith('${namespace}_'))
        .toList();
    for (final key in keysToRemove) {
      _storage.remove(key);
    }
  }

  @override
  Future<List<String>> getAllKeys() async {
    final prefix = '${namespace}_';
    return _storage.keys
        .where((key) => key.startsWith(prefix))
        .map((key) => key.substring(prefix.length))
        .toList();
  }

  void clear() {
    _storage.clear();
  }
}

void main() {
  group('HiveCryptoHelper', () {
    late HiveCryptoHelper helper;
    late MockSecureStorage mockStorage;

    setUp(() async {
      mockStorage = MockSecureStorage();
      helper = HiveCryptoHelper(secureStorage: mockStorage);
    });

    tearDown(() async {
      mockStorage.clear();
    });

    test('should not be initialized before calling initialize()', () {
      expect(helper.isInitialized, false);
      expect(helper.cipher, isNull);
    });

    test('should be initialized after calling initialize()', () async {
      await helper.initialize();

      expect(helper.isInitialized, true);
      expect(helper.cipher, isNotNull);
    });

    test('should generate and store encryption key on first initialize', () async {
      await helper.initialize();

      // Check that a key was stored
      final storedKey = await mockStorage.read(
        key: SecureStorageKeys.hiveEncryptionKey,
      );
      expect(storedKey, isNotNull);
      expect(storedKey!.isNotEmpty, true);

      // Verify it's valid base64
      final decoded = base64Decode(storedKey);
      expect(decoded.length, 32); // 256-bit key
    });

    test('should reuse existing key on subsequent initializations', () async {
      await helper.initialize();

      final firstKey = await mockStorage.read(
        key: SecureStorageKeys.hiveEncryptionKey,
      );

      // Create new helper with same storage
      final helper2 = HiveCryptoHelper(secureStorage: mockStorage);
      await helper2.initialize();

      final secondKey = await mockStorage.read(
        key: SecureStorageKeys.hiveEncryptionKey,
      );

      expect(firstKey, equals(secondKey));
    });

    test('should throw StateError when opening box before initialization', () {
      expect(
        () async => await helper.openEncryptedBox<String>('test_box'),
        throwsStateError,
      );
    });

    test('should not reinitialize if already initialized', () async {
      await helper.initialize();

      final firstCipher = helper.cipher;

      await helper.initialize(); // Second call should be no-op

      expect(helper.cipher, same(firstCipher));
    });

    test('generated key should be cryptographically random', () async {
      // Generate multiple keys and ensure they're different
      final keys = <String>[];
      
      for (int i = 0; i < 5; i++) {
        final storage = MockSecureStorage();
        final h = HiveCryptoHelper(secureStorage: storage);
        await h.initialize();
        
        final key = await storage.read(key: SecureStorageKeys.hiveEncryptionKey);
        keys.add(key!);
      }

      // All keys should be unique
      expect(keys.toSet().length, 5);
    });
  });

  group('EncryptedBoxNames', () {
    test('should have correct box name constants', () {
      expect(EncryptedBoxNames.sensitiveUserData, 'encrypted_user_data');
      expect(EncryptedBoxNames.credentials, 'encrypted_credentials');
      expect(EncryptedBoxNames.syncMetadata, 'encrypted_sync_metadata');
    });
  });

  group('HiveAesCipher compatibility', () {
    test('should create valid cipher from 32-byte key', () async {
      // Generate a 32-byte key
      final key = Uint8List.fromList(List<int>.generate(32, (i) => i));
      
      // This should not throw
      final cipher = HiveAesCipher(key);
      expect(cipher, isNotNull);
    });

    test('key should be exactly 32 bytes (256 bits)', () async {
      final mockStorage = MockSecureStorage();
      final helper = HiveCryptoHelper(secureStorage: mockStorage);
      await helper.initialize();

      final storedKey = await mockStorage.read(
        key: SecureStorageKeys.hiveEncryptionKey,
      );
      final decoded = base64Decode(storedKey!);

      expect(decoded.length, 32);
    });
  });
}
