import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/today/ui/today_screen.dart';

import '../app_harness.dart';

/// Today, for the great majority who have not joined the sangat.
///
/// The banner is the sangat's entire presence on this screen until somebody
/// taps it, and these tests hold two lines: it does not crash without an
/// account, and it does not overflow. The second is not fussiness — the first
/// version of this banner overflowed by 92 pixels in the widget tests, which
/// is a black-and-yellow stripe across Today on a real phone.
void main() {
  late TestApp app;

  setUp(() async {
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 11, 20, 9, 0),
    );
  });

  tearDown(() => app.dispose());

  Future<L> pump(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const TodayScreen(), locale: locale));
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('the join banner is offered to somebody with no account',
      (tester) async {
    final l = await pump(tester);
    expect(find.text(l.sangatBannerTitle), findsOneWidget);
    expect(find.text(l.sangatBannerCta), findsOneWidget);
  });

  testWidgets('Today lays out with no account and no server', (tester) async {
    await pump(tester);
    // No account, no backend: the default repository reports nothing and the
    // screen has to stand up anyway, because that is every first run.
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('the banner does not overflow in ${locale.languageCode}',
        (tester) async {
      await pump(tester, locale: locale);
      // An overflow throws during layout and lands here. Punjabi and Hindi
      // are the long ones, so all three are checked rather than English only.
      expect(tester.takeException(), isNull);
    });
  }
}
