import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_account.dart';
import 'package:hazri/features/sangat/ui/verify_email_screen.dart';

import '../app_harness.dart';
import '../fake_account_repository.dart';

const _account = SangatAccount(
  id: 'uid-1',
  name: 'Harjit Singh',
  city: 'Amritsar, Punjab',
  email: 'harjit@example.com',
);

/// Design 34 — sending the link, and correcting the address it goes to.
void main() {
  late TestApp app;
  late FakeAccountRepository repo;

  Future<L> pump(
    WidgetTester tester, {
    SangatAccount? account = _account,
    Locale locale = const Locale('en'),
  }) async {
    repo = FakeAccountRepository(account: account);
    addTearDown(repo.dispose);
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      extra: [accountRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const VerifyEmailScreen(), locale: locale));
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('sends the link to the address already on the account',
      (tester) async {
    final l = await pump(tester);

    await tester.tap(find.text(l.verifySend));
    await settle(tester);

    expect(repo.sentTo, ['harjit@example.com']);
    expect(find.text(l.verifySentTo('harjit@example.com')), findsOneWidget);
    expect(find.text(l.verifySendAgain), findsOneWidget);
  });

  testWidgets('a corrected address is saved, then written to', (tester) async {
    final l = await pump(tester);

    await tester.tap(find.text(l.verifyWrongAddress));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'harjit.singh@example.com');
    await tester.tap(find.text(l.verifySend));
    await settle(tester);

    // Saved first: the account screen and the mail must agree even if the
    // person never opens the link.
    expect(repo.savedProfiles.single.email, 'harjit.singh@example.com');
    expect(repo.sentTo, ['harjit.singh@example.com']);
  });

  testWidgets('an address that is not an address is refused before sending',
      (tester) async {
    final l = await pump(tester);

    await tester.tap(find.text(l.verifyWrongAddress));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'harjit at example');
    await tester.tap(find.text(l.verifySend));
    await settle(tester);

    expect(find.text(l.sangatBadEmail), findsOneWidget);
    expect(repo.sentTo, isEmpty);
  });

  testWidgets('a refusal is not reported as a lost signal', (tester) async {
    final l = await pump(tester);
    repo.nextOutcome = const SangatRefused('permission-denied');

    await tester.tap(find.text(l.verifySend));
    await settle(tester);

    // The distinction this whole sealed type exists for: our fault reads as
    // our fault, not as the reader's train tunnel.
    expect(find.text(l.sangatRefused), findsOneWidget);
    expect(find.text(l.sangatUnavailable), findsNothing);
  });

  testWidgets('being offline says so and offers the send again', (tester) async {
    final l = await pump(tester);
    repo.nextOutcome = const SangatUnavailable();

    await tester.tap(find.text(l.verifySend));
    await settle(tester);

    expect(find.text(l.sangatUnavailable), findsOneWidget);
    expect(find.text(l.verifySend), findsOneWidget,
        reason: 'a failed send must not look like a sent one');
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('lays out without overflowing in ${locale.languageCode}',
        (tester) async {
      await pump(tester, locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
