import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/diary/domain/streak.dart';
import '../../features/goals/domain/day_verdict.dart';
import '../../features/goals/domain/goal_constants.dart';
import '../time/clock.dart';
import 'user_db.dart';

/// Set during bootstrap in `main.dart`.
final userDbProvider = Provider<UserDb>(
  (ref) => throw UnimplementedError('UserDb must be overridden at startup'),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(userDbProvider), ref.watch(clockProvider)),
);

/// What a new goal item asks for (04-goals §5.3, design 47).
@immutable
class GoalItemSpec {
  const GoalItemSpec({
    required this.itemType,
    this.baniId,
    this.timesPerDay = 1,
    this.simranMinutes,
    this.durationType = DurationType.everyDay,
    this.durationDays,
    this.untilDate,
    this.reminderTime,
  });

  const GoalItemSpec.bani(
    String this.baniId, {
    this.timesPerDay = 1,
    this.durationType = DurationType.everyDay,
    this.durationDays,
    this.untilDate,
    this.reminderTime,
  })  : itemType = ItemType.bani,
        simranMinutes = null;

  const GoalItemSpec.simran(
    int this.simranMinutes, {
    this.durationType = DurationType.everyDay,
    this.durationDays,
    this.untilDate,
    this.reminderTime,
  })  : itemType = ItemType.simran,
        baniId = null,
        timesPerDay = 1;

  final ItemType itemType;
  final String? baniId;
  final int timesPerDay;
  final int? simranMinutes;
  final DurationType durationType;
  final int? durationDays;

  /// `YYYY-MM-DD`, for [DurationType.untilDate].
  final String? untilDate;

  /// `HH:mm`, or null for no reminder.
  final String? reminderTime;
}

/// A day's live rows, which [verdictOn] judges.
@immutable
class DayRows {
  const DayRows({
    required this.day,
    required this.items,
    required this.completions,
    required this.sittings,
  });

  final String day;

  /// Every goal item ever made; [verdictOn] picks those in scope.
  final List<GoalItem> items;
  final List<Completion> completions;
  final List<SimranSession> sittings;

  DayVerdict get verdict => verdictOn(day, items, completions, sittings);

  List<GoalItem> get itemsInScope => [for (final i in items) if (inScope(i, day)) i];
}

/// Thrown by the goal operations when a rule refuses the change.
class GoalRuleException implements Exception {
  const GoalRuleException(this.rule);

  /// The rule that refused it, e.g. `GI6` for an end date in the past.
  final String rule;

  @override
  String toString() => 'GoalRuleException($rule)';
}

/// Everything written to `user.db`: reading position, completions, sittings,
/// goals, grace days and the calendar's per-event bells.
///
/// Every write runs in one transaction and sets `updatedAt` (04-goals §5.7).
/// [onChanged] is called after each write that can change what a reminder
/// should say, so the notification plan follows (RM3).
class UserRepository {
  UserRepository(this._db, this._clock);

  final UserDb _db;
  final Clock _clock;

  /// Re-plans notifications. Set by the scheduler at start-up.
  VoidCallback? onChanged;

  static final _rand = math.Random.secure();

  /// A UUID v4, so rows stay merge-safe for the backup (04-goals §5.1).
  static String newId() {
    final b = List<int>.generate(16, (_) => _rand.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String h(int from, int to) =>
        b.sublist(from, to).map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h(0, 4)}-${h(4, 6)}-${h(6, 8)}-${h(8, 10)}-${h(10, 16)}';
  }

  DateTime get _nowUtc => _clock.now().toUtc();
  String get _today => localDateKey(_clock.today());

  void _changed() {
    onChanged?.call();
    for (final l in _listeners) {
      l();
    }
  }

  final _listeners = <void Function()>[];

  /// Called after every completion, sitting, Diary edit and goal change, as
  /// [onChanged] is; for the badges (12-badges EV2).
  void addChangeListener(void Function() listener) => _listeners.add(listener);

  /// 08-sangat §5.1: queue every paath and sitting, and every undo, for the
  /// Sangat. Set while the person belongs to at least one active group;
  /// otherwise nothing is queued.
  bool queueForSangat = false;

  /// Called after a row is queued, so the sender can go at once.
  void Function()? onOutbox;

