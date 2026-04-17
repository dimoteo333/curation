import 'package:curator_mobile/src/data/ondevice/litert_method_channel_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.curator.curator_mobile/litert_lm');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('부분 준비 상태는 native-partial로 정규화한다', () {
    final status = OnDeviceRuntimeStatus.fromJson(const <Object?, Object?>{
      'llmReady': true,
      'embedderReady': false,
      'runtime': 'native-ready',
      'message': 'LiteRT LLM은 준비되었지만 텍스트 임베딩은 Dart 폴백을 사용합니다.',
      'platform': 'android',
      'llmModelConfigured': true,
      'embedderModelConfigured': true,
      'llmModelAvailable': true,
      'embedderModelAvailable': true,
      'fallbackActive': true,
    });

    expect(status.runtime, 'native-partial');
    expect(status.usingNativeLlm, isTrue);
    expect(status.usingNativeEmbedder, isFalse);
  });

  test('임베딩 미지원 오류는 공통 메시지로 정규화한다', () async {
    messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
      if (call.method == 'embed') {
        throw PlatformException(
          code: 'embedder_unavailable',
          message: 'Android bridge raw error',
        );
      }
      return null;
    });

    const bridge = MethodChannelOnDeviceLlmBridge();

    await expectLater(
      () => bridge.embed('테스트'),
      throwsA(
        isA<OnDeviceRuntimeException>()
            .having(
              (OnDeviceRuntimeException error) => error.code,
              'code',
              'embedder_unavailable',
            )
            .having(
              (OnDeviceRuntimeException error) => error.message,
              'message',
              '네이티브 텍스트 임베딩을 사용할 수 없어 Dart 의미 임베딩 폴백을 사용합니다.',
            ),
      ),
    );
  });
}
