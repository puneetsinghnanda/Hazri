import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/sangat/data/sangat_controller.dart';
import 'package:hazri/features/sangat/ui/join_screen.dart';
import 'package:hazri/core/theme/hazri_text.dart';
import 'package:hazri/features/sangat/ui/sangat_screen.dart';
import 'package:hazri/features/sangat/ui/sangat_widgets.dart';

import '../app_harness.dart';
import '../features/profile/profile_fakes.dart';

/// 08-sangat §10 at the screen seam.
void main() {
  late FakeServer server;
  late TestApp app;
  late L l;

  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  Map<String, Object?> builtIn({bool member = false}) => {
        'groupId': 'simran',
        'kind': 'BUILT_IN',
        'names': {'en': 'Simran Sangat', 'pa': 'ਸਿਮਰਨ ਸੰਗਤ', 'hi': 'सिमरन संगत'},
        'status': 'ACTIVE',
        'memberCount': 120,
        'isMember': member,
        'role': member ? 'MEMBER' : null,
        'goal': {
          'goalId': 'g0001', 'type': 'SIMRAN', 'simranMinutes': null, 'target': 1000, 'startDay': '2026-10-01',
          'endDay': '2026-10-31', 'status': 'ACTIVE', 'total': 250, 'pct': 25, 'todayTotal': 9, 'daysLeft': 23,
        },
      };

  Future<void> boot(WidgetTester tester, Widget screen) async {
    app = await TestApp.create(prefs: {'onboarding_done': true}, extra: server.overrides());
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(screen));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await settle(tester);
  }

  setUp(() {
    server = FakeServer();
    server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
    server.on('GET', '/sangat/groups/mine', 200, {'groups': []});
    server.on('GET', '/sangat/groups/built-in', 200, {'groups': [builtIn()]});
    server.on('POST', '/sangat/contributions', 200, {'processed': []});
  });

  testWidgets('S-1: no profile → built-in groups with Join', (tester) async {
    await boot(tester, const SangatScreen());
    expect(find.text('Simran Sangat'), findsOneWidget);
    expect(find.text(l.sangatJoin), findsOneWidget);
    expect(find.text(l.sangatNoGroups), findsOneWidget);
    expect(find.text(l.sangatCreate), findsOneWidget);
  });

  testWidgets('SG-1: a Simran goal reads in minutes of Naam Simran', (tester) async {
    server.on('GET', '/sangat/groups/mine', 200, {'groups': [builtIn(member: true)]});
    await boot(tester, const SangatScreen());
    // The built-in row's goal line, and the tile's total of target.
    expect(find.textContaining('1000 minutes of Naam Simran by'), findsOneWidget);
    expect(find.text('250 of 1,000 min'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.textContaining('sittings'), findsNothing);
  });

  testWidgets('design 102: a built-in group is a full-width row with Join, then Leave', (tester) async {
    await boot(tester, const SangatScreen());
    final row = find.byType(BuiltInGroupRow);
    expect(row, findsOneWidget);
    // The phone is 390 wide and the tab's gutter is 20 a side.
    expect(tester.getSize(row).width, closeTo(390 - 2 * HazriSize.gutter, 0.5));
    expect(find.descendant(of: row, matching: find.text(l.sangatJoin)), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('120 members')), findsOneWidget);
  });

  testWidgets('design 102: Create group and Join group sit side by side', (tester) async {
    await boot(tester, const SangatScreen());
    final create = tester.getRect(find.widgetWithText(SangatActionTile, l.sangatCreate));
    final join = tester.getRect(find.widgetWithText(SangatActionTile, l.sangatJoinGroupTile));
    expect(create.top, closeTo(join.top, 0.5));
    expect(create.height, closeTo(join.height, 0.5));
    expect(create.right, lessThan(join.left));
    expect(find.text(l.sangatJoinGroupSub), findsOneWidget);
  });

  testWidgets('VS1, design 102: my groups are a 2 x 2 grid, an ended one last and marked', (tester) async {
    Map<String, Object?> custom(String id, String name, {String status = 'ACTIVE'}) => {
          'groupId': id, 'kind': 'CUSTOM', 'name': name, 'status': status, 'memberCount': 4, 'isMember': true,
          'role': 'MEMBER', 'endedOn': status == 'ACTIVE' ? null : '2026-10-05',
          'goal': {
            'goalId': 'g$id', 'type': 'BANI', 'baniId': 'JAPJ', 'target': 100, 'startDay': '2026-09-01',
            'endDay': status == 'ACTIVE' ? '2026-12-31' : '2026-10-05',
            'status': status == 'ACTIVE' ? 'ACTIVE' : 'COMPLETED', 'total': status == 'ACTIVE' ? 40 : 100,
            'pct': status == 'ACTIVE' ? 40 : 100, 'todayTotal': 2, 'daysLeft': 80,
          },
        };
    server.on('GET', '/sangat/groups/mine', 200, {
      'groups': [custom('a', 'Gill Parivar Ended', status: 'INACTIVE'), custom('b', 'Gill Parivar'), builtIn(member: true)],
    });
    await boot(tester, const SangatScreen());
    final tiles = find.byType(GroupGridTile);
    expect(tiles, findsNWidgets(3));
    final first = tester.getRect(tiles.at(0));
    final second = tester.getRect(tiles.at(1));
    final third = tester.getRect(tiles.at(2));
    expect(first.top, closeTo(second.top, 0.5));
    expect(third.top, greaterThan(first.bottom));
    // Active first; the ended group last, with Ended on it.
    expect(find.descendant(of: tiles.at(2), matching: find.text('Gill Parivar Ended')), findsOneWidget);
    expect(find.descendant(of: tiles.at(2), matching: find.text(l.sangatEndedHeading)), findsOneWidget);
    expect(find.descendant(of: tiles.at(0), matching: find.text('40 of 100')), findsOneWidget);
    expect(find.descendant(of: tiles.at(0), matching: find.text(l.sangatDaysLeft(80))), findsOneWidget);
  });

  testWidgets('a paath waiting in the outbox is sent before the totals are read', (tester) async {
    await boot(tester, const SizedBox());
    final repo = app.container.read(userRepositoryProvider)..queueForSangat = true;
    await tester.runAsync(() => repo.logCompletion(
          baniId: 'JAPJ', slot: BaniSlotValue.morning, source: CompletionSource.reader));
    server.requests.clear();
    await tester.pumpWidget(app.wrapRouted(const SangatScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await settle(tester);
    final post = server.requests.indexOf('POST /sangat/contributions');
    expect(post, isNot(-1));
    expect(post, lessThan(server.requests.indexOf('GET /sangat/groups/built-in')));
  });

  testWidgets('S-2: Join a built-in group → member, and the outbox turns on', (tester) async {
    server.on('POST', '/sangat/groups/simran/join', 200, {'result': 'JOINED', 'groupId': 'simran'});
    await boot(tester, const SangatScreen());
    server.on('GET', '/sangat/groups/built-in', 200, {'groups': [builtIn(member: true)]});
    await tester.tap(find.text(l.sangatJoin));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await settle(tester);
    expect(server.requests, contains('POST /sangat/groups/simran/join'));
    expect(find.text(l.sangatLeave), findsOneWidget);
    expect(app.container.read(sangatMemberProvider), isTrue);
  });

  testWidgets('S-28: offline with no copy says so', (tester) async {
    server.offline = true;
    await boot(tester, const SangatScreen());
    expect(find.textContaining(l.sangatOffline), findsWidgets);
  });

  testWidgets('IV8: an invalid code is refused inline without asking the server', (tester) async {
    await boot(tester, const JoinScreen());
    await tester.enterText(find.byType(TextField), 'nope');
    await tester.tap(find.text(l.sangatJoin));
    await settle(tester);
    expect(find.text(l.sangatCodeInvalid), findsOneWidget);
    expect(server.requests.where((r) => r == 'POST /sangat/join'), isEmpty);
  });

  testWidgets('S-25: a full group says so', (tester) async {
    server.on('POST', '/sangat/join', 409, errorJson('GROUP_FULL'));
    await boot(tester, const JoinScreen(code: 'ABCD-2345'));
    await tester.tap(find.text(l.sangatJoin));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await settle(tester);
    expect(find.text(l.sangatGroupFull), findsOneWidget);
  });

  for (final locale in const [Locale('pa'), Locale('hi')]) {
    testWidgets('the tab lays out in ${locale.languageCode}', (tester) async {
      app = await TestApp.create(prefs: {'onboarding_done': true}, extra: server.overrides());
      addTearDown(app.dispose);
      usePhoneFrame(tester);
      await tester.pumpWidget(app.wrapRouted(const SangatScreen(), locale: locale));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('ਸਿਮਰਨ ਸੰਗਤ').evaluate().isNotEmpty || find.text('सिमरन संगत').evaluate().isNotEmpty, isTrue);
    });
  }
}
