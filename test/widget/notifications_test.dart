import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/reminders/data/notification_switches.dart';
import 'package:hazri/features/reminders/domain/reminder_plan.dart';
import 'package:hazri/features/reminders/ui/notifications_screen.dart';

import '../app_harness.dart';

/// The Notifications screen (02-notifications §6): one switch per kind, all
/// on by default; the Sangat switch only for a member.
void main() {
  late TestApp app;

  Future<L> pump(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(
      app.wrapRouted(const NotificationsScreen(), locale: locale),
    );
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('four kinds, each switched on; no Sangat switch without a group',
      (tester) async {
    final l = await pump(tester);
    expect(find.text(l.notifKindAmritVela), findsOneWidget);
    expect(find.text(l.notifKindGoals), findsOneWidget);
    expect(find.text(l.notifKindCalendar), findsOneWidget);
    expect(find.text(l.notifKindHazri), findsOneWidget);
    expect(find.text(l.notifKindSangat), findsNothing);
    final switches = tester.widgetList<Switch>(find.byType(Switch));
    expect(switches, hasLength(4));
    expect(switches.every((s) => s.value), isTrue);
  });

  testWidgets('turning a kind off is stored and re-plans without it', (tester) async {
    final l = await pump(tester);
    await tester.tap(find.descendant(
      of: find.ancestor(of: find.text(l.notifKindHazri), matching: find.byType(Row)).first,
      matching: find.byType(Switch),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
    expect(app.container.read(notificationSwitchesProvider).contains(NotificationKind.hazriNudge), isFalse);
    expect(app.reminders.scheduled.where((n) => n.kind == NotificationKind.hazriNudge), isEmpty);
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('lays out without overflowing in ${locale.languageCode}',
        (tester) async {
      await pump(tester, locale: locale);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('DP2: without exact alarms the screen asks for them, and the card goes once allowed',
      (tester) async {
    app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    app.reminders.exactAlarmsGranted = false;
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const NotificationsScreen()));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    expect(find.text(l.notifExactNote), findsOneWidget);
    await tester.tap(find.text(l.notifExactAllow));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);

    expect(app.reminders.exactRequests, 1);
    expect(find.text(l.notifExactAllow), findsNothing);
  });

  testWidgets('DP2: with exact alarms allowed nothing is asked', (tester) async {
    final l = await pump(tester);
    expect(find.text(l.notifExactAllow), findsNothing);
  });
}
