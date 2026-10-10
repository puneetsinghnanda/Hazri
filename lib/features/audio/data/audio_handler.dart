import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/paath_player.dart';

export '../domain/paath_player.dart' show PaathTrack;

/// The single source of truth for playback (PRD §6.2).
///
/// It runs inside `audio_service`, so the paath keeps going when the app is
/// minimised or the phone is locked, and the notification and lock screen
/// drive the same player the reader is following.
class HazriAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements PaathPlayer {
  HazriAudioHandler(this._player);

  final AudioPlayer _player;

  /// Bani ids in queue order, so the UI can map a media item back to content.
  final List<PaathTrack> _tracks = [];

  /// Fires when a bani finishes, carrying its id, so a completion can be
  /// logged without the handler knowing about the database.
  final _completed = StreamController<String>.broadcast();

  Stream<String> get baniCompleted => _completed.stream;

  /// Set when a sleep timer is running.
  Timer? _sleepTimer;
  DateTime? _sleepEndsAt;
  final _sleepRemaining = StreamController<Duration?>.broadcast();

  Stream<Duration?> get sleepRemaining => _sleepRemaining.stream;

  DateTime? get sleepEndsAt => _sleepEndsAt;

  /// True once a bani has been reported complete, so the 95% rule fires once.
  final Set<int> _reportedComplete = {};

  /// The playhead, ticking. The synchronous [position] getter is the
  /// PaathPlayer one.
  Stream<Duration> get positionStream => _player.positionStream;

  AudioPlayer get player => _player;

  List<PaathTrack> get tracks => List.unmodifiable(_tracks);

  @override
  String? get currentSlug => currentTrack?.slug;

  @override
  bool get isLoaded =>
      _player.audioSource != null &&
      _player.processingState != ProcessingState.idle;

  @override
  bool get isPlaying => _player.playing;

  @override
  int get queueLength => _tracks.length;

  @override
  Duration get position => _player.position;

  PaathTrack? get currentTrack {
    final i = _player.currentIndex;
    return i != null && i >= 0 && i < _tracks.length ? _tracks[i] : null;
  }

