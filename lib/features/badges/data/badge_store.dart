import 'package:drift/drift.dart';

import '../../../core/db/user_db.dart';
import '../../goals/domain/goal_constants.dart';
import '../domain/badges.dart';

/// The counts of 12-badges §3.1 from `user.db`, and the `badges` table
/// (§4). Never a second record of practice: every count is read from the
/// Diary's own rows.
class BadgeStore {
  BadgeStore(this._db);

  final UserDb _db;

  /// Hazri, Nitnem and Simran days and the banis ever completed (EV3).
  /// [morningBanis] are the `default_slot` = `morning` banis of `content.db`.
  Future<BadgeCounts> counts({
    required Set<String> morningBanis,
    required Set<String> allBanis,
    int goalsReached = 0,
    int joins = 0,
  }) async {
    final completions = await (_db.select(_db.completions)..where((c) => c.deletedAt.isNull())).get();
    final sittings = await (_db.select(_db.simranSessions)
          ..where((s) => s.deletedAt.isNull() & s.durationS.isBiggerOrEqualValue(GoalConstants.hazriSimranMinSeconds)))
        .get();
    final byDay = <String, Set<String>>{};
    for (final c in completions) {
      byDay.putIfAbsent(c.localDate, () => {}).add(c.baniId);
    }
    final simranDays = {for (final s in sittings) s.localDate};
    return BadgeCounts(
      hazriDays: {...byDay.keys, ...simranDays}.length,
      nitnemDays: morningBanis.isEmpty
          ? 0
          : byDay.values.where((banis) => banis.containsAll(morningBanis)).length,
      simranDays: simranDays.length,
      banisCompleted: {for (final c in completions) c.baniId},
      allBanis: allBanis,
      goalsReached: goalsReached,
      joins: joins,
    );
  }

  Future<List<BadgeRow>> all() => _db.select(_db.badges).get();

  Stream<List<BadgeRow>> watchAll() => _db.select(_db.badges).watch();

  /// EV1: inserts a row for each of [ids] that has none, never updating or
  /// deleting one (NT1). [silent]: inserted already announced (LS2, BB4).
  Future<List<BadgeId>> insertNew(Set<BadgeId> ids, {required String today, bool silent = false}) async {
    final held = {for (final r in await all()) r.badgeId};
    final now = DateTime.now().toUtc();
    final added = <BadgeId>[];
    for (final b in BadgeId.values) {
      if (!ids.contains(b) || held.contains(b.id)) continue;
      await _db.into(_db.badges).insert(
            BadgesCompanion.insert(
              badgeId: b.id,
              earnedOn: today,
              announcedAt: Value(silent ? now : null),
              createdAt: now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      added.add(b);
    }
    return added;
  }

  /// AN2: the highest badge waiting to be announced, with every other
  /// waiting one marked announced; null when none waits.
  Future<BadgeId?> takeAnnouncement() => _db.transaction(() async {
        final waiting = await (_db.select(_db.badges)..where((b) => b.announcedAt.isNull())).get();
        if (waiting.isEmpty) return null;
        final ids = [for (final r in waiting) BadgeId.byId(r.badgeId)].whereType<BadgeId>().toList()
          ..sort((a, b) => a.index.compareTo(b.index));
        final now = DateTime.now().toUtc();
        await (_db.update(_db.badges)..where((b) => b.announcedAt.isNull()))
            .write(BadgesCompanion(announcedAt: Value(now), updatedAt: Value(now)));
        return ids.isEmpty ? null : ids.last;
      });

  /// BB3: a restored row is inserted when missing, or moves `earnedOn` to the
  /// earlier of the two; it is never announced.
  Future<int> mergeRestored(List<BadgeRow> rows) => _db.transaction(() async {
        var added = 0;
        final now = DateTime.now().toUtc();
        for (final r in rows) {
          final local = await (_db.select(_db.badges)..where((b) => b.badgeId.equals(r.badgeId))).getSingleOrNull();
          if (local == null) {
            await _db.into(_db.badges).insert(r.copyWith(announcedAt: Value(r.announcedAt ?? now)));
            added++;
          } else if (r.earnedOn.compareTo(local.earnedOn) < 0) {
            await (_db.update(_db.badges)..where((b) => b.badgeId.equals(r.badgeId)))
                .write(BadgesCompanion(earnedOn: Value(r.earnedOn), updatedAt: Value(now)));
          }
        }
        return added;
      });

  /// BB1: rows changed since the backup watermark.
  Future<List<BadgeRow>> changedSince(DateTime? since) => (_db.select(_db.badges)
        ..where((b) => since == null ? const Constant(true) : b.updatedAt.isBiggerOrEqualValue(since)))
      .get();
}
