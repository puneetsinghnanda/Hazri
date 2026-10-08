import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// `presenceSnapshot/current` as `GET /presence/globe` returns it (07-simran
/// §5.4, §6.2): city totals only, never a person (PV2).
@immutable
class GlobeSnapshot {
  const GlobeSnapshot({
    required this.day,
    required this.live,
    required this.counted,
    required this.cities,
    this.builtAt,
  });

  /// The IST day it counts.
  final String day;
  final int live;
  final int counted;

  /// cityId → (live, counted).
  final Map<String, ({int live, int counted})> cities;
  final DateTime? builtAt;

  static const empty = GlobeSnapshot(day: '', live: 0, counted: 0, cities: {});

  factory GlobeSnapshot.fromJson(Map<String, Object?> j) {
    final cities = <String, ({int live, int counted})>{};
    final countries = j['countries'];
    if (countries is Map<String, Object?>) {
      for (final country in countries.values.whereType<Map<String, Object?>>()) {
        final states = country['s'];
        if (states is! Map<String, Object?>) continue;
        for (final state in states.values.whereType<Map<String, Object?>>()) {
          final k = state['k'];
          if (k is! Map<String, Object?>) continue;
          for (final e in k.entries) {
            final v = e.value;
            if (v is List && v.length == 2) {
              cities[e.key] = (live: (v[0] as num).toInt(), counted: (v[1] as num).toInt());
            }
          }
        }
      }
    }
    return GlobeSnapshot(
      day: (j['day'] as String?) ?? '',
      live: (j['live'] as num?)?.toInt() ?? 0,
      counted: (j['counted'] as num?)?.toInt() ?? 0,
      cities: cities,
      builtAt: DateTime.tryParse('${j['builtAt']}'),
    );
  }
}

/// The three dots of §2.1.
enum DotKind { you, live, here }

/// One dot to draw: where, what, how many and how big.
@immutable
class GlobeDot {
  const GlobeDot({
    required this.cityId,
    required this.lat,
    required this.lon,
    required this.kind,
    required this.count,
    required this.radius,
  });

  final String cityId;
  final double lat;
  final double lon;
  final DotKind kind;
  final int count;

  /// Logical pixels (SZ1); You uses the smallest.
  final double radius;

  @override
  bool operator ==(Object other) =>
      other is GlobeDot &&
      other.cityId == cityId &&
      other.kind == kind &&
      other.count == count &&
      other.radius == radius &&
      other.lat == lat &&
      other.lon == lon;

  @override
  int get hashCode => Object.hash(cityId, kind, count, radius, lat, lon);
}

/// §2.1: what one city draws for this viewer. [viewer] null: no profile, so
/// nothing is taken off (NP1).
({int you, int live, int here}) splitCity(
  int live,
  int counted, {
  ({bool inThisCity, bool markedToday})? viewer,
}) {
  final here = counted - live;
  if (viewer == null || !viewer.inThisCity) return (you: 0, live: live, here: here);
  if (viewer.markedToday) return (you: 1, live: math.max(0, live - 1), here: here);
  return (you: 1, live: live, here: math.max(0, here - 1));
}

const dotMinRadius = 3.0;
const dotMaxRadius = 14.0;

/// SZ1: area grows with the count; the largest green or blue dot is the
/// maximum. Rounded to one decimal.
double dotRadius(int count, int largest) {
  if (count <= 0 || largest <= 0) return dotMinRadius;
  final r = dotMinRadius + (dotMaxRadius - dotMinRadius) * math.sqrt(count / largest);
  return (r * 10).roundToDouble() / 10;
}

