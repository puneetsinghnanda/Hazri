import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart' show AudioTrackRow, BaniSlot;
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart' show BaniSlotValue, CompletionSource;
import '../../../core/db/user_repository.dart';
import '../../../core/settings/settings_controller.dart';
import '../../nitnem/domain/bani.dart';
import 'audio_handler.dart';

/// Set during bootstrap in `main.dart`. Null when the media session could not
/// start, so the app still runs as a text-only reader.
final audioHandlerProvider = Provider<HazriAudioHandler?>((ref) => null);

/// True when this build has any recitation at all.
final hasAudioProvider = Provider<bool>((ref) {
  final tracks = ref.watch(audioTracksProvider).value;
  return ref.watch(audioHandlerProvider) != null && (tracks?.isNotEmpty ?? false);
});

/// Whether a given bani can be played.
final baniHasAudioProvider = Provider.family<bool, String>((ref, baniId) {
  if (ref.watch(audioHandlerProvider) == null) return false;
  return (ref.watch(audioTracksProvider).value ?? const {}).containsKey(baniId);
});

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler?.playbackState ?? const Stream<PlaybackState>.empty();
});

/// The playhead, ticking while audio is loaded.
final positionProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler?.position ?? const Stream<Duration>.empty();
});

final currentMediaItemProvider = StreamProvider<MediaItem?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler?.mediaItem ?? const Stream<MediaItem?>.empty();
});

final sleepRemainingProvider = StreamProvider<Duration?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler?.sleepRemaining ?? const Stream<Duration?>.empty();
});

/// The slug of whatever is playing, so the reader knows if it is the bani on
/// screen.
final playingSlugProvider = Provider<String?>(
  (ref) => ref.watch(currentMediaItemProvider).value?.id,
);

final playbackControllerProvider = Provider<PlaybackController>(
  (ref) => PlaybackController(ref),
);

/// Starts banis playing and records what finished.
class PlaybackController {
  PlaybackController(this._ref) {
    final handler = _ref.read(audioHandlerProvider);
    // A bani reaching 95% counts as completed, whether the reader is open or
    // the phone is in a pocket (PRD 1.9).
    _completion = handler?.baniCompleted.listen(_logCompletion);
  }

  final Ref _ref;
  StreamSubscription<String>? _completion;

  Future<void> _logCompletion(String baniId) async {
    final banis = await _ref.read(contentRepositoryProvider).banis();
    final bani = banis.where((b) => b.id == baniId).firstOrNull;
    if (bani == null) return;
    final repo = _ref.read(userRepositoryProvider);
    await repo.logCompletion(
      baniId: bani.id,
      slot: switch (bani.defaultSlot) {
        BaniSlot.morning => BaniSlotValue.morning,
        BaniSlot.evening => BaniSlotValue.evening,
        BaniSlot.bedtime => BaniSlotValue.bedtime,
        BaniSlot.none => BaniSlotValue.none,
      },
      source: CompletionSource.listen,
    );
    await repo.creditGoalsFor(bani.id);
  }

  PaathTrack? _trackFor(Bani bani, Map<String, AudioTrackRow> tracks, String language) {
    final row = tracks[bani.id];
    if (row == null) return null;
    return PaathTrack(
      baniId: bani.id,
      slug: bani.slug,
      title: bani.name(language),
      nativeTitle: bani.nativeName,
      assetPath: 'assets/audio/${row.file}',
      duration: Duration(milliseconds: row.durationMs ?? 0),
    );
  }

  /// Plays one bani, optionally from a position.
  Future<bool> playBani(Bani bani, {Duration? at, required String language}) async {
    final handler = _ref.read(audioHandlerProvider);
    if (handler == null) return false;
    final tracks = await _ref.read(audioTracksProvider.future);
    final track = _trackFor(bani, tracks, language);
    if (track == null) return false;

    if (handler.currentTrack?.slug != bani.slug || handler.tracks.length != 1) {
      await handler.setQueue([track], at: at);
    } else if (at != null) {
      await handler.seek(at);
    }
    await handler.setSpeed(_ref.read(settingsProvider).speed);
    await handler.play();
    return true;
  }

  /// Queues every bani in a slot that has audio and starts the first
  /// (PRD 1.7, "Play all").
  Future<bool> playSlot(BaniSlot slot, {required String language}) async {
    final handler = _ref.read(audioHandlerProvider);
    if (handler == null) return false;
    final banis = await _ref.read(contentRepositoryProvider).banis();
    final tracks = await _ref.read(audioTracksProvider.future);
    final queue = <PaathTrack>[
      for (final b in banis)
        if (b.defaultSlot == slot)
          if (_trackFor(b, tracks, language) case final t?) t,
    ];
    if (queue.isEmpty) return false;
    await handler.setQueue(queue);
    await handler.setSpeed(_ref.read(settingsProvider).speed);
    await handler.play();
    return true;
  }

  Future<void> togglePlayPause() async {
    final handler = _ref.read(audioHandlerProvider);
    if (handler == null) return;
    handler.playbackState.value.playing ? await handler.pause() : await handler.play();
  }

  /// Flips between normal pace and 1.5x, and remembers the choice.
  Future<double> toggleSpeed() async {
    final settings = _ref.read(settingsProvider);
    final next = settings.speed >= 1.5 ? 1.0 : 1.5;
    await _ref.read(settingsProvider.notifier).setSpeed(next);
    await _ref.read(audioHandlerProvider)?.setSpeed(next);
    return next;
  }

  Future<void> setSpeed(double speed) async {
    await _ref.read(settingsProvider.notifier).setSpeed(speed);
    await _ref.read(audioHandlerProvider)?.setSpeed(speed);
  }

  void dispose() => _completion?.cancel();
}

/// Which line of the open bani is being recited, and which word.
@immutable
class FollowState {
  const FollowState({this.lineIdx = -1, this.wordIdx = -1, this.attached = true});

  /// The line's `idx`, or -1 when nothing is playing for this bani.
  final int lineIdx;
  final int wordIdx;

  /// False once the reader has been scrolled by hand (PRD 1.6).
  final bool attached;

  bool get isFollowing => lineIdx >= 0;

  FollowState copyWith({int? lineIdx, int? wordIdx, bool? attached}) => FollowState(
    lineIdx: lineIdx ?? this.lineIdx,
    wordIdx: wordIdx ?? this.wordIdx,
    attached: attached ?? this.attached,
  );
}
