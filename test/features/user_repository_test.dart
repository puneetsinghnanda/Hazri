import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/goals/domain/goal_progress.dart';

/// Completion, goal and diary rules against a real (in-memory) database.
void main() {
  late UserDb db;
  late UserRepository repo;
  late FixedClock clock;

  final today = DateTime(2026, 9, 12);

  setUp(() {
    db = UserDb.memory();
    clock = FixedClock(DateTime(2026, 9, 12, 6, 30));
    repo = UserRepository(db, clock);
  });

  tearDown(() => db.close());

  group('completions', () {
    test('one bani in one slot counts once a day, however often it is read', () async {
      for (var i = 0; i < 3; i++) {
        await repo.logCompletion(
          baniId: 'JAPJ',
          slot: BaniSlotValue.morning,
          source: CompletionSource.read,
        );
      }
      final rows = await repo.completionsOn(today);
      expect(rows.length, 1);
      expect(rows.single.source, CompletionSource.read);
    });

    test('different banis in the same slot are separate completions', () async {
      await repo.logCompletion(
        baniId: 'JAPJ',
        slot: BaniSlotValue.morning,
        source: CompletionSource.read,
      );
      await repo.logCompletion(
        baniId: 'JAAP',
        slot: BaniSlotValue.morning,
        source: CompletionSource.listen,
      );
      expect((await repo.completionsOn(today)).length, 2);
    });

    test('a manual tick can be removed again', () async {
      await repo.logCompletion(
        baniId: 'REHR',
        slot: BaniSlotValue.evening,
        source: CompletionSource.manual,
        on: today,
      );
      expect((await repo.completionsOn(today)).length, 1);
      await repo.removeCompletion(
        baniId: 'REHR',
        slot: BaniSlotValue.evening,
        on: today,
      );
      expect(await repo.completionsOn(today), isEmpty);
    });

    test('completions are filed under the day they happened', () async {
      final yesterday = today.subtract(const Duration(days: 1));
      await repo.logCompletion(
        baniId: 'JAPJ',
        slot: BaniSlotValue.morning,
        source: CompletionSource.manual,
        on: yesterday,
      );
      expect(await repo.completionsOn(today), isEmpty);
      expect((await repo.completionsOn(yesterday)).length, 1);
    });
  });

  group('reading progress', () {
    test('is stored per bani version and overwritten as reading continues', () async {
      await repo.saveProgress('JAPJ_SGPC', 12);
      await repo.saveProgress('JAPJ_SGPC', 40);
      final p = await repo.progressFor('JAPJ_SGPC');
      expect(p!.lineIdx, 40);
      expect(await repo.progressFor('REHR_SGPC'), isNull);
    });
  });

  group('goals', () {
    Future<String> addGoal({int times = 1, String bani = 'JAPJ'}) async {
      final id = UserRepository.newId();
      await repo.saveGoal(
        GoalsCompanion.insert(
          id: id,
          baniId: bani,
          timesPerDay: Value(times),
          durationType: GoalDuration.everyDay,
          startDate: localDateKey(today),
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      return id;
    }

    test('finishing a bani credits its goals, up to the daily target', () async {
      final id = await addGoal(times: 2);
      await repo.creditGoalsFor('JAPJ');
      await repo.creditGoalsFor('JAPJ');
      await repo.creditGoalsFor('JAPJ');
      final ticks = await repo.goalTicksOn(today);
      expect(ticks.where((t) => t.goalId == id).length, 2);
    });

    test('a goal for another bani is not credited', () async {
      await addGoal(bani: 'SUKH');
      await repo.creditGoalsFor('JAPJ');
      expect(await repo.goalTicksOn(today), isEmpty);
    });

    test('the progress stream moves when a bani is finished', () async {
      // The bug this exists for: the stream watched the goals table, and a
      // tick writes to goal_tick, so the count stayed at whatever it was when
      // the screen opened however many banis were finished afterwards.
      final id = await addGoal(times: 2);
      final seen = <int>[];
      final sub = repo.watchGoalsAndTicks(today).listen((data) =>
          seen.add(data.ticks.where((t) => t.goalId == id).length));

      await pumpEventQueue();
      await repo.creditGoalsFor('JAPJ');
      await pumpEventQueue();
      await repo.creditGoalsFor('JAPJ');
      await pumpEventQueue();
      await sub.cancel();

      expect(seen.first, 0, reason: 'starts at nothing done');
      expect(seen.last, 2, reason: 'the stream never reported the ticks');
    });

    test('the stream carries the goal even before anything is ticked', () async {
      await addGoal();
      final data = await repo.watchGoalsAndTicks(today).first;
      expect(data.goals.length, 1);
      expect(data.ticks, isEmpty);
    });

    test('a goal ticked twice is not reported twice by the join', () async {
      await addGoal(times: 3);
      await repo.creditGoalsFor('JAPJ');
      await repo.creditGoalsFor('JAPJ');
      final data = await repo.watchGoalsAndTicks(today).first;
      expect(data.goals.length, 1, reason: 'the join repeats a goal per tick');
      expect(data.ticks.length, 2);
    });

    test('undoing a completion takes back only the credit it gave', () async {
      final id = await addGoal(times: 3);
      await repo.creditGoalsFor('JAPJ');
      await repo.tickGoal(id); // somebody added this one by hand
      expect((await repo.goalTicksOn(today)).length, 2);

      await repo.removeGoalCreditFor('JAPJ');
      final left = await repo.goalTicksOn(today);
      expect(left.length, 1);
      expect(left.single.source, 'manual', reason: 'the hand-added tick is theirs');
    });

    test('a goal credited for an earlier day lands on that day', () async {
      final id = await addGoal();
      final yesterday = today.subtract(const Duration(days: 1));
      await repo.creditGoalsFor('JAPJ', on: yesterday);
      expect(await repo.goalTicksOn(today), isEmpty);
      expect((await repo.goalTicksOn(yesterday)).single.goalId, id);
    });

    test('a manual +1 adds a tick beyond the automatic ones', () async {
      final id = await addGoal(times: 5);
      await repo.creditGoalsFor('JAPJ');
      await repo.tickGoal(id);
      expect((await repo.goalTicksOn(today)).length, 2);
    });

    test('progress reports done for the day once the target is met', () async {
      final id = await addGoal(times: 2);
      await repo.creditGoalsFor('JAPJ');
      final goals = await repo.activeGoals();
      var progress = GoalCalculator.progressFor(
        goal: goals.single,
        ticksToday: await repo.goalTicksOn(today),
        today: today,
      );
      expect(progress.isDoneToday, isFalse);
      expect(progress.fraction, 0.5);

      await repo.tickGoal(id);
      progress = GoalCalculator.progressFor(
        goal: goals.single,
        ticksToday: await repo.goalTicksOn(today),
        today: today,
      );
      expect(progress.isDoneToday, isTrue);
    });

    test('deleting a goal takes its ticks with it', () async {
      final id = await addGoal();
      await repo.tickGoal(id);
      await repo.deleteGoal(id);
      expect(await repo.activeGoals(), isEmpty);
      expect(await repo.goalTicksOn(today), isEmpty);
    });
  });

  group('simran', () {
    test('a completed session lands on today and is visible to the diary', () async {
      await repo.logSimran(
        duration: const Duration(minutes: 5),
        count: 108,
        completed: true,
      );
      final days = await repo.diaryMonth(today);
      expect(days.firstWhere((d) => d.date == today).simran, isTrue);
    });

    test('a session ended early is logged but does not count as done', () async {
      await repo.logSimran(
        duration: const Duration(minutes: 2),
        count: 20,
        completed: false,
      );
      final days = await repo.diaryMonth(today);
      expect(days.firstWhere((d) => d.date == today).simran, isFalse);
    });

    test('and it credits a Naam Simran goal, like a bani credits its own',
        () async {
      // The reported bug: sit the simran, the day is marked as hazri, and
      // the goal beside it stays undone. A bani credits its goal on every
      // path it can be finished by; simran credited nothing, anywhere.
      final id = UserRepository.newId();
      await repo.saveGoal(
        GoalsCompanion.insert(
          id: id,
          baniId: kSimranGoalId,
          minutes: const Value(11),
          timesPerDay: const Value(1),
          durationType: GoalDuration.everyDay,
          startDate: localDateKey(today),
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      await repo.logSimran(
        duration: const Duration(minutes: 11),
        count: 0,
        completed: true,
      );

      final ticks = await repo.goalTicksOn(today);
      expect(ticks.where((t) => t.goalId == id).length, 1);
      // And the diary agrees, which is the alignment that was missing.
      final days = await repo.diaryMonth(today);
      expect(days.firstWhere((d) => d.date == today).simran, isTrue);
    });

    test('a sitting ended early credits nothing, the way it marks nothing',
        () async {
      final id = UserRepository.newId();
      await repo.saveGoal(
        GoalsCompanion.insert(
          id: id,
          baniId: kSimranGoalId,
          timesPerDay: const Value(1),
          durationType: GoalDuration.everyDay,
          startDate: localDateKey(today),
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await repo.logSimran(
        duration: const Duration(minutes: 1),
        count: 0,
        completed: false,
      );
      expect(await repo.goalTicksOn(today), isEmpty);
    });

    test('and unticking the day in the Diary takes the credit back', () async {
      final id = UserRepository.newId();
      await repo.saveGoal(
        GoalsCompanion.insert(
          id: id,
          baniId: kSimranGoalId,
          timesPerDay: const Value(1),
          durationType: GoalDuration.everyDay,
          startDate: localDateKey(today),
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await repo.logSimran(
        duration: const Duration(minutes: 5),
        count: 0,
        completed: true,
      );
      expect(await repo.goalTicksOn(today), hasLength(1));

      await repo.removeSimranOn(today);
      expect(await repo.goalTicksOn(today), isEmpty);
      final days = await repo.diaryMonth(today);
      expect(days.firstWhere((d) => d.date == today).simran, isFalse);
    });
  });

  group('diary month', () {
    test('covers every day of the month, in order', () async {
      final days = await repo.diaryMonth(DateTime(2026, 9));
      expect(days.length, 30);
      expect(days.first.date, DateTime(2026, 9, 1));
      expect(days.last.date, DateTime(2026, 9, 30));
    });

    test('February in a leap year has 29 days', () async {
      final days = await repo.diaryMonth(DateTime(2028, 2));
      expect(days.length, 29);
    });

    test('marks which slots were completed on each day', () async {
      await repo.logCompletion(
        baniId: 'JAPJ',
        slot: BaniSlotValue.morning,
        source: CompletionSource.read,
        on: DateTime(2026, 9, 3),
      );
      final days = await repo.diaryMonth(DateTime(2026, 9));
      final third = days.firstWhere((d) => d.date == DateTime(2026, 9, 3));
      expect(third.slots, {BaniSlotValue.morning});
      expect(third.isNitnemDay, isTrue);
      expect(days.first.isNitnemDay, isFalse);
    });
  });

  group('streak', () {
    test('persists the grace days it grants, so they stay put', () async {
      for (final offset in [0, 1, 2, 4, 5]) {
        await repo.logCompletion(
          baniId: 'JAPJ',
          slot: BaniSlotValue.morning,
          source: CompletionSource.manual,
          on: today.subtract(Duration(days: offset)),
        );
      }
      final first = await repo.streak();
      expect(first.days, 5);
      expect(first.graceUsed.length, 1);

      // Running again must not spend a second grace day on the same gap.
      final second = await repo.streak();
      expect(second.days, 5);
      expect(second.graceUsed, isEmpty);

      final days = await repo.diaryMonth(DateTime(2026, 9));
      expect(days.firstWhere((d) => d.date == DateTime(2026, 9, 9)).isGrace, isTrue);
    });
  });

  group('ids', () {
    test('are UUID v4, so rows stay merge-safe if sync is added', () {
      final id = UserRepository.newId();
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
            .hasMatch(id),
        isTrue,
        reason: id,
      );
      expect(UserRepository.newId(), isNot(id));
    });
  });
}
