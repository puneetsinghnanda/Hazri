import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/api_client.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/settings/settings_controller.dart';
import '../../profile/data/profile_controller.dart';
import '../domain/simran_presence.dart';

/// Attendance and the globe (07-simran §4.2, §4.3).
class PresenceService {
  PresenceService(this._ref);

  final Ref _ref;
  static const kAttendance = 'presence_attendance_v1';
  static const kSnapshot = 'presence_snapshot_v1';

  bool _calling = false;

  /// AT1–AT4: once per IST day, only with a profile, fire and forget. The
  /// flag is set only on success, so a failure is retried at the next start
  /// or resume.
  Future<void> markAttendance() async {
    if (_ref.read(profileControllerProvider) is! ProfileLoaded) return;
    final prefs = _ref.read(sharedPreferencesProvider);
    final today = istDay();
    if (prefs.getString(kAttendance) == today || _calling) return;
    _calling = true;
    try {
      await _ref.read(apiClientProvider).post('/presence/attendance', const <String, Object?>{});
      await prefs.setString(kAttendance, today);
      _ref.invalidate(markedTodayProvider);
    } on ApiException catch (e) {
      debugPrint('Hazri: attendance refused ($e)');
    } on NetworkException {
      // Retried at the next start or resume.
    } finally {
      _calling = false;
    }
  }

  /// GB1: the shared snapshot; the copy on the phone is kept for next time
  /// (GB3). Throws on failure so the caller keeps what it had.
  Future<GlobeSnapshot> fetchGlobe() async {
    final j = await _ref.read(apiClientProvider).get('/presence/globe');
    await _ref.read(sharedPreferencesProvider).setString(kSnapshot, jsonEncode(j));
    return GlobeSnapshot.fromJson(j);
  }

  GlobeSnapshot? savedGlobe() {
    final raw = _ref.read(sharedPreferencesProvider).getString(kSnapshot);
    if (raw == null) return null;
    try {
      return GlobeSnapshot.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return null;
    }
  }
}

final presenceServiceProvider = Provider<PresenceService>(PresenceService.new);

/// Whether this install's attendance is marked for today's IST day.
final markedTodayProvider = Provider<bool>(
  (ref) => ref.watch(sharedPreferencesProvider).getString(PresenceService.kAttendance) == istDay(),
);

/// The globe as the screen draws it: the last snapshot, when it was fetched
/// or saved, and whether the last fetch failed (GB3).
@immutable
class GlobeState {
  const GlobeState({this.snapshot, this.fetchedAt, this.failing = false});

  final GlobeSnapshot? snapshot;
  final DateTime? fetchedAt;
  final bool failing;
}

class GlobeController extends Notifier<GlobeState> {
  @override
  GlobeState build() {
    final saved = ref.read(presenceServiceProvider).savedGlobe();
    return GlobeState(snapshot: saved, fetchedAt: saved?.builtAt);
  }

  Future<void> refresh() async {
    try {
      final s = await ref.read(presenceServiceProvider).fetchGlobe();
      state = GlobeState(snapshot: s, fetchedAt: DateTime.now());
    } on Object catch (e) {
      debugPrint('Hazri: globe not fetched ($e)');
      state = GlobeState(snapshot: state.snapshot, fetchedAt: state.fetchedAt, failing: true);
    }
  }
}

final globeProvider = NotifierProvider<GlobeController, GlobeState>(GlobeController.new);

/// City positions from `content.db`, by id.
final cityPositionsProvider = Provider<Map<String, ({double lat, double lon})>>((ref) {
  final rows = ref.watch(citiesProvider).value ?? const <CityRow>[];
  return {for (final c in rows) c.id: (lat: c.lat, lon: c.lon)};
});

/// What the painter draws: the dots (§2.1, SZ1) and their threads (DR6,
/// DR7), recomputed only when the snapshot, the profile or the mark change.
final globeDrawingProvider = Provider<({List<GlobeDot> dots, List<(int, int)> threads})>((ref) {
  final snapshot = ref.watch(globeProvider.select((g) => g.snapshot)) ?? GlobeSnapshot.empty;
  final dots = globeDots(
    snapshot,
    ref.watch(cityPositionsProvider),
    yourCityId: ref.watch(profileProvider.select((p) => p?.cityId)),
    markedToday: ref.watch(markedTodayProvider) && snapshot.day == istDay(),
  );
  return (dots: dots, threads: globeThreads(dots));
});
