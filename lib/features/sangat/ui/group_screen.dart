import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/group_repository.dart';
import '../domain/sangat_group.dart';
import 'log_paath_sheet.dart';
import 'sangat_screen.dart' show groupKindLabel, groupProgressLine;

/// Designs 31 and 42 — one group: its shared goal, what you have done, and
/// who else is doing it.
///
/// The two bars are the point of the screen. YOU and THE GROUP are drawn to
/// the same scale, so a family of six can see at a glance that one person is
/// carrying it — which is information the group wants, not a scoreboard.
class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final group = ref.watch(groupProvider(groupId)).value;
    final members = ref.watch(groupMembersProvider(groupId)).value ?? const <GroupMember>[];

    if (group == null) {
      return HazriScreen(
        title: l.sangatTitle,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Text(l.groupGone, style: HazriText.body.copyWith(color: c.muted)),
          ),
        ],
      );
    }

    final goal = group.goal;
    final numbers = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());

    return HazriScreen(
      title: group.name,
      subtitle: '${l.groupMembers(group.memberCount)} · ${groupKindLabel(l, group.kind)}',
      children: [
        const SizedBox(height: 6),
        HazriCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProgressRing(
                    progress: group.progress ?? 0,
                    size: 54,
                    strokeWidth: 5,
                    child: Text(
                      numbers.format(group.total),
                      style: HazriText.captionStrong.copyWith(color: c.ink),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.groupSharedGoal,
                            style: HazriText.captionStrong.copyWith(color: c.muted)),
                        Text(
                          groupProgressLine(context, group),
                          style: HazriText.bodyStrong.copyWith(color: c.ink),
                        ),
                        if (goal?.occasion != null)
                          Text(goal!.occasion!,
                              style: HazriText.caption.copyWith(color: c.muted)),
                      ],
                    ),
                  ),
                  if (group.youAreAdmin)
                    CardIconButton(
                      icon: HazriIconData.sliders,
                      tooltip: l.groupSetGoalTitle,
                      size: 38,
                      iconSize: 18,
                      onPressed: () => context.push(Routes.groupGoal(groupId)),
                    ),
                ],
              ),
              if (goal != null) ...[
                const SizedBox(height: 14),
                _Bar(
                  label: l.groupYou,
                  value: group.yours,
                  outOf: goal.target,
                  colour: c.kesri,
                ),
                const SizedBox(height: 8),
                _Bar(
                  label: l.groupTheGroup,
                  value: group.total,
                  outOf: goal.target,
                  colour: c.sage,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (goal != null && !group.countsMinutes)
              Expanded(
                child: PrimaryButton(
                  label: l.groupStartPaath,
                  onPressed: () => context.push(Routes.reader(goal.slug)),
                ),
              ),
            if (goal != null && !group.countsMinutes) const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: l.groupLogPaath,
                secondary: true,
                onPressed: () => showLogPaathSheet(context, group),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Eyebrow(l.groupMembersTitle)),
            HazriChip(
              label: l.groupInvite,
              background: c.card2,
              foreground: c.ink2,
              onTap: () => context.push(Routes.groupInvite(groupId)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        HazriCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              for (var i = 0; i < members.length; i++) ...[
                _MemberRow(
                  member: members[i],
                  countsMinutes: group.countsMinutes,
                ),
                if (i != members.length - 1) Divider(height: 1, color: c.rule),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: () => _confirmLeave(context, ref, l),
            child: Text(l.groupLeave,
                style: HazriText.captionStrong.copyWith(color: c.muted)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref, L l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.groupLeave),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l.groupLeave),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(groupRepositoryProvider).leave(groupId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.groupLeft)));
    if (context.canPop()) context.pop();
  }
}

/// One of the two bars. Both are drawn against the goal, never against each
/// other, so YOU never appears to be most of the group's work.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.outOf,
    required this.colour,
  });

  final String label;
  final int value;
  final int outOf;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fraction = outOf <= 0 ? 0.0 : (value / outOf).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: HazriText.eyebrow.copyWith(color: c.muted)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: c.card2,
              valueColor: AlwaysStoppedAnimation(colour),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$value', style: HazriText.captionStrong.copyWith(color: c.ink)),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.countsMinutes});

  final GroupMember member;
  final bool countsMinutes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    // Somebody who turned their name off is "a member", not a blank line and
    // not a name we went and found anyway.
    final name = member.name.isEmpty ? l.groupAnonMember : member.name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: c.card2, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: HazriText.caption.copyWith(color: c.ink2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: HazriText.bodyStrong.copyWith(color: c.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (member.isAdmin) ...[
            HazriChip(
              label: l.groupAdmin,
              background: c.card2,
              foreground: c.muted,
              minHeight: 26,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '${member.count} ${countsMinutes ? l.unitMinutes : l.unitPaath}',
            style: HazriText.caption.copyWith(color: c.ink2),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    String first(String w) => String.fromCharCodes(w.runes.take(1));
    if (words.length == 1) return first(words.first).toUpperCase();
    return (first(words.first) + first(words.last)).toUpperCase();
  }
}
