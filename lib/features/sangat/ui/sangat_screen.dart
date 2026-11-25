import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/menu_sheet.dart';
import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/tab_header.dart';
import '../../profile/data/profile_controller.dart';
import '../../profile/ui/messages.dart';
import '../../badges/data/badge_controller.dart';
import '../data/sangat_api.dart';
import '../data/sangat_controller.dart';
import '../../live/data/live_controller.dart';
import '../../live/domain/live_group.dart';
import '../../live/ui/live_cards.dart';
import '../domain/sangat_models.dart';
import 'sangat_widgets.dart';

/// The Sangat tab (08-sangat §8.1 as changed by 15-live-sangat LS2-LS4a,
/// designs 125 and 126): two tabs, Discover and My groups. The copy on the
/// phone shows first (§5.2).
class SangatScreen extends ConsumerStatefulWidget {
  const SangatScreen({super.key});

  @override
  ConsumerState<SangatScreen> createState() => _SangatScreenState();
}

class _SangatScreenState extends ConsumerState<SangatScreen> with WidgetsBindingObserver {
  final _busy = <String>{};
  bool _visible = false;

  /// The tab chosen by a tap; null until then, so the default of LS2 holds.
  int? _tab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The shell keeps the tab built when another is showing, with tickers
    // off; refresh each time it comes into view, not only the first time,
    // or a paath read on another tab never shows here.
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    // LS2: the default is chosen afresh each time the tab opens.
    if (visible) _tab = null;
    if (visible) WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _visible) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    // 12-badges SF4: the Sangat facts when the tab opens.
    unawaited(ref.read(badgeControllerProvider).refreshFacts());
    // What waited in the outbox goes first, so the totals that come back
    // already hold it.
    unawaited(ref.read(liveStatusProvider.notifier).refresh());
    await ref.read(outboxSenderProvider).send();
    if (!mounted) return;
    await ref.read(sangatListsProvider.notifier).refresh();
  }

  Future<void> _toggle(SangatGroup g) async {
    final l = L.of(context);
    final api = ref.read(sangatApiProvider);
    setState(() => _busy.add(g.groupId));
    try {
      // Leave is inside the group (design 3E, 2026-10-29); this row only joins.
      if (g.isMember) return;
      await api.joinBuiltIn(g.groupId);
      await ref.read(sangatListsProvider.notifier).setMember(true);
      await _refresh();
    } on Object catch (e) {
      if (mounted) ProfileMessages.snack(context, ProfileMessages.of(l, e));
    } finally {
      if (mounted) setState(() => _busy.remove(g.groupId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final view = ref.watch(sangatListsProvider);
    final lists = view?.value;
    final mine = lists?.mine ?? const <SangatGroup>[];
    final builtIn = lists?.builtIn ?? const <SangatGroup>[];
    final live = ref.watch(liveStatusProvider);
    // The server's list of mine holds the built-in groups you joined; the
    // built-in list is read as well, in case one answer is newer.
    final mineIds = {for (final g in mine) g.groupId};
    final joinedBuiltIn = [for (final g in builtIn) if (g.isMember && !mineIds.contains(g.groupId)) g];
    // LS2: "My groups · N" counts every group you are in: live, built-in and
    // your own.
    final count = mine.length + joinedBuiltIn.length + live.joinedCount;
    // LS2: My groups when you are in any group, else Discover; chosen once
    // each time the tab opens (when there is something to choose from), so
    // joining a group does not move you off the tab you are on.
    if (view != null) _tab ??= count > 0 ? 1 : 0;
    final tab = _tab ?? 0;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: PhoneWidth(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 0, HazriSize.gutter, 24),
              children: [
                TabHeader(title: l.sangatTitle, onMenu: () => showMenuDrawer(context)),
                _Tabs(
                  index: tab,
                  labels: [l.sangatTabDiscover, l.sangatTabMine(count)],
                  onTap: (i) => setState(() => _tab = i),
                ),
                const SizedBox(height: 10),
                UpdatedLine(savedAt: view?.savedAt, offline: view?.offline ?? false),
                if (view == null || (view.offline && lists == null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: view == null
                        ? const Center(
                            child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
                          )
                        : HazriCard(
                            child: Text(l.sangatOffline, style: HazriText.body.copyWith(color: c.ink2)),
                          ),
                  ),
                if (tab == 0) ..._discover(context, builtIn, live) else ..._mine(context, mine, joinedBuiltIn, live),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// LS3, design 125: the live groups as tall cards, the built-in groups,
  /// then your own group.
  List<Widget> _discover(BuildContext context, List<SangatGroup> builtIn, LiveView live) {
    final c = context.colors;
    final l = L.of(context);
    final hasProfile = ref.watch(profileControllerProvider) is ProfileLoaded;
    return [
      SizedBox(
        height: 236,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < liveGroups.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: LiveCard(
                  def: liveGroups[i],
                  status: live.of(liveGroups[i].id),
                  waiting: live.offline && live.groups.isEmpty,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Eyebrow(l.sangatBuiltInGroups, colour: c.ink2),
      ),
      const SizedBox(height: 8),
      if (builtIn.isNotEmpty)
        HazriCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < builtIn.length; i++)
                BuiltInGroupRow(
                  group: builtIn[i],
                  divider: i > 0,
                  busy: _busy.contains(builtIn[i].groupId),
                  onToggle: () => _toggle(builtIn[i]),
                  onTap: builtIn[i].isMember ? () => context.push(Routes.sangatGroup(builtIn[i].groupId)) : null,
                ),
            ],
          ),
        ),
      const SizedBox(height: 16),
      HazriCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.sangatOwnGroup, style: HazriText.bodyStrong.copyWith(color: c.ink)),
            const SizedBox(height: 4),
            Text(l.sangatOwnGroupSub, style: HazriText.bodySmall.copyWith(color: c.ink2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: l.sangatCreate,
                    onPressed: () => hasProfile ? context.push(Routes.sangatCreate) : _needsProfile(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: l.sangatJoinGroupTile,
                    secondary: true,
                    onPressed: () => context.push(Routes.sangatJoin()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  /// LS4a, design 126: Create and Join at the top, the live groups you are
  /// in, then running and ended.
  List<Widget> _mine(BuildContext context, List<SangatGroup> mine, List<SangatGroup> joinedBuiltIn, LiveView live) {
    final c = context.colors;
    final l = L.of(context);
    final hasProfile = ref.watch(profileControllerProvider) is ProfileLoaded;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final seconds = ref.watch(liveSecondsProvider).value ?? const {};
    final liveIn = [for (final d in liveGroups) if (live.of(d.id).joined) d];
    final running = [...mine.where((g) => !groupEnded(g)), ...joinedBuiltIn];
    final ended = mine.where(groupEnded).toList();
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Eyebrow(text, colour: c.ink2),
        );
    return [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SangatActionTile(
                icon: HazriIconData.plus,
                label: l.sangatCreate,
                sub: l.sangatCreateSub,
                background: dark ? c.card2 : c.primary,
                foreground: Colors.white,
                onTap: () => hasProfile ? context.push(Routes.sangatCreate) : _needsProfile(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SangatActionTile(
                icon: HazriIconData.code,
                label: l.sangatJoinGroupTile,
                sub: l.sangatJoinGroupSub,
                background: c.kesriSoft,
                foreground: c.kesriInk,
                onTap: () => context.push(Routes.sangatJoin()),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (liveIn.isNotEmpty) ...[
        heading(l.liveYouAreIn),
        HazriCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final d in liveIn)
                LiveRow(
                  def: d,
                  status: live.of(d.id),
                  minutesToday: (seconds[d.id]?.today ?? 0) ~/ 60,
                  waiting: live.offline && live.groups.isEmpty,
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
      if (running.isEmpty && ended.isEmpty && liveIn.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(l.sangatNoGroups, style: HazriText.bodySmall.copyWith(color: c.muted)),
        ),
      if (running.isNotEmpty) ...[
        heading(l.sangatRunningHeading),
        TwoColumnGrid(
          children: [
            for (final g in running) GroupGridTile(group: g, onTap: () => context.push(Routes.sangatGroup(g.groupId))),
          ],
        ),
      ],
      if (ended.isNotEmpty) ...[
        heading(l.sangatEndedHeading),
        TwoColumnGrid(
          children: [
            for (final g in ended) GroupGridTile(group: g, onTap: () => context.push(Routes.sangatGroup(g.groupId))),
          ],
        ),
      ],
    ];
  }

  /// CG1: Create without a profile shows the profile prompt.
  void _needsProfile(BuildContext context) {
    final l = L.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.sangatCreateNeedsProfile, style: HazriText.body),
            const SizedBox(height: 16),
            PrimaryButton(
              label: l.profileBannerTitle,
              onPressed: () {
                Navigator.of(sheet).pop();
                context.push(Routes.profileSetup);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The two tabs, Discover first (LS2).
class _Tabs extends StatelessWidget {
  const _Tabs({required this.index, required this.labels, required this.onTap});

  final int index;
  final List<String> labels;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: i == index,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: i == index ? c.card : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HazriText.captionStrong.copyWith(color: i == index ? c.ink : c.ink2, fontSize: 14),
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
