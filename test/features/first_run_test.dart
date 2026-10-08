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
}
