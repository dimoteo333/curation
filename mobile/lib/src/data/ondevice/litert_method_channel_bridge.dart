import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class OnDeviceRuntimeException implements Exception {
  const OnDeviceRuntimeException(this.message, {this.code = 'runtime_error'});

  final String message;
  final String code;

  @override
  String toString() => message;
}

class OnDeviceRuntimeStatus {
  const OnDeviceRuntimeStatus({
    required this.llmReady,
    required this.embedderReady,
    required this.runtime,
    required this.message,
    required this.platform,
    required this.llmModelConfigured,
    required this.embedderModelConfigured,
    required this.llmModelAvailable,
    required this.embedderModelAvailable,
    required this.fallbackActive,
    this.lastError,
    this.lastPrepareDurationMs,
  });

  final bool llmReady;
  final bool embedderReady;
  final String runtime;
  final String message;
  final String platform;
  final bool llmModelConfigured;
  final bool embedderModelConfigured;
  final bool llmModelAvailable;
  final bool embedderModelAvailable;
  final bool fallbackActive;
  final String? lastError;
  final int? lastPrepareDurationMs;

  bool get usingNativeLlm => llmReady;
  bool get usingNativeEmbedder => embedderReady;

  factory OnDeviceRuntimeStatus.fromJson(Map<Object?, Object?> json) {
    final llmReady = json['llmReady'] as bool? ?? false;
    final embedderReady = json['embedderReady'] as bool? ?? false;
    return OnDeviceRuntimeStatus(
      llmReady: llmReady,
      embedderReady: embedderReady,
      runtime: _normalizedRuntime(
        json['runtime'] as String?,
        llmReady: llmReady,
        embedderReady: embedderReady,
      ),
      message: json['message'] as String? ?? '온디바이스 런타임이 준비되지 않았습니다.',
      platform: json['platform'] as String? ?? _currentPlatformLabel(),
      llmModelConfigured: json['llmModelConfigured'] as bool? ?? false,
      embedderModelConfigured:
          json['embedderModelConfigured'] as bool? ?? false,
      llmModelAvailable: json['llmModelAvailable'] as bool? ?? false,
      embedderModelAvailable: json['embedderModelAvailable'] as bool? ?? false,
      fallbackActive: json['fallbackActive'] as bool? ?? true,
      lastError: json['lastError'] as String?,
      lastPrepareDurationMs: (json['lastPrepareDurationMs'] as num?)?.toInt(),
    );
  }

  factory OnDeviceRuntimeStatus.remoteHarness() {
    return const OnDeviceRuntimeStatus(
      llmReady: false,
      embedderReady: false,
      runtime: 'remote-harness',
      message: '현재는 FastAPI 개발 하네스를 사용합니다.',
      platform: 'remote',
      llmModelConfigured: false,
      embedderModelConfigured: false,
      llmModelAvailable: false,
      embedderModelAvailable: false,
      fallbackActive: false,
    );
  }

  factory OnDeviceRuntimeStatus.missingPlugin({
    String? llmModelPath,
    String? embedderModelPath,
    String message = 'Flutter 테스트 환경에서는 네이티브 LiteRT 브릿지가 연결되지 않습니다.',
  }) {
    return OnDeviceRuntimeStatus(
      llmReady: false,
      embedderReady: false,
      runtime: 'template-fallback',
      message: message,
      platform: 'flutter-test',
      llmModelConfigured: _isConfigured(llmModelPath),
      embedderModelConfigured: _isConfigured(embedderModelPath),
      llmModelAvailable: _pathExists(llmModelPath),
      embedderModelAvailable: _pathExists(embedderModelPath),
      fallbackActive: true,
    );
  }

