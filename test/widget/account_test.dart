import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_account.dart';
import 'package:hazri/features/sangat/ui/account_screen.dart';

import '../app_harness.dart';
import '../fake_account_repository.dart';

const _unverified = SangatAccount(
  id: 'uid-1',
  name: 'Harjit Singh',
  city: 'Amritsar, Punjab',
  email: 'harjit@example.com',
);

/// Design 33 — the account, and the only place the app ever asks anybody to
/// verify anything.
void main() {
  late TestApp app;
  late FakeAccountRepository repo;

  Future<L> pump(
    WidgetTester tester, {
    SangatAccount? account,
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
    await tester.pumpWidget(app.wrapRouted(const AccountScreen(), locale: locale));
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('somebody who never joined is offered the way in, not empty rows',
      (tester) async {
    final l = await pump(tester);
    expect(find.text(l.accountJoinedFirst), findsOneWidget);
    expect(find.text(l.sangatBannerCta), findsOneWidget);
    expect(find.text(l.accountSignOut), findsNothing);
  });

  testWidgets('an unverified account is told so, and offered the one fix',
      (tester) async {
    final l = await pump(tester, account: _unverified);
    expect(find.text('Harjit Singh'), findsOneWidget);
    expect(find.text('harjit@example.com'), findsOneWidget);
    expect(find.text(l.accountNotVerified), findsOneWidget);
    expect(find.text(l.accountVerifyCta), findsOneWidget);
    expect(find.text(l.accountSafeTitle), findsNothing);
  });

  testWidgets('a verified account is not nagged', (tester) async {
    final l = await pump(tester, account: _unverified.copyWith(emailVerified: true));
    expect(find.text(l.accountVerified), findsOneWidget);
    expect(find.text(l.accountSafeTitle), findsOneWidget);
    // The kesri card is the whole point of the unverified state. It must not
    // survive into the verified one.
    expect(find.text(l.accountVerifyCta), findsNothing);
  });

  testWidgets('a missing phone says so rather than showing a blank line',
      (tester) async {
    final l = await pump(tester, account: _unverified);
    expect(find.text(l.accountNotAdded), findsOneWidget);
  });

  testWidgets('signing out of an unverified account has to be confirmed',
      (tester) async {
    final l = await pump(tester, account: _unverified);

    await tester.tap(find.text(l.accountSignOut));
    await settle(tester);
    // The warning is the point: this account has no way back.
    expect(find.text(l.accountSignOutWarn), findsOneWidget);
    expect(repo.signOutCalls, 0);

    await tester.tap(find.text(l.actionCancel));
    await settle(tester);
    expect(repo.signOutCalls, 0, reason: 'cancel must mean cancel');

    await tester.tap(find.text(l.accountSignOut));
    await settle(tester);
    await tester.tap(find.text(l.accountSignOutConfirm));
    await settle(tester);
    expect(repo.signOutCalls, 1);
  });

  testWidgets('the screen follows the account without being asked',
      (tester) async {
    final l = await pump(tester, account: _unverified);
    expect(find.text(l.accountNotVerified), findsOneWidget);

    repo.emit(_unverified.copyWith(emailVerified: true));
    await settle(tester);
    expect(find.text(l.accountVerified), findsOneWidget);
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('lays out without overflowing in ${locale.languageCode}',
        (tester) async {
      await pump(tester, account: _unverified, locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
