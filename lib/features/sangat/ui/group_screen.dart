import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/surfaces.dart';
import '../../goals/data/goals_controller.dart';
import '../../profile/ui/messages.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/sangat_api.dart';
import '../data/sangat_controller.dart';
import '../domain/sangat_models.dart';
import 'create_group_screen.dart';
import 'sangat_widgets.dart';

/// What this phone did today toward [goal], from `user.db`: paath of the
/// goal's bani, or whole minutes of Naam Simran, each sitting counted as the
/// server counts it (08-sangat CT1, `amountFor`).
int yoursToday(DayRows? rows, SangatGoal goal) {
  if (rows == null) return 0;
  if (goal.isSimran) {
    return rows.sittings.where((s) => s.deletedAt == null).fold(0, (sum, s) => sum + s.durationS ~/ 60);
  }
  return rows.completions.where((c) => c.deletedAt == null && c.baniId == goal.baniId).length;
}

/// One group (VS3, VS4) and its menu (§8.2), design 103: the ring in a navy
/// band, the goal's timeline, three figures, Sit for the paath (SC1), and
/// the members. [offerShare]: just created, so the invite is offered at once
/// (S-4).
class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({super.key, required this.groupId, this.offerShare = false});

  final String groupId;
  final bool offerShare;

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> {
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    // The outbox first, so the group comes back with this phone's paath in it.
    await ref.read(outboxSenderProvider).send();
    if (!mounted) return;
    final ok = await ref.read(sangatGroupProvider(widget.groupId).notifier).refresh();
    if (!ok && mounted) setState(() => _gone = true);
  }

  Future<void> _act(Future<void> Function() action, {bool leaveScreen = false}) async {
    final l = L.of(context);
    try {
      await action();
      await ref.read(sangatListsProvider.notifier).refresh();
      if (!mounted) return;
      if (leaveScreen) {
        context.canPop() ? context.pop() : context.go(Routes.sangat);
      } else {
        await _refresh();
      }
    } on Object catch (e) {
      if (mounted) ProfileMessages.snack(context, ProfileMessages.of(l, e));
    }
  }

  Future<bool> _confirm(String text, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          content: Text(text),
          actions: [
            TextButton(onPressed: () => Navigator.of(d).pop(false), child: Text(L.of(context).actionCancel)),
            TextButton(onPressed: () => Navigator.of(d).pop(true), child: Text(action)),
          ],
        ),
      ) ??
      false;

  Future<void> _menu(String value, SangatGroup g) async {
    final l = L.of(context);
    final api = ref.read(sangatApiProvider);
    final name = g.displayName(l.localeName);
    switch (value) {
      case 'share':
        await shareInvite(context, ref, g);
      case 'reset':
        await _act(() async {
          await api.invite(g.groupId, reset: true);
        });
        if (mounted) await shareInvite(context, ref, g);
      case 'end':
        final goal = g.goal;
        if (goal == null) return;
        final today = istToday();
        final start = parseLocalDateKey(goal.startDay);
        final picked = await showDatePicker(
          context: context,
          initialDate: parseLocalDateKey(goal.endDay).isBefore(today) ? today : parseLocalDateKey(goal.endDay),
          firstDate: today,
          lastDate: start.add(const Duration(days: 364)),
        );
        if (picked != null) {
          await _act(() async {
            await api.changeEndDay(g.groupId, localDateKey(picked));
          });
        }
      case 'leave':
        if (await _confirm(l.sangatLeaveConfirm(name), l.sangatLeave)) {
          await _act(() => api.leave(g.groupId), leaveScreen: true);
        }
      case 'delete':
        if (await _confirm(l.sangatDeleteConfirm(name), l.sangatDeleteGroup)) {
          await _act(() => api.delete(g.groupId), leaveScreen: true);
        }
      case 'report':
        if (mounted) await showReportSheet(context, g.groupId);
    }
  }

  /// The ⋮ in the band (§8.2): Share invite, the creator's actions, Leave,
  /// Report. A built-in group has Leave and Report only (IV1).
  Widget _menuButton(SangatGroup g) {
    final l = L.of(context);
    final onlyMember = g.memberCount <= 1;
    return PopupMenuButton<String>(
      tooltip: l.sangatGroupMenu,
      onSelected: (v) => _menu(v, g),
      itemBuilder: (_) => [
        if (!g.isBuiltIn && g.isActive) PopupMenuItem(value: 'share', child: Text(l.sangatShareInvite)),
        if (g.isCreator && g.isActive) ...[
          PopupMenuItem(value: 'end', child: Text(l.sangatChangeEndDate)),
          PopupMenuItem(value: 'reset', child: Text(l.sangatResetCode)),
        ],
        if (g.isCreator && onlyMember) PopupMenuItem(value: 'delete', child: Text(l.sangatDeleteGroup)),
        if (!g.isCreator && g.isMember) PopupMenuItem(value: 'leave', child: Text(l.sangatLeave)),
        PopupMenuItem(value: 'report', child: Text(l.sangatReport)),
      ],
      child: const _BandSquare(icon: HazriIconData.dots),
    );
  }

  void _back() => context.canPop() ? context.pop() : context.go(Routes.sangat);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final view = ref.watch(sangatGroupProvider(widget.groupId));
    final g = view?.value;

    if (_gone || (g == null && view == null && _gone)) {
      return HazriScreen(title: l.sangatTitle, children: [Text(l.sangatCodeInvalid)]);
    }
    if (g == null) {
      return HazriScreen(
        title: l.sangatTitle,
        children: const [Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))],
      );
    }
    final goal = g.goal;
    final ended = groupEnded(g);
    final shareBelow = !g.isBuiltIn && g.isActive;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: PopScope(
        canPop: context.canPop(),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go(Routes.sangat);
        },
        child: Scaffold(
          backgroundColor: c.bg,
          body: PhoneWidth(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _GroupBand(group: g, menu: _menuButton(g), onBack: _back),
                  // The first card overlaps the band by 28 dp, as on Today.
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (goal != null) ...[
                            _Timeline(group: g, goal: goal),
                            const SizedBox(height: 10),
                            _Figures(group: g, goal: goal),
                            if (g.isMember && !ended) ...[
                              const SizedBox(height: 10),
                              SitForButton(goal: goal),
                            ],
                          ],
                          if (widget.offerShare && shareBelow) ...[
                            const SizedBox(height: 10),
                            PrimaryButton(
                              label: l.sangatShareInvite,
                              icon: HazriIconData.share,
                              onPressed: () => shareInvite(context, ref, g),
                            ),
                          ],
                          const SizedBox(height: 10),
                          _MembersCard(
                            group: g,
                            onRemove: (m) async {
                              final name = m.name ?? l.sangatAnonymousName;
                              if (await _confirm(l.sangatRemoveConfirm(name), l.sangatRemoveMember)) {
                                await _act(() => ref.read(sangatApiProvider).removeMember(g.groupId, m.memberKey));
                              }
                            },
                          ),
                          if (shareBelow && !widget.offerShare) ...[
                            const SizedBox(height: 10),
                            PrimaryButton(
                              label: l.sangatShareInvite,
                              icon: HazriIconData.share,
                              secondary: true,
                              onPressed: () => shareInvite(context, ref, g),
                            ),
                          ],
                          UpdatedLine(savedAt: view?.savedAt, offline: view?.offline ?? false),
                          SizedBox(height: MediaQuery.paddingOf(context).bottom),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A 44 dp square on the band: white on a white wash, as on Today.
class _BandSquare extends StatelessWidget {
  const _BandSquare({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: AppIcon(icon, size: 20, color: Colors.white),
      );
}

/// Design 103's band: back, the name over "Built-in group · N members", the
/// menu; the ring with total of target and the percentage; the goal.
class _GroupBand extends ConsumerWidget {
  const _GroupBand({required this.group, required this.menu, required this.onBack});

  final SangatGroup group;
  final Widget menu;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final band = dark ? c.card2 : c.primary;
    const white = Colors.white;
    final accent = HazriColors.dark.kesri;
    final goal = group.goal;
    final members = l.sangatMembers(group.memberCount);
    final sub = group.isBuiltIn ? '${l.sangatBuiltInKind} · $members' : members;
    final lang = l.localeName;

    return Container(
      decoration: BoxDecoration(
        color: band,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 16, 18, 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Tooltip(
                message: l.actionBack,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: onBack,
                    child: const _BandSquare(icon: HazriIconData.chevronLeft),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.displayName(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: HazriText.display22.copyWith(color: white, height: 1.1),
                    ),
                    Text(sub, style: HazriText.caption.copyWith(color: white.withValues(alpha: 0.82), fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              menu,
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: ProgressRing(
              size: 150,
              strokeWidth: 13,
              progress: goal == null ? 0 : (goal.pct / 100).clamp(0.0, 1.0),
              colour: accent,
              trackColour: white.withValues(alpha: 0.16),
              child: goal == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatCount(lang, goal.total),
                                style: HazriText.display22.copyWith(color: white, fontSize: 28, height: 1)),
                            Text(
                              goal.isSimran
                                  ? l.sangatOfTargetMinutes(formatCount(lang, goal.target))
                                  : l.sangatOfTarget(formatCount(lang, goal.target)),
                              style: HazriText.captionStrong.copyWith(color: white.withValues(alpha: 0.85)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('${goal.pct}%',
                                  style: HazriText.display22.copyWith(color: accent, fontSize: 17, height: 1.2)),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            goal == null ? l.sangatNoGoalYet : goalSummary(context, ref, goal),
            textAlign: TextAlign.center,
            style: HazriText.bodyStrong
                .copyWith(color: white.withValues(alpha: 0.92), fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Design 103: the current goal only, as three points: started, today with
/// the days left, and the end (with the next goal's first day for a built-in
/// group, BI4). An ended goal is two points.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.group, required this.goal});

  final SangatGroup group;
  final SangatGoal goal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final navy = dark ? c.ink2 : c.primary;
    final start = parseLocalDateKey(goal.startDay);
    final end = parseLocalDateKey(goal.endDay);
    final days = DateTime.utc(end.year, end.month, end.day)
            .difference(DateTime.utc(start.year, start.month, start.day))
            .inDays +
        1;
    final ended = groupEnded(group);
    final day = (days - goal.daysLeft + 1).clamp(1, days);
    final next = DateTime(end.year, end.month, end.day + 1);

    Widget dot({Color? fill, Color? ring, bool halo = false}) => Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill ?? c.card,
            border: ring == null ? null : Border.all(color: ring, width: 2),
            boxShadow: halo ? [BoxShadow(color: c.kesriSoft, spreadRadius: 4)] : null,
          ),
        );

    Widget node(Widget mark, String t1, String t2, CrossAxisAlignment align, {bool hl = false}) {
      final text = switch (align) {
        CrossAxisAlignment.start => TextAlign.left,
        CrossAxisAlignment.end => TextAlign.right,
        _ => TextAlign.center,
      };
      return Expanded(
        child: Column(
          crossAxisAlignment: align,
          children: [
            mark,
            const SizedBox(height: 6),
            Text(t1,
                textAlign: text,
                style: HazriText.captionStrong
                    .copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: hl ? c.kesriInk : c.ink)),
            Text(t2, textAlign: text, style: HazriText.caption.copyWith(color: hl ? c.kesriInk : c.ink2, height: 1.25)),
          ],
        ),
      );
    }

    return HazriCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Eyebrow(l.sangatThisGoal, colour: c.ink2)),
              const SizedBox(width: 8),
              Text(ended ? goalWhen(context, group) : l.sangatDayOf(day, days),
                  style: HazriText.captionStrong.copyWith(color: c.ink2, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                Positioned(
                  left: 9,
                  right: 9,
                  top: 8,
                  height: 2,
                  child: ColoredBox(color: c.rule),
                ),
                Positioned(
                  left: 9,
                  width: ended ? box.maxWidth - 18 : box.maxWidth / 2 - 9,
                  top: 8,
                  height: 2,
                  child: ColoredBox(color: navy),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    node(dot(fill: navy), dates.shortDate(start), l.sangatStarted, CrossAxisAlignment.start),
                    if (!ended)
                      node(dot(fill: c.kesri, halo: true), l.today, l.sangatDaysLeft(goal.daysLeft),
                          CrossAxisAlignment.center,
                          hl: true),
                    node(
                      ended ? dot(fill: navy) : dot(ring: c.muted.withValues(alpha: 0.5)),
                      dates.shortDate(end),
                      group.isBuiltIn && !ended
                          ? l.sangatEndsNewGoal(dates.shortDate(next))
                          : ended
                              ? l.sangatEndedHeading
                              : l.sangatEnds,
                      CrossAxisAlignment.end,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Design 103: the sangat today (the server's), yours today (this phone's,
/// from `user.db`) and yours toward the goal (your member row).
class _Figures extends ConsumerWidget {
  const _Figures({required this.group, required this.goal});

  final SangatGroup group;
  final SangatGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final lang = l.localeName;
    final unit = goal.isSimran ? l.sangatMinUnit : null;
    final mine = group.members.where((m) => m.isYou).firstOrNull?.contribution ?? 0;
    final today = yoursToday(ref.watch(todayRowsProvider).value, goal);
    final tiles = <Widget>[
      _Figure(value: formatCount(lang, goal.todayTotal), unit: unit, label: l.sangatFigureSangatToday),
      if (group.isMember) ...[
        _Figure(value: formatCount(lang, today), unit: unit, label: l.sangatFigureYoursToday, mine: true),
        _Figure(value: formatCount(lang, mine), unit: unit, label: l.sangatFigureYoursGoal, mine: true),
      ],
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: i < tiles.length ? tiles[i] : const SizedBox.shrink()),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label, this.unit, this.mine = false});

  final String value;
  final String? unit;
  final String label;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final colour = mine ? c.kesriInk : c.ink;
    return HazriCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: value,
                children: [
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: HazriText.captionStrong.copyWith(fontSize: 13, color: colour),
                    ),
                ],
              ),
              style: HazriText.display22.copyWith(color: colour, height: 1.1),
            ),
          ),
          Text(label, style: HazriText.captionStrong.copyWith(color: c.ink2, height: 1.25)),
        ],
      ),
    );
  }
}

/// SC1: "Sit for Naam Simran" opens the Simran tab, as Today's CTA does;
/// "Sit for {bani}" opens the reader at that bani. The bani's name comes
/// from `content.db`.
class SitForButton extends ConsumerWidget {
  const SitForButton({super.key, required this.goal});

  final SangatGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    if (goal.isSimran) {
      return PrimaryButton(
        label: l.sangatSitFor(l.sangatGoalSimran),
        icon: HazriIconData.simranDots,
        onPressed: () => context.go(Routes.simran),
      );
    }
    final bani = goalBani(ref, goal);
    if (bani == null) return const SizedBox.shrink();
    return PrimaryButton(
      label: l.sangatSitFor(bani.name(l.localeName)),
      icon: HazriIconData.book,
      onPressed: () => context.push(Routes.reader(bani.slug)),
    );
  }
}

/// VS4–VS6, design 103: A to Z as the server sends them, each with their
/// own figure; no bars and no rank; then "and N more".
class _MembersCard extends StatelessWidget {
  const _MembersCard({required this.group, required this.onRemove});

  final SangatGroup group;
  final void Function(SangatMember) onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final lang = l.localeName;
    final minutes = group.goal?.isSimran ?? false;
    return HazriCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Eyebrow(l.sangatMembersHeading, colour: c.ink2),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l.sangatMembersAtoZ(formatCount(lang, group.memberCount)),
                    textAlign: TextAlign.end,
                    style: HazriText.captionStrong.copyWith(color: c.ink2, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < group.members.length; i++)
            _MemberRow(
              member: group.members[i],
              divider: i > 0,
              figure: minutes
                  ? l.goalSimranMinutes(group.members[i].contribution)
                  : formatCount(lang, group.members[i].contribution),
              canRemove: group.isCreator && !group.members[i].isCreator && !group.members[i].hasLeft && group.isActive,
              onRemove: () => onRemove(group.members[i]),
            ),
          if (group.moreMembers > 0)
            DecoratedBox(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.rule))),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  l.sangatAndMore(formatCount(lang, group.moreMembers)),
                  style: HazriText.captionStrong.copyWith(color: c.ink2, fontSize: 13.5),
                ),
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// VS4, VS5, VS6: a name and a contribution; no rank, nobody marked as
/// behind.
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.figure,
    required this.canRemove,
    required this.onRemove,
    this.divider = false,
  });

  final SangatMember member;
  final String figure;
  final bool canRemove;
  final VoidCallback onRemove;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final name = member.name ?? l.sangatAnonymousName;
    return DecoratedBox(
      decoration: BoxDecoration(border: divider ? Border(top: BorderSide(color: c.rule)) : null),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 6, canRemove ? 4 : 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.isYou ? '$name (${l.sangatYou})' : name,
                        style: HazriText.body
                            .copyWith(fontWeight: FontWeight.w600, color: member.hasLeft ? c.muted : c.ink)),
                    if (member.isCreator)
                      Text(l.sangatCreatorLabel, style: HazriText.caption.copyWith(color: c.kesriInk)),
                    if (member.hasLeft) Text(l.sangatLeft, style: HazriText.caption.copyWith(color: c.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(figure, style: HazriText.body.copyWith(fontWeight: FontWeight.w600, color: c.ink2)),
              if (canRemove)
                IconButton(
                  tooltip: l.sangatRemoveMember,
                  icon: Icon(Icons.person_remove_outlined, size: 20, color: c.muted),
                  onPressed: onRemove,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// RP1–RP3: four reasons; Other takes an optional note of up to 200.
Future<void> showReportSheet(BuildContext context, String groupId) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReportSheet(groupId: groupId),
    );

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.groupId});

  final String groupId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  String _reason = 'OFFENSIVE';
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = L.of(context);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(sangatApiProvider).report(
            widget.groupId,
            _reason,
            note: _reason == 'OTHER' && _note.text.trim().isNotEmpty ? _note.text.trim() : null,
          );
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.sangatReportSent)));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(ProfileMessages.of(l, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final reasons = {
      'OFFENSIVE': l.sangatReportReasonOffensive,
      'SPAM': l.sangatReportReasonSpam,
      'OFF_TOPIC': l.sangatReportReasonOffTopic,
      'OTHER': l.sangatReportReasonOther,
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.sangatReport, style: HazriText.display22),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v ?? _reason),
            child: Column(
              children: [
                for (final e in reasons.entries) RadioListTile<String>(value: e.key, title: Text(e.value)),
              ],
            ),
          ),
          if (_reason == 'OTHER')
            TextField(
              controller: _note,
              maxLength: 200,
              decoration: InputDecoration(labelText: l.sangatReportNote),
            ),
          const SizedBox(height: 12),
          _busy ? const Center(child: CircularProgressIndicator()) : PrimaryButton(label: l.sangatReportSend, onPressed: _send),
        ],
      ),
    );
  }
}
