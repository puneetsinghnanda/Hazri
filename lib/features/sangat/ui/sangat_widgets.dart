import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/surfaces.dart';
import '../../nitnem/domain/bani.dart';
import '../../profile/ui/messages.dart';
import '../data/sangat_api.dart';
import '../domain/sangat_models.dart';

/// "5,000 Japji Sahib by 31 Dec" or "100,000 minutes of Naam Simran by 31 Dec".
String goalSummary(BuildContext context, WidgetRef ref, SangatGoal g) {
  final l = L.of(context);
  final date = HazriDates.of(context).shortDate(parseLocalDateKey(g.endDay));
  if (g.isSimran) return l.sangatGoalSummarySimran(g.target, date);
  final banis = ref.watch(banisProvider).value ?? const <Bani>[];
  final bani = banis.where((b) => b.id == g.baniId).firstOrNull?.name(l.localeName) ?? g.baniId ?? '';
  return l.sangatGoalSummaryBani(g.target, bani, date);
}

/// "40 of 100 · 40%", or "400 of 1,000 min · 40%" for Naam Simran.
String goalProgress(L l, SangatGoal g) =>
    g.isSimran ? l.sangatProgressMinutes(g.total, g.target, g.pct) : l.sangatProgress(g.total, g.target, g.pct);

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

/// A group in a list (VS1, VS2): name, goal, total of target, percentage,
/// days left; [trailing] for Join or Leave.
class GroupTile extends ConsumerWidget {
  const GroupTile({super.key, required this.group, this.onTap, this.trailing});

  final SangatGroup group;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final g = group.goal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HazriCard(
        onTap: onTap,
        child: Row(
          children: [
            ProgressRing(
              size: 46,
              progress: g == null ? 0 : (g.pct / 100).clamp(0.0, 1.0),
              done: g?.status == 'COMPLETED',
              child: g == null ? null : Text('${g.pct}%', style: HazriText.caption.copyWith(fontSize: 10, color: c.ink)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.displayName(l.localeName), style: HazriText.bodyStrong.copyWith(color: c.ink)),
                  const SizedBox(height: 2),
                  Text(g == null ? l.sangatNoGoalYet : goalSummary(context, ref, g),
                      style: HazriText.caption.copyWith(color: c.ink2)),
                  if (g != null)
                    Text(
                      '${goalProgress(l, g)} · ${goalWhen(context, group)}',
                      style: HazriText.caption.copyWith(color: c.muted),
                    ),
                  if (group.isBuiltIn)
                    Text(l.sangatMembers(group.memberCount), style: HazriText.caption.copyWith(color: c.muted)),
                ],
              ),
            ),
            ?trailing,
          ],
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
    await Share.share(l.sangatInviteMessage(
      group.displayName(l.localeName),
      g?.target ?? 0,
      goal,
      g == null ? '' : dates.shortDate(parseLocalDateKey(g.endDay)),
      invite.link,
      invite.code,
    ));
  } on Object catch (e) {
    if (context.mounted) ProfileMessages.snack(context, ProfileMessages.of(l, e));
  }
}

/// "Updated 9:41 AM", with the offline line when the last refresh failed.
class UpdatedLine extends StatelessWidget {
  const UpdatedLine({super.key, this.savedAt, this.offline = false});

  final DateTime? savedAt;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final at = savedAt;
    final parts = [
      if (offline) l.sangatOffline,
      if (at != null) l.sangatUpdatedAt(HazriDates.of(context).time(at)),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(parts.join(' · '), style: HazriText.caption.copyWith(color: c.muted)),
    );
  }
}
