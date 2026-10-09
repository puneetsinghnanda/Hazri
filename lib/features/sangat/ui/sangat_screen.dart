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

/// The Sangat tab (08-sangat §8.1): my groups, Create and Join, then the
/// built-in groups. The copy on the phone shows first (§5.2).
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
    final active = mine.where((g) => g.isActive).toList();
    final ended = mine.where((g) => !g.isActive).toList();
    final hasProfile = ref.watch(profileControllerProvider) is ProfileLoaded;

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
                Eyebrow(l.sangatMyGroups),
                const SizedBox(height: 8),
                if (mine.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(l.sangatNoGroups, style: HazriText.bodySmall.copyWith(color: c.muted)),
                  ),
                for (final g in active)
                  GroupTile(group: g, onTap: () => context.push(Routes.sangatGroup(g.groupId))),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: l.sangatCreate,
                        icon: HazriIconData.sparkle,
                        onPressed: () => hasProfile ? context.push(Routes.sangatCreate) : _needsProfile(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: l.sangatJoinWithCode,
                        secondary: true,
                        onPressed: () => context.push(Routes.sangatJoin()),
                      ),
                    ),
                  ],
                ),
                if (ended.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Eyebrow(l.sangatEndedHeading),
                  const SizedBox(height: 8),
                  for (final g in ended)
                    GroupTile(group: g, onTap: () => context.push(Routes.sangatGroup(g.groupId))),
                ],
                const SizedBox(height: 18),
                Eyebrow(l.sangatBuiltInGroups),
                const SizedBox(height: 8),
                for (final g in lists?.builtIn ?? const <SangatGroup>[])
                  GroupTile(
                    group: g,
                    onTap: g.isMember ? () => context.push(Routes.sangatGroup(g.groupId)) : null,
                    trailing: _busy.contains(g.groupId)
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : TextButton(
                            onPressed: () => _toggle(g),
                            child: Text(g.isMember ? l.sangatLeave : l.sangatJoin),
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

