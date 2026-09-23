import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/diary/domain/streak.dart';
import '../../features/goals/domain/goal_progress.dart';
import '../time/clock.dart';
import 'user_db.dart';

/// Set during bootstrap in `main.dart`.
final userDbProvider = Provider<UserDb>(
  (ref) => throw UnimplementedError('UserDb must be overridden at startup'),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(userDbProvider), ref.watch(clockProvider)),
);

/// One day's worth of diary marks.
class DiaryDay {
  DiaryDay({
    required this.date,
    required this.slots,
    required this.isGrace,
    required this.simran,
    this.goals = GoalDay.none,
  });

  final DateTime date;
  final Set<BaniSlotValue> slots;
  final bool isGrace;
  final bool simran;

  /// What the day's goals came to: how many it asked for, how many were met.
  ///
  /// The count matters as much as the verdict. A day with no goals is not a
  /// day anybody failed, so the diary draws one dot on it rather than a grey
  /// second one — the difference between "nothing was asked" and "something
  /// was asked and missed".
  final GoalDay goals;

  /// Whether the day had goals at all. The diary's second dot exists only
  /// when this is true.
  bool get hasGoals => goals.hasGoals;

  /// Every goal the day asked for was met on it. The second dot, lit.
  bool get goalsMet => goals.allMet;

  bool get isNitnemDay => slots.isNotEmpty;

  /// Whether somebody turned up at all: one paath, or one sitting of simran.
  ///
  /// The diary's first dot. It is deliberately a lower bar than [goalsMet] —
  /// hazri is being present, not finishing the list.
  bool get hazri => slots.isNotEmpty || simran;
}

/// Everything written to `user.db`: progress, completions, goals, Simran,
/// reminders and grace days.
class UserRepository {
  UserRepository(this._db, this._clock);

  final UserDb _db;
  final Clock _clock;

  static final _rand = math.Random.secure();

  /// A UUID v4, so rows stay merge-safe if sync is added later (PRD §17.1).
  static String newId() {
    final b = List<int>.generate(16, (_) => _rand.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String h(int from, int to) =>
        b.sublist(from, to).map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h(0, 4)}-${h(4, 6)}-${h(6, 8)}-${h(8, 10)}-${h(10, 16)}';
  }

  // ---------------------------------------------------------------- progress

  Future<ReadingProgressData?> progressFor(String baniVersionId) =>
      (_db.select(_db.readingProgress)
            ..where((p) => p.baniVersionId.equals(baniVersionId)))
          .getSingleOrNull();

  Stream<List<ReadingProgressData>> watchAllProgress() => _db.select(_db.readingProgress).watch();

  Future<void> saveProgress(String baniVersionId, int lineIdx, {int audioPosMs = 0}) =>
      _db.into(_db.readingProgress).insertOnConflictUpdate(
            ReadingProgressCompanion.insert(
              baniVersionId: baniVersionId,
              lineIdx: Value(lineIdx),
              audioPosMs: Value(audioPosMs),
              updatedAt: DateTime.now().toUtc(),
            ),
          );

  Future<void> clearProgress(String baniVersionId) =>
      (_db.delete(_db.readingProgress)..where((p) => p.baniVersionId.equals(baniVersionId))).go();

  // ------------------------------------------------------------- completions

  Stream<List<Completion>> watchCompletions() => _db.select(_db.completions).watch();

  Stream<List<Completion>> watchCompletionsOn(DateTime date) {
    final key = localDateKey(date);
    return (_db.select(_db.completions)..where((c) => c.localDate.equals(key))).watch();
  }

  Future<List<Completion>> completionsOn(DateTime date) {
    final key = localDateKey(date);
    return (_db.select(_db.completions)..where((c) => c.localDate.equals(key))).get();
  }

