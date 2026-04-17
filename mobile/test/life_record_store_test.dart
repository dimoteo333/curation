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
    });
    tempDirectory = await Directory.systemTemp.createTemp('curator-store-');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('deleteAllData는 로컬 DB와 SharedPreferences를 함께 지운다', () async {
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
    expect(preferences.getKeys(), isEmpty);
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
}
