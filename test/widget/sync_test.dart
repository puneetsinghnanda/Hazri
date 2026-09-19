import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_account.dart';
import 'package:hazri/features/sync/data/diary_sync.dart';
import 'package:hazri/features/sync/domain/sync_status.dart';
import 'package:hazri/features/sync/ui/sync_screen.dart';

import '../app_harness.dart';
import '../fake_account_repository.dart';

const _account = SangatAccount(
  id: 'uid-1',
  name: 'Harjit Singh',
  city: 'Amritsar',
  email: 'harjit@example.com',
);

class _FakeSync implements DiarySync {
  _FakeSync(this.status);
  SyncStatus status;
  int pushes = 0;

  @override
  Future<SyncStatus> push() async {
    pushes++;
    return status;
  }

  @override
  Future<int> pull() async => 0;

  @override
  Stream<SyncStatus> watch() => Stream.value(status);
}

/// Design 49. Every state here has to leave somebody free to carry on
/// reading, so the tests are largely about what the screen does NOT say.
void main() {
  late _FakeSync sync;

  Future<L> pump(
    WidgetTester tester, {
    SyncStatus status = const SyncOff(),
    SangatAccount? signedIn = _account,
    Map<String, Object> prefs = const {},
    Locale locale = const Locale('en'),
  }) async {
    sync = _FakeSync(status);
    final account = FakeAccountRepository(account: signedIn);
    addTearDown(account.dispose);
    final app = await TestApp.create(
      prefs: {'onboarding_done': true, ...prefs},
      extra: [
        accountRepositoryProvider.overrideWithValue(account),
        diarySyncProvider.overrideWithValue(sync),
      ],
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const SyncScreen(), locale: locale));
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('sync off is a complete answer, not a warning', (tester) async {
    final l = await pump(tester);
    expect(find.text(l.syncStateOff), findsOneWidget);
    expect(find.text(l.syncStateOffSub), findsOneWidget);
  });

  testWidgets('no connection tells somebody to carry on', (tester) async {
    final l = await pump(tester, status: const SyncWaiting());
    expect(find.text(l.syncStateWaiting), findsOneWidget);
    expect(find.text(l.syncStateWaitingSub), findsOneWidget);
  });

  testWidgets('waiting for Wi-Fi is told apart from having no signal',
      (tester) async {
    // One is the phone's situation and the other is a setting the person can
    // change, so they must not share a message.
    final l = await pump(tester, status: const SyncWaiting(forWifi: true));
    expect(find.text(l.syncStateWifi), findsOneWidget);
    expect(find.text(l.syncStateWaiting), findsNothing);
  });

  testWidgets('sending says how many days', (tester) async {
    final l = await pump(tester, status: const Sending(3));
    expect(find.text(l.syncStateSending(3)), findsOneWidget);
  });

  testWidgets('without an account the switch is dead and says why',
      (tester) async {
    final l = await pump(tester, signedIn: null);
    expect(find.text(l.syncNeedsAccount), findsOneWidget);
    final sw = tester.widget<Switch>(find.byType(Switch).first);
    expect(sw.onChanged, isNull);
  });

  testWidgets('turning sync on pushes straight away', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    expect(sync.pushes, 1);
  });

  testWidgets('the screen says the app works without any of this',
      (tester) async {
    final l = await pump(tester);
    expect(find.text(l.syncWorksWithout), findsOneWidget);
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('lays out without overflowing in ${locale.languageCode}',
        (tester) async {
      await pump(tester, status: const SyncWaiting(forWifi: true), locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