  /// Records that a bani was finished.
  ///
  /// The diary holds one completion per bani per slot per day, so a repeat
  /// paath on the same day updates rather than duplicates -- extra paaths
  /// still count towards goals, which are ticked separately.
  Future<void> logCompletion({
    required String baniId,
    required BaniSlotValue slot,
    required CompletionSource source,
    DateTime? on,
  }) async {
    final date = on ?? _clock.today();
    final key = localDateKey(date);
    final existing = await (_db.select(_db.completions)
          ..where((c) =>
              c.localDate.equals(key) & c.baniId.equals(baniId) & c.slot.equalsValue(slot)))
        .getSingleOrNull();
    if (existing != null) return;
    await _db.into(_db.completions).insert(
          CompletionsCompanion.insert(
            id: newId(),
            localDate: key,
            baniId: baniId,
            slot: slot,
            source: source,
            completedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> removeCompletion({
    required String baniId,
    required BaniSlotValue slot,
    required DateTime on,
  }) {
    final key = localDateKey(on);
    return (_db.delete(_db.completions)
          ..where((c) =>
              c.localDate.equals(key) & c.baniId.equals(baniId) & c.slot.equalsValue(slot)))
        .go();
  }

  // ------------------------------------------------------------------ simran

  Stream<List<SimranSession>> watchSimranSessions() => _db.select(_db.simranSessions).watch();

  /// Records a sitting, and credits a Naam Simran goal for the same day.
  ///
  /// The credit is here rather than at the call sites because there are
  /// three of them -- the timer finishing, a tick in the Diary, and a restore
  /// -- and none of them was doing it. A bani credits its goal through
  /// `creditGoalsFor` on every path it can be completed by; simran had no
  /// equivalent, so the day was marked as hazri and the goal beside it stayed
  /// undone. That is the misalignment between the Diary and the goals.
  ///
  /// Only a completed sitting counts, which is the same bar hazri and the
  /// Diary already use: `Hazri.from` and `diaryMonth` both filter on
  /// `completed`. A sitting ended early marks nothing, anywhere.
  Future<void> logSimran({
    required Duration duration,
    required int count,
    required bool completed,
    DateTime? on,
  }) async {
    final day = on ?? _clock.today();
    await _db.into(_db.simranSessions).insert(
          SimranSessionsCompanion.insert(
            id: newId(),
            localDate: localDateKey(day),
            startedAt: DateTime.now().toUtc().subtract(duration),
            durationS: duration.inSeconds,
            count: Value(count),
            completed: Value(completed),
          ),
        );
    if (completed) await creditGoalsFor(kSimranGoalId, on: day);
  }

  Future<void> removeSimranOn(DateTime date) async {
    final key = localDateKey(date);
    await (_db.delete(_db.simranSessions)..where((s) => s.localDate.equals(key)))
        .go();
    // And take back what the sitting gave, the way unticking a bani does.
    await removeGoalCreditFor(kSimranGoalId, on: date);
  }

  // ------------------------------------------------------------------- diary

  /// The diary marks for one calendar month.
  Future<List<DiaryDay>> diaryMonth(DateTime month) async {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final from = localDateKey(first);
    final to = localDateKey(last);

    final completions = await (_db.select(_db.completions)
          ..where((c) => c.localDate.isBiggerOrEqualValue(from) & c.localDate.isSmallerOrEqualValue(to)))
        .get();
    final simran = await (_db.select(_db.simranSessions)
          ..where((s) =>
              s.localDate.isBiggerOrEqualValue(from) &
              s.localDate.isSmallerOrEqualValue(to) &
              s.completed.equals(true)))
        .get();
    final grace = await (_db.select(_db.graceDays)
          ..where((g) => g.monthKey.equals(monthKey(first))))
        .get();
    // Every goal, archived ones included: a goal kept for three weeks and then
    // stopped still describes those three weeks, and deleting it used to erase
    // them. `GoalCalculator.appliesOn` decides which days each one covers.
    final goals = await _db.select(_db.goals).get();
    final ticks = await (_db.select(_db.goalTicks)
          ..where((t) =>
              t.localDate.isBiggerOrEqualValue(from) &
              t.localDate.isSmallerOrEqualValue(to)))
        .get();
    // Counted, not collected: a goal of three paath a day is met at three.
    final ticksByDay = <String, Map<String, int>>{};
    for (final t in ticks) {
      final day = ticksByDay.putIfAbsent(t.localDate, () => {});
      day[t.goalId] = (day[t.goalId] ?? 0) + 1;
    }

    final bySlot = <String, Set<BaniSlotValue>>{};
    for (final c in completions) {
      bySlot.putIfAbsent(c.localDate, () => {}).add(c.slot);
    }
    final simranDays = {for (final s in simran) s.localDate};
    final graceDays = {for (final g in grace) g.localDate};

    return [
      for (var d = 1; d <= last.day; d++)
        () {
          final date = DateTime(month.year, month.month, d);
          final key = localDateKey(date);
          return DiaryDay(
            date: date,
            slots: bySlot[key] ?? const {},
            isGrace: graceDays.contains(key),
            simran: simranDays.contains(key),
            goals: GoalCalculator.outcomeOn(
              goals: goals,
              ticks: ticksByDay[key] ?? const {},
              day: date,
            ),
          );
        }(),
    ];
  }

  /// Recomputes the streak, persisting any grace days it had to spend.
  Future<StreakResult> streak() async {
    final completions = await _db.select(_db.completions).get();
    final nitnemDays = <String>{};
    for (final c in completions) {
      if (c.slot != BaniSlotValue.none) nitnemDays.add(c.localDate);
    }
    final grace = await _db.select(_db.graceDays).get();
    final result = StreakCalculator.compute(
      nitnemDays: nitnemDays,
      existingGraceDays: {for (final g in grace) g.localDate},
      today: _clock.today(),
    );
    for (final d in result.graceUsed) {
      await _db.into(_db.graceDays).insertOnConflictUpdate(
            GraceDaysCompanion.insert(localDate: localDateKey(d), monthKey: monthKey(d)),
          );
    }
    return result;
  }

  // ------------------------------------------------------------------- goals

  Stream<List<Goal>> watchGoals() =>
      (_db.select(_db.goals)..orderBy([(g) => OrderingTerm(expression: g.createdAt)])).watch();

  Future<List<Goal>> activeGoals() =>
      (_db.select(_db.goals)..where((g) => g.active.equals(true))).get();

  Future<void> saveGoal(GoalsCompanion goal) =>
      _db.into(_db.goals).insertOnConflictUpdate(goal);

  /// Stops a goal without erasing the days it covered.
  ///
  /// It is archived, not deleted: `endedOn` is set to the last day it asked
  /// anything of, `active` goes false so it leaves the live list, and every
  /// tick stays. Deleting the row took its ticks with it, so a goal kept from
  /// the 1st to the 22nd and then stopped rewrote all twenty-two days as
  /// though nobody had ever set it.
  ///
  /// [on] is the last day it counts for, today by default. A goal stopped
  /// today is still owed today's paath.
  Future<void> archiveGoal(String id, {DateTime? on}) async {
    final last = localDateKey(on ?? _clock.today());
    await (_db.update(_db.goals)..where((g) => g.id.equals(id))).write(
      GoalsCompanion(
        endedOn: Value(last),
        active: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Erases a goal and everything it ever recorded.
  ///
  /// Only for a goal created by mistake, where there is no history worth
  /// keeping. Stopping one somebody actually kept is [archiveGoal].
  Future<void> forgetGoal(String id) async {
    await (_db.delete(_db.goalTicks)..where((t) => t.goalId.equals(id))).go();
    await (_db.delete(_db.goals)..where((g) => g.id.equals(id))).go();
  }

  Stream<List<GoalTick>> watchGoalTicks() => _db.select(_db.goalTicks).watch();

  /// Every goal, with the ticks recorded on [date], as one stream.
  ///
  /// A join, rather than watching the goals table and reading the ticks
  /// alongside it. drift re-runs a watched query when any table the query
  /// touches changes, and a tick writes to goal_tick, not goal -- so watching
  /// goals alone left the count frozen at whatever it was when the screen
  /// opened, however many banis were finished afterwards.
  Stream<({List<Goal> goals, List<GoalTick> ticks})> watchGoalsAndTicks(
    DateTime date,
  ) {
    final key = localDateKey(date);
    final query = _db.select(_db.goals).join([
      leftOuterJoin(
        _db.goalTicks,
        _db.goalTicks.goalId.equalsExp(_db.goals.id) &
            _db.goalTicks.localDate.equals(key),
      ),
    ])
      ..orderBy([OrderingTerm(expression: _db.goals.createdAt)]);

    return query.watch().map((rows) {
      // The join repeats a goal once per tick, so both sides are de-duplicated
      // by id rather than collected straight off the rows.
      final goals = <String, Goal>{};
      final ticks = <String, GoalTick>{};
      for (final row in rows) {
        final goal = row.readTable(_db.goals);
        goals[goal.id] = goal;
        final tick = row.readTableOrNull(_db.goalTicks);
        if (tick != null) ticks[tick.id] = tick;
      }
      return (goals: goals.values.toList(), ticks: ticks.values.toList());
    });
  }

  Future<List<GoalTick>> goalTicksOn(DateTime date) {
    final key = localDateKey(date);
    return (_db.select(_db.goalTicks)..where((t) => t.localDate.equals(key))).get();
  }

  Future<void> tickGoal(String goalId, {String source = 'manual', DateTime? on}) =>
      _db.into(_db.goalTicks).insert(
            GoalTicksCompanion.insert(
              id: newId(),
              goalId: goalId,
              localDate: localDateKey(on ?? _clock.today()),
              source: source,
              at: DateTime.now().toUtc(),
            ),
          );

  /// Adds a tick to every active goal for [baniId] that has not met its daily
  /// target yet (PRD 1.15).
  Future<void> creditGoalsFor(String baniId, {DateTime? on}) async {
    final day = on ?? _clock.today();
    final goals = await activeGoals();
    final ticks = await goalTicksOn(day);
    for (final g in goals) {
      if (g.baniId != baniId) continue;
      final done = ticks.where((t) => t.goalId == g.id).length;
      if (done >= g.timesPerDay) continue;
      await tickGoal(g.id, source: 'auto', on: day);
    }
  }

  /// Takes back the credit a completion gave, when that completion is undone.
  ///
  /// Only the ticks this credited automatically: a tick somebody added by hand
  /// on the Goals screen is theirs, and unticking a bani in the Diary should
  /// not quietly delete it.
  Future<void> removeGoalCreditFor(String baniId, {DateTime? on}) async {
    final key = localDateKey(on ?? _clock.today());
    final goals = await activeGoals();
    for (final g in goals) {
      if (g.baniId != baniId) continue;
      final mine = await (_db.select(_db.goalTicks)
            ..where((t) =>
                t.goalId.equals(g.id) &
                t.localDate.equals(key) &
                t.source.equals('auto'))
            ..orderBy([(t) => OrderingTerm(expression: t.at, mode: OrderingMode.desc)])
            ..limit(1))
          .getSingleOrNull();
      if (mine != null) {
        await (_db.delete(_db.goalTicks)..where((t) => t.id.equals(mine.id))).go();
      }
    }
  }

  // --------------------------------------------------------------- reminders

  Stream<List<Reminder>> watchReminders() => _db.select(_db.reminders).watch();

  Future<List<Reminder>> reminders() => _db.select(_db.reminders).get();

  Future<Reminder?> reminder(String id) =>
      (_db.select(_db.reminders)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<void> saveReminder(RemindersCompanion reminder) =>
      _db.into(_db.reminders).insertOnConflictUpdate(reminder);

  Future<void> deleteReminder(String id) =>
      (_db.delete(_db.reminders)..where((r) => r.id.equals(id))).go();

  // -------------------------------------------------------- event overrides

  Future<Map<String, bool>> eventOverrides() async {
    final rows = await _db.select(_db.eventReminderOverrides).get();
    return {for (final r in rows) r.eventId: r.enabled};
  }

  Future<void> setEventOverride(String eventId, bool enabled) =>
      _db.into(_db.eventReminderOverrides).insertOnConflictUpdate(
            EventReminderOverridesCompanion.insert(eventId: eventId, enabled: enabled),
          );
}
