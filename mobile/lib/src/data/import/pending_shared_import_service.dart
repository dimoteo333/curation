import 'package:flutter/services.dart';

import '../../domain/entities/life_record.dart';
import 'file_picker_gateway.dart';
import 'file_record_import_service.dart';

typedef PendingSharedResumeHandler = Future<void> Function();

class PendingSharedImportResult {
  const PendingSharedImportResult({
    required this.pendingFileCount,
    required this.fileImportResult,
  });

  final int pendingFileCount;
  final FileImportResult fileImportResult;

  bool get hadPendingFiles => pendingFileCount > 0;
}

/// Platform bridge for files delivered through the iOS share extension.
abstract class PendingSharedImportBridge {
  Future<List<PickedImportFile>> listPendingFiles();

  Future<void> clearPendingFiles(List<PickedImportFile> files);

  void setResumeHandler(PendingSharedResumeHandler? onResume);
}

/// Method-channel implementation of the pending shared-file bridge.
class MethodChannelPendingSharedImportBridge
    implements PendingSharedImportBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.curator.curator_mobile/shared_imports',
  );
  PendingSharedResumeHandler? _onResume;

  @override
  Future<List<PickedImportFile>> listPendingFiles() async {
    try {
      final rawFiles = await _channel.invokeListMethod<Object?>(
        'listPendingSharedFiles',
      );
      if (rawFiles == null) {
        return const <PickedImportFile>[];
      }

      return rawFiles
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> rawFile) {
            final normalized = Map<String, Object?>.fromEntries(
              rawFile.entries.map(
                (entry) => MapEntry(entry.key.toString(), entry.value),
              ),
            );
            final path = normalized['path'] as String?;
            final name = normalized['name'] as String?;
            if (path == null || name == null) {
              return null;
            }
            return PickedImportFile(path: path, name: name);
          })
          .whereType<PickedImportFile>()
          .toList(growable: false);
    } on MissingPluginException {
      return const <PickedImportFile>[];
    } on PlatformException {
      return const <PickedImportFile>[];
    }
  }

  @override
  Future<void> clearPendingFiles(List<PickedImportFile> files) async {
    if (files.isEmpty) {
      return;
    }

    try {
      await _channel.invokeMethod<void>(
        'clearPendingSharedFiles',
        <String, Object>{
          'paths': files.map((file) => file.path).toList(growable: false),
        },
      );
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  @override
  void setResumeHandler(PendingSharedResumeHandler? onResume) {
    _onResume = onResume;
    _channel.setMethodCallHandler(
      onResume == null
          ? null
          : (MethodCall call) async {
              if (call.method == 'appDidResume') {
                await _onResume?.call();
              }
            },
    );
  }
}

/// Drains pending shared files into the normal file import pipeline.
class PendingSharedImportService {
  const PendingSharedImportService({
    required this.bridge,
    required this.fileImportService,
  });

  final PendingSharedImportBridge bridge;
  final FileRecordImportService fileImportService;

  Future<PendingSharedImportResult> importPendingSharedFiles() async {
    final files = await bridge.listPendingFiles();
    if (files.isEmpty) {
      return PendingSharedImportResult(
        pendingFileCount: 0,
        fileImportResult: const FileImportResult(
          importedCount: 0,
          duplicateFiles: <String>[],
          skippedFiles: <String>[],
          records: <LifeRecord>[],
        ),
      );
    }

    final importResult = await fileImportService.importFiles(files);
    await bridge.clearPendingFiles(files);
    return PendingSharedImportResult(
      pendingFileCount: files.length,
      fileImportResult: importResult,
    );
  }
}
