import 'dart:io';

import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/semantic_embedding_service.dart';
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
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'app.onboarding_completed': true,
      'app.runtime_mode': 'remote',
      'app.llm_model_path': '/models/llm.litertlm',
      'app.excluded_calendar_ids': <String>['work'],
      'app.recent_conversations': r'[{"question":"q"}]',

      'app.excluded_record_ids': <String>['record-1'],
      'import_history.entries': '[]',
    });
    tempDirectory = await Directory.systemTemp.createTemp('curator-store-');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('deleteAllData는 로컬 DB를 지우고 설정 관련 SharedPreferences는 보존한다', () async {
    final databasePath = path.join(tempDirectory.path, 'store.db');
    final preferences = await SharedPreferences.getInstance();
    final encryption = createTestDatabaseEncryption();
    final store = LifeRecordStore(
      vectorDb: VectorDb(
        databaseFactory: databaseFactoryFfi,
        databasePathResolver: () async => databasePath,
        databaseEncryption: encryption,
      ),
      databaseEncryption: encryption,
      embeddingService: const SemanticEmbeddingService(),
      seedRecords: seededLifeRecords.take(2).toList(),
      sharedPreferences: preferences,
    );

    await store.loadDemoData();
    expect(await File(databasePath).exists(), isTrue);
    expect(preferences.getBool('app.onboarding_completed'), isTrue);

    await store.deleteAllData();

    expect(await File(databasePath).exists(), isFalse);
    expect(preferences.getBool('app.onboarding_completed'), isTrue);
    expect(preferences.getString('app.runtime_mode'), 'remote');
    expect(preferences.getString('app.llm_model_path'), '/models/llm.litertlm');
    expect(preferences.getStringList('app.excluded_calendar_ids'), <String>[
      'work',
    ]);
    expect(preferences.getString('app.recent_conversations'), isNull);
    expect(preferences.getStringList('app.excluded_record_ids'), isNull);
    expect(preferences.getString('import_history.entries'), isNull);
    expect(await encryption.hasMasterKey(), isFalse);
  });

  test('initialize는 빈 DB를 자동으로 데모 데이터로 채우지 않는다', () async {
    final databasePath = path.join(tempDirectory.path, 'empty-store.db');
    final preferences = await SharedPreferences.getInstance();
    final encryption = createTestDatabaseEncryption();
    final store = LifeRecordStore(
      vectorDb: VectorDb(
        databaseFactory: databaseFactoryFfi,
        databasePathResolver: () async => databasePath,
        databaseEncryption: encryption,
      ),
      databaseEncryption: encryption,
      embeddingService: const SemanticEmbeddingService(),
      seedRecords: seededLifeRecords.take(2).toList(),
      sharedPreferences: preferences,
    );

    await store.initialize();

    expect(await store.isEmpty(), isTrue);
  });

  test('loadDemoData는 명시적으로 호출될 때만 데모 데이터를 적재한다', () async {
    final databasePath = path.join(tempDirectory.path, 'demo-store.db');
    final preferences = await SharedPreferences.getInstance();
    final encryption = createTestDatabaseEncryption();
    final store = LifeRecordStore(
      vectorDb: VectorDb(
        databaseFactory: databaseFactoryFfi,
        databasePathResolver: () async => databasePath,
        databaseEncryption: encryption,
      ),
      databaseEncryption: encryption,
      embeddingService: const SemanticEmbeddingService(),
      seedRecords: seededLifeRecords.take(2).toList(),
      sharedPreferences: preferences,
    );

    await store.loadDemoData();

    expect(await store.isEmpty(), isFalse);
    expect(preferences.getBool('local_records.demo_data_loaded'), isNull);
  });

  test('deleteAllData 후 앱을 다시 시작해도 데모 데이터가 자동으로 들어오지 않는다', () async {
    final databasePath = path.join(tempDirectory.path, 'restart-empty.db');
    final preferences = await SharedPreferences.getInstance();
    final secureKeyStore = InMemorySecureKeyStore();
    final firstStore = LifeRecordStore(
      vectorDb: VectorDb(
        databaseFactory: databaseFactoryFfi,
        databasePathResolver: () async => databasePath,
        databaseEncryption: createTestDatabaseEncryption(
          secureKeyStore: secureKeyStore,
        ),
      ),
      databaseEncryption: createTestDatabaseEncryption(
        secureKeyStore: secureKeyStore,
      ),
      embeddingService: const SemanticEmbeddingService(),
      seedRecords: seededLifeRecords.take(2).toList(),
      sharedPreferences: preferences,
    );

    await firstStore.loadDemoData();
    expect(await firstStore.isEmpty(), isFalse);

    await firstStore.deleteAllData();

    final restartedStore = LifeRecordStore(
      vectorDb: VectorDb(
        databaseFactory: databaseFactoryFfi,
        databasePathResolver: () async => databasePath,
        databaseEncryption: createTestDatabaseEncryption(
          secureKeyStore: secureKeyStore,
        ),
      ),
      databaseEncryption: createTestDatabaseEncryption(
        secureKeyStore: secureKeyStore,
      ),
      embeddingService: const SemanticEmbeddingService(),
      seedRecords: seededLifeRecords.take(2).toList(),
      sharedPreferences: preferences,
    );

    await restartedStore.initialize();

    expect(await restartedStore.isEmpty(), isTrue);
  });
}
