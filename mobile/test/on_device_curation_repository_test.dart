import 'dart:io';

import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/data/local/seed_records.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/data/ondevice/semantic_embedding_service.dart';
import 'package:curator_mobile/src/data/repositories/on_device_curation_repository.dart';
import 'package:curator_mobile/src/domain/entities/curation_query_scope.dart';
import 'package:curator_mobile/src/domain/entities/life_record.dart';
import 'package:curator_mobile/src/domain/services/llm_engine.dart';
import 'package:curator_mobile/src/domain/services/text_embedding_service.dart';
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
    final encryption = createTestDatabaseEncryption();
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'curator.db'),
      databaseEncryption: encryption,
    );
    final embeddingService = const SemanticEmbeddingService();
    final recordStore = LifeRecordStore(
      vectorDb: vectorDb,
      databaseEncryption: encryption,
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

    await recordStore.loadDemoData();
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

  test('scope는 최근 한 달 기록만 참고 기록으로 남긴다', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final encryption = createTestDatabaseEncryption();
    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async =>
          path.join(tempDirectory.path, 'curator-scope.db'),
      databaseEncryption: encryption,
      nowProvider: () => DateTime(2026, 4, 20),
    );
    const embeddingService = _DeterministicEmbeddingService();
    final records = <LifeRecord>[
      _buildRecord(
        id: 'old-sleep-record',
        title: '겨울 수면 메모',
        content: '수면 리듬이 무너져 하루 종일 피곤했다.',
        createdAt: DateTime(2026, 2, 10),
      ),
      _buildRecord(
        id: 'recent-sleep-record',
        title: '최근 수면 메모',
        content: '수면 리듬이 무너졌지만 산책 후 조금 회복됐다.',
        createdAt: DateTime(2026, 4, 10),
      ),
      _buildRecord(
        id: 'recent-recovery-record',
        title: '회복 루틴 메모',
        content: '잠이 부족한 주간에도 회복 루틴이 도움이 됐다.',
        createdAt: DateTime(2026, 4, 15),
      ),
    ];
    final recordStore = LifeRecordStore(
      vectorDb: vectorDb,
      databaseEncryption: encryption,
      embeddingService: embeddingService,
      seedRecords: records,
      sharedPreferences: preferences,
    );
    final repository = OnDeviceCurationRepository(
      vectorDb: vectorDb,
      embeddingService: embeddingService,
      llmEngine: LlmEngine(
        bridge: const MethodChannelOnDeviceLlmBridge(),
        nowProvider: () => DateTime(2026, 4, 20),
      ),
      recordStore: recordStore,
      nowProvider: () => DateTime(2026, 4, 20),
    );

    await recordStore.loadDemoData();

    final unscopedResponse = await repository.curateQuestion(
      '수면 리듬이 무너져서 회복이 필요해',
    );
    final scopedResponse = await repository.curateQuestion(
      '수면 리듬이 무너져서 회복이 필요해',
      scope: const CurationQueryScope(timeScope: CurationTimeScope.pastMonth),
    );

    expect(
      unscopedResponse.supportingRecords.map((record) => record.id),
      contains('old-sleep-record'),
    );
    expect(
      scopedResponse.supportingRecords.map((record) => record.id),
      isNot(contains('old-sleep-record')),
    );
    expect(scopedResponse.supportingRecords, isNotEmpty);
    expect(
      scopedResponse.supportingRecords.every(
        (record) => !record.createdAt.isBefore(DateTime(2026, 3, 21)),
      ),
      isTrue,
    );
  });
}

LifeRecord _buildRecord({
  required String id,
  required String title,
  required String content,
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
    tags: const <String>['수면', '회복'],
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
