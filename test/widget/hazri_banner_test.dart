import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/settings/settings_controller.dart';
import 'package:hazri/features/today/ui/today_screen.dart';
import 'package:hazri/features/vichar/ui/vichar_card.dart';

import '../app_harness.dart';

/// Designs 58 and 59 on Today.
///
/// The hazri banner used to be hidden until somebody joined the sangat, so
/// that Today never carried two banners at once. That cost more than it
/// saved: the sangat is opt-in (rule 4), so the majority who never join saw
/// no hazri marker at all -- the one thing the app is named after. It is
/// shown to everybody now, and the join banner is the one that goes away.
void main() {
  late TestApp app;

  Future<L> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 11, 20, 9, 0),
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const TodayScreen(), locale: locale));
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('somebody who never joins the sangat still sees their hazri',
      (tester) async {
    // This is the whole point of the change. Hazri is on this phone: it needs
    // no account, no network and nobody else, and hiding it behind the sangat
    // hid it from most people who will ever use the app.
    final l = await pump(tester);
    expect(find.text(l.hazriNotYet), findsOneWidget);
  });

  testWidgets('and so does somebody who has', (tester) async {
    final l = await pump(tester);
    expect(find.text(l.sangatBannerTitle), findsNothing);
    expect(find.text(l.hazriNotYet), findsOneWidget);
  });

  testWidgets('a day with nothing done says "not yet", never "missed"',
      (tester) async {
    final l = await pump(tester);
    expect(find.text(l.hazriNotYet), findsOneWidget);
    expect(find.text(l.hazriHow), findsOneWidget);
  });

  testWidgets('one completed bani marks the hazri and says so', (tester) async {
    final l = await pump(tester);
    await app.container.read(userRepositoryProvider).logCompletion(
          baniId: 'japji',
          slot: BaniSlotValue.morning,
          source: CompletionSource.reader,
          on: DateTime(2026, 11, 20, 5, 52),
        );
    // drift's query and its watch both run on the real event loop, which the
    // fake clock in `settle` does not advance. Without this the widget is
    // rebuilt before the row exists.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
    expect(find.text(l.hazriMarked), findsOneWidget);
  });

  Future<void> markHazri(WidgetTester tester) async {
    await app.container.read(userRepositoryProvider).logCompletion(
          baniId: 'japji',
          slot: BaniSlotValue.morning,
          source: CompletionSource.reader,
          on: DateTime(2026, 11, 20, 5, 52),
        );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
  }

  testWidgets('T1a: a marked banner closes for the day and the cards move up', (tester) async {
    final l = await pump(tester);
    expect(find.byTooltip(l.actionClose), findsNothing, reason: 'never closed before it is marked');
    await markHazri(tester);
    final goalsBefore = tester.getTopLeft(find.byType(VicharCard)).dy;

    await tester.tap(find.byTooltip(l.actionClose));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    final midway = tester.getTopLeft(find.byType(VicharCard)).dy;
    await settle(tester);

    expect(find.text(l.hazriMarked), findsNothing);
    final goalsAfter = tester.getTopLeft(find.byType(VicharCard)).dy;
    expect(goalsAfter, lessThan(goalsBefore));
    expect(midway, inExclusiveRange(goalsAfter, goalsBefore), reason: 'it moves, not jumps');
    expect(app.container.read(sharedPreferencesProvider).getString('hazri_banner_closed_v1'), '2026-11-20');
  });

  testWidgets('T1a: closed yesterday, the banner is back today', (tester) async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true, 'hazri_banner_closed_v1': '2026-11-19'},
      now: DateTime(2026, 11, 20, 9, 0),
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const TodayScreen()));
    await settle(tester);
    await markHazri(tester);
    final l = await L.delegate.load(const Locale('en'));
    expect(find.text(l.hazriMarked), findsOneWidget);
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('the banner does not overflow in ${locale.languageCode}',
        (tester) async {
      await pump(tester, locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
