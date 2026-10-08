import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/backend/api_client.dart';
import 'package:hazri/core/backend/api_exception.dart';
import 'package:hazri/core/backend/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeAuth implements AuthService {
  int refreshes = 0;
  bool offline = false;

  @override
  String? get uid => 'uid-1';

  @override
  Future<void> ensureSignedIn() async {}

  @override
  Future<String> idToken({bool forceRefresh = false}) async {
    if (offline) throw const NetworkException('offline');
    if (forceRefresh) refreshes++;
    return forceRefresh ? 'fresh' : 'stale';
  }
}

/// `01-accounts.md` §8.2: the ApiClient's five rules, both paths of each.
void main() {
  late _FakeAuth auth;
  setUp(() => auth = _FakeAuth());

  ApiClient client(MockClientHandler handler) => ApiClient(
        auth: auth,
        client: MockClient(handler),
        baseUrl: 'https://example.test/api/v1',
        timeout: const Duration(milliseconds: 200),
      );

  test('sends the bearer token and JSON, and decodes a 2xx', () async {
    late http.Request seen;
    final api = client((req) async {
      seen = req;
      return http.Response(jsonEncode({'ok': true}), 200);
    });
    final body = await api.post('/profile', {'name': 'Harpreet'});
    expect(body, {'ok': true});
    expect(seen.url.toString(), 'https://example.test/api/v1/profile');
    expect(seen.headers['Authorization'], 'Bearer stale');
    expect(seen.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(seen.body), {'name': 'Harpreet'});
  });

  test('a 401 refreshes the token and retries once', () async {
    final tokens = <String?>[];
    final api = client((req) async {
      tokens.add(req.headers['Authorization']);
      return tokens.length == 1
          ? http.Response('', 401)
          : http.Response(jsonEncode({'result': 'ok'}), 200);
    });
    expect(await api.get('/profile'), {'result': 'ok'});
    expect(tokens, ['Bearer stale', 'Bearer fresh']);
    expect(auth.refreshes, 1);
  });

  test('a second 401 throws, and there is no third try', () async {
    var calls = 0;
    final api = client((req) async {
      calls++;
      return http.Response(
          jsonEncode({'error': {'code': 'UNAUTHENTICATED', 'message': 'no'}}), 401);
    });
    await expectLater(
      api.get('/profile'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
    );
    expect(calls, 2);
  });

  test('a non-2xx is parsed from the common error body', () async {
    final api = client((req) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Check the form',
              'fields': {'name': 'too short'},
            },
          }),
          400,
        ));
    final e = await api.post('/profile', {}).then<ApiException?>((_) => null,
        onError: (Object e) => e as ApiException);
    expect(e!.statusCode, 400);
    expect(e.fields, {'name': 'too short'});
  });

  test('RATE_LIMITED carries retryAfterSeconds; a token error its purpose', () async {
    final api = client((req) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'RATE_LIMITED',
              'message': 'Wait',
              'retryAfterSeconds': 42,
              'purpose': 'VERIFY_EMAIL',
            },
          }),
          429,
        ));
    try {
      await api.post('/profile/verification-email');
      fail('should throw');
    } on ApiException catch (e) {
      expect(e.retryAfterSeconds, 42);
      expect(e.purpose, 'VERIFY_EMAIL');
    }
  });

  test('a body that is not the common shape still throws, with the status', () async {
    final api = client((req) async => http.Response('<html>Bad gateway</html>', 502));
    await expectLater(
      api.get('/profile'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'HTTP_502')),
    );
  });

  test('no network, a timeout and an offline sign-in are NetworkException',
      () async {
    final down = client((req) async => throw const SocketException('down'));
    await expectLater(down.get('/x'), throwsA(isA<NetworkException>()));

    final slow = client((req) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return http.Response('{}', 200);
    });
    await expectLater(slow.get('/x'), throwsA(isA<NetworkException>()));

    auth.offline = true;
    final ok = client((req) async => http.Response('{}', 200));
    await expectLater(ok.get('/x'), throwsA(isA<NetworkException>()));
  });

  test('query parameters are encoded onto the path', () async {
    late Uri seen;
    final api = client((req) async {
      seen = req.url;
      return http.Response('{}', 200);
    });
    await api.get('/backup/weeks', query: {'from': '2026-10-04', 'limit': '8'});
    expect(seen.queryParameters, {'from': '2026-10-04', 'limit': '8'});
  });
}
