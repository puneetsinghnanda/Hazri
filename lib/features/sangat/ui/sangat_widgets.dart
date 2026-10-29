import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/surfaces.dart';
import '../../nitnem/domain/bani.dart';
import '../../profile/ui/messages.dart';
import '../data/sangat_api.dart';
import '../domain/sangat_models.dart';

/// "5000 Japji Sahib by 31 Dec" or "100000 minutes of Naam Simran by 31 Dec".
String goalSummary(BuildContext context, WidgetRef ref, SangatGoal g) {
  final l = L.of(context);
  final date = HazriDates.of(context).shortDate(parseLocalDateKey(g.endDay));
  if (g.isSimran) return l.sangatGoalSummarySimran(g.target, date);
  final bani = goalBani(ref, g)?.name(l.localeName) ?? g.baniId ?? '';
  return l.sangatGoalSummaryBani(g.target, bani, date);
}

/// The goal's bani from `content.db`, or null for Naam Simran or while the
/// list is loading. Its name is never typed in Dart (rule 3).
Bani? goalBani(WidgetRef ref, SangatGoal g) {
  if (g.isSimran) return null;
  final banis = ref.watch(banisProvider).value ?? const <Bani>[];
  return banis.where((b) => b.id == g.baniId).firstOrNull;
}

/// A count with the locale's grouping: "212,480", or "2,12,480" in pa/hi.
String formatCount(String locale, int n) {
  try {
    return NumberFormat.decimalPattern(locale).format(n);
  } on Object {
    return NumberFormat.decimalPattern().format(n);
  }
}

/// "3,412 of 5,000", or "212,480 of 500,000 min" for Naam Simran.
String goalTotalOf(L l, SangatGoal g) {
  final total = formatCount(l.localeName, g.total);
  final target = formatCount(l.localeName, g.target);
  return g.isSimran ? l.sangatTotalOfMinutes(total, target) : l.sangatTotalOf(total, target);
}

/// Whether the group or its goal has finished (CG6, BI4).
bool groupEnded(SangatGroup group) {
  final g = group.goal;
  return !group.isActive || (g != null && g.status != 'ACTIVE');
}

/// The goal's state in one line: days left, or the day it ended (VS1, VS3).
String goalWhen(BuildContext context, SangatGroup group) {
  final l = L.of(context);
  final g = group.goal;
  if (!group.isActive || g == null || g.status != 'ACTIVE') {
    final end = group.endedOn ?? g?.endDay;
    return end == null ? '' : l.sangatEndedOn(HazriDates.of(context).shortDate(parseLocalDateKey(end)));
  }
  return l.sangatDaysLeft(g.daysLeft);
}

/// The icon a group is drawn with: people for a group of one's own, and
/// for a built-in group what it counts.
String groupIcon(SangatGroup group) {
  if (!group.isBuiltIn) return HazriIconData.sangat;
  return group.goal?.isSimran ?? false ? HazriIconData.simranDots : HazriIconData.book;
}

/// A small rounded square holding an icon, teal on the second card colour.
class GroupIconTile extends StatelessWidget {
  const GroupIconTile({super.key, required this.icon, this.size = 38, this.radius = 12});

  final String icon;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: AppIcon(icon, size: (size * 0.5).roundToDouble(), color: c.teal),
    );
  }
}

