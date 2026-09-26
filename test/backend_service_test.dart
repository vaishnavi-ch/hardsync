import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hardsync/services/backend_service.dart';

void main() {
  setUp(() {
    BackendService.baseUriOverride = Uri.parse('http://test.local/');
    BackendService.sessionId = null;
  });

  tearDown(() {
    BackendService.transport.close();
    BackendService.transport = http.Client();
    BackendService.baseUriOverride = null;
    BackendService.sessionId = null;
  });

  group('BackendService request contract', () {
    test('sends GET without a body and decodes an object', () async {
      BackendService.transport = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/account');
        return http.Response('{"tier":"free","testCalls":false}', 200);
      });
      expect(await BackendService.request('/api/account'), {
        'tier': 'free',
        'testCalls': false,
      });
    });

    test('sends POST JSON and wraps list responses', () async {
      BackendService.transport = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['content-type'], 'application/json');
        expect(request.body, '{"value":1}');
        return http.Response('[1,2]', 200);
      });
      expect(await BackendService.request('/api/test', {'value': 1}), {
        'data': [1, 2],
      });
    });

    test('accepts an empty successful response', () async {
      BackendService.transport = MockClient(
        (_) async => http.Response('', 204),
      );
      expect(await BackendService.request('/api/empty'), isEmpty);
    });

    test('preserves structured API errors', () async {
      BackendService.transport = MockClient(
        (_) async =>
            http.Response('{"error":"Subscription required."}', 403),
      );
      await expectLater(
        BackendService.request('/api/sessions', {}),
        throwsA(
          isA<BackendException>()
              .having((e) => e.status, 'status', 403),
        ),
      );
    });

    test('rejects HTML, malformed JSON, and empty error bodies', () async {
      for (final response in [
        http.Response('<html>down</html>', 502),
        http.Response('{broken', 200),
        http.Response('', 500),
      ]) {
        BackendService.transport = MockClient((_) async => response);
        await expectLater(
          BackendService.request('/api/test'),
          throwsA(isA<BackendException>()),
        );
      }
    });

    test('normalizes transport failures', () async {
      BackendService.transport = MockClient((_) async {
        throw http.ClientException('offline');
      });
      await expectLater(
        BackendService.request('/api/test'),
        throwsA(
          isA<BackendException>()
              .having((e) => e.status, 'status', 0)
              .having((e) => e.toString(), 'message', contains('reach')),
        ),
      );
    });
  });

  group('Backend URI resolution', () {
    test('resolves relative paths against override', () {
      expect(
        BackendService.uri('/api/account').toString(),
        'http://test.local/api/account',
      );
    });

    test('keeps absolute URLs intact', () {
      expect(
        BackendService.uri('https://example.com/value').toString(),
        'https://example.com/value',
      );
    });
  });
}
