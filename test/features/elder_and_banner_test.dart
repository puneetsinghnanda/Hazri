import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/app/router.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/settings/settings_controller.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/features/onboarding/ui/welcome_screen.dart';
import 'package:hazri/features/profile/data/profile_controller.dart';

import '../app_harness.dart';
import 'profile/profile_fakes.dart';

/// Owner, 2026-11-21: a tester's phone showed three tabs, Simran and Sangat
/// gone (elder mode, switched on by a large system font); and "Set up your
/// profile" showed when the server had only not answered.
void main() {
  late L l;
  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  Future<TestApp> pumpApp(WidgetTester tester, Map<String, Object> prefs, {List<Override> extra = const [], double width = 390}) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true, ...prefs}, now: DateTime(2026, 11, 21, 7), extra: extra);
    addTearDown(app.dispose);
    tester.view.physicalSize = Size(width * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: app.container,
      child: MaterialApp.router(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: HazriTheme.light(),
        routerConfig: app.container.read(routerProvider),
      ),
    ));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 300));
    return app;
  }

  group('PRD 4.17 as amended: elder mode is larger, never smaller', () {
    testWidgets('all five tabs in elder mode, on a narrow phone too', (tester) async {
      await pumpApp(tester, {'elder_mode': true}, width: 360);
      for (final t in [l.navToday, l.navNitnem, l.navSimran, l.navSangat, l.navDiary]) {
        expect(find.text(t), findsWidgets, reason: '$t must be in the bottom bar');
      }
      expect(tester.takeException(), isNull, reason: 'five larger tabs must fit at 360 dp');
    });

    testWidgets('F-2: a large system font no longer switches it on', (tester) async {
      final app = await TestApp.create(now: DateTime(2026, 11, 21, 7));
      addTearDown(app.dispose);
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: app.container,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5), size: Size(390, 844)),
          child: MaterialApp.router(
            localizationsDelegates: L.localizationsDelegates,
            supportedLocales: L.supportedLocales,
            theme: HazriTheme.light(),
            routerConfig: app.container.read(routerProvider),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      await tester.ensureVisible(find.text(l.welcomeBegin));
      await tester.tap(find.text(l.welcomeBegin));
      await tester.pump(const Duration(milliseconds: 300));
      expect(app.container.read(settingsProvider).elderMode, isFalse);
    });
  });

  group('01-accounts R10, R11: the profile banner and asking again', () {
    testWidgets('R10: the server not answering is not "Set up your profile"', (tester) async {
      final server = FakeServer()..offline = true;
      final app = await pumpApp(tester, const {}, extra: server.overrides());
      expect(app.container.read(profileControllerProvider), isA<ProfileUnavailable>());
      expect(find.text(l.profileBannerTitle), findsNothing);
    });

    testWidgets('R10: the server saying there is none still shows it', (tester) async {
      final server = FakeServer()..on('GET', '/profile', 404, errorJson('NO_PROFILE'));
      await pumpApp(tester, const {}, extra: server.overrides());
      expect(find.text(l.profileBannerTitle), findsOneWidget);
    });

    testWidgets('R11: unsure is asked again; a confirmed answer costs nothing', (tester) async {
      final server = FakeServer()..offline = true;
      final app = await pumpApp(tester, const {}, extra: server.overrides());
      final controller = app.container.read(profileControllerProvider.notifier);
      server
        ..offline = false
        ..on('GET', '/profile', 200, {'profile': profileJson()});
      await tester.runAsync(controller.recheckIfUnsure);
      expect(app.container.read(profileControllerProvider), isA<ProfileLoaded>());

      final asked = server.requests.where((r) => r == 'GET /profile').length;
      await tester.runAsync(controller.recheckIfUnsure);
      expect(server.requests.where((r) => r == 'GET /profile').length, asked, reason: 'a fresh profile is not asked about again');
    });
  });
}
