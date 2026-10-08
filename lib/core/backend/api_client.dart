import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import 'api_exception.dart';
import 'auth_service.dart';

/// The one way the app talks to the server: the `api` Cloud Function under
/// `/api/v1`, with the install's anonymous ID token (`01-accounts.md` §8.2,
/// ARCHITECTURE §6). No client reads or writes Firestore.
///
/// 1. Signs in if needed, then sends `Authorization: Bearer <token>` and
///    `Content-Type: application/json`, with a 15 s timeout.
/// 2. On 401, refreshes the token and retries once; a second 401 throws.
/// 3. 2xx returns the decoded JSON; anything else throws [ApiException].
/// 4. No answer at all throws [NetworkException]. No other retries.
class ApiClient {
  ApiClient({
    required AuthService auth,
    http.Client? client,
    String baseUrl = AppConfig.apiBaseUrl,
    Duration timeout = AppConfig.httpTimeout,
  })  : _auth = auth,
        _http = client ?? http.Client(),
        _base = baseUrl,
        _timeout = timeout;

  final AuthService _auth;
  final http.Client _http;
  final String _base;
  final Duration _timeout;

  Future<Map<String, Object?>> get(String path, {Map<String, String>? query}) =>
      request('GET', path, query: query);

  Future<Map<String, Object?>> post(String path, [Object? body]) =>
      request('POST', path, body: body);

  Future<Map<String, Object?>> patch(String path, [Object? body]) =>
      request('PATCH', path, body: body);

  Future<Map<String, Object?>> put(String path, [Object? body]) =>
      request('PUT', path, body: body);

  Future<Map<String, Object?>> delete(String path, [Object? body]) =>
      request('DELETE', path, body: body);

  Future<Map<String, Object?>> request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    var response = await _send(method, path, body, query, refresh: false);
    if (response.statusCode == 401) {
      response = await _send(method, path, body, query, refresh: true);
    }
    final decoded = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, Object?> ? decoded : const {};
    }
    throw ApiException.fromBody(response.statusCode, decoded);
  }

  Future<http.Response> _send(
    String method,
    String path,
    Object? body,
    Map<String, String>? query, {
    required bool refresh,
  }) async {
    final token = await _auth.idToken(forceRefresh: refresh);
    final uri = Uri.parse('$_base$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
    final req = http.Request(method, uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Content-Type'] = 'application/json';
    if (body != null) req.body = jsonEncode(body);
    try {
      final streamed = await _http.send(req).timeout(_timeout);
      return await http.Response.fromStream(streamed).timeout(_timeout);
    } on SocketException catch (e) {
      throw NetworkException(e);
    } on TimeoutException catch (e) {
      throw NetworkException(e);
    } on http.ClientException catch (e) {
      throw NetworkException(e);
    } on HandshakeException catch (e) {
      throw NetworkException(e);
    }
  }

  static Object? _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(auth: ref.watch(authServiceProvider)),
);
