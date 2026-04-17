import 'dart:io';

import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/semantic_embedding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('curator-vector-db-');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('무기력 질문은 야근 회고와 번아웃 기록을 상위로 반환한다', () async {
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'vector.db'),
      databaseEncryption: createTestDatabaseEncryption(),
    );
    final embeddingService = const SemanticEmbeddingService();

    await vectorDb.replaceAllRecords(seededLifeRecords, embeddingService);
    final queryVector = await embeddingService.embed('요즘 무기력하고 번아웃 같아');
    final matches = await vectorDb.search(queryVector, topK: 3);

    expect(matches, hasLength(3));
    final topIds = matches
        .take(2)
        .map((VectorSearchMatch match) => match.record.id)
        .toList(growable: false);
    expect(
      topIds,
      anyOf(
        contains('diary-burnout-feb-2024'),
        contains('diary-burnout-nov-2024'),
      ),
    );
    expect(topIds, contains('diary-project-pressure-2022'));
    expect(matches.first.score, greaterThan(0.35));
  });

  test('수면 질문은 수면 리듬 기록을 가장 먼저 반환한다', () async {
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'vector.db'),
      databaseEncryption: createTestDatabaseEncryption(),
    );
    final embeddingService = const SemanticEmbeddingService();

    await vectorDb.replaceAllRecords(seededLifeRecords, embeddingService);
    final queryVector = await embeddingService.embed('요즘 잠이 뒤집혀서 수면이 부족해');
    final matches = await vectorDb.search(queryVector, topK: 2);

    expect(matches.first.record.id, 'diary-routine-reset-2023');
    expect(matches.first.score, greaterThan(matches.last.score));
  });

  test('관련 없는 질문은 낮은 검색 점수를 받는다', () async {
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'vector.db'),
      databaseEncryption: createTestDatabaseEncryption(),
    );
    final embeddingService = const SemanticEmbeddingService();

    await vectorDb.replaceAllRecords(seededLifeRecords, embeddingService);
    final queryVector = await embeddingService.embed('해외 주식 환율과 반도체 전망이 궁금해');
    final matches = await vectorDb.search(queryVector, topK: 1);

    expect(matches, hasLength(1));
    expect(matches.first.score, lessThan(0.35));
  });

  test('같은 질문 반복 시 정규화와 검색 결과 캐시를 재사용한다', () async {
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'vector.db'),
      databaseEncryption: createTestDatabaseEncryption(),
    );
    final embeddingService = const SemanticEmbeddingService();

    await vectorDb.replaceAllRecords(seededLifeRecords, embeddingService);
    final queryVector = await embeddingService.embed('무기력하고 잠도 부족해');

    await vectorDb.search(queryVector, topK: 3);
    expect(vectorDb.debugIndexedDocumentCount, seededLifeRecords.length);
    expect(vectorDb.debugCachedQueryCount, 1);
    expect(vectorDb.debugSearchResultCacheCount, 1);

    await vectorDb.search(queryVector, topK: 3);
    expect(vectorDb.debugCachedQueryCount, 1);
    expect(vectorDb.debugSearchResultCacheCount, 1);
  });

  test('개인 데이터 필드는 평문이 아닌 암호문으로 저장된다', () async {
    final databasePath = path.join(tempDirectory.path, 'encrypted.db');
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async => databasePath,
      databaseEncryption: createTestDatabaseEncryption(),
    );

    await vectorDb.replaceAllRecords(
      seededLifeRecords.take(1).toList(),
      const SemanticEmbeddingService(),
    );

    final rawDb = await databaseFactoryFfi.openDatabase(databasePath);
    final rows = await rawDb.query('documents');
    await rawDb.close();

    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row['title'], isNot(contains('야근')));
    expect(row['content'], isNot(contains('몸')));
    expect((row['title']! as String).startsWith('enc:v1:'), isTrue);
    expect((row['content']! as String).startsWith('enc:v1:'), isTrue);
    expect((row['tags_json']! as String).startsWith('enc:v1:'), isTrue);
    expect((row['metadata_json']! as String).startsWith('enc:v1:'), isTrue);
  });

  test('deleteAllData는 SQLite 파일을 제거한다', () async {
    final databasePath = path.join(tempDirectory.path, 'delete.db');
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async => databasePath,
      databaseEncryption: createTestDatabaseEncryption(),
    );

    await vectorDb.replaceAllRecords(
      seededLifeRecords.take(2).toList(),
      const SemanticEmbeddingService(),
    );
    expect(await File(databasePath).exists(), isTrue);

    await vectorDb.deleteAllData();

    expect(await File(databasePath).exists(), isFalse);
    expect(await vectorDb.documentCount(), 0);
  });

  test('v1 스키마는 v3로 마이그레이션되며 기존 개인 필드를 암호화한다', () async {
    final databasePath = path.join(tempDirectory.path, 'migration.db');
    final legacyDb = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE documents (
              id TEXT PRIMARY KEY,
              source TEXT NOT NULL,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              tags_json TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE embeddings (
              doc_id TEXT PRIMARY KEY,
              dim INTEGER NOT NULL,
              vector_json TEXT NOT NULL,
              FOREIGN KEY(doc_id) REFERENCES documents(id) ON DELETE CASCADE
            )
          ''');
        },
      ),
    );

    await legacyDb.insert('documents', <String, Object?>{
      'id': 'legacy-record',
      'source': '메모',
      'title': '예전 메모',
      'content': '예전 버전 DB에서 온 문장입니다.',
      'created_at': DateTime(2024, 4, 1, 9).millisecondsSinceEpoch,
      'tags_json': '["회고"]',
    });
    await legacyDb.insert('embeddings', <String, Object?>{
      'doc_id': 'legacy-record',
      'dim': 3,
      'vector_json': '[0.1, 0.2, 0.3]',
    });
    await legacyDb.close();

    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async => databasePath,
      databaseEncryption: createTestDatabaseEncryption(),
    );
    await vectorDb.initialize();

    final queryVector = await const SemanticEmbeddingService().embed('예전 메모');
    final matches = await vectorDb.search(queryVector, topK: 1);

    expect(matches.first.record.importSource, 'note');
    expect(matches.first.record.metadata, isEmpty);

    final migratedDb = await databaseFactoryFfi.openDatabase(databasePath);
    final rows = await migratedDb.query(
      'documents',
      where: 'id = ?',
      whereArgs: <Object>['legacy-record'],
    );
    await migratedDb.close();
    final row = rows.single;
    expect((row['title']! as String).startsWith('enc:v1:'), isTrue);
    expect((row['content']! as String).startsWith('enc:v1:'), isTrue);
    expect((row['tags_json']! as String).startsWith('enc:v1:'), isTrue);
    expect((row['metadata_json']! as String).startsWith('enc:v1:'), isTrue);
  });
}
