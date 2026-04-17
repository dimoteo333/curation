import 'package:curator_mobile/src/core/security/database_encryption.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  test('DatabaseEncryption은 값을 암호화한 뒤 복호화할 수 있다', () async {
    final encryption = createTestDatabaseEncryption();
    const plaintext = '개인 기록 본문입니다.';

    final encrypted = await encryption.encryptValue(plaintext);
    final decrypted = await encryption.decryptValue(encrypted);

    expect(encrypted, isNot(plaintext));
    expect(encrypted.startsWith('enc:v1:'), isTrue);
    expect(decrypted, plaintext);
  });

  test('같은 secure storage와 기기 문맥이면 복호화가 유지된다', () async {
    final secureStore = InMemorySecureKeyStore();
    final first = DatabaseEncryption(
      secureKeyStore: secureStore,
      deviceContextResolver: () async => 'shared-device',
      appNamespace: 'curator.test',
    );
    final second = DatabaseEncryption(
      secureKeyStore: secureStore,
      deviceContextResolver: () async => 'shared-device',
      appNamespace: 'curator.test',
    );

    final encrypted = await first.encryptValue('같은 기기 키 테스트');
    final decrypted = await second.decryptValue(encrypted);

    expect(decrypted, '같은 기기 키 테스트');
  });
}
