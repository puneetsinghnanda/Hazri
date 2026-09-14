import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/core/widgets/day_arc.dart';
import 'package:hazri/features/today/ui/today_screen.dart';

import '../app_harness.dart';

/// Today opens on the goals card (PRD 1.3): a prompt before any goal exists,
/// the goals on the arc once they do.
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

  testWidgets('with no goals it asks for one instead of drawing an empty arc',
      (tester) async {
    final l = await pump(tester);
    expect(find.text(l.goalsEmptyTitle), findsOneWidget);
    expect(find.text(l.goalsAdd), findsOneWidget);
    expect(find.byType(DayArc), findsNothing);
  });

  testWidgets('a goal with a time goes on the arc', (tester) async {
    await addGoal('g1', 'JAPJ', '05:30');
    final l = await pump(tester);
    expect(find.byType(DayArc), findsOneWidget);
    expect(find.text(l.goalsEmptyTitle), findsNothing);
    // The time is spelled out under the arc, where the node is too small.
    expect(find.textContaining('Japji Sahib · '), findsOneWidget);
  });

  testWidgets('a goal with no time is listed under the curve, not dropped',
      (tester) async {
    await addGoal('g1', 'JAPJ', '05:30');
    await addGoal('g2', 'SOHL', null, times: 2);
    await pump(tester);
    expect(find.byType(DayArc), findsOneWidget);
    // "0 of 2" on a chip: it still has to be countable.
    expect(find.textContaining('Kirtan Sohila · '), findsOneWidget);
  });

  testWidgets('goals with no times at all still report progress', (tester) async {
    await addGoal('g1', 'JAPJ', null);
    final l = await pump(tester);
    expect(find.byType(DayArc), findsNothing);
    expect(find.text(l.goalsSubtitle(0, 1)), findsOneWidget);
    expect(find.text(l.goalsEmptyTitle), findsNothing);
  });

  testWidgets('the Start Nitnem button survived the card change', (tester) async {
    await pump(tester);
    // The CTA used to live inside the arc card; losing it with the arc would
    // have taken Start Nitnem off Today entirely.
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.byType(DayArc), findsNothing);
  });
}
