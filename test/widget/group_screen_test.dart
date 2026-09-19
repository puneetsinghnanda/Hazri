import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/data/group_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_account.dart';
import 'package:hazri/features/sangat/domain/sangat_group.dart';
import 'package:hazri/features/sangat/ui/create_group_screen.dart';
import 'package:hazri/features/sangat/ui/group_screen.dart';

import '../app_harness.dart';
import '../fake_account_repository.dart';
import '../fake_group_repository.dart';

const _account = SangatAccount(
  id: 'uid-1',
  name: 'Harjit Singh',
  city: 'Amritsar',
  email: 'harjit@example.com',
);

const _group = SangatGroup(
  id: 'g1',
  name: 'Nanda Family',
  kind: GroupKind.family,
  createdBy: 'uid-1',
  goal: GroupGoal(slug: 'sukhmani', target: 101),
  memberCount: 6,
  total: 68,
  yours: 18,
  youAreAdmin: true,
);

const _members = [
  GroupMember(uid: 'uid-1', name: 'Harjit Singh', count: 18, isAdmin: true),
  GroupMember(uid: 'uid-2', name: 'Gurpreet Kaur', count: 15),
  // Somebody who turned their name off (screen 35).
  GroupMember(uid: 'uid-3', name: '', count: 9),
];

/// Designs 31, 39 and 42 — one group, making one, and adding to its count.
void main() {
  late TestApp app;
  late FakeGroupRepository groups;

  Future<L> pump(
    WidgetTester tester,
    Widget screen, {
    List<SangatGroup> mine = const [_group],
    List<GroupMember> members = _members,
    Locale locale = const Locale('en'),
  }) async {
    final account = FakeAccountRepository(account: _account);
    groups = FakeGroupRepository(mine: mine, members: members);
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
    await tester.pumpWidget(app.wrapRouted(screen, locale: locale));
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('the group shows both bars and everybody in it', (tester) async {
    final l = await pump(tester, const GroupScreen(groupId: 'g1'));
    expect(find.text('Nanda Family'), findsOneWidget);
    expect(find.text(l.groupYou), findsOneWidget);
    expect(find.text(l.groupTheGroup), findsOneWidget);
    expect(find.text('Gurpreet Kaur'), findsOneWidget);
  });

  testWidgets('a member with their name off is "a member", not a blank line',
      (tester) async {
    final l = await pump(tester, const GroupScreen(groupId: 'g1'));
    expect(find.text(l.groupAnonMember), findsOneWidget);
  });

  testWidgets('a group that is gone says so instead of a blank screen',
      (tester) async {
    final l = await pump(tester, const GroupScreen(groupId: 'missing'));
    expect(find.text(l.groupGone), findsOneWidget);
  });

  testWidgets('logging a paath writes only an amount, and only yours',
      (tester) async {
    final l = await pump(tester, const GroupScreen(groupId: 'g1'));

    await tester.tap(find.text(l.groupLogPaath));
    await settle(tester);
    // The sheet's title and the button that opened it are the same words in
    // English, so both are on screen now.
    expect(find.text(l.groupLogTitle), findsWidgets);

    await tester.tap(find.text(l.groupLogAdd));
    await settle(tester);
    expect(groups.logged, [('g1', 1)]);
  });

  testWidgets('a circle logs minutes in fives, not paath in ones',
      (tester) async {
    const circle = SangatGroup(
      id: 'c1',
      name: 'Amrit Vela Circle',
      kind: GroupKind.circle,
      createdBy: 'uid-1',
      goal: GroupGoal(slug: 'simran', target: 300),
      memberCount: 12,
      total: 255,
    );
    final l = await pump(tester, const GroupScreen(groupId: 'c1'), mine: const [circle]);

    await tester.tap(find.text(l.groupLogPaath));
    await settle(tester);
    await tester.tap(find.text(l.groupLogAdd));
    await settle(tester);
    expect(groups.logged, [('c1', 11)]);
  });

  testWidgets('a refused log is not reported as a lost signal', (tester) async {
    final l = await pump(tester, const GroupScreen(groupId: 'g1'));
    groups.nextOutcome = const GroupRefused('permission-denied');

    await tester.tap(find.text(l.groupLogPaath));
    await settle(tester);
    await tester.tap(find.text(l.groupLogAdd));
    await settle(tester);

    expect(find.text(l.sangatRefused), findsOneWidget);
    expect(groups.logged, isEmpty);
  });

  testWidgets('a new group needs a name before it is made', (tester) async {
    final l = await pump(tester, const CreateGroupScreen());

    await tester.tap(find.text(l.groupCreateCta));
    await settle(tester);
    expect(find.text(l.groupNeedName), findsOneWidget);
    expect(groups.created, isNull);
  });

  testWidgets('asking for a listed group explains the wait', (tester) async {
    final l = await pump(tester, const CreateGroupScreen());

    expect(find.text(l.groupListedNote), findsNothing);
    await tester.tap(find.text(l.groupListed));
    await settle(tester);
    // The reader asked how a hurtful name is kept out. This is the answer,
    // and it is said before the group is made rather than after.
    expect(find.text(l.groupListedNote), findsOneWidget);
  });

  testWidgets('a group is made private whatever was asked for', (tester) async {
    final l = await pump(tester, const CreateGroupScreen());

    await tester.enterText(find.byType(TextField), 'Nanda Family');
    await tester.tap(find.text(l.groupListed));
    await settle(tester);
    // The listed note pushes the button past the fold, and a ListView does
    // not build what is off screen, so it has to be scrolled to rather than
    // found.
    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await settle(tester);
    await tester.tap(find.text(l.groupCreateCta));
    await settle(tester);

    expect(groups.created?.name, 'Nanda Family');
    expect(groups.created?.listed, isFalse,
        reason: 'listing is decided after review, never by the phone');
    // The ask is recorded so somebody can act on it; it is a request, and
    // the group is private and working in the meantime.
    expect(groups.listingRequested, isTrue);
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('the group lays out without overflowing in ${locale.languageCode}',
        (tester) async {
      await pump(tester, const GroupScreen(groupId: 'g1'), locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
