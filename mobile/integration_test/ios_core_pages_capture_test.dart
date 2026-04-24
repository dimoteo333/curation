import 'dart:async';

import 'package:curator_mobile/src/app.dart';
import 'package:curator_mobile/src/core/config/app_build_info.dart';
import 'package:curator_mobile/src/data/import/calendar_import_service.dart';
import 'package:curator_mobile/src/data/import/import_history_service.dart';
import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/domain/entities/curation_query_scope.dart';
import 'package:curator_mobile/src/domain/entities/curated_response.dart';
import 'package:curator_mobile/src/domain/entities/life_record.dart';
import 'package:curator_mobile/src/domain/repositories/curation_repository.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/fake_pending_import.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture ios core pages for website', (
    WidgetTester tester,
  ) async {
    await _captureLoading(binding, tester);
    await _captureOnboarding(binding, tester);
    await _captureHome(binding, tester);
    await _captureAsk(binding, tester);
    await _captureAnswerAndMemory(binding, tester);
    await _captureTimeline(binding, tester);
    await _captureSettings(binding, tester);
  });
}

Future<void> _captureLoading(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
) async {
  final preferences = await _preferences(const <String, Object>{
    'app.onboarding_completed': true,
    'app.calendar_sync_enabled': true,
  });
  final initialization = Completer<void>();

  await _mountApp(
    tester,
    preferences: preferences,
    initializationFuture: initialization.future,
  );

  await tester.pump(const Duration(milliseconds: 200));
  expect(find.text('로컬 데이터를 준비하는 중입니다'), findsOneWidget);
  await binding.takeScreenshot('loading');
  initialization.complete();
  await _resetSurface(tester);
}

Future<void> _captureOnboarding(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
) async {
  final preferences = await _preferences(const <String, Object>{});

  await _mountApp(tester, preferences: preferences);

  await tester.pumpAndSettle();
  expect(find.text('큐레이터 시작하기'), findsOneWidget);
  await binding.takeScreenshot('onboarding');
  await _resetSurface(tester);
}

Future<void> _captureHome(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
) async {
  final preferences = await _preferences(const <String, Object>{
    'app.onboarding_completed': true,
    'app.calendar_sync_enabled': true,
  });

  await _mountApp(tester, preferences: preferences);

  await tester.pumpAndSettle();
  expect(find.byKey(const Key('homeBrandLogo')), findsOneWidget);
  await binding.takeScreenshot('home');
  await _resetSurface(tester);
}

Future<void> _captureAsk(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
) async {
  final preferences = await _preferences(const <String, Object>{
    'app.onboarding_completed': true,
    'app.calendar_sync_enabled': true,
  });

  await _mountApp(tester, preferences: preferences);

  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('todayAskCard')));
  await tester.pumpAndSettle();
  await _dismissActiveInput(tester);
  expect(find.byKey(const Key('questionTextField')), findsOneWidget);
  await binding.takeScreenshot('today-question');
  await _resetSurface(tester);
}

Future<void> _captureAnswerAndMemory(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
) async {
  final preferences = await _preferences(const <String, Object>{
    'app.onboarding_completed': true,
    'app.calendar_sync_enabled': true,
  });

  await _mountApp(tester, preferences: preferences);

  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('todayAskCard')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('questionTextField')),
    '요즘 왜 이렇게 무기력한지 알고 싶어요.',
  );
  await tester.tap(find.byKey(const Key('submitQuestionButton')));
  await tester.pump();
  await _pumpUntilFound(tester, find.text('답변이 도움이 되었나요?'));
  await tester.pumpAndSettle();
  expect(find.text('참고한 기록'), findsOneWidget);
  await binding.takeScreenshot('answer');

  await tester.tap(find.text(_primarySupportingRecord.title).first);
  await tester.pumpAndSettle();
  expect(find.text('원문 열기'), findsOneWidget);
  await binding.takeScreenshot('memory-sheet');
  await _resetSurface(tester);
}

Future<void> _captureTimeline(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
) async {
  final preferences = await _preferences(const <String, Object>{
    'app.onboarding_completed': true,
    'app.calendar_sync_enabled': true,
  });

  await _mountApp(tester, preferences: preferences);

  await tester.pumpAndSettle();
  await tester.tap(find.text('타임라인'));
  await tester.pumpAndSettle();
  expect(find.text('타임라인'), findsWidgets);
  await binding.takeScreenshot('timeline');
  await _resetSurface(tester);
}

