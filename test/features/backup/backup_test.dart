import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/backend/api_client.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/backup/data/backup_service.dart';
import 'package:hazri/features/backup/data/backup_store.dart';
import 'package:hazri/features/backup/domain/backup_json.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../profile/profile_fakes.dart';

/// `10-backup.md` §9, and the RS3 merge table one row at a time.
void main() {
  late UserDb db;
  late UserRepository repo;
  late FixedClock clock;
  late FakeServer server;
  late BackupService service;
  late SharedPreferences prefs;
  final posted = <Map<String, Object?>>[];

  setUp(() async {
    db = UserDb.memory();
    clock = FixedClock(DateTime(2026, 10, 8, 9));
    repo = UserRepository(db, clock);
    server = FakeServer();
    posted.clear();
    server.routes['POST /backup'] = (body) {
      posted.add(body);
      return http.Response(
          jsonEncode({'result': 'BACKUP_SAVED', 'rowsReceived': 1, 'documentsWritten': 1, 'lastBackupAt': body['final'] == true ? '2026-10-08T03:30:00.000Z' : null}),
          200);
    };
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = BackupService(
      api: ApiClient(auth: FakeAuth(), client: server.client, baseUrl: 'https://t/api/v1'),
      store: BackupStore(db),
      prefs: prefs,
      clock: clock,
    );
  });

  tearDown(() => db.close());

  Future<Completion> read(String bani, {DateTime? on}) =>
      repo.logCompletion(baniId: bani, slot: BaniSlotValue.morning, source: CompletionSource.reader, on: on);

  group('backup', () {
    test('K-1: the first backup sends everything and moves the watermark', () async {
      await repo.addItem(const GoalItemSpec.bani('JAPJ'));
      await read('JAPJ');
      final outcome = await service.backup();
      expect(outcome, isA<BackupSaved>());
      expect(posted, hasLength(1));
      expect((posted.single['goals']! as List), hasLength(1));
      expect((posted.single['completions']! as List), hasLength(1));
      expect(posted.single['final'], isTrue);
      expect(service.lastBackupAt, isNotNull);
    });

    test('BK6: the next backup sends only what changed, soft-deleted rows included (K-9)', () async {
      await read('JAPJ');
      await service.backup();
      clock.instant = DateTime(2026, 10, 9, 9);
      await repo.undoLatestCompletion('JAPJ', DateTime(2026, 10, 8));
      await read('REHR');
      await service.backup();
      final second = posted.last['completions']! as List;
      expect(second, hasLength(2));
      expect(second.any((c) => (c as Map)['deletedAt'] != null), isTrue);
    });

    test('K-4: 5,000 rows go in three requests, final only on the last', () async {
      final rows = ChangedRows(goals: const [], items: const [], completions: [
        for (var i = 0; i < 5000; i++)
          Completion(
            id: '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
            localDate: '2026-10-08',
            baniId: 'JAPJ',
            slot: BaniSlotValue.morning,
            source: CompletionSource.reader,
            completedAt: DateTime.utc(2026, 10, 8),
            updatedAt: DateTime.utc(2026, 10, 8),
          ),
      ], sittings: const []);
      final chunks = BackupService.chunksOf(rows);
      expect(chunks, hasLength(3));
      expect(chunks.map((c) => (c['completions']! as List).length), [2000, 2000, 1000]);
    });

    test('BK7: a failure part-way leaves the watermark where it was', () async {
      await read('JAPJ');
      server.routes['POST /backup'] = (_) => http.Response('{"error":{"code":"INTERNAL","message":"x"}}', 500);
      final outcome = await service.backup();
      expect(outcome, isA<BackupFailed>());
      expect(service.lastBackupAt, isNull);
    });

    test('K-8: NO_PROFILE stops (ST2)', () async {
      server.on('POST', '/backup', 404, errorJson('NO_PROFILE'));
      expect(await service.backup(), isA<BackupNoProfile>());
    });

    test('ST3: a rate limit is waited out', () async {
      server.on('POST', '/backup', 429, errorJson('RATE_LIMITED', {'retryAfterSeconds': 120}));
      final outcome = await service.backup();
      expect(outcome, isA<BackupLater>());
      expect((outcome as BackupLater).retryAfter, const Duration(minutes: 2));
    });

    test('BK1: the next slot is Sunday 00:00 plus at most 60 minutes', () {
      for (final from in [DateTime(2026, 10, 8, 9), DateTime(2026, 10, 10, 23, 59), DateTime(2026, 10, 11, 0, 30)]) {
        final at = BackupService.nextSlot(from, random: math.Random(1));
        expect(at.weekday, DateTime.sunday);
        expect(at.hour, 0);
        expect(at.isAfter(from), isTrue);
        expect(at.difference(from), lessThanOrEqualTo(const Duration(days: 7, hours: 1)));
      }
    });
  });

  group('restore', () {
    Map<String, Object?> completionJson(String id, {required String updated, String? deleted, String bani = 'JAPJ'}) => {
          'id': id,
          'localDate': '2026-09-01',
          'baniId': bani,
          'slot': 'MORNING',
          'source': 'READER',
          'completedAt': '2026-09-01T00:30:00.000Z',
          'updatedAt': updated,
          'deletedAt': deleted,
        };

    void serve({List<Map<String, Object?>> completions = const [], List<Map<String, Object?>> goals = const []}) {
      server.on('GET', '/backup/manifest', 200, {
        'lastBackupAt': '2026-10-04T00:31:12.000Z',
        'goalIds': [for (final g in goals) (g['goal']! as Map)['id']],
        'weeks': {'2026-08-30': completions.length},
        'rowCount': completions.length,
      });
      server.on('GET', '/backup/goals', 200, {'goals': goals});
      server.on('GET', '/backup/weeks', 200, {
        'weeks': [
          {'weekId': '2026-08-30', 'completions': completions, 'simranSessions': []},
        ],
        'next': null,
      });
    }

    const a = '11111111-1111-4111-8111-111111111111';
    const b = '22222222-2222-4222-8222-222222222222';

    test('R-7: no backup → nothing, and nothing changes', () async {
      server.on('GET', '/backup/manifest', 200, {'lastBackupAt': null, 'goalIds': [], 'weeks': {}, 'rowCount': 0});
      expect(await service.restore(), isA<RestoreNothing>());
    });

    test('RS3: missing and live → inserted; missing and soft-deleted → inserted deleted (R-5)', () async {
      serve(completions: [
        completionJson(a, updated: '2026-09-01T00:30:00.000Z'),
        completionJson(b, updated: '2026-09-02T00:00:00.000Z', deleted: '2026-09-02T00:00:00.000Z'),
      ]);
      final outcome = await service.restore() as RestoreDone;
      expect(outcome.added, 2);
      final rows = await db.select(db.completions).get();
      expect(rows.firstWhere((r) => r.id == b).deletedAt, isNotNull);
      expect(await repo.completionsOn(DateTime(2026, 9, 1)), hasLength(1), reason: 'the deleted one shows nowhere');
    });

    test('R-3: the server is newer → the phone row is replaced', () async {
      final local = BackupJson.completionFrom(completionJson(a, updated: '2026-09-01T00:30:00.000Z'));
      await db.into(db.completions).insert(local);
      serve(completions: [completionJson(a, updated: '2026-09-05T00:00:00.000Z', deleted: '2026-09-05T00:00:00.000Z')]);
      await service.restore();
      expect((await db.select(db.completions).getSingle()).deletedAt, isNotNull);
    });

    test('R-4: the phone is newer (or equal) → the phone row is kept', () async {
      final local = BackupJson.completionFrom(completionJson(a, updated: '2026-09-09T00:00:00.000Z'));
      await db.into(db.completions).insert(local);
      serve(completions: [completionJson(a, updated: '2026-09-05T00:00:00.000Z', deleted: '2026-09-05T00:00:00.000Z')]);
      await service.restore();
      expect((await db.select(db.completions).getSingle()).deletedAt, isNull);
    });

    test('RS3: equal updatedAt keeps the phone row', () async {
      final local = BackupJson.completionFrom(completionJson(a, updated: '2026-09-05T00:00:00.000Z'));
      await db.into(db.completions).insert(local);
      serve(completions: [completionJson(a, updated: '2026-09-05T00:00:00.000Z', deleted: '2026-09-05T00:00:00.000Z')]);
      await service.restore();
      expect((await db.select(db.completions).getSingle()).deletedAt, isNull);
    });

    test('R-2 / RS4: this week\'s rows the server did not send are untouched', () async {
      final mine = await read('REHR');
      serve(completions: [completionJson(a, updated: '2026-09-01T00:30:00.000Z')]);
      await service.restore();
      final rows = await db.select(db.completions).get();
      expect(rows.map((r) => r.id), containsAll([a, mine.id]));
      expect(rows.firstWhere((r) => r.id == mine.id), mine);
    });

    test('R-9: a second restore changes nothing', () async {
      serve(completions: [completionJson(a, updated: '2026-09-01T00:30:00.000Z')]);
      await service.restore();
      final before = await db.select(db.completions).get();
      final second = await service.restore() as RestoreDone;
      expect(second.added, 0);
      expect(await db.select(db.completions).get(), before);
    });

    test('R-6 / RS5: two active goals → the phone keeps its own; the server\'s completes on its start', () async {
      clock.instant = DateTime(2026, 10, 1, 9);
      await repo.addItem(const GoalItemSpec.bani('REHR'));
      final phoneGoal = (await repo.activeGoal())!;
      const sg = '33333333-3333-4333-8333-333333333333';
      const si = '44444444-4444-4444-8444-444444444444';
      serve(goals: [
        {
          'goal': {'id': sg, 'startDate': '2026-08-01', 'completedOn': null, 'createdAt': '2026-08-01T00:00:00.000Z', 'updatedAt': '2026-08-01T00:00:00.000Z'},
          'items': [
            {
              'id': si, 'goalId': sg, 'seriesId': si, 'itemType': 'BANI', 'baniId': 'JAPJ', 'timesPerDay': 1,
              'simranMinutes': null, 'durationType': 'EVERY_DAY', 'durationDays': null, 'startDate': '2026-08-01',
              'endDate': null, 'removedOn': null, 'reminderTime': null,
              'createdAt': '2026-08-01T00:00:00.000Z', 'updatedAt': '2026-08-01T00:00:00.000Z',
            },
          ],
        },
      ]);
      await service.restore();
      expect((await repo.activeGoal())!.id, phoneGoal.id);
      final serverGoal = await (db.select(db.goals)..where((g) => g.id.equals(sg))).getSingle();
      expect(serverGoal.completedOn, phoneGoal.startDate);
      final serverItem = await (db.select(db.goalItems)..where((i) => i.id.equals(si))).getSingle();
      expect(serverItem.removedOn, phoneGoal.startDate);
      // August keeps its history: Japji was in scope then.
      expect((await repo.dayRows(DateTime(2026, 8, 15))).verdict.itemsInScope, 1);
    });
  });

  test('every row survives the JSON round trip the server validates', () async {
    await repo.addItem(const GoalItemSpec.simran(11, durationType: DurationType.days, durationDays: 40, reminderTime: '05:30'));
    await read('JAPJ');
    await repo.logSitting(duration: const Duration(minutes: 11), completed: true, source: SittingSource.timer);
    final rows = await BackupStore(db).changedSince(null);
    for (final g in rows.goals) {
      expect(BackupJson.goalFrom(BackupJson.goal(g)), g);
    }
    for (final i in rows.items) {
      final j = BackupJson.item(i);
      expect(j['itemType'], 'SIMRAN');
      expect(j['durationType'], 'DAYS');
      expect(BackupJson.itemFrom(j), i);
    }
    for (final c in rows.completions) {
      expect(BackupJson.completion(c)['slot'], 'MORNING');
      expect(BackupJson.completionFrom(BackupJson.completion(c)), c);
    }
    for (final s in rows.sittings) {
      expect(BackupJson.sitting(s)['source'], 'TIMER');
      expect(BackupJson.sittingFrom(BackupJson.sitting(s)), s);
    }
  });
}