  static Future<HazriAudioHandler> create() async {
    final player = AudioPlayer(handleInterruptions: false);
    final handler = await AudioService.init(
      builder: () => HazriAudioHandler(player),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'app.hazri.playback',
        androidNotificationChannelName: 'Playback',
        androidNotificationOngoing: true,
        // Swiping the app away stops playback and clears the notification
        // (PRD 1.8).
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'drawable/ic_notification',
      ),
    );
    await handler._writeArt();
    await handler._configureSession();
    return handler;
  }

  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    // A call or another app taking focus pauses the paath; a transient
    // notification ducks it (PRD 1.8).
    var wasPlayingBeforeInterruption = false;
    session.interruptionEventStream.listen((event) async {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            await _player.setVolume(0.3);
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            wasPlayingBeforeInterruption = _player.playing;
            await pause();
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            await _player.setVolume(1);
          case AudioInterruptionType.pause:
            if (wasPlayingBeforeInterruption) await play();
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });

    // Headphones unplugged or Bluetooth disconnected: pause, and never resume
    // onto the speaker (PRD 1.8).
    session.becomingNoisyEventStream.listen((_) => pause());

    // Every stream that can change what the media session should report.
    //
    // `playbackEventStream` alone is not enough: a PlaybackEvent carries the
    // processing state and position but not whether the player is playing, so
    // relying on it can leave the session reporting paused forever -- and
    // Android only puts controls on the lock screen for a session that says it
    // is playing.
    void publish() => playbackState.add(_currentState());

    _player.playbackEventStream.listen(
      (_) => publish(),
      onError: (Object e, StackTrace st) => debugPrint('Hazri audio: $e'),
    );
    _player.playingStream.listen((_) => publish());
    _player.speedStream.listen((_) => publish());
    _player.currentIndexStream.listen((_) => publish());
    _player.processingStateStream.listen((_) => publish());
    publish();

    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _tracks.length) {
        _saying = null; // a new bani: its own lines from here
        mediaItem.add(_mediaItemFor(_tracks[index]));
      }
    });

    // A bani counts as done once the track reaches 95% (PRD 1.9).
    _player.positionStream.listen((pos) {
      final index = _player.currentIndex;
      final total = _player.duration;
      if (index == null || total == null || total == Duration.zero) return;
      if (_reportedComplete.contains(index)) return;
      if (pos.inMilliseconds >= total.inMilliseconds * 0.95) {
        _reportedComplete.add(index);
        if (index < _tracks.length) _completed.add(_tracks[index].baniId);
      }
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _stopSleepTimer();
    });
  }

  PlaybackState _currentState() => buildPlaybackState(
    playing: _player.playing,
    processingState: _player.processingState,
    position: _player.position,
    bufferedPosition: _player.bufferedPosition,
    speed: _player.speed,
    queueIndex: _player.currentIndex,
  );

  /// Builds what the media session reports to Android.
  ///
  /// Pure, so the mapping that decides whether the lock screen shows controls
  /// can be tested without an audio device.
  static PlaybackState buildPlaybackState({
    required bool playing,
    required ProcessingState processingState,
    required Duration position,
    required Duration bufferedPosition,
    required double speed,
    int? queueIndex,
  }) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.skipToNext,
      ],
      // Named so the lock screen and Bluetooth controls offer them even when
      // they are not among the notification's own buttons.
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.playPause,
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.setSpeed,
      },
      androidCompactActionIndices: const [1, 2, 3],
      processingState: switch (processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: playing,
      updatePosition: position,
      bufferedPosition: bufferedPosition,
      speed: speed,
      queueIndex: queueIndex,
    );
  }

  /// The sunrise mark on Neela, as a file the media session can load
  /// (design 18). Null until written, and in tests.
  Uri? _art;

  /// The line being recited, from the timings (design 18's lock screen).
  String? _saying;

  MediaItem _mediaItemFor(PaathTrack t) => MediaItem(
    id: t.slug,
    title: t.title,
    // Android shows the title and the artist line: the bani, then the line
    // being recited, or before one is known "Morning Nitnem · 1 of 5" or the
    // Gurmukhi name (design 18).
    artist: _saying ?? t.subtitle ?? t.nativeTitle,
    album: t.nativeTitle,
    artUri: _art,
    duration: t.duration,
    extras: {'route': t.route},
  );

  /// Puts [line] under the bani's name in the notification and on the lock
  /// screen; null goes back to the subtitle. Only a change is published.
  void setSaying(String? line) {
    if (line == _saying) return;
    _saying = line;
    final t = currentTrack;
    if (t != null) mediaItem.add(_mediaItemFor(t));
  }

  /// Writes the artwork where the media session can read it.
  Future<void> _writeArt() async {
    try {
      final bytes = await rootBundle.load('assets/images/media_art.png');
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/media_art.png');
      if (!file.existsSync() || file.lengthSync() != bytes.lengthInBytes) {
        await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      }
      _art = Uri.file(file.path);
    } on Object catch (e) {
      // No artwork is a plainer notification, never a broken one.
      debugPrint('Hazri audio: no artwork ($e)');
    }
  }

  /// Loads a queue and parks it at [startIndex], without starting playback.
  @override
  Future<void> setQueue(List<PaathTrack> tracks, {int startIndex = 0, Duration? at}) async {
    _tracks
      ..clear()
      ..addAll(tracks);
    _saying = null;
    _reportedComplete.clear();
    queue.add([for (final t in tracks) _mediaItemFor(t)]);

    await _player.setAudioSource(
      ConcatenatingAudioSource(
        children: [for (final t in tracks) AudioSource.asset(t.assetPath)],
      ),
      initialIndex: startIndex,
      initialPosition: at ?? Duration.zero,
    );
    if (tracks.isNotEmpty) mediaItem.add(_mediaItemFor(tracks[startIndex]));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) => _player.seek(Duration.zero, index: index);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> rewind() => _nudge(const Duration(seconds: -10));

  @override
  Future<void> fastForward() => _nudge(const Duration(seconds: 10));

  Future<void> _nudge(Duration by) async {
    final target = _player.position + by;
    final max = _player.duration ?? Duration.zero;
    await _player.seek(target < Duration.zero
        ? Duration.zero
        : (target > max ? max : target));
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() async {
    _stopSleepTimer();
    await _player.stop();
    await super.stop();
  }

  /// Fades out and pauses after [after]. Passing null cancels.
  void setSleepTimer(Duration? after) {
    _stopSleepTimer();
    if (after == null) return;
    _sleepEndsAt = DateTime.now().add(after);
    _sleepRemaining.add(after);
    _sleepTimer = Timer(after, () async {
      // A five-second fade, so the paath does not stop mid-word (PRD 1.8).
      for (var i = 10; i >= 0; i--) {
        await _player.setVolume(i / 10);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      await pause();
      await _player.setVolume(1);
      _stopSleepTimer();
    });
  }

  void _stopSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepEndsAt = null;
    _sleepRemaining.add(null);
  }

  Future<void> dispose() async {
    _stopSleepTimer();
    await _completed.close();
    await _sleepRemaining.close();
    await _player.dispose();
  }
}
