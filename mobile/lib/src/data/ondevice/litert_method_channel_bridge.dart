import 'package:flutter/services.dart';

class OnDeviceRuntimeException implements Exception {
  const OnDeviceRuntimeException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OnDeviceRuntimeStatus {
  const OnDeviceRuntimeStatus({
    required this.llmReady,
    required this.embedderReady,
    required this.runtime,
    required this.message,
  });

  final bool llmReady;
  final bool embedderReady;
  final String runtime;
  final String message;

  factory OnDeviceRuntimeStatus.fromJson(Map<Object?, Object?> json) {
    return OnDeviceRuntimeStatus(
      llmReady: json['llmReady'] as bool? ?? false,
      embedderReady: json['embedderReady'] as bool? ?? false,
      runtime: json['runtime'] as String? ?? 'unavailable',
      message: json['message'] as String? ?? '온디바이스 런타임이 준비되지 않았습니다.',
    );
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

  static const MethodChannel _channel = MethodChannel(
    'com.curator.curator_mobile/litert_lm',
  );

  @override
  Future<OnDeviceRuntimeStatus> prepare({
    String? llmModelPath,
    String? embedderModelPath,
  }) async {
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'prepare',
        <String, Object?>{
          'llmModelPath': llmModelPath,
          'embedderModelPath': embedderModelPath,
        },
      );
      return OnDeviceRuntimeStatus.fromJson(
        response ?? const <Object?, Object?>{},
      );
    } on MissingPluginException {
      return const OnDeviceRuntimeStatus(
        llmReady: false,
        embedderReady: false,
        runtime: 'template-fallback',
        message: 'Flutter 테스트 환경에서는 네이티브 LiteRT 브릿지가 연결되지 않습니다.',
      );
    } on PlatformException catch (error) {
      return OnDeviceRuntimeStatus(
        llmReady: false,
        embedderReady: false,
        runtime: 'native-error',
        message: error.message ?? '온디바이스 런타임 준비에 실패했습니다.',
      );
    }
  }

  @override
  Future<OnDeviceRuntimeStatus> status() async {
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'status',
      );
      return OnDeviceRuntimeStatus.fromJson(
        response ?? const <Object?, Object?>{},
      );
    } on MissingPluginException {
      return const OnDeviceRuntimeStatus(
        llmReady: false,
        embedderReady: false,
        runtime: 'template-fallback',
        message: '네이티브 브릿지가 아직 연결되지 않아 로컬 템플릿 엔진을 사용합니다.',
      );
    } on PlatformException catch (error) {
      return OnDeviceRuntimeStatus(
        llmReady: false,
        embedderReady: false,
        runtime: 'native-error',
        message: error.message ?? '온디바이스 런타임 상태 확인에 실패했습니다.',
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
      throw const OnDeviceRuntimeException('네이티브 LLM 브릿지가 연결되지 않았습니다.');
    } on PlatformException catch (error) {
      throw OnDeviceRuntimeException(
        error.message ?? '온디바이스 LLM 생성 중 오류가 발생했습니다.',
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
      throw const OnDeviceRuntimeException('네이티브 임베더 브릿지가 연결되지 않았습니다.');
    } on PlatformException catch (error) {
      throw OnDeviceRuntimeException(
        error.message ?? '온디바이스 임베딩 중 오류가 발생했습니다.',
      );
    }
  }
}