  factory OnDeviceRuntimeStatus.timeout({
    String? llmModelPath,
    String? embedderModelPath,
    Duration timeout = MethodChannelOnDeviceLlmBridge.prepareTimeout,
    String? platform,
  }) {
    return OnDeviceRuntimeStatus(
      llmReady: false,
      embedderReady: false,
      runtime: 'timeout-fallback',
      message: '네이티브 런타임 초기화가 ${timeout.inSeconds}초 안에 끝나지 않아 템플릿 폴백으로 전환했습니다.',
      platform: platform ?? _currentPlatformLabel(),
      llmModelConfigured: _isConfigured(llmModelPath),
      embedderModelConfigured: _isConfigured(embedderModelPath),
      llmModelAvailable: _pathExists(llmModelPath),
      embedderModelAvailable: _pathExists(embedderModelPath),
      fallbackActive: true,
      lastError: 'bridge-timeout',
      lastPrepareDurationMs: timeout.inMilliseconds,
    );
  }

  factory OnDeviceRuntimeStatus.nativeError({
    required String message,
    String? llmModelPath,
    String? embedderModelPath,
    String? platform,
  }) {
    return OnDeviceRuntimeStatus(
      llmReady: false,
      embedderReady: false,
      runtime: 'native-error',
      message: message,
      platform: platform ?? _currentPlatformLabel(),
      llmModelConfigured: _isConfigured(llmModelPath),
      embedderModelConfigured: _isConfigured(embedderModelPath),
      llmModelAvailable: _pathExists(llmModelPath),
      embedderModelAvailable: _pathExists(embedderModelPath),
      fallbackActive: true,
      lastError: message,
    );
  }

  static bool _isConfigured(String? path) =>
      path != null && path.trim().isNotEmpty;

  static bool _pathExists(String? path) {
    if (!_isConfigured(path)) {
      return false;
    }
    return File(path!).existsSync();
  }

  static String _normalizedRuntime(
    String? rawRuntime, {
    required bool llmReady,
    required bool embedderReady,
  }) {
    if (llmReady && !embedderReady) {
      return 'native-partial';
    }
    return rawRuntime ?? 'unavailable';
  }

  static String _currentPlatformLabel() {
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    return 'unknown';
  }
}

abstract class OnDeviceLlmBridge {
  Future<OnDeviceRuntimeStatus> prepare({
    String? llmModelPath,
    String? embedderModelPath,
  });

  Future<OnDeviceRuntimeStatus> status();

  Future<String> generate({
    required String prompt,
    int maxTokens = 320,
    double temperature = 0.3,
    int topK = 32,
    int randomSeed = 17,
  });

  Future<List<double>> embed(String text);
}

class MethodChannelOnDeviceLlmBridge implements OnDeviceLlmBridge {
  const MethodChannelOnDeviceLlmBridge();

  static const Duration prepareTimeout = Duration(seconds: 4);

  static const MethodChannel _channel = MethodChannel(
    'com.curator.curator_mobile/litert_lm',
  );

  @override
  Future<OnDeviceRuntimeStatus> prepare({
    String? llmModelPath,
    String? embedderModelPath,
  }) async {
    try {
      final response = await _channel
          .invokeMapMethod<Object?, Object?>('prepare', <String, Object?>{
            'llmModelPath': llmModelPath,
            'embedderModelPath': embedderModelPath,
          })
          .timeout(prepareTimeout);
      return OnDeviceRuntimeStatus.fromJson(
        response ?? const <Object?, Object?>{},
      );
    } on TimeoutException {
      return OnDeviceRuntimeStatus.timeout(
        llmModelPath: llmModelPath,
        embedderModelPath: embedderModelPath,
      );
    } on MissingPluginException {
      return OnDeviceRuntimeStatus.missingPlugin(
        llmModelPath: llmModelPath,
        embedderModelPath: embedderModelPath,
      );
    } on PlatformException catch (error) {
      return OnDeviceRuntimeStatus.nativeError(
        message: _normalizedPlatformErrorMessage(
          error,
          fallbackMessage: '온디바이스 런타임 준비에 실패했습니다.',
        ),
        llmModelPath: llmModelPath,
        embedderModelPath: embedderModelPath,
      );
    }
  }

