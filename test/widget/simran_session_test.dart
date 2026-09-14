import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/simran/data/simran_controller.dart';
import 'package:hazri/features/simran/ui/simran_screen.dart';

import '../app_harness.dart';

/// A Simran session belongs to the app, not to one instance of the screen.
///
/// Tapping the mini player opened a second Simran screen over the shell. That
/// screen had its own timer, starting at five minutes, while the recitation it
/// was reporting on carried on underneath — so the session appeared to reset
/// every time somebody looked at it.
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 9, 14, 6, 30),
    );
  });

  tearDown(() => app.dispose());

  testWidgets('a second Simran screen shows the session already running',
      (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(const SimranScreen()));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    await tester.tap(find.text(l.simranBegin));
    await tester.pump();
    await tester.pump(const Duration(seconds: 40));
    expect(app.container.read(simranSessionProvider).running, isTrue);

    // Build the screen again from scratch, which is what a push did.
    await tester.pumpWidget(app.wrap(const SimranScreen()));
    await tester.pump();

    // The countdown is short of five minutes, and the button is End rather
    // than Begin: the fresh screen found the running session.
    expect(find.text('5:00'), findsNothing);
    expect(find.text(l.simranEnd), findsOneWidget);
    expect(find.text(l.simranBegin), findsNothing);

    // And ending it from the second screen ends the one session there is.
    await tester.tap(find.text(l.simranEnd));
    await settle(tester);
    expect(app.container.read(simranSessionProvider).running, isFalse);
  });

  testWidgets('ending the session logs it and returns the screen to Begin',
      (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(const SimranScreen()));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    await tester.tap(find.text(l.simranBegin));
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    await tester.tap(find.text(l.simranEnd));
    await settle(tester);

    expect(app.container.read(simranSessionProvider).running, isFalse);
    expect(find.text('5:00'), findsOneWidget);
  });
}
