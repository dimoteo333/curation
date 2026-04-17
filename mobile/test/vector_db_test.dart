import 'dart:io';

import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/semantic_embedding_service.dart';
import 'package:curator_mobile/src/domain/entities/life_record.dart';
import 'package:curator_mobile/src/domain/services/text_embedding_service.dart';
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
    const question = '무기력하고 잠도 부족해';

    await vectorDb.replaceAllRecords(seededLifeRecords, embeddingService);
    final queryVector = await embeddingService.embed(question);

    await vectorDb.searchWithPrefilter(question, queryVector, limit: 3);
    expect(vectorDb.debugIndexedDocumentCount, seededLifeRecords.length);
    expect(vectorDb.debugCachedQueryCount, 1);
    expect(vectorDb.debugSearchResultCacheCount, 1);

    await vectorDb.searchWithPrefilter(question, queryVector, limit: 3);
    expect(vectorDb.debugCachedQueryCount, 1);
    expect(vectorDb.debugSearchResultCacheCount, 1);
  });

  test('정규화 상태를 DB에 저장하고 재사용한다', () async {
    final databasePath = path.join(tempDirectory.path, 'normalized.db');
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async => databasePath,
      databaseEncryption: createTestDatabaseEncryption(),
    );

    await vectorDb.replaceAllRecords(
      seededLifeRecords.take(2).toList(),
      const SemanticEmbeddingService(),
    );

    final rawDb = await databaseFactoryFfi.openDatabase(databasePath);
    final rows = await rawDb.query('embeddings');
    await rawDb.close();

    expect(rows, hasLength(2));
    for (final row in rows) {
      expect((row['normalized'] as int?) ?? 0, 1);
    }
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

  test('v1 스키마는 v4로 마이그레이션되며 기존 개인 필드를 암호화한다', () async {
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
    final embeddingRows = await migratedDb.query(
      'embeddings',
      columns: <String>['normalized'],
      where: 'doc_id = ?',
      whereArgs: <Object>['legacy-record'],
    );
    await migratedDb.close();
    final row = rows.single;
    expect((row['title']! as String).startsWith('enc:v1:'), isTrue);
    expect((row['content']! as String).startsWith('enc:v1:'), isTrue);
    expect((row['tags_json']! as String).startsWith('enc:v1:'), isTrue);
    expect((row['metadata_json']! as String).startsWith('enc:v1:'), isTrue);
    expect((embeddingRows.single['normalized'] as int?) ?? 0, 1);
  });

  test('searchWithPrefilter는 limit와 offset 페이지네이션을 지원한다', () async {
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'pagination.db'),
      databaseEncryption: createTestDatabaseEncryption(),
    );
    const embeddingService = _DeterministicEmbeddingService();
    final records = <LifeRecord>[
      _buildRecord(
        id: 'burnout-1',
        title: '번아웃 회고',
        content: '야근이 이어져 번아웃이 심했다.',
        tags: const <String>['번아웃', '야근'],
        createdAt: DateTime(2024, 1, 3),
      ),
      _buildRecord(
        id: 'burnout-2',
        title: '회복 기록',
        content: '번아웃 뒤에 휴식으로 회복했다.',
        tags: const <String>['번아웃', '회복'],
        createdAt: DateTime(2024, 1, 2),
      ),
      _buildRecord(
        id: 'burnout-3',
        title: '업무 압박 메모',
        content: '프로젝트 마감으로 정신이 없었다.',
        tags: const <String>['마감', '업무'],
        createdAt: DateTime(2024, 1, 1),
      ),
    ];

    await vectorDb.replaceAllRecords(records, embeddingService);
    final queryVector = await embeddingService.embed('번아웃과 야근 때문에 힘들어');

    final firstPage = await vectorDb.searchWithPrefilter(
      '번아웃과 야근 때문에 힘들어',
      queryVector,
      limit: 1,
      offset: 0,
    );
    final secondPage = await vectorDb.searchWithPrefilter(
      '번아웃과 야근 때문에 힘들어',
      queryVector,
      limit: 1,
      offset: 1,
    );

    expect(firstPage, hasLength(1));
    expect(secondPage, hasLength(1));
    expect(firstPage.single.record.id, isNot(secondPage.single.record.id));
    expect(vectorDb.debugSearchResultCacheCount, 1);
  });

  test('새 레코드 import 시 질문 결과 캐시를 무효화한다', () async {
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'cache-invalidation.db'),
      databaseEncryption: createTestDatabaseEncryption(),
    );
    const embeddingService = _DeterministicEmbeddingService();
    final initialRecords = <LifeRecord>[
      _buildRecord(
        id: 'sleep-1',
        title: '수면 메모',
        content: '잠이 부족했다.',
        tags: const <String>['수면'],
        createdAt: DateTime(2024, 2, 1),
      ),
    ];

    await vectorDb.replaceAllRecords(initialRecords, embeddingService);
    final queryVector = await embeddingService.embed('수면 리듬이 무너졌다');
    final initialMatches = await vectorDb.searchWithPrefilter(
      '수면 리듬이 무너졌다',
      queryVector,
      limit: 1,
    );
    expect(initialMatches.single.record.id, 'sleep-1');
    expect(vectorDb.debugSearchResultCacheCount, 1);

    await vectorDb.upsertRecords(<LifeRecord>[
      _buildRecord(
        id: 'sleep-2',
        title: '새 수면 기록',
        content: '수면 리듬이 완전히 무너져 더 힘들었다.',
        tags: const <String>['수면', '회복'],
        createdAt: DateTime(2024, 2, 2),
      ),
    ], embeddingService);

    final refreshedMatches = await vectorDb.searchWithPrefilter(
      '수면 리듬이 무너졌다',
      queryVector,
      limit: 2,
    );
    final refreshedIds = refreshedMatches
        .map((VectorSearchMatch match) => match.record.id)
        .toList(growable: false);
    expect(refreshedIds, contains('sleep-2'));
    expect(vectorDb.debugSearchResultCacheCount, 1);
  });

  test('같은 import_source/source_id는 upsert로 한 건만 유지한다', () async {
    final databasePath = path.join(tempDirectory.path, 'dedupe.db');
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async => databasePath,
      databaseEncryption: createTestDatabaseEncryption(),
    );
    const embeddingService = _DeterministicEmbeddingService();

    await vectorDb.upsertRecords(<LifeRecord>[
      LifeRecord(
        id: 'calendar-doc-1',
        sourceId: 'event-123',
        source: '캘린더',
        importSource: 'calendar',
        title: '첫 일정 제목',
        content: '첫 일정 내용',
        createdAt: DateTime(2026, 4, 10, 9),
        tags: <String>['일정'],
      ),
    ], embeddingService);

    await vectorDb.upsertRecords(<LifeRecord>[
      LifeRecord(
        id: 'calendar-doc-2',
        sourceId: 'event-123',
        source: '캘린더',
        importSource: 'calendar',
        title: '업데이트된 일정 제목',
        content: '업데이트된 일정 내용',
        createdAt: DateTime(2026, 4, 12, 9),
        tags: <String>['일정', '업데이트'],
      ),
    ], embeddingService);

    expect(await vectorDb.documentCount(), 1);

    final rawDb = await databaseFactoryFfi.openDatabase(databasePath);
    final rows = await rawDb.query('documents');
    await rawDb.close();

    expect(rows, hasLength(1));
    expect(rows.single['id'], 'calendar-doc-2');
    expect(rows.single['source_id'], 'event-123');
  });

  test('100건 검색은 ANN prefilter로 100ms 안에 끝난다', () async {
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'performance.db'),
      databaseEncryption: createTestDatabaseEncryption(),
    );
    const embeddingService = _DeterministicEmbeddingService();
    final records = List<LifeRecord>.generate(100, (int index) {
      final isSleepRecord = index % 5 == 0;
      return _buildRecord(
        id: 'record-$index',
        title: isSleepRecord ? '수면 기록 $index' : '업무 기록 $index',
        content: isSleepRecord
            ? '수면 리듬과 회복 상태를 정리한 메모 $index'
            : '프로젝트와 업무 압박을 정리한 메모 $index',
        tags: isSleepRecord
            ? const <String>['수면', '회복']
            : const <String>['업무', '마감'],
        createdAt: DateTime(2024, 3, 1).add(Duration(days: index)),
      );
    });

    await vectorDb.replaceAllRecords(records, embeddingService);
    final query = '수면 리듬이 무너져서 회복이 필요해';
    final queryVector = await embeddingService.embed(query);

    final stopwatch = Stopwatch()..start();
    final matches = await vectorDb.searchWithPrefilter(
      query,
      queryVector,
      limit: 5,
    );
    stopwatch.stop();

    expect(matches, hasLength(5));
    expect(stopwatch.elapsedMilliseconds, lessThan(100));
  });
}

LifeRecord _buildRecord({
  required String id,
  required String title,
  required String content,
  required List<String> tags,
  required DateTime createdAt,
}) {
  return LifeRecord(
    id: id,
    sourceId: id,
    source: '메모',
    importSource: 'note',
    title: title,
    content: content,
    createdAt: createdAt,
    tags: tags,
  );
}

class _DeterministicEmbeddingService implements TextEmbeddingService {
  const _DeterministicEmbeddingService();

  static const int _dimensions = 48;

  @override
  Future<List<double>> embed(String text) async {
    final vector = List<double>.filled(_dimensions, 0);
    final normalized = text.trim().toLowerCase();
    for (var index = 0; index < normalized.length; index += 1) {
      final codeUnit = normalized.codeUnitAt(index);
      final bucket = (codeUnit + index * 17) % _dimensions;
      vector[bucket] += 1 + (codeUnit % 11) / 10;
    }
    return vector;
  }
}