/// Design 102: one of the two tiles at the top of the tab, an icon in a
/// translucent square, a label and the line under it.
class SangatActionTile extends StatelessWidget {
  const SangatActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.sub,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String icon;
  final String label;
  final String sub;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: HazriCard(
        colour: background,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: AppIcon(icon, size: 20, color: foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: HazriText.bodyStrong.copyWith(color: foreground, fontSize: 16, height: 1.3)),
                    Text(
                      sub,
                      style: HazriText.caption.copyWith(
                        color: foreground.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Design 102: a group in the 2 x 2 grid of My groups (VS1). The ring with
/// its percentage, the group's icon (or Ended), the name, total of target
/// and days left. An ended group is muted.
class GroupGridTile extends ConsumerWidget {
  const GroupGridTile({super.key, required this.group, this.onTap});

  final SangatGroup group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final g = group.goal;
    final ended = groupEnded(group);
    final met = g != null && (g.status == 'COMPLETED' || g.pct >= 100);
    final ringColour = met ? c.sage : (ended ? c.muted : c.kesri);
    final line = c.ink2;
    return Opacity(
      opacity: ended ? 0.8 : 1,
      child: HazriCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 102),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressRing(
                    size: 46,
                    strokeWidth: 6,
                    progress: g == null ? 0 : (g.pct / 100).clamp(0.0, 1.0),
                    colour: ringColour,
                    child: g == null
                        ? null
                        : Text(
                            '${g.pct}%',
                            style: HazriText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: c.ink),
                          ),
                  ),
                  const SizedBox(width: 6),
                  if (ended)
                    Flexible(
                      child: HazriChip(
                        label: l.sangatEndedHeading,
                        minHeight: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                    )
                  else
                    GroupIconTile(icon: groupIcon(group), size: 28, radius: 9),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                group.displayName(l.localeName),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: HazriText.bodyStrong.copyWith(color: c.ink, fontSize: 14.5, height: 1.2),
              ),
              const SizedBox(height: 5),
              if (g == null)
                Text(l.sangatNoGoalYet, style: HazriText.caption.copyWith(color: line, height: 1.3))
              else ...[
                Text(
                  goalTotalOf(l, g),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.caption.copyWith(color: line, height: 1.3),
                ),
                Text(
                  goalWhen(context, group),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.caption.copyWith(color: line, height: 1.3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays [children] out two to a row, each row as tall as its taller tile.
class TwoColumnGrid extends StatelessWidget {
  const TwoColumnGrid({super.key, required this.children, this.gap = 10});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: children[i]),
                  SizedBox(width: gap),
                  Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox.shrink()),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Design 102: a built-in group as a full-width row of the Join the sangat
/// card (VS2): its icon, name, goal on one line, member count, and Join, or
/// a green Joined chip once you are in it (design 3E, owner 2026-10-29).
/// Leave is inside the group, in its ⋮ menu, with a confirmation.
class BuiltInGroupRow extends ConsumerWidget {
  const BuiltInGroupRow({
    super.key,
    required this.group,
    required this.busy,
    required this.onToggle,
    this.onTap,
    this.divider = false,
  });

  final SangatGroup group;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final bool divider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final g = group.goal;
    final small = HazriText.caption.copyWith(color: c.ink2, fontSize: 12.5, height: 1.35);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider ? Border(top: BorderSide(color: c.rule)) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
        child: Row(
          children: [
            GroupIconTile(icon: groupIcon(group)),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.displayName(l.localeName),
                      style: HazriText.bodyStrong.copyWith(color: c.ink, fontSize: 14.5, height: 1.3),
                    ),
                    Text(
                      g == null ? l.sangatNoGoalYet : goalSummary(context, ref, g),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: small,
                    ),
                    Text(l.sangatMembers(group.memberCount), style: small),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (busy)
              const SizedBox(
                width: 72,
                height: 44,
                child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            else if (group.isMember)
              HazriChip(
                icon: HazriIconData.check,
                label: l.sangatJoinedChip,
                background: c.sageSoft,
                foreground: c.sage,
                minHeight: 36,
                onTap: onTap,
              )
            else
              _PillButton(label: l.sangatJoin, onPressed: onToggle),
          ],
        ),
      ),
    );
  }
}

/// Join (saffron), 44 dp high and fully round.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const shape = StadiumBorder();
    return Material(
      color: c.kesriSoft,
      shape: shape,
      child: InkWell(
        onTap: onPressed,
        customBorder: shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: HazriText.chip.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: c.kesriInk),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// IV2, IV4: reuses the current code or makes a new one, then Android's
/// share sheet with `sangatInviteMessage`.
Future<void> shareInvite(BuildContext context, WidgetRef ref, SangatGroup group) async {
  final l = L.of(context);
  final dates = HazriDates.of(context);
  final banis = ref.read(banisProvider).value ?? const <Bani>[];
  try {
    final invite = await ref.read(sangatApiProvider).invite(group.groupId);
    final g = group.goal;
    final goal = g == null
        ? ''
        : g.isSimran
        ? l.sangatSimranMinutesUnit
        : banis.where((b) => b.id == g.baniId).firstOrNull?.name(l.localeName) ?? '';
    await Share.share(
      l.sangatInviteMessage(
        group.displayName(l.localeName),
        g?.target ?? 0,
        goal,
        g == null ? '' : dates.shortDate(parseLocalDateKey(g.endDay)),
        invite.link,
        invite.code,
      ),
    );
  } on Object catch (e) {
    if (context.mounted) ProfileMessages.snack(context, ProfileMessages.of(l, e));
  }
}

/// "Updated 9:41 AM", with the offline line when the last refresh failed.
class UpdatedLine extends StatelessWidget {
  const UpdatedLine({super.key, this.savedAt, this.offline = false, this.colour});

  final DateTime? savedAt;
  final bool offline;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final at = savedAt;
    final parts = [if (offline) l.sangatOffline, if (at != null) l.sangatUpdatedAt(HazriDates.of(context).time(at))];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(parts.join(' · '), style: HazriText.caption.copyWith(color: colour ?? c.muted)),
    );
  }
}
