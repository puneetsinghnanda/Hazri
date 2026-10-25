import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'user_db.g.dart';

// The schema of `user.db`, version 5. ARCHITECTURE §3.3 (04-goals §5) is the
// definition; this file is its code. Enum columns hold UPPER_SNAKE strings
// (04-goals §5.1), so every enum here goes through [UpperSnake].

/// How a completion came to be recorded (04-goals §5.4).
enum CompletionSource { reader, audio, diary, restored, migrated }

/// How a Naam Simran sitting came to be recorded (04-goals §5.5).
enum SittingSource { timer, diary, restored, migrated }

/// A goal item is one bani, or Naam Simran (04-goals §5.3).
enum ItemType { bani, simran }

/// How long a goal item runs (04-goals GI4).
enum DurationType { everyDay, days, untilDate }

/// Mirrors `BaniSlot` from the content database so completions can carry a
/// slot without the two databases depending on each other.
enum BaniSlotValue { morning, evening, bedtime, none }

/// Stores a Dart enum as its UPPER_SNAKE name: `everyDay` ↔ `EVERY_DAY`.
class UpperSnake<T extends Enum> extends TypeConverter<T, String> {
  const UpperSnake(this.values);

  final List<T> values;

  static String encode(Enum e) => e.name
      .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
      .toUpperCase();

  @override
  T fromSql(String fromDb) => values.firstWhere((v) => encode(v) == fromDb);

  @override
  String toSql(T value) => encode(value);
}

/// Where the reader or player last was in a bani.
class ReadingProgress extends Table {
  TextColumn get baniVersionId => text()();
  IntColumn get lineIdx => integer().withDefault(const Constant(0))();
  IntColumn get audioPosMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {baniVersionId};
}

/// One recitation of one bani (04-goals §5.4). No uniqueness per day: reading
/// Japji three times is three rows (CR5).
@DataClassName('Completion')
class Completions extends Table {
  TextColumn get id => text()();
  TextColumn get localDate => text()();
  TextColumn get baniId => text()();
  TextColumn get slot => text().map(const UpperSnake(BaniSlotValue.values))();
  TextColumn get source => text().map(const UpperSnake(CompletionSource.values))();
  DateTimeColumn get completedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Set by Diary − (CR3). A row with it set is ignored everywhere.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One Naam Simran sitting, with its actual length (04-goals §5.5).
@DataClassName('SimranSession')
class SimranSessions extends Table {
  TextColumn get id => text()();
  TextColumn get localDate => text()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get durationS => integer()();
  IntColumn get count => integer().withDefault(const Constant(0))();

  /// True when the sitting reached the timer's planned length.
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().map(const UpperSnake(SittingSource.values))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One goal. At most one row has [completedOn] null (GL3).
@DataClassName('Goal')
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get startDate => text()();

  /// The first blank day (BG1, BG2). Null while the goal is active.
  TextColumn get completedOn => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One stretch of one bani, or of Naam Simran, inside a goal (04-goals §5.3).
@DataClassName('GoalItem')
class GoalItems extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text()();

  /// Equals [id] on the first row of a series; a target edit copies it (GI6).
  TextColumn get seriesId => text()();
  TextColumn get itemType => text().map(const UpperSnake(ItemType.values))();
  TextColumn get baniId => text().nullable()();
  IntColumn get timesPerDay => integer()();
  IntColumn get simranMinutes => integer().nullable()();
  TextColumn get durationType => text().map(const UpperSnake(DurationType.values))();
  IntColumn get durationDays => integer().nullable()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text().nullable()();
  TextColumn get removedOn => text().nullable()();

  /// `HH:mm`, local. Null means the reminder is off (RM1).
  TextColumn get reminderTime => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Paath and sittings waiting to be sent to the Sangat (08-sangat §5.1).
@DataClassName('OutboxRow')
class SangatOutbox extends Table {
  /// The completion's or sitting's id.
  TextColumn get id => text()();

  /// `BANI` or `SIMRAN`.
  TextColumn get kind => text()();
  TextColumn get baniId => text().nullable()();
  IntColumn get durationS => integer().nullable()();

  /// `READER`, `AUDIO`, `DIARY`, `TIMER`, …
  TextColumn get source => text()();
  DateTimeColumn get at => dateTime()();

  /// True when this row takes back an earlier one (Diary −, CT5).
  BoolColumn get retracted => boolean().withDefault(const Constant(false))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id, retracted};
}

/// A missed day the streak forgives. Two per calendar month, never announced.
/// Badges earned (12-badges §4.1, ARCHITECTURE §3.6). A row is never
/// deleted or taken back (NT1).
@DataClassName('BadgeRow')
class Badges extends Table {
  /// One of 12-badges §2, e.g. `JIGYASU`.
  TextColumn get badgeId => text()();

