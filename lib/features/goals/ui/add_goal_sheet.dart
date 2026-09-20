import 'package:drift/drift.dart' show Value;
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
import '../../../core/widgets/surfaces.dart';
import '../../nitnem/domain/bani.dart';
import '../../reminders/ui/time_wheel.dart';
import '../data/goals_controller.dart';

/// Add a paath goal (Design 20).
Future<void> showAddGoalSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const _AddGoalSheet(),
);

class _AddGoalSheet extends ConsumerStatefulWidget {
  const _AddGoalSheet();

  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  String? _baniId;
  int _times = 1;
  GoalDuration _duration = GoalDuration.everyDay;
  int _days = 40;
  DateTime? _until;
  bool _remind = true;
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 30);
  bool _showAllBanis = false;

  /// Minutes a sitting lasts, when the goal is Naam Simran.
  int _minutes = 11;

  bool get _isSimran => _baniId == kSimranGoalId;

  /// The five banis the design offers first, before "More…".
  static const _featured = ['JAPJ', 'CHAU', 'SUKH', 'ANND', 'REHR'];

  /// The lengths design 47 offers, before Custom.
  static const _lengths = [5, 11, 21, 31];

  /// Design 47's "Custom" length. A plain number, because a sitting is
  /// however long somebody has, not one of four blessed values.
  Future<void> _pickMinutes() async {
    final controller = TextEditingController(text: '$_minutes');
    final chosen = await showDialog<int>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(L.of(dialog).goalHowLong),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: Text(L.of(dialog).actionCancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialog).pop(int.tryParse(controller.text.trim())),
            child: Text(L.of(dialog).actionDone),
          ),
        ],
      ),
    );
    controller.dispose();
    if (chosen != null && chosen > 0 && mounted) {
      setState(() => _minutes = chosen.clamp(1, 300));
    }
  }

  Future<void> _save() async {
    final baniId = _baniId;
    if (baniId == null) return;
    final now = DateTime.now().toUtc();
    final today = ref.read(clockProvider).today();

    await ref.read(userRepositoryProvider).saveGoal(
          GoalsCompanion.insert(
            id: UserRepository.newId(),
            baniId: baniId,
            minutes: Value(_isSimran ? _minutes : null),
            timesPerDay: Value(_isSimran ? 1 : _times),
            durationType: _duration,
            days: Value(_duration == GoalDuration.days ? _days : null),
            untilDate: Value(
              _duration == GoalDuration.until && _until != null
                  ? localDateKey(_until!)
                  : null,
            ),
            startDate: localDateKey(today),
            reminderTime: Value(
              _remind
                  ? '${_time.hour.toString().padLeft(2, '0')}:'
                      '${_time.minute.toString().padLeft(2, '0')}'
                  : null,
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );
    ref.invalidate(goalProgressProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final shown = _showAllBanis
        ? banis
        : banis.where((b) => _featured.contains(b.id)).toList();
    final selected = banis.where((b) => b.id == _baniId).firstOrNull;

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
                decoration: BoxDecoration(
                  color: c.rule,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(l.goalsAdd, style: HazriText.display22.copyWith(color: c.ink)),
            const SizedBox(height: 16),
            Text(l.goalSimranOrBani, style: HazriText.bodySmall.copyWith(color: c.muted)),
            const SizedBox(height: 14),
            Text(l.goalFieldBani, style: HazriText.bodyStrong.copyWith(color: c.ink)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Naam Simran first, as design 47 has it. It is the shortest
                // thing somebody can promise themselves and the likeliest
                // first goal, so it should not be behind "More…".
                HazriChip(
                  label: l.hazriSimran,
                  background: _isSimran ? c.kesriSoft : c.card2,
                  foreground: _isSimran ? c.kesriInk : c.ink2,
                  minHeight: 40,
                  onTap: () => setState(() => _baniId = kSimranGoalId),
                ),
                for (final b in shown)
                  HazriChip(
                    label: b.name(l.localeName),
                    background: _baniId == b.id ? c.kesriSoft : c.card2,
                    foreground: _baniId == b.id ? c.kesriInk : c.ink2,
                    minHeight: 40,
                    onTap: () => setState(() => _baniId = b.id),
                  ),
                if (!_showAllBanis)
                  HazriChip(
                    label: l.goalMoreBanis,
                    minHeight: 40,
                    onTap: () => setState(() => _showAllBanis = true),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (_isSimran) ...[
              Text(l.goalHowLong, style: HazriText.bodyStrong.copyWith(color: c.ink)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in _lengths)
                    HazriChip(
                      label: l.minutes(m),
                      background: _minutes == m ? c.kesriSoft : c.card2,
                      foreground: _minutes == m ? c.kesriInk : c.ink2,
                      minHeight: 40,
                      onTap: () => setState(() => _minutes = m),
                    ),
                  HazriChip(
                    label: l.goalCustomMinutes,
                    background: _lengths.contains(_minutes) ? c.card2 : c.kesriSoft,
                    foreground: _lengths.contains(_minutes) ? c.ink2 : c.kesriInk,
                    minHeight: 40,
                    onTap: _pickMinutes,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(l.goalSimranLoops,
                  style: HazriText.caption.copyWith(color: c.muted)),
            ] else ...[
            Text(l.goalFieldTimes, style: HazriText.bodyStrong.copyWith(color: c.ink)),
            const SizedBox(height: 8),
            Row(
              children: [
                _StepperButton(
                  label: '−',
                  onTap: _times > 1 ? () => setState(() => _times--) : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$_times',
                      style: HazriText.display22.copyWith(color: c.ink),
                    ),
                  ),
                ),
                _StepperButton(
                  label: '+',
                  onTap: _times < 21 ? () => setState(() => _times++) : null,
                ),
              ],
            ),
            if (selected != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l.goalFieldTimesHint(selected.estMinutes),
                  style: HazriText.caption.copyWith(color: c.muted),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(l.goalFieldDuration, style: HazriText.bodyStrong.copyWith(color: c.ink)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                HazriChip(
                  label: l.goalDurationEveryDay,
                  minHeight: 40,
                  background: _duration == GoalDuration.everyDay ? c.kesriSoft : c.card2,
                  foreground: _duration == GoalDuration.everyDay ? c.kesriInk : c.ink2,
                  onTap: () => setState(() => _duration = GoalDuration.everyDay),
                ),
                HazriChip(
                  label: l.goalDuration40Days,
                  minHeight: 40,
                  background: _duration == GoalDuration.days ? c.kesriSoft : c.card2,
                  foreground: _duration == GoalDuration.days ? c.kesriInk : c.ink2,
                  onTap: () => setState(() {
                    _duration = GoalDuration.days;
                    _days = 40;
                  }),
                ),
                HazriChip(
                  label: _until == null
                      ? l.goalDurationUntilDate
                      : l.goalRuleUntil(dates.shortDate(_until!)),
                  minHeight: 40,
                  background: _duration == GoalDuration.until ? c.kesriSoft : c.card2,
                  foreground: _duration == GoalDuration.until ? c.kesriInk : c.ink2,
                  onTap: () async {
                    final today = ref.read(clockProvider).today();
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 365 * 2)),
                      initialDate: _until ?? today.add(const Duration(days: 40)),
                    );
                    if (picked != null) {
                      setState(() {
                        _duration = GoalDuration.until;
                        _until = picked;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.goalFieldReminder,
                    style: HazriText.bodyStrong.copyWith(color: c.ink),
                  ),
                ),
                Switch(value: _remind, onChanged: (v) => setState(() => _remind = v)),
              ],
            ),
            if (_remind) ...[
              const SizedBox(height: 8),
              TimeWheel(value: _time, onChanged: (v) => setState(() => _time = v)),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: l.goalSave,
              onPressed: _baniId == null ? null : _save,
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
        decoration: BoxDecoration(
          color: c.card2,
          borderRadius: BorderRadius.circular(HazriRadius.chip),
        ),
        child: Center(
          child: Text(
            label,
            style: HazriText.display22.copyWith(
              color: onTap == null ? c.muted : c.ink,
            ),
          ),
        ),
      ),
    );
  }
}
