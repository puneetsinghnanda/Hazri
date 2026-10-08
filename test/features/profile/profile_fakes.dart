import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazri/core/backend/api_client.dart';
import 'package:hazri/core/backend/api_exception.dart';
import 'package:hazri/core/backend/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A signed-in install with a fixed uid.
class FakeAuth implements AuthService {
  FakeAuth([this.uid = 'uid-1']);

  @override
  final String? uid;

  @override
  Future<void> ensureSignedIn() async {}

  @override
  Future<String> idToken({bool forceRefresh = false}) async => 'token';
}

/// The server: answers each (method, path) from [routes], records requests.
class FakeServer {
  final routes = <String, http.Response Function(Map<String, Object?> body)>{};
  final requests = <String>[];
  bool offline = false;

  void on(String method, String path, int status, Object body) =>
      routes['$method $path'] = (_) => http.Response(jsonEncode(body), status,
          headers: {'content-type': 'application/json; charset=utf-8'});

  http.Client get client => MockClient((req) async {
        final key = '${req.method} ${req.url.path.replaceFirst('/api/v1', '')}';
        requests.add(key);
        if (offline) throw http.ClientException('offline');
        final r = routes[key];
        if (r == null) return http.Response('{"error":{"code":"NOT_FOUND","message":"x"}}', 404);
        final body = req.body.isEmpty ? <String, Object?>{} : jsonDecode(req.body) as Map<String, Object?>;
        return r(body);
      });

  List<Override> overrides({String uid = 'uid-1'}) {
    final auth = FakeAuth(uid);
    return [
      authServiceProvider.overrideWithValue(auth),
      apiClientProvider.overrideWithValue(
        ApiClient(auth: auth, client: client, baseUrl: 'https://test/api/v1'),
      ),
    ];
  }
}

Map<String, Object?> profileJson({
  String name = 'Harpreet Kaur',
  String email = 'harpreet@example.com',
  bool verified = false,
  String cityId = 'new_delhi',
  String? pendingEmail,
}) =>
    {
      'profileId': 'p1',
      'name': name,
      'email': email,
      'phone': null,
      'cityId': cityId,
      'emailVerified': verified,
      'createdAt': '2026-10-08T00:00:00Z',
      'pendingEmail': pendingEmail,
    };

Map<String, Object?> errorJson(String code, [Map<String, Object?> extra = const {}]) =>
    {'error': {'code': code, 'message': code, ...extra}};

/// Unused import guard for tests that only need the type.
typedef Net = NetworkException;
