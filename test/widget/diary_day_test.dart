import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hazri/app/router.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
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
    expect(find.text(l.diaryWhatYouDid.toUpperCase()), findsOneWidget);
  });

  testWidgets('it carries design 56: banner, ticks, stats and the note',
      (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(diaryApp(at: Routes.diaryDay(today)));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    expect(find.text(l.hazriNotYet), findsOneWidget);
    expect(find.text(l.diaryWhatYouDid.toUpperCase()), findsOneWidget);
    expect(find.text(l.diaryStatPaath), findsOneWidget);
    expect(find.text(l.diaryStatSimranMinutes), findsOneWidget);
    expect(find.text(l.diaryStatDaysInRow), findsOneWidget);
    expect(find.text(l.diaryHazriNote), findsOneWidget);
    // Nothing is ticked yet, so every row says so.
    expect(find.text(l.diaryNotYet), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ticking a bani writes it and marks the day', (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(diaryApp(at: Routes.diaryDay(today)));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    await tester.tap(find.text('Japji Sahib'));
    await settle(tester);

    final repo = app.container.read(userRepositoryProvider);
    final rows = await repo.completionsOn(today);
    expect(rows, hasLength(1));
    expect(rows.single.source, CompletionSource.manual);
    // And the banner turns over to design 56's kesri state.
    expect(find.text(l.hazriMarked), findsOneWidget);
  });

  testWidgets('a day older than a week opens read-only rather than refusing',
      (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(
        diaryApp(at: Routes.diaryDay(DateTime(2026, 9, 1))));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    expect(find.byType(DiaryDayScreen), findsOneWidget);
    expect(find.text(l.diaryTickTooOld), findsOneWidget);

    await tester.tap(find.text('Japji Sahib'));
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
