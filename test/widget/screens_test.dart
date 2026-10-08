import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/diary/ui/diary_screen.dart';
import 'package:hazri/features/nitnem/ui/nitnem_screen.dart';
import 'package:hazri/features/onboarding/ui/intro_screen.dart';
import 'package:hazri/features/reader/ui/reader_screen.dart';
import 'package:hazri/features/settings/ui/settings_screen.dart';
import 'package:hazri/features/simran/ui/simran_screen.dart';
import 'package:hazri/features/today/ui/today_screen.dart';

import '../app_harness.dart';

/// Renders each screen in all three languages and both themes.
///
/// These are smoke tests, not goldens: they prove the screens build from real
/// content without throwing, in every locale the app ships.
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 9, 12, 6, 30),
    );
  });

  tearDown(() => app.dispose());

  const locales = [Locale('en'), Locale('pa'), Locale('hi')];

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required Locale locale,
    required bool dark,
  }) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(screen, locale: locale, dark: dark));
    await settle(tester);
    expect(tester.takeException(), isNull);
  }

  for (final locale in locales) {
    for (final dark in [false, true]) {
      final label = '${locale.languageCode}/${dark ? 'dark' : 'light'}';

      testWidgets('Today renders in $label', (tester) async {
        await pumpScreen(tester, const TodayScreen(), locale: locale, dark: dark);
        final l = await L.delegate.load(locale);
        // 05-today T8 and 01-accounts §8.4: the greeting, and with no
        // profile (a test has no server: ProfileUnavailable) the banner.
        expect(find.text(l.profileWelcome), findsOneWidget);
        expect(find.text(l.profileBannerTitle), findsOneWidget);
        expect(find.text(l.greeting), findsNothing);
      });

      testWidgets('Nitnem renders in $label', (tester) async {
        await pumpScreen(tester, const NitnemScreen(), locale: locale, dark: dark);
        final l = await L.delegate.load(locale);
        expect(find.text(l.nitnemTitle), findsOneWidget);
        expect(find.text(l.slotAmritVela), findsOneWidget);
        // The Gurmukhi name sits under every bani, in every locale; in Punjabi
        // the row's title is the same string, so both spellings match.
        expect(find.text('ਜਪੁ ਜੀ ਸਾਹਿਬ'), findsWidgets);
      });

      testWidgets('Reader renders Japji in $label', (tester) async {
        await pumpScreen(
          tester,
          const ReaderScreen(slug: 'japji-sahib'),
          locale: locale,
          dark: dark,
        );
        // The Mool Mantar is the first line of the bani.
        expect(find.textContaining('ੴ'), findsWidgets);
      });

      testWidgets('Diary renders in $label', (tester) async {
        await pumpScreen(tester, const DiaryScreen(), locale: locale, dark: dark);
        final l = await L.delegate.load(locale);
        expect(find.text(l.diaryTitle), findsOneWidget);
      });

      testWidgets('Simran renders in $label', (tester) async {
        await pumpScreen(tester, const SimranScreen(), locale: locale, dark: dark);
        final l = await L.delegate.load(locale);
        expect(find.text(l.simranTitle), findsOneWidget);
      });

      testWidgets('Settings renders in $label', (tester) async {
        await pumpScreen(tester, const SettingsScreen(), locale: locale, dark: dark);
        final l = await L.delegate.load(locale);
        expect(find.text(l.settingsTitle), findsOneWidget);
      });

      testWidgets('Intro renders in $label', (tester) async {
        await pumpScreen(tester, const IntroScreen(), locale: locale, dark: dark);
        final l = await L.delegate.load(locale);
        expect(find.text(l.introTitle1), findsOneWidget);
      });
    }
  }

  testWidgets('Sukhmani, the longest bani, opens on its own text', (tester) async {
    // This test used to assert the opposite -- that Sukhmani said it was not
    // in the build. Every bani has its text now, so the reader's
    // "not in this build" branch is unreachable from bundled content and is
    // left in place only for a bani added ahead of its text.
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(const ReaderScreen(slug: 'sukhmani-sahib')));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));
    expect(find.text(l.baniNotInBuild), findsNothing);
    expect(find.textContaining('ਸੁਖਮਨੀ'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the reader shows the bani name and its section label', (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(const ReaderScreen(slug: 'japji-sahib')));
    await settle(tester);
    expect(find.text('Japji Sahib'), findsOneWidget);
    expect(find.textContaining('Mool Mantar'), findsOneWidget);
  });
}
