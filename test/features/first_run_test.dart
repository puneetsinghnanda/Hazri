import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hazri/app/router.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/settings/app_settings.dart';
import 'package:hazri/core/settings/settings_controller.dart';
import 'package:hazri/core/theme/hazri_text.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/features/onboarding/ui/setup_screen.dart';
import 'package:hazri/features/onboarding/ui/welcome_screen.dart';
import 'package:hazri/features/profile/data/incoming_link.dart';
import 'package:hazri/features/profile/data/profile_controller.dart';
import 'package:hazri/features/profile/ui/city_field.dart';
import 'package:hazri/features/profile/ui/profile_made_screen.dart';

import 'profile/profile_fakes.dart';

import '../app_harness.dart';

/// 03-first-run: the flow through the app's real router, because the bugs
/// this file is about live in the redirect and not in any one screen.
void main() {
  late TestApp app;

  Future<GoRouter> pumpRouter(WidgetTester tester) async {
    usePhoneFrame(tester);
    final router = app.container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: app.container,
      child: MaterialApp.router(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: HazriTheme.light(),
        routerConfig: router,
      ),
    ));
    await tester.pump();
    return router;
  }

  String path(GoRouter r) {
    final last = r.routerDelegate.currentConfiguration.last;
    return last is ImperativeRouteMatch ? last.matches.uri.toString() : r.routerDelegate.currentConfiguration.uri.toString();
  }

  tearDown(() => app.dispose());

  testWidgets('F-a: a fresh install opens on Welcome at the first frame, no hold',
      (tester) async {
    app = await TestApp.create(now: DateTime(2026, 10, 8, 6));
    final router = await pumpRouter(tester);
    expect(path(router), Routes.intro);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('F-d: setup done goes straight to Today', (tester) async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 10, 8, 6),
    );
    final router = await pumpRouter(tester);
    expect(path(router), Routes.today);
    expect(find.byType(WelcomeScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  });

  testWidgets('F-l: an invite before setup is held, Welcome shows, setup is not interrupted',
      (tester) async {
    app = await TestApp.create(now: DateTime(2026, 10, 8, 6));
    final router = await pumpRouter(tester);
    router.go('https://hazri-dfcc1.web.app/j/ABCD2345');
    await tester.pump();
    expect(path(router), Routes.intro);
    final prefs = app.container.read(sharedPreferencesProvider);
    expect(prefs.getString(kHeldLink), '/sangat-join?code=ABCD2345');
  });

  testWidgets('F-e and F7: Skip is Gurmukhi at the standard size, then Today, then the held invite',
      (tester) async {
    app = await TestApp.create(
      prefs: {kHeldLink: '/sangat-join?code=ABCD2345'},
      now: DateTime(2026, 10, 8, 6),
    );
    final n = app.container.read(settingsProvider.notifier);
    await n.setScript(GurbaniScript.roman);
    await n.setReaderFontSize(30);
    final router = await pumpRouter(tester);
    router.go(Routes.setup(2));
    await settle(tester);

    final l = await L.delegate.load(const Locale('en'));
    await tester.tap(find.text(l.actionSkip));
    await settle(tester);
    // F10: Skip goes on to the profile step; Not now there ends setup.
    expect(path(router), Routes.setup(3));
    expect(find.text(l.setupProfileTitle), findsOneWidget);
    await tester.tap(find.text(l.actionNotNow));
    await settle(tester);

    final s = app.container.read(settingsProvider);
    expect(s.onboardingDone, isTrue);
    expect(s.script, GurbaniScript.gurmukhi);
    expect(s.readerFontSize, ReaderType.gurmukhiDefault);
    expect(path(router), '/sangat-join?code=ABCD2345');
    expect(app.container.read(sharedPreferencesProvider).getString(kHeldLink), isNull,
        reason: 'taken once, never offered twice');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  });

  testWidgets('F2: How you read shows a real line from content.db', (tester) async {
    app = await TestApp.create(now: DateTime(2026, 10, 8, 6));
    final router = await pumpRouter(tester);
    router.go(Routes.setup(2));
    await settle(tester);
    // The first verse of Japji Sahib, as the content pipeline stored it.
    final line = app.container.read(setupSampleLineProvider).value;
    expect(line, isNotNull);
    expect(line!.isHeading, isFalse);
    expect(find.text(line.gurmukhi), findsOneWidget);
  });

  // F10 (owner, 2026-11-18, option C): the profile is the last step of setup.
  group('the profile step (F10)', () {
    late FakeServer server;
    setUp(() {
      server = FakeServer();
      server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
    });

    Future<L> openStep(WidgetTester tester) async {
      app = await TestApp.create(now: DateTime(2026, 10, 8, 6), extra: server.overrides());
      final router = await pumpRouter(tester);
      router.go(Routes.setup(3));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await settle(tester);
      return L.delegate.load(const Locale('en'));
    }

    Future<void> fill(WidgetTester tester, L l, {String email = ''}) async {
      await tester.enterText(find.byType(TextFormField).first, 'Harpreet Kaur');
      await tester.tap(find.byType(CityField));
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextField, l.cityPickerSearch), 'Ludh');
      await settle(tester);
      await tester.tap(find.text('Ludhiana').last);
      await settle(tester);
      if (email.isNotEmpty) await tester.enterText(find.byType(TextFormField).last, email);
      await settle(tester);
    }

    Future<void> create(WidgetTester tester, L l) async {
      await tester.tap(find.text(l.setupProfileCreate));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await settle(tester);
    }

    testWidgets('the card fills in as you type', (tester) async {
      final l = await openStep(tester);
      expect(find.text(l.cardYourName), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Harpreet Kaur');
      await settle(tester);
      expect(find.text(l.cardYourName), findsNothing);
      expect(find.text('Harpreet Kaur'), findsWidgets);
    });

    testWidgets('with no email: made, setup done, Welcome on top of Today', (tester) async {
      server.on('POST', '/profile', 201, {'profile': profileJson(email: null, cityId: 'ludhiana')});
      final l = await openStep(tester);
      await fill(tester, l);
      await create(tester, l);
      expect(app.container.read(settingsProvider).onboardingDone, isTrue);
      expect(find.byType(ProfileMadeScreen), findsOneWidget);
      expect(find.text(l.profileMadeTitle('Harpreet')), findsOneWidget);
      expect(find.text(l.profileMadeNoEmailBody), findsOneWidget);
      expect(find.text(l.profileConfirmEmail), findsNothing);
      await tester.tap(find.text(l.profileMadeToday));
      await settle(tester);
      expect(path(app.container.read(routerProvider)), Routes.today);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 5));
    });

    testWidgets('with an email: Welcome offers Confirm my email', (tester) async {
      server.on('POST', '/profile', 201, {'profile': profileJson(cityId: 'ludhiana')});
      final l = await openStep(tester);
      await fill(tester, l, email: 'harpreet@example.com');
      await create(tester, l);
      expect(find.text(l.profileConfirmEmail), findsOneWidget);
      expect(find.text(l.profileMadeLater), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 5));
    });

    testWidgets('no connection: kept on the phone, setup ends on Today', (tester) async {
      final l = await openStep(tester);
      await fill(tester, l);
      server.offline = true;
      await create(tester, l);
      expect(app.container.read(settingsProvider).onboardingDone, isTrue);
      expect(find.text(l.setupProfileKept), findsOneWidget);
      expect(app.container.read(sharedPreferencesProvider).getString(ProfileController.kPending), isNotNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 5));
    });
  });
}
