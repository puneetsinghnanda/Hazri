import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'user_db.g.dart';

/// How a completion came to be recorded.
/// How a completion came to be recorded.
///
/// `restored` is a diary day that came back from the account on a new phone.
/// Kept apart from `manual` because it was not somebody ticking a box, and a
/// diary that cannot tell the two apart cannot explain itself later.
enum CompletionSource { read, listen, manual, restored }

/// Whether a reminder follows the sun, a fixed time, or is off.
enum ReminderMode { auto, fixed, off }

/// What a reminder is attached to.
enum ReminderTarget { slot, bani, simran, gurpurab, goal }

/// How long a paath goal runs for.
enum GoalDuration { everyDay, days, until }

/// Where the reader or player last was in a bani.
class ReadingProgress extends Table {
  TextColumn get baniVersionId => text()();
  IntColumn get lineIdx => integer().withDefault(const Constant(0))();
  IntColumn get audioPosMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {baniVersionId};
}

/// One bani finished on one day.
class Completions extends Table {
  TextColumn get id => text()();
  TextColumn get localDate => text()();
  TextColumn get baniId => text()();
  TextColumn get slot => textEnum<BaniSlotValue>()();
  TextColumn get source => textEnum<CompletionSource>()();
  TextColumn get goalId => text().nullable()();
  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirrors `BaniSlot` from the content database so completions can be stored
/// per slot without the two databases depending on each other.
enum BaniSlotValue { morning, evening, bedtime, none }

class SimranSessions extends Table {
  TextColumn get id => text()();
  TextColumn get localDate => text()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get durationS => integer()();
  IntColumn get count => integer().withDefault(const Constant(0))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// The id a Naam Simran goal carries in [Goals.baniId].
///
/// Simran is not a bani and has no row in content.db, so a goal for it needs
/// an id of its own. A sentinel rather than a second table: everything else
/// about a goal -- its schedule, its ticks, its length -- is identical, and
/// two tables would mean two of every query.
const String kSimranGoalId = 'simran';

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get baniId => text()();

  /// How many minutes a sitting is, for a Naam Simran goal (design 47).
  /// Null for a bani, which is counted in paath.
  IntColumn get minutes => integer().nullable()();
  IntColumn get timesPerDay => integer().withDefault(const Constant(1))();
  TextColumn get durationType => textEnum<GoalDuration>()();
  IntColumn get days => integer().nullable()();
  TextColumn get untilDate => text().nullable()();
  TextColumn get startDate => text()();
  TextColumn get reminderTime => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class GoalTicks extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text()();
  TextColumn get localDate => text()();
  TextColumn get source => text()();
  DateTimeColumn get at => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get targetType => textEnum<ReminderTarget>()();
  TextColumn get targetId => text()();
  TextColumn get mode => textEnum<ReminderMode>()();
  TextColumn get anchor => text().nullable()();
  IntColumn get offsetMin => integer().nullable()();
  TextColumn get timeHhmm => text().nullable()();
  IntColumn get daysMask => integer().withDefault(const Constant(0x7F))();
  TextColumn get slotOverride => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A missed day the streak forgives. Two per calendar month.
class GraceDays extends Table {
  TextColumn get localDate => text()();
  TextColumn get monthKey => text()();

  @override
  Set<Column> get primaryKey => {localDate};
}

class EventReminderOverrides extends Table {
  TextColumn get eventId => text()();
  BoolColumn get enabled => boolean()();

  @override
  Set<Column> get primaryKey => {eventId};
}

/// Everything the user creates.
///
/// Every row carries a UUID id and `updated_at` in UTC so that optional sync
/// can be added later without a migration (PRD §17.1).
@DriftDatabase(
  tables: [
    ReadingProgress,
    Completions,
    SimranSessions,
    Goals,
    GoalTicks,
    Reminders,
    GraceDays,
    EventReminderOverrides,
  ],
)
class UserDb extends _$UserDb {
  UserDb(super.e);

  /// For tests: an in-memory database with the schema applied.
  UserDb.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // 2: the daily Hukamnama gave way to ਅੱਜ ਦਾ ਵਿਚਾਰ, which is bundled
      // content and needs no cache of its own.
      if (from < 2) await customStatement('DROP TABLE IF EXISTS hukamnama_cache');
      // 3: a goal can now be Naam Simran, which is counted in minutes rather
      // than paath (design 47). Nullable, so every existing goal is untouched
      // and still means what it meant.
      if (from < 3) await m.addColumn(goals, goals.minutes);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static Future<UserDb> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'user.db'));
    await file.parent.create(recursive: true);
    return UserDb(NativeDatabase.createInBackground(file));
  }
}
