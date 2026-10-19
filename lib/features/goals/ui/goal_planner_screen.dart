import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../audio/data/notification_access.dart';
import '../../nitnem/domain/bani.dart';
import '../../reminders/ui/exact_alarm_card.dart';
import '../../reminders/ui/time_wheel.dart';
import '../data/goals_controller.dart';
import '../domain/goal_constants.dart';

/// What a row stands for: a bani id, or Naam Simran.
const _simran = '__simran__';

/// The goal as one page (04-goals §7.2, design 106, option C of 2026-10-19):
/// the day as a timeline, every bani and Naam Simran at its own time. Tap a
/// paath to add it, tap again to take it out, tap its time to move the
/// reminder; nothing is written until Start or Save. Every paath is read once
/// a day (GI10) and every reminder is on (RM1).
class GoalPlannerScreen extends ConsumerStatefulWidget {
  const GoalPlannerScreen({super.key});

  @override
  ConsumerState<GoalPlannerScreen> createState() => _GoalPlannerScreenState();
}

class _GoalPlannerScreenState extends ConsumerState<GoalPlannerScreen> {
  /// Chosen paaths and their reminder times, `HH:mm`.
  final _chosen = <String, String>{};
  int _minutes = GoalConstants.simranGoalMinutesDefault;
  DurationType _duration = DurationType.everyDay;
  int _days = GoalConstants.durationDaysPreset;
  DateTime? _until;
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  List<GoalItem> get _inScope => ref.read(itemsInScopeTodayProvider);

  /// Starts from the goal as it stands today.
  void _load(List<GoalItem> items) {
    _loaded = true;
    for (final i in items) {
      final key = i.itemType == ItemType.simran ? _simran : i.baniId!;
      _chosen[key] = i.reminderTime ?? _defaultTime(key);
      if (i.itemType == ItemType.simran) _minutes = i.simranMinutes ?? _minutes;
    }
    final first = items.firstOrNull;
    if (first != null) {
      _duration = first.durationType;
      _days = first.durationDays ?? _days;
      if (first.durationType == DurationType.untilDate && first.endDate != null) {
        _until = parseLocalDateKey(first.endDate!);
      }
    }
  }

  static String _defaultTime(String key) =>
      key == _simran ? GoalConstants.simranReminderDefault : GoalConstants.reminderFor(baniId: key);

