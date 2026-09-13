import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_db.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../data/reminders_controller.dart';
import '../domain/reminder_plan.dart';
import 'reminder_time_sheet.dart';

/// One row in the reminders list: what it is, how it is timed, and the time.
///
/// Tapping it opens the reminder time sheet (Design 08).
class ReminderRow extends ConsumerWidget {
  const ReminderRow({
    super.key,
    required this.reminderId,
    required this.reminder,
    this.showDivider = true,
  });

  final String reminderId;
  final Reminder? reminder;
  final bool showDivider;

  static String titleFor(L l, String id) => switch (id) {
    ReminderIds.amritVela => l.slotAmritVela,
    ReminderIds.evening => l.diaryStatRehras,
    ReminderIds.bedtime => l.diaryStatSohila,
    ReminderIds.simran => l.reminderDailySimran,
    ReminderIds.gurpurab => l.reminderGurpurabDays,
    _ => l.goalsTitle,
  };

  static String iconFor(String id) => switch (id) {
    ReminderIds.amritVela => HazriIconData.sunArc,
    ReminderIds.evening => HazriIconData.sunset,
    ReminderIds.bedtime => HazriIconData.moon,
    ReminderIds.simran => HazriIconData.simranDots,
    ReminderIds.gurpurab => HazriIconData.calendar,
    _ => HazriIconData.flag,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final autoTimes = ref.watch(autoTimesProvider).value ?? const {};

    final mode = reminder?.mode ?? ReminderMode.off;
    final auto = autoTimes[reminderId];

    final String modeLabel;
    final String timeLabel;
    switch (mode) {
      case ReminderMode.off:
        modeLabel = l.reminderOff;
        timeLabel = '—';
      case ReminderMode.auto:
        modeLabel = switch (reminderId) {
          ReminderIds.amritVela => l.reminderAutoBeforeSunrise,
          ReminderIds.evening => l.reminderAutoAtSunset,
          _ => l.reminderAuto,
        };
        timeLabel = auto == null ? '—' : dates.time(auto);
      case ReminderMode.fixed:
        modeLabel = reminderId == ReminderIds.gurpurab
            ? l.reminderEveningBefore
            : l.reminderMyTime;
        timeLabel = _formatHhmm(context, reminder?.timeHhmm);
    }

    return Column(
      children: [
        InkWell(
          onTap: () => showReminderTimeSheet(context, reminderId: reminderId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: mode == ReminderMode.off ? c.card2 : c.kesriSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: AppIcon(
                      iconFor(reminderId),
                      size: 20,
                      color: mode == ReminderMode.off ? c.muted : c.kesriInk,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleFor(l, reminderId),
                        style: HazriText.bodyStrong.copyWith(color: c.ink),
                      ),
                      Text(modeLabel, style: HazriText.caption.copyWith(color: c.muted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.card2,
                    borderRadius: BorderRadius.circular(HazriRadius.chip),
                  ),
                  child: Text(
                    timeLabel,
                    style: HazriText.chip.copyWith(color: c.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 64),
            child: Divider(height: 1, color: c.rule),
          ),
      ],
    );
  }

  static String _formatHhmm(BuildContext context, String? hhmm) {
    if (hhmm == null) return '—';
    final parts = hhmm.split(':');
    final now = DateTime.now();
    return HazriDates.of(context).time(
      DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1])),
    );
  }
}
