/// The fixed constants of 04-goals.md §3. No other file may hard-code them.
abstract final class GoalConstants {
  /// A sitting this long or longer marks hazri (HZ1).
  static const hazriSimranMinSeconds = 300;

  /// The Simran timer's length when no simran item is in scope (HZ4).
  static const simranDefaultMinutes = 5;

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

  /// Pre-filled when a reminder is switched on; reminders start off (RM1).
  static const reminderDefaultTime = '19:30';
}
