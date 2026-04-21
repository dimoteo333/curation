import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class PickedImportFile {
  const PickedImportFile({required this.path, required this.name});

  final String path;
  final String name;
}

abstract class ImportFilePicker {
  Future<List<PickedImportFile>> pickFiles();
}

class FilePickerImportFilePicker implements ImportFilePicker {
  const FilePickerImportFilePicker();

  @override
  Future<List<PickedImportFile>> pickFiles() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: const <String>['txt', 'md'],
      );
    } on MissingPluginException {
      return const <PickedImportFile>[];
    } on PlatformException {
      return const <PickedImportFile>[];
    }
    if (result == null) {
      return const <PickedImportFile>[];
    }

    return result.files
        .where((PlatformFile file) => file.path != null)
        .map(
          (PlatformFile file) =>
              PickedImportFile(path: file.path!, name: file.name),
        )
        .toList(growable: false);
  }
}
