import 'dart:io';

import 'package:curator_mobile/src/data/import/file_picker_gateway.dart';
import 'package:curator_mobile/src/data/import/file_record_import_service.dart';
import 'package:curator_mobile/src/data/local/life_record_store.dart';
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
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    tempDirectory = await Directory.systemTemp.createTemp('curator-import-');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('마크다운 헤더와 텍스트 첫 줄을 제목으로 가져와 로컬 DB에 저장한다', () async {
    final markdownFile = File(path.join(tempDirectory.path, 'night.md'));
    await markdownFile.writeAsString(
      '# 야근 후 회고\n오늘도 10시까지 야근했다. 몸이 점점 무거워지는 느낌이다.\n산책 후 조금 나아졌다.',
    );
    await markdownFile.setLastModified(DateTime(2026, 4, 15, 23, 10));

    final textFile = File(path.join(tempDirectory.path, 'memo.txt'));
    await textFile.writeAsString('회의 뒤 메모\n생각보다 피로가 오래 남았다.');
    await textFile.setLastModified(DateTime(2026, 4, 16, 8, 40));

    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'vector.db'),
      databaseEncryption: createTestDatabaseEncryption(),
    );
    final embeddingService = const SemanticEmbeddingService();
    final preferences = await SharedPreferences.getInstance();
    final recordStore = LifeRecordStore(
      vectorDb: vectorDb,
      embeddingService: embeddingService,
      seedRecords: const [],
      sharedPreferences: preferences,
    );
    final service = FileRecordImportService(
      recordStore: recordStore,
      filePicker: _FakeImportFilePicker(
        files: [
          PickedImportFile(path: markdownFile.path, name: 'night.md'),
          PickedImportFile(path: textFile.path, name: 'memo.txt'),
        ],
      ),
      nowProvider: () => DateTime(2026, 4, 17, 9),
    );

    final result = await service.pickAndImport();

    expect(result.importedCount, 2);
    expect(await vectorDb.documentCount(), 2);

    final queryVector = await embeddingService.embed('야근 후 몸이 무겁다');
    final matches = await vectorDb.search(queryVector, topK: 1);
    final record = matches.first.record;

    expect(record.title, '야근 후 회고');
    expect(record.importSource, 'file');
    expect(record.createdAt, DateTime(2026, 4, 15, 23, 10));
    expect(record.tags, containsAll(<String>['야근', '회복']));
    expect(record.metadata['file_extension'], 'md');
    expect(record.metadata['parser'], 'markdown-header');
    expect(record.metadata['tag_count'], greaterThanOrEqualTo(2));
  });

  test('비어 있거나 지원하지 않는 파일은 건너뛴다', () async {
    final emptyFile = File(path.join(tempDirectory.path, 'empty.txt'));
    await emptyFile.writeAsString('   \n');
    final unsupportedFile = File(path.join(tempDirectory.path, 'image.png'));
    await unsupportedFile.writeAsString('not-really-an-image');

    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'vector.db'),
      databaseEncryption: createTestDatabaseEncryption(),
    );
    final preferences = await SharedPreferences.getInstance();
    final recordStore = LifeRecordStore(
      vectorDb: vectorDb,
      embeddingService: const SemanticEmbeddingService(),
      seedRecords: const [],
      sharedPreferences: preferences,
    );
    final service = FileRecordImportService(
      recordStore: recordStore,
      filePicker: _FakeImportFilePicker(
        files: [
          PickedImportFile(path: emptyFile.path, name: 'empty.txt'),
          PickedImportFile(path: unsupportedFile.path, name: 'image.png'),
        ],
      ),
    );

    final result = await service.pickAndImport();

    expect(result.importedCount, 0);
    expect(
      result.skippedFiles,
      containsAll(<String>['empty.txt', 'image.png']),
    );
    expect(await vectorDb.documentCount(), 0);
  });

  test('경로 순회 파일명과 잘못된 UTF-8 파일은 건너뛴다', () async {
    final invalidNameFile = File(path.join(tempDirectory.path, 'unsafe.txt'));
    await invalidNameFile.writeAsString('메모 제목\n본문');
    final invalidUtf8File = File(path.join(tempDirectory.path, 'broken.txt'));
    await invalidUtf8File.writeAsBytes(const <int>[0xFF, 0xFE, 0x00]);

    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'vector.db'),
      databaseEncryption: createTestDatabaseEncryption(),
    );
    final preferences = await SharedPreferences.getInstance();
    final recordStore = LifeRecordStore(
      vectorDb: vectorDb,
      embeddingService: const SemanticEmbeddingService(),
      seedRecords: const [],
      sharedPreferences: preferences,
    );
    final service = FileRecordImportService(
      recordStore: recordStore,
      filePicker: _FakeImportFilePicker(
        files: [
          PickedImportFile(path: invalidNameFile.path, name: '../unsafe.txt'),
          PickedImportFile(path: invalidUtf8File.path, name: 'broken.txt'),
        ],
      ),
    );

    final result = await service.pickAndImport();

    expect(result.importedCount, 0);
    expect(
      result.skippedFiles,
      containsAll(<String>['../unsafe.txt', 'broken.txt']),
    );
  });
}

class _FakeImportFilePicker implements ImportFilePicker {
  const _FakeImportFilePicker({required this.files});

  final List<PickedImportFile> files;

  @override
  Future<List<PickedImportFile>> pickFiles() async {
    return files;
  }
}
