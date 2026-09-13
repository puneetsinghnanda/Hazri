import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/audio/data/audio_handler.dart';
import 'package:just_audio/just_audio.dart';

/// What the media session reports to Android.
///
/// Android puts controls on the lock screen for a session that says it is
/// playing and offers the matching actions. Getting this mapping wrong is
/// invisible in the app itself -- the paath still plays -- so it is asserted
/// here rather than discovered on a locked phone.
void main() {
  PlaybackState state({
    bool playing = true,
    ProcessingState processing = ProcessingState.ready,
    double speed = 1.0,
    int? queueIndex = 0,
  }) =>
      HazriAudioHandler.buildPlaybackState(
        playing: playing,
        processingState: processing,
        position: const Duration(seconds: 12),
        bufferedPosition: const Duration(seconds: 30),
        speed: speed,
        queueIndex: queueIndex,
      );

  test('reports playing, which is what puts controls on the lock screen', () {
    expect(state(playing: true).playing, isTrue);
    expect(state(playing: false).playing, isFalse);
  });

  test('offers play/pause to the system, not only in the notification', () {
    final actions = state().systemActions;
    expect(actions, contains(MediaAction.playPause));
    expect(actions, contains(MediaAction.play));
    expect(actions, contains(MediaAction.pause));
  });

  test('offers seeking and skipping, for Bluetooth and car controls', () {
    final actions = state().systemActions;
    expect(actions, contains(MediaAction.seek));
    expect(actions, contains(MediaAction.skipToNext));
    expect(actions, contains(MediaAction.skipToPrevious));
  });

  test('shows pause while playing and play while paused', () {
    expect(
      state(playing: true).controls.map((c) => c.action),
      contains(MediaAction.pause),
    );
    expect(
      state(playing: false).controls.map((c) => c.action),
      contains(MediaAction.play),
    );
  });

  test('the compact view keeps rewind, play/pause and forward', () {
    final s = state();
    expect(s.androidCompactActionIndices, [1, 2, 3]);
    final compact = [for (final i in s.androidCompactActionIndices!) s.controls[i].action];
    expect(compact, [MediaAction.rewind, MediaAction.pause, MediaAction.fastForward]);
  });

  test('maps every just_audio processing state', () {
    const expected = {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    };
    for (final entry in expected.entries) {
      expect(state(processing: entry.key).processingState, entry.value);
    }
  });

  test('carries the position, speed and queue index', () {
    final s = state(speed: 1.5, queueIndex: 2);
    expect(s.updatePosition, const Duration(seconds: 12));
    expect(s.bufferedPosition, const Duration(seconds: 30));
    expect(s.speed, 1.5);
    expect(s.queueIndex, 2);
  });
}
