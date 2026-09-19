import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/content_repository.dart';
import '../../../features/nitnem/domain/bani.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/group_repository.dart';
import '../domain/sangat_group.dart';

/// Design 40 — what the group is reciting together, and by when.
///
/// Admin only, and the rules agree: `groups/{id}` takes an update from an
/// admin and nobody else, so a member who reached this screen some other way
/// would be refused at the door rather than trusted by the UI.
class GroupGoalScreen extends ConsumerStatefulWidget {
  const GroupGoalScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupGoalScreen> createState() => _GroupGoalScreenState();
}

class _GroupGoalScreenState extends ConsumerState<GroupGoalScreen> {
  String? _slug;
  int _target = 0;
  DateTime? _endsAt;
  bool _busy = false;
  String? _error;

  Future<void> _save(SangatGroup group) async {
    final l = L.of(context);
    final slug = group.countsMinutes ? 'simran' : _slug;
    if (slug == null) {
      setState(() => _error = l.groupGoalWhat);
      return;
    }
    if (_target <= 0) {
      setState(() => _error = l.groupGoalNeedTarget);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final outcome = await ref.read(groupRepositoryProvider).setGoal(
          widget.groupId,
          GroupGoal(slug: slug, target: _target, endsAt: _endsAt),
        );
    if (!mounted) return;

    switch (outcome) {
      case GroupOk():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.groupGoalSaved)));
        context.pop();
      case GroupRefused():
        setState(() {
          _busy = false;
          _error = l.sangatRefused;
        });
      case GroupNotFound():
        setState(() {
          _busy = false;
          _error = l.groupGone;
        });
      case GroupUnavailable():
      case GroupFailed():
        setState(() {
          _busy = false;
          _error = l.sangatUnavailable;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final lang = L.of(context).localeName;

    if (group == null) {
      return HazriScreen(
        title: l.groupSetGoalTitle,
        children: [
          const SizedBox(height: 40),
          Center(child: Text(l.groupGone, style: HazriText.body.copyWith(color: c.muted))),
        ],
      );
    }

    // A circle counts minutes and has nothing to choose; everything else
    // picks a bani from the content database, never a name typed in Dart.
    final choosesBani = !group.countsMinutes;
    final step = group.countsMinutes ? 15 : 1;
    if (_target == 0) _target = group.goal?.target ?? (group.countsMinutes ? 300 : 11);
    _slug ??= group.goal?.slug;

    return HazriScreen(
      title: l.groupSetGoalTitle,
      subtitle: group.name,
      children: [
        if (choosesBani) ...[
          const SizedBox(height: 6),
          Eyebrow(l.groupGoalWhat),
          const SizedBox(height: 8),
          HazriCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (var i = 0; i < banis.length; i++) ...[
                  InkWell(
                    onTap: () => setState(() => _slug = banis[i].slug),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(banis[i].name(lang),
                                style: HazriText.bodyStrong.copyWith(color: c.ink)),
                          ),
                          if (_slug == banis[i].slug)
                            AppIcon(HazriIconData.check, size: 20, color: c.kesri),
                        ],
                      ),
                    ),
                  ),
                  if (i != banis.length - 1) Divider(height: 1, color: c.rule),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        Eyebrow(l.groupGoalHowMany),
        const SizedBox(height: 8),
        HazriCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CardIconButton(
                icon: HazriIconData.close,
                tooltip: l.actionRemove,
                onPressed:
                    _target <= step ? null : () => setState(() => _target -= step),
              ),
              SizedBox(
                width: 140,
                child: Column(
                  children: [
                    Text('$_target', style: HazriText.display34.copyWith(color: c.ink)),
                    Text(group.countsMinutes ? l.unitMinutes : l.unitPaath,
                        style: HazriText.caption.copyWith(color: c.muted)),
                  ],
                ),
              ),
              CardIconButton(
                icon: HazriIconData.sparkle,
                tooltip: l.actionShowMore,
                onPressed: () => setState(() => _target += step),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Eyebrow(l.groupGoalByWhen),
        const SizedBox(height: 8),
        HazriCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endsAt ?? now.add(const Duration(days: 7)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 730)),
                  );
                  if (picked != null) setState(() => _endsAt = picked);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _endsAt == null
                              ? l.groupGoalPickDate
                              : MaterialLocalizations.of(context)
                                  .formatFullDate(_endsAt!),
                          style: HazriText.bodyStrong.copyWith(color: c.ink),
                        ),
                      ),
                      AppIcon(HazriIconData.calendar, size: 19, color: c.muted),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: c.rule),
              InkWell(
                onTap: () => setState(() => _endsAt = null),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l.groupGoalNoEnd,
                            style: HazriText.bodyStrong.copyWith(color: c.ink)),
                      ),
                      if (_endsAt == null)
                        AppIcon(HazriIconData.check, size: 20, color: c.kesri),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: HazriText.bodySmall.copyWith(color: c.kesriInk)),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: l.groupGoalSet,
          onPressed: _busy ? null : () => _save(group),
        ),
      ],
    );
  }
}
