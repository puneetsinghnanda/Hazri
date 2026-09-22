import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/settings/settings_controller.dart';
import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_account.dart';
import 'package:hazri/features/today/ui/today_screen.dart';

import '../app_harness.dart';
import '../fake_account_repository.dart';

const _account = SangatAccount(
  id: 'uid-1',
  name: 'Harjit Singh',
  city: 'Amritsar',
  email: 'harjit@example.com',
);

/// Designs 58 and 59 on Today, and the reader's rule that there are never
/// two banners at once.
void main() {
  late TestApp app;

  Future<L> pump(
    WidgetTester tester, {
    SangatAccount? signedIn,
    Locale locale = const Locale('en'),
  }) async {
    final account = FakeAccountRepository(account: signedIn);
    addTearDown(account.dispose);
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 11, 20, 9, 0),
      extra: [accountRepositoryProvider.overrideWithValue(account)],
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const TodayScreen(), locale: locale));
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('before setup there is one banner, and it is the join one',
      (tester) async {
    final l = await pump(tester);
    expect(find.text(l.sangatBannerTitle), findsOneWidget);
    // The reader's constraint, in a test: no hazri banner until setup is done,
    // or Today carries two banners shouting at somebody who came to read.
    expect(find.text(l.hazriNotYet), findsNothing);
    expect(find.text(l.hazriMarked), findsNothing);
  });

  testWidgets('after setup the hazri banner replaces it', (tester) async {
    final l = await pump(tester, signedIn: _account);
    expect(find.text(l.sangatBannerTitle), findsNothing);
    expect(find.text(l.hazriNotYet), findsOneWidget);
  });

  testWidgets('Not now on the sheet also hands the slot to the hazri card',
      (tester) async {
    // The sangat is opt-in (rule 4). Somebody who declines it once must still
    // see the thing the app is named after, and must not be asked again on
    // every open of Today. The menu's account card is still the way in.
    final l = await pump(tester);
    await tester.tap(find.text(l.sangatBannerTitle));
    await settle(tester);
    expect(find.text(l.sangatNotNow), findsOneWidget);
    await tester.tap(find.text(l.sangatNotNow));
    await settle(tester);

    expect(find.text(l.sangatBannerTitle), findsNothing);
    expect(find.text(l.hazriNotYet), findsOneWidget);
    expect(app.container.read(settingsProvider).sangatDeclined, isTrue);
  });

  testWidgets('a day with nothing done says "not yet", never "missed"',
      (tester) async {
    final l = await pump(tester, signedIn: _account);
    expect(find.text(l.hazriNotYet), findsOneWidget);
    expect(find.text(l.hazriHow), findsOneWidget);
  });

  testWidgets('one completed bani marks the hazri and says so', (tester) async {
    final l = await pump(tester, signedIn: _account);
    await app.container.read(userRepositoryProvider).logCompletion(
          baniId: 'japji',
          slot: BaniSlotValue.morning,
          source: CompletionSource.read,
          on: DateTime(2026, 11, 20, 5, 52),
        );
    // drift's query and its watch both run on the real event loop, which the
    // fake clock in `settle` does not advance. Without this the widget is
    // rebuilt before the row exists.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
    expect(find.text(l.hazriMarked), findsOneWidget);
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('the banner does not overflow in ${locale.languageCode}',
        (tester) async {
      await pump(tester, signedIn: _account, locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
