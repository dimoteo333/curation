import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef DeviceContextResolver = Future<String> Function();

abstract class SecureKeyStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class FlutterSecureKeyStore implements SecureKeyStore {
  FlutterSecureKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const AndroidOptions _androidOptions = AndroidOptions();
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) {
    return _storage.read(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  @override
  Future<void> write(String key, String value) {
    return _storage.write(
      key: key,
      value: value,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }
}

class DatabaseEncryption {
  DatabaseEncryption({
    required SecureKeyStore secureKeyStore,
    required DeviceContextResolver deviceContextResolver,
    required String appNamespace,
    Random? random,
  }) : _secureKeyStore = secureKeyStore,
       _deviceContextResolver = deviceContextResolver,
       _appNamespace = appNamespace,
       _random = random ?? Random.secure();

  static const String _masterKeyStorageKey = 'curator.database.master_key.v1';
  static const String _cipherPrefix = 'enc:v1';
  static const int _masterKeyLengthBytes = 32;
  static const int _ivLengthBytes = 12;

  final SecureKeyStore _secureKeyStore;
  final DeviceContextResolver _deviceContextResolver;
  final String _appNamespace;
  final Random _random;

  bool isEncryptedValue(String value) => value.startsWith('$_cipherPrefix:');

  Future<String> encryptValue(String plaintext) async {
    if (plaintext.isEmpty) {
      return plaintext;
    }

    final cipher = await _buildCipher();
    final iv = encrypt.IV(Uint8List.fromList(_randomBytes(_ivLengthBytes)));
    final encryptedValue = cipher.encrypt(
      plaintext,
      iv: iv,
      associatedData: _associatedDataBytes(),
    );
    return '$_cipherPrefix:${iv.base64}:${encryptedValue.base64}';
  }

  Future<String> decryptValue(String value) async {
    if (value.isEmpty || !isEncryptedValue(value)) {
      return value;
    }

    final parts = value.split(':');
    if (parts.length != 4) {
      throw const FormatException('Invalid encrypted database value.');
    }

    final iv = encrypt.IV.fromBase64(parts[2]);
    final cipher = await _buildCipher();
    return cipher.decrypt64(
      parts[3],
      iv: iv,
      associatedData: _associatedDataBytes(),
    );
  }

  @visibleForTesting
  Future<String> masterKeyForTesting() async {
    return _loadOrCreateMasterKey();
  }

  Future<encrypt.Encrypter> _buildCipher() async {
    final masterKey = await _loadOrCreateMasterKey();
    final deviceContext = await _deviceContextResolver();
    final derivedKey = sha256
        .convert(utf8.encode('$_appNamespace::$deviceContext::$masterKey'))
        .bytes;
    return encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key(Uint8List.fromList(derivedKey)),
        mode: encrypt.AESMode.gcm,
        padding: null,
      ),
    );
  }

  Future<String> _loadOrCreateMasterKey() async {
    final existing = await _secureKeyStore.read(_masterKeyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = base64UrlEncode(_randomBytes(_masterKeyLengthBytes));
    await _secureKeyStore.write(_masterKeyStorageKey, created);
    return created;
  }

  Uint8List _associatedDataBytes() {
    return Uint8List.fromList(utf8.encode(_appNamespace));
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(
      length,
      (_) => _random.nextInt(256),
      growable: false,
    );
  }
}
