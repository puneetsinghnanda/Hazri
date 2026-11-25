import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_repository.dart' show HazriStreak;
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/today/ui/today_screen.dart' show streakCardView;

/// 05-today.md T12 (owner, 2026-11-25): the streak card stays while any of
/// the last seven days has hazri, and goes after seven days without.
void main() {
  final today = DateTime(2026, 11, 25);
  String back(int n) => localDateKey(today.subtract(Duration(days: n)));
  HazriStreak streak(int current, Set<int> daysBack) =>
      HazriStreak(current: current, longest: current, days: {for (final n in daysBack) back(n)});

  test('a run of two or more says the run', () {
    expect(streakCardView(streak(4, {0, 1, 2, 3}), today), (count: 4, run: true));
  });

  test('T-s1: a missed day keeps the card, counting the week', () {
    // Hazri on four days, then yesterday missed: the run is broken.
    expect(streakCardView(streak(0, {2, 3, 4, 5}), today), (count: 4, run: false));
  });

  test('T-s2: one hazri six days ago still shows the card', () {
    expect(streakCardView(streak(0, {6}), today), (count: 1, run: false));
  });

  test('T-s3: one hazri today after a long gap shows the card', () {
    expect(streakCardView(streak(1, {0, 30}), today), (count: 1, run: false));
  });

  test('T-s4: no hazri for seven days hides the card', () {
    expect(streakCardView(streak(0, {7, 8, 9}), today), isNull);
    expect(streakCardView(HazriStreak.zero, today), isNull);
  });
}