Future<void> _captureSettings(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
) async {
  final preferences = await _preferences(const <String, Object>{
    'app.onboarding_completed': true,
    'app.calendar_sync_enabled': true,
  });

  await _mountApp(tester, preferences: preferences);

  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('openSettingsButton')));
  await tester.pumpAndSettle();
  expect(find.text('사용 방식'), findsOneWidget);
  await binding.takeScreenshot('settings');
  await _resetSurface(tester);
}

Future<void> _mountApp(
  WidgetTester tester, {
  required SharedPreferences preferences,
  Future<void>? initializationFuture,
}) async {
  final pendingImportService = FakePendingSharedImportService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        appBuildInfoProvider.overrideWithValue(
          const AppBuildInfo(
            appName: '큐레이터',
            packageName: 'com.curator.mobile',
            version: '0.2.0',
            buildNumber: '42',
          ),
        ),
        localDataInitializationProvider.overrideWith(
          (ref) => initializationFuture ?? Future<void>.value(),
        ),
        pendingSharedImportBridgeProvider.overrideWithValue(
          pendingImportService.bridge,
        ),
        pendingSharedImportServiceProvider.overrideWithValue(
          pendingImportService,
        ),
        localDataStatsProvider.overrideWith(
          (ref) => LocalDataStats(
            recordCount: _sampleRecords.length,
            databaseSizeBytes: 1024 * 1024 * 12,
            sourceCounts: const <String, int>{
              'diary': 2,
              'calendar': 1,
              'memo': 1,
            },
          ),
        ),
        localLifeRecordsProvider.overrideWith((ref) async => _sampleRecords),
        curationRepositoryProvider.overrideWithValue(
          _FakeCurationRepository(_sampleResponse),
        ),
        onDeviceRuntimeStatusProvider.overrideWith(
          (ref) => Future<OnDeviceRuntimeStatus>.value(
            const OnDeviceRuntimeStatus(
              llmReady: false,
              embedderReady: false,
              runtime: 'template-fallback',
              message: '시뮬레이터 캡쳐에서는 검증용 폴백 상태를 사용합니다.',
              platform: 'ios',
              llmModelConfigured: false,
              embedderModelConfigured: false,
              llmModelAvailable: false,
              embedderModelAvailable: false,
              fallbackActive: true,
            ),
          ),
        ),
        calendarSyncStatusProvider.overrideWith(
          (ref) => Future<CalendarSyncStatus>.value(
            CalendarSyncStatus(
              syncEnabled: true,
              permissionStatus: CalendarImportPermissionStatus.granted,
              importedEventCount: 12,
              lastSyncedAt: DateTime(2026, 4, 20, 9, 30),
            ),
          ),
        ),
        importHistorySnapshotProvider.overrideWith(
          (ref) => Future<ImportHistorySnapshot>.value(
            ImportHistorySnapshot(
              recentEntries: [
                ImportHistoryEntry(
                  importSource: 'calendar',
                  label: '캘린더 동기화',
                  detail: '가져온 일정 4건 / 조회한 일정 6건',
                  importedAt: DateTime(2026, 4, 20, 9, 30),
                  count: 4,
                ),
                ImportHistoryEntry(
                  importSource: 'file',
                  label: 'retrospective-april.md',
                  detail: '파일 가져오기',
                  importedAt: DateTime(2026, 4, 19, 22, 10),
                ),
              ],
              uniqueCountsBySource: const <String, int>{
                'file': 3,
                'calendar': 12,
                'memo': 1,
              },
              lastCalendarSyncAt: DateTime(2026, 4, 20, 9, 30),
            ),
          ),
        ),
      ],
      child: const CuratorApp(),
    ),
  );
}

