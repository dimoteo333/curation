import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

class InputValidationException implements Exception {
  const InputValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InputSanitizer {
  const InputSanitizer._();

  static const int maxQuestionLength = 280;
  static const int maxFileSizeBytes = 1024 * 1024;
  static const int maxTitleLength = 120;
  static const int maxContentLength = 16000;

  static final RegExp _disallowedControlCharacters = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]',
  );

  static String sanitizeQuestion(String rawValue) {
    final normalized = _normalizeText(
      rawValue,
      maxLength: maxQuestionLength,
      preserveNewLines: false,
      truncate: false,
    );
    if (normalized.length < 2) {
      throw const InputValidationException('질문은 두 글자 이상 입력해 주세요.');
    }
    return normalized;
  }

  static String sanitizeTitle(String rawValue) {
    final normalized = _normalizeText(
      rawValue,
      maxLength: maxTitleLength,
      preserveNewLines: false,
      truncate: true,
    );
    if (normalized.isEmpty) {
      throw const InputValidationException('파일 제목이 비어 있습니다.');
    }
    return normalized;
  }

  static String sanitizeContent(String rawValue) {
    final normalized = _normalizeText(
      rawValue,
      maxLength: maxContentLength,
      preserveNewLines: true,
      truncate: true,
    );
    if (normalized.isEmpty) {
      throw const InputValidationException('파일 내용이 비어 있습니다.');
    }
    return normalized;
  }

  static void validateFileName(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      throw const InputValidationException('파일 이름이 비어 있습니다.');
    }
    if (trimmed.contains('/') || trimmed.contains(r'\')) {
      throw const InputValidationException('파일 이름에 경로 구분자가 포함되어 있습니다.');
    }
    if (trimmed.contains('..')) {
      throw const InputValidationException('파일 이름에 상위 경로 이동 문자가 포함되어 있습니다.');
    }
    if (path.basename(trimmed) != trimmed) {
      throw const InputValidationException('파일 이름이 올바르지 않습니다.');
    }
  }

  static String buildFileNameFingerprint(String rawValue) {
    final digest = sha256.convert(utf8.encode(rawValue.trim())).toString();
    return digest.substring(0, 16);
  }

  static String _normalizeText(
    String rawValue, {
    required int maxLength,
    required bool preserveNewLines,
    required bool truncate,
  }) {
    var normalized = rawValue.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    normalized = normalized.replaceAll(_disallowedControlCharacters, '');
    if (!preserveNewLines) {
      normalized = normalized.replaceAll('\n', ' ');
    }
    normalized = normalized.trim();
    normalized = normalized.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    if (normalized.length > maxLength) {
      if (!truncate) {
        throw InputValidationException('입력은 최대 $maxLength자까지 가능합니다.');
      }
      normalized = normalized.substring(0, maxLength).trim();
    }
    return normalized;
  }
}
