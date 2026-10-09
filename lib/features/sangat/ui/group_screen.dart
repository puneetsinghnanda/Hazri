import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/surfaces.dart';
import '../../profile/ui/messages.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/sangat_api.dart';
import '../data/sangat_controller.dart';
import '../domain/sangat_models.dart';
import 'create_group_screen.dart';
import 'sangat_widgets.dart';

/// One group (VS3, VS4) and its menu (§8.2). [offerShare]: just created,
/// so the invite is offered at once (S-4).
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final dates = HazriDates.of(context);
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
    final onlyMember = g.memberCount <= 1;

    return HazriScreen(
      title: g.displayName(l.localeName),
      actions: [
        PopupMenuButton<String>(
          icon: AppIcon(HazriIconData.dots, size: 20, color: c.ink),
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
        ),
      ],
      children: [
        UpdatedLine(savedAt: view?.savedAt, offline: view?.offline ?? false),
        HazriCard(
          child: Row(
            children: [
              ProgressRing(
                size: 64,
                progress: goal == null ? 0 : (goal.pct / 100).clamp(0.0, 1.0),
                done: goal?.status == 'COMPLETED',
                child: goal == null ? null : Text('${goal.pct}%', style: HazriText.captionStrong.copyWith(color: c.ink)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal == null ? l.sangatNoGoalYet : goalSummary(context, ref, goal),
                        style: HazriText.bodyStrong.copyWith(color: c.ink)),
                    if (goal != null) ...[
                      const SizedBox(height: 4),
                      Text(goalProgress(l, goal),
                          style: HazriText.caption.copyWith(color: c.ink2)),
                      Text(
                        '${goal.isSimran ? l.sangatTodayMinutes(goal.todayTotal) : l.sangatToday(goal.todayTotal)} · ${goalWhen(context, g)}',
                        style: HazriText.caption.copyWith(color: c.muted),
                      ),
                      Text(
                        '${dates.shortDate(parseLocalDateKey(goal.startDay))} – ${dates.shortDate(parseLocalDateKey(goal.endDay))}',
                        style: HazriText.caption.copyWith(color: c.muted),
                      ),
                    ],
                    Text(l.sangatMembers(g.memberCount), style: HazriText.caption.copyWith(color: c.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.offerShare && g.isActive && !g.isBuiltIn) ...[
          const SizedBox(height: 12),
          PrimaryButton(label: l.sangatShareInvite, onPressed: () => shareInvite(context, ref, g)),
        ],
        const SizedBox(height: 16),
        HazriCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (final m in g.members)
                _MemberRow(
                  member: m,
                  minutes: g.goal?.isSimran ?? false,
                  canRemove: g.isCreator && !m.isCreator && !m.hasLeft && g.isActive,
                  onRemove: () async {
                    final name = m.name ?? l.sangatAnonymousName;
                    if (await _confirm(l.sangatRemoveConfirm(name), l.sangatRemoveMember)) {
                      await _act(() => ref.read(sangatApiProvider).removeMember(g.groupId, m.memberKey));
                    }
                  },
                ),
              if (g.moreMembers > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l.sangatMoreMembers(g.moreMembers), style: HazriText.caption.copyWith(color: c.muted)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// VS4, VS5, VS6: a name and a contribution; no rank, nobody marked as
/// behind.
class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.canRemove, required this.onRemove, this.minutes = false});

  final SangatMember member;

  /// A Naam Simran goal: the contribution is minutes.
  final bool minutes;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final name = member.name ?? l.sangatAnonymousName;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.isYou ? '$name (${l.sangatYou})' : name,
                    style: HazriText.bodyStrong.copyWith(color: member.hasLeft ? c.muted : c.ink)),
                if (member.isCreator)
                  Text(l.sangatCreatorLabel, style: HazriText.caption.copyWith(color: c.kesriInk)),
                if (member.hasLeft) Text(l.sangatLeft, style: HazriText.caption.copyWith(color: c.muted)),
              ],
            ),
          ),
          Text(minutes ? l.goalSimranMinutes(member.contribution) : '${member.contribution}', style: HazriText.bodyStrong.copyWith(color: c.ink)),
          if (canRemove)
            IconButton(
              tooltip: l.sangatRemoveMember,
              icon: Icon(Icons.person_remove_outlined, size: 20, color: c.muted),
              onPressed: onRemove,
            ),
        ],
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