  static int _minuteOfDay(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static TimeOfDay _tod(String hhmm) {
    final m = _minuteOfDay(hhmm);
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

  static String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String? get _untilKey => _until == null ? null : localDateKey(_until!);

  bool _sameDuration(GoalItem e) =>
      e.durationType == _duration &&
      (_duration != DurationType.days || e.durationDays == _days) &&
      (_duration != DurationType.untilDate || e.endDate == _untilKey);

  Future<void> _pickTime(String key, String name) async {
    final l = L.of(context);
    var value = _tod(_chosen[key]!);
    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      useSafeArea: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 16, HazriSize.gutter, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(name, style: HazriText.display22.copyWith(color: sheet.colors.ink)),
              Text(l.goalPlanChangeTime, style: HazriText.caption.copyWith(color: sheet.colors.muted)),
              const SizedBox(height: 12),
              TimeWheel(value: value, onChanged: (v) => setSheet(() => value = v)),
              // DP2: a reminder time is what exact alarms are for.
              const ExactAlarmCard(padding: EdgeInsets.only(top: 10)),
              const SizedBox(height: 16),
              PrimaryButton(label: l.actionDone, onPressed: () => Navigator.of(sheet).pop(value)),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _chosen[key] = _hhmm(picked));
  }

  Future<void> _pickMinutes() async {
    final l = L.of(context);
    final picked = await showDialog<int>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(l.goalMinutesLabel),
        children: [
          for (final m in GoalConstants.simranGoalMinutesPresets)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialog).pop(m),
              child: Text(l.goalSimranMinutes(m),
                  style: HazriText.body.copyWith(fontWeight: m == _minutes ? FontWeight.w700 : null)),
            ),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _minutes = picked);
  }

  Future<void> _pickUntil() async {
    final today = ref.read(clockProvider).today();
    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: GoalConstants.untilDateMaxAheadDays)),
      initialDate: _until ?? today.add(const Duration(days: GoalConstants.durationDaysPreset)),
    );
    if (picked != null && mounted) {
      setState(() {
        _duration = DurationType.untilDate;
        _until = picked;
      });
    }
  }

  /// §5.7: new paaths first, then changes, then what was taken out, so a
  /// goal that is being changed never passes through empty (BG1).
  Future<void> _save(Map<String, String> names) async {
    final l = L.of(context);
    final repo = ref.read(userRepositoryProvider);
    final existing = _inScope;
    String keyOf(GoalItem i) => i.itemType == ItemType.simran ? _simran : i.baniId!;
    final out = existing.where((i) => !_chosen.containsKey(keyOf(i))).toList();
    if (out.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l.goalRemoveConfirmTitle(out.map((i) => names[keyOf(i)] ?? '').join(', '))),
          content: Text(l.goalRemoveConfirmBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(l.actionCancel)),
            TextButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(l.goalRemove)),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final days = _duration == DurationType.days ? _days : null;
      for (final entry in _chosen.entries) {
        final e = existing.where((i) => keyOf(i) == entry.key).firstOrNull;
        if (e == null) {
          await repo.addItem(entry.key == _simran
              ? GoalItemSpec.simran(_minutes,
                  durationType: _duration, durationDays: days, untilDate: _untilKey, reminderTime: entry.value)
              : GoalItemSpec.bani(entry.key,
                  durationType: _duration, durationDays: days, untilDate: _untilKey, reminderTime: entry.value));
          continue;
        }
        if (e.reminderTime != entry.value) await repo.editReminder(e.id, entry.value);
        if (!_sameDuration(e)) {
          await repo.editDuration(e.id, type: _duration, durationDays: days, untilDate: _untilKey);
        }
        if (e.itemType == ItemType.simran && e.simranMinutes != _minutes) {
          await repo.editTarget(e.id, simranMinutes: _minutes);
        } else if (e.itemType == ItemType.bani && e.timesPerDay != 1) {
          await repo.editTarget(e.id, timesPerDay: 1);
        }
      }
      for (final i in out) {
        await repo.removeItem(i.id);
      }
      if (mounted) context.canPop() ? context.pop() : context.go(Routes.goals);
    } on GoalRuleException catch (err) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = err.rule == 'GI6' || err.rule == 'GI4' ? l.goalEndDateInPast : null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final items = ref.watch(itemsInScopeTodayProvider);
    final rowsReady = ref.watch(todayRowsProvider).hasValue;
    if (!_loaded && rowsReady) _load(items);
    final allowed = ref.watch(notificationsAllowedProvider).value ?? true;
    final hasGoal = items.isNotEmpty;

    final names = <String, String>{
      for (final b in banis) b.id: b.name(l.localeName),
      _simran: l.goalNaamSimran,
    };
    final keys = [for (final b in banis) b.id, _simran];
    String timeOf(String k) => _chosen[k] ?? _defaultTime(k);
    keys.sort((a, b) => _minuteOfDay(timeOf(a)).compareTo(_minuteOfDay(timeOf(b))));

    String band(String k) {
      final m = _minuteOfDay(timeOf(k));
      if (m < 6 * 60) return l.goalPlanAmritVela;
      if (m < 11 * 60) return l.goalPlanMorning;
      if (m < 17 * 60) return l.goalPlanDaytime;
      return l.goalPlanEvening;
    }

    final rows = <Widget>[];
    String? lastBand;
    for (final k in keys) {
      final b = band(k);
      if (b != lastBand) {
        rows.add(_BandLabel(label: b, night: b == l.goalPlanAmritVela || b == l.goalPlanEvening));
        lastBand = b;
      }
      final bani = banis.where((x) => x.id == k).firstOrNull;
      final time = timeOf(k);
      rows.add(_TimelineRow(
        time: dates.time(DateTime(2000, 1, 1, _minuteOfDay(time) ~/ 60, _minuteOfDay(time) % 60)),
        name: names[k] ?? k,
        native: bani?.nativeName,
        detail: k == _simran ? l.goalSimranMinutes(_minutes) : null,
        chosen: _chosen.containsKey(k),
        onToggle: () => setState(() {
          _error = null;
          _chosen.containsKey(k) ? _chosen.remove(k) : _chosen[k] = _defaultTime(k);
        }),
        onTime: () => _pickTime(k, names[k] ?? k),
        onDetail: k == _simran ? _pickMinutes : null,
      ));
    }

    final count = _chosen.length;
    final changed = !rowsReady
        ? false
        : !(_chosen.length == items.length &&
            items.every((i) {
              final k = i.itemType == ItemType.simran ? _simran : i.baniId!;
              return _chosen[k] == (i.reminderTime ?? _defaultTime(k)) &&
                  _sameDuration(i) &&
                  (i.itemType != ItemType.simran || i.simranMinutes == _minutes) &&
                  i.timesPerDay == 1;
            }));
    final label = count == 0
        ? l.goalEditSave
        : (hasGoal ? l.goalPlanSave(count) : l.goalPlanStart(count));

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.today);
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: PhoneWidth(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: l.actionBack,
                            icon: AppIcon(HazriIconData.chevronLeft, size: 22, color: c.ink),
                            onPressed: () => context.canPop() ? context.pop() : context.go(Routes.today),
                          ),
                          const SizedBox(width: 4),
                          Expanded(child: Text(l.goalPlanTitle, style: HazriText.display22.copyWith(color: c.ink))),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                        child: Text(l.goalPlanIntro, style: HazriText.bodySmall.copyWith(color: c.ink2, height: 1.45)),
                      ),
                      // RM6: a reminder that cannot arrive says so.
                      if (!allowed) ...[
                        const SizedBox(height: 6),
                        HazriCard(
                          colour: c.kesriSoft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.notificationRationale, style: HazriText.body.copyWith(color: c.kesriInk)),
                              const SizedBox(height: 10),
                              PrimaryButton(
                                label: l.actionAllow,
                                onPressed: () => ref.read(notificationsAllowedProvider.notifier).allow(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      ...rows,
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(color: c.kesriSoft, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: AppIcon(HazriIconData.bell, size: 16, color: c.kesri),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(l.goalPlanReminderNote,
                                  style: HazriText.bodySmall.copyWith(color: c.kesriInk, height: 1.45)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // The bar: how long, and the one button.
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(color: c.card, border: Border(top: BorderSide(color: c.rule))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Segments(
                        options: [
                          (l.goalDurationEveryDay, _duration == DurationType.everyDay,
                              () => setState(() => _duration = DurationType.everyDay)),
                          (l.goalDurationDays(_days), _duration == DurationType.days,
                              () => setState(() => _duration = DurationType.days)),
                          (
                            _until == null ? l.goalDurationUntil('…') : l.goalDurationUntil(dates.shortDate(_until!)),
                            _duration == DurationType.untilDate,
                            _pickUntil,
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: HazriText.bodySmall.copyWith(color: c.kesriInk)),
                      ],
                      const SizedBox(height: 10),
                      PrimaryButton(
                        label: label,
                        onPressed: _saving || !changed || (count == 0 && !hasGoal) ? null : () => _save(names),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BandLabel extends StatelessWidget {
  const _BandLabel({required this.label, required this.night});

  final String label;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 16, 0, 8),
      child: Row(
        children: [
          AppIcon(night ? HazriIconData.moon : HazriIconData.sunArc, size: 16, color: night ? c.primary : c.kesri),
          const SizedBox(width: 8),
          Text(label.toUpperCase(), style: HazriText.eyebrow.copyWith(color: c.muted)),
        ],
      ),
    );
  }
}

/// One paath on the day's line: its time, a dot, and a card. A chosen paath
/// is a solid card with its reminder as an orange chip; the rest are dashed.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.time,
    required this.name,
    required this.chosen,
    required this.onToggle,
    required this.onTime,
    this.native,
    this.detail,
    this.onDetail,
  });

  final String time;
  final String name;
  final String? native;
  final String? detail;
  final bool chosen;
  final VoidCallback onToggle;
  final VoidCallback onTime;
  final VoidCallback? onDetail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final card = Semantics(
      button: true,
      toggled: chosen,
      child: chosen
          ? HazriCard(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              onTap: onToggle,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: HazriText.bodyStrong.copyWith(color: c.ink, fontSize: 16)),
                        if (native != null)
                          Text(native!, style: HazriText.gurmukhi(13).copyWith(color: c.ink2, height: 1.4)),
                      ],
                    ),
                  ),
                  if (detail != null) ...[
                    _Chip(label: detail!, onTap: onDetail, tooltip: l.goalMinutesLabel, soft: true),
                    const SizedBox(width: 6),
                  ],
                  _Chip(label: time, onTap: onTime, tooltip: l.goalPlanChangeTime, bell: true),
                ],
              ),
            )
          : CustomPaint(
              foregroundPainter: _Dashed(color: c.muted.withValues(alpha: 0.6), radius: 16),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(detail == null ? name : '$name · $detail',
                              style: HazriText.bodyStrong.copyWith(color: c.ink2, fontSize: 16)),
                        ),
                        AppIcon(HazriIconData.plus, size: 18, color: c.kesri),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Center(
              child: Text(time,
                  textAlign: TextAlign.right,
                  style: HazriText.captionStrong.copyWith(color: c.muted, fontSize: 12)),
            ),
          ),
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(top: 0, bottom: 0, child: Container(width: 2, color: c.rule)),
                if (chosen)
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: c.kesri, shape: BoxShape.circle),
                    child: Center(child: AppIcon(HazriIconData.check, size: 16, color: Colors.white)),
                  )
                else
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: c.bg,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.muted.withValues(alpha: 0.6), width: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: card),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, required this.tooltip, this.bell = false, this.soft = false});

  final String label;
  final VoidCallback? onTap;
  final String tooltip;
  final bool bell;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: soft ? c.card2 : c.kesriSoft,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (bell) ...[
                    AppIcon(HazriIconData.bell, size: 14, color: c.kesriInk),
                    const SizedBox(width: 4),
                  ],
                  Text(label, style: HazriText.captionStrong.copyWith(color: soft ? c.ink2 : c.kesriInk, fontSize: 13)),
                  const SizedBox(width: 2),
                  AppIcon(HazriIconData.chevronDown, size: 12, color: soft ? c.ink2 : c.kesriInk),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.options});

  final List<(String, bool, VoidCallback)> options;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (final (label, on, onTap) in options)
            Expanded(
              child: Semantics(
                selected: on,
                button: true,
                child: Material(
                  color: on ? c.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onTap,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: HazriText.captionStrong.copyWith(color: on ? c.ink : c.ink2, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dashed extends CustomPainter {
  _Dashed({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.75));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Dashed old) => old.color != color;
}
