import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/features/goals/domain/day_verdict.dart';

/// 04-goals §5.8 and B-6: a schema-4 database, built by hand the way v4
/// wrote it, opened by the v5 code.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // Drift's default: DateTime as unix seconds.
  int at(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  UserDb v4() => UserDb(NativeDatabase.memory(setup: (raw) {
        raw.execute('''
          CREATE TABLE reading_progress (bani_version_id TEXT NOT NULL PRIMARY KEY,
            line_idx INTEGER NOT NULL DEFAULT 0, audio_pos_ms INTEGER NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL);
          CREATE TABLE completions (id TEXT NOT NULL PRIMARY KEY, local_date TEXT NOT NULL,
            bani_id TEXT NOT NULL, slot TEXT NOT NULL, source TEXT NOT NULL, goal_id TEXT,
            completed_at INTEGER NOT NULL);
          CREATE TABLE simran_sessions (id TEXT NOT NULL PRIMARY KEY, local_date TEXT NOT NULL,
            started_at INTEGER NOT NULL, duration_s INTEGER NOT NULL,
            count INTEGER NOT NULL DEFAULT 0, completed INTEGER NOT NULL DEFAULT 0);
          CREATE TABLE goals (id TEXT NOT NULL PRIMARY KEY, bani_id TEXT NOT NULL, minutes INTEGER,
            times_per_day INTEGER NOT NULL DEFAULT 1, duration_type TEXT NOT NULL, days INTEGER,
            until_date TEXT, start_date TEXT NOT NULL, reminder_time TEXT, ended_on TEXT,
            active INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);
          CREATE TABLE goal_ticks (id TEXT NOT NULL PRIMARY KEY, goal_id TEXT NOT NULL,
            local_date TEXT NOT NULL, source TEXT NOT NULL, at INTEGER NOT NULL);
          CREATE TABLE reminders (id TEXT NOT NULL PRIMARY KEY, target_type TEXT NOT NULL,
            target_id TEXT NOT NULL, mode TEXT NOT NULL, anchor TEXT, offset_min INTEGER,
            time_hhmm TEXT, days_mask INTEGER NOT NULL DEFAULT 127, slot_override TEXT,
            updated_at INTEGER NOT NULL);
          CREATE TABLE grace_days (local_date TEXT NOT NULL PRIMARY KEY, month_key TEXT NOT NULL);
          CREATE TABLE event_reminder_overrides (event_id TEXT NOT NULL PRIMARY KEY,
            enabled INTEGER NOT NULL);
        ''');
        final t = at(DateTime(2026, 9, 1, 6));
        raw.execute('''
          INSERT INTO goals VALUES ('g1','JAPJ',NULL,1,'everyDay',NULL,NULL,'2026-09-01','06:00',NULL,1,$t,$t);
          INSERT INTO goals VALUES ('g2','simran',11,1,'everyDay',NULL,NULL,'2026-09-01',NULL,'2026-09-10',0,$t,$t);
          INSERT INTO completions VALUES ('c1','2026-09-05','JAPJ','morning','read','g1',${at(DateTime(2026, 9, 5, 5))});
          INSERT INTO completions VALUES ('c2','2026-09-05','REHR','evening','listen',NULL,${at(DateTime(2026, 9, 5, 19))});
          INSERT INTO goal_ticks VALUES ('t1','g1','2026-09-05','auto',${at(DateTime(2026, 9, 5, 5))});
          INSERT INTO goal_ticks VALUES ('t2','g1','2026-09-06','manual',${at(DateTime(2026, 9, 6, 8))});
          INSERT INTO goal_ticks VALUES ('t3','g2','2026-09-07','manual',${at(DateTime(2026, 9, 7, 8))});
          INSERT INTO simran_sessions VALUES ('s1','2026-09-08',${at(DateTime(2026, 9, 8, 5))},600,0,1);
          INSERT INTO reminders VALUES ('amrit','slot','morning','auto','sunrise',-90,NULL,127,NULL,$t);
          INSERT INTO grace_days VALUES ('2026-09-04','2026-09');
          PRAGMA user_version = 4;
        ''');
      }));

  test('B-6: goals become one goal of items, ticks become rows, old tables go', () async {
    final db = v4();
    addTearDown(db.close);

    final goals = await db.select(db.goals).get();
    expect(goals, hasLength(1));
    expect(goals.single.startDate, '2026-09-01');
    expect(goals.single.completedOn, isNull, reason: 'Japji every day is still running');

    final items = await db.select(db.goalItems).get();
    final japji = items.singleWhere((i) => i.itemType == ItemType.bani);
    final simran = items.singleWhere((i) => i.itemType == ItemType.simran);
    expect(japji.baniId, 'JAPJ');
    expect(japji.reminderTime, '06:00');
    expect(simran.simranMinutes, 11);
    expect(simran.removedOn, '2026-09-11', reason: 'the day after the old endedOn');

    final completions = await db.select(db.completions).get();
    expect(completions.firstWhere((c) => c.id == 'c1').source, CompletionSource.reader);
    expect(completions.firstWhere((c) => c.id == 'c2').source, CompletionSource.audio);
    expect(completions.firstWhere((c) => c.id == 'c1').slot, BaniSlotValue.morning);
    final migrated = completions.where((c) => c.source == CompletionSource.migrated).toList();
    expect(migrated, hasLength(1), reason: 'the auto tick had a completion behind it and goes');
    expect(migrated.single.localDate, '2026-09-06');

    final sittings = await db.select(db.simranSessions).get();
    expect(sittings.firstWhere((s) => s.id == 's1').source, SittingSource.timer);
    final manualSitting = sittings.singleWhere((s) => s.source == SittingSource.migrated);
    expect(manualSitting.localDate, '2026-09-07');
    expect(manualSitting.durationS, 660);

    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((r) => r.read<String>('name'))
        .get();
    expect(tables, isNot(contains('goal_ticks')));
    expect(tables, isNot(contains('reminders')));
    expect(tables, isNot(contains('goals_v4')));
    expect(tables, contains('sangat_outbox'));
    expect(await db.select(db.graceDays).get(), hasLength(1));
  });

  test('B-6: the dots v4 showed survive the migration', () async {
    final db = v4();
    addTearDown(db.close);
    final items = await db.select(db.goalItems).get();
    final completions = await db.select(db.completions).get();
    final sittings = await db.select(db.simranSessions).get();
    DayVerdict v(String day) => verdictOn(day, items, completions, sittings);

    // 6 Sep: Japji ticked by hand → met; the simran item was in scope and not.
    expect(v('2026-09-06').hazri, isTrue);
    expect(v('2026-09-06').itemsMet, 1);
    expect(v('2026-09-06').itemsInScope, 2);
    // 7 Sep: the hand-ticked simran is a sitting of its goal's 11 minutes.
    expect(v('2026-09-07').itemsMet, 1);
    // From 11 Sep only Japji is judged.
    expect(v('2026-09-12').itemsInScope, 1);
  });
}
