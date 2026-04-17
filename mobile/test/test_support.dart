import 'dart:math';

import 'package:curator_mobile/src/core/security/database_encryption.dart';

class InMemorySecureKeyStore implements SecureKeyStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

DatabaseEncryption createTestDatabaseEncryption({
  String appNamespace = 'curator.test',
  String deviceContext = 'test-device',
}) {
  return DatabaseEncryption(
    secureKeyStore: InMemorySecureKeyStore(),
    deviceContextResolver: () async => deviceContext,
    appNamespace: appNamespace,
    random: Random(7),
  );
}
