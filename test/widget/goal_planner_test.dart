import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/features/goals/ui/goal_planner_screen.dart';

import '../app_harness.dart';

/// The goal as one page (04-goals §7.2, design 106): many paaths from one
/// screen, each once a day, each with its reminder on at its own time.
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 10, 19, 9, 30),
    );
  });

  tearDown(() => app.dispose());

  UserRepository repo() => app.container.read(userRepositoryProvider);

  /// The planner pushed over a home screen, as Today and the Goals screen
  /// push it, so Start pops back.
  Future<L> pump(WidgetTester tester) async {
    usePhoneFrame(tester);
    final router = GoRouter(
      initialLocation: '/goals/plan',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('home')),
          routes: [GoRoute(path: 'goals/plan', builder: (_, _) => const GoalPlannerScreen())],
        ),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: app.container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: HazriTheme.light(),
        routerConfig: router,
      ),
    ));
    await settle(tester);
    return L.delegate.load(const Locale('en'));
  }

  Future<void> tapPaath(WidgetTester tester, String name) async {
    final row = find.text(name);
    await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(row);
    await settle(tester);
  }

  testWidgets('every paath is on the day, Naam Simran first at 05:30', (tester) async {
    final l = await pump(tester);
    expect(find.text(l.goalPlanTitle), findsOneWidget);
    expect(find.text(l.goalPlanAmritVela.toUpperCase()), findsOneWidget);
    double y(Finder f) => tester.getTopLeft(f).dy;
    expect(y(find.textContaining(l.goalNaamSimran)), lessThan(y(find.text('Japji Sahib'))));
    expect(y(find.text('Japji Sahib')), lessThan(y(find.text('Jaap Sahib'))));
    // Nothing chosen and no goal: the button waits.
    await tester.tap(find.text(l.goalEditSave));
    await settle(tester);
    expect(await repo().activeGoal(), isNull);
  });

  testWidgets('two paaths from one page start one goal, reminders on at their own times', (tester) async {
    final l = await pump(tester);
    await tapPaath(tester, 'Japji Sahib');
    await tapPaath(tester, 'Jaap Sahib');
    expect(find.text(l.goalPlanStart(2)), findsOneWidget);
    await tester.tap(find.text(l.goalPlanStart(2)));
    await settle(tester);

    final items = await repo().itemsInScopeToday();
    expect(items.map((i) => (i.baniId, i.reminderTime, i.timesPerDay)).toSet(), {
      ('JAPJ', '06:00', 1),
      ('JAAP', '06:15', 1),
    });
    expect(items.every((i) => i.durationType == DurationType.everyDay), isTrue);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('opened on a goal, it shows it; taking a paath out asks first', (tester) async {
    await repo().addItem(const GoalItemSpec.bani('JAPJ'));
    await repo().addItem(const GoalItemSpec.bani('REHR'));
    final l = await pump(tester);
    expect(find.text(l.goalPlanSave(2)), findsOneWidget);

    await tapPaath(tester, 'Rehras Sahib');
    await tester.tap(find.text(l.goalPlanSave(1)));
    await settle(tester);
    expect(find.text(l.goalRemoveConfirmTitle('Rehras Sahib')), findsOneWidget);
    await tester.tap(find.text(l.goalRemove));
    await settle(tester);

    final items = await repo().itemsInScopeToday();
    expect(items.single.baniId, 'JAPJ');
  });
}
