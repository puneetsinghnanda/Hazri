import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/backend/api_client.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/settings/settings_controller.dart';
import '../../audio/data/audio_controller.dart';
import '../../audio/domain/paath_player.dart';
import '../../profile/data/profile_controller.dart';
import '../domain/live_group.dart';

/// The three live groups as the server last told us (15-live-sangat LS7,
/// LS8, LS9), from the copy on the phone first, and whether that copy is
/// stale because the last refresh could not reach the server.
@immutable
class LiveView {
  const LiveView(this.groups, {this.offline = false});

  final Map<String, LiveGroupStatus> groups;
  final bool offline;

  LiveGroupStatus of(String id) => groups[id] ?? LiveGroupStatus(id: id);

  int get joinedCount => groups.values.where((g) => g.joined).length;
}

final liveStatusProvider = NotifierProvider<LiveStatusController, LiveView>(LiveStatusController.new);

class LiveStatusController extends Notifier<LiveView> {
  static const kCache = 'live_cache_v1';

  ApiClient get _api => ref.read(apiClientProvider);

  @override
  LiveView build() {
    final raw = ref.read(sharedPreferencesProvider).getString(kCache);
    if (raw == null) return const LiveView({}, offline: true);
    try {
      return LiveView(_parse(jsonDecode(raw) as Map<String, Object?>), offline: true);
    } on Object {
      return const LiveView({}, offline: true);
    }
  }

  static Map<String, LiveGroupStatus> _parse(Map<String, Object?> j) => {
        for (final g in (j['groups'] as List<Object?>? ?? const []).cast<Map<String, Object?>>())
          '${g['id']}': LiveGroupStatus.fromJson(g),
      };

  /// GET /live; offline, the copy stays and says it is waiting (LS7).
  Future<void> refresh() async {
    try {
      final body = await _api.get('/live');
      await ref.read(sharedPreferencesProvider).setString(kCache, jsonEncode(body));
      state = LiveView(_parse(body));
    } on NetworkException {
      state = LiveView(state.groups, offline: true);
    } on ApiException catch (e) {
      debugPrint('Hazri: live refused ($e)');
      state = LiveView(state.groups, offline: true);
    }
  }

  /// Join needs a profile (LS11); the server says NO_PROFILE otherwise.
  Future<void> join(String id) async {
    await _api.post('/live/$id/join');
    _set(id, joined: true);
    unawaited(refresh());
  }

  Future<void> leave(String id) async {
    await _api.post('/live/$id/leave');
    _set(id, joined: false);
    unawaited(refresh());
  }

  void _set(String id, {required bool joined}) {
    final g = state.of(id);
    state = LiveView({...state.groups, id: g.copyWith(joined: joined)}, offline: state.offline);
  }
}

/// When this phone last played each live group (`live_heard_v1`), so it
/// counts itself for a day (LS7b). Kept on the phone; never sent.
final liveHeardProvider = NotifierProvider<LiveHeard, Map<String, DateTime>>(LiveHeard.new);

class LiveHeard extends Notifier<Map<String, DateTime>> {
  static const key = 'live_heard_v1';

  @override
  Map<String, DateTime> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(key);
    if (raw == null) return const {};
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      return {
        for (final e in j.entries)
          if (DateTime.tryParse('${e.value}') case final at?) e.key: at,
      };
    } on Object {
      return const {};
    }
  }

  Future<void> heard(String groupId, DateTime at) async {
    state = {...state, groupId: at};
    await ref
        .read(sharedPreferencesProvider)
        .setString(key, jsonEncode({for (final e in state.entries) e.key: e.value.toIso8601String()}));
  }
}

/// Seconds listened per group, today and this month, counted on the phone
/// (LS7a).
final liveSecondsProvider = StreamProvider<Map<String, ({int today, int month})>>(
  (ref) => ref.watch(userRepositoryProvider).watchLiveSeconds(),
);

/// The live group playing now, or null.
final liveListenerProvider = NotifierProvider<LiveListener, String?>(LiveListener.new);

/// Plays a live group's loop and keeps its two counts: the seconds on the
/// phone (LS7a) and, with a profile, the listening mark every five minutes
/// (LS15). It lives above the page, so the counting goes on with the screen
/// locked and the page closed until the sound stops.
class LiveListener extends Notifier<String?> {
  static const tick = Duration(seconds: 15);
  static const markEvery = Duration(minutes: 5);

  Timer? _timer;
  DateTime? _lastTick;
  DateTime? _lastMark;

  @override
  String? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  PaathPlayer? get _player => ref.read(paathPlayerProvider);

  /// True while [id]'s loop is loaded and sounding.
  bool isPlaying(String id) {
    final p = _player;
    final def = liveGroupById(id);
    return p != null && def != null && p.isLooping && p.currentSlug == def.slug && p.isPlaying;
  }

  /// Starts [def]'s loop at the second every other phone is at (LS6).
  Future<void> listen(LiveGroupDef def, {required String title}) async {
    final player = _player;
    if (player == null) return;
    if (!(player.isLooping && player.currentSlug == def.slug)) {
      await player.setLoop(
        PaathTrack(
          baniId: def.slug,
          slug: def.slug,
          title: title,
          nativeTitle: def.gurmukhi,
          assetPath: def.assetPath,
          duration: def.length,
          route: Routes.live(def.id),
        ),
        at: liveOffset(DateTime.now(), def.length),
      );
      await player.setSpeed(1);
      _lastMark = null;
    } else {
      // Paused and resumed: back to where the sangat is now.
      await player.seek(liveOffset(DateTime.now(), def.length));
    }
    await player.play();
    state = def.id;
    await ref.read(liveHeardProvider.notifier).heard(def.id, DateTime.now());
    _lastTick = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(tick, (_) => unawaited(onTick()));
    final last = _lastMark;
    if (last == null || DateTime.now().difference(last) >= markEvery) unawaited(_mark(def.id));
  }

  Future<void> pause() async {
    await onTick();
    await _player?.pause();
  }

  /// Stops the sound and the counting.
  Future<void> stop() async {
    await onTick();
    _timer?.cancel();
    _timer = null;
    final p = _player;
    if (p != null && p.isLooping) await p.stop();
    state = null;
  }

  /// Banks what has played since the last tick and sends a mark when one is
  /// due. Public so a test can drive it without waiting.
  @visibleForTesting
  Future<void> onTick() async {
    final id = state;
    final now = DateTime.now();
    final since = _lastTick ?? now;
    _lastTick = now;
    if (id == null) return;
    final p = _player;
    final def = liveGroupById(id);
    if (p == null || def == null || !p.isLooping || p.currentSlug != def.slug) {
      // Something else took the player: a bani, or the end of a sitting.
      _timer?.cancel();
      _timer = null;
      state = null;
      return;
    }
    if (!p.isPlaying) return;
    final secs = now.difference(since).inSeconds.clamp(0, tick.inSeconds * 2);
    await ref.read(userRepositoryProvider).addLiveSeconds(id, secs);
    final last = _lastMark;
    if (last == null || now.difference(last) >= markEvery) await _mark(id);
  }

  /// POST /live/:id/listen, with a profile only (LS15). Without one nothing
  /// is sent and nobody is counted (S-6).
  Future<void> _mark(String id) async {
    if (ref.read(profileControllerProvider) is! ProfileLoaded) return;
    _lastMark = DateTime.now();
    try {
      await ref.read(apiClientProvider).post('/live/$id/listen');
    } on Object catch (e) {
      debugPrint('Hazri: live mark not sent ($e)');
    }
  }
}
