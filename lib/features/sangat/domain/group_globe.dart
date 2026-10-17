import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../simran/domain/simran_presence.dart';

/// `GROUP_ARRIVALS_MINUTES` (08-sangat §3): the window the server's `recent`
/// covers. The phone holds a copy to the same window, so a globe kept from
/// yesterday never says that yesterday's paath "arrived in the last hour".
const groupArrivalsWindow = Duration(minutes: 60);

/// GG4: one arrival after another, this far apart.
const groupArrivalSpacing = Duration(milliseconds: 800);

/// One paath counted toward the group's current goal (GG4): where the member
/// who did it lives (null without a profile), when the server received it,
/// and what it counted (1 for a paath, minutes for Naam Simran).
@immutable
class GroupArrival {
  const GroupArrival({this.cityId, required this.at, this.amount = 1});

  final String? cityId;
  final DateTime at;
  final int amount;

  @override
  bool operator ==(Object other) =>
      other is GroupArrival && other.cityId == cityId && other.at == at && other.amount == amount;

  @override
  int get hashCode => Object.hash(cityId, at, amount);
}

/// The group's globe as 7.15 returns it (ARCHITECTURE §6.4a): counts per
/// city and nothing finer (GG2, GG7), not personalised (the phone takes the
/// viewer off itself, GG3).
@immutable
class GroupGlobe {
  const GroupGlobe({
    required this.day,
    this.builtAt,
    required this.cities,
    this.unplacedToday = 0,
    this.unplacedMembers = 0,
    this.recent = const [],
  });

  /// The IST day "today" is counted for.
  final String day;
  final DateTime? builtAt;

  /// cityId → (members who added today, active members).
  final Map<String, ({int today, int members})> cities;

  /// Active members with no city: no profile, or a row not yet filled.
  final int unplacedToday;
  final int unplacedMembers;

  /// Newest first, as the server sends it.
  final List<GroupArrival> recent;

  int get totalToday => cities.values.fold(unplacedToday, (n, c) => n + c.today);
  int get totalMembers => cities.values.fold(unplacedMembers, (n, c) => n + c.members);

  factory GroupGlobe.fromJson(Map<String, Object?> j) {
    int n(Object? v) => v is num ? v.toInt() : 0;
    final cities = <String, ({int today, int members})>{};
    final raw = j['cities'];
    if (raw is Map<String, Object?>) {
      for (final e in raw.entries) {
        final v = e.value;
        if (v is List && v.length >= 2) cities[e.key] = (today: n(v[0]), members: n(v[1]));
      }
    }
    final unplaced = j['unplaced'];
    final recent = <GroupArrival>[];
    for (final r in (j['recent'] as List<Object?>? ?? const []).whereType<Map<String, Object?>>()) {
      final at = parseServerTime(r['at']);
      if (at == null) continue;
      final city = r['cityId'];
      recent.add(
        GroupArrival(
          cityId: city is String && city.isNotEmpty ? city : null,
          at: at,
          amount: r['amount'] is num ? n(r['amount']) : 1,
        ),
      );
    }
    return GroupGlobe(
      day: (j['day'] as String?) ?? '',
      builtAt: parseServerTime(j['builtAt']),
      cities: cities,
      unplacedToday: unplaced is Map<String, Object?> ? n(unplaced['today']) : 0,
      unplacedMembers: unplaced is Map<String, Object?> ? n(unplaced['members']) : 0,
      recent: recent,
    );
  }

  /// The same counts in the shape the Simran globe draws from: green is
  /// "today", blue is the rest (GG3).
  GlobeSnapshot asSnapshot() => GlobeSnapshot(
    day: day,
    live: totalToday,
    counted: totalMembers,
    cities: {for (final e in cities.entries) e.key: (live: e.value.today, counted: e.value.members)},
    builtAt: builtAt,
  );
}

/// A time as the server may send it: ISO 8601, milliseconds since the epoch,
/// or a serialised Firestore timestamp.
DateTime? parseServerTime(Object? v) {
  if (v is String) return DateTime.tryParse(v);
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);
  if (v is Map) {
    final s = v['_seconds'] ?? v['seconds'];
    if (s is num) return DateTime.fromMillisecondsSinceEpoch((s * 1000).toInt(), isUtc: true);
  }
  return null;
}

/// Who is looking, for GG3: drawn only as a member with a profile city.
/// [today]: their own "yours today" (VS3) is above 0, so they come off their
/// city's green; otherwise off its blue.
typedef GroupViewer = ({String cityId, bool today});

/// GG3: the group's dots for this viewer, by the Simran globe's own split and
/// sizes (07-simran §2.1, SZ1). A city `content.db` does not know is not
/// drawn; it is still counted in the key ([groupGlobeKey]).
List<GlobeDot> groupGlobeDots(
  GroupGlobe? globe,
  Map<String, ({double lat, double lon})> positions, {
  GroupViewer? viewer,
}) =>
    // GG8: with no globe at all, only you.
    globeDots(
      (globe ?? const GroupGlobe(day: '', cities: {})).asSnapshot(),
      positions,
      yourCityId: viewer?.cityId,
      countedLive: viewer?.today ?? false,
    );

/// GG1: the key under the ring. "You" are counted apart, so You, today and
/// not yet add up to the group's members; members without a city are in
/// today or not yet (GG2). Without a viewer nothing is taken off.
({int today, int notYet, int cities}) groupGlobeKey(GroupGlobe globe, {GroupViewer? viewer}) {
  var today = globe.totalToday;
  var notYet = globe.totalMembers - globe.totalToday;
  if (viewer != null) {
    if (viewer.today) {
      today -= 1;
    } else {
      notYet -= 1;
    }
  }
  final cities = {
    for (final e in globe.cities.entries)
      if (e.value.members > 0) e.key,
    ?viewer?.cityId,
  };
  return (today: math.max(0, today), notYet: math.max(0, notYet), cities: cities.length);
}

/// GG4, GG5: what arrived in the last hour as of [now], oldest first. A copy
/// kept on the phone ages out of the window rather than replaying old paath.
List<GroupArrival> recentArrivals(GroupGlobe? globe, DateTime now) {
  if (globe == null) return const [];
  final since = now.subtract(groupArrivalsWindow);
  return [
    for (final a in globe.recent.reversed)
      if (!a.at.isBefore(since)) a,
  ]..sort((a, b) => a.at.compareTo(b.at));
}

/// GG5: the line's number: paath for a bani goal, minutes for Naam Simran.
/// Each arrival's amount is what it counted toward the goal.
int arrivalsAmount(List<GroupArrival> arrivals) => arrivals.fold(0, (n, a) => n + a.amount);

/// GG4: which of [arrivals] (oldest first) still have to be played, given the
/// newest one already played; all of them on opening.
List<GroupArrival> arrivalsToPlay(List<GroupArrival> arrivals, DateTime? playedUpTo) => [
  for (final a in arrivals)
    if (playedUpTo == null || a.at.isAfter(playedUpTo)) a,
];
