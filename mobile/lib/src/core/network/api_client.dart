import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required http.Client client,
    this.requestTimeout = const Duration(seconds: 10),
    this.retryCount = 1,
  }) : _client = client;

  final String baseUrl;
  final http.Client _client;
  final Duration requestTimeout;
  final int retryCount;

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    for (var attempt = 0; attempt <= retryCount; attempt += 1) {
      try {
        final response = await _client
            .post(
              Uri.parse('$baseUrl$path'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(requestTimeout);

        if (response.statusCode >= 500 && attempt < retryCount) {
          continue;
        }

        if (response.statusCode >= 400) {
          throw ApiException(_errorMessageForResponse(response));
        }

        return _decodeSuccessResponse(response);
      } on TimeoutException {
        if (attempt >= retryCount) {
          throw const ApiException('요청 시간이 초과되었습니다. 잠시 후 다시 시도해 주세요.');
        }
      } on http.ClientException catch (error) {
        if (attempt >= retryCount) {
          throw ApiException('네트워크 연결에 실패했습니다: ${error.message}');
        }
      } on ApiException {
        rethrow;
      } catch (_) {
        if (attempt >= retryCount) {
          throw const ApiException('요청 처리 중 알 수 없는 오류가 발생했습니다.');
        }
      }
    }

    throw const ApiException('요청 처리 중 오류가 발생했습니다.');
  }

  Map<String, dynamic> _decodeSuccessResponse(http.Response response) {
    final normalizedBody = response.body.trim();
    if (normalizedBody.isEmpty) {
      throw const ApiException('서버가 빈 응답을 반환했습니다.');
    }

    try {
      final decoded = jsonDecode(normalizedBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      throw const ApiException('서버 응답을 JSON으로 해석하지 못했습니다.');
    }

    throw const ApiException('서버 응답 형식이 올바르지 않습니다.');
  }

  String _errorMessageForResponse(http.Response response) {
    final normalizedBody =
        utf8.decode(response.bodyBytes, allowMalformed: true).trim();
    if (normalizedBody.isEmpty) {
      return _defaultErrorMessage(response.statusCode);
    }

    String? extractedMessage;
    try {
      final decoded = jsonDecode(normalizedBody);
      extractedMessage = _errorMessageFromDecodedBody(decoded);
    } on FormatException {
      extractedMessage = _plainTextErrorMessage(normalizedBody);
    }

    return extractedMessage ?? _defaultErrorMessage(response.statusCode);
  }

  String _defaultErrorMessage(int statusCode) {
    if (statusCode == 408 || statusCode == 504) {
      return '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.';
    }
    if (statusCode == 429) {
      return '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.';
    }
    if (statusCode >= 500) {
      return '서버 오류로 요청을 처리하지 못했습니다.';
    }
    return '요청을 처리하지 못했습니다. 입력을 확인한 뒤 다시 시도해 주세요.';
  }

  String? _errorMessageFromDecodedBody(Object? decoded) {
    if (decoded is Map) {
      for (final key in const <String>['detail', 'message', 'error']) {
        final message = _stringFromErrorValue(decoded[key]);
        if (message != null) {
          return message;
        }
      }
    }

    if (decoded is List) {
      for (final item in decoded) {
        final message = _stringFromErrorValue(item);
        if (message != null) {
          return message;
        }
      }
    }

    return null;
  }

  String? _stringFromErrorValue(Object? value) {
    if (value is String) {
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    }

    if (value is Map) {
      for (final nestedKey in const <String>['message', 'detail', 'msg']) {
        final nested = _stringFromErrorValue(value[nestedKey]);
        if (nested != null) {
          return nested;
        }
      }
    }

    if (value is List) {
      final messages = value
          .map(_stringFromErrorValue)
          .whereType<String>()
          .toList(growable: false);
      if (messages.isEmpty) {
        return null;
      }
      return messages.join(' / ');
    }

    return null;
  }

  String? _plainTextErrorMessage(String normalizedBody) {
    final looksLikeHtml =
        normalizedBody.startsWith('<!DOCTYPE') ||
        normalizedBody.startsWith('<html') ||
        RegExp(r'<[^>]+>').hasMatch(normalizedBody);
    if (looksLikeHtml) {
      return null;
    }

    if (normalizedBody.length <= 160) {
      return normalizedBody;
    }
    return '${normalizedBody.substring(0, 157).trimRight()}...';
  }
}
