import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/ui/restore_screen.dart';

import '../app_harness.dart';
import '../fake_account_repository.dart';

/// Designs 53, 54 and 52 — coming back on a new phone, with no password
/// anywhere in it.
void main() {
  late FakeAccountRepository repo;

  Future<L> pump(
    WidgetTester tester, {
    String? email = 'harjit@example.com',
    Locale locale = const Locale('en'),
  }) async {
    repo = FakeAccountRepository();
    addTearDown(repo.dispose);
    final app = await TestApp.create(
      prefs: {'onboarding_done': true},
      extra: [accountRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(
      app.wrapRouted(RestoreScreen(email: email), locale: locale),
    );
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('the address is carried over, not typed again', (tester) async {
    await pump(tester);
    expect(find.text('harjit@example.com'), findsOneWidget);
  });

  testWidgets('restoring signs nothing out, and says so up front',
      (tester) async {
    final l = await pump(tester);
    expect(find.text(l.restoreBeenHere), findsOneWidget);
    expect(find.text(l.restoreNothingSignedOut), findsOneWidget);
  });

  testWidgets('starting fresh is offered plainly, not hidden', (tester) async {
    final l = await pump(tester);
    expect(find.text(l.restoreStartFresh), findsOneWidget);
  });

  testWidgets('the link is asked for only after one has been sent',
      (tester) async {
    final l = await pump(tester);
    expect(find.text(l.restorePasteLabel), findsNothing);

    await tester.tap(find.text(l.restoreSendLink));
    await settle(tester);
    expect(repo.sentTo, ['harjit@example.com']);
    expect(find.text(l.restorePasteLabel), findsOneWidget);
  });

  testWidgets('a pasted link brings the account back', (tester) async {
    final l = await pump(tester);
    await tester.tap(find.text(l.restoreSendLink));
    await settle(tester);

    await tester.enterText(
      find.byType(TextField).last,
      'https://hazri-dfcc1.web.app/verify?oobCode=abc',
    );
    await tester.tap(find.text(l.restoreThisAccount));
    await settle(tester);

    expect(find.text(l.restoreDone), findsOneWidget);
    expect(find.text(l.restoreDiaryNote), findsOneWidget);
  });

  testWidgets('a used link says so, and is not confused with an old one',
      (tester) async {
    final l = await pump(tester);
    await tester.tap(find.text(l.restoreSendLink));
    await settle(tester);
    repo.nextOutcome = const LinkDidNotWork(LinkProblem.alreadyUsed);

    await tester.enterText(find.byType(TextField).last, 'https://x/verify?oobCode=abc');
    await tester.tap(find.text(l.restoreThisAccount));
    await settle(tester);

    expect(find.text(l.linkUsedTitle), findsOneWidget);
    expect(find.text(l.linkExpiredTitle), findsNothing);
  });

  testWidgets('an expired link says that instead', (tester) async {
    final l = await pump(tester);
    await tester.tap(find.text(l.restoreSendLink));
    await settle(tester);
    repo.nextOutcome = const LinkDidNotWork(LinkProblem.expired);

    await tester.enterText(find.byType(TextField).last, 'https://x/verify?oobCode=abc');
    await tester.tap(find.text(l.restoreThisAccount));
    await settle(tester);

    expect(find.text(l.linkExpiredTitle), findsOneWidget);
    expect(find.text(l.linkUsedTitle), findsNothing);
  });

  testWidgets('a refusal is still not reported as a lost signal',
      (tester) async {
    final l = await pump(tester);
    repo.nextOutcome = const SangatRefused('permission-denied');

    await tester.tap(find.text(l.restoreSendLink));
    await settle(tester);
    expect(find.text(l.sangatRefused), findsOneWidget);
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('lays out without overflowing in ${locale.languageCode}',
        (tester) async {
      final l = await pump(tester, locale: locale);
      await tester.tap(find.text(l.restoreSendLink));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
