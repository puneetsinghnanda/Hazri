import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/db/content_repository.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/settings/settings_controller.dart';
import '../../audio/data/audio_controller.dart';
import '../../sangat/data/presence_repository.dart';

/// A Simran session in progress (PRD 1.13).
class SimranSession {
  const SimranSession({
    this.runningSince,
    this.banked = Duration.zero,
    this.elapsed = Duration.zero,
    this.total = Duration.zero,
    this.active = false,
    this.justCompleted = false,
  });

  /// When the current run began, or null while paused.
  ///
  /// The running part of a session is anchored to an instant rather than to a
  /// tick count, so locking the phone or leaving the app does not lose time.
  final DateTime? runningSince;

  /// Time from the runs before this one. A pause banks what had passed and
  /// clears [runningSince]; resuming starts a fresh instant on top of it.
  final Duration banked;

  /// How much of the sitting has passed, recomputed four times a second.
  final Duration elapsed;

  /// The length chosen for *this* sitting.
  ///
  /// Held on the session rather than read from settings each time it is
  /// wanted: a simran goal of eleven minutes has to survive the whole sitting,
  /// and reading the five-minute default at the end capped every goal-length
  /// sitting back to five.
  final Duration total;

  /// A sitting is open — running or paused.
  final bool active;

  /// Set on the one state that ends a session that ran its full length, so
  /// the screen can say so even though the timer finished without it.
  final bool justCompleted;

  bool get running => active && runningSince != null;

  bool get paused => active && runningSince == null;

  Duration get remaining {
    final left = total - elapsed;
    return left.isNegative ? Duration.zero : left;
  }
}

final simranSessionProvider =
    NotifierProvider<SimranController, SimranSession>(SimranController.new);

/// Owns the running session.
///
/// It lives above the screen rather than inside it, because the screen is not
/// the only thing that can be on top: tapping the mini player, following a
/// reminder or switching tabs all build a fresh [SimranScreen], and a timer
/// held in that widget's state restarted at five minutes each time while the
/// recitation carried on underneath it.
class SimranController extends Notifier<SimranSession> {
  Timer? _ticker;
  bool _logged = false;

  /// The length a fresh sitting would be, when nothing has asked for one.
  ///
  /// A sitting that is already open carries its own length on the session.
  Duration get defaultTotal =>
      Duration(minutes: ref.read(settingsProvider).simranMinutes);

  @override
  SimranSession build() {
    ref.onDispose(() => _ticker?.cancel());
    return const SimranSession();
  }

  /// Begins a sitting of [length], or of the length in Settings.
  ///
  /// [length] is what makes a simran goal mean anything: the goal carries the
  /// minutes somebody chose for it, and starting from the goal used to hand
  /// the screen's five-minute default to the timer regardless.
  Future<void> start({required String title, Duration? length}) async {
    if (state.active) return;
    _logged = false;
    state = SimranSession(
      runningSince: DateTime.now(),
      total: length ?? defaultTotal,
      active: true,
    );
    unawaited(WakelockPlus.enable());
    // Before the audio, not after it. Loading a five-minute recitation and
    // bringing up the media session takes fifteen or twenty seconds on a
    // real phone, and the ticker used to be created at the end of all that:
    // the countdown sat at its full length until somebody paused and
    // resumed, which created it by another route. The sitting begins when
    // the person taps, so the clock begins then too.
    _start();

    final track = await ref.read(simranTrackProvider.future);
    if (track != null && state.running) {
      await ref.read(playbackControllerProvider).playSimran(track, title: title);
    }
  }

  /// Holds the sitting where it is: the clock stops and so does the
  /// recitation.
  ///
  /// Ending was the only way out, which made a knock at the door cost
  /// somebody their sitting. What is banked here is real time already sat,
  /// and it is what gets logged if they end from a pause rather than resume.
  void pause() {
    final since = state.runningSince;
    if (since == null) return;
    _ticker?.cancel();
    _ticker = null;
    final banked = state.banked + DateTime.now().difference(since);
    state = SimranSession(
      banked: banked,
      elapsed: banked,
      total: state.total,
      active: true,
    );
    unawaited(ref.read(paathPlayerProvider)?.pause() ?? Future<void>.value());
    unawaited(WakelockPlus.disable());
  }

  void resume() {
    if (!state.paused) return;
    state = SimranSession(
      runningSince: DateTime.now(),
      banked: state.banked,
      elapsed: state.elapsed,
      total: state.total,
      active: true,
    );
    unawaited(WakelockPlus.enable());
    unawaited(ref.read(paathPlayerProvider)?.play() ?? Future<void>.value());
    _start();
  }

  void _start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
  }

  /// Recomputes from the start instant rather than trusting the ticker, so a
  /// session resumed after a lock is at the right place.
  void tick() {
    final since = state.runningSince;
    if (since == null) return;
    final elapsed = state.banked + DateTime.now().difference(since);
    if (elapsed >= state.total) {
      unawaited(finish(completed: true));
      return;
    }
    state = SimranSession(
      runningSince: since,
      banked: state.banked,
      elapsed: elapsed,
      total: state.total,
      active: true,
    );
  }

  /// Ends the session, logging what was actually sat through.
  ///
  /// Returns true when it ran to the end, which is the screen's cue to say so.
  Future<bool> finish({required bool completed}) async {
    if (_logged) return false;
    _logged = true;
    _ticker?.cancel();
    _ticker = null;

    final since = state.runningSince;
    final total = state.total;
    final elapsed = state.banked +
        (since == null ? Duration.zero : DateTime.now().difference(since));
    final capped = elapsed > total ? total : elapsed;
    state = SimranSession(justCompleted: completed);

    await ref.read(userRepositoryProvider).logSimran(
          duration: capped,
          count: 0,
          completed: completed,
        );
    await ref.read(paathPlayerProvider)?.stop();
    // The globe counts sittings that happened, not screens that were opened,
    // so this is here and not in `start`. It is also the only thing simran
    // sends anywhere, and only for somebody who joined the sangat: the
    // repository is the no-op one for everybody else.
    if (completed) unawaited(_markOnTheGlobe());
    if (completed) await HapticFeedback.mediumImpact();
    await WakelockPlus.disable();
    return completed;
  }

  /// Adds this sitting to today's count for the city the person chose.
  ///
  /// Never awaited and never allowed to fail loudly: a globe that did not get
  /// the news is not a reason for somebody's simran to end in an error.
  Future<void> _markOnTheGlobe() async {
    final cityId = ref.read(settingsProvider).cityId;
    final city = (await ref.read(citiesProvider.future))
        .where((c) => c.id == cityId)
        .firstOrNull;
    if (city == null) return;
    await ref.read(presenceRepositoryProvider).markSitting(
          cityId: city.id,
          cityName: city.nameEn,
          lat: city.lat,
          lon: city.lon,
        );
    // And read the globe again, so the sitting just added appears on it.
    ref.invalidate(simranPresenceProvider);
  }
}
