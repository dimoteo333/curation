import 'package:curator_mobile/src/app.dart';
import 'package:curator_mobile/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_curation_repository.dart';

void main() {
  testWidgets('큐레이션 응답이 화면에 렌더링된다', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 2200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curationRepositoryProvider.overrideWithValue(
            FakeCurationRepository(),
          ),
        ],
        child: const CuratorApp(),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('submitQuestionButton')));
    await tester.tap(find.byKey(const Key('submitQuestionButton')));
    await tester.pumpAndSettle();

    expect(find.text('최근 기록에서 반복된 흐름'), findsOneWidget);
    expect(find.text('테스트 환경에서도 질문 흐름이 화면에 표시됩니다.'), findsOneWidget);
    expect(find.byKey(const Key('responseSection')), findsOneWidget);
  });
}
