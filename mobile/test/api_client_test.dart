import 'package:curator_mobile/src/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('기본 요청 타임아웃은 10초다', () {
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((http.Request request) async {
        return http.Response('{"ok":true}', 200);
      }),
    );

    expect(client.requestTimeout, const Duration(seconds: 10));
  });

  test('timeout 발생 시 한 번 재시도한 뒤 ApiException을 던진다', () async {
    var callCount = 0;
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((http.Request request) async {
        callCount += 1;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response('{"ok":true}', 200);
      }),
      requestTimeout: const Duration(milliseconds: 5),
    );

    await expectLater(
      () => client.postJson('/api/test', body: const <String, dynamic>{}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '요청 시간이 초과되었습니다. 잠시 후 다시 시도해 주세요.',
        ),
      ),
    );
    expect(callCount, 2);
  });

  test('200 응답이 JSON이 아니면 의미 있는 ApiException을 던진다', () async {
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((http.Request request) async {
        return http.Response('<html>bad gateway</html>', 200);
      }),
    );

    await expectLater(
      () => client.postJson('/api/test', body: const <String, dynamic>{}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '서버 응답을 JSON으로 해석하지 못했습니다.',
        ),
      ),
    );
  });

  test('502 응답은 한 번 재시도한 뒤 서버 오류 메시지를 던진다', () async {
    var callCount = 0;
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((http.Request request) async {
        callCount += 1;
        return http.Response('', 502);
      }),
    );

    await expectLater(
      () => client.postJson('/api/test', body: const <String, dynamic>{}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '서버 오류로 요청을 처리하지 못했습니다.',
        ),
      ),
    );
    expect(callCount, 2);
  });

  test('400 plain text 응답은 본문 메시지를 보존한다', () async {
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((http.Request request) async {
        return http.Response('잘못된 요청입니다.', 400,
            headers: {'content-type': 'text/plain; charset=utf-8'});
      }),
    );

    await expectLater(
      () => client.postJson('/api/test', body: const <String, dynamic>{}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '잘못된 요청입니다.',
        ),
      ),
    );
  });

  test('빈 200 응답은 명시적인 ApiException을 던진다', () async {
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((http.Request request) async {
        return http.Response('', 200);
      }),
    );

    await expectLater(
      () => client.postJson('/api/test', body: const <String, dynamic>{}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '서버가 빈 응답을 반환했습니다.',
        ),
      ),
    );
  });
}
