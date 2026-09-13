import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart' show BaniSlot;
import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/reminders_controller.dart';
import '../domain/reminder_plan.dart';
import 'reminder_row.dart';
import 'time_wheel.dart';

/// The reminder time sheet (Design 08).
Future<void> showReminderTimeSheet(
  BuildContext context, {
  required String reminderId,
  String? title,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReminderTimeSheet(reminderId: reminderId, title: title),
    );

class _ReminderTimeSheet extends ConsumerStatefulWidget {
  const _ReminderTimeSheet({required this.reminderId, this.title});

  final String reminderId;
  final String? title;

  @override
  ConsumerState<_ReminderTimeSheet> createState() => _ReminderTimeSheetState();
}

class _ReminderTimeSheetState extends ConsumerState<_ReminderTimeSheet> {
  ReminderMode? _mode;
  TimeOfDay? _time;
  int? _daysMask;
  String? _slotOverride;
  bool _loaded = false;

  /// Only Amrit Vela, Rehras and Sohila have an Auto rule to offer.
  bool get _supportsAuto => const {
    ReminderIds.amritVela,
    ReminderIds.evening,
    ReminderIds.bedtime,
  }.contains(widget.reminderId);

  void _loadFrom(Reminder? r) {
    if (_loaded) return;
    _loaded = true;
    _mode = r?.mode ?? (_supportsAuto ? ReminderMode.auto : ReminderMode.fixed);
    _daysMask = r?.daysMask ?? 0x7F;
    _slotOverride = r?.slotOverride;
    final hhmm = r?.timeHhmm;
    if (hhmm != null) {
      final parts = hhmm.split(':');
      _time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } else {
      _time = const TimeOfDay(hour: 7, minute: 0);
    }
  }

  Future<void> _save({bool turnOff = false}) async {
    final repo = ref.read(userRepositoryProvider);
    final time = _time ?? const TimeOfDay(hour: 7, minute: 0);
    await repo.saveReminder(
      RemindersCompanion.insert(
        id: widget.reminderId,
        targetType: _targetType,
        targetId: widget.reminderId,
        mode: turnOff ? ReminderMode.off : (_mode ?? ReminderMode.fixed),
        timeHhmm: Value(
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        ),
        daysMask: Value(_daysMask ?? 0x7F),
        slotOverride: Value(_slotOverride),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await ref.read(reminderSchedulerProvider).reschedule();
    if (mounted) Navigator.of(context).pop();
  }

  ReminderTarget get _targetType => switch (widget.reminderId) {
    ReminderIds.simran => ReminderTarget.simran,
    ReminderIds.gurpurab => ReminderTarget.gurpurab,
    _ => widget.reminderId.startsWith('goal:') ? ReminderTarget.goal : ReminderTarget.slot,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    _loadFrom(reminders.where((r) => r.id == widget.reminderId).firstOrNull);

    final auto = ref.watch(autoTimesProvider).value?[widget.reminderId];
    final autoLabel = auto == null
        ? l.reminderAuto
        : widget.reminderId == ReminderIds.amritVela
            ? l.reminderSheetBeforeSunriseToday(dates.time(auto))
            : l.reminderSheetAtSunsetToday(dates.time(auto));

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: HazriSize.gutter,
          right: HazriSize.gutter,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.rule,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              l.reminderSheetTitle(widget.title ?? ReminderRow.titleFor(l, widget.reminderId)),
              style: HazriText.display22.copyWith(color: c.ink),
            ),
            const SizedBox(height: 16),
            if (_supportsAuto) ...[
              _ModeChoice(
                label: l.reminderAuto,
                sub: autoLabel,
                selected: _mode == ReminderMode.auto,
                onTap: () => setState(() => _mode = ReminderMode.auto),
              ),
              const SizedBox(height: 8),
            ],
            _ModeChoice(
              label: l.reminderMyTime,
              sub: l.reminderSheetSameTime,
              selected: _mode == ReminderMode.fixed,
              onTap: () => setState(() => _mode = ReminderMode.fixed),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _mode == ReminderMode.fixed ? 1 : 0.4,
              child: IgnorePointer(
                ignoring: _mode != ReminderMode.fixed,
                child: TimeWheel(
                  value: _time ?? const TimeOfDay(hour: 7, minute: 0),
                  onChanged: (v) => setState(() => _time = v),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.reminderSheetRepeat, style: HazriText.bodyStrong.copyWith(color: c.ink)),
            const SizedBox(height: 8),
            _DayChips(
              mask: _daysMask ?? 0x7F,
              onChanged: (m) => setState(() => _daysMask = m),
            ),
            if (_targetType == ReminderTarget.slot) ...[
              const SizedBox(height: 18),
              Text(
                l.reminderSheetShowInMyDay,
                style: HazriText.bodyStrong.copyWith(color: c.ink),
              ),
              const SizedBox(height: 8),
              _SlotChoice(
                value: _slotOverride,
                onChanged: (v) => setState(() => _slotOverride = v),
              ),
            ],
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => _save(turnOff: true),
              child: Text(
                l.reminderSheetTurnOff,
                style: HazriText.body.copyWith(color: c.muted, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            PrimaryButton(label: l.actionSave, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _ModeChoice extends StatelessWidget {
  const _ModeChoice({
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HazriCard(
      onTap: onTap,
      colour: selected ? c.kesriSoft : c.card2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: selected ? Border.all(color: c.kesri, width: 1.5) : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: HazriText.bodyStrong
                      .copyWith(color: selected ? c.kesriInk : c.ink),
                ),
                Text(
                  sub,
                  style: HazriText.bodySmall
                      .copyWith(color: selected ? c.kesriInk : c.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChips extends StatelessWidget {
  const _DayChips({required this.mask, required this.onChanged});

  final int mask;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final labels = [l.dayMon, l.dayTue, l.dayWed, l.dayThu, l.dayFri, l.daySat, l.daySun];

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(HazriRadius.chip),
                onTap: () => onChanged(mask ^ (1 << i)),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: (mask & (1 << i)) != 0 ? c.primary : c.card2,
                    borderRadius: BorderRadius.circular(HazriRadius.chip),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: HazriText.chip.copyWith(
                        color: (mask & (1 << i)) != 0 ? c.onPrimary : c.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SlotChoice extends StatelessWidget {
  const _SlotChoice({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final options = <(String, String)>[
      (BaniSlot.morning.name, l.slotMorning),
      (BaniSlot.evening.name, l.slotEvening),
      (BaniSlot.bedtime.name, l.slotBedtime),
    ];

    return Row(
      children: [
        for (final (slot, label) in options)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(HazriRadius.chip),
                onTap: () => onChanged(value == slot ? null : slot),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: value == slot ? c.kesriSoft : c.card2,
                    borderRadius: BorderRadius.circular(HazriRadius.chip),
                    border: value == slot ? Border.all(color: c.kesri) : null,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: HazriText.chip.copyWith(
                        color: value == slot ? c.kesriInk : c.ink2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
