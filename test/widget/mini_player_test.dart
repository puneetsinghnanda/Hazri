import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/audio/data/audio_controller.dart';
import 'package:hazri/features/audio/ui/mini_player.dart';

import '../app_harness.dart';

/// Leaving the reader does not stop the paath, so something has to say so.
///
/// Without this strip the only sign a recitation is still going is the sound,
/// and the only way to pause it is to find the bani again in Nitnem.
void main() {
  late TestApp app;
  late FakePaathPlayer player;

  const item = MediaItem(
    id: 'japji-sahib',
    title: 'Japji Sahib',
    album: 'ਜਪੁ ਜੀ ਸਾਹਿਬ',
    duration: Duration(minutes: 19),
  );

  Future<void> pump(
    WidgetTester tester, {
    MediaItem? playingItem,
    bool playing = true,
    AudioProcessingState processing = AudioProcessingState.ready,
  }) async {
    player = FakePaathPlayer();
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      extra: [
        paathPlayerProvider.overrideWithValue(player),
        currentMediaItemProvider.overrideWith(
          (ref) => Stream.value(playingItem),
        ),
        playbackStateProvider.overrideWith(
          (ref) => Stream.value(
            PlaybackState(playing: playing, processingState: processing),
          ),
        ),
        positionProvider.overrideWith(
          (ref) => Stream.value(const Duration(minutes: 2, seconds: 4)),
        ),
      ],
    );
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(
      const Scaffold(bottomNavigationBar: MiniPlayer()),
    ));
    await settle(tester);
  }

  tearDown(() => app.dispose());

  testWidgets('stays out of the way when nothing is loaded', (tester) async {
    await pump(tester, playingItem: null);
    expect(find.text('Japji Sahib'), findsNothing);
  });

  testWidgets('names the bani and how far in it is', (tester) async {
    await pump(tester, playingItem: item);
    expect(find.text('Japji Sahib'), findsOneWidget);
    expect(find.text('2:04 / 19:00'), findsOneWidget);
  });

  testWidgets('pauses without going back to the reader', (tester) async {
    await pump(tester, playingItem: item);
    final l = await L.delegate.load(const Locale('en'));
    await tester.tap(find.bySemanticsLabel(l.actionPause));
    await tester.pump();
    expect(player.isPlaying, isFalse);
  });

  testWidgets('offers Resume, not Pause, when the paath is paused',
      (tester) async {
    await pump(tester, playingItem: item, playing: false);
    final l = await L.delegate.load(const Locale('en'));
    expect(find.bySemanticsLabel(l.actionResume), findsOneWidget);
    expect(find.bySemanticsLabel(l.actionPause), findsNothing);
  });

  testWidgets('stopping ends the paath', (tester) async {
    await pump(tester, playingItem: item);
    final l = await L.delegate.load(const Locale('en'));
    await tester.tap(find.bySemanticsLabel(l.actionStop));
    await tester.pump();
    expect(player.stopCalls, 1);
  });

  testWidgets('goes away once the paath has been stopped', (tester) async {
    await pump(
      tester,
      playingItem: item,
      playing: false,
      processing: AudioProcessingState.idle,
    );
    expect(find.text('Japji Sahib'), findsNothing);
  });
}
