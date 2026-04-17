import 'dart:io';

import 'package:path/path.dart' as path;

import '../../domain/entities/life_record.dart';
import '../local/life_record_store.dart';
import '../ondevice/semantic_embedding_service.dart';
import 'file_picker_gateway.dart';

class FileImportResult {
  const FileImportResult({
    required this.importedCount,
    required this.skippedFiles,
    required this.records,
  });

  final int importedCount;
  final List<String> skippedFiles;
  final List<LifeRecord> records;

  bool get hasImportedRecords => importedCount > 0;
}

class FileRecordImportService {
  FileRecordImportService({
    required this.recordStore,
    required this.filePicker,
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  final LifeRecordStore recordStore;
  final ImportFilePicker filePicker;
  final DateTime Function() _nowProvider;

  Future<FileImportResult> pickAndImport() async {
    final files = await filePicker.pickFiles();
    return importFiles(files);
  }

  Future<FileImportResult> importFiles(List<PickedImportFile> files) async {
    final skippedFiles = <String>[];
    final records = <LifeRecord>[];

    for (final file in files) {
      final record = await _parseFile(file);
      if (record == null) {
        skippedFiles.add(file.name);
        continue;
      }
      records.add(record);
    }

    if (records.isNotEmpty) {
      await recordStore.importRecords(records);
    }

    return FileImportResult(
      importedCount: records.length,
      skippedFiles: skippedFiles,
      records: records,
    );
  }

  Future<LifeRecord?> _parseFile(PickedImportFile pickedFile) async {
    final extension = path.extension(pickedFile.path).toLowerCase();
    if (extension != '.txt' && extension != '.md') {
      return null;
    }

    final file = File(pickedFile.path);
    if (!await file.exists()) {
      return null;
    }

    final rawText = await file.readAsString();
    final normalizedText = rawText.replaceAll('\r\n', '\n').trim();
    if (normalizedText.isEmpty) {
      return null;
    }

    final stat = await file.stat();
    final parser = extension == '.md'
        ? _parseMarkdown(pickedFile.name, normalizedText)
        : _parsePlainText(pickedFile.name, normalizedText);
    final tags = SemanticEmbeddingService.suggestTags(
      '${parser.title} ${parser.content}',
    );

    return LifeRecord(
      id: _buildRecordId(fileName: pickedFile.name, modifiedAt: stat.modified),
      source: '파일',
      importSource: 'file',
      title: parser.title,
      content: parser.content,
      createdAt: stat.modified,
      tags: tags,
      metadata: <String, dynamic>{
        'file_name': pickedFile.name,
        'file_extension': extension.replaceFirst('.', ''),
        'modified_at': stat.modified.toIso8601String(),
        'imported_at': _nowProvider().toIso8601String(),
        'parser': parser.parser,
        'tag_count': tags.length,
      },
    );
  }

  String _buildRecordId({
    required String fileName,
    required DateTime modifiedAt,
  }) {
    final sanitizedName = path
        .basenameWithoutExtension(fileName)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9가-힣]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return 'file-$sanitizedName-${modifiedAt.millisecondsSinceEpoch}';
  }

  _ParsedImportRecord _parseMarkdown(String fileName, String content) {
    final lines = content.split('\n');
    var headerIndex = -1;
    var title = '';

    for (var index = 0; index < lines.length; index += 1) {
      final trimmed = lines[index].trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final match = RegExp(r'^#{1,6}\s+(.+)$').firstMatch(trimmed);
      if (match == null) {
        break;
      }
      headerIndex = index;
      title = match.group(1)!.trim();
      break;
    }

    final fallbackTitle = path.basenameWithoutExtension(fileName);
    if (headerIndex == -1) {
      return _ParsedImportRecord(
        title: fallbackTitle,
        content: content,
        parser: 'markdown-fallback',
      );
    }

    final remainingLines = <String>[
      for (var index = 0; index < lines.length; index += 1)
        if (index != headerIndex) lines[index],
    ];
    final body = remainingLines.join('\n').trim();
    return _ParsedImportRecord(
      title: title.isEmpty ? fallbackTitle : title,
      content: body.isEmpty ? title : body,
      parser: 'markdown-header',
    );
  }

  _ParsedImportRecord _parsePlainText(String fileName, String content) {
    final lines = content
        .split('\n')
        .map((String line) => line.trimRight())
        .toList(growable: false);
    final fallbackTitle = path.basenameWithoutExtension(fileName);
    final firstNonEmptyLineIndex = lines.indexWhere(
      (String line) => line.trim().isNotEmpty,
    );

    if (firstNonEmptyLineIndex == -1) {
      return _ParsedImportRecord(
        title: fallbackTitle,
        content: content,
        parser: 'plain-fallback',
      );
    }

    final firstLine = lines[firstNonEmptyLineIndex].trim();
    final remainingLines = <String>[
      for (
        var index = firstNonEmptyLineIndex + 1;
        index < lines.length;
        index += 1
      )
        lines[index],
    ];
    final remainingBody = remainingLines.join('\n').trim();

    if (firstLine.length <= 60 && remainingBody.isNotEmpty) {
      return _ParsedImportRecord(
        title: firstLine,
        content: remainingBody,
        parser: 'plain-first-line',
      );
    }

    return _ParsedImportRecord(
      title: fallbackTitle,
      content: content,
      parser: 'plain-fallback',
    );
  }
}

class _ParsedImportRecord {
  const _ParsedImportRecord({
    required this.title,
    required this.content,
    required this.parser,
  });

  final String title;
  final String content;
  final String parser;
}
