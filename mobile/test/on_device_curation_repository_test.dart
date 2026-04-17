import 'dart:io';

import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/data/ondevice/semantic_embedding_service.dart';
import 'package:curator_mobile/src/data/repositories/on_device_curation_repository.dart';
import 'package:curator_mobile/src/domain/services/llm_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
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
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'curator.db'),
    );
    final embeddingService = const SemanticEmbeddingService();
    final recordStore = LifeRecordStore(
      vectorDb: vectorDb,
      embeddingService: embeddingService,
      seedRecords: seededLifeRecords,
      sharedPreferences: preferences,
    );
    final repository = OnDeviceCurationRepository(
      vectorDb: vectorDb,
      embeddingService: embeddingService,
      llmEngine: LlmEngine(
        bridge: const MethodChannelOnDeviceLlmBridge(),
        nowProvider: () => DateTime(2026, 4, 17),
      ),
      recordStore: recordStore,
    );

    final response = await repository.curateQuestion('나 요즘 왜 이렇게 무기력하지?');

    expect(response.supportingRecords, isNotEmpty);
    expect(response.summary, contains('이번 질문은'));
    expect(response.answer, anyOf(contains('2년 전'), contains('1년 전')));
    expect(
      response.answer,
      anyOf(contains('야근이 길어지던 주간 회고'), contains('쉬어도 피곤한 주말')),
    );
    expect(
      response.supportingRecords.first.excerpt,
      anyOf(contains('무기력했다'), contains('지쳤던 상태')),
    );
    expect(response.runtimeInfo?.label, '템플릿 폴백 사용 중');
  });
}
