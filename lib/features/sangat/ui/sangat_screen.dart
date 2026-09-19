import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/account_repository.dart';
import '../data/group_repository.dart';
import '../domain/sangat_group.dart';
import 'join_sangat_sheet.dart';

/// Design 38 — the Sangat tab.
///
/// Three states, and the first is the common one: somebody who has not joined
/// sees what the sangat is and the way in, not an empty list. Nothing on this
/// screen is reachable without an account, which is the opt-in rule kept
/// honest at the tab rather than argued about in each card.
class SangatScreen extends ConsumerWidget {
  const SangatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final joined = ref.watch(hasJoinedSangatProvider);

    if (!joined) return _NotJoined(l: l);

    final mine = ref.watch(myGroupsProvider).value ?? const <SangatGroup>[];
    final listed = ref.watch(listedGroupsProvider).value ?? const <SangatGroup>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 14, HazriSize.gutter, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l.sangatTitle,
                  style: HazriText.display26.copyWith(color: c.ink)),
            ),
            HazriChip(
              label: l.sangatCreateOrJoin,
              icon: HazriIconData.sangat,
              background: c.kesriSoft,
              foreground: c.kesriInk,
              onTap: () => context.push(Routes.createGroup),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // The globe lives on Simran; this is the door to it, not a second
        // copy of it.
        HazriCard(
          colour: c.card2,
          onTap: () => context.go(Routes.simran),
          child: Row(
            children: [
              AppIcon(HazriIconData.globe, size: 22, color: c.teal),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l.sangatWorldwide,
                    style: HazriText.bodyStrong.copyWith(color: c.ink)),
              ),
              AppIcon(HazriIconData.chevronRight, size: 18, color: c.muted),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Eyebrow(l.sangatYourGroups),
        const SizedBox(height: 8),
        if (mine.isEmpty)
          HazriCard(
            child: Text(l.sangatNoGroupsYet,
                style: HazriText.bodySmall.copyWith(color: c.ink2)),
          )
        else
          for (final group in mine) ...[
            _MyGroupCard(group: group),
            const SizedBox(height: 10),
          ],
        if (listed.isNotEmpty) ...[
          const SizedBox(height: 10),
          Eyebrow(l.sangatCanJoin),
          const SizedBox(height: 8),
          HazriCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (var i = 0; i < listed.length; i++) ...[
                  _ListedGroupRow(group: listed[i]),
                  if (i != listed.length - 1) Divider(height: 1, color: c.rule),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => context.push(Routes.joinByLink),
            child: Text(l.sangatHaveLink,
                style: HazriText.captionStrong.copyWith(color: c.muted)),
          ),
        ),
      ],
    );
  }
}

/// What somebody who never joined sees on this tab: the offer, not a wall.
class _NotJoined extends StatelessWidget {
  const _NotJoined({required this.l});

  final L l;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 28, HazriSize.gutter, 24),
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: c.kesriSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppIcon(HazriIconData.sangat, size: 38, color: c.kesriInk),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l.sangatNotJoinedTitle,
          textAlign: TextAlign.center,
          style: HazriText.display22.copyWith(color: c.ink),
        ),
        const SizedBox(height: 10),
        Text(
          l.sangatSheetBody,
          textAlign: TextAlign.center,
          style: HazriText.body.copyWith(color: c.ink2),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: l.sangatBannerCta,
          onPressed: () => showJoinSangatSheet(context),
        ),
        const SizedBox(height: 14),
        Text(
          l.sangatNoAds,
          textAlign: TextAlign.center,
          style: HazriText.caption.copyWith(color: c.muted),
        ),
      ],
    );
  }
}

class _MyGroupCard extends StatelessWidget {
  const _MyGroupCard({required this.group});

  final SangatGroup group;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final percent = group.percent;

    return HazriCard(
      onTap: () => context.push(Routes.group(group.id)),
      child: Row(
        children: [
          ProgressRing(
            progress: group.progress ?? 0,
            size: 46,
            strokeWidth: 4,
            child: Text(
              percent == null ? '—' : '$percent%',
              style: HazriText.caption.copyWith(color: c.ink, fontSize: 11),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name,
                    style: HazriText.bodyStrong.copyWith(color: c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  '${groupKindLabel(l, group.kind)} · ${l.groupMembers(group.memberCount)}',
                  style: HazriText.caption.copyWith(color: c.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  groupProgressLine(context, group),
                  style: HazriText.caption.copyWith(color: c.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListedGroupRow extends ConsumerStatefulWidget {
  const _ListedGroupRow({required this.group});

  final SangatGroup group;

  @override
  ConsumerState<_ListedGroupRow> createState() => _ListedGroupRowState();
}

class _ListedGroupRowState extends ConsumerState<_ListedGroupRow> {
  bool _busy = false;

  Future<void> _join() async {
    final l = L.of(context);
    setState(() => _busy = true);
    final outcome = await ref.read(groupRepositoryProvider).join(widget.group.id);
    if (!mounted) return;
    setState(() => _busy = false);
    final words = switch (outcome) {
      GroupOk() => null,
      GroupNotFound() => l.groupGone,
      GroupUnavailable() => l.sangatUnavailable,
      GroupRefused() => l.sangatRefused,
      GroupFailed() => l.sangatUnavailable,
    };
    if (words != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(words)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final g = widget.group;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.name,
                    style: HazriText.bodyStrong.copyWith(color: c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  '${groupKindLabel(l, g.kind)} · ${l.groupMembers(g.memberCount)}',
                  style: HazriText.caption.copyWith(color: c.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          HazriChip(
            label: l.sangatJoinGroup,
            background: c.card2,
            foreground: c.ink2,
            onTap: _busy ? null : _join,
          ),
        ],
      ),
    );
  }
}

/// The group's kind in the reader's language.
String groupKindLabel(L l, GroupKind kind) => switch (kind) {
      GroupKind.family => l.groupKindFamily,
      GroupKind.sangat => l.groupKindSangat,
      GroupKind.circle => l.groupKindCircle,
    };

/// "68 of 101 Sukhmani Sahib", "255 of 300 minutes", or the no-goal line.
///
/// The unit is the bani's own name where the goal names one, because "68 of
/// 101 paath" says less than the group knows.
String groupProgressLine(BuildContext context, SangatGroup group) {
  final l = L.of(context);
  final goal = group.goal;
  if (goal == null) return l.groupNoGoalYet;
  final numbers = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
  final unit = group.countsMinutes ? l.unitMinutes : l.unitPaath;
  return l.groupProgress(
    numbers.format(group.total),
    numbers.format(goal.target),
    unit,
  );
}
