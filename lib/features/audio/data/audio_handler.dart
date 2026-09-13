import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

/// The single source of truth for playback (PRD §6.2).
///
/// It runs inside `audio_service`, so the paath keeps going when the app is
/// minimised or the phone is locked, and the notification and lock screen
/// drive the same player the reader is following.
class HazriAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
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

  Stream<Duration> get position => _player.positionStream;

  AudioPlayer get player => _player;

  List<PaathTrack> get tracks => List.unmodifiable(_tracks);

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

    _player.playbackEventStream.listen(
      (event) => playbackState.add(_transform(event)),
      onError: (Object e, StackTrace st) => debugPrint('Hazri audio: $e'),
    );

    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _tracks.length) {
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

  PlaybackState _transform(PlaybackEvent event) {
    final playing = _player.playing;
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek, MediaAction.setSpeed},
      androidCompactActionIndices: const [1, 2, 3],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  MediaItem _mediaItemFor(PaathTrack t) => MediaItem(
    id: t.slug,
    title: t.title,
    // The Gurmukhi name rides along as the album line, as the design shows in
    // the notification and on the lock screen (Design 18).
    album: t.nativeTitle,
    artist: 'Hazri',
    duration: t.duration,
  );

  /// Loads a queue and starts at [startIndex].
  ///
  /// Bundled assets cannot be read by the platform player directly, so each is
  /// copied into app storage once and played from there.
  Future<void> setQueue(List<PaathTrack> tracks, {int startIndex = 0, Duration? at}) async {
    _tracks
      ..clear()
      ..addAll(tracks);
    _reportedComplete.clear();
    queue.add([for (final t in tracks) _mediaItemFor(t)]);

    final sources = <AudioSource>[];
    for (final t in tracks) {
      sources.add(AudioSource.file(await _materialise(t.assetPath)));
    }
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: startIndex,
      initialPosition: at ?? Duration.zero,
    );
    if (tracks.isNotEmpty) mediaItem.add(_mediaItemFor(tracks[startIndex]));
  }

  static final Map<String, String> _materialised = {};

  Future<String> _materialise(String assetPath) async {
    final cached = _materialised[assetPath];
    if (cached != null) return cached;
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'audio', p.basename(assetPath)));
    if (!file.existsSync()) {
      await file.parent.create(recursive: true);
      final data = await rootBundle.load(assetPath);
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    _materialised[assetPath] = file.path;
    return file.path;
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
