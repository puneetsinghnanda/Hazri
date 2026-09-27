import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/data/pending_verification.dart';
import 'package:hazri/features/sangat/ui/verify_email_screen.dart';

import '../app_harness.dart';
import '../fake_account_repository.dart';

/// A tapped link finishes on its own.
///
/// The thing being asserted is an **absence**: nobody copies a URL, nobody
/// types an address, nobody presses a button. Three rounds went out before
/// this worked, and each time the report was the same sentence -- the app
/// still asks me to paste the code. So the test drives the screen the way
/// Android does, with a link and no interaction at all, and fails if
/// anything is asked of the reader.
void main() {
  const link =
      'https://hazri-dfcc1.web.app/__/auth/action?mode=signIn&oobCode=ABC123';

  late FakeAccountRepository repo;

  Future<L> pump(
    WidgetTester tester, {
    String? remembered = 'harjit@example.com',
    String? arrivedWith = link,
  }) async {
    repo = FakeAccountRepository();
    addTearDown(repo.dispose);
    final app = await TestApp.create(
      prefs: {
        'onboarding_done': true,
        if (remembered != null) 'pending_verification_email': remembered,
      },
      extra: [accountRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(
      app.wrapRouted(VerifyEmailScreen(arrivedWith: arrivedWith)),
    );
    await settle(tester);
    return L.delegate.load(const Locale('en'));
  }

  testWidgets('the link is used without anybody being asked for it',
      (tester) async {
    await pump(tester);

    expect(repo.linksTried, [link],
        reason: 'the whole link, untouched, and used without a tap');
  });

  testWidgets('the address it pairs with is the one the link was sent to',
      (tester) async {
    // Read back from where it was written before the link went out. On a
    // phone that is restoring there is no account to read it from, which is
    // the entire reason it is written down.
    await pump(tester);
    await settle(tester);

    final account = repo.current;
    expect(account?.email, 'harjit@example.com');
    expect(account?.emailVerified, isTrue);
  });

  testWidgets('and then it is forgotten', (tester) async {
    final app = await TestApp.create(
      prefs: {
        'onboarding_done': true,
        'pending_verification_email': 'harjit@example.com',
      },
      extra: [accountRepositoryProvider.overrideWithValue(
          repo = FakeAccountRepository())],
    );
    addTearDown(repo.dispose);
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(
      app.wrapRouted(const VerifyEmailScreen(arrivedWith: link)),
    );
    await settle(tester);

    // Left behind, the next link would be tried against a stale address.
    expect(app.container.read(pendingVerificationProvider).address, isNull);
  });

  testWidgets('a link with nothing to pair it with asks, rather than failing',
      (tester) async {
    // A second phone that never asked for this link: no account, nothing
    // remembered. Firing continueWithLink with an empty address can only
    // fail, and the reader would be told their link was bad when it is fine.
    await pump(tester, remembered: null);

    expect(repo.linksTried, isEmpty,
        reason: 'no doomed call with an empty address');
    expect(find.byType(TextField), findsWidgets,
        reason: 'the address is asked for instead');
  });

  testWidgets('no link means the screen behaves exactly as it always did',
      (tester) async {
    await pump(tester, arrivedWith: null);
    expect(repo.linksTried, isEmpty);
  });
}
