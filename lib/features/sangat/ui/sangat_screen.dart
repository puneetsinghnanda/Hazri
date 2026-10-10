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
import '../domain/sangat_models.dart';
import 'sangat_widgets.dart';

/// The Sangat tab (08-sangat §8.1, design 102 "dashboard tiles"): Create
/// and Join side by side, my groups as a 2 x 2 grid, then the built-in groups
/// as full-width rows. The copy on the phone shows first (§5.2).
class SangatScreen extends ConsumerStatefulWidget {
  const SangatScreen({super.key});

  @override
  ConsumerState<SangatScreen> createState() => _SangatScreenState();
}

class _SangatScreenState extends ConsumerState<SangatScreen> with WidgetsBindingObserver {
  final _busy = <String>{};
  bool _visible = false;

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
    await ref.read(outboxSenderProvider).send();
    if (!mounted) return;
    await ref.read(sangatListsProvider.notifier).refresh();
  }

  Future<void> _toggle(SangatGroup g) async {
    final l = L.of(context);
    final api = ref.read(sangatApiProvider);
    setState(() => _busy.add(g.groupId));
    try {
      if (g.isMember) {
        await api.leave(g.groupId);
      } else {
        await api.joinBuiltIn(g.groupId);
        await ref.read(sangatListsProvider.notifier).setMember(true);
      }
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
    // VS1: active groups first, then the ones that have ended, muted.
    final ordered = [...mine.where((g) => !groupEnded(g)), ...mine.where(groupEnded)];
    final hasProfile = ref.watch(profileControllerProvider) is ProfileLoaded;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final builtIn = lists?.builtIn ?? const <SangatGroup>[];

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
                TabHeader(title: l.sangatTitle, onMenu: () => showMenuSheet(context)),
                UpdatedLine(savedAt: view?.savedAt, offline: view?.offline ?? false),
                if (view == null || (view.offline && lists == null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: view == null
                        ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                        : HazriCard(child: Text(l.sangatOffline, style: HazriText.body.copyWith(color: c.ink2))),
                  ),
                // Design 102: Create (navy) and Join (saffron) side by side.
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
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Eyebrow(l.sangatMyGroups, colour: c.ink2),
                ),
                const SizedBox(height: 8),
                if (mine.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                    child: Text(l.sangatNoGroups, style: HazriText.bodySmall.copyWith(color: c.muted)),
                  )
                else
                  TwoColumnGrid(
                    children: [
                      for (final g in ordered)
                        GroupGridTile(group: g, onTap: () => context.push(Routes.sangatGroup(g.groupId))),
                    ],
                  ),
                const SizedBox(height: 4),
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
                            onTap: builtIn[i].isMember
                                ? () => context.push(Routes.sangatGroup(builtIn[i].groupId))
                                : null,
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

