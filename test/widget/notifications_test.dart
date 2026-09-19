import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/reminders/ui/notifications_screen.dart';

import '../app_harness.dart';

/// Design 50. The point of these tests is the split: what this phone can do
/// on its own, and what needs a server Phase 2 does not have.
void main() {
  Future<L> pump(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(
      app.wrapRouted(const NotificationsScreen(), locale: locale),
    );
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('the three groups are all named', (tester) async {
    final l = await pump(tester);
    expect(find.text(l.notifOwnPractice.toUpperCase()), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await settle(tester);
    expect(find.text(l.notifYourGroups.toUpperCase()), findsOneWidget);
  });

  testWidgets('group notifications are shown switched off and unavailable',
      (tester) async {
    final l = await pump(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await settle(tester);

    expect(find.text(l.notifGoalClose), findsOneWidget);
    // A dead switch, not a live one that does nothing: nobody should turn
    // this on and wonder for a week why nothing arrived.
    final switches = tester.widgetList<Switch>(find.byType(Switch));
    expect(switches.every((s) => s.onChanged == null), isTrue);
    expect(switches.every((s) => s.value == false), isTrue);
  });

  testWidgets('and the screen says why, rather than hiding them',
      (tester) async {
    final l = await pump(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await settle(tester);
    expect(find.text(l.notifGroupsNotYet), findsOneWidget);
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('lays out without overflowing in ${locale.languageCode}',
        (tester) async {
      await pump(tester, locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
