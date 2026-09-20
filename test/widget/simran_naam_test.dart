import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/features/simran/domain/simran_track.dart';
import 'package:hazri/features/simran/ui/simran_naam.dart';

import '../app_harness.dart';

/// ਵਾਹਿਗੁਰੂ drifting off the globe.
///
/// It follows the recitation's own onsets, so it says nothing the recording
/// does not. The word itself is passed in and never composed here.
void main() {
  const word = 'ਵਾਹਿਗੁਰੂ';

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  /// How many words the painter has been handed.
  int alive(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(SimranNaam),
        matching: find.byType(CustomPaint),
      ),
    );
    return (paint.painter! as dynamic).words.length as int;
  }

  testWidgets('a word appears for each utterance the reciter has reached',
      (tester) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    final track = await app.container.read(simranTrackProvider.future);
    expect(track, isNotNull);
    expect(track!.onsets, isNotEmpty);

    await tester.pumpWidget(wrap(SimranNaam(
      size: 280,
      word: word,
      track: track,
      elapsed: const Duration(seconds: 60),
      running: true,
    )));
    await tester.pump(const Duration(milliseconds: 20));

    // Several utterances have passed by a minute in, but the catch-up is
    // capped: coming back from a locked screen must not throw a minute of
    // them into the air at once.
    expect(alive(tester), inInclusiveRange(1, 3));
  });

  testWidgets('and none at all without a recitation to follow',
      (tester) async {
    await tester.pumpWidget(wrap(const SimranNaam(
      size: 280,
      word: word,
      track: null,
      elapsed: Duration(seconds: 60),
      running: true,
    )));
    await tester.pump(const Duration(milliseconds: 20));
    // An invented rhythm would be the screen saying something it does not
    // know.
    expect(alive(tester), 0);
  });

  testWidgets('a paused sitting stops putting new words in the air',
      (tester) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    final track = await app.container.read(simranTrackProvider.future);

    await tester.pumpWidget(wrap(SimranNaam(
      size: 280,
      word: word,
      track: track,
      elapsed: const Duration(seconds: 30),
      running: false,
    )));
    await tester.pump(const Duration(milliseconds: 20));
    expect(alive(tester), 0);
  });

  testWidgets('it shows nothing when the system asks for less motion',
      (tester) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    final track = await app.container.read(simranTrackProvider.future);

    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(
            child: SimranNaam(
              size: 280,
              word: word,
              track: track,
              elapsed: const Duration(seconds: 60),
              running: true,
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 20));
    expect(
      find.descendant(
        of: find.byType(SimranNaam),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });

  test('the onsets are what the word follows, and there are plenty', () async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    final SimranTrack? track =
        await app.container.read(simranTrackProvider.future);
    expect(track!.onsets.length, greaterThan(100));
    // In order, so `onsetsBefore` can binary-search them.
    for (var i = 1; i < track.onsets.length; i++) {
      expect(track.onsets[i] >= track.onsets[i - 1], isTrue, reason: 'at $i');
    }
  });
}
