import 'package:drift/drift.dart';

import '../../../core/db/user_db.dart';

/// The rows a backup sends and the merge a restore applies, on `user.db`
/// (10-backup §4.2, §4.3).
class BackupStore {
  BackupStore(this._db);

  final UserDb _db;

  /// BK6: every row whose `updatedAt` is at or after [since] (null: all),
  /// soft-deleted rows included. "At", not "after": drift keeps seconds, so a
  /// row written in the watermark's own second is sent again rather than
  /// missed (BK7); the server's merge makes a repeat harmless (BK8).
  Future<ChangedRows> changedSince(DateTime? since) async {
    Expression<bool> after(GeneratedColumn<DateTime> c) =>
        since == null ? const Constant(true) : c.isBiggerOrEqualValue(since);
    final items = await (_db.select(_db.goalItems)..where((i) => after(i.updatedAt))).get();
    final itemGoalIds = {for (final i in items) i.goalId};
    final goals = await (_db.select(_db.goals)
          ..where((g) => after(g.updatedAt) | g.id.isIn(itemGoalIds)))
        .get();
    return ChangedRows(
      goals: goals,
      items: items,
      completions: await (_db.select(_db.completions)..where((c) => after(c.updatedAt))).get(),
      sittings: await (_db.select(_db.simranSessions)..where((s) => after(s.updatedAt))).get(),
    );
  }

  /// RS3 + RS5 for the goals page. Returns the number of rows inserted.
  Future<int> mergeGoals(List<({Goal goal, List<GoalItem> items})> server) => _db.transaction(() async {
        var added = 0;
        final phoneActive =
            await (_db.select(_db.goals)..where((g) => g.completedOn.isNull())).getSingleOrNull();
        for (final entry in server) {
          var goal = entry.goal;
          var items = entry.items;
          // RS5: the phone's active goal stays active; a different active
          // goal from the server is stored as completed on its start date,
          // with its open items removed from that day.
          if (phoneActive != null && goal.completedOn == null && goal.id != phoneActive.id) {
            final cut = phoneActive.startDate;
            goal = goal.copyWith(completedOn: Value(cut));
            items = [
              for (final i in items)
                i.removedOn == null || i.removedOn!.compareTo(cut) > 0 ? i.copyWith(removedOn: Value(cut)) : i,
            ];
          }
          added += await _mergeRow(_db.goals, goal, goal.id, goal.updatedAt);
          for (final i in items) {
            added += await _mergeRow(_db.goalItems, i, i.id, i.updatedAt);
          }
        }
        return added;
      });

  /// RS3 for one page of weeks, in one transaction (RS7). Returns inserts.
  Future<int> mergeWeek(List<Completion> completions, List<SimranSession> sittings) =>
      _db.transaction(() async {
        var added = 0;
        for (final c in completions) {
          added += await _mergeRow(_db.completions, c, c.id, c.updatedAt);
        }
        for (final s in sittings) {
          added += await _mergeRow(_db.simranSessions, s, s.id, s.updatedAt);
        }
        return added;
      });

  /// RS3, one row: missing → inserted (soft-deleted ones too); present and
  /// the server's is newer → replaced; otherwise kept. 1 when inserted.
  Future<int> _mergeRow<T extends Table, D extends DataClass>(
    TableInfo<T, D> table,
    Insertable<D> row,
    String id,
    DateTime serverUpdatedAt,
  ) async {
    final idCol = table.columnsByName['id']! as GeneratedColumn<String>;
    final updCol = table.columnsByName['updated_at']! as GeneratedColumn<DateTime>;
    final local = await (_db.selectOnly(table)
          ..addColumns([updCol])
          ..where(idCol.equals(id)))
        .getSingleOrNull();
    if (local == null) {
      await _db.into(table).insert(row);
      return 1;
    }
    final localUpdated = local.read(updCol)!;
    if (serverUpdatedAt.isAfter(localUpdated)) {
      await _db.into(table).insertOnConflictUpdate(row);
    }
    return 0;
  }
}

/// What [BackupStore.changedSince] found.
class ChangedRows {
  const ChangedRows({
    required this.goals,
    required this.items,
    required this.completions,
    required this.sittings,
  });

  final List<Goal> goals;
  final List<GoalItem> items;
  final List<Completion> completions;
  final List<SimranSession> sittings;

  int get count => goals.length + items.length + completions.length + sittings.length;
  bool get isEmpty => count == 0;
}
