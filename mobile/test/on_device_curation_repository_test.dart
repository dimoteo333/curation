import 'dart:io';

import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/keyword_hash_embedding_service.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/data/repositories/on_device_curation_repository.dart';
import 'package:curator_mobile/src/domain/services/llm_engine.dart';
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
    tempDirectory = await Directory.systemTemp.createTemp('curator-ondevice-');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('온디바이스 저장소는 네이티브 브릿지가 없어도 로컬 RAG 응답을 만든다', () async {
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'curator.db'),
    );
    final embeddingService = const KeywordHashEmbeddingService();
    final repository = OnDeviceCurationRepository(
      vectorDb: vectorDb,
      embeddingService: embeddingService,
      llmEngine: const LlmEngine(bridge: MethodChannelOnDeviceLlmBridge()),
      seedRecords: seededLifeRecords,
    );

    final response = await repository.curateQuestion('나 요즘 왜 이렇게 무기력하지?');

    expect(response.supportingRecords, isNotEmpty);
    expect(response.summary, contains('로컬 검색'));
    expect(response.answer, contains('기기 안에서 처리'));
  });
}
