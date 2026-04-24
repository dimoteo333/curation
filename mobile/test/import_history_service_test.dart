import 'package:curator_mobile/src/data/import/import_history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('import history는 content hash를 기준으로 중복을 추적한다', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = ImportHistoryService(sharedPreferences: preferences);
    final importedAt = DateTime(2026, 4, 17, 9, 0);

    expect(await service.hasImportedFile(contentHash: 'abc123'), isFalse);

    await service.recordFileImports(<FileImportHistoryRecord>[
      FileImportHistoryRecord(
        contentHash: 'abc123',
        fileName: 'journal.txt',
        sourceId: 'abc123',
        importedAt: importedAt,
      ),
    ]);

    expect(await service.hasImportedFile(contentHash: 'abc123'), isTrue);

    final snapshot = await service.loadSnapshot();
    expect(snapshot.countForSource('file'), 1);
    expect(snapshot.recentEntries, hasLength(1));
    expect(snapshot.recentEntries.single.label, 'journal.txt');
  });
}