  /// The local date the rule was first found met.
  TextColumn get earnedOn => text()();

  /// When its sheet was shown, or when it was marked never to be shown.
  DateTimeColumn get announcedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {badgeId};
}

/// A saakhi the reader marked with the heart (13-saakhi.md SK12). Kept on
/// the phone only; nothing about a saakhi is counted (SK7).
class SaakhiFavourites extends Table {
  TextColumn get saakhiId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {saakhiId};
}

class GraceDays extends Table {
  TextColumn get localDate => text()();
  TextColumn get monthKey => text()();

  @override
  Set<Column> get primaryKey => {localDate};
}

/// The calendar's per-event bell (02-notifications §9).
class EventReminderOverrides extends Table {
  TextColumn get eventId => text()();
  BoolColumn get enabled => boolean()();

  @override
  Set<Column> get primaryKey => {eventId};
}

/// Everything the reader creates. Every row carries a UUID id and `updatedAt`,
/// which is what the weekly backup sends (10-backup.md).
@DriftDatabase(
  tables: [
    ReadingProgress,
    Completions,
    SimranSessions,
    Goals,
    GoalItems,
    SangatOutbox,
    GraceDays,
    EventReminderOverrides,
    Badges,
    SaakhiFavourites,
  ],
)
class UserDb extends _$UserDb {
  UserDb(super.e);

  /// For tests: an in-memory database with the schema applied.
  UserDb.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) await customStatement('DROP TABLE IF EXISTS hukamnama_cache');
          if (from < 3) await customStatement('ALTER TABLE goals ADD COLUMN minutes INTEGER');
          if (from < 4) await customStatement('ALTER TABLE goals ADD COLUMN ended_on TEXT');
          if (from < 5) await migrateToV5(this, m);
          // 12-badges §4.1: the table, empty.
          if (from < 6) await m.createTable(badges);
          // 13-saakhi SK12: the hearts, empty.
          if (from < 7) await m.createTable(saakhiFavourites);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createIndexes() async {
    // 04-goals §5.6.
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_goal_items_goal ON goal_items (goal_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_goals_completed ON goals (completed_on)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_completions_date ON completions (local_date)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_simran_date ON simran_sessions (local_date)');
  }

  static Future<UserDb> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'user.db'));
    await file.parent.create(recursive: true);
    return UserDb(NativeDatabase.createInBackground(file));
  }
}

