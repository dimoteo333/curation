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
    final store = LifeRecordStore(
      vectorDb: VectorDb(
        databaseFactory: databaseFactoryFfi,
        databasePathResolver: () async => databasePath,
        databaseEncryption: createTestDatabaseEncryption(),
      ),
      embeddingService: const SemanticEmbeddingService(),
      seedRecords: seededLifeRecords.take(2).toList(),
      sharedPreferences: preferences,
    );

    await store.initialize();
    expect(await File(databasePath).exists(), isTrue);
    expect(preferences.getBool('app.onboarding_completed'), isTrue);

    await store.deleteAllData();

    expect(await File(databasePath).exists(), isFalse);
    expect(preferences.getKeys(), isEmpty);
  });
}
