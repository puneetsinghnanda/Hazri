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

  /// Logical pixels (SZ1); one person is the size of You.
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
/// nothing is taken off (NP1). `countedLive`: the snapshot already counts the
/// viewer as live (CT1), so they come off the green; otherwise they are still
/// in its blue and come off that.
({int you, int live, int here}) splitCity(
  int live,
  int counted, {
  ({bool inThisCity, bool countedLive})? viewer,
}) {
  final here = counted - live;
  if (viewer == null || !viewer.inThisCity) return (you: 0, live: live, here: here);
  if (viewer.countedLive) return (you: 1, live: math.max(0, live - 1), here: here);
  return (you: 1, live: live, here: math.max(0, here - 1));
}

/// CT1: whether [snapshot] already counts the viewer as live. It does once
/// their attendance is marked *and* the snapshot was built after it was: the
/// server rebuilds every two minutes, so for a while after marking, the
/// snapshot still has them under Here today. [markedAt] null with [marked]
/// true is a mark from before the time was kept, long since counted.
bool snapshotCountsYou(GlobeSnapshot snapshot, {required bool marked, DateTime? markedAt}) {
  if (!marked) return false;
  final built = snapshot.builtAt;
  if (built == null || markedAt == null) return true;
  return !built.isBefore(markedAt);
}

/// DR5 as amended (CT2): the people live today, as the dots show them. The
/// snapshot's total, plus you while it has not caught up with your mark.
int globeLiveTotal(GlobeSnapshot snapshot, {required bool marked, required bool countedLive}) =>
    snapshot.live + (marked && !countedLive ? 1 : 0);

/// SZ1 as amended (owner, 2026-10-17): one person is the size of your dot,
/// and a dot grows by area until `DOT_FULL_AT` people, after which it stays
/// at the maximum. Absolute, so a quiet day does not blow single people up.
const dotYouRadius = 4.0;
const dotMaxRadius = 14.0;
const dotFullAt = 25;

double dotRadius(int count) {
  if (count <= 1) return dotYouRadius;
  final f = (math.min(count, dotFullAt) - 1) / (dotFullAt - 1);
  final r = dotYouRadius + (dotMaxRadius - dotYouRadius) * math.sqrt(f);
  return (r * 10).roundToDouble() / 10;
}

/// Every dot of the snapshot for this viewer (DR1, DR2). [positions] maps a
/// city id to its lat/lon from `content.db`; a city the phone does not know
/// is skipped. [yourCityId] null without a profile; [countedLive]: the
/// snapshot already counts this viewer as live ([snapshotCountsYou]).
List<GlobeDot> globeDots(
  GlobeSnapshot snapshot,
  Map<String, ({double lat, double lon})> positions, {
  String? yourCityId,
  bool countedLive = false,
}) {
  final dots = <GlobeDot>[];
  for (final e in snapshot.cities.entries) {
    final at = positions[e.key];
    if (at == null) continue;
    final s = splitCity(
      e.value.live,
      e.value.counted,
      viewer: yourCityId == null ? null : (inThisCity: e.key == yourCityId, countedLive: countedLive),
    );
    if (s.here > 0) {
      dots.add(GlobeDot(
          cityId: e.key, lat: at.lat, lon: at.lon, kind: DotKind.here,
          count: s.here, radius: dotRadius(s.here)));
    }
    if (s.live > 0) {
      dots.add(GlobeDot(
          cityId: e.key, lat: at.lat, lon: at.lon, kind: DotKind.live,
          count: s.live, radius: dotRadius(s.live)));
    }
  }
  // DR1: your dot from the profile on the phone, offline too, drawn last.
  final mine = yourCityId == null ? null : positions[yourCityId];
  if (mine != null) {
    dots.add(GlobeDot(
        cityId: yourCityId!, lat: mine.lat, lon: mine.lon, kind: DotKind.you, count: 1,
        radius: dotYouRadius));
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

/// One thread: index pairs into the dots, and whether it starts at your dot.
typedef GlobeThread = ({int a, int b, bool mine});

/// The threads to draw (DR6, DR7 as amended 2026-10-17), each pair once.
///
/// The sangat joined to itself: Prim's shortest tree over every city plus
/// each city's two nearest, so nobody is left on their own. With a profile,
/// a thread from your dot to every other city as well. Computed when a
/// snapshot arrives, never per frame; whether a thread faces the viewer is
/// the painter's question.
List<GlobeThread> globeThreads(List<GlobeDot> dots) {
  final you = dots.indexWhere((d) => d.kind == DotKind.you);
  final out = <GlobeThread>[];
  final yourCity = you >= 0 ? dots[you].cityId : null;
  if (you >= 0) {
    final seen = <String>{yourCity!};
    for (var i = 0; i < dots.length; i++) {
      if (seen.add(dots[i].cityId)) out.add((a: you, b: i, mine: true));
    }
  }
  // One node per city other than yours: two dots in one city are side by
  // side already, and yours is joined by its own threads.
  final nodes = <int>[];
  final seen = <String>{};
  for (var i = 0; i < dots.length; i++) {
    if (dots[i].cityId == yourCity) continue;
    if (seen.add(dots[i].cityId)) nodes.add(i);
  }
  final n = nodes.length;
  if (n < 2) return out;
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
  out.addAll([for (final (a, b) in edges) (a: a, b: b, mine: false)]);
  return out;
}

/// Samples along each thread as 3-D points, lifted off the surface toward the
/// middle so a thread arcs over the earth rather than lying on it (DR8). A
/// thread between cities further apart rises higher. Flat (x, y, z) triples,
/// [arcSamples] + 1 points each.
const arcSamples = 24;

List<List<double>> globeArcs(List<GlobeDot> dots, List<GlobeThread> threads) {
  const d = math.pi / 180;
  List<double> unit(GlobeDot g) {
    final p = g.lat * d, l = g.lon * d;
    return [math.cos(p) * math.cos(l), math.cos(p) * math.sin(l), math.sin(p)];
  }

  return [
    for (final t in threads)
      () {
        final a = unit(dots[t.a]), b = unit(dots[t.b]);
        final w = math.acos((a[0] * b[0] + a[1] * b[1] + a[2] * b[2]).clamp(-1.0, 1.0));
        final out = <double>[];
        if (w < 1e-6) return out;
        final lift = 0.03 + 0.22 * (w / math.pi);
        final sw = math.sin(w);
        for (var s = 0; s <= arcSamples; s++) {
          final f = s / arcSamples;
          final k1 = math.sin((1 - f) * w) / sw, k2 = math.sin(f * w) / sw;
          final h = 1 + lift * math.sin(math.pi * f);
          out
            ..add((k1 * a[0] + k2 * b[0]) * h)
            ..add((k1 * a[1] + k2 * b[1]) * h)
            ..add((k1 * a[2] + k2 * b[2]) * h);
        }
        return out;
      }(),
  ];
}

/// The IST day (07-simran §2), whatever the phone's zone.
String istDay([DateTime? now]) {
  final ist = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 5, minutes: 30));
  return '${ist.year.toString().padLeft(4, '0')}-${ist.month.toString().padLeft(2, '0')}-${ist.day.toString().padLeft(2, '0')}';
}
