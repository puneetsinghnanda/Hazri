import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/goals/domain/day_verdict.dart';

/// 04-goals §8 against a real (in-memory) database: every row a test.
void main() {
  late UserDb db;
  late UserRepository repo;
  late FixedClock clock;

  DateTime d(int month, int day, [int hour = 9]) => DateTime(2026, month, day, hour);

  setUp(() {
    db = UserDb.memory();
    clock = FixedClock(d(10, 1));
    repo = UserRepository(db, clock);
  });

  tearDown(() => db.close());

  Future<Completion> read(String bani, {DateTime? on, CompletionSource source = CompletionSource.reader}) =>
      repo.logCompletion(baniId: bani, slot: BaniSlotValue.morning, source: source, on: on);

  Future<SimranSession> sit(int seconds, {DateTime? on, bool completed = true}) => repo.logSitting(
      duration: Duration(seconds: seconds), completed: completed, source: SittingSource.timer, on: on);

  Future<DayVerdict> verdict([DateTime? day]) async => (await repo.dayRows(day ?? clock.today())).verdict;

  group('8.1 hazri without goals', () {
    test('H-1: a completed bani marks hazri; no second dot', () async {
      await read('JAPJ');
      final v = await verdict();
      expect(v.hazri, isTrue);
      expect(v.goalState, GoalState.none);
    });

    test('H-2: a 5-minute sitting marks hazri', () async {
      await sit(300);
      expect((await verdict()).hazri, isTrue);
    });

    test('H-3: 4 min 59 s is stored and marks nothing', () async {
      await sit(299, completed: false);
      expect((await verdict()).hazri, isFalse);
      expect(await repo.allSittings(), hasLength(1));
    });

    test('H-6: a bani outside the goal marks hazri, not the goal', () async {
      await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      await read('REHR');
      final v = await verdict();
      expect(v.hazri, isTrue);
      expect(v.goalState, GoalState.notMet);
    });
  });

  group('8.2 goals', () {
    test('G-2: Japji ×1 read → met (DV2)', () async {
      await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      await read('JAPJ');
      final v = await verdict();
      expect(v.goalState, GoalState.met);
      expect((v.itemsMet, v.itemsInScope), (1, 1));
    });

    test('G-3, G-4: Japji ×3 needs three completions', () async {
      await repo.addItem(const GoalItemSpec.bani('JAPJ', timesPerDay: 3));
      await read('JAPJ');
      expect((await verdict()).goalState, GoalState.notMet);
      await read('JAPJ');
      await read('JAPJ');
      expect((await verdict()).goalState, GoalState.met);
    });

    test('G-5: a sitting shorter than the item is not met (HZ4)', () async {
      await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      await repo.addItem(const GoalItemSpec.simran(11));
      await read('JAPJ');
      await sit(7 * 60, completed: false);
      final v = await verdict();
      expect(v.hazri, isTrue);
      expect((v.itemsMet, v.itemsInScope), (1, 2));
    });

    test('G-6: an 11-minute sitting meets Simran 11', () async {
      await repo.addItem(const GoalItemSpec.simran(11));
      await sit(11 * 60);
      expect((await verdict()).goalState, GoalState.met);
    });

    test('G-7: Japji read twice is two rows and met once (CR6)', () async {
      await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      await read('JAPJ');
      await read('JAPJ');
      expect(await repo.completionsOn(clock.today()), hasLength(2));
      expect((await verdict()).itemsMet, 1);
    });

    test('G-11 / GI1: an item already in scope cannot be added twice', () async {
      await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      expect(() => repo.addItem(const GoalItemSpec.bani('JAPJ')), throwsA(isA<GoalRuleException>()));
    });

    test('GL3: one active goal holds every item', () async {
      await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      await repo.addItem(const GoalItemSpec.bani('REHR'));
      expect(await db.select(db.goals).get(), hasLength(1));
    });
  });

  group('8.3 duration, editing and removal', () {
    test('E-1: a 7-day goal kept to the end completes on day 8', () async {
      await repo.addItem(const GoalItemSpec.bani('JAPJ', durationType: DurationType.days, durationDays: 7));
      for (var day = 1; day <= 7; day++) {
        clock.instant = d(10, day);
        await read('JAPJ');
      }
      clock.instant = d(10, 8);
      await repo.closeGoalIfBlank();
      expect((await verdict(d(10, 7))).goalState, GoalState.met);
      expect((await verdict(d(10, 8))).goalState, GoalState.none);
      expect(await repo.activeGoal(), isNull);
      expect((await db.select(db.goals).getSingle()).completedOn, '2026-10-08');
    });

    test('E-2: removing one of two keeps the goal; earlier days unchanged', () async {
      await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      final rehras = await repo.addItem(const GoalItemSpec.bani('REHR'));
      await read('JAPJ');
      clock.instant = d(10, 20);
      await repo.removeItem(rehras.id);
      expect(await repo.activeGoal(), isNotNull);
      expect((await verdict(d(10, 1))).itemsInScope, 2);
      expect((await verdict(d(10, 20))).itemsInScope, 1);
    });

    test('E-3: removing the only item today completes the goal; today has no second dot', () async {
      final japji = await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      clock.instant = d(10, 5);
      await read('JAPJ');
      await repo.removeItem(japji.id);
      expect(await repo.activeGoal(), isNull);
      expect((await verdict()).goalState, GoalState.none);
      expect((await verdict(d(10, 4))).goalState, GoalState.notMet);
    });

    test('E-4: added and removed the same day is never in scope', () async {
      await repo.addItem(const GoalItemSpec.bani('REHR'));
      final japji = await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      await repo.removeItem(japji.id);
      expect((await verdict()).itemsInScope, 1);
    });

    test('E-5: a target change applies from today; earlier days keep theirs (GI6)', () async {
      final japji = await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      await read('JAPJ');
      clock.instant = d(10, 11);
      await repo.editTarget(japji.id, timesPerDay: 3);
      await read('JAPJ');
      expect((await verdict(d(10, 1))).goalState, GoalState.met);
      expect((await verdict()).goalState, GoalState.notMet);
    });

    test('E-6: lengthening a 40-day item moves its end from the series start', () async {
      final japji = await repo.addItem(
          const GoalItemSpec.bani('JAPJ', durationType: DurationType.days, durationDays: 40));
      clock.instant = d(10, 12);
      await repo.editDuration(japji.id, type: DurationType.days, durationDays: 60);
      final row = await repo.item(japji.id);
      expect(row!.endDate, '2026-11-29');
    });

    test('E-7: an end date in the past is refused and nothing saves', () async {
      final japji = await repo.addItem(
          const GoalItemSpec.bani('JAPJ', durationType: DurationType.days, durationDays: 40));
      clock.instant = d(10, 12);
      expect(
        () => repo.editDuration(japji.id, type: DurationType.untilDate, untilDate: '2026-10-11'),
        throwsA(isA<GoalRuleException>()),
      );
      expect((await repo.item(japji.id))!.endDate, '2026-11-09');
    });

    test('E-8: a reminder change moves only the reminder', () async {
      final japji = await repo.addItem(const GoalItemSpec.bani('JAPJ', reminderTime: '06:00'));
      await repo.editReminder(japji.id, '06:30');
      final rows = await repo.allItems();
      expect(rows, hasLength(1));
      expect(rows.single.reminderTime, '06:30');
    });

    test('E-9: after a completed goal, adding starts a new one (GL4)', () async {
      final japji = await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      await repo.removeItem(japji.id);
      clock.instant = d(10, 2);
      await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      final goals = await db.select(db.goals).get();
      expect(goals, hasLength(2));
      expect(goals.where((g) => g.completedOn == null).single.startDate, '2026-10-02');
    });
  });

  group('8.4 Diary editing', () {
    test('D-1: + on a past day lights both dots', () async {
      await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      clock.instant = d(10, 4);
      await read('JAPJ', on: d(10, 1), source: CompletionSource.diary);
      final v = await verdict(d(10, 1));
      expect(v.hazri, isTrue);
      expect(v.goalState, GoalState.met);
    });

    test('D-2: − undoes the reader\'s completion by setting deletedAt (CR4)', () async {
      await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      final c = await read('JAPJ');
      await repo.undoLatestCompletion('JAPJ', clock.today());
      final v = await verdict();
      expect(v.hazri, isFalse);
      expect(v.goalState, GoalState.notMet);
      final row = await (db.select(db.completions)..where((x) => x.id.equals(c.id))).getSingle();
      expect(row.deletedAt, isNotNull);
    });

    test('CR4: − takes the newest, whatever its source', () async {
      await read('JAPJ', source: CompletionSource.reader);
      clock.instant = d(10, 1, 10);
      await read('JAPJ', source: CompletionSource.audio);
      await repo.undoLatestCompletion('JAPJ', clock.today());
      final live = await repo.completionsOn(clock.today());
      expect(live.single.source, CompletionSource.reader);
    });

    test('D-3: − with nothing to undo changes nothing', () async {
      await read('REHR');
      expect(await repo.undoLatestCompletion('JAPJ', clock.today()), isNull);
      expect(await repo.completionsOn(clock.today()), hasLength(1));
    });
  });

  group('the streak (09-diary D12)', () {
    test('counts hazri days: Sukhmani and a 5-minute sitting extend it (D9)', () async {
      for (var day = 1; day <= 3; day++) {
        clock.instant = d(10, day);
        await read('JAPJ');
      }
      clock.instant = d(10, 4);
      await repo.logCompletion(baniId: 'SUKH', slot: BaniSlotValue.none, source: CompletionSource.reader);
      clock.instant = d(10, 5);
      await sit(300);
      final s = await repo.hazriStreak();
      expect(s.current, 5);
      expect(s.longest, 5);
    });

    test('a sitting under 5 minutes marks no hazri and does not count (D9)', () async {
      clock.instant = d(10, 1);
      await read('JAPJ');
      clock.instant = d(10, 2);
      await read('JAPJ');
      clock.instant = d(10, 3);
      await sit(299);
      // Day 3 has no hazri: the run is the one ending yesterday.
      expect((await repo.hazriStreak()).current, 2);
    });

    test('longest outlives a broken run', () async {
      for (final day in [1, 2, 3, 4]) {
        clock.instant = d(9, day);
        await read('JAPJ');
      }
      for (final day in [20, 21]) {
        clock.instant = d(9, day);
        await read('JAPJ');
      }
      final s = await repo.hazriStreak();
      expect(s.current, 2);
      expect(s.longest, 4);
    });
  });

  test('onChanged fires on every write (RM3, CM2)', () async {
    var calls = 0;
    repo.onChanged = () => calls++;
    await read('JAPJ');
    await sit(300);
    await repo.addItem(const GoalItemSpec.bani('REHR'));
    expect(calls, greaterThanOrEqualTo(3));
  });
}
