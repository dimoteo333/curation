import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../../core/security/input_sanitizer.dart';
import '../../domain/entities/life_record.dart';
import '../local/life_record_store.dart';
import '../ondevice/semantic_embedding_service.dart';
import 'file_picker_gateway.dart';
import 'import_history_service.dart';

class FileImportResult {
  const FileImportResult({
    required this.importedCount,
    required this.duplicateFiles,
    required this.skippedFiles,
    required this.records,
  });

  final int importedCount;
  final List<String> duplicateFiles;
  final List<String> skippedFiles;
  final List<LifeRecord> records;

  bool get hasImportedRecords => importedCount > 0;
}

/// Parses local text files and persists them as life records.
class FileRecordImportService {
  FileRecordImportService({
    required this.recordStore,
    required this.filePicker,
    required this.importHistoryService,
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  final LifeRecordStore recordStore;
  final ImportFilePicker filePicker;
  final ImportHistoryService importHistoryService;
  final DateTime Function() _nowProvider;

  Future<FileImportResult> pickAndImport() async {
    final files = await filePicker.pickFiles();
    return importFiles(files);
  }

  Future<FileImportResult> importFiles(List<PickedImportFile> files) async {
    final skippedFiles = <String>[];
    final duplicateFiles = <String>[];
    final records = <LifeRecord>[];
    final importedFiles = <FileImportHistoryRecord>[];
    final seenSourceIds = <String>{};

    for (final file in files) {
      final parsedRecord = await _parseFile(file);
      if (parsedRecord == null) {
        skippedFiles.add(file.name);
        continue;
      }
      final alreadyImported = await importHistoryService.hasImportedFile(
        contentHash: parsedRecord.contentHash,
      );
      if (alreadyImported || !seenSourceIds.add(parsedRecord.record.sourceId)) {
        duplicateFiles.add(file.name);
        continue;
      }

      records.add(parsedRecord.record);
      importedFiles.add(
        FileImportHistoryRecord(
          contentHash: parsedRecord.contentHash,
          fileName: file.name,
          sourceId: parsedRecord.record.sourceId,
          importedAt: _nowProvider(),
        ),
      );
    }

    if (records.isNotEmpty) {
      await recordStore.importRecords(records);
      await importHistoryService.recordFileImports(importedFiles);
    }

    return FileImportResult(
      importedCount: records.length,
      duplicateFiles: duplicateFiles,
      skippedFiles: skippedFiles,
      records: records,
    );
  }

  Future<_ParsedImportFile?> _parseFile(PickedImportFile pickedFile) async {
    try {
      InputSanitizer.validateFileName(pickedFile.name);

      final extension = path.extension(pickedFile.path).toLowerCase();
      if (extension != '.txt' && extension != '.md') {
        return null;
      }

      final file = File(pickedFile.path);
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      if (stat.size > InputSanitizer.maxFileSizeBytes) {
        return null;
      }

      final rawBytes = await file.readAsBytes();
      final contentHash = sha256.convert(rawBytes).toString();
      final normalizedText = _decodeUtf8(rawBytes);
      if (normalizedText == null) {
        return null;
      }

      final parser = extension == '.md'
          ? _parseMarkdown(pickedFile.name, normalizedText)
          : _parsePlainText(pickedFile.name, normalizedText);
      final sanitizedTitle = InputSanitizer.sanitizeTitle(parser.title);
      final sanitizedContent = InputSanitizer.sanitizeContent(parser.content);
      final tags = await SemanticEmbeddingService.suggestTags(
        '$sanitizedTitle $sanitizedContent',
      );
      final sourceId = contentHash;
      return _ParsedImportFile(
        contentHash: contentHash,
        record: LifeRecord(
          id: 'file-$contentHash',
          sourceId: sourceId,
          source: '파일',
          importSource: 'file',
          title: sanitizedTitle,
          content: sanitizedContent,
          createdAt: stat.modified,
          tags: tags,
          metadata: <String, dynamic>{
            'content_hash': contentHash,
            'original_file_name': pickedFile.name,
            'original_file_path': pickedFile.path,
            'file_extension': extension.replaceFirst('.', ''),
            'modified_at': stat.modified.toIso8601String(),
            'imported_at': _nowProvider().toIso8601String(),
            'parser': parser.parser,
            'tag_count': tags.length,
          },
        ),
      );
    } on FileSystemException {
      return null;
    } on InputValidationException {
      return null;
    }
  }

  String? _decodeUtf8(List<int> bytes) {
    try {
      final normalizedBytes =
          bytes.length >= 3 &&
              bytes[0] == 0xEF &&
              bytes[1] == 0xBB &&
              bytes[2] == 0xBF
          ? bytes.sublist(3)
          : bytes;
      final decoded = utf8.decode(normalizedBytes, allowMalformed: false);
      final sanitized = InputSanitizer.sanitizeContent(decoded);
      return sanitized.isEmpty ? null : sanitized;
    } on FormatException {
      return null;
    } on InputValidationException {
      return null;
    }
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

class _ParsedImportFile {
  const _ParsedImportFile({required this.contentHash, required this.record});

  final String contentHash;
  final LifeRecord record;
}
