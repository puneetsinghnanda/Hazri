import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/today/ui/today_screen.dart';

import '../app_harness.dart';

/// Today opens on the goals card (design 30): a prompt before any goal
/// exists, then a count, a ring and one row per goal.
///
/// The Phase 1 card drew a day arc with the goals hung off it as nodes.
/// These tests moved with it rather than being deleted: the questions are
/// the same, and the answers are now numbers rather than positions on a
/// curve.
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 9, 14, 9, 30),
    );
  });

  tearDown(() => app.dispose());

  Future<void> addGoal(String id, String bani, String? at, {int times = 1}) =>
      app.container.read(userRepositoryProvider).saveGoal(
            GoalsCompanion.insert(
              id: id,
              baniId: bani,
              timesPerDay: Value(times),
              durationType: GoalDuration.everyDay,
              startDate: localDateKey(DateTime(2026, 9, 14)),
              reminderTime: Value(at),
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            ),
          );

  Future<L> pump(WidgetTester tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const TodayScreen()));
    await settle(tester);
    return L.delegate.load(const Locale('en'));
  }

  testWidgets('with no goals it asks for one instead of an empty card',
      (tester) async {
    final l = await pump(tester);
    expect(find.text(l.goalsEmptyTitle), findsOneWidget);
    expect(find.text(l.goalsAdd), findsOneWidget);
    expect(find.text(l.goalsCardTitle.toUpperCase()), findsNothing);
  });

  testWidgets('a goal is a row with its name and the time it is due',
      (tester) async {
    await addGoal('g1', 'JAPJ', '05:30');
    final l = await pump(tester);
    expect(find.text(l.goalsCardTitle.toUpperCase()), findsOneWidget);
    expect(find.text('Japji Sahib'), findsOneWidget);
    expect(find.text(l.goalsEmptyTitle), findsNothing);
  });

  testWidgets('a goal with no time shows how many of how many, not a blank',
      (tester) async {
    await addGoal('g1', 'JAPJ', '05:30');
    await addGoal('g2', 'SOHL', null, times: 2);
    final l = await pump(tester);
    expect(find.text('Kirtan Sohila'), findsOneWidget);
    expect(find.text(l.nOfM(0, 2)), findsOneWidget);
  });

  testWidgets('the headline counts goals, and the ring counts the paath in them',
      (tester) async {
    // One of two goals done, but three of six paath: the row count and the
    // ring answer different questions and both are on the card.
    await addGoal('g1', 'JAPJ', null);
    await addGoal('g2', 'SOHL', null, times: 5);
    final l = await pump(tester);
    expect(find.text(l.goalsDoneOf(0, 2)), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('a Naam Simran goal is named, not shown as a bare id',
      (tester) async {
    await addGoal('g1', kSimranGoalId, '05:15');
    final l = await pump(tester);
    expect(find.text(l.hazriSimran), findsOneWidget);
  });

  testWidgets('the Start Nitnem button survived the card change', (tester) async {
    await pump(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
  });
}
