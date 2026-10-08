import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/today/ui/today_screen.dart';

import '../app_harness.dart';

/// 05-today §5.5: the app bar, the streak card and elder mode.
void main() {
  late L l;
  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  Future<TestApp> pump(WidgetTester tester, {bool elder = false, int nitnemDays = 0}) async {
    final app = await TestApp.create(
      prefs: {'onboarding_done': true, if (elder) 'elder_mode': true},
      now: DateTime(2026, 10, 8, 9),
    );
    addTearDown(app.dispose);
    final repo = app.container.read(userRepositoryProvider);
    final clock = app.container.read(clockProvider) as FixedClock;
    for (var i = nitnemDays - 1; i >= 0; i--) {
      clock.instant = DateTime(2026, 10, 8 - i, 6);
      await repo.logCompletion(baniId: 'JAPJ', slot: BaniSlotValue.morning, source: CompletionSource.reader);
    }
    clock.instant = DateTime(2026, 10, 8, 9);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const TodayScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await settle(tester);
    return app;
  }

  testWidgets('T11: the band carries Hazri and the greeting', (tester) async {
    await pump(tester);
    expect(find.text(l.appBarTitle), findsOneWidget);
    expect(find.text(l.profileWelcome), findsOneWidget);
    expect(find.byTooltip(l.profileTitle), findsOneWidget);
  });

  testWidgets('T-t: twelve days of Nitnem → the streak card says 12', (tester) async {
    await pump(tester, nitnemDays: 12);
    expect(find.text(l.todayStreakDays(12)), findsOneWidget);
    expect(find.text(l.todayStreakCaption), findsOneWidget);
  });

  testWidgets('T-v: under two days → no streak card, nothing said', (tester) async {
    await pump(tester, nitnemDays: 1);
    expect(find.text(l.todayStreakCaption), findsNothing);
  });

  testWidgets('T-m: elder mode is the same tree — hazri and the goal card stay', (tester) async {
    await pump(tester, elder: true);
    expect(find.text(l.appBarTitle), findsOneWidget);
    expect(find.text(l.goalSetCardTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('lays out at 390×844 ${dark ? 'dark' : 'light'}', (tester) async {
      final app = await TestApp.create(prefs: {'onboarding_done': true});
      addTearDown(app.dispose);
      usePhoneFrame(tester);
      await tester.pumpWidget(app.wrapRouted(const TodayScreen(), dark: dark));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
