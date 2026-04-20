import 'package:curator_mobile/src/data/import/file_picker_gateway.dart';
import 'package:curator_mobile/src/data/import/pending_shared_import_service.dart';
import 'package:curator_mobile/src/data/import/file_record_import_service.dart';

class FakePendingSharedImportService implements PendingSharedImportService {
  @override
  final PendingSharedImportBridge bridge;

  FakePendingSharedImportService() : bridge = _FakeBridge();

  @override
  FileRecordImportService get fileImportService => throw UnimplementedError(
    'FakePendingSharedImportService.fileImportService',
  );

  @override
  Future<PendingSharedImportResult> importPendingSharedFiles() async {
    return PendingSharedImportResult(
      pendingFileCount: 0,
      fileImportResult: FileImportResult(
        importedCount: 0,
        duplicateFiles: [],
        skippedFiles: [],
        records: [],
      ),
    );
  }
}

class _FakeBridge implements PendingSharedImportBridge {
  @override
  Future<List<PickedImportFile>> listPendingFiles() async => const [];
  @override
  Future<void> clearPendingFiles(List<PickedImportFile> files) async {}
  @override
  void setResumeHandler(PendingSharedResumeHandler? onResume) {}
}
