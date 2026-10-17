import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/backend/api_exception.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/time/clock.dart';
import '../../goals/data/goals_controller.dart';
import '../../profile/data/profile_controller.dart';
import '../../simran/data/presence_repository.dart';
import '../../simran/domain/simran_presence.dart';
import '../domain/group_globe.dart';
import '../domain/sangat_models.dart';
import 'sangat_api.dart';
import 'sangat_controller.dart';

/// What this phone did today toward [goal], from `user.db`: paath of the
/// goal's bani, or whole minutes of Naam Simran, each sitting counted as the
/// server counts it (08-sangat CT1, `amountFor`).
int yoursToday(DayRows? rows, SangatGoal goal) {
  if (rows == null) return 0;
  if (goal.isSimran) {
    return rows.sittings.where((s) => s.deletedAt == null).fold(0, (sum, s) => sum + s.durationS ~/ 60);
  }
  return rows.completions.where((c) => c.deletedAt == null && c.baniId == goal.baniId).length;
}

/// `sangat_globe_cache_v1` (ARCHITECTURE §3.5, 08-sangat GG8): the last 7.15
/// reply of each group, as a JSON map of group id to the reply.
class GroupGlobeCache {
  GroupGlobeCache(this._prefs);

  static const key = 'sangat_globe_cache_v1';
  final SharedPreferences _prefs;

  Map<String, Object?> _all() {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, Object?>;
    } on Object {
      return {};
    }
  }

  Map<String, Object?>? read(String groupId) {
    final e = _all()[groupId];
    return e is Map<String, Object?> ? e : null;
  }

  Future<void> write(String groupId, Map<String, Object?> reply) =>
      _prefs.setString(key, jsonEncode(_all()..[groupId] = reply));
}

final groupGlobeCacheProvider = Provider<GroupGlobeCache>(
  (ref) => GroupGlobeCache(ref.watch(sharedPreferencesProvider)),
);

/// The group's globe as the screen has it: the last reply (the copy on the
/// phone first, GG8), and whether the last fetch failed.
@immutable
class GroupGlobeView {
  const GroupGlobeView({this.globe, this.offline = false});

  final GroupGlobe? globe;
  final bool offline;
}

/// GG6, GG8: the copy first, then the server's; offline, the copy stays.
class GroupGlobeController extends FamilyNotifier<GroupGlobeView, String> {
  @override
  GroupGlobeView build(String groupId) {
    final saved = ref.read(groupGlobeCacheProvider).read(groupId);
    if (saved == null) return const GroupGlobeView();
    try {
      return GroupGlobeView(globe: GroupGlobe.fromJson(saved));
    } on Object {
      return const GroupGlobeView();
    }
  }

  Future<void> refresh() async {
    try {
      final j = await ref.read(sangatApiProvider).globe(arg);
      final globe = GroupGlobe.fromJson(j);
      await ref.read(groupGlobeCacheProvider).write(arg, j);
      state = GroupGlobeView(globe: globe);
    } on NetworkException {
      state = GroupGlobeView(globe: state.globe, offline: true);
    } on Object catch (e) {
      // A refusal is the group screen's to report (7.3 says whether the group
      // is gone); the globe keeps what it had.
      debugPrint('Hazri: group globe not fetched ($e)');
      state = GroupGlobeView(globe: state.globe, offline: true);
    }
  }
}

final groupGlobeProvider = NotifierProvider.family<GroupGlobeController, GroupGlobeView, String>(
  GroupGlobeController.new,
);

/// What the group screen draws (GG1–GG5, GG9), recomputed only when the
/// globe, the group, the profile's city or today's rows change.
@immutable
class GroupGlobeDrawing {
  const GroupGlobeDrawing({
    required this.dots,
    required this.threads,
    required this.arcs,
    this.viewer,
    this.key,
    this.arrivals = const [],
  });

  final List<GlobeDot> dots;
  final List<GlobeThread> threads;
  final List<List<double>> arcs;

  /// You, when you are drawn (GG3): a member with a profile city.
  final GroupViewer? viewer;

  /// GG1's key; null with no globe yet.
  final ({int today, int notYet, int cities})? key;

  /// GG4: the last hour's, oldest first; none for an ended goal (GG9).
  final List<GroupArrival> arrivals;

  static const empty = GroupGlobeDrawing(dots: [], threads: [], arcs: []);
}

final groupGlobeDrawingProvider = Provider.family<GroupGlobeDrawing, String>((ref, groupId) {
  final group = ref.watch(sangatGroupProvider(groupId))?.value;
  final goal = group?.goal;
  if (group == null || goal == null) return GroupGlobeDrawing.empty;
  final globe = ref.watch(groupGlobeProvider(groupId).select((v) => v.globe));
  final city = ref.watch(profileProvider.select((p) => p?.cityId));
  final today = yoursToday(ref.watch(todayRowsProvider).value, goal) > 0;
  // GG3: you are on it as a member with a profile; without one, nothing is
  // taken off and there is no orange dot.
  final GroupViewer? viewer = group.isMember && city != null ? (cityId: city, today: today) : null;
  final dots = groupGlobeDots(globe, ref.watch(cityPositionsProvider), viewer: viewer);
  final threads = globeThreads(dots);
  final active = group.isActive && goal.status == 'ACTIVE';
  return GroupGlobeDrawing(
    dots: dots,
    threads: threads,
    arcs: globeArcs(dots, threads),
    viewer: viewer,
    key: globe == null ? null : groupGlobeKey(globe, viewer: viewer),
    arrivals: active ? recentArrivals(globe, ref.read(clockProvider).now()) : const [],
  );
});
