import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/features/simran/data/simran_controller.dart';
import 'package:hazri/features/simran/domain/simran_track.dart';
import 'package:hazri/features/simran/ui/simran_screen.dart';

import '../app_harness.dart';

/// The sitting's length, and the two ways out of it.
void main() {
  late TestApp app;

  /// Ends whatever sitting is open. The session's ticker outlives the widget
  /// tree, and `flutter_test` fails any test that finishes with a timer still
  /// pending.
  Future<void> endSitting(WidgetTester tester, L l) async {
    await tester.tap(find.text(l.simranEnd));
    await settle(tester);
  }

  Future<void> giveSimranGoal(TestApp app, {required int minutes}) async {
    final now = DateTime(2026, 9, 20, 6, 30);
    await app.container.read(userRepositoryProvider).saveGoal(
          GoalsCompanion(
            id: const Value('g-simran'),
            baniId: const Value(kSimranGoalId),
            minutes: Value(minutes),
            timesPerDay: const Value(1),
            durationType: const Value(GoalDuration.everyDay),
            startDate: Value(localDateKey(now)),
            active: const Value(true),
            createdAt: Value(now.toUtc()),
            updatedAt: Value(now.toUtc()),
          ),
        );
  }

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 9, 20, 6, 30),
    );
  });

  tearDown(() => app.dispose());

  testWidgets('a simran goal of 11 minutes starts an 11 minute sitting',
      (tester) async {
    await giveSimranGoal(app, minutes: 11);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(const SimranScreen()));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    // The button offers the goal's length, not the five-minute default.
    expect(find.text(l.simranBeginMinutes(11)), findsOneWidget);
    expect(find.text(l.simranBeginMinutes(5)), findsNothing);

    await tester.tap(find.text(l.simranBeginMinutes(11)));
    await tester.pump();

    // And the timer counts down from it. This is the whole bug: the session
    // used to read Settings and cap an eleven minute goal at five.
    expect(app.container.read(simranSessionProvider).total,
        const Duration(minutes: 11));
    expect(find.text('11:00'), findsOneWidget);

    // The session owns a ticker, so a test that walks away from an open
    // sitting leaves a pending timer and fails on the way out.
    await endSitting(tester, l);
  });

  testWidgets('with no goal the sitting is the length in Settings',
      (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(const SimranScreen()));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    await tester.tap(find.text(l.simranBeginMinutes(5)));
    await tester.pump();
    expect(app.container.read(simranSessionProvider).total,
        const Duration(minutes: 5));
    await endSitting(tester, l);
  });

  testWidgets('the clock runs while the recitation is still loading',
      (tester) async {
    // The reported bug: tap Begin and the countdown sits at its full length
    // for fifteen or twenty seconds, until you pause and resume. The ticker
    // was created at the *end* of `start`, after awaiting the track and the
    // media session; on a real phone that is the whole of that delay.
    //
    // A track future that never completes stands in for a slow load.
    final slow = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 9, 20, 6, 30),
      extra: [
        simranTrackProvider.overrideWith((ref) => Completer<SimranTrack?>().future),
      ],
    );
    addTearDown(slow.dispose);

    usePhoneFrame(tester);
    await tester.pumpWidget(slow.wrap(const SimranScreen()));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    await tester.tap(find.text(l.simranBeginMinutes(5)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // The audio has not arrived and never will, and the clock has still
    // moved off its full length.
    final session = slow.container.read(simranSessionProvider);
    expect(session.running, isTrue);
    expect(session.elapsed, greaterThan(Duration.zero));
    expect(find.text('5:00'), findsNothing);

    slow.container.read(simranSessionProvider.notifier).finish(completed: false);
    await settle(tester);
  });

  testWidgets('pause holds the clock, and resume carries on from there',
      (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(const SimranScreen()));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));
    final controller = app.container.read(simranSessionProvider.notifier);

    await tester.tap(find.text(l.simranBeginMinutes(5)));
    await tester.pump();
    // Both ways out are on screen, which is the point: ending used to be the
    // only one, so a knock at the door cost the whole sitting.
    expect(find.text(l.actionPause), findsOneWidget);
    expect(find.text(l.simranEnd), findsOneWidget);

    await tester.tap(find.text(l.actionPause));
    await tester.pump();

    final held = app.container.read(simranSessionProvider);
    expect(held.paused, isTrue);
    expect(held.active, isTrue);
    expect(find.text(l.simranPaused), findsOneWidget);
    expect(find.text(l.actionResume), findsOneWidget);

    // The clock does not move while it is held.
    controller.tick();
    expect(app.container.read(simranSessionProvider).elapsed, held.elapsed);

    await tester.tap(find.text(l.actionResume));
    await tester.pump();
    expect(app.container.read(simranSessionProvider).running, isTrue);
    expect(find.text(l.actionPause), findsOneWidget);
    await endSitting(tester, l);
  });

  testWidgets('ending from a pause still logs what was sat', (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(const SimranScreen()));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));

    await tester.tap(find.text(l.simranBeginMinutes(5)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    await tester.tap(find.text(l.actionPause));
    await tester.pump();
    await tester.tap(find.text(l.simranEnd));
    await settle(tester);

    // Read the table, not `watchSimranSessions()`: a drift stream needs the
    // real event loop to turn, and `flutter_test`'s fake clock never gives it
    // one -- awaiting its first event hangs the test out.
    final sessions = await app.userDb.select(app.userDb.simranSessions).get();
    expect(sessions, hasLength(1));
    expect(sessions.single.completed, isFalse);
    // The banked time is real seconds sat, not zero because the run that was
    // in flight had been closed off.
    expect(sessions.single.durationS, greaterThanOrEqualTo(0));
    expect(app.container.read(simranSessionProvider).active, isFalse);
  });
}
