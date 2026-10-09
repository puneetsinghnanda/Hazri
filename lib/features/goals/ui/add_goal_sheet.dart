import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../nitnem/domain/bani.dart';
import '../../reminders/ui/time_wheel.dart';
import '../data/goals_controller.dart';
import '../domain/goal_constants.dart';

/// The Add Goal and Edit Item sheet (04-goals §7.2, design 47). [editing]
/// opens it on an existing item; choosing a bani already in scope switches to
/// editing that item (GI1).
Future<void> showGoalItemSheet(BuildContext context, {GoalItem? editing, bool simran = false}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _GoalItemSheet(editing: editing, startWithSimran: simran),
    );

class _GoalItemSheet extends ConsumerStatefulWidget {
  const _GoalItemSheet({this.editing, this.startWithSimran = false});

  final GoalItem? editing;
  final bool startWithSimran;

  @override
  ConsumerState<_GoalItemSheet> createState() => _GoalItemSheetState();
}

/// What the chips select: a bani id, or Naam Simran.
const _simranChoice = '__simran__';

class _GoalItemSheetState extends ConsumerState<_GoalItemSheet> {
  GoalItem? _editing;
  String? _choice;
  int _times = 1;
  int _minutes = GoalConstants.simranGoalMinutesDefault;
  DurationType _duration = DurationType.everyDay;
  int _days = GoalConstants.durationDaysPreset;
  DateTime? _until;
  bool _remind = false;
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 30);
  bool _showAllBanis = false;
  String? _error;

  /// The featured banis, before More… (§7.2).
  static const _featured = ['JAPJ', 'CHAU', 'SUKH', 'ANND', 'REHR'];

  bool get _isSimran => _choice == _simranChoice;

  @override
  void initState() {
    super.initState();
    if (widget.startWithSimran) _choice = _simranChoice;
    final e = widget.editing;
    if (e != null) _loadFrom(e);
  }

  void _loadFrom(GoalItem e) {
    _editing = e;
    _choice = e.itemType == ItemType.simran ? _simranChoice : e.baniId;
    _times = e.timesPerDay;
    _minutes = e.simranMinutes ?? GoalConstants.simranGoalMinutesDefault;
    _duration = e.durationType;
    _days = e.durationDays ?? GoalConstants.durationDaysPreset;
    _until = e.durationType == DurationType.untilDate && e.endDate != null
        ? parseLocalDateKey(e.endDate!)
        : null;
    final t = e.reminderTime;
    _remind = t != null;
    if (t != null) {
      final p = t.split(':');
      _time = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
  }

  /// GI1: choosing something already in scope opens it for editing.
  void _choose(String choice) {
    final items = ref.read(itemsInScopeTodayProvider);
    final existing = items.where((i) => choice == _simranChoice
        ? i.itemType == ItemType.simran
        : i.itemType == ItemType.bani && i.baniId == choice).firstOrNull;
    setState(() {
      _error = null;
      if (existing != null) {
        _loadFrom(existing);
      } else {
        _editing = null;
        _choice = choice;
      }
    });
  }

  String? get _reminder => _remind
      ? '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'
      : null;

  Future<void> _pickMinutes(L l) async {
    final controller = TextEditingController(text: '$_minutes');
    final chosen = await showDialog<int>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.goalMinutesLabel),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(), child: Text(l.actionCancel)),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(int.tryParse(controller.text.trim()) ?? -1),
            child: Text(l.actionDone),
          ),
        ],
      ),
    );
    controller.dispose();
    if (chosen == null || !mounted) return;
    if (chosen < GoalConstants.simranGoalMinutesMin || chosen > GoalConstants.simranGoalMinutesMax) {
      setState(() => _error = l.goalValidationMinutes);
      return;
    }
    setState(() {
      _error = null;
      _minutes = chosen;
    });
  }

  Future<void> _save(L l) async {
    final choice = _choice;
    if (choice == null) return;
    final repo = ref.read(userRepositoryProvider);
    final untilKey = _until == null ? null : localDateKey(_until!);
    try {
      final e = _editing;
      if (e == null) {
        await repo.addItem(_isSimran
            ? GoalItemSpec.simran(
                _minutes,
                durationType: _duration,
                durationDays: _days,
                untilDate: untilKey,
                reminderTime: _reminder,
              )
            : GoalItemSpec.bani(
                choice,
                timesPerDay: _times,
                durationType: _duration,
                durationDays: _days,
                untilDate: untilKey,
                reminderTime: _reminder,
              ));
      } else {
        // §5.7: whatever changed, through the operation for it.
        if (e.reminderTime != _reminder) await repo.editReminder(e.id, _reminder);
        final durationChanged = e.durationType != _duration ||
            (_duration == DurationType.days && e.durationDays != _days) ||
            (_duration == DurationType.untilDate && e.endDate != untilKey);
        if (durationChanged) {
          await repo.editDuration(e.id, type: _duration, durationDays: _days, untilDate: untilKey);
        }
        final targetChanged = _isSimran ? e.simranMinutes != _minutes : e.timesPerDay != _times;
        if (targetChanged) {
          await repo.editTarget(
            e.id,
            timesPerDay: _isSimran ? null : _times,
            simranMinutes: _isSimran ? _minutes : null,
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } on GoalRuleException catch (err) {
      setState(() => _error = err.rule == 'GI6' || err.rule == 'GI4' ? l.goalEndDateInPast : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final inScope = ref.watch(itemsInScopeTodayProvider);
    final shown = _showAllBanis ? banis : banis.where((b) => _featured.contains(b.id)).toList();
    final selected = banis.where((b) => b.id == _choice).firstOrNull;
    final editingName = _isSimran ? l.goalNaamSimran : selected?.name(l.localeName);

    bool inGoal(String choice) => inScope.any((i) => choice == _simranChoice
        ? i.itemType == ItemType.simran
        : i.baniId == choice);

    Widget chip(String label, bool on, VoidCallback onTap, {String? badge}) => HazriChip(
          label: badge == null ? label : '$label · $badge',
          background: on ? c.kesriSoft : c.card2,
          foreground: on ? c.kesriInk : c.ink2,
          minHeight: 40,
          onTap: onTap,
        );

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: HazriSize.gutter,
          right: HazriSize.gutter,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: c.rule, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              _editing != null && editingName != null ? l.goalEditTitle(editingName) : l.goalAddTitle,
              style: HazriText.display22.copyWith(color: c.ink),
            ),
            // Design 47's subtitle.
            Text(l.goalSimranOrBani, style: HazriText.caption.copyWith(color: c.muted, fontSize: 13)),
            const SizedBox(height: 16),
            if (_editing == null) ...[
              Eyebrow(l.goalChoose),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in shown)
                    chip(b.name(l.localeName), _choice == b.id, () => _choose(b.id),
                        badge: inGoal(b.id) ? l.goalInGoalBadge : null),
                  if (!_showAllBanis)
                    chip(l.goalMoreBanis, false, () => setState(() => _showAllBanis = true)),
                  chip(l.goalNaamSimran, _isSimran, () => _choose(_simranChoice),
                      badge: inGoal(_simranChoice) ? l.goalInGoalBadge : null),
                ],
              ),
              const SizedBox(height: 18),
            ],
            if (_isSimran) ...[
              Eyebrow(l.goalMinutesLabel),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in GoalConstants.simranGoalMinutesPresets)
                    chip(l.goalSimranMinutes(m), _minutes == m, () => setState(() => _minutes = m)),
                  chip(
                    GoalConstants.simranGoalMinutesPresets.contains(_minutes)
                        ? l.goalCustom
                        : l.goalSimranMinutes(_minutes),
                    !GoalConstants.simranGoalMinutesPresets.contains(_minutes),
                    () => _pickMinutes(l),
                  ),
                ],
              ),
            ] else if (_choice != null) ...[
              Eyebrow(l.goalTimesPerDay),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StepperButton(
                    label: '−',
                    onTap: _times > GoalConstants.timesPerDayMin ? () => setState(() => _times--) : null,
                  ),
                  Expanded(
                    child: Center(
                      child: Text('$_times', style: HazriText.display22.copyWith(color: c.ink)),
                    ),
                  ),
                  _StepperButton(
                    label: '+',
                    onTap: _times < GoalConstants.timesPerDayMax ? () => setState(() => _times++) : null,
                  ),
                ],
              ),
            ],
            if (_choice != null) ...[
              const SizedBox(height: 18),
              Eyebrow(l.goalDuration),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  chip(l.goalDurationEveryDay, _duration == DurationType.everyDay,
                      () => setState(() => _duration = DurationType.everyDay)),
                  chip(l.goalDurationDays(_days), _duration == DurationType.days,
                      () => setState(() => _duration = DurationType.days)),
                  chip(
                    _until == null
                        ? l.goalDurationUntil('…')
                        : l.goalDurationUntil(dates.shortDate(_until!)),
                    _duration == DurationType.untilDate,
                    () async {
                      final today = ref.read(clockProvider).today();
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: today,
                        lastDate: today.add(const Duration(days: GoalConstants.untilDateMaxAheadDays)),
                        initialDate: _until ?? today.add(const Duration(days: 40)),
                      );
                      if (picked != null) {
                        setState(() {
                          _duration = DurationType.untilDate;
                          _until = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              if (_duration == DurationType.days) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StepperButton(
                      label: '−',
                      onTap: _days > GoalConstants.durationDaysMin ? () => setState(() => _days--) : null,
                    ),
                    Expanded(
                      child: Center(
                        child: Text('$_days', style: HazriText.display22.copyWith(color: c.ink)),
                      ),
                    ),
                    _StepperButton(
                      label: '+',
                      onTap: _days < GoalConstants.durationDaysMax ? () => setState(() => _days++) : null,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              // Design 47: the reminder as a card row with its bell.
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                decoration: BoxDecoration(
                  color: c.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.rule),
                ),
                child: Row(
                children: [
                  AppIcon(HazriIconData.bell, size: 20, color: c.kesriInk),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.goalReminder, style: HazriText.bodyStrong.copyWith(color: c.ink, fontSize: 14)),
                        if (_remind)
                          Text(
                            l.goalReminderEveryDayAt(dates.time(DateTime(2000, 1, 1, _time.hour, _time.minute))),
                            style: HazriText.caption.copyWith(color: c.muted),
                          ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _remind,
                    onChanged: (v) => setState(() {
                      _remind = v;
                      // RM1: 19:30 pre-filled when switched on.
                      if (v && _editing?.reminderTime == null) {
                        _time = const TimeOfDay(hour: 19, minute: 30);
                      }
                    }),
                  ),
                ],
              ),
              ),
              if (_remind) ...[
                const SizedBox(height: 8),
                TimeWheel(value: _time, onChanged: (v) => setState(() => _time = v)),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: HazriText.bodySmall.copyWith(color: c.kesriInk)),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: _editing == null ? l.goalSave : l.goalEditSave,
              onPressed: _choice == null ? null : () => _save(l),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HazriRadius.chip),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(HazriRadius.chip)),
        child: Center(
          child: Text(label, style: HazriText.display22.copyWith(color: onTap == null ? c.muted : c.ink)),
        ),
      ),
    );
  }
}
