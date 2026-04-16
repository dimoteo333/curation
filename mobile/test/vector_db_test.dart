import 'dart:io';

import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/keyword_hash_embedding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  test('SQLite 기반 벡터 검색이 한국어 질의와 가장 가까운 기록을 반환한다', () async {
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'vector.db'),
    );
    final embeddingService = const KeywordHashEmbeddingService();

    await vectorDb.replaceAllRecords(seededLifeRecords, embeddingService);
    final queryVector = await embeddingService.embed('요즘 무기력하고 번아웃 같아');
    final matches = await vectorDb.search(queryVector, topK: 2);

    expect(matches, hasLength(2));
    expect(
      matches.map((VectorSearchMatch match) => match.record.id),
      contains('diary-burnout-feb-2024'),
    );
    expect(matches.first.score, greaterThan(0));
  });
}
