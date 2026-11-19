import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/audio/data/audio_controller.dart';
import 'package:hazri/features/live/data/live_controller.dart';
import 'package:hazri/features/live/domain/live_group.dart';
import 'package:hazri/features/live/ui/live_cards.dart';
import 'package:hazri/features/live/ui/live_screen.dart';
import 'package:hazri/features/profile/data/profile_controller.dart';
import 'package:hazri/features/sangat/ui/sangat_screen.dart';
import 'package:hazri/features/sangat/ui/sangat_widgets.dart';
import 'package:hazri/features/simran/data/simran_controller.dart';

import '../../app_harness.dart';
import '../profile/profile_fakes.dart';

/// 15-live-sangat §9 at the seams the rules live at.
void main() {
  late FakeServer server;
  late L l;

  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  Map<String, Object?> liveBody({bool joined = false, int listening = 4}) => {
        'builtAt': '2026-11-18T06:00:00Z',
        'groups': [
          for (final d in liveGroups)
            {
              'id': d.id,
              'listening': listening,
              'cities': 2,
              'cityIds': ['ludhiana', 'amritsar'],
              'members': joined ? 1 : 0,
              'minutesToday': 25,
              'minutesMonth': 300,
              'joins': [
                {'name': 'Harpreet K.', 'cityId': 'ludhiana', 'at': '2026-11-18T05:59:00Z'},
              ],
              'memberRows': const [],
              'joined': joined && d.id == 'naam-simran',
              'myMinutesMonth': joined ? 10 : null,
            },
        ],
      };

  setUp(() {
    server = FakeServer();
    server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
    server.on('GET', '/sangat/groups/mine', 200, {'groups': []});
    server.on('GET', '/sangat/groups/built-in', 200, {'groups': []});
    server.on('POST', '/sangat/contributions', 200, {'processed': []});
    server.on('GET', '/live', 200, liveBody());
    server.on('POST', '/live/naam-simran/listen', 200, {'result': 'COUNTED', 'nextInSeconds': 300});
  });

  group('LS6: the same second on every phone', () {
    test('S-3: two phones at the same instant are at the same place in the loop', () {
      final def = liveGroupById('mool-mantar')!;
      final at = DateTime.utc(2026, 11, 18, 6, 0, 7, 250);
      expect(liveOffset(at, def.length), liveOffset(at.toLocal(), def.length));
    });

    test('the loop starts again at 00:00 IST and wraps at its length', () {
      final def = liveGroupById('naam-simran')!; // 56 s
      // 00:00 IST is 18:30 UTC the day before.
      expect(liveOffset(DateTime.utc(2026, 11, 17, 18, 30), def.length), Duration.zero);
      expect(liveOffset(DateTime.utc(2026, 11, 17, 18, 31), def.length), const Duration(seconds: 4));
      expect(liveOffset(DateTime.utc(2026, 11, 17, 18, 30, 56), def.length), Duration.zero);
    });

    test('every live group has its bundled loop', () {
      for (final d in liveGroups) {
        expect(d.assetPath, 'assets/live/${d.id}.ogg');
      }
    });
  });

  group('LS7b: you are in the count for a day after you listen', () {
    const g = LiveGroupStatus(id: 'naam-simran', listening: 3, cities: 2, cityIds: ['ludhiana', 'amritsar']);
    final now = DateTime(2026, 11, 19, 10);

    test('the server count plus you, and your city once', () {
      final s = liveShown(g, heardAt: now.subtract(const Duration(minutes: 1)), now: now, yourCityId: 'toronto');
      expect((s.listening, s.cities), (4, 3));
      expect(s.cityIds, contains('toronto'));
      final same = liveShown(g, heardAt: now, now: now, yourCityId: 'ludhiana');
      expect((same.listening, same.cities), (4, 2));
    });

    test('not twice once the server counts you', () {
      const counted = LiveGroupStatus(id: 'naam-simran', listening: 3, cities: 2, youCounted: true);
      expect(liveShown(counted, heardAt: now, now: now).listening, 3);
    });

    test('and no longer after 24 hours', () {
      expect(liveShown(g, heardAt: now.subtract(const Duration(hours: 23, minutes: 59)), now: now).listening, 4);
      expect(liveShown(g, heardAt: now.subtract(const Duration(hours: 24)), now: now).listening, 3);
      expect(liveShown(g, heardAt: null, now: now).listening, 3);
    });
  });

  group('the listener', () {
    late TestApp app;
    late FakePaathPlayer player;

    Future<void> start({bool profile = false}) async {
      if (profile) server.on('GET', '/profile', 200, {'profile': profileJson()});
      player = FakePaathPlayer();
      app = await TestApp.create(
        prefs: {'onboarding_done': true},
        extra: [...server.overrides(), paathPlayerProvider.overrideWithValue(player)],
      );
      addTearDown(app.dispose);
      app.container.read(profileControllerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    test('LS6: listening loads the loop alone at the clock position and plays it', () async {
      await start();
      final def = liveGroupById('chaupai-sahib')!;
      await app.container.read(liveListenerProvider.notifier).listen(def, title: 'Chaupai Sahib');
      expect(player.looping, isTrue);
      expect(player.queued.single.assetPath, 'assets/live/chaupai-sahib.ogg');
      expect(player.position, lessThan(def.length));
      expect(player.isPlaying, isTrue);
      expect(app.container.read(liveListenerProvider), 'chaupai-sahib');
      // Kept on the phone so it counts itself for a day (LS7b).
      expect(app.container.read(liveHeardProvider)['chaupai-sahib'], isNotNull);
    });

    test('S-6: without a profile nothing is sent', () async {
      await start();
      await app.container.read(liveListenerProvider.notifier).listen(liveGroups.first, title: 'Naam Simran');
      await app.container.read(liveListenerProvider.notifier).onTick();
      expect(server.requests.where((r) => r.contains('/listen')), isEmpty);
    });

    test('LS15: with a profile, a listening mark goes when it starts', () async {
      await start(profile: true);
      expect(app.container.read(profileControllerProvider), isA<ProfileLoaded>());
      await app.container.read(liveListenerProvider.notifier).listen(liveGroups.first, title: 'Naam Simran');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(server.requests.where((r) => r == 'POST /live/naam-simran/listen'), hasLength(1));
      // A tick inside five minutes sends no second mark.
      await app.container.read(liveListenerProvider.notifier).onTick();
      expect(server.requests.where((r) => r == 'POST /live/naam-simran/listen'), hasLength(1));
    });

    test('S-8: listening is not sitting: no simran session is recorded', () async {
      await start();
      await app.container.read(liveListenerProvider.notifier).listen(liveGroups.first, title: 'Naam Simran');
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await app.container.read(liveListenerProvider.notifier).onTick();
      expect(await app.container.read(userRepositoryProvider).allSittings(), isEmpty);
    });

    test('a bani taking the player ends the live listening', () async {
      await start();
      await app.container.read(liveListenerProvider.notifier).listen(liveGroups.first, title: 'Naam Simran');
      await player.setQueue([player.queued.single]);
      await app.container.read(liveListenerProvider.notifier).onTick();
      expect(app.container.read(liveListenerProvider), isNull);
    });

    test('S-7: a sitting in a live group plays the loop and is logged as a sitting', () async {
      // The screen stays awake during a sitting; a test has no screen.
      for (final m in ['toggle', 'isEnabled']) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$m',
          (_) async => const StandardMessageCodec().encodeMessage(<Object?>[false]),
        );
      }
      await start();
      final def = liveGroups.first;
      final simran = app.container.read(simranSessionProvider.notifier);
      await simran.start(
        title: 'Naam Simran',
        length: const Duration(minutes: 11),
        playAudio: () => app.container.read(liveListenerProvider.notifier).listen(def, title: 'Naam Simran'),
      );
      expect(player.looping, isTrue);
      await simran.finish(completed: true);
      final sat = await app.container.read(userRepositoryProvider).allSittings();
      expect(sat, hasLength(1));
      expect(sat.single.completed, isTrue);
      // The reminders re-plan a moment after a sitting ends; let it run
      // before the container goes.
      await Future<void>.delayed(const Duration(seconds: 1));
    });
  });

  test('LS7a: seconds listened add up per group, today and this month', () async {
    final app = await TestApp.create(now: DateTime(2026, 11, 18, 9));
    addTearDown(app.dispose);
    final repo = app.container.read(userRepositoryProvider);
    await repo.addLiveSeconds('naam-simran', 600);
    await repo.addLiveSeconds('naam-simran', 300);
    await repo.addLiveSeconds('mool-mantar', 60);
    final s = await repo.liveSeconds();
    expect(s['naam-simran'], (today: 900, month: 900));
    expect(s['mool-mantar'], (today: 60, month: 60));
  });

  group('the Sangat tab', () {
    late TestApp app;

    Future<void> boot(WidgetTester tester) async {
      app = await TestApp.create(prefs: {'onboarding_done': true}, extra: server.overrides());
      addTearDown(app.dispose);
      usePhoneFrame(tester);
      await tester.pumpWidget(app.wrapRouted(const SangatScreen()));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await settle(tester);
    }

    testWidgets('S-1: in no group, it opens on Discover with the three live cards first', (tester) async {
      await boot(tester);
      expect(find.byType(LiveCard), findsNWidgets(3));
      expect(find.text(l.liveListening(4)), findsNWidgets(3));
      expect(find.text(l.sangatTabMine(0)), findsOneWidget);
      // Every card is on screen at once (LS3).
      for (final e in find.byType(LiveCard).evaluate()) {
        expect(tester.getRect(find.byWidget(e.widget)).right, lessThanOrEqualTo(390));
      }
    });

    testWidgets('S-2 and S-8a: in a live group, it opens on My groups with Create and Join on top '
        'and the minutes you listened today', (tester) async {
      server.on('GET', '/live', 200, liveBody(joined: true));
      await tester.runAsync(() async {
        app = await TestApp.create(prefs: {'onboarding_done': true}, extra: server.overrides());
        await app.container.read(userRepositoryProvider).addLiveSeconds('naam-simran', 15 * 60);
      });
      addTearDown(app.dispose);
      usePhoneFrame(tester);
      // The live answer is cached first, as it would be from an earlier visit.
      await tester.runAsync(() => app.container.read(liveStatusProvider.notifier).refresh());
      await tester.pumpWidget(app.wrapRouted(const SangatScreen()));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await settle(tester);
      expect(find.text(l.sangatTabMine(1)), findsOneWidget);
      expect(find.byType(LiveCard), findsNothing);
      final create = tester.getRect(find.widgetWithText(SangatActionTile, l.sangatCreate));
      final live = tester.getRect(find.byType(LiveRow));
      expect(create.bottom, lessThan(live.top));
      expect(find.text(l.liveYouListened(15)), findsOneWidget);
    });
  });

  group('the live page', () {
    for (final locale in const [Locale('en'), Locale('pa'), Locale('hi')]) {
      testWidgets('LS5, LS8: it lays out in ${locale.languageCode} with the feed and the sheet', (tester) async {
        final player = FakePaathPlayer();
        late TestApp app;
        await tester.runAsync(() async {
          app = await TestApp.create(
            prefs: {'onboarding_done': true},
            extra: [...server.overrides(), paathPlayerProvider.overrideWithValue(player)],
          );
        });
        addTearDown(app.dispose);
        usePhoneFrame(tester);
        await tester.pumpWidget(app.wrapRouted(const LiveScreen(groupId: 'mool-mantar'), locale: locale));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(player.looping, isTrue);
        expect(find.text(liveGroupById('mool-mantar')!.nameFor(locale.languageCode)), findsOneWidget);
        if (locale.languageCode == 'en') {
          expect(find.text(l.liveTag), findsOneWidget);
          // The server's four and you, without a profile too (LS7b).
          expect(find.text(l.liveListening(5)), findsOneWidget);
          expect(find.textContaining('Harpreet K. joined from'), findsOneWidget);
          expect(find.text(l.liveSwipeUp), findsOneWidget);
          // S-6: without a profile, Join asks for one.
          await tester.tap(find.text(l.liveJoin));
          await settle(tester);
          expect(find.text(l.liveJoinNeedsProfile), findsOneWidget);
          expect(server.requests.where((r) => r.contains('/join')), isEmpty);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  });

  testWidgets('a joined page has no Joined button, and the ⋮ sits at the right', (tester) async {
    server.on('GET', '/live', 200, liveBody(joined: true));
    final player = FakePaathPlayer();
    late TestApp app;
    await tester.runAsync(() async {
      app = await TestApp.create(
        prefs: {'onboarding_done': true},
        extra: [...server.overrides(), paathPlayerProvider.overrideWithValue(player)],
      );
    });
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const LiveScreen(groupId: 'naam-simran')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
    expect(find.text(l.liveJoin), findsNothing);
    expect(find.text(l.liveJoined), findsNothing);
    final menu = tester.getRect(find.byType(PopupMenuButton<int>));
    expect(menu.right, greaterThan(390 - 40));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('with the screen off the page stops asking for counts, and asks again when it is back', (tester) async {
    final player = FakePaathPlayer();
    late TestApp app;
    await tester.runAsync(() async {
      app = await TestApp.create(
        prefs: {'onboarding_done': true},
        extra: [...server.overrides(), paathPlayerProvider.overrideWithValue(player)],
      );
    });
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const LiveScreen(groupId: 'naam-simran')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
    int asks() => server.requests.where((r) => r == 'GET /live').length;
    final before = asks();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 7));
    expect(asks(), before);
    expect(player.isPlaying, isTrue); // the sound goes on
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    expect(asks(), before + 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