  Future<void> _queue({
    required String id,
    required String kind,
    String? baniId,
    int? durationS,
    required String source,
    required DateTime at,
    required bool retract,
  }) async {
    if (!queueForSangat) return;
    await _db.into(_db.sangatOutbox).insertOnConflictUpdate(SangatOutboxCompanion.insert(
          id: id,
          kind: kind,
          baniId: Value(baniId),
          durationS: Value(durationS),
          source: source,
          at: at,
          retracted: Value(retract),
          createdAt: _nowUtc,
        ));
    onOutbox?.call();
  }

  /// The queue, oldest first, for the sender.
  Future<List<OutboxRow>> outbox({int limit = 200}) => (_db.select(_db.sangatOutbox)
        ..orderBy([(o) => OrderingTerm(expression: o.createdAt)])
        ..limit(limit))
      .get();

  /// Rows the server confirmed.
  Future<void> clearOutbox(Iterable<OutboxRow> rows) => _db.batch((b) {
        for (final r in rows) {
          b.deleteWhere(_db.sangatOutbox, ($SangatOutboxTable o) => o.id.equals(r.id) & o.retracted.equals(r.retracted));
        }
      });

  // ---------------------------------------------------------------- progress

  Future<ReadingProgressData?> progressFor(String baniVersionId) =>
      (_db.select(_db.readingProgress)
            ..where((p) => p.baniVersionId.equals(baniVersionId)))
          .getSingleOrNull();

  Stream<List<ReadingProgressData>> watchAllProgress() =>
      _db.select(_db.readingProgress).watch();

  Future<void> saveProgress(String baniVersionId, int lineIdx, {int audioPosMs = 0}) =>
      _db.into(_db.readingProgress).insertOnConflictUpdate(
            ReadingProgressCompanion.insert(
              baniVersionId: baniVersionId,
              lineIdx: Value(lineIdx),
              audioPosMs: Value(audioPosMs),
              updatedAt: _nowUtc,
            ),
          );

  Future<void> clearProgress(String baniVersionId) =>
      (_db.delete(_db.readingProgress)..where((p) => p.baniVersionId.equals(baniVersionId)))
          .go();

  // ------------------------------------------------------------- completions

  /// Every live completion, for the badge and streak counts.
  Future<List<Completion>> allCompletions() =>
      (_db.select(_db.completions)..where((c) => c.deletedAt.isNull())).get();

  Stream<List<Completion>> watchCompletions() =>
      (_db.select(_db.completions)..where((c) => c.deletedAt.isNull())).watch();

