import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/group_repository.dart';
import '../domain/sangat_group.dart';

/// Design 42 — adding what you did to the group's count.
///
/// It only ever writes your own row. The rules refuse anything else, which is
/// what stops one member inflating a neighbour's total or the group's.
Future<void> showLogPaathSheet(BuildContext context, SangatGroup group) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogPaathSheet(group: group),
    );

class _LogPaathSheet extends ConsumerStatefulWidget {
  const _LogPaathSheet({required this.group});

  final SangatGroup group;

  @override
  ConsumerState<_LogPaathSheet> createState() => _LogPaathSheetState();
}

class _LogPaathSheetState extends ConsumerState<_LogPaathSheet> {
  /// A circle counts minutes, where 1 is a silly default; a family counts
  /// paath, where anything but 1 usually is.
  late int _amount = widget.group.countsMinutes ? 11 : 1;
  bool _busy = false;

  Future<void> _add() async {
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);

    final outcome =
        await ref.read(groupRepositoryProvider).logPaath(widget.group.id, _amount);
    if (!mounted) return;

    final words = switch (outcome) {
      GroupOk() => l.groupLogged,
      GroupNotFound() => l.groupGone,
      GroupUnavailable() => l.sangatUnavailable,
      GroupRefused() => l.sangatRefused,
      GroupFailed() => l.sangatUnavailable,
    };
    messenger.showSnackBar(SnackBar(content: Text(words)));
    if (outcome is GroupOk) {
      navigator.pop();
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final group = widget.group;
    final unit = group.countsMinutes ? l.unitMinutes : l.unitPaath;
    final step = group.countsMinutes ? 5 : 1;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.rule,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.groupLogTitle, style: HazriText.display22.copyWith(color: c.ink)),
            const SizedBox(height: 4),
            Text(
              group.goal == null
                  ? group.name
                  : '${group.name} · ${group.goal!.target} ${_goalName(l, group)}',
              textAlign: TextAlign.center,
              style: HazriText.caption.copyWith(color: c.muted),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CardIconButton(
                  icon: HazriIconData.close,
                  tooltip: l.actionRemove,
                  onPressed: _amount <= step
                      ? null
                      : () => setState(() => _amount -= step),
                ),
                SizedBox(
                  width: 130,
                  child: Column(
                    children: [
                      Text('$_amount',
                          style: HazriText.display34.copyWith(color: c.ink)),
                      Text(unit, style: HazriText.caption.copyWith(color: c.muted)),
                    ],
                  ),
                ),
                CardIconButton(
                  icon: HazriIconData.sparkle,
                  tooltip: l.actionShowMore,
                  onPressed: () => setState(() => _amount += step),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: l.groupLogAdd,
              onPressed: _busy ? null : _add,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.actionCancel,
                  style: HazriText.captionStrong.copyWith(color: c.muted)),
            ),
          ],
        ),
      ),
    );
  }

  /// What the goal is in, for the line under the title. A circle's goal is
  /// minutes; everything else names its bani through the content database, so
  /// the slug is shown only until that lookup exists here.
  String _goalName(L l, SangatGroup group) =>
      group.countsMinutes ? l.unitMinutes : l.unitPaath;
}
