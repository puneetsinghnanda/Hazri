import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/widgets/progress_ring.dart';
import 'package:hazri/features/simran/ui/anhad_ring.dart';
import 'package:hazri/features/simran/ui/simran_screen.dart';

import '../app_harness.dart';

/// Design 21, as it now stands: the countdown under the circle, the standing
/// wave inside it, and no sound picker.
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 9, 12, 6, 30),
    );
  });

  tearDown(() => app.dispose());

  Future<void> pump(WidgetTester tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(const SimranScreen()));
    await settle(tester);
  }

  testWidgets('the countdown sits below the ring, not inside it', (tester) async {
    await pump(tester);
    final l = await L.delegate.load(const Locale('en'));

    final ring = tester.getRect(find.byType(ProgressRing));
    final clock = tester.getRect(find.text('5:00'));
    expect(clock.top, greaterThan(ring.bottom),
        reason: 'the countdown belongs under the circle');
    expect(find.text(l.simranLeftOf('5:00')), findsOneWidget);
  });

  testWidgets('the wave fills the circle', (tester) async {
    await pump(tester);
    expect(find.byType(AnhadRing), findsOneWidget);
    // ਵਾਹਿਗੁਰੂ stays at the centre of it.
    expect(
      find.descendant(of: find.byType(AnhadRing), matching: find.text('ਵਾਹਿਗੁਰੂ')),
      findsOneWidget,
    );
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
