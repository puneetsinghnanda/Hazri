import '../../../core/db/user_db.dart';

/// `user.db` rows as the backup carries them (10-backup §5.1, ARCHITECTURE
/// §6.4): camelCase fields, dates `YYYY-MM-DD`, date-times ISO 8601 UTC, and
/// enums in the UPPER_SNAKE spelling `user.db` stores. The server validates
/// exactly these fields (`functions/src/backup/rows.ts`).
abstract final class BackupJson {
  static String _iso(DateTime d) => d.toUtc().toIso8601String();
  static String? _isoOrNull(DateTime? d) => d == null ? null : _iso(d);
  static DateTime _dt(Object? v) => DateTime.parse(v! as String).toLocal();
  static DateTime? _dtOrNull(Object? v) => v == null ? null : _dt(v);

  static String _upper(Enum e) => UpperSnake.encode(e);
  static T _enum<T extends Enum>(List<T> values, Object? v) =>
      values.firstWhere((e) => UpperSnake.encode(e) == v);

  static Map<String, Object?> goal(Goal g) => {
        'id': g.id,
        'startDate': g.startDate,
        'completedOn': g.completedOn,
        'createdAt': _iso(g.createdAt),
        'updatedAt': _iso(g.updatedAt),
      };

  static Goal goalFrom(Map<String, Object?> j) => Goal(
        id: j['id']! as String,
        startDate: j['startDate']! as String,
        completedOn: j['completedOn'] as String?,
        createdAt: _dt(j['createdAt']),
        updatedAt: _dt(j['updatedAt']),
      );

  static Map<String, Object?> item(GoalItem i) => {
        'id': i.id,
        'goalId': i.goalId,
        'seriesId': i.seriesId,
        'itemType': _upper(i.itemType),
        'baniId': i.baniId,
        'timesPerDay': i.timesPerDay,
        'simranMinutes': i.simranMinutes,
        'durationType': _upper(i.durationType),
        'durationDays': i.durationDays,
        'startDate': i.startDate,
        'endDate': i.endDate,
        'removedOn': i.removedOn,
        'reminderTime': i.reminderTime,
        'createdAt': _iso(i.createdAt),
        'updatedAt': _iso(i.updatedAt),
      };

  static GoalItem itemFrom(Map<String, Object?> j) => GoalItem(
        id: j['id']! as String,
        goalId: j['goalId']! as String,
        seriesId: j['seriesId']! as String,
        itemType: _enum(ItemType.values, j['itemType']),
        baniId: j['baniId'] as String?,
        timesPerDay: (j['timesPerDay']! as num).toInt(),
        simranMinutes: (j['simranMinutes'] as num?)?.toInt(),
        durationType: _enum(DurationType.values, j['durationType']),
        durationDays: (j['durationDays'] as num?)?.toInt(),
        startDate: j['startDate']! as String,
        endDate: j['endDate'] as String?,
        removedOn: j['removedOn'] as String?,
        reminderTime: j['reminderTime'] as String?,
        createdAt: _dt(j['createdAt']),
        updatedAt: _dt(j['updatedAt']),
      );

  static Map<String, Object?> completion(Completion c) => {
        'id': c.id,
        'localDate': c.localDate,
        'baniId': c.baniId,
        'slot': _upper(c.slot),
        'source': _upper(c.source),
        'completedAt': _iso(c.completedAt),
        'updatedAt': _iso(c.updatedAt),
        'deletedAt': _isoOrNull(c.deletedAt),
      };

  static Completion completionFrom(Map<String, Object?> j) => Completion(
        id: j['id']! as String,
        localDate: j['localDate']! as String,
        baniId: j['baniId']! as String,
        slot: _enum(BaniSlotValue.values, j['slot']),
        source: _enum(CompletionSource.values, j['source']),
        completedAt: _dt(j['completedAt']),
        updatedAt: _dt(j['updatedAt']),
        deletedAt: _dtOrNull(j['deletedAt']),
      );

  static Map<String, Object?> sitting(SimranSession s) => {
        'id': s.id,
        'localDate': s.localDate,
        'startedAt': _iso(s.startedAt),
        'durationS': s.durationS,
        'completed': s.completed,
        'count': s.count,
        'source': _upper(s.source),
        'updatedAt': _iso(s.updatedAt),
        'deletedAt': _isoOrNull(s.deletedAt),
      };

  static SimranSession sittingFrom(Map<String, Object?> j) => SimranSession(
        id: j['id']! as String,
        localDate: j['localDate']! as String,
        startedAt: _dt(j['startedAt']),
        durationS: (j['durationS']! as num).toInt(),
        count: (j['count'] as num?)?.toInt() ?? 0,
        completed: j['completed'] == true,
        source: _enum(SittingSource.values, j['source']),
        updatedAt: _dt(j['updatedAt']),
        deletedAt: _dtOrNull(j['deletedAt']),
      );

  /// 12-badges BB1.
  static Map<String, Object?> badge(BadgeRow b) => {
        'badgeId': b.badgeId,
        'earnedOn': b.earnedOn,
        'announcedAt': _isoOrNull(b.announcedAt),
        'createdAt': _iso(b.createdAt),
        'updatedAt': _iso(b.updatedAt),
      };

  static BadgeRow badgeFrom(Map<String, Object?> j) => BadgeRow(
        badgeId: j['badgeId']! as String,
        earnedOn: j['earnedOn']! as String,
        announcedAt: _dtOrNull(j['announcedAt']),
        createdAt: _dt(j['createdAt']),
        updatedAt: _dt(j['updatedAt']),
      );
}
