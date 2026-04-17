import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum DatabaseEncryptionFailureReason { missingMasterKey, invalidMasterKey }

class DatabaseEncryptionResetRequiredException implements Exception {
  const DatabaseEncryptionResetRequiredException({
    required this.reason,
    required this.message,
  });

  final DatabaseEncryptionFailureReason reason;
  final String message;

  @override
  String toString() => message;
}

abstract class SecureKeyStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
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

  @override
  Future<void> delete(String key) {
    return _storage.delete(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }
}

class DatabaseEncryption {
  DatabaseEncryption({
    required SecureKeyStore secureKeyStore,
    required String appNamespace,
    Random? random,
  }) : _secureKeyStore = secureKeyStore,
       _appNamespace = appNamespace,
       _random = random ?? Random.secure();

  static const String cipherPrefix = 'enc:v1';
  static const String _masterKeyStorageKey = 'curator.database.master_key.v1';
  static const int _masterKeyLengthBytes = 32;
  static const int _ivLengthBytes = 12;

  final SecureKeyStore _secureKeyStore;
  final String _appNamespace;
  final Random _random;

  bool isEncryptedValue(String value) => value.startsWith('$cipherPrefix:');

  Future<void> ensureMasterKey() async {
    await _loadOrCreateMasterKey();
  }

  Future<bool> hasMasterKey() async {
    final existing = await _secureKeyStore.read(_masterKeyStorageKey);
    return existing != null && existing.isNotEmpty;
  }

  Future<void> deleteMasterKey() {
    return _secureKeyStore.delete(_masterKeyStorageKey);
  }

  Future<void> ensureKeyAvailableForEncryptedData({
    required bool encryptedDataExists,
  }) async {
    if (!encryptedDataExists) {
      return;
    }
    if (!await hasMasterKey()) {
      throw const DatabaseEncryptionResetRequiredException(
        reason: DatabaseEncryptionFailureReason.missingMasterKey,
        message: '암호화 키를 찾지 못해 기존 로컬 데이터를 읽을 수 없습니다. 데이터를 초기화한 뒤 다시 시작해 주세요.',
      );
    }
  }

  Future<String> encryptValue(String plaintext) async {
    if (plaintext.isEmpty) {
      return plaintext;
    }

    final cipher = await _buildCipher(createIfMissing: true);
    final iv = encrypt.IV(Uint8List.fromList(_randomBytes(_ivLengthBytes)));
    final encryptedValue = cipher.encrypt(
      plaintext,
      iv: iv,
      associatedData: _associatedDataBytes(),
    );
    return '$cipherPrefix:${iv.base64}:${encryptedValue.base64}';
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
    final cipher = await _buildCipher(createIfMissing: false);
    try {
      return cipher.decrypt64(
        parts[3],
        iv: iv,
        associatedData: _associatedDataBytes(),
      );
    } catch (_) {
      throw const DatabaseEncryptionResetRequiredException(
        reason: DatabaseEncryptionFailureReason.invalidMasterKey,
        message: '저장된 암호화 키로 기존 로컬 데이터를 복호화할 수 없습니다. 데이터를 초기화한 뒤 다시 시작해 주세요.',
      );
    }
  }

  @visibleForTesting
  Future<String> masterKeyForTesting() async {
    return _loadOrCreateMasterKey();
  }

  Future<encrypt.Encrypter> _buildCipher({
    required bool createIfMissing,
  }) async {
    final masterKey = createIfMissing
        ? await _loadOrCreateMasterKey()
        : await _loadExistingMasterKey();
    return encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key(Uint8List.fromList(_decodeMasterKey(masterKey))),
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

  Future<String> _loadExistingMasterKey() async {
    final existing = await _secureKeyStore.read(_masterKeyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    throw const DatabaseEncryptionResetRequiredException(
      reason: DatabaseEncryptionFailureReason.missingMasterKey,
      message: '암호화 키를 찾지 못해 기존 로컬 데이터를 읽을 수 없습니다. 데이터를 초기화한 뒤 다시 시작해 주세요.',
    );
  }

  Uint8List _associatedDataBytes() {
    return Uint8List.fromList(utf8.encode(_appNamespace));
  }

  List<int> _decodeMasterKey(String value) {
    try {
      return base64Url.decode(value);
    } catch (_) {
      throw const DatabaseEncryptionResetRequiredException(
        reason: DatabaseEncryptionFailureReason.invalidMasterKey,
        message:
            '저장된 암호화 키가 손상되어 기존 로컬 데이터를 읽을 수 없습니다. 데이터를 초기화한 뒤 다시 시작해 주세요.',
      );
    }
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(
      length,
      (_) => _random.nextInt(256),
      growable: false,
    );
  }
}
