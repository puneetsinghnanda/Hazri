import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/about/ui/about_screen.dart';
import 'package:hazri/features/about/ui/licences_screen.dart';
import 'package:hazri/features/about/ui/privacy_screen.dart';
import 'package:hazri/features/today/ui/help_sheet.dart';

import '../app_harness.dart';

/// About & credits as the owner set it on 2026-11-09: no Gurbani text or
/// meanings sections, the calendar and Vichar in plain words, and the
/// Gurbani data's MIT notices still in the app, on the Licences screen.
void main() {
  late L l;
  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  testWidgets(
    'the calendar, city data and Vichar read as written; no source lists',
    (tester) async {
      final app = await TestApp.create(prefs: {'onboarding_done': true});
      addTearDown(app.dispose);
      usePhoneFrame(tester);
      await tester.pumpWidget(app.wrapRouted(const AboutScreen()));
      await settle(tester);
      expect(
        find.text(l.aboutCalendarBody, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(l.aboutCityDataBody, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text(l.aboutVicharBody, skipOffstage: false), findsOneWidget);
      expect(
        find.text('Shabad OS Database', skipOffstage: false),
        findsNothing,
      );
      expect(find.textContaining('Teeka', skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'the Gurbani data\'s MIT notices are registered for the Licences screen',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerDataLicences();
      final packages = <String>{};
      final texts = <String>[];
      await for (final entry in LicenseRegistry.licenses) {
        packages.addAll(entry.packages);
        texts.addAll(entry.paragraphs.map((p) => p.text));
      }
      expect(packages, containsAll(['Shabad OS Database', 'gurmukhi-utils']));
      expect(texts.join(' '), contains('Permission is hereby granted'));
    },
  );

  testWidgets('Privacy & my data: deletion within 30 days, and what stays on the phone', (tester) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const PrivacyScreen()));
    await settle(tester);
    expect(find.text(l.privacyPhoneOther, skipOffstage: false), findsOneWidget);
    await tester.scrollUntilVisible(find.text(l.privacyDeleteHow), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text(l.privacyDeleteHow), findsOneWidget);
    expect(l.privacyDeleteHow, contains('30 days'));
    expect(l.privacyNothingUnless, contains('anonymous sign-in'));
  });

  testWidgets('How Hazri works: seven tips, every one reachable', (tester) async {
    final app = await TestApp.create(prefs: {'onboarding_done': true});
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(Builder(
      builder: (context) => TextButton(onPressed: () => showHelpSheet(context), child: const Text('open')),
    )));
    await settle(tester);
    await tester.tap(find.text('open'));
    await settle(tester);
    for (final title in [
      l.helpTip1Title, l.helpTip2Title, l.helpTip3Title, l.helpTip4Title,
      l.helpTip5Title, l.helpTip6Title, l.helpTip7Title,
    ]) {
      expect(find.textContaining('$title. ', findRichText: true, skipOffstage: false), findsOneWidget, reason: title);
    }
    expect(tester.takeException(), isNull);
  });
}
