import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/features/goals/domain/goal_progress.dart';

/// The reader's five scenarios, written down (2026-09-23).
///
/// One rule decides which days a goal asks anything of, and it is the rule
/// Today's card, the diary's month grid and the diary's day screen all use.
/// Before it there were three answers to the same question.
void main() {
  Goal goal({
    String id = 'g1',
    String start = '2026-09-01',
    GoalDuration duration = GoalDuration.everyDay,
    int? days,
    String? until,
    String? endedOn,
    int timesPerDay = 1,
  }) =>
      Goal(
        id: id,
        baniId: 'japji-sahib',
        timesPerDay: timesPerDay,
        durationType: duration,
        days: days,
        untilDate: until,
        startDate: start,
        endedOn: endedOn,
        active: endedOn == null,
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 9, 1),
      );

  DateTime sep(int d) => DateTime(2026, 9, d);

  group('which days a goal covers', () {
    test('a seven-day goal from the 1st ends on the 7th, not the 8th', () {
      final g = goal(duration: GoalDuration.days, days: 7);
      expect(GoalCalculator.lastDayOf(g), sep(7));
      expect(GoalCalculator.appliesOn(g, sep(7)), isTrue);
      expect(GoalCalculator.appliesOn(g, sep(8)), isFalse);
    });

    test('scenario 1: it asks nothing of the days after it finished', () {
      // It used to be judged against every later day for ever, so the green
      // dot went dark on the 8th and could never light again.
      final g = goal(duration: GoalDuration.days, days: 7);
      for (final d in [8, 15, 23, 30]) {
        expect(GoalCalculator.appliesOn(g, sep(d)), isFalse, reason: 'Sept $d');
      }
    });

    test('and nothing of the days before it started', () {
      expect(GoalCalculator.appliesOn(goal(start: '2026-09-15'), sep(14)), isFalse);
      expect(GoalCalculator.appliesOn(goal(start: '2026-09-15'), sep(15)), isTrue);
    });

    test('an until date is the last day, inclusive', () {
      final g = goal(duration: GoalDuration.until, until: '2026-09-15');
      expect(GoalCalculator.appliesOn(g, sep(15)), isTrue);
      expect(GoalCalculator.appliesOn(g, sep(16)), isFalse);
    });

    test('scenario 5: an open-ended goal never stops', () {
      final g = goal();
      expect(GoalCalculator.lastDayOf(g), isNull);
      expect(GoalCalculator.appliesOn(g, DateTime(2027, 6, 1)), isTrue);
    });

    test('scenario 4: stopping one keeps the days it covered', () {
      // Started 1 Sept, stopped on the 22nd: the 1st to the 22nd still count,
      // the 23rd does not.
      final g = goal(endedOn: '2026-09-22');
      expect(GoalCalculator.appliesOn(g, sep(1)), isTrue);
      expect(GoalCalculator.appliesOn(g, sep(22)), isTrue);
      expect(GoalCalculator.appliesOn(g, sep(23)), isFalse);
    });

    test('whichever end comes first wins', () {
      final g = goal(duration: GoalDuration.days, days: 30, endedOn: '2026-09-10');
      expect(GoalCalculator.lastDayOf(g), sep(10));
    });
  });

  group('how a day went', () {
    test('a goal of three paath is met at three, not at one', () {
      // The month grid used to count any tick as met, so a goal of three lit
      // the green dot after one paath while Today still said nought of one.
      final g = goal(timesPerDay: 3);
      expect(
        GoalCalculator.outcomeOn(goals: [g], ticks: {'g1': 1}, day: sep(10)).allMet,
        isFalse,
      );
      expect(
        GoalCalculator.outcomeOn(goals: [g], ticks: {'g1': 3}, day: sep(10)).allMet,
        isTrue,
      );
    });

    test('scenario 3: a day with no goals has none to miss', () {
      final out = GoalCalculator.outcomeOn(
        goals: [goal(start: '2026-09-15')],
        ticks: const {},
        day: sep(10),
      );
      expect(out.hasGoals, isFalse, reason: 'one dot, not a grey second one');
      expect(out.allMet, isFalse);
    });

    test('scenario 2: a finished goal does not spoil a day the live one met',
        () {
      // Japji for the first week, simran every day. On the 20th the simran
      // was done and that is everything the day asked for.
      final japji = goal(id: 'japji', duration: GoalDuration.days, days: 7);
      final simran = goal(id: 'simran');

      final out = GoalCalculator.outcomeOn(
        goals: [japji, simran],
        ticks: {'simran': 1},
        day: sep(20),
      );
      expect(out.inScope, 1, reason: 'only the simran goal is still asking');
      expect(out.allMet, isTrue, reason: 'and it was met');
    });

    test('and both count on a day they were both running', () {
      final japji = goal(id: 'japji', duration: GoalDuration.days, days: 7);
      final simran = goal(id: 'simran');

      final out = GoalCalculator.outcomeOn(
        goals: [japji, simran],
        ticks: {'simran': 1},
        day: sep(5),
      );
      expect(out.inScope, 2);
      expect(out.met, 1);
      expect(out.allMet, isFalse);
    });
  });
}
