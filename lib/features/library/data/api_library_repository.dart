import 'package:flutter/foundation.dart';

import '../../../core/backend/api_client.dart';
import '../../../core/backend/api_exception.dart';
import '../domain/library_entry.dart';
import 'library_repository.dart';

/// The library through the `api` Function (`GET /api/v1/vichar/entries`),
/// since no client reads Firestore any more (`01-accounts.md` §13.4).
///
/// Entries are fetched once and held for the session: they change when
/// somebody edits them, not while a person is reading, and a list that
/// re-fetched on every keystroke of the search box would be a bill for
/// nothing.
class ApiLibraryRepository implements LibraryRepository {
  ApiLibraryRepository(this._api);

  final ApiClient _api;
  List<LibraryEntry>? _cached;

  @override
  Future<List<LibraryEntry>> entries() async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final body = await _api.get('/vichar/entries');
      final raw = body['entries'];
      final list = <LibraryEntry>[
        if (raw is List)
          for (final e in raw)
            if (e is Map<String, Object?>) ?LibraryEntry.fromJson(e),
      ]..sort((a, b) => a.title.compareTo(b.title));
      _cached = list;
      return list;
    } on ApiException catch (e) {
      debugPrint('Hazri: library fetch failed ($e)');
      return const [];
    } on NetworkException catch (e) {
      debugPrint('Hazri: library fetch offline ($e)');
      return const [];
    }
  }

  @override
  Future<LibraryEntry?> entry(String id) async =>
      (await entries()).where((e) => e.id == id).firstOrNull;
}
