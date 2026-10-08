import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/badges/data/badge_controller.dart';
import 'package:hazri/features/badges/domain/badges.dart';
import 'package:hazri/features/badges/ui/badges_screen.dart';

import '../app_harness.dart';

/// 12-badges UI2 and UI4 (B-16b, B-16c).
void main() {
  late L l;
  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  testWidgets('B-16b: four earned in colour with dates; six greyed with "Not yet"', (tester) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    await app.container.read(badgeStoreProvider).insertNew(
      {BadgeId.jigyasu, BadgeId.shardhalu, BadgeId.abhyasi, BadgeId.nitnemi},
      today: '2026-10-08',
      silent: true,
    );
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const BadgesScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await settle(tester);
    expect(find.text(l.badgesTitle), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Vichari'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text(l.badgeNotYet), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('B-16c: a greyed badge opens its page with how it is earned and no meter', (tester) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const BadgeDetailScreen(badgeId: 'VICHARI')));
    await settle(tester);
    expect(find.text(l.badgeNumber(10)), findsOneWidget);
    expect(find.text(l.badgeHowVichari), findsOneWidget);
    expect(find.text(l.badgeNotYet), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('NITNEMI\'s rule names the five morning banis from content.db', (tester) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const BadgeDetailScreen(badgeId: 'NITNEMI')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await settle(tester);
    expect(find.textContaining('Japji Sahib'), findsOneWidget);
    expect(find.textContaining('Anand Sahib'), findsOneWidget);
  });
}
