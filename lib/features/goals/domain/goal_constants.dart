/// The fixed constants of 04-goals.md §3. No other file may hard-code them.
abstract final class GoalConstants {
  /// A sitting this long or longer marks hazri (HZ1).
  static const hazriSimranMinSeconds = 300;

  /// The Simran timer's length when no simran item is in scope (HZ4).
  static const simranDefaultMinutes = 5;

  /// The range a stored bani item may hold. Every item made since
  /// 2026-10-19 is read once a day (GI10); larger targets survive only in
  /// history rows, so past verdicts stay as they were.
  static const timesPerDayMin = 1;
  static const timesPerDayMax = 11;

  static const simranGoalMinutesMin = 5;
  static const simranGoalMinutesMax = 120;
  static const simranGoalMinutesPresets = [5, 11, 21, 31];

  /// Design 47's default when Naam Simran is chosen.
  static const simranGoalMinutesDefault = 11;

  static const durationDaysMin = 1;
  static const durationDaysMax = 365;
  static const durationDaysPreset = 40;
  static const untilDateMaxAheadDays = 365;

  /// Today and the seven days before it can be edited in the Diary.
  static const diaryEditWindowDays = 7;

  /// Reminders are always on (RM1, owner 2026-10-19). Each bani starts at
  /// its own time, keyed by its `content.db` id; the person can move it.
  static const reminderDefaults = {
    'JAPJ': '06:00',
    'JAAP': '06:15',
    'TVPS': '06:30',
    'CHAU': '06:45',
    'ANND': '07:00',
    'SUKH': '11:00',
    'REHR': '18:00',
    'ARDS': '18:30',
    'SOHL': '19:00',
  };

  /// Naam Simran's reminder: Amrit Vela.
  static const simranReminderDefault = '05:30';

  /// A bani added to `content.db` later, with no time of its own above.
  static const reminderDefaultTime = '19:30';

  /// The time a new item's reminder starts at (RM1).
  static String reminderFor({String? baniId, bool simran = false}) =>
      simran ? simranReminderDefault : (reminderDefaults[baniId] ?? reminderDefaultTime);
}
