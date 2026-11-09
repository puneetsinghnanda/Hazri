import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/simran/data/presence_repository.dart';
import 'package:hazri/features/simran/domain/simran_presence.dart';
import 'package:hazri/features/simran/ui/simran_globe.dart';
import 'package:hazri/features/simran/ui/simran_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_harness.dart';
import '../features/profile/profile_fakes.dart';

/// 07-simran §9 at the screen and service seams, against a fake server.
void main() {
  late FakeServer server;
  late L l;

  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  final snapshot = {
    'day': '2026-10-08',
    'live': 30,
    'counted': 50,
    'builtAt': '2026-10-08T03:00:00.000Z',
    'countries': {
      'IN': {
        'l': 30, 'c': 50,
        's': {
          'IN-DL': {'l': 20, 'c': 30, 'k': {'new_delhi': [20, 30]}},
        },
      },
    },
  };

  setUp(() {
    server = FakeServer();
    server.on('GET', '/presence/globe', 200, snapshot);
    server.on('POST', '/presence/attendance', 200, {'result': 'ATTENDANCE_MARKED', 'day': '2026-10-08'});
  });

  Future<TestApp> pump(WidgetTester tester, {bool profile = false, Locale locale = const Locale('en')}) async {
    server.on('GET', '/profile', profile ? 200 : 404, profile ? {'profile': profileJson()} : errorJson('NO_PROFILE'));
    final app = await TestApp.create(prefs: {'onboarding_done': true}, extra: server.overrides());
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const SimranScreen(), locale: locale));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await settle(tester);
    return app;
  }

  testWidgets('G-6: no profile → the live count, three legend entries, the banner', (tester) async {
    await pump(tester);
    expect(find.bySemanticsLabel(l.globeLiveCount(30)), findsOneWidget);
    // CT3: everyone counted and not live; without a profile nobody is taken off.
    expect(find.bySemanticsLabel(l.globeHereCount(20)), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text(l.simranLegendYou), findsOneWidget);
    expect(find.text(l.simranLegendLive), findsOneWidget);
    expect(find.text(l.simranLegendHere), findsOneWidget);
    expect(find.text(l.globeProfileBanner), findsOneWidget);
    expect(server.requests, isNot(contains('POST /presence/attendance')));
  });

  testWidgets('G-13: offline with nothing saved says so; the globe still draws', (tester) async {
    server.offline = true;
    await pump(tester);
    expect(find.text(l.globeOffline), findsOneWidget);
    expect(find.byType(SimranGlobe), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with a profile there is no banner', (tester) async {
    await pump(tester, profile: true);
    expect(find.text(l.globeProfileBanner), findsNothing);
  });

  testWidgets('the globe draws, and turns by hand', (tester) async {
    await pump(tester, profile: true);
    await tester.drag(find.byType(SimranGlobe), const Offset(-60, 0));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  group('CT1, CT2 at the screen: the line counts you as the dots do', () {
    // The owner's report of 2026-10-17: marked a minute ago, and the snapshot
    // is from before that, so it still has you under Here today.
    Future<void> pumpMarked(WidgetTester tester, {required Duration builtAfterMark}) async {
      final now = DateTime.now().toUtc();
      final day = istDay(now);
      final markedAt = now.subtract(const Duration(minutes: 1));
      server.on('GET', '/presence/globe', 200, {
        ...snapshot,
        'day': day,
        'builtAt': markedAt.add(builtAfterMark).toIso8601String(),
      });
      server.on('GET', '/profile', 200, {'profile': profileJson()});
      final app = await TestApp.create(prefs: {
        'onboarding_done': true,
        PresenceService.kAttendance: day,
        PresenceService.kAttendanceAt: markedAt.toIso8601String(),
      }, extra: server.overrides());
      addTearDown(app.dispose);
      usePhoneFrame(tester);
      await tester.pumpWidget(app.wrapRouted(const SimranScreen()));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await settle(tester);
    }

    testWidgets('a snapshot from before your mark: its 30, plus you', (tester) async {
      await pumpMarked(tester, builtAfterMark: const Duration(seconds: -30));
      expect(find.bySemanticsLabel(l.globeLiveCount(31)), findsOneWidget);
      // CT3: still in the snapshot's blue, so you come off it (you are orange).
      expect(find.bySemanticsLabel(l.globeHereCount(19)), findsOneWidget);
    });

    testWidgets('a snapshot from after it already counts you: 30', (tester) async {
      await pumpMarked(tester, builtAfterMark: const Duration(seconds: 30));
      expect(find.bySemanticsLabel(l.globeLiveCount(30)), findsOneWidget);
      expect(find.bySemanticsLabel(l.globeHereCount(20)), findsOneWidget);
    });
  });

  testWidgets('CT3, design 124: during a sitting both counts stay, '
      'either side of the countdown', (tester) async {
    await pump(tester);
    await tester.tap(find.text(l.simranBeginMinutes(5)));
    await tester.pump();
    final clock = find.text(l.simranLeftOf('5:00'));
    expect(clock, findsOneWidget);
    final live = find.bySemanticsLabel(l.globeLiveCount(30));
    final here = find.bySemanticsLabel(l.globeHereCount(20));
    expect(live, findsOneWidget);
    expect(here, findsOneWidget);
    expect(tester.getCenter(live).dx, lessThan(tester.getCenter(clock).dx));
    expect(tester.getCenter(here).dx, greaterThan(tester.getCenter(clock).dx));
    // The session's ticker outlives the tree; end it so no timer is left.
    await tester.tap(find.text(l.simranEnd));
    await settle(tester);
  });

  group('attendance (AT1–AT4)', () {
    testWidgets('G-3, G-4: once a day, then never again that day', (tester) async {
      final app = await pump(tester, profile: true);
      final service = app.container.read(presenceServiceProvider);
      await tester.runAsync(service.markAttendance);
      await tester.runAsync(service.markAttendance);
      await tester.runAsync(service.markAttendance);
      expect(server.requests.where((r) => r == 'POST /presence/attendance'), hasLength(1));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PresenceService.kAttendance), isNotNull);
    });

    testWidgets('G-5: a failure leaves the flag unset, so it is tried again', (tester) async {
      final app = await pump(tester, profile: true);
      server.offline = true;
      final service = app.container.read(presenceServiceProvider);
      await tester.runAsync(service.markAttendance);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PresenceService.kAttendance), isNull);
      server.offline = false;
      await tester.runAsync(service.markAttendance);
      expect(prefs.getString(PresenceService.kAttendance), isNotNull);
    });

    testWidgets('AT2: never without a profile', (tester) async {
      final app = await pump(tester);
      await tester.runAsync(app.container.read(presenceServiceProvider).markAttendance);
      expect(server.requests, isNot(contains('POST /presence/attendance')));
    });
  });

  for (final locale in [const Locale('pa'), const Locale('hi')]) {
    testWidgets('lays out without overflowing in ${locale.languageCode}', (tester) async {
      await pump(tester, locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