/// The migration of 04-goals §5.8, from schema 4 to 5, in one transaction.
///
/// Public so the migration test can run it on a hand-built v4 database.
Future<void> migrateToV5(UserDb db, Migrator m) async {
  await db.transaction(() async {
    final today = _dateKey(DateTime.now());

    // 1. The old goals table makes way for goals and goal_items.
    await db.customStatement('ALTER TABLE goals RENAME TO goals_v4');
    await m.createTable(db.goals);
    await m.createTable(db.goalItems);

    final old = await db.customSelect('SELECT * FROM goals_v4').get();
    final nowUtc = DateTime.now().toUtc();
    if (old.isNotEmpty) {
      // 2. One goal for all the old rows.
      String? earliest;
      // A goal stays active while any of its items still has a day ahead of
      // it, today included; otherwise it completed the day after the last.
      var anyActive = false;
      String? latestLast;
      final items = <GoalItemsCompanion>[];
      final goalId = _uuid();
      for (final r in old) {
        final id = r.read<String>('id');
        final baniId = r.read<String>('bani_id');
        final start = r.read<String>('start_date');
        final minutes = r.readNullable<int>('minutes');
        final times = r.read<int>('times_per_day');
        final type = switch (r.read<String>('duration_type')) {
          'days' => DurationType.days,
          'until' => DurationType.untilDate,
          _ => DurationType.everyDay,
        };
        final days = r.readNullable<int>('days');
        final until = r.readNullable<String>('until_date');
        final endedOn = r.readNullable<String>('ended_on');
        final isSimran = baniId == 'simran';
        final endDate = switch (type) {
          DurationType.everyDay => null,
          DurationType.days => _dateKey(_parse(start).add(Duration(days: (days ?? 1) - 1))),
          DurationType.untilDate => until,
        };
        // removedOn: the day after old endedOn, when set.
        final removedOn = endedOn == null ? null : _dateKey(_parse(endedOn).add(const Duration(days: 1)));
        // The item's last day, for the goal's completedOn.
        final lastCandidates = [?endDate, if (removedOn != null) _dateKey(_parse(removedOn).subtract(const Duration(days: 1)))];
        lastCandidates.sort();
        final last = lastCandidates.isEmpty ? null : lastCandidates.first;
        if (last == null || last.compareTo(today) >= 0) anyActive = true;
        if (last != null && (latestLast == null || last.compareTo(latestLast) > 0)) latestLast = last;
        if (earliest == null || start.compareTo(earliest) < 0) earliest = start;

        items.add(GoalItemsCompanion.insert(
          id: id,
          goalId: goalId,
          seriesId: id,
          itemType: isSimran ? ItemType.simran : ItemType.bani,
          baniId: Value(isSimran ? null : baniId),
          // Clamped into 04-goals §3's ranges, which the backup validates:
          // one row out of range would refuse every backup after it.
          timesPerDay: isSimran ? 1 : times.clamp(1, 11),
          simranMinutes: Value(isSimran ? (minutes ?? 5).clamp(5, 120) : null),
          durationType: type,
          durationDays: Value(type == DurationType.days ? (days ?? 1).clamp(1, 365) : null),
          startDate: start,
          endDate: Value(endDate),
          removedOn: Value(removedOn),
          reminderTime: Value(r.readNullable<String>('reminder_time')),
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ));
      }
      final completedOn = anyActive || latestLast == null
          ? null
          : _dateKey(_parse(latestLast).add(const Duration(days: 1)));
      await db.into(db.goals).insert(GoalsCompanion.insert(
            id: goalId,
            startDate: earliest!,
            completedOn: Value(completedOn),
            createdAt: nowUtc,
            updatedAt: nowUtc,
          ));
      for (final i in items) {
        await db.into(db.goalItems).insert(i);
      }
    }

    // 5. completions: map the values and drop goal_id.
    await db.customStatement('ALTER TABLE completions RENAME TO completions_v4');
    await m.createTable(db.completions);
    await db.customStatement('''
      INSERT INTO completions (id, local_date, bani_id, slot, source, completed_at, updated_at, deleted_at)
      SELECT id, local_date, bani_id, UPPER(slot),
        CASE source WHEN 'read' THEN 'READER' WHEN 'listen' THEN 'AUDIO'
                    WHEN 'manual' THEN 'DIARY' WHEN 'restored' THEN 'RESTORED'
                    ELSE 'DIARY' END,
        completed_at, completed_at, NULL
      FROM completions_v4''');

    // 6. simran_sessions gain source, updated_at and deleted_at.
    await db.customStatement('ALTER TABLE simran_sessions RENAME TO simran_sessions_v4');
    await m.createTable(db.simranSessions);
    await db.customStatement('''
      INSERT INTO simran_sessions (id, local_date, started_at, duration_s, count, completed, source, updated_at, deleted_at)
      SELECT id, local_date, started_at, duration_s, count, completed, 'TIMER', started_at, NULL
      FROM simran_sessions_v4''');

    // 4. Manual ticks become MIGRATED completions or sittings; auto ticks go,
    // because a completion already stands behind each one.
    final ticks = await db.customSelect('''
      SELECT t.local_date AS day, t.at AS at, g.bani_id AS bani, g.minutes AS minutes
      FROM goal_ticks t JOIN goals_v4 g ON g.id = t.goal_id
      WHERE t.source = 'manual' ''').get();
    for (final t in ticks) {
      final day = t.read<String>('day');
      final at = t.read<DateTime>('at');
      final bani = t.read<String>('bani');
      if (bani == 'simran') {
        final minutes = t.readNullable<int>('minutes') ?? 5;
        await db.into(db.simranSessions).insert(SimranSessionsCompanion.insert(
              id: _uuid(),
              localDate: day,
              startedAt: at,
              durationS: minutes * 60,
              completed: const Value(true),
              source: SittingSource.migrated,
              updatedAt: nowUtc,
            ));
      } else {
        await db.into(db.completions).insert(CompletionsCompanion.insert(
              id: _uuid(),
              localDate: day,
              baniId: bani,
              slot: BaniSlotValue.none,
              source: CompletionSource.migrated,
              completedAt: at,
              updatedAt: nowUtc,
            ));
      }
    }

    // The sangat outbox is new in 5 (08-sangat §5.1).
    await m.createTable(db.sangatOutbox);

    for (final t in ['goal_ticks', 'goals_v4', 'completions_v4', 'simran_sessions_v4', 'reminders']) {
      await db.customStatement('DROP TABLE IF EXISTS $t');
    }
    await db._createIndexes();
  });
}

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _parse(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

final _rand = Random.secure();

String _uuid() {
  final b = List<int>.generate(16, (_) => _rand.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int from, int to) =>
      b.sublist(from, to).map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h(0, 4)}-${h(4, 6)}-${h(6, 8)}-${h(8, 10)}-${h(10, 16)}';
}