  @override
  Future<OnDeviceRuntimeStatus> status() async {
    try {
      final response = await _channel
          .invokeMapMethod<Object?, Object?>('status')
          .timeout(prepareTimeout);
      return OnDeviceRuntimeStatus.fromJson(
        response ?? const <Object?, Object?>{},
      );
    } on TimeoutException {
      return OnDeviceRuntimeStatus.timeout();
    } on MissingPluginException {
      return OnDeviceRuntimeStatus.missingPlugin(
        message: '네이티브 브릿지가 아직 연결되지 않아 로컬 템플릿 엔진을 사용합니다.',
      );
    } on PlatformException catch (error) {
      return OnDeviceRuntimeStatus.nativeError(
        message: _normalizedPlatformErrorMessage(
          error,
          fallbackMessage: '온디바이스 런타임 상태 확인에 실패했습니다.',
        ),
      );
    }
  }

  @override
  Future<String> generate({
    required String prompt,
    int maxTokens = 320,
    double temperature = 0.3,
    int topK = 32,
    int randomSeed = 17,
  }) async {
    try {
      final response = await _channel
          .invokeMethod<String>('generate', <String, Object?>{
            'prompt': prompt,
            'maxTokens': maxTokens,
            'temperature': temperature,
            'topK': topK,
            'randomSeed': randomSeed,
          });
      if (response == null || response.trim().isEmpty) {
        throw const OnDeviceRuntimeException('온디바이스 생성 결과가 비어 있습니다.');
      }
      return response;
    } on MissingPluginException {
      throw const OnDeviceRuntimeException(
        '네이티브 LLM 브릿지가 연결되지 않았습니다.',
        code: 'missing_plugin',
      );
    } on PlatformException catch (error) {
      throw _runtimeExceptionFromPlatform(
        error,
        fallbackCode: 'generate_failed',
        fallbackMessage: '온디바이스 LLM 생성 중 오류가 발생했습니다.',
      );
    }
  }

  @override
  Future<List<double>> embed(String text) async {
    try {
      final response = await _channel.invokeListMethod<double>(
        'embed',
        <String, Object?>{'text': text},
      );
      if (response == null || response.isEmpty) {
        throw const OnDeviceRuntimeException('온디바이스 임베딩 결과가 비어 있습니다.');
      }
      return response;
    } on MissingPluginException {
      throw const OnDeviceRuntimeException(
        '네이티브 임베더 브릿지가 연결되지 않았습니다.',
        code: 'missing_plugin',
      );
    } on PlatformException catch (error) {
      throw _runtimeExceptionFromPlatform(
        error,
        fallbackCode: 'embed_failed',
        fallbackMessage: '온디바이스 임베딩 중 오류가 발생했습니다.',
      );
    }
  }

  static OnDeviceRuntimeException _runtimeExceptionFromPlatform(
    PlatformException error, {
    required String fallbackCode,
    required String fallbackMessage,
  }) {
    return OnDeviceRuntimeException(
      _normalizedPlatformErrorMessage(error, fallbackMessage: fallbackMessage),
      code: error.code.isEmpty ? fallbackCode : error.code,
    );
  }

  static String _normalizedPlatformErrorMessage(
    PlatformException error, {
    required String fallbackMessage,
  }) {
    return switch (error.code) {
      'llm_unavailable' => 'LLM 모델 경로가 준비되지 않았습니다.',
      'embedder_unavailable' => '네이티브 텍스트 임베딩을 사용할 수 없어 Dart 의미 임베딩 폴백을 사용합니다.',
      'invalid_prompt' => '프롬프트가 비어 있습니다.',
      'invalid_text' => '임베딩할 텍스트가 비어 있습니다.',
      _ => error.message ?? fallbackMessage,
    };
  }
}
