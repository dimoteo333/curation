import 'dart:io';

import 'package:curator_mobile/src/core/config/app_build_info.dart';
import 'package:curator_mobile/src/core/security/database_encryption.dart';
import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/semantic_embedding_service.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    tempDirectory = await Directory.systemTemp.createTemp('curator-app-init-');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'fresh install initializes local storage and stores first_run_version',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final harness = _ProviderHarness(
        databasePath: path.join(tempDirectory.path, 'fresh.db'),
        preferences: preferences,
        secureKeyStore: InMemorySecureKeyStore(),
      );

      final container = harness.createContainer();
      addTearDown(container.dispose);

      await container.read(localDataInitializationProvider.future);

      expect(preferences.getString('app.first_run_version'), '1.5.0+15');
      expect(await harness.encryption.hasMasterKey(), isTrue);
      expect(container.read(appSettingsProvider).onboardingCompleted, isFalse);
    },
  );
}

class _ProviderHarness {
  _ProviderHarness({
    required String databasePath,
    required this.preferences,
    required SecureKeyStore secureKeyStore,
  }) {
    encryption = createTestDatabaseEncryption(
      appNamespace: 'curator.test.app',
      secureKeyStore: secureKeyStore,
    );
    vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async => databasePath,
      databaseEncryption: encryption,
    );
    store = LifeRecordStore(
      vectorDb: vectorDb,
      databaseEncryption: encryption,
      embeddingService: const SemanticEmbeddingService(),
      seedRecords: seededLifeRecords.take(4).toList(),
      sharedPreferences: preferences,
    );
  }

  final SharedPreferences preferences;
  late final DatabaseEncryption encryption;
  late final VectorDb vectorDb;
  late final LifeRecordStore store;

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        appBuildInfoProvider.overrideWithValue(
          const AppBuildInfo(
            appName: '큐레이터',
            packageName: 'curator_mobile',
            version: '1.5.0',
            buildNumber: '15',
          ),
        ),
        databaseEncryptionProvider.overrideWithValue(encryption),
        vectorDbProvider.overrideWithValue(vectorDb),
        lifeRecordStoreProvider.overrideWithValue(store),
      ],
    );
  }
}
