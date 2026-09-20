import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/simran/ui/simran_screen.dart';

import '../app_harness.dart';

/// The Simran tab at rest, which is design 29's globe.
///
/// The ring, the countdown and the anhad wave are the *running* screen now,
/// and they are tested in `simran_session_test.dart`, which knows how to
/// start a session. They used to be tested here because the resting screen
/// and the running one were the same screen.
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 9, 12, 6, 30),
    );
  });

  tearDown(() => app.dispose());

  Future<L> pump(WidgetTester tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(const SimranScreen()));
    await settle(tester);
    return L.delegate.load(const Locale('en'));
  }

  testWidgets('the globe is the tab, with or without an account', (tester) async {
    // The first version of this showed the globe only to somebody who had
    // joined the sangat, so the great majority opened Simran and got the
    // Phase 1 screen. This harness has no account at all.
    final l = await pump(tester);
    expect(find.text(l.simranTurnGlobeShort), findsOneWidget);
    expect(find.text(l.simranGlobeFirst), findsOneWidget);
  });

  testWidgets('it offers the sitting, with its length on the button',
      (tester) async {
    final l = await pump(tester);
    expect(find.text(l.simranBeginMinutes(5)), findsOneWidget);
  });

  testWidgets('the sound picker is gone', (tester) async {
    await pump(tester);
    expect(find.text('Sound'), findsNothing);
    expect(find.text('Soft drone'), findsNothing);
    expect(find.text('Bell at the end'), findsNothing);
  });

  testWidgets('this build ships a recitation for the ring to follow',
      (tester) async {
    final track = await app.container.read(simranTrackProvider.future);
    expect(track, isNotNull);
    expect(track!.onsets, isNotEmpty);
    expect(track.assetPath, 'assets/audio/naam-simran.m4a');
  });
}
