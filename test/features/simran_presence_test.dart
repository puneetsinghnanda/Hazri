import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/simran/domain/simran_presence.dart';

/// 07-simran §10: the split, the radii and the threads, as pure functions.
void main() {
  group('§2.1 the split', () {
    test('G-8: outside the city, nothing is taken off', () {
      expect(splitCity(25, 40, viewer: (inThisCity: false, countedLive: true)), (you: 0, live: 25, here: 15));
    });
    test('G-9: in the city and counted live: you, live − 1, here', () {
      expect(splitCity(25, 40, viewer: (inThisCity: true, countedLive: true)), (you: 1, live: 24, here: 15));
    });
    test('in the city, not counted live yet: you, live, here − 1', () {
      expect(splitCity(25, 40, viewer: (inThisCity: true, countedLive: false)), (you: 1, live: 25, here: 14));
    });
    test('NP1: no profile, nothing taken off', () {
      expect(splitCity(25, 40), (you: 0, live: 25, here: 15));
    });
    test('G-7: 1,000 counted, 500 live including you → 1 orange, 499 green, 500 blue', () {
      final snap = GlobeSnapshot(day: '2026-10-08', live: 500, counted: 1000, cities: {
        'delhi': (live: 300, counted: 600),
        'amritsar': (live: 200, counted: 400),
      });
      final dots = globeDots(snap, {'delhi': (lat: 28.6, lon: 77.2), 'amritsar': (lat: 31.6, lon: 74.9)},
          yourCityId: 'amritsar', countedLive: true);
      int sum(DotKind k) => dots.where((d) => d.kind == k).fold(0, (a, d) => a + d.count);
      expect(sum(DotKind.you), 1);
      expect(sum(DotKind.live), 499);
      expect(sum(DotKind.here), 500);
    });
  });

  group('SZ1 radii (owner, 2026-10-17)', () {
    test('one person is the size of your dot', () {
      expect(dotRadius(1), dotYouRadius);
    });
    test('area grows to the maximum at 25 people, and stays there', () {
      expect(dotRadius(25), dotMaxRadius);
      expect(dotRadius(400), dotMaxRadius);
      expect(dotRadius(7), 9.0);
      expect(dotRadius(2) > dotYouRadius, isTrue);
    });
    test('a quiet day does not blow single people up', () {
      final snap = GlobeSnapshot(day: 'd', live: 3, counted: 3, cities: {
        'a': (live: 1, counted: 1),
        'b': (live: 1, counted: 1),
        'c': (live: 1, counted: 1),
      });
      final dots = globeDots(snap, {for (final c in ['a', 'b', 'c']) c: (lat: 0.0, lon: 0.0)});
      expect(dots.every((d) => d.radius == dotYouRadius), isTrue);
    });
  });

  group('CT1, CT2: the count and the dots agree', () {
    // The owner's screenshot of 2026-10-17: you in Amritsar, one other person
    // live there, one in Lahore. Built at 03:00, marked at 03:01.
    final built = DateTime.utc(2026, 10, 17, 3);
    final stale = GlobeSnapshot(day: '2026-10-17', live: 2, counted: 3, builtAt: built, cities: {
      'amritsar': (live: 1, counted: 2), // the other person live; you not yet
      'lahore': (live: 1, counted: 1),
    });
    final fresh = GlobeSnapshot(day: '2026-10-17', live: 3, counted: 3, builtAt: built.add(const Duration(minutes: 2)), cities: {
      'amritsar': (live: 2, counted: 2), // now counting you
      'lahore': (live: 1, counted: 1),
    });
    const at = {'amritsar': (lat: 31.6, lon: 74.9), 'lahore': (lat: 31.5, lon: 74.4)};
    final markedAt = built.add(const Duration(minutes: 1));

    for (final (name, snap) in [('before the snapshot catches up', stale), ('after', fresh)]) {
      test('$name: you once, nobody else lost, and 3 live', () {
        final counted = snapshotCountsYou(snap, marked: true, markedAt: markedAt);
        final dots = globeDots(snap, at, yourCityId: 'amritsar', countedLive: counted);
        int sum(DotKind k) => dots.where((d) => d.kind == k).fold(0, (a, d) => a + d.count);
        expect(sum(DotKind.you), 1);
        expect(sum(DotKind.live), 2);
        expect(sum(DotKind.here), 0, reason: 'you are never drawn blue as well as orange');
        expect(globeLiveTotal(snap, marked: true, countedLive: counted), 3);
      });
    }

    test('not marked yet: the total is the snapshot\'s', () {
      expect(globeLiveTotal(stale, marked: false, countedLive: false), 2);
    });
    test('a mark kept before its time was: taken as counted', () {
      expect(snapshotCountsYou(stale, marked: true), isTrue);
    });
  });

  group('threads', () {
    final positions = {
      'amritsar': (lat: 31.6, lon: 74.9),
      'delhi': (lat: 28.6, lon: 77.2),
      'southall': (lat: 51.5, lon: -0.4),
      'dubai': (lat: 25.2, lon: 55.3),
      'toronto': (lat: 43.7, lon: -79.4),
    };
    final snap = GlobeSnapshot(day: 'd', live: 5, counted: 10, cities: {
      for (final c in positions.keys) c: (live: 1, counted: 2),
    });

    test('DR6: from your dot to every other city, once each', () {
      final dots = globeDots(snap, positions, yourCityId: 'amritsar', countedLive: true);
      final threads = globeThreads(dots);
      final you = dots.indexWhere((d) => d.kind == DotKind.you);
      final mine = threads.where((t) => t.mine).toList();
      expect(mine.every((t) => t.a == you), isTrue);
      expect({for (final t in mine) dots[t.b].cityId}, positions.keys.toSet()..remove('amritsar'));
      expect(mine.length, positions.length - 1);
    });

    test('DR7 with a profile too: the others are joined to each other', () {
      final dots = globeDots(snap, positions, yourCityId: 'amritsar', countedLive: true);
      final web = globeThreads(dots).where((t) => !t.mine).toList();
      final others = positions.keys.where((c) => c != 'amritsar').toList();
      final parent = <String, String>{for (final c in others) c: c};
      String find(String x) => parent[x] == x ? x : (parent[x] = find(parent[x]!));
      for (final t in web) {
        parent[find(dots[t.a].cityId)] = find(dots[t.b].cityId);
      }
      expect(others.map(find).toSet(), hasLength(1));
    });

    test('DR8: every arc rises off the earth and comes back down at its ends', () {
      final dots = globeDots(snap, positions, yourCityId: 'amritsar', countedLive: true);
      final threads = globeThreads(dots);
      final arcs = globeArcs(dots, threads);
      expect(arcs, hasLength(threads.length));
      for (final a in arcs) {
        double len(int i) => math.sqrt(a[i] * a[i] + a[i + 1] * a[i + 1] + a[i + 2] * a[i + 2]);
        expect(len(0), closeTo(1, 1e-9));
        expect(len(a.length - 3), closeTo(1, 1e-9));
        expect(len((arcSamples ~/ 2) * 3), greaterThan(1.02));
      }
    });

    test('DR7: without a profile, one connected web, each pair once', () {
      final dots = globeDots(snap, positions);
      final threads = globeThreads(dots);
      expect(threads.toSet().length, threads.length);
      // Union-find over cities.
      final parent = <String, String>{for (final c in positions.keys) c: c};
      String find(String x) => parent[x] == x ? x : (parent[x] = find(parent[x]!));
      for (final t in threads) {
        parent[find(dots[t.a].cityId)] = find(dots[t.b].cityId);
      }
      expect(positions.keys.map(find).toSet(), hasLength(1));
    });

    test('G-18: Europe is joined to the Gulf, not left on its own', () {
      final dots = globeDots(snap, positions);
      final threads = globeThreads(dots);
      bool linked(String x, String y) => threads.any((t) =>
          {dots[t.a].cityId, dots[t.b].cityId}.containsAll({x, y}));
      expect(linked('southall', 'dubai') || linked('southall', 'amritsar') || linked('southall', 'delhi'), isTrue);
    });
  });

  test('the snapshot parses the nested country/state/city shape', () {
    final s = GlobeSnapshot.fromJson({
      'day': '2026-10-08',
      'live': 30,
      'counted': 50,
      'builtAt': '2026-10-08T03:00:00.000Z',
      'countries': {
        'IN': {
          'l': 30, 'c': 50,
          's': {
            'IN-PB': {'l': 10, 'c': 20, 'k': {'amritsar': [10, 20]}},
            'IN-DL': {'l': 20, 'c': 30, 'k': {'delhi': [20, 30]}},
          },
        },
      },
    });
    expect(s.cities['delhi'], (live: 20, counted: 30));
    expect(s.live, 30);
    expect(s.builtAt, isNotNull);
  });

  test('the IST day turns at 18:30 UTC', () {
    expect(istDay(DateTime.utc(2026, 10, 8, 18, 29)), '2026-10-08');
    expect(istDay(DateTime.utc(2026, 10, 8, 18, 30)), '2026-10-09');
  });
}
