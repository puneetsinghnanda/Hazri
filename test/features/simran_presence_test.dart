import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/simran/domain/simran_presence.dart';

/// 07-simran §10: the split, the radii and the threads, as pure functions.
void main() {
  group('§2.1 the split', () {
    test('G-8: outside the city, nothing is taken off', () {
      expect(splitCity(25, 40, viewer: (inThisCity: false, markedToday: true)), (you: 0, live: 25, here: 15));
    });
    test('G-9: in the city and marked: you, live − 1, here', () {
      expect(splitCity(25, 40, viewer: (inThisCity: true, markedToday: true)), (you: 1, live: 24, here: 15));
    });
    test('in the city, not yet marked: you, live, here − 1', () {
      expect(splitCity(25, 40, viewer: (inThisCity: true, markedToday: false)), (you: 1, live: 25, here: 14));
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
          yourCityId: 'amritsar', markedToday: true);
      int sum(DotKind k) => dots.where((d) => d.kind == k).fold(0, (a, d) => a + d.count);
      expect(sum(DotKind.you), 1);
      expect(sum(DotKind.live), 499);
      expect(sum(DotKind.here), 500);
    });
  });

  group('SZ1 radii', () {
    test('the largest is the maximum; area grows with the count', () {
      expect(dotRadius(100, 100), dotMaxRadius);
      expect(dotRadius(25, 100), 8.5);
      expect(dotRadius(1, 100), 4.1);
    });
    test('every count equal → every dot the maximum', () {
      final snap = GlobeSnapshot(day: 'd', live: 0, counted: 9, cities: {
        'a': (live: 0, counted: 3),
        'b': (live: 0, counted: 3),
        'c': (live: 0, counted: 3),
      });
      final dots = globeDots(snap, {for (final c in ['a', 'b', 'c']) c: (lat: 0.0, lon: 0.0)});
      expect(dots.every((d) => d.radius == dotMaxRadius), isTrue);
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

    test('DR6: from your dot to every other dot, each once', () {
      final dots = globeDots(snap, positions, yourCityId: 'amritsar', markedToday: true);
      final threads = globeThreads(dots);
      final you = dots.indexWhere((d) => d.kind == DotKind.you);
      expect(threads.every((t) => t.$1 == you), isTrue);
      // Every dot outside your own city, green and blue alike.
      expect(threads.length, dots.where((d) => d.cityId != 'amritsar').length);
    });

    test('DR7: without a profile, one connected web, each pair once', () {
      final dots = globeDots(snap, positions);
      final threads = globeThreads(dots);
      expect(threads.toSet().length, threads.length);
      // Union-find over cities.
      final parent = <String, String>{for (final c in positions.keys) c: c};
      String find(String x) => parent[x] == x ? x : (parent[x] = find(parent[x]!));
      for (final (a, b) in threads) {
        parent[find(dots[a].cityId)] = find(dots[b].cityId);
      }
      expect(positions.keys.map(find).toSet(), hasLength(1));
    });

    test('G-18: Europe is joined to the Gulf, not left on its own', () {
      final dots = globeDots(snap, positions);
      final threads = globeThreads(dots);
      bool linked(String x, String y) => threads.any((t) =>
          {dots[t.$1].cityId, dots[t.$2].cityId}.containsAll({x, y}));
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
