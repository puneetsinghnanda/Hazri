import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hazri/app/router.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/diary/ui/diary_day_screen.dart';
import 'package:hazri/features/diary/ui/diary_screen.dart';

import '../app_harness.dart';

/// Design 56 is a screen, not a sheet.
///
/// It was a modal bottom sheet for three rounds of review. On a 390 x 844
/// phone that sheet cut the day's stats and the note off the bottom, and the
/// bottom nav — which design 56 draws under it — was behind a scrim.
void main() {
  late TestApp app;
  final today = DateTime(2026, 9, 18);

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 9, 18, 6, 30),
    );
  });

  tearDown(() => app.dispose());

  /// A once-a-day Japji goal that started on [from], the way the add-goal
  /// sheet writes one.
  Future<void> addJapjiGoal({DateTime? from}) =>
      app.container.read(userRepositoryProvider).saveGoal(GoalsCompanion.insert(
            id: 'goal-japji',
            baniId: 'JAPJ',
            durationType: GoalDuration.everyDay,
            startDate: localDateKey(from ?? today),
            createdAt: DateTime.utc(2026, 9, 1),
            updatedAt: DateTime.utc(2026, 9, 1),
          ));

  /// The Diary branch, exactly as `router.dart` nests it.
  Widget diaryApp({
    String at = Routes.diary,
    Locale locale = const Locale('en'),
    bool dark = false,
  }) =>
      UncontrolledProviderScope(
        container: app.container,
        child: MaterialApp.router(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: dark ? HazriTheme.dark() : HazriTheme.light(),
          routerConfig: GoRouter(
            initialLocation: at,
            routes: [
              GoRoute(
                path: Routes.diary,
                builder: (_, _) => const DiaryScreen(),
                routes: [
                  GoRoute(
                    path: ':date',
                    builder: (_, state) => DiaryDayScreen(
                      date: DateTime.parse(state.pathParameters['date']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  testWidgets('a day opens as a pushed screen, not a bottom sheet',
      (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(diaryApp());
    await settle(tester);

    // The 18th, in the month grid.
    await tester.tap(find.text('18'));
    await settle(tester);

    expect(find.byType(DiaryDayScreen), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    final l = await L.delegate.load(const Locale('en'));
    expect(find.text(l.diaryHazriAndGoals.toUpperCase()), findsOneWidget);
  });

  testWidgets('it carries the day: banner, hazri and goals, stats and the note',
      (tester) async {
    await addJapjiGoal();
    usePhoneFrame(tester);
    await tester.pumpWidget(diaryApp(at: Routes.diaryDay(today)));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    expect(find.text(l.hazriNotYet), findsOneWidget);
    expect(find.text(l.diaryHazriAndGoals.toUpperCase()), findsOneWidget);
    // The hazri row, then the one goal.
    expect(find.text(l.diaryHazriDot), findsOneWidget);
    expect(find.text('Japji Sahib'), findsOneWidget);
    expect(find.text(l.diaryStatGoalsMet), findsOneWidget);
    expect(find.text(l.nOfM(0, 1)), findsOneWidget);
    expect(find.text(l.diaryStatDaysInRow), findsOneWidget);
    expect(find.text(l.diaryHazriNote), findsOneWidget);
    // Nothing is ticked yet, so every row says so.
    expect(find.text(l.diaryNotYet), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the diary lists the goals, not every nitnem bani',
      (tester) async {
    await addJapjiGoal();
    usePhoneFrame(tester);
    await tester.pumpWidget(diaryApp(at: Routes.diaryDay(today)));
    await settle(tester);

    // Seven banis used to be listed here whether or not anybody had set
    // themselves one. Only the goal is now.
    expect(find.text('Japji Sahib'), findsOneWidget);
    expect(find.text('Rehras Sahib'), findsNothing);
    expect(find.text('Kirtan Sohila'), findsNothing);
    expect(find.text('Jaap Sahib'), findsNothing);
  });

  testWidgets('ticking a goal records the paath, credits the goal and marks '
      'the day', (tester) async {
    await addJapjiGoal();
    usePhoneFrame(tester);
    await tester.pumpWidget(diaryApp(at: Routes.diaryDay(today)));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    await tester.tap(find.text('Japji Sahib'));
    await settle(tester);

    final repo = app.container.read(userRepositoryProvider);
    final rows = await repo.completionsOn(today);
    expect(rows, hasLength(1));
    expect(rows.single.baniId, 'JAPJ');
    expect(rows.single.source, CompletionSource.manual);
    expect(await repo.goalTicksOn(today), hasLength(1));
    // And the banner turns over to design 56's kesri state.
    expect(find.text(l.hazriMarked), findsOneWidget);
    expect(find.text(l.nOfM(1, 1)), findsOneWidget);

    // Unticking takes both back, so the hazri does not stand on nothing.
    await tester.tap(find.text('Japji Sahib'));
    await settle(tester);
    expect(await repo.completionsOn(today), isEmpty);
    expect(await repo.goalTicksOn(today), isEmpty);
    expect(find.text(l.hazriNotYet), findsOneWidget);
  });

  testWidgets('the hazri can be marked by hand on a day with no goal',
      (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(diaryApp(at: Routes.diaryDay(today)));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    // No goal, so the card offers to set one rather than listing banis.
    expect(find.text(l.goalsEmptyTitle), findsOneWidget);

    await tester.tap(find.text(l.diaryHazriDot));
    await settle(tester);

    final repo = app.container.read(userRepositoryProvider);
    final rows = await repo.completionsOn(today);
    expect(rows, hasLength(1));
    expect(rows.single.baniId, kHazriMarkId);
    expect(find.text(l.hazriMarked), findsOneWidget);
    // Nothing named it, so the banner says when and not what with.
    expect(find.textContaining(', with '), findsNothing);

    await tester.tap(find.text(l.diaryHazriDot));
    await settle(tester);
    expect(await repo.completionsOn(today), isEmpty);
  });

  testWidgets('a hazri marked by a real paath is shown, not offered',
      (tester) async {
    final repo = app.container.read(userRepositoryProvider);
    await repo.logCompletion(
      baniId: 'JAPJ',
      slot: BaniSlotValue.morning,
      source: CompletionSource.read,
    );
    usePhoneFrame(tester);
    await tester.pumpWidget(diaryApp(at: Routes.diaryDay(today)));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    expect(find.text(l.hazriMarked), findsOneWidget);
    await tester.tap(find.text(l.diaryHazriDot));
    await settle(tester);
    // Tapping the row cannot delete the paath that marked the day.
    expect(await repo.completionsOn(today), hasLength(1));
  });

  testWidgets('a day older than a week opens read-only rather than refusing',
      (tester) async {
    await addJapjiGoal(from: DateTime(2026, 8, 1));
    usePhoneFrame(tester);
    await tester.pumpWidget(
        diaryApp(at: Routes.diaryDay(DateTime(2026, 9, 1))));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    expect(find.byType(DiaryDayScreen), findsOneWidget);
    expect(find.text(l.diaryTickTooOld), findsOneWidget);

    await tester.tap(find.text('Japji Sahib'));
    await tester.tap(find.text(l.diaryHazriDot));
    await settle(tester);
    final rows = await app.container
        .read(userRepositoryProvider)
        .completionsOn(DateTime(2026, 9, 1));
    expect(rows, isEmpty);
  });

  for (final locale in [Locale('en'), Locale('pa'), Locale('hi')]) {
    for (final dark in [false, true]) {
      testWidgets(
          'lays out on a 390 x 844 phone in '
          '${locale.languageCode}/${dark ? 'dark' : 'light'}', (tester) async {
        usePhoneFrame(tester);
        await tester.pumpWidget(
          diaryApp(at: Routes.diaryDay(today), locale: locale, dark: dark),
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
