import 'package:curator_mobile/src/core/config/app_build_info.dart';
import 'package:curator_mobile/src/data/import/calendar_import_service.dart';
import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:curator_mobile/src/data/local/life_record_store.dart';
import 'package:curator_mobile/src/presentation/screens/settings_screen.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:curator_mobile/src/theme/curator_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'app.onboarding_completed': true,
    });
  });

  testWidgets('설정 화면은 런타임, 데이터 상태, import 액션을 노출한다', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          appBuildInfoProvider.overrideWithValue(
            const AppBuildInfo(
              appName: '큐레이터',
              packageName: 'curator_mobile',
              version: '1.0.0',
              buildNumber: '1',
            ),
          ),
          localDataStatsProvider.overrideWith(
            (ref) => const LocalDataStats(
              recordCount: 5,
              databaseSizeBytes: 2048,
              sourceCounts: <String, int>{'file': 2, 'calendar': 1, 'diary': 2},
            ),
          ),
          onDeviceLlmBridgeProvider.overrideWithValue(
            const _FakeOnDeviceLlmBridge(),
          ),
          deviceCalendarGatewayProvider.overrideWithValue(
            const _FakeDeviceCalendarGateway(),
          ),
        ],
        child: MaterialApp(
          theme: buildCuratorTheme(Brightness.light),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('사용 방식'), findsOneWidget);
    expect(find.text('캘린더'), findsOneWidget);
    expect(find.text('데모 데이터 로드'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(preferences.getString('app.runtime_mode'), 'remote');
  });
}

class _FakeDeviceCalendarGateway implements DeviceCalendarGateway {
  const _FakeDeviceCalendarGateway();

  @override
  Future<List<CalendarImportEvent>> listEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    return const <CalendarImportEvent>[];
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<CalendarImportPermissionStatus> permissionStatus() async {
    return CalendarImportPermissionStatus.granted;
  }

  @override
  Future<CalendarImportPermissionStatus> requestPermission() async {
    return CalendarImportPermissionStatus.granted;
  }
}

class _FakeOnDeviceLlmBridge implements OnDeviceLlmBridge {
  const _FakeOnDeviceLlmBridge();

  @override
  Future<List<double>> embed(String text) async => <double>[0.1, 0.2, 0.3];

  @override
  Future<String> generate({
    required String prompt,
    int maxTokens = 320,
    double temperature = 0.3,
    int topK = 32,
    int randomSeed = 17,
  }) async {
    return '테스트 응답';
  }

  @override
  Future<OnDeviceRuntimeStatus> prepare({
    String? llmModelPath,
    String? embedderModelPath,
  }) async {
    return const OnDeviceRuntimeStatus(
      llmReady: true,
      embedderReady: false,
      runtime: 'partial-native',
      message: 'LLM은 준비됐고 임베딩은 폴백입니다.',
      platform: 'flutter-test',
      llmModelConfigured: true,
      embedderModelConfigured: false,
      llmModelAvailable: true,
      embedderModelAvailable: false,
      fallbackActive: true,
    );
  }

  @override
  Future<OnDeviceRuntimeStatus> status() async => prepare();
}
