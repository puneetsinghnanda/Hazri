import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/features/today/ui/today_screen.dart';

/// Design 1A (owner, 2026-10-29): a goal of more than three items folds to
/// the one due now, the next, and the earliest missed.
void main() {
  final utc = DateTime.utc(2026, 10, 1);
  GoalItem item(String id, String? at) => GoalItem(
    id: id,
    goalId: 'g',
    seriesId: id,
    itemType: ItemType.bani,
    baniId: id,
    timesPerDay: 1,
    durationType: DurationType.everyDay,
    startDate: '2026-10-01',
    reminderTime: at,
    createdAt: utc,
    updatedAt: utc,
  );
  DateTime? at(GoalItem i) {
    final t = i.reminderTime;
    if (t == null) return null;
    final p = t.split(':');
    return DateTime(2026, 10, 29, int.parse(p[0]), int.parse(p[1]));
  }

  // The owner's goal of 29 October, in clock order.
  final goal = [
    item('JAPJ', '06:00'),
    item('JAAP', '06:15'),
    item('TVPS', '06:30'),
    item('ANND', '07:00'),
    item('SIMRAN', '09:30'),
    item('REHR', '18:00'),
    item('SOHL', '19:00'),
  ];

  List<(String, GoalTag)> fold(Set<String> met, DateTime now) => [
    for (final (i, t) in foldGoalRows(goal, at: at, met: (i) => met.contains(i.id), now: now)) (i.id, t),
  ];

  test('at 6:46 PM with Japji and Jaap done: Rehras now, Kirtan Sohila next, Tav Prasad missed', () {
    expect(fold({'JAPJ', 'JAAP'}, DateTime(2026, 10, 29, 18, 46)), [
      ('REHR', GoalTag.now),
      ('SOHL', GoalTag.none),
      ('TVPS', GoalTag.missed),
    ]);
  });

  test('before the first one: the next three, none due', () {
    expect(fold({}, DateTime(2026, 10, 29, 5)), [
      ('JAPJ', GoalTag.none),
      ('JAAP', GoalTag.none),
      ('TVPS', GoalTag.none),
    ]);
  });

  test('after the last: the latest is now, the rest missed, earliest first', () {
    expect(fold({'REHR'}, DateTime(2026, 10, 29, 22)), [
      ('SOHL', GoalTag.now),
      ('JAPJ', GoalTag.missed),
      ('JAAP', GoalTag.missed),
    ]);
  });

  test('everything met folds to nothing', () {
    expect(fold(goal.map((i) => i.id).toSet(), DateTime(2026, 10, 29, 22)), isEmpty);
  });
}
