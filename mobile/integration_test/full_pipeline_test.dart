import 'dart:io';

import 'package:curator_mobile/src/data/import/file_picker_gateway.dart';
import 'package:curator_mobile/src/data/import/file_record_import_service.dart';
import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/data/local/vector_db.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/data/ondevice/semantic_embedding_service.dart';
import 'package:curator_mobile/src/data/repositories/on_device_curation_repository.dart';
import 'package:curator_mobile/src/domain/services/llm_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    tempDirectory = await Directory.systemTemp.createTemp(
      'curator-full-pipeline-',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  testWidgets('파일 import 후 관련 질문에 한국어 큐레이션 응답을 돌려준다', (
    WidgetTester tester,
  ) async {
    final diaryFile = File(path.join(tempDirectory.path, 'late-night.md'));
    await diaryFile.writeAsString(
      '# 야근 후 회고\n오늘도 10시까지 야근했다. 몸이 점점 무거워지는 느낌이다.\n집에 와서도 일 생각이 떠나지 않았지만, 샤워 후 따뜻한 차를 마시니 조금 진정됐다.',
    );
    await diaryFile.setLastModified(DateTime(2026, 1, 12, 23, 10));

    final vectorDb = VectorDb(
      databaseFactory: databaseFactoryFfi,
      databasePathResolver: () async => path.join(tempDirectory.path, 'rag.db'),
    );
    final embeddingService = const SemanticEmbeddingService();
    final preferences = await SharedPreferences.getInstance();
    final recordStore = LifeRecordStore(
      vectorDb: vectorDb,
      embeddingService: embeddingService,
      seedRecords: const [],
      sharedPreferences: preferences,
    );
    final importService = FileRecordImportService(
      recordStore: recordStore,
      filePicker: _FakeImportFilePicker(
        files: <PickedImportFile>[
          PickedImportFile(path: diaryFile.path, name: 'late-night.md'),
        ],
      ),
      nowProvider: () => DateTime(2026, 4, 17, 9),
    );
    final repository = OnDeviceCurationRepository(
      vectorDb: vectorDb,
      embeddingService: embeddingService,
      llmEngine: LlmEngine(
        bridge: const _FallbackBridge(),
        nowProvider: () => DateTime(2026, 4, 17),
      ),
      recordStore: recordStore,
    );

    final importResult = await importService.pickAndImport();
    expect(importResult.importedCount, 1);
    expect(importResult.records.single.title, '야근 후 회고');
    expect(importResult.records.single.tags, containsAll(<String>['야근', '회복']));

    final response = await repository.curateQuestion('요즘 일하고 나면 왜 이렇게 몸이 무겁지?');

    expect(response.insightTitle, isNotEmpty);
    expect(response.answer, contains('야근 후 회고'));
    expect(response.answer, contains('3개월 전'));
    expect(response.supportingRecords, hasLength(1));
    expect(
      response.supportingRecords.single.excerpt,
      contains('오늘도 10시까지 야근했다'),
    );
    expect(response.suggestedFollowUp, isNotEmpty);
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

class _FallbackBridge implements OnDeviceLlmBridge {
  const _FallbackBridge();

  @override
  Future<List<double>> embed(String text) async => <double>[0.0];

  @override
  Future<String> generate({
    required String prompt,
    int maxTokens = 320,
    double temperature = 0.3,
    int topK = 32,
    int randomSeed = 17,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<OnDeviceRuntimeStatus> prepare({
    String? llmModelPath,
    String? embedderModelPath,
  }) async {
    return const OnDeviceRuntimeStatus(
      llmReady: false,
      embedderReady: false,
      runtime: 'template-fallback',
      message: '모델이 없어 폴백 경로를 사용합니다.',
      platform: 'flutter-test',
      llmModelConfigured: false,
      embedderModelConfigured: false,
      llmModelAvailable: false,
      embedderModelAvailable: false,
      fallbackActive: true,
    );
  }

  @override
  Future<OnDeviceRuntimeStatus> status() async {
    throw UnimplementedError();
  }
}
