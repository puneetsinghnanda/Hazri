import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/about/ui/privacy_screen.dart';
import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_account.dart';

import '../app_harness.dart';
import '../fake_account_repository.dart';

const _account = SangatAccount(
  id: 'uid-1',
  name: 'Harjit Singh',
  city: 'Amritsar',
  email: 'harjit@example.com',
);

/// Design 35. This screen is a promise in writing, so the tests are about
/// what it says as much as what it does.
void main() {
  late FakeAccountRepository repo;

  Future<L> pump(
    WidgetTester tester, {
    SangatAccount? signedIn,
    Locale locale = const Locale('en'),
  }) async {
    repo = FakeAccountRepository(account: signedIn);
    addTearDown(repo.dispose);
    final app = await TestApp.create(
      prefs: {'onboarding_done': true},
      extra: [accountRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const PrivacyScreen(), locale: locale));
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('the three headings are all there, in order of what matters',
      (tester) async {
    final l = await pump(tester);
    // Eyebrow uppercases what it is given, the way the design sheet does.
    expect(find.text(l.privacyOnPhoneOnly.toUpperCase()), findsOneWidget);
    expect(find.text(l.privacySharedWithSangat.toUpperCase()), findsOneWidget);
    // The third heading is past the fold, and a ListView does not build what
    // is off screen.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await settle(tester);
    expect(find.text(l.privacyAccountOnly.toUpperCase()), findsOneWidget);
  });

  testWidgets('it does not claim the app sends nothing anywhere',
      (tester) async {
    final l = await pump(tester);
    // The Phase 1 sentence was retired when joining became possible. PRD
    // §13.1 says this screen may never run ahead of what is true, and this
    // is that rule as a test.
    expect(l.privacyNoAnalytics.contains('no network requests'), isFalse);
    expect(find.text(l.privacyNoAnalytics), findsOneWidget);
  });

  testWidgets('somebody who never joined is told nothing left the phone',
      (tester) async {
    final l = await pump(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await settle(tester);
    expect(find.text(l.privacyNotJoined), findsOneWidget);
    expect(find.text(l.privacyDelete), findsNothing);
  });

  testWidgets('a member gets the name switch, the download and the delete',
      (tester) async {
    final l = await pump(tester, signedIn: _account);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await settle(tester);
    expect(find.text(l.privacyShowMyName), findsOneWidget);
    expect(find.text(l.privacyDownload), findsOneWidget);
    expect(find.text(l.privacyDelete), findsOneWidget);
  });

  testWidgets('turning the name off is saved, not just shown', (tester) async {
    await pump(tester, signedIn: _account);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await settle(tester);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(repo.savedProfiles.single.showName, isFalse);
  });

  testWidgets('deleting asks first, and cancel means cancel', (tester) async {
    final l = await pump(tester, signedIn: _account);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await settle(tester);

    await tester.tap(find.text(l.privacyDelete));
    await settle(tester);
    expect(find.text(l.privacyDeleteConfirm), findsOneWidget);

    await tester.tap(find.text(l.actionCancel));
    await settle(tester);
    expect(repo.deleteCalls, 0);
  });

  testWidgets('confirming deletes everything the server holds', (tester) async {
    final l = await pump(tester, signedIn: _account);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await settle(tester);
    await tester.tap(find.text(l.privacyDelete));
    await settle(tester);
    await tester.tap(find.text(l.privacyDeleteDo));
    await settle(tester);
    expect(repo.deleteCalls, 1);
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('lays out without overflowing in ${locale.languageCode}',
        (tester) async {
      await pump(tester, signedIn: _account, locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
