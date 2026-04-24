import 'dart:convert';
import 'dart:io';

import 'package:curator_mobile/src/app.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool _ciRemoteHarnessAssertions = bool.fromEnvironment(
  'CI_REMOTE_HARNESS_ASSERTIONS',
  defaultValue: false,
);
const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('원격 하네스 응답을 렌더링한다', (WidgetTester tester) async {
    const question = '요즘 계속 무기력하고 지쳐요';
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setBool('app.onboarding_completed', true);
    await preferences.setString('app.runtime_mode', 'remote');

    final liveResponse = await _fetchLiveResponse(question);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          localDataInitializationProvider.overrideWith((ref) async {}),
        ],
        child: const CuratorApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('navDock-ask')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('questionTextField')), question);
    await tester.tap(find.byKey(const Key('submitQuestionButton')));
    await tester.pump();

    await _pumpUntilFound(
      tester,
      find.byKey(const Key('supportingRecordsSection')),
    );

    expect(find.byKey(const Key('supportingRecordsSection')), findsOneWidget);

    if (liveResponse != null) {
      expect(liveResponse.supportingRecordIds, isNotEmpty);
      expect(
        find.byKey(ValueKey<String>('supportingRecord-${liveResponse.supportingRecordIds.first}')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('supportingRecordsCount')),
        findsOneWidget,
      );
      expect(
        find.text(liveResponse.supportingRecordCount.toString()),
        findsOneWidget,
      );
      expect(find.text(liveResponse.firstSupportingTitle), findsOneWidget);
    }
  });
}

Future<_RemoteHarnessSnapshot?> _fetchLiveResponse(String question) async {
  if (!_ciRemoteHarnessAssertions) {
    return null;
  }

  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('$_apiBaseUrl/api/v1/curation/query'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(<String, Object>{'question': question, 'top_k': 3}));
    final response = await request.close();
    expect(response.statusCode, HttpStatus.ok);

    final responseBody = await response.transform(utf8.decoder).join();
    final payload = jsonDecode(responseBody) as Map<String, dynamic>;
    final supportingRecords =
        payload['supporting_records'] as List<dynamic>? ?? <dynamic>[];
    expect(supportingRecords, isNotEmpty);

    final firstRecord = supportingRecords.first as Map<String, dynamic>;
    return _RemoteHarnessSnapshot(
      firstSupportingTitle: firstRecord['title'] as String,
      supportingRecordCount: supportingRecords.length,
      supportingRecordIds: supportingRecords
          .map((dynamic item) => (item as Map<String, dynamic>)['id'] as String)
          .toList(growable: false),
    );
  } finally {
    client.close(force: true);
  }
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  throw TestFailure('Timed out waiting for remote harness response.');
}

class _RemoteHarnessSnapshot {
  const _RemoteHarnessSnapshot({
    required this.firstSupportingTitle,
    required this.supportingRecordCount,
    required this.supportingRecordIds,
  });

  final String firstSupportingTitle;
  final int supportingRecordCount;
  final List<String> supportingRecordIds;
}
