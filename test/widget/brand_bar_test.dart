import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/widgets/app_mark.dart';
import 'package:hazri/core/widgets/brand_bar.dart';

import '../app_harness.dart';

/// The mark and the name sit above every tab, in one place (PRD 1.3).
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(prefs: {'onboarding_done': true});
  });

  tearDown(() => app.dispose());

  testWidgets('carries the mark and the name', (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(const Scaffold(body: BrandBar())));
    await settle(tester);

    final l = await L.delegate.load(const Locale('en'));
    expect(find.byType(AppMark), findsOneWidget);
    expect(find.text(l.appName), findsOneWidget);
  });

  testWidgets('the name is the app name in every language', (tester) async {
    for (final locale in const [Locale('pa'), Locale('hi')]) {
      usePhoneFrame(tester);
      await tester.pumpWidget(
        app.wrap(const Scaffold(body: BrandBar()), locale: locale),
      );
      await settle(tester);
      final l = await L.delegate.load(locale);
      expect(find.text(l.appName), findsOneWidget, reason: '$locale');
    }
  });

  testWidgets('the help button appears only when there is somewhere to go',
      (tester) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrap(const Scaffold(body: BrandBar())));
    await settle(tester);
    final l = await L.delegate.load(const Locale('en'));
    expect(find.byTooltip(l.helpSheetTitle), findsNothing);

    var tapped = 0;
    await tester.pumpWidget(
      app.wrap(Scaffold(body: BrandBar(onHelp: () => tapped++))),
    );
    await settle(tester);
    await tester.tap(find.byTooltip(l.helpSheetTitle));
    expect(tapped, 1);
  });
}
