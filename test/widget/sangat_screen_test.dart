import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/data/group_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_account.dart';
import 'package:hazri/features/sangat/domain/sangat_group.dart';
import 'package:hazri/features/sangat/ui/sangat_screen.dart';

import '../app_harness.dart';
import '../fake_account_repository.dart';
import '../fake_group_repository.dart';

const _account = SangatAccount(
  id: 'uid-1',
  name: 'Harjit Singh',
  city: 'Amritsar, Punjab',
  email: 'harjit@example.com',
);

const _family = SangatGroup(
  id: 'g1',
  name: 'Nanda Family',
  kind: GroupKind.family,
  createdBy: 'uid-1',
  goal: GroupGoal(slug: 'sukhmani', target: 101),
  memberCount: 6,
  total: 68,
  yours: 18,
);

const _listed = SangatGroup(
  id: 'g9',
  name: 'Amrit Vela · 4 AM',
  kind: GroupKind.circle,
  createdBy: 'somebody',
  listed: true,
  memberCount: 1840,
);

/// Design 38 — the Sangat tab, whose first job is to be honest to the
/// majority who have not joined anything.
void main() {
  late TestApp app;
  late FakeGroupRepository groups;
  late FakeAccountRepository account;

  Future<L> pump(
    WidgetTester tester, {
    SangatAccount? signedIn,
    List<SangatGroup> mine = const [],
    List<SangatGroup> listed = const [],
    Locale locale = const Locale('en'),
  }) async {
    account = FakeAccountRepository(account: signedIn);
    groups = FakeGroupRepository(mine: mine, listedGroups: listed);
    addTearDown(account.dispose);
    addTearDown(groups.dispose);
    app = await TestApp.create(
      prefs: {'onboarding_done': true},
      extra: [
        accountRepositoryProvider.overrideWithValue(account),
        groupRepositoryProvider.overrideWithValue(groups),
      ],
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
        // The real screen is a tab body inside the shell's Scaffold, which is
    // what a SnackBar needs to appear in. Without one, an error the screen
    // reports would silently go nowhere here and the test would pass on a
    // bug.
    await tester.pumpWidget(
      app.wrapRouted(const Scaffold(body: SangatScreen()), locale: locale),
    );
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('somebody who never joined sees the offer, not an empty list',
      (tester) async {
    final l = await pump(tester);
    expect(find.text(l.sangatNotJoinedTitle), findsOneWidget);
    expect(find.text(l.sangatYourGroups), findsNothing);
  });

  testWidgets('joined but in no group is a normal place to be', (tester) async {
    final l = await pump(tester, signedIn: _account);
    expect(find.text(l.sangatNoGroupsYet), findsOneWidget);
    expect(find.text(l.sangatCreateOrJoin), findsOneWidget);
  });

  testWidgets('a group shows its per cent against the shared goal',
      (tester) async {
    await pump(tester, signedIn: _account, mine: const [_family]);
    expect(find.text('Nanda Family'), findsOneWidget);
    // 68 of 101.
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('68 of 101 paath'), findsOneWidget);
  });

  testWidgets('a group with no goal says so rather than showing nought per cent',
      (tester) async {
    final l = await pump(
      tester,
      signedIn: _account,
      mine: const [
        SangatGroup(
          id: 'g2',
          name: 'New group',
          kind: GroupKind.family,
          createdBy: 'uid-1',
          memberCount: 2,
        )
      ],
    );
    expect(find.text(l.groupNoGoalYet), findsOneWidget);
    expect(find.text('0%'), findsNothing);
  });

  testWidgets('a circle counts minutes, not paath', (tester) async {
    final l = await pump(
      tester,
      signedIn: _account,
      mine: const [
        SangatGroup(
          id: 'g3',
          name: 'Amrit Vela Circle',
          kind: GroupKind.circle,
          createdBy: 'uid-1',
          goal: GroupGoal(slug: 'simran', target: 300),
          memberCount: 12,
          total: 255,
        )
      ],
    );
    expect(find.text('255 of 300 ${l.unitMinutes}'), findsOneWidget);
  });

  testWidgets('a listed group can be joined from the row', (tester) async {
    final l = await pump(tester, signedIn: _account, listed: const [_listed]);
    expect(find.text('Amrit Vela · 4 AM'), findsOneWidget);

    await tester.tap(find.text(l.sangatJoinGroup));
    await settle(tester);
    expect(groups.joined, ['g9']);
  });

  testWidgets('a refused join is not reported as a lost signal', (tester) async {
    final l = await pump(tester, signedIn: _account, listed: const [_listed]);
    groups.nextOutcome = const GroupRefused('permission-denied');

    await tester.tap(find.text(l.sangatJoinGroup));
    await settle(tester);

    expect(find.text(l.sangatRefused), findsOneWidget);
    expect(groups.joined, isEmpty);
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('lays out without overflowing in ${locale.languageCode}',
        (tester) async {
      await pump(
        tester,
        signedIn: _account,
        mine: const [_family],
        listed: const [_listed],
        locale: locale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
