import 'package:curator_mobile/src/data/import/import_history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('import history는 파일 경로와 수정 시각을 기준으로 중복을 추적한다', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = ImportHistoryService(sharedPreferences: preferences);
    final modifiedAt = DateTime(2026, 4, 17, 8, 30);
    final importedAt = DateTime(2026, 4, 17, 9, 0);

    expect(
      await service.hasImportedFile(
        path: '/tmp/journal.txt',
        modifiedAt: modifiedAt,
      ),
      isFalse,
    );

    await service.recordFileImports(<FileImportHistoryRecord>[
      FileImportHistoryRecord(
        path: '/tmp/journal.txt',
        fileName: 'journal.txt',
        modifiedAt: modifiedAt,
        sourceId: 'file-123',
        importedAt: importedAt,
      ),
    ]);

    expect(
      await service.hasImportedFile(
        path: '/tmp/journal.txt',
        modifiedAt: modifiedAt,
      ),
      isTrue,
    );

    final snapshot = await service.loadSnapshot();
    expect(snapshot.countForSource('file'), 1);
    expect(snapshot.recentEntries, hasLength(1));
    expect(snapshot.recentEntries.single.label, 'journal.txt');
  });
}