/// Every dot of the snapshot for this viewer (DR1, DR2). [positions] maps a
/// city id to its lat/lon from `content.db`; a city the phone does not know
/// is skipped. [yourCityId] null without a profile; [markedToday]: this
/// install's attendance is marked for the snapshot's day.
List<GlobeDot> globeDots(
  GlobeSnapshot snapshot,
  Map<String, ({double lat, double lon})> positions, {
  String? yourCityId,
  bool markedToday = false,
}) {
  final split = <String, ({int you, int live, int here})>{};
  for (final e in snapshot.cities.entries) {
    split[e.key] = splitCity(
      e.value.live,
      e.value.counted,
      viewer: yourCityId == null ? null : (inThisCity: e.key == yourCityId, markedToday: markedToday),
    );
  }
  var largest = 0;
  for (final s in split.values) {
    largest = math.max(largest, math.max(s.live, s.here));
  }
  final dots = <GlobeDot>[];
  for (final e in split.entries) {
    final at = positions[e.key];
    if (at == null) continue;
    if (e.value.here > 0) {
      dots.add(GlobeDot(
          cityId: e.key, lat: at.lat, lon: at.lon, kind: DotKind.here,
          count: e.value.here, radius: dotRadius(e.value.here, largest)));
    }
    if (e.value.live > 0) {
      dots.add(GlobeDot(
          cityId: e.key, lat: at.lat, lon: at.lon, kind: DotKind.live,
          count: e.value.live, radius: dotRadius(e.value.live, largest)));
    }
  }
  // DR1: your dot from the profile on the phone, offline too, drawn last.
  final mine = yourCityId == null ? null : positions[yourCityId];
  if (mine != null) {
    dots.add(GlobeDot(
        cityId: yourCityId!, lat: mine.lat, lon: mine.lon, kind: DotKind.you, count: 1,
        radius: dotMinRadius + 1));
  }
  return dots;
}

/// Great-circle distance in radians.
double greatCircle(double lat1, double lon1, double lat2, double lon2) {
  const d = math.pi / 180;
  final p1 = lat1 * d, p2 = lat2 * d;
  final dp = p2 - p1, dl = (lon2 - lon1) * d;
  final a = math.pow(math.sin(dp / 2), 2) + math.cos(p1) * math.cos(p2) * math.pow(math.sin(dl / 2), 2);
  return 2 * math.asin(math.min(1, math.sqrt(a.toDouble())));
}

/// The threads to draw, as index pairs into [dots], each pair once.
///
/// DR6: with a You dot, one from it to every other dot. DR7: without one, a
/// web: Prim's shortest tree over every city plus each city's 2 nearest.
/// Computed when a snapshot arrives, never per frame; whether a thread is on
/// the visible side is the painter's question.
List<(int, int)> globeThreads(List<GlobeDot> dots) {
  final you = dots.indexWhere((d) => d.kind == DotKind.you);
  if (you >= 0) {
    return [
      for (var i = 0; i < dots.length; i++)
        if (i != you && dots[i].cityId != dots[you].cityId) (you, i),
    ];
  }
  // One node per city: the web joins places, and two dots in one city are
  // side by side already.
  final nodes = <int>[];
  final seen = <String>{};
  for (var i = 0; i < dots.length; i++) {
    if (seen.add(dots[i].cityId)) nodes.add(i);
  }
  final n = nodes.length;
  if (n < 2) return const [];
  double dist(int a, int b) =>
      greatCircle(dots[nodes[a]].lat, dots[nodes[a]].lon, dots[nodes[b]].lat, dots[nodes[b]].lon);

  final edges = <(int, int)>{};
  void add(int a, int b) {
    final x = nodes[a], y = nodes[b];
    edges.add(x < y ? (x, y) : (y, x));
  }

  // Prim's algorithm.
  final inTree = List<bool>.filled(n, false);
  final best = List<double>.filled(n, double.infinity);
  final from = List<int>.filled(n, -1);
  best[0] = 0;
  for (var step = 0; step < n; step++) {
    var u = -1;
    for (var v = 0; v < n; v++) {
      if (!inTree[v] && (u < 0 || best[v] < best[u])) u = v;
    }
    inTree[u] = true;
    if (from[u] >= 0) add(from[u], u);
    for (var v = 0; v < n; v++) {
      if (inTree[v]) continue;
      final dv = dist(u, v);
      if (dv < best[v]) {
        best[v] = dv;
        from[v] = u;
      }
    }
  }
  // And each node's two nearest.
  for (var a = 0; a < n; a++) {
    final order = [for (var b = 0; b < n; b++) if (b != a) b]..sort((x, y) => dist(a, x).compareTo(dist(a, y)));
    for (final b in order.take(2)) {
      add(a, b);
    }
  }
  return edges.toList();
}

/// The IST day (07-simran §2), whatever the phone's zone.
String istDay([DateTime? now]) {
  final ist = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 5, minutes: 30));
  return '${ist.year.toString().padLeft(4, '0')}-${ist.month.toString().padLeft(2, '0')}-${ist.day.toString().padLeft(2, '0')}';
}
