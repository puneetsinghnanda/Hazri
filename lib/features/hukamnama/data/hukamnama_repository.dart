import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/time/clock.dart';
import '../domain/hukamnama.dart';

/// Swap this override in when a permitted provider is configured.
final hukamnamaSourceProvider = Provider<HukamnamaSource>(
  (ref) => const UnconfiguredHukamnamaSource(),
);

final hukamnamaRepositoryProvider = Provider<HukamnamaRepository>(
  (ref) => HukamnamaRepository(
    ref.watch(userDbProvider),
    ref.watch(hukamnamaSourceProvider),
    ref.watch(clockProvider),
  ),
);

/// Today's Hukamnama, or the most recent one still cached.
final todayHukamnamaProvider = FutureProvider<Hukamnama?>(
  (ref) => ref.watch(hukamnamaRepositoryProvider).todayOrLatest(),
);

/// Fetches, caches for 30 days, and serves the newest available Hukamnama.
class HukamnamaRepository {
  HukamnamaRepository(this._db, this._source, this._clock);

  final UserDb _db;
  final HukamnamaSource _source;
  final Clock _clock;

  bool get isConfigured => _source.isConfigured;

  String? get sourceName => _source.name;

  /// The newest cached Hukamnama, refreshing first if the cache is stale.
  ///
  /// Diaspora users simply see the latest available one with its own date
  /// (PRD 1.11).
  Future<Hukamnama?> todayOrLatest() async {
    if (_source.isConfigured) await refreshIfStale();
    final row = await (_db.select(_db.hukamnamaCache)
          ..orderBy([(h) => OrderingTerm.desc(h.date)])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : Hukamnama.tryDecode(row.payloadJson);
  }

  /// Fetches today's Hukamnama if the cache does not already hold it.
  Future<void> refreshIfStale() async {
    if (!_source.isConfigured) return;
    final today = _clock.today();
    final key = localDateKey(today);
    final existing = await (_db.select(_db.hukamnamaCache)
          ..where((h) => h.date.equals(key)))
        .getSingleOrNull();
    if (existing != null) return;

    final fetched = await _source.fetch(today);
    if (fetched == null) return;
    await _db.into(_db.hukamnamaCache).insertOnConflictUpdate(
          HukamnamaCacheCompanion.insert(
            date: key,
            payloadJson: fetched.toJsonString(),
            source: _source.name ?? 'unknown',
            fetchedAt: DateTime.now().toUtc(),
          ),
        );
    await _pruneOlderThan(today.subtract(const Duration(days: 30)));
  }

  Future<void> _pruneOlderThan(DateTime cutoff) =>
      (_db.delete(_db.hukamnamaCache)
            ..where((h) => h.date.isSmallerThanValue(localDateKey(cutoff))))
          .go();
}