  Stream<List<Completion>> watchCompletionsOn(DateTime date) {
    final key = localDateKey(date);
    return (_db.select(_db.completions)
          ..where((c) => c.localDate.equals(key) & c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.completedAt)]))
        .watch();
  }

  Future<List<Completion>> completionsOn(DateTime date) {
    final key = localDateKey(date);
    return (_db.select(_db.completions)
          ..where((c) => c.localDate.equals(key) & c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.completedAt)]))
        .get();
  }

  /// Records one recitation (CR1–CR3). Every paath is its own row (CR5); the
  /// reader and the player make sure one opening logs at most one (CR2).
  ///
  /// The caller is `completeBani` (06-nitnem B1) or the Diary's +, and
  /// nothing else.
  Future<Completion> logCompletion({
    required String baniId,
    required BaniSlotValue slot,
    required CompletionSource source,
    DateTime? on,
  }) async {
    final now = _nowUtc;
    final row = CompletionsCompanion.insert(
      id: newId(),
      localDate: localDateKey(on ?? _clock.today()),
      baniId: baniId,
      slot: slot,
      source: source,
      completedAt: now,
      updatedAt: now,
    );
    final saved = await _db.into(_db.completions).insertReturning(row);
    await _queue(
      id: saved.id,
      kind: 'BANI',
      baniId: baniId,
      source: UpperSnake.encode(source),
      at: saved.completedAt,
      retract: false,
    );
    _changed();
    return saved;
  }

  /// Diary −: soft-deletes the newest live completion of [baniId] on [day],
  /// whatever its source (CR3). Returns it, or null when there was none.
  Future<Completion?> undoLatestCompletion(String baniId, DateTime day) async {
    final key = localDateKey(day);
    final row = await (_db.select(_db.completions)
          ..where((c) =>
              c.localDate.equals(key) & c.baniId.equals(baniId) & c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.completedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    final now = _nowUtc;
    await (_db.update(_db.completions)..where((c) => c.id.equals(row.id)))
        .write(CompletionsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    // CT5: taken back from every group it counted in.
    await _queue(
      id: row.id,
      kind: 'BANI',
      baniId: row.baniId,
      source: UpperSnake.encode(row.source),
      at: row.completedAt,
      retract: true,
    );
    _changed();
    return row;
  }

  // ------------------------------------------------------------------ simran

  Stream<List<SimranSession>> watchSimranSessions() =>
      (_db.select(_db.simranSessions)..where((s) => s.deletedAt.isNull())).watch();

  Future<List<SimranSession>> allSittings() =>
      (_db.select(_db.simranSessions)..where((s) => s.deletedAt.isNull())).get();

  Stream<List<SimranSession>> watchSittings() =>
      (_db.select(_db.simranSessions)..where((s) => s.deletedAt.isNull())).watch();

  Stream<List<SimranSession>> watchSittingsOn(DateTime date) {
    final key = localDateKey(date);
    return (_db.select(_db.simranSessions)
          ..where((s) => s.localDate.equals(key) & s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm(expression: s.startedAt)]))
        .watch();
  }

  /// Records one sitting with its actual length (HZ4, CR4). A sitting under
  /// 300 s is stored and marks nothing (HZ3).
  Future<SimranSession> logSitting({
    required Duration duration,
    required bool completed,
    required SittingSource source,
    int count = 0,
    DateTime? on,
  }) async {
    final now = _nowUtc;
    final saved = await _db.into(_db.simranSessions).insertReturning(
          SimranSessionsCompanion.insert(
            id: newId(),
            localDate: localDateKey(on ?? _clock.today()),
            startedAt: now.subtract(duration),
            durationS: duration.inSeconds,
            count: Value(count),
            completed: Value(completed),
            source: source,
            updatedAt: now,
          ),
        );
    await _queue(
      id: saved.id,
      kind: 'SIMRAN',
      durationS: saved.durationS,
      source: UpperSnake.encode(source),
      at: saved.startedAt,
      retract: false,
    );
    _changed();
    return saved;
  }

  /// Diary − for Naam Simran: soft-deletes the day's newest live sitting (CR4).
  Future<SimranSession?> undoLatestSitting(DateTime day) async {
    final key = localDateKey(day);
    final row = await (_db.select(_db.simranSessions)
          ..where((s) => s.localDate.equals(key) & s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm(expression: s.startedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    final now = _nowUtc;
    await (_db.update(_db.simranSessions)..where((s) => s.id.equals(row.id)))
        .write(SimranSessionsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    await _queue(
      id: row.id,
      kind: 'SIMRAN',
      durationS: row.durationS,
      source: UpperSnake.encode(row.source),
      at: row.startedAt,
      retract: true,
    );
    _changed();
    return row;
  }

  // ------------------------------------------------------------------- goals

  /// The active goal (`completedOn` null), or null (GL3).
  Future<Goal?> activeGoal() =>
      (_db.select(_db.goals)..where((g) => g.completedOn.isNull())).getSingleOrNull();

  Stream<Goal?> watchActiveGoal() =>
      (_db.select(_db.goals)..where((g) => g.completedOn.isNull())).watchSingleOrNull();

  /// Whether any goal was ever made: decides the Set Goal card's subtitle
  /// (04-goals §7.1).
  Stream<bool> watchHadGoal() => _db.select(_db.goals).watch().map((g) => g.isNotEmpty);

  /// Every item of every goal, in creation order. Past days are judged by the
  /// items that covered them, so history needs them all.
  Stream<List<GoalItem>> watchAllItems() =>
      (_db.select(_db.goalItems)..orderBy([(i) => OrderingTerm(expression: i.createdAt)]))
          .watch();

  Future<List<GoalItem>> allItems() =>
      (_db.select(_db.goalItems)..orderBy([(i) => OrderingTerm(expression: i.createdAt)]))
          .get();

  Future<GoalItem?> item(String id) =>
      (_db.select(_db.goalItems)..where((i) => i.id.equals(id))).getSingleOrNull();

  /// The items of the active goal in scope today, in creation order (§7.3).
  Future<List<GoalItem>> itemsInScopeToday() async {
    final goal = await activeGoal();
    if (goal == null) return const [];
    final items = await (_db.select(_db.goalItems)
          ..where((i) => i.goalId.equals(goal.id))
          ..orderBy([(i) => OrderingTerm(expression: i.createdAt)]))
        .get();
    return [for (final i in items) if (inScope(i, _today)) i];
  }

  /// The item for [baniId] (or Naam Simran when null) in scope today (GI1).
  Future<GoalItem?> inScopeItemFor({String? baniId, required ItemType type}) async {
    final items = await itemsInScopeToday();
    return items
        .where((i) => i.itemType == type && (type == ItemType.simran || i.baniId == baniId))
        .firstOrNull;
  }

  /// Adds an item, creating the goal if none is active (GL2, GI1, GI2, GI4).
  /// Throws [GoalRuleException] `GI1` when the bani already has an item in
  /// scope: the caller opens that item for editing instead.
  Future<GoalItem> addItem(GoalItemSpec spec) async {
    _validate(spec);
    final result = await _db.transaction(() async {
      final existing = await inScopeItemFor(baniId: spec.baniId, type: spec.itemType);
      if (existing != null) throw const GoalRuleException('GI1');
      final now = _nowUtc;
      final goal = await activeGoal() ??
          await _db.into(_db.goals).insertReturning(GoalsCompanion.insert(
            id: newId(),
            startDate: _today,
            createdAt: now,
            updatedAt: now,
          ));
      final id = newId();
      return _db.into(_db.goalItems).insertReturning(GoalItemsCompanion.insert(
            id: id,
            goalId: goal.id,
            seriesId: id,
            itemType: spec.itemType,
            baniId: Value(spec.itemType == ItemType.bani ? spec.baniId : null),
            timesPerDay: spec.itemType == ItemType.simran ? 1 : spec.timesPerDay,
            simranMinutes: Value(spec.itemType == ItemType.simran ? spec.simranMinutes : null),
            durationType: spec.durationType,
            durationDays: Value(spec.durationType == DurationType.days ? spec.durationDays : null),
            startDate: _today,
            endDate: Value(endDateFor(
              type: spec.durationType,
              seriesStart: _today,
              durationDays: spec.durationDays,
              untilDate: spec.untilDate,
            )),
            // RM1: always on; a spec with no time takes the item's own.
            reminderTime: Value(spec.reminderTime ??
                GoalConstants.reminderFor(baniId: spec.baniId, simran: spec.itemType == ItemType.simran)),
            createdAt: now,
            updatedAt: now,
          ));
    });
    _changed();
    return result;
  }

  /// GI10 and RM1 for goals made before 2026-10-19: an item in scope read
  /// more than once a day becomes once a day (through [editTarget], so past
  /// days keep their verdict), and one with no reminder gets its own time.
  /// Run at start and after a restore; a second run changes nothing.
  Future<void> normaliseGoalItems() async {
    for (final i in await itemsInScopeToday()) {
      if (i.reminderTime == null) {
        await editReminder(
            i.id, GoalConstants.reminderFor(baniId: i.baniId, simran: i.itemType == ItemType.simran));
      }
      if (i.itemType == ItemType.bani && i.timesPerDay != 1) await editTarget(i.id, timesPerDay: 1);
    }
  }

  void _validate(GoalItemSpec spec) {
    if (spec.itemType == ItemType.bani) {
      if (spec.baniId == null) throw const GoalRuleException('GI1');
      if (spec.timesPerDay < 1 || spec.timesPerDay > 11) throw const GoalRuleException('G3');
    } else {
      final m = spec.simranMinutes ?? 0;
      if (m < 5 || m > 120) throw const GoalRuleException('GI5');
    }
    if (spec.durationType == DurationType.days) {
      final d = spec.durationDays ?? 0;
      if (d < 1 || d > 365) throw const GoalRuleException('GI4');
    }
    if (spec.durationType == DurationType.untilDate) {
      final u = spec.untilDate;
      if (u == null || u.compareTo(_today) < 0) throw const GoalRuleException('GI4');
      final max = localDateKey(_clock.today().add(const Duration(days: 365)));
      if (u.compareTo(max) > 0) throw const GoalRuleException('GI4');
    }
  }

  /// Reminder only: updated in place (GI6). There is no "off" (RM1).
  Future<void> editReminder(String itemId, String time) async {
    await (_db.update(_db.goalItems)..where((i) => i.id.equals(itemId))).write(
      GoalItemsCompanion(reminderTime: Value(time), updatedAt: Value(_nowUtc)),
    );
    _changed();
  }

  /// Duration: updated in place; the new end date must be today or later
  /// (GI6, scenario E-7).
  Future<void> editDuration(
    String itemId, {
    required DurationType type,
    int? durationDays,
    String? untilDate,
  }) async {
    await _db.transaction(() async {
      final row = await item(itemId);
      if (row == null) return;
      final seriesStart = await _seriesStart(row.seriesId);
      final end = endDateFor(
        type: type,
        seriesStart: seriesStart,
        durationDays: durationDays,
        untilDate: untilDate,
      );
      if (end != null && end.compareTo(_today) < 0) throw const GoalRuleException('GI6');
      await (_db.update(_db.goalItems)..where((i) => i.id.equals(itemId))).write(
        GoalItemsCompanion(
          durationType: Value(type),
          durationDays: Value(type == DurationType.days ? durationDays : null),
          endDate: Value(end),
          updatedAt: Value(_nowUtc),
        ),
      );
    });
    _changed();
  }

  Future<String> _seriesStart(String seriesId) async {
    final rows = await (_db.select(_db.goalItems)..where((i) => i.seriesId.equals(seriesId))).get();
    return rows.map((r) => r.startDate).reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
  }

  /// Target (`timesPerDay` or `simranMinutes`): the old row ends today and a
  /// new row in the same series starts today, unless the old row started
  /// today, in which case it is updated in place (GI6).
  Future<GoalItem?> editTarget(String itemId, {int? timesPerDay, int? simranMinutes}) async {
    final result = await _db.transaction(() async {
      final row = await item(itemId);
      if (row == null) return null;
      final now = _nowUtc;
      if (row.startDate == _today) {
        await (_db.update(_db.goalItems)..where((i) => i.id.equals(itemId))).write(
          GoalItemsCompanion(
            timesPerDay: Value(timesPerDay ?? row.timesPerDay),
            simranMinutes: Value(simranMinutes ?? row.simranMinutes),
            updatedAt: Value(now),
          ),
        );
        return item(itemId);
      }
      await (_db.update(_db.goalItems)..where((i) => i.id.equals(itemId)))
          .write(GoalItemsCompanion(removedOn: Value(_today), updatedAt: Value(now)));
      return _db.into(_db.goalItems).insertReturning(GoalItemsCompanion.insert(
            id: newId(),
            goalId: row.goalId,
            seriesId: row.seriesId,
            itemType: row.itemType,
            baniId: Value(row.baniId),
            timesPerDay: timesPerDay ?? row.timesPerDay,
            simranMinutes: Value(simranMinutes ?? row.simranMinutes),
            durationType: row.durationType,
            durationDays: Value(row.durationDays),
            startDate: _today,
            endDate: Value(row.endDate),
            reminderTime: Value(row.reminderTime),
            createdAt: now,
            updatedAt: now,
          ));
    });
    _changed();
    return result;
  }

  /// Remove (GI7): out of scope from today, history kept. Then BG1.
  Future<void> removeItem(String itemId) async {
    await _db.transaction(() async {
      final row = await item(itemId);
      if (row == null) return;
      await (_db.update(_db.goalItems)..where((i) => i.id.equals(itemId)))
          .write(GoalItemsCompanion(removedOn: Value(_today), updatedAt: Value(_nowUtc)));
      await _closeIfBlank(row.goalId);
    });
    _changed();
  }

  /// BG2: completes the active goal when nothing is in scope today and
  /// nothing starts later. Run at app start, on resume and at the day change.
  Future<void> closeGoalIfBlank() async {
    final goal = await activeGoal();
    if (goal == null) return;
    final closed = await _db.transaction(() => _closeIfBlank(goal.id));
    if (closed) _changed();
  }

  /// Completes the goal when it is blank: no item in scope today and none
  /// starting later (§2). Removed today → completed today (BG1); ended by
  /// duration → the day after the latest last day (BG2).
  Future<bool> _closeIfBlank(String goalId) async {
    final items = await (_db.select(_db.goalItems)..where((i) => i.goalId.equals(goalId))).get();
    final today = _today;
    final blank = !items.any((i) => inScope(i, today) || i.startDate.compareTo(today) > 0);
    if (!blank) return false;
    String? latestLast;
    for (final i in items) {
      final last = lastDayOf(i);
      if (last != null && (latestLast == null || last.compareTo(latestLast) > 0)) {
        latestLast = last;
      }
    }
    var completedOn = today;
    if (latestLast != null) {
      final after = localDateKey(parseLocalDateKey(latestLast).add(const Duration(days: 1)));
      if (after.compareTo(today) < 0) completedOn = after;
    }
    await (_db.update(_db.goals)..where((g) => g.id.equals(goalId)))
        .write(GoalsCompanion(completedOn: Value(completedOn), updatedAt: Value(_nowUtc)));
    return true;
  }

  /// GI9: an item whose bani is not in `content.db` leaves scope today.
  Future<void> removeItemsWithUnknownBanis(Set<String> knownBaniIds) async {
    for (final i in await itemsInScopeToday()) {
      if (i.itemType == ItemType.bani && !knownBaniIds.contains(i.baniId)) {
        debugPrint('Hazri: goal item ${i.id} names unknown bani ${i.baniId}; removed (GI9)');
        await removeItem(i.id);
      }
    }
  }

  // ---------------------------------------------------------------- verdicts

  /// One day's rows, live, for [verdictOn] (04-goals §5.7 watchDay).
  Stream<DayRows> watchDay(DateTime date) {
    final key = localDateKey(date);
    final query = _db.select(_db.goalItems).watch();
    // Re-read on any change to any of the three tables.
    return _merge3(
      query,
      watchCompletionsOn(date),
      watchSittingsOn(date),
      (items, completions, sittings) => DayRows(
        day: key,
        items: items,
        completions: completions,
        sittings: sittings,
      ),
    );
  }

  Future<DayRows> dayRows(DateTime date) async => DayRows(
        day: localDateKey(date),
        items: await allItems(),
        completions: await completionsOn(date),
        sittings: await (_db.select(_db.simranSessions)
              ..where((s) => s.localDate.equals(localDateKey(date)) & s.deletedAt.isNull()))
            .get(),
      );

  /// The rows of a month, live, for the Diary grid (04-goals §7.4).
  Stream<MonthRows> watchMonth(DateTime month) {
    final from = localDateKey(DateTime(month.year, month.month, 1));
    final to = localDateKey(DateTime(month.year, month.month + 1, 0));
    final completions = (_db.select(_db.completions)
          ..where((c) =>
              c.localDate.isBiggerOrEqualValue(from) &
              c.localDate.isSmallerOrEqualValue(to) &
              c.deletedAt.isNull()))
        .watch();
    final sittings = (_db.select(_db.simranSessions)
          ..where((s) =>
              s.localDate.isBiggerOrEqualValue(from) &
              s.localDate.isSmallerOrEqualValue(to) &
              s.deletedAt.isNull()))
        .watch();
    return _merge3(
      watchAllItems(),
      completions,
      sittings,
      (items, c, s) => MonthRows(month: DateTime(month.year, month.month), items: items, completions: c, sittings: s),
    );
  }

  /// DV3: the earliest day anything was recorded, or null with no rows.
  Future<String?> firstRecordedDay() async {
    final rows = await _db.customSelect('''
      SELECT MIN(d) AS d FROM (
        SELECT MIN(local_date) AS d FROM completions WHERE deleted_at IS NULL
        UNION ALL SELECT MIN(local_date) FROM simran_sessions WHERE deleted_at IS NULL
        UNION ALL SELECT MIN(start_date) FROM goals)''').getSingle();
    return rows.readNullable<String>('d');
  }

  // ------------------------------------------------------------------ streak

  /// `hazriStreak(today)`: the run of hazri days now and the longest
  /// (09-diary D12), persisting any grace days the current run spends (D8).
  ///
  /// A hazri day is any paath or 5 minutes of Naam Simran (`hazriFrom`), so
  /// Ardas, Sukhmani Sahib and a sitting count; before 2026-10-10 only a
  /// Nitnem bani did (D9).
  Future<HazriStreak> hazriStreak() async {
    final completions = await allCompletions();
    final sittings = await allSittings();
    final hazriDays = <String>{
      for (final c in completions) c.localDate,
      for (final s in sittings)
        if (s.durationS >= GoalConstants.hazriSimranMinSeconds) s.localDate,
    };
    final grace = await _db.select(_db.graceDays).get();
    final result = StreakCalculator.compute(
      countedDays: hazriDays,
      existingGraceDays: {for (final g in grace) g.localDate},
      today: _clock.today(),
    );
    for (final d in result.graceUsed) {
      await _db.into(_db.graceDays).insertOnConflictUpdate(
            GraceDaysCompanion.insert(localDate: localDateKey(d), monthKey: monthKey(d)),
          );
    }
    final allGrace = {
      for (final g in grace) g.localDate,
      for (final d in result.graceUsed) localDateKey(d),
    };
    final longest = StreakCalculator.longest(countedDays: hazriDays, graceDays: allGrace);
    return HazriStreak(
      current: result.days,
      longest: math.max(longest, result.days),
      days: {...hazriDays},
    );
  }

  /// Every grace day spent, for the month grid's label (09-diary Y-j).
  Future<Set<String>> graceDayKeys() async =>
      {for (final g in await _db.select(_db.graceDays).get()) g.localDate};

  // -------------------------------------------------------- event overrides

  Future<Map<String, bool>> eventOverrides() async {
    final rows = await _db.select(_db.eventReminderOverrides).get();
    return {for (final r in rows) r.eventId: r.enabled};
  }

  Future<void> setEventOverride(String eventId, bool enabled) async {
    await _db.into(_db.eventReminderOverrides).insertOnConflictUpdate(
          EventReminderOverridesCompanion.insert(eventId: eventId, enabled: enabled),
        );
    _changed();
  }
}

/// A month's live rows, for the Diary grid.
@immutable
class MonthRows {
  const MonthRows({
    required this.month,
    required this.items,
    required this.completions,
    required this.sittings,
  });

  final DateTime month;
  final List<GoalItem> items;
  final List<Completion> completions;
  final List<SimranSession> sittings;

  DayVerdict verdict(DateTime day) =>
      verdictOn(localDateKey(day), items, completions, sittings);

  /// Whether any day of the month had a goal: decides the legend's goal entry
  /// (04-goals §7.4).
  bool get anyGoalDay {
    final last = DateTime(month.year, month.month + 1, 0).day;
    for (var d = 1; d <= last; d++) {
      final key = localDateKey(DateTime(month.year, month.month, d));
      if (items.any((i) => inScope(i, key))) return true;
    }
    return false;
  }
}

/// The two numbers of the streak cards (05-today T12, 09-diary D12).
@immutable
class HazriStreak {
  const HazriStreak({required this.current, required this.longest, this.days = const {}});

  static const zero = HazriStreak(current: 0, longest: 0);

  final int current;
  final int longest;

  /// Every hazri day, so the week strip can light its dots.
  final Set<String> days;
}

/// Combines three streams, emitting once all three have a value.
Stream<R> _merge3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A, B, C) combine,
) {
  late StreamController<R> out;
  A? va;
  B? vb;
  C? vc;
  var ha = false, hb = false, hc = false;
  final subs = <StreamSubscription<Object?>>[];
  void emit() {
    if (ha && hb && hc) out.add(combine(va as A, vb as B, vc as C));
  }

  out = StreamController<R>(
    onListen: () {
      subs
        ..add(a.listen((v) {
          va = v;
          ha = true;
          emit();
        }, onError: out.addError))
        ..add(b.listen((v) {
          vb = v;
          hb = true;
          emit();
        }, onError: out.addError))
        ..add(c.listen((v) {
          vc = v;
          hc = true;
          emit();
        }, onError: out.addError));
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
    },
  );
  return out.stream;
}
