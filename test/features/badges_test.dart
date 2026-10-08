import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/backup/domain/backup_json.dart';
import 'package:hazri/features/badges/data/badge_store.dart';
import 'package:hazri/features/badges/domain/badges.dart';

/// 12-badges §9, against an in-memory user.db.
void main() {
  const morning = {'JAPJ', 'JAAP', 'TVPS', 'CHAU', 'ANND'};
  const all = {...morning, 'REHR', 'SOHL', 'ARDS', 'SUKH'};

  group('§3.2 rules at the threshold and one below', () {
    BadgeCounts c({int hazri = 0, int nitnem = 0, int simran = 0, Set<String> banis = const {}, int goals = 0, int joins = 0}) =>
        BadgeCounts(
          hazriDays: hazri,
          nitnemDays: nitnem,
          simranDays: simran,
          banisCompleted: banis,
          allBanis: all,
          goalsReached: goals,
          joins: joins,
        );

    for (final (badge, at, below) in [
      (BadgeId.jigyasu, c(hazri: 1), c()),
      (BadgeId.shardhalu, c(hazri: 7), c(hazri: 6)),
      (BadgeId.abhyasi, c(hazri: 40), c(hazri: 39)),
      (BadgeId.nitnemi, c(nitnem: 40), c(nitnem: 39)),
      (BadgeId.simrani, c(simran: 108), c(simran: 107)),
      (BadgeId.paathi, c(banis: all), c(banis: all.difference({'ARDS'}))),
      (BadgeId.sevadar, c(goals: 3), c(goals: 2)),
      (BadgeId.satsangi, c(joins: 5), c(joins: 4)),
      (BadgeId.vichari, c(hazri: 365), c(hazri: 364)),
    ]) {
      test('${badge.id}: earned at the threshold, not one below', () {
        expect(badgesMet(at), contains(badge));
        expect(badgesMet(below), isNot(contains(badge)));
      });
    }

    test('GURSIKH: Nitnemi, Simrani, Paathi and 180 hazri days', () {
      final full = c(hazri: 180, nitnem: 40, simran: 108, banis: all);
      expect(badgesMet(full), contains(BadgeId.gursikh));
      expect(badgesMet(c(hazri: 179, nitnem: 40, simran: 108, banis: all)), isNot(contains(BadgeId.gursikh)));
      // The three held already count, even if a count has since dropped.
      expect(
        badgesMet(c(hazri: 180), earned: {BadgeId.nitnemi, BadgeId.simrani, BadgeId.paathi}),
        contains(BadgeId.gursikh),
      );
    });

    test('B-8: without the Sangat facts, eight at most', () {
      final everything = c(hazri: 400, nitnem: 400, simran: 400, banis: all);
      expect(badgesMet(everything), hasLength(8));
    });
  });

  group('counts from user.db', () {
    late UserDb db;
    late UserRepository repo;
    late FixedClock clock;
    late BadgeStore store;

    setUp(() {
      db = UserDb.memory();
      clock = FixedClock(DateTime(2026, 1, 1, 6));
      repo = UserRepository(db, clock);
      store = BadgeStore(db);
    });
    tearDown(() => db.close());

    Future<void> read(String bani, DateTime day) async {
      clock.instant = day;
      await repo.logCompletion(baniId: bani, slot: BaniSlotValue.morning, source: CompletionSource.reader);
    }

    test('HC3: totals, never runs — days far apart count', () async {
      for (var i = 0; i < 7; i++) {
        await read('SUKH', DateTime(2026, 1, 1 + i * 20, 6));
      }
      final counts = await store.counts(morningBanis: morning, allBanis: all);
      expect(counts.hazriDays, 7);
      expect(badgesMet(counts), contains(BadgeId.shardhalu));
    });

    test('B-4a / B-4b: a Nitnem day needs exactly the five morning banis', () async {
      final day1 = DateTime(2026, 1, 1, 6);
      for (final b in ['JAPJ', 'JAAP', 'TVPS', 'ANND', 'REHR', 'SOHL']) {
        await read(b, day1); // all but Chaupai
      }
      final day2 = DateTime(2026, 1, 2, 6);
      for (final b in morning) {
        await read(b, day2);
      }
      final counts = await store.counts(morningBanis: morning, allBanis: all);
      expect(counts.nitnemDays, 1);
    });

    test('B-5: Sukhmani alone is a hazri day, not a Nitnem day', () async {
      await read('SUKH', DateTime(2026, 1, 3, 6));
      final counts = await store.counts(morningBanis: morning, allBanis: all);
      expect((counts.hazriDays, counts.nitnemDays), (1, 0));
    });

    test('B-6: four-minute sittings are no simran days', () async {
      clock.instant = DateTime(2026, 1, 4, 6);
      await repo.logSitting(duration: const Duration(minutes: 4), completed: false, source: SittingSource.timer);
      final counts = await store.counts(morningBanis: morning, allBanis: all);
      expect((counts.simranDays, counts.hazriDays), (0, 0));
    });

    test('NT1 / B-3: a Diary − below the threshold keeps the badge', () async {
      await read('JAPJ', DateTime(2026, 1, 5, 6));
      await store.insertNew(badgesMet(await store.counts(morningBanis: morning, allBanis: all)), today: '2026-01-05');
      await repo.undoLatestCompletion('JAPJ', DateTime(2026, 1, 5));
      await store.insertNew(badgesMet(await store.counts(morningBanis: morning, allBanis: all)), today: '2026-01-05');
      expect((await store.all()).map((r) => r.badgeId), contains('JIGYASU'));
    });

    test('EV1: an existing row is never updated', () async {
      await store.insertNew({BadgeId.jigyasu}, today: '2026-01-01');
      await store.insertNew({BadgeId.jigyasu}, today: '2026-02-01');
      expect((await store.all()).single.earnedOn, '2026-01-01');
    });

    test('AN2 / LS2 / B-12: several waiting → the highest announced, the rest marked', () async {
      await store.insertNew({BadgeId.jigyasu, BadgeId.shardhalu, BadgeId.abhyasi}, today: '2026-01-01');
      expect(await store.takeAnnouncement(), BadgeId.abhyasi);
      expect(await store.takeAnnouncement(), isNull);
      expect((await store.all()).every((r) => r.announcedAt != null), isTrue);
    });

    test('BB3 / B-14: a restore inserts, keeps the earlier date, never announces', () async {
      await store.insertNew({BadgeId.jigyasu}, today: '2026-03-01');
      final now = DateTime.utc(2026, 3, 1);
      final added = await store.mergeRestored([
        BadgeRow(badgeId: 'JIGYASU', earnedOn: '2026-01-15', announcedAt: now, createdAt: now, updatedAt: now),
        BadgeRow(badgeId: 'SHARDHALU', earnedOn: '2026-01-20', createdAt: now, updatedAt: now),
      ]);
      expect(added, 1);
      final rows = {for (final r in await store.all()) r.badgeId: r};
      expect(rows['JIGYASU']!.earnedOn, '2026-01-15');
      expect(rows['SHARDHALU']!.announcedAt, isNotNull);
    });

    test('BB1: a badge row survives the backup JSON round trip', () async {
      await store.insertNew({BadgeId.nitnemi}, today: '2026-01-01', silent: true);
      final row = (await store.all()).single;
      expect(BackupJson.badgeFrom(BackupJson.badge(row)), row);
    });
  });
}
