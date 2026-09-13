import 'package:flutter/foundation.dart';

/// One bani queued for playback.
@immutable
class PaathTrack {
  const PaathTrack({
    required this.baniId,
    required this.slug,
    required this.title,
    required this.nativeTitle,
    required this.assetPath,
    required this.duration,
  });

  final String baniId;
  final String slug;
  final String title;
  final String nativeTitle;

  /// The bundled asset key, e.g. `assets/audio/japji-sahib.m4a`.
  final String assetPath;
  final Duration duration;
}

/// The commands the app issues to whatever is playing the paath.
///
/// The media session implements this; tests substitute a fake. Keeping the
/// surface this small is what makes "pressing play actually starts the
/// recitation" something a test can assert without an audio device.
abstract interface class PaathPlayer {
  /// The slug of the bani currently loaded, or null when nothing is.
  String? get currentSlug;

  /// True when a track is loaded and ready to play. A player with no source
  /// accepts `play()` and does nothing, which is the failure this exists to
  /// make visible.
  bool get isLoaded;

  bool get isPlaying;

  int get queueLength;

  /// The playhead. Available synchronously so it can be read during dispose,
  /// where provider access is no longer allowed.
  Duration get position;

  Future<void> setQueue(List<PaathTrack> tracks, {int startIndex, Duration? at});

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> setSpeed(double speed);
}
