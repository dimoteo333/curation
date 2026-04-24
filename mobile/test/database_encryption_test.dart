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

  test('첫 실행 시 마스터 키를 생성하고 이후 같은 secure storage에서 재사용한다', () async {
    final secureStore = InMemorySecureKeyStore();
    final first = DatabaseEncryption(
      secureKeyStore: secureStore,
      appNamespace: 'curator.test',
    );
    final second = DatabaseEncryption(
      secureKeyStore: secureStore,
      appNamespace: 'curator.test',
    );

    final firstKey = await first.masterKeyForTesting();
    final secondKey = await second.masterKeyForTesting();

    expect(firstKey, isNotEmpty);
    expect(secondKey, firstKey);
  });

  test('같은 secure storage면 앱 재시작 후에도 복호화가 유지된다', () async {
    final secureStore = InMemorySecureKeyStore();
    final first = DatabaseEncryption(
      secureKeyStore: secureStore,
      appNamespace: 'curator.test',
    );
    final second = DatabaseEncryption(
      secureKeyStore: secureStore,
      appNamespace: 'curator.test',
    );

    final encrypted = await first.encryptValue('같은 설치 키 테스트');
    final decrypted = await second.decryptValue(encrypted);

    expect(decrypted, '같은 설치 키 테스트');
  });

  test('마스터 키를 잃어버리면 명시적인 복구 예외를 던진다', () async {
    final originalStore = InMemorySecureKeyStore();
    final first = DatabaseEncryption(
      secureKeyStore: originalStore,
      appNamespace: 'curator.test',
    );
    final encrypted = await first.encryptValue('복구 필요 테스트');
    final missingKeyInstance = DatabaseEncryption(
      secureKeyStore: InMemorySecureKeyStore(),
      appNamespace: 'curator.test',
    );

    expect(
      () => missingKeyInstance.decryptValue(encrypted),
      throwsA(
        isA<DatabaseEncryptionResetRequiredException>()
            .having(
              (error) => error.reason,
              'reason',
              DatabaseEncryptionFailureReason.missingMasterKey,
            )
            .having(
              (error) => error.message,
              'message',
              contains('Secure Storage'),
            ),
      ),
    );
  });
}
