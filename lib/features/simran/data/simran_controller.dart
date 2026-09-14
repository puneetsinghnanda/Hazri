import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/db/content_repository.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/settings/settings_controller.dart';
import '../../audio/data/audio_controller.dart';

/// A Simran session in progress (PRD 1.13).
class SimranSession {
  const SimranSession({
    this.startedAt,
    this.elapsed = Duration.zero,
    this.justCompleted = false,
  });

  /// When the session began, or null when none is running.
  ///
  /// The session is anchored to an instant rather than to a tick count, so
  /// locking the phone or leaving the app does not lose time.
  final DateTime? startedAt;

  /// How much of it has passed, recomputed from [startedAt] four times a
  /// second.
  final Duration elapsed;

  /// Set on the one state that ends a session that ran its full length, so
  /// the screen can say so even though the timer finished without it.
  final bool justCompleted;

  bool get running => startedAt != null;
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

  Duration get total => Duration(minutes: ref.read(settingsProvider).simranMinutes);

  @override
  SimranSession build() {
    ref.onDispose(() => _ticker?.cancel());
    return const SimranSession();
  }

  Future<void> start({required String title}) async {
    if (state.running) return;
    _logged = false;
    state = SimranSession(startedAt: DateTime.now());
    unawaited(WakelockPlus.enable());

    final track = await ref.read(simranTrackProvider.future);
    if (track != null && state.running) {
      await ref.read(playbackControllerProvider).playSimran(track, title: title);
    }
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
  }

  /// Recomputes from the start instant rather than trusting the ticker, so a
  /// session resumed after a lock is at the right place.
  void tick() {
    final started = state.startedAt;
    if (started == null) return;
    final elapsed = DateTime.now().difference(started);
    if (elapsed >= total) {
      unawaited(finish(completed: true));
      return;
    }
    state = SimranSession(startedAt: started, elapsed: elapsed);
  }

  /// Ends the session, logging what was actually sat through.
  ///
  /// Returns true when it ran to the end, which is the screen's cue to say so.
  Future<bool> finish({required bool completed}) async {
    if (_logged) return false;
    _logged = true;
    _ticker?.cancel();
    _ticker = null;

    final started = state.startedAt;
    final elapsed = started == null ? Duration.zero : DateTime.now().difference(started);
    final capped = elapsed > total ? total : elapsed;
    state = SimranSession(justCompleted: completed);

    await ref.read(userRepositoryProvider).logSimran(
          duration: capped,
          count: 0,
          completed: completed,
        );
    await ref.read(paathPlayerProvider)?.stop();
    if (completed) await HapticFeedback.mediumImpact();
    await WakelockPlus.disable();
    return completed;
  }
}
