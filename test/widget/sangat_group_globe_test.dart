import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hazri/app/router.dart' show Routes;
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/settings/settings_controller.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/features/about/ui/privacy_screen.dart';
import 'package:hazri/features/sangat/data/group_globe_controller.dart';
import 'package:hazri/features/sangat/data/sangat_controller.dart';
import 'package:hazri/features/sangat/ui/group_globe.dart';
import 'package:hazri/features/sangat/ui/group_screen.dart';
import 'package:hazri/features/simran/domain/simran_presence.dart';
import 'package:hazri/features/simran/domain/world_outline.dart';
import 'package:hazri/features/simran/ui/simran_globe.dart';

import '../app_harness.dart';
import '../features/profile/profile_fakes.dart';

/// 08-sangat GG1–GG9 at the group screen, against a fake server: the key's
/// numbers, the arrivals line and its light, the copy on the phone first.
void main() {
  late L l;

  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  final now = DateTime(2026, 10, 9, 9);
  String ago(int minutes) => now.toUtc().subtract(Duration(minutes: minutes)).toIso8601String();

  Map<String, Object?> goal({String type = 'BANI', String status = 'ACTIVE'}) => {
    'goalId': 'g0002',
    'type': type,
    'baniId': type == 'BANI' ? 'JAPJ' : null,
    'target': 5000,
    'startDay': '2026-10-01',
    'endDay': '2026-12-31',
    'status': status,
    'total': 3412,
    'pct': 68,
    'todayTotal': 46,
    'daysLeft': 84,
  };

  Map<String, Object?> groupBody(String id, Map<String, Object?> goal) => {
    'groupId': id,
    'kind': 'CUSTOM',
    'name': 'Gill Parivar',
    'status': 'ACTIVE',
    'memberCount': 24,
    'isMember': true,
    'role': 'MEMBER',
    'goal': goal,
    'members': [
      {
        'memberKey': 'm1',
        'name': 'Charanjit Singh',
        'role': 'MEMBER',
        'status': 'ACTIVE',
        'contribution': 96,
        'isYou': true,
      },
    ],
    'moreMembers': 0,
  };

  // 24 members: Amritsar 6 (3 today), Delhi 9 (4 today), London 5 (2 today),
  // a city content.db does not know 1 (1 today), 3 with no profile (1 today).
  Map<String, Object?> globe({List<Map<String, Object?>>? recent}) => {
    'day': '2026-10-09',
    'builtAt': ago(1),
    'cities': {
      'amritsar': [3, 6],
      'new_delhi': [4, 9],
      'london': [2, 5],
      'atlantis': [1, 1],
    },
    'unplaced': {'today': 1, 'members': 3},
    'recent':
        recent ??
        [
          {'cityId': 'amritsar', 'at': ago(5), 'amount': 1},
          {'cityId': null, 'at': ago(20), 'amount': 1},
          {'cityId': 'london', 'at': ago(50), 'amount': 1},
          // Older than the hour: not counted, not played.
          {'cityId': 'london', 'at': ago(70), 'amount': 1},
        ],
  };

  late FakeServer server;

  Future<TestApp> boot(
    WidgetTester tester, {
    bool profile = true,
    Map<String, Object?>? groupJson,
    Map<String, Object?>? globeJson,
    Map<String, Object> prefs = const {},
    bool reduceMotion = false,
    Future<void> Function(UserRepository repo)? seed,
    void Function()? onFirstFrame,
  }) async {
    server = FakeServer();
    server.on(
      'GET',
      '/profile',
      profile ? 200 : 404,
      profile ? {'profile': profileJson(cityId: 'amritsar')} : errorJson('NO_PROFILE'),
    );
    server.on('GET', '/sangat/groups/mine', 200, {'groups': []});
    server.on('GET', '/sangat/groups/built-in', 200, {'groups': []});
    server.on('GET', '/sangat/groups/gill', 200, {'group': groupJson ?? groupBody('gill', goal())});
    if (globeJson != null) server.on('GET', '/sangat/groups/gill/globe', 200, globeJson);
    server.on('POST', '/sangat/contributions', 200, {'processed': []});
    final app = await TestApp.create(
      prefs: {'onboarding_done': true, ...prefs},
      now: now,
      extra: [...server.overrides(), worldOutlineProvider.overrideWith((ref) async => WorldOutline.empty)],
    );
    addTearDown(app.dispose);
    if (seed != null) await tester.runAsync(() => seed(app.container.read(userRepositoryProvider)));
    usePhoneFrame(tester);
    final router = GoRouter(
      initialLocation: Routes.sangatGroup('gill'),
      routes: [
        GoRoute(path: Routes.sangat, builder: (_, _) => const Text('SANGAT TAB')),
        GoRoute(
          path: '/sangat-group/:id',
          builder: (_, s) => GroupScreen(groupId: s.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: app.container,
        child: MaterialApp.router(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: HazriTheme.light(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
        ),
      ),
    );
    onFirstFrame?.call();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
    return app;
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  }

  int globeFetches() => server.requests.where((r) => r == 'GET /sangat/groups/gill/globe').length;

  group('GG1 the key', () {
    testWidgets('you have added today: You · 10 today · 13 not yet · 4 cities', (tester) async {
      await boot(
        tester,
        globeJson: globe(),
        seed: (repo) =>
            repo.logCompletion(baniId: 'JAPJ', slot: BaniSlotValue.morning, source: CompletionSource.reader),
      );
      expect(find.byType(SimranGlobe), findsOneWidget);
      expect(find.bySemanticsLabel(l.sangatGlobeKey('10', '13', '4')), findsOneWidget);
      // The total, of the target and the percentage stay under the ring.
      expect(find.text('3,412'), findsOneWidget);
      expect(find.text(l.sangatOfTarget('5,000')), findsOneWidget);
      expect(find.text('68%'), findsOneWidget);
      await drain(tester);
    });

    testWidgets('not yet today, you come off not yet instead', (tester) async {
      final app = await boot(tester, globeJson: globe());
      expect(find.bySemanticsLabel(l.sangatGlobeKey('11', '12', '4')), findsOneWidget);
      final drawing = app.container.read(groupGlobeDrawingProvider('gill'));
      // You in orange on Amritsar, taken off its blue: 3 green, 2 blue.
      int count(DotKind k) =>
          drawing.dots.where((d) => d.cityId == 'amritsar' && d.kind == k).fold(0, (n, d) => n + d.count);
      expect(count(DotKind.you), 1);
      expect(count(DotKind.live), 3);
      expect(count(DotKind.here), 2);
      await drain(tester);
    });

    testWidgets('without a profile nothing is taken off and You is not in the key', (tester) async {
      final app = await boot(tester, profile: false, globeJson: globe());
      final parts = l.sangatGlobeKey('11', '13', '4').split(' · ');
      expect(find.bySemanticsLabel(parts.skip(1).join(' · ')), findsOneWidget);
      expect(find.text(parts.first), findsNothing);
      final drawing = app.container.read(groupGlobeDrawingProvider('gill'));
      expect(drawing.dots.where((d) => d.kind == DotKind.you), isEmpty);
      await drain(tester);
    });

    testWidgets('the tap card says today and not yet', (tester) async {
      await boot(tester, globeJson: globe());
      final g = tester.widget<SimranGlobe>(find.byType(SimranGlobe));
      expect(g.liveTip!(3), l.sangatGlobeTipToday(3));
      expect(g.hereTip!(2), l.sangatGlobeTipNotYet(2));
      await drain(tester);
    });
  });

  group('GG5 the arrivals line', () {
    testWidgets('a bani goal counts the paath of the last hour', (tester) async {
      await boot(tester, globeJson: globe());
      expect(find.text(l.sangatArrivals('3')), findsOneWidget);
      await drain(tester);
    });

    testWidgets('a Naam Simran goal adds up the minutes', (tester) async {
      await boot(
        tester,
        groupJson: groupBody('gill', goal(type: 'SIMRAN')),
        globeJson: globe(
          recent: [
            {'cityId': 'london', 'at': ago(10), 'amount': 11},
            {'cityId': null, 'at': ago(30), 'amount': 5},
          ],
        ),
      );
      expect(find.text(l.sangatArrivalsMinutes('16')), findsOneWidget);
      await drain(tester);
    });

    testWidgets('hidden when nothing arrived', (tester) async {
      await boot(tester, globeJson: globe(recent: []));
      expect(find.byType(GroupArrivalsLine), findsOneWidget);
      expect(find.text(l.sangatArrivals('0')), findsNothing);
      expect(find.textContaining('last hour'), findsNothing);
      await drain(tester);
    });

    testWidgets('GG9: none for an ended goal, and no light', (tester) async {
      await boot(
        tester,
        groupJson: groupBody('gill', goal(status: 'COMPLETED')),
        globeJson: globe(),
      );
      expect(find.textContaining('last hour'), findsNothing);
      expect(tester.state<GroupArrivalsState>(find.byType(GroupArrivals)).queued, isEmpty);
      // The globe stays as it was.
      expect(find.bySemanticsLabel(l.sangatGlobeKey('11', '12', '4')), findsOneWidget);
      await drain(tester);
    });
  });

  group('GG4 the light', () {
    testWidgets('on opening, the last hour plays oldest first, 0.8 s apart; then only new ones', (tester) async {
      await boot(tester, globeJson: globe());
      final state = tester.state<GroupArrivalsState>(find.byType(GroupArrivals));
      expect(state.queued.map((a) => a.cityId), ['london', null, 'amritsar']);
      server.on(
        'GET',
        '/sangat/groups/gill/globe',
        200,
        globe(
          recent: [
            {'cityId': 'new_delhi', 'at': ago(0), 'amount': 1},
            {'cityId': 'amritsar', 'at': ago(5), 'amount': 1},
            {'cityId': null, 'at': ago(20), 'amount': 1},
            {'cityId': 'london', 'at': ago(50), 'amount': 1},
          ],
        ),
      );
      final before = globeFetches();
      // GG6: the next fetch is two minutes on.
      await tester.pump(const Duration(minutes: 2));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await settle(tester);
      expect(globeFetches(), before + 1);
      expect(state.queued.map((a) => a.cityId), ['london', null, 'amritsar', 'new_delhi']);
      expect(find.text(l.sangatArrivals('4')), findsOneWidget);
      await drain(tester);
    });

    testWidgets('GG4a: with nothing arriving, every dot in view is still tied to the ring', (tester) async {
      await boot(tester, globeJson: globe(recent: []));
      final tethers = tester.widget<GroupTethers>(find.byType(GroupTethers));
      final inView = [
        for (final d in tethers.dots)
          if (tethers.project(d.lat, d.lon).front) d.kind,
      ];
      expect(inView, containsAll([DotKind.you, DotKind.live, DotKind.here]));
      expect(tethers.starts().map((s) => s.kind), inView);
      expect(tester.state<GroupArrivalsState>(find.byType(GroupArrivals)).queued, isEmpty);
      await drain(tester);
    });

    testWidgets('the flights are spaced 0.8 s apart', (tester) async {
      await boot(tester, globeJson: globe());
      final state = tester.state<GroupArrivalsState>(find.byType(GroupArrivals));
      final s = state.starts;
      expect(s, hasLength(3));
      expect(s[1] - s[0], const Duration(milliseconds: 800));
      expect(s[2] - s[1], const Duration(milliseconds: 800));
      await drain(tester);
    });

    testWidgets('with reduced motion no light runs, and the line still counts', (tester) async {
      await boot(tester, globeJson: globe(), reduceMotion: true);
      expect(tester.state<GroupArrivalsState>(find.byType(GroupArrivals)).queued, isEmpty);
      expect(find.text(l.sangatArrivals('3')), findsOneWidget);
      await drain(tester);
    });
  });

  group('GG6, GG8 the copy on the phone', () {
    testWidgets('the copy is shown first and kept when the server cannot be reached', (tester) async {
      // No route for the globe: every fetch fails.
      final app = await boot(
        tester,
        prefs: {
          GroupGlobeCache.key: jsonEncode({'gill': globe()}),
        },
      );
      expect(globeFetches(), greaterThan(0));
      expect(find.bySemanticsLabel(l.sangatGlobeKey('11', '12', '4')), findsOneWidget);
      expect(app.container.read(groupGlobeProvider('gill')).offline, isTrue);
      await drain(tester);
    });

    testWidgets('the reply replaces the copy and is saved for next time', (tester) async {
      final reply = globe(recent: []);
      (reply['cities']! as Map<String, Object?>)['toronto'] = [0, 1];
      var first = false;
      final app = await boot(
        tester,
        globeJson: reply,
        prefs: {
          GroupGlobeCache.key: jsonEncode({'gill': globe()}),
          SangatCache.key: jsonEncode({
            'group:gill': {
              'savedAt': now.toIso8601String(),
              'body': {'group': groupBody('gill', goal())},
            },
          }),
        },
        // The first frame, before any reply, draws the copy
        // (before the profile is read, so nobody is taken off yet).
        onFirstFrame: () => first = find
            .byWidgetPredicate((w) => w is GroupGlobeKey && w.counts == (today: 11, notYet: 13, cities: 4))
            .evaluate()
            .isNotEmpty,
      );
      expect(first, isTrue);
      expect(find.bySemanticsLabel(l.sangatGlobeKey('11', '13', '5')), findsOneWidget);
      final saved =
          jsonDecode(app.container.read(sharedPreferencesProvider).getString(GroupGlobeCache.key)!)
              as Map<String, Object?>;
      expect((saved['gill']! as Map)['cities'], containsPair('toronto', [0, 1]));
      await drain(tester);
    });

    testWidgets('with no copy and no network the globe draws only you, and no key', (tester) async {
      final app = await boot(tester);
      final drawing = app.container.read(groupGlobeDrawingProvider('gill'));
      expect(drawing.dots.map((d) => d.kind), [DotKind.you]);
      expect(drawing.key, isNull);
      expect(find.byType(GroupGlobeKey), findsNothing);
      expect(tester.takeException(), isNull);
      await drain(tester);
    });
  });

  for (final locale in const [Locale('pa'), Locale('hi')]) {
    testWidgets('the band with its globe lays out in ${locale.languageCode}', (tester) async {
      final app = await boot(tester, globeJson: globe());
      final router = GoRouter(
        initialLocation: Routes.sangatGroup('gill'),
        routes: [
          GoRoute(
            path: '/sangat-group/:id',
            builder: (_, s) => GroupScreen(groupId: s.pathParameters['id']!),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: app.container,
          child: MaterialApp.router(
            locale: locale,
            localizationsDelegates: L.localizationsDelegates,
            supportedLocales: L.supportedLocales,
            theme: HazriTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      final ll = await L.delegate.load(locale);
      expect(find.text(ll.sangatArrivals('3')), findsOneWidget);
      await drain(tester);
    });
  }

  test('the projector puts the near side on the disc and the far side on its rim', () {
    final near = GlobePainter.locate(lat: 0, lon: 0, size: 190, zoom: 1, rotation: 0, tilt: 0);
    expect(near.front, isTrue);
    expect(near.at, const Offset(95, 95));
    final far = GlobePainter.locate(lat: 0, lon: 170, size: 190, zoom: 1, rotation: 0, tilt: 0);
    expect(far.front, isFalse);
    expect((far.at - const Offset(95, 95)).distance, closeTo(95, 1e-6));
  });

  testWidgets('the Simran globe\'s card takes the group\'s labels', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [worldOutlineProvider.overrideWith((ref) async => WorldOutline.empty)],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SimranGlobe(
                dots: const [
                  GlobeDot(cityId: 'accra', lat: 0, lon: 0, kind: DotKind.live, count: 3, radius: 7),
                  GlobeDot(cityId: 'accra', lat: 0, lon: 0, kind: DotKind.here, count: 2, radius: 6),
                ],
                cityNames: const {'accra': 'Accra'},
                size: 320,
                spinning: false,
                liveTip: l.sangatGlobeTipToday,
                hereTip: l.sangatGlobeTipNotYet,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(SimranGlobe)) + const Offset(10, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Accra'), findsOneWidget);
    expect(find.text(l.sangatGlobeTipToday(3)), findsOneWidget);
    expect(find.text(l.sangatGlobeTipNotYet(2)), findsOneWidget);
    expect(find.text(l.globeTipLive(3)), findsNothing);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('GG7: the privacy screen says what a group\'s globe shows, under joining a group', (tester) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const PrivacyScreen()));
    await settle(tester);
    final line = find.text(l.privacyGroupGlobe);
    await tester.scrollUntilVisible(line, 200, scrollable: find.byType(Scrollable).first);
    expect(line, findsOneWidget);
    expect(tester.getTopLeft(line).dy, greaterThan(tester.getTopLeft(find.text(l.privacyGroupToken)).dy));
  });
}
