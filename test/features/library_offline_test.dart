import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/backend/api_client.dart';
import 'package:hazri/core/backend/auth_service.dart';
import 'package:hazri/features/library/data/api_library_repository.dart';
import 'package:hazri/features/library/data/library_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeAuth implements AuthService {
  @override
  String? get uid => 'uid-1';

  @override
  Future<void> ensureSignedIn() async {}

  @override
  Future<String> idToken({bool forceRefresh = false}) async => 't';
}

String _body(List<String> titles) => jsonEncode({
      'entries': [
        for (final t in titles) {'id': t.toLowerCase(), 'title': t, 'kind': 'day'},
      ],
    });

/// docs/vichar-content.md, "On the phone": the last list is kept, opens
/// with the radio off, and is replaced by a fresh one behind it.
void main() {
  late int calls;
  late http.Response Function() answer;

  ApiLibraryRepository repo(LibraryStore store, {void Function()? onUpdated}) {
    calls = 0;
    return ApiLibraryRepository(
      ApiClient(
        auth: _FakeAuth(),
        client: MockClient((_) async {
          calls++;
          return answer();
        }),
        baseUrl: 'https://example.test/api/v1',
        timeout: const Duration(milliseconds: 200),
      ),
      store: store,
      onUpdated: onUpdated,
    );
  }

  http.Response offline() => throw const SocketException('no route');

  test('a fetched list is saved, and opens with no connection next time', () async {
    final store = MemoryLibraryStore();
    answer = () => http.Response(_body(['Vaisakhi', 'Maghi']), 200);
    expect((await repo(store).entries()).map((e) => e.title), ['Maghi', 'Vaisakhi']);
    expect(store.saved, isNotNull);

    answer = offline;
    final next = repo(store);
    expect((await next.entries()).map((e) => e.title), ['Maghi', 'Vaisakhi']);
  });

  test('with nothing saved and no connection the library is empty', () async {
    answer = offline;
    expect(await repo(MemoryLibraryStore()).entries(), isEmpty);
  });

  test('a saved list shows at once, and a different fresh one replaces it '
      'and is saved', () async {
    final store = MemoryLibraryStore(_body(['Maghi']));
    answer = () => http.Response(_body(['Maghi', 'Vaisakhi']), 200);
    var updated = 0;
    final r = repo(store, onUpdated: () => updated++);

    expect((await r.entries()).map((e) => e.title), ['Maghi']);
    await pumpEventQueue();
    expect(calls, 1);
    expect(updated, 1);
    expect((await r.entries()).map((e) => e.title), ['Maghi', 'Vaisakhi']);
    expect(store.saved, contains('Vaisakhi'));
  });

  test('a fresh list that matches the saved one does not redraw the screen',
      () async {
    final store = MemoryLibraryStore(_body(['Maghi']));
    answer = () => http.Response(_body(['Maghi']), 200);
    var updated = 0;
    final r = repo(store, onUpdated: () => updated++);
    await r.entries();
    await pumpEventQueue();
    expect(calls, 1);
    expect(updated, 0);
  });

  test('a server error keeps the saved list; it is fetched once per session',
      () async {
    final store = MemoryLibraryStore(_body(['Maghi']));
    answer = () => http.Response(jsonEncode({'error': {'code': 'INTERNAL'}}), 500);
    final r = repo(store);
    await r.entries();
    await pumpEventQueue();
    await r.entries();
    await r.entry('maghi');
    expect(calls, 1);
    expect(store.saved, _body(['Maghi']));
    expect((await r.entries()).single.title, 'Maghi');
  });

  test('an unreadable saved copy is ignored rather than shown', () async {
    answer = () => http.Response(_body(['Vaisakhi']), 200);
    expect((await repo(MemoryLibraryStore('{not json')).entries()).single.title, 'Vaisakhi');
  });
}