Future<void> _resetSurface(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

Future<void> _dismissActiveInput(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<SharedPreferences> _preferences(
  Map<String, Object> initialValues,
) async {
  SharedPreferences.setMockInitialValues(initialValues);
  return SharedPreferences.getInstance();
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  throw TestFailure('Timed out waiting for $finder.');
}

final SupportingRecord _primarySupportingRecord = SupportingRecord(
  id: 'record-diary-1',
  source: '일기',
  importSource: 'diary',
  title: '퇴근 후 한강 산책',
  createdAt: DateTime(2026, 4, 8, 21, 10),
  excerpt: '업무가 길어졌지만 강변을 걷고 나니 몸의 긴장이 조금 풀렸다.',
  relevanceReason: '지친 날에 회복감을 준 루틴이 반복됐습니다.',
  content:
      '오늘은 예상보다 늦게 퇴근했다. 머리가 무거웠지만 한강을 20분 걷고 나니 숨이 길어지고 마음이 가라앉았다. 집에 돌아와 따뜻한 차를 마시며 하루를 정리했다.',
  tags: <String>['회복', '산책', '야근'],
  metadata: <String, dynamic>{'location': '여의도', 'mood': 'calm'},
);

final List<LifeRecord> _sampleRecords = <LifeRecord>[
  LifeRecord(
    id: 'record-diary-1',
    sourceId: 'diary-20260408',
    source: '일기',
    importSource: 'diary',
    title: '퇴근 후 한강 산책',
    content:
        '오늘은 예상보다 늦게 퇴근했다. 머리가 무거웠지만 한강을 20분 걷고 나니 숨이 길어지고 마음이 가라앉았다. 집에 돌아와 따뜻한 차를 마시며 하루를 정리했다.',
    createdAt: DateTime(2026, 4, 8, 21, 10),
    tags: <String>['회복', '산책', '야근'],
    metadata: <String, dynamic>{'location': '여의도', 'mood': 'calm'},
  ),
  LifeRecord(
    id: 'record-diary-2',
    sourceId: 'diary-20260405',
    source: '일기',
    importSource: 'diary',
    title: '비 오는 날의 과로',
    content: '회의가 길어지면서 집중력이 뚝 떨어졌다. 저녁에 집에서 조명을 낮추고 음악을 틀자 겨우 긴장이 풀렸다.',
    createdAt: DateTime(2026, 4, 5, 23, 10),
    tags: <String>['과로', '휴식'],
    metadata: <String, dynamic>{'mood': 'tired'},
  ),
  LifeRecord(
    id: 'record-calendar-1',
    sourceId: 'calendar-standup',
    source: '캘린더',
    importSource: 'calendar',
    title: '분기 회고 미팅',
    content: '오전 10시 팀 회고. 지난달 과로 패턴과 휴식 시간을 함께 점검했다.',
    createdAt: DateTime(2026, 4, 3, 10),
    tags: <String>['회고', '팀'],
  ),
  LifeRecord(
    id: 'record-memo-1',
    sourceId: 'memo-energizers',
    source: '메모',
    importSource: 'memo',
    title: '컨디션 회복 메모',
    content: '산책, 따뜻한 차, 조명 낮추기가 지난달 회복 루틴으로 가장 자주 등장했다.',
    createdAt: DateTime(2026, 3, 28, 8, 40),
    tags: <String>['루틴', '회복'],
  ),
];

final CuratedResponse _sampleResponse = CuratedResponse(
  insightTitle: '지친 날엔 감각을 낮추는 루틴이 먼저 작동했습니다',
  summary: '야근 뒤에는 산책과 조도 조절 같은 느린 전환이 회복을 만들었습니다.',
  answer:
      '최근 기록을 보면 무기력감은 과로 직후에 가장 크게 나타났고, 그 직후에 산책이나 조명 낮추기처럼 몸의 자극을 줄이는 루틴을 두었을 때 회복 속도가 빨라졌습니다. 특히 퇴근 후 한강 산책 기록이 그 전환점을 가장 또렷하게 보여줍니다.',
  supportingRecords: <SupportingRecord>[_primarySupportingRecord],
  suggestedFollowUp: '최근 2주 동안 비슷하게 지쳤던 날을 하나만 더 떠올려 볼까요?',
  runtimeInfo: const CurationRuntimeInfo(
    path: CurationRuntimePath.onDeviceFallback,
    label: '온디바이스 폴백',
    message: '시뮬레이터 검증용 응답입니다.',
  ),
);

class _FakeCurationRepository implements CurationRepository {
  const _FakeCurationRepository(this.response);

  final CuratedResponse response;

  @override
  Future<CuratedResponse> curateQuestion(
    String question, {
    CurationQueryScope scope = CurationQueryScope.all,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return response;
  }
}
