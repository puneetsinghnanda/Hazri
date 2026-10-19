import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/backend/api_client.dart';
import '../../../core/backend/api_exception.dart';
import '../domain/library_entry.dart';
import 'library_repository.dart';
import 'library_store.dart';

/// The library through the `api` Function (`GET /api/v1/vichar/entries`),
/// since no client reads Firestore any more (`01-accounts.md` §13.4), with
/// the last answer kept on the phone (`docs/vichar-content.md`, "On the
/// phone").
///
/// The first time the library is opened in a session:
/// - with a saved copy, that copy is shown at once, connection or not, and a
///   fresh one is fetched behind it; when it arrives it replaces the saved
///   copy and [onUpdated] tells the screen to show it;
/// - with none, the screen waits for the fetch, as it always did.
///
/// After that the session's list is held in memory: entries change when
/// somebody edits them, not while a person is reading, and a list that
/// re-fetched on every keystroke of the search box would be a bill for
/// nothing.
class ApiLibraryRepository implements LibraryRepository {
  ApiLibraryRepository(this._api, {LibraryStore? store, this.onUpdated})
      : _store = store ?? const FileLibraryStore();

  final ApiClient _api;
  final LibraryStore _store;

  /// Called when a fetch behind a saved copy brings a different list.
  final VoidCallback? onUpdated;

  List<LibraryEntry>? _cached;
  Future<List<LibraryEntry>>? _loading;

  @override
  Future<List<LibraryEntry>> entries() {
    final cached = _cached;
    if (cached != null) return Future.value(cached);
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<List<LibraryEntry>> _load() async {
    final saved = _parse(await _store.read());
    if (saved != null) {
      _cached = saved;
      unawaited(_refresh(saved));
      return saved;
    }
    final fresh = await _fetch();
    _cached = fresh;
    return fresh ?? const [];
  }

  /// The fetch behind a saved copy. A failure keeps the saved copy.
  Future<void> _refresh(List<LibraryEntry> saved) async {
    final fresh = await _fetch();
    if (fresh == null || _sameAs(fresh, saved)) return;
    _cached = fresh;
    onUpdated?.call();
  }

  /// The list from the server, saved for next time; null when it could not
  /// be had.
  Future<List<LibraryEntry>?> _fetch() async {
    try {
      final body = await _api.get('/vichar/entries');
      final list = _fromBody(body);
      await _store.write(jsonEncode({'entries': body['entries']}));
      return list;
    } on ApiException catch (e) {
      debugPrint('Hazri: library fetch failed ($e)');
      return null;
    } on NetworkException catch (e) {
      debugPrint('Hazri: library fetch offline ($e)');
      return null;
    }
  }

  static List<LibraryEntry>? _parse(String? json) {
    if (json == null) return null;
    try {
      final body = jsonDecode(json);
      return body is Map<String, Object?> ? _fromBody(body) : null;
    } on FormatException {
      return null;
    }
  }

  static List<LibraryEntry> _fromBody(Map<String, Object?> body) {
    final raw = body['entries'];
    return <LibraryEntry>[
      if (raw is List)
        for (final e in raw)
          if (e is Map<String, Object?>) ?LibraryEntry.fromJson(e),
    ]..sort((a, b) => a.title.compareTo(b.title));
  }

  /// Whether two lists would show the same thing. Entries compare by id, so
  /// an edited body would look unchanged by `==`; the comparison is made on
  /// what is shown.
  static bool _sameAs(List<LibraryEntry> a, List<LibraryEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x.id != y.id || x.title != y.title || x.summary != y.summary ||
          x.body != y.body || x.kind != y.kind || !setEquals(x.tags, y.tags) ||
          !listEquals(x.dates, y.dates) || !mapEquals(x.facts, y.facts) ||
          x.minutes != y.minutes || x.place != y.place) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<LibraryEntry?> entry(String id) async =>
      (await entries()).where((e) => e.id == id).firstOrNull;
}
