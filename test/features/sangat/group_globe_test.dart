import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/sangat/domain/group_globe.dart';
import 'package:hazri/features/simran/domain/simran_presence.dart';

/// 08-sangat GG1–GG5 as pure functions: the reply, the split, the key and
/// the arrivals.
void main() {
  const positions = {
    'new_delhi': (lat: 28.6, lon: 77.2),
    'amritsar': (lat: 31.6, lon: 74.9),
    'london': (lat: 51.5, lon: -0.1),
  };

  // 24 members: Delhi 9 (4 today), Amritsar 6 (3 today), London 5 (2 today),
  // a city the phone does not know 1 (1 today), and 3 with no city (1 today).
  final reply = {
    'day': '2026-10-09',
    'builtAt': '2026-10-09T03:28:00.000Z',
    'cities': {
      'new_delhi': [4, 9],
      'amritsar': [3, 6],
      'london': [2, 5],
      'atlantis': [1, 1],
    },
    'unplaced': {'today': 1, 'members': 3},
    'recent': [
      {'cityId': 'amritsar', 'at': '2026-10-09T03:25:00.000Z', 'amount': 1},
      {'cityId': null, 'at': '2026-10-09T03:10:00.000Z', 'amount': 1},
      {'cityId': 'london', 'at': '2026-10-09T02:40:00.000Z', 'amount': 1},
      {'cityId': 'new_delhi', 'at': '2026-10-09T02:00:00.000Z', 'amount': 1},
    ],
  };
  final globe = GroupGlobe.fromJson(reply);

  int sum(List<GlobeDot> dots, DotKind k, [String? city]) =>
      dots.where((d) => d.kind == k && (city == null || d.cityId == city)).fold(0, (n, d) => n + d.count);

  group('7.15 reply', () {
    test('reads the cities, the unplaced and the recent, newest first as sent', () {
      expect(globe.day, '2026-10-09');
      expect(globe.builtAt, DateTime.utc(2026, 10, 9, 3, 28));
      expect(globe.cities['new_delhi'], (today: 4, members: 9));
      expect(globe.totalToday, 11);
      expect(globe.totalMembers, 24);
      expect(globe.recent.first.cityId, 'amritsar');
      expect(globe.recent[1].cityId, isNull);
    });

    test('a malformed entry is passed over, not thrown on', () {
      final g = GroupGlobe.fromJson({
        'day': '2026-10-09',
        'cities': {
          'x': 'nonsense',
          'y': [1],
        },
        'recent': [
          {'cityId': 'x'},
          'nonsense',
        ],
      });
      expect(g.cities, isEmpty);
      expect(g.recent, isEmpty);
      expect(g.totalMembers, 0);
    });
  });

  group('GG3 the dots', () {
    test('green is today, blue is the rest, per city, sized by SZ1', () {
      final dots = groupGlobeDots(globe, positions);
      expect(sum(dots, DotKind.live, 'new_delhi'), 4);
      expect(sum(dots, DotKind.here, 'new_delhi'), 5);
      expect(dots.firstWhere((d) => d.cityId == 'new_delhi' && d.kind == DotKind.here).radius, dotRadius(5));
      expect(sum(dots, DotKind.you), 0);
    });

    test('you today: orange on your city, taken off its green', () {
      final dots = groupGlobeDots(globe, positions, viewer: (cityId: 'amritsar', today: true));
      expect(sum(dots, DotKind.you, 'amritsar'), 1);
      expect(sum(dots, DotKind.live, 'amritsar'), 2);
      expect(sum(dots, DotKind.here, 'amritsar'), 3);
      // Nobody else is taken off.
      expect(sum(dots, DotKind.live, 'new_delhi'), 4);
    });

    test('you not today: taken off your city\'s blue', () {
      final dots = groupGlobeDots(globe, positions, viewer: (cityId: 'amritsar', today: false));
      expect(sum(dots, DotKind.you, 'amritsar'), 1);
      expect(sum(dots, DotKind.live, 'amritsar'), 3);
      expect(sum(dots, DotKind.here, 'amritsar'), 2);
    });

    test('no profile: nothing taken off and no orange dot', () {
      final dots = groupGlobeDots(globe, positions);
      expect(sum(dots, DotKind.live, 'amritsar'), 3);
      expect(sum(dots, DotKind.here, 'amritsar'), 3);
      expect(dots.where((d) => d.kind == DotKind.you), isEmpty);
    });

    test('a city content.db does not know is not drawn', () {
      final dots = groupGlobeDots(globe, positions);
      expect(dots.where((d) => d.cityId == 'atlantis'), isEmpty);
      // The members with no city are not drawn either (GG2).
      expect(sum(dots, DotKind.live) + sum(dots, DotKind.here), 20);
    });

    test('GG8: no globe yet draws only you', () {
      final dots = groupGlobeDots(null, positions, viewer: (cityId: 'london', today: false));
      expect(dots, hasLength(1));
      expect(dots.single.kind, DotKind.you);
    });

    test('the threads and arcs are the Simran globe\'s, joining every city', () {
      final dots = groupGlobeDots(globe, positions, viewer: (cityId: 'london', today: true));
      final threads = globeThreads(dots);
      expect(threads.where((t) => t.mine).map((t) => dots[t.b].cityId).toSet(), {'new_delhi', 'amritsar'});
      expect(globeArcs(dots, threads), hasLength(threads.length));
    });
  });

  group('GG1 the key', () {
    test('you today: You · 10 today · 13 not yet, adding up to 24 members', () {
      final k = groupGlobeKey(globe, viewer: (cityId: 'amritsar', today: true));
      expect(k, (today: 10, notYet: 13, cities: 4));
      expect(1 + k.today + k.notYet, globe.totalMembers);
    });

    test('you not today come off not yet', () {
      expect(groupGlobeKey(globe, viewer: (cityId: 'amritsar', today: false)), (today: 11, notYet: 12, cities: 4));
    });

    test('no profile: nothing taken off', () {
      expect(groupGlobeKey(globe), (today: 11, notYet: 13, cities: 4));
    });

    test('a city missing from content.db still counts, and so do the members with no city', () {
      // atlantis is one of the four cities; the three unplaced are in today
      // and not yet.
      final k = groupGlobeKey(globe);
      expect(k.cities, 4);
      expect(k.today + k.notYet, 24);
    });

    test('your city counts once, even before the server has placed you', () {
      final k = groupGlobeKey(globe, viewer: (cityId: 'toronto', today: false));
      expect(k.cities, 5);
    });

    test('never below zero', () {
      const empty = GroupGlobe(day: '2026-10-09', cities: {});
      expect(groupGlobeKey(empty, viewer: (cityId: 'london', today: true)), (today: 0, notYet: 0, cities: 1));
    });
  });

  group('GG4, GG5 arrivals', () {
    final now = DateTime.utc(2026, 10, 9, 3, 30);

    test('the last hour, oldest first', () {
      final a = recentArrivals(globe, now);
      expect(a.map((x) => x.at), [
        DateTime.utc(2026, 10, 9, 2, 40),
        DateTime.utc(2026, 10, 9, 3, 10),
        DateTime.utc(2026, 10, 9, 3, 25),
      ]);
      expect(arrivalsAmount(a), 3);
    });

    test('a copy kept from earlier ages out rather than replaying old paath', () {
      expect(recentArrivals(globe, now.add(const Duration(hours: 2))), isEmpty);
    });

    test('Naam Simran counts its minutes', () {
      final g = GroupGlobe.fromJson({
        'day': '2026-10-09',
        'cities': {},
        'recent': [
          {'cityId': 'london', 'at': '2026-10-09T03:20:00Z', 'amount': 11},
          {'cityId': null, 'at': '2026-10-09T03:00:00Z', 'amount': 5},
        ],
      });
      expect(arrivalsAmount(recentArrivals(g, now)), 16);
    });

    test('on opening all are played; afterwards only those newer than the last played', () {
      final a = recentArrivals(globe, now);
      expect(arrivalsToPlay(a, null), a);
      expect(arrivalsToPlay(a, DateTime.utc(2026, 10, 9, 3, 10)).map((x) => x.cityId), ['amritsar']);
      expect(arrivalsToPlay(a, DateTime.utc(2026, 10, 9, 3, 25)), isEmpty);
    });
  });
}
