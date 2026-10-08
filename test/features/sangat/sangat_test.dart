import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/settings/settings_controller.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/profile/data/incoming_link.dart';
import 'package:hazri/features/sangat/data/sangat_controller.dart';
import 'package:hazri/features/sangat/data/sangat_device.dart';
import 'package:hazri/features/sangat/domain/sangat_models.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../profile/profile_fakes.dart';

void main() {
  group('codes (IV7)', () {
    test('typed or pasted, with or without the hyphen, in any case', () {
      expect(normalizeInviteCode('abcd-2345'), 'ABCD2345');
      expect(normalizeInviteCode(' ABCD 2345 '), 'ABCD2345');
      expect(formatInviteCode('ABCD2345'), 'ABCD-2345');
    });
    test('letters the alphabet leaves out, or the wrong length, are not codes', () {
      expect(normalizeInviteCode('ABCD-2340'), isNull, reason: '0 is not in the alphabet');
      expect(normalizeInviteCode('OBCD-2345'), isNull);
      expect(normalizeInviteCode('ABCD-234'), isNull);
    });
    test('IV6: the referrer carries the code, and nothing else counts', () {
      expect(codeFromReferrer('sangat_code=ABCD2345'), 'ABCD2345');
      expect(codeFromReferrer('utm_source=google-play&utm_medium=organic'), isNull);
      expect(codeFromReferrer(null), isNull);
    });
    test('IV5: an invite link opens Join with its code', () {
      expect(incomingLinkRoute(Uri.parse('https://hazri-dfcc1.web.app/j/ABCD-2345')),
          '/sangat-join?code=ABCD-2345');
      expect(incomingLinkRoute(Uri.parse('/j/ABCD2345')), '/sangat-join?code=ABCD2345');
    });
  });

  group('outbox (§5.1)', () {
    late UserDb db;
    late UserRepository repo;
    late FakeServer server;
    late ProviderContainer c;
    final sent = <List<Object?>>[];

    setUp(() async {
      db = UserDb.memory();
      repo = UserRepository(db, FixedClock(DateTime(2026, 10, 8, 9)));
      server = FakeServer();
      sent.clear();
      server.routes['POST /sangat/contributions'] = (body) {
        final items = body['items']! as List<Object?>;
        sent.add(items);
        return http.Response(
            jsonEncode({'result': 'CONTRIBUTIONS_RECEIVED', 'processed': [for (final i in items) (i! as Map)['id']]}),
            200);
      };
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        userRepositoryProvider.overrideWithValue(repo),
        ...server.overrides(),
      ]);
    });

    tearDown(() async {
      c.dispose();
      await db.close();
    });

    test('in no group, nothing is queued', () async {
      await repo.logCompletion(baniId: 'JAPJ', slot: BaniSlotValue.morning, source: CompletionSource.reader);
      expect(await repo.outbox(), isEmpty);
    });

    test('in a group: ADD for a paath, RETRACT for its undo, sent in order and cleared (CT5, S-13)', () async {
      await c.read(sangatListsProvider.notifier).setMember(true);
      final japji =
          await repo.logCompletion(baniId: 'JAPJ', slot: BaniSlotValue.morning, source: CompletionSource.diary);
      await repo.undoLatestCompletion('JAPJ', DateTime(2026, 10, 8));
      await repo.logSitting(duration: const Duration(minutes: 11), completed: true, source: SittingSource.timer);
      expect(await repo.outbox(), hasLength(3));

      await c.read(outboxSenderProvider).send();
      final items = sent.single.cast<Map<String, Object?>>();
      expect(items.map((i) => (i['id'], i['action'])).take(2), [(japji.id, 'ADD'), (japji.id, 'RETRACT')]);
      expect(items[0]['source'], 'DIARY');
      expect(items[2]['kind'], 'SIMRAN');
      expect(items[2]['durationS'], 660);
      expect(await repo.outbox(), isEmpty);
    });

    test('offline, the outbox waits and goes when the network returns (K13)', () async {
      await c.read(sangatListsProvider.notifier).setMember(true);
      await repo.logCompletion(baniId: 'JAPJ', slot: BaniSlotValue.morning, source: CompletionSource.reader);
      server.offline = true;
      await c.read(outboxSenderProvider).send();
      expect(await repo.outbox(), hasLength(1));
      server.offline = false;
      await c.read(outboxSenderProvider).send();
      expect(await repo.outbox(), isEmpty);
    });

    test('a row the server did not confirm stays queued', () async {
      await c.read(sangatListsProvider.notifier).setMember(true);
      await repo.logCompletion(baniId: 'JAPJ', slot: BaniSlotValue.morning, source: CompletionSource.reader);
      server.on('POST', '/sangat/contributions', 200, {'result': 'CONTRIBUTIONS_RECEIVED', 'processed': []});
      await c.read(outboxSenderProvider).send();
      expect(await repo.outbox(), hasLength(1));
    });
  });

  test('a group parses from the server shape', () {
    final g = SangatGroup.fromJson({
      'groupId': 'g1',
      'kind': 'BUILT_IN',
      'name': null,
      'names': {'en': 'Simran Sangat', 'pa': 'ਸਿਮਰਨ ਸੰਗਤ', 'hi': 'सिमरन संगत'},
      'status': 'ACTIVE',
      'memberCount': 12,
      'isMember': true,
      'role': 'MEMBER',
      'goal': {
        'goalId': 'g0001', 'type': 'SIMRAN', 'baniId': null, 'simranMinutes': 11, 'target': 1000,
        'startDay': '2026-10-01', 'endDay': '2026-10-31', 'status': 'ACTIVE', 'total': 250, 'pct': 25,
        'todayTotal': 9, 'daysLeft': 23, 'completedAt': null, 'sequence': 1,
      },
      'members': [
        {'memberKey': 'p_1', 'name': 'Harpreet', 'role': 'MEMBER', 'status': 'ACTIVE', 'contribution': 7, 'isYou': true},
        {'memberKey': 'u_x', 'name': null, 'role': 'MEMBER', 'status': 'LEFT', 'contribution': 2, 'isYou': false},
      ],
      'moreMembers': 450,
    });
    expect(g.displayName('pa'), 'ਸਿਮਰਨ ਸੰਗਤ');
    expect(g.goal!.isSimran, isTrue);
    expect(g.members.last.name, isNull);
    expect(g.members.last.hasLeft, isTrue);
    expect(g.moreMembers, 450);
  });
}
