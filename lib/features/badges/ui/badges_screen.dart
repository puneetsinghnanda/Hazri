import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_db.dart' show BaniSlot;
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart' show BadgeRow;
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../../nitnem/domain/bani.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/badge_controller.dart';
import '../domain/badges.dart';
import 'badge_text.dart';
import 'badge_widgets.dart';

/// UI2, design 96: all ten, two per row; earned in colour with the date,
/// the rest greyed with their name, rule and "Not yet". No meters (UI3).
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final rows = ref.watch(earnedBadgesProvider).value ?? const <BadgeRow>[];
    final byId = {for (final r in rows) r.badgeId: r};
    final days = ref.watch(hazriDayCountProvider).value ?? 0;

    return HazriScreen(
      title: l.badgesTitle,
      subtitle: l.badgesSummary(rows.length, days),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
          children: [
            for (final b in BadgeId.values)
              HazriCard(
                colour: byId[b.id] == null ? c.card2 : null,
                padding: const EdgeInsets.all(12),
                onTap: () => context.push(Routes.badge(b.id)),
                child: Column(
                  children: [
                    BadgeEmblem(badge: b, earned: byId[b.id] != null),
                    const SizedBox(height: 6),
                    Text(b.nameFor(l.localeName),
                        style: HazriText.gurmukhi(16).copyWith(color: byId[b.id] != null ? c.ink : c.muted)),
                    Text(b.latin,
                        style: HazriText.bodyStrong.copyWith(color: byId[b.id] != null ? c.ink : c.muted)),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Text(l.badgeRule(b),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: HazriText.caption.copyWith(color: c.muted)),
                    ),
                    Text(
                      byId[b.id] == null ? l.badgeNotYet : earnedLine(context, byId[b.id]!),
                      style: HazriText.captionStrong.copyWith(color: byId[b.id] == null ? c.muted : c.kesri),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// UI4, design 97: one badge in full, with the previous and next by name.
class BadgeDetailScreen extends ConsumerWidget {
  const BadgeDetailScreen({super.key, required this.badgeId});

  final String badgeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final b = BadgeId.byId(badgeId) ?? BadgeId.jigyasu;
    final row = (ref.watch(earnedBadgesProvider).value ?? const <BadgeRow>[])
        .where((r) => r.badgeId == b.id)
        .firstOrNull;
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    // NITNEMI: the five names from content.db (rule 3), never the ARB file.
    final morning = banis.where((x) => x.defaultSlot == BaniSlot.morning).map((x) => x.name(l.localeName)).join(', ');
    final prev = b.index > 0 ? BadgeId.values[b.index - 1] : null;
    final next = b.index < BadgeId.values.length - 1 ? BadgeId.values[b.index + 1] : null;

    Widget block(String title, String body) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: HazriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(title),
                const SizedBox(height: 6),
                Text(body, style: HazriText.body.copyWith(color: c.ink2)),
              ],
            ),
          ),
        );

    return HazriScreen(
      title: l.badgeNumber(b.number),
      children: [
        const SizedBox(height: 12),
        Center(child: BadgeEmblem(badge: b, earned: row != null, size: 128)),
        const SizedBox(height: 12),
        Center(child: Text(b.nameFor(l.localeName), style: HazriText.gurmukhi(26).copyWith(color: c.ink))),
        Center(child: Text(b.latin, style: HazriText.display22.copyWith(color: c.ink2, fontSize: 18))),
        const SizedBox(height: 8),
        Center(
          child: HazriChip(
            label: row == null ? l.badgeNotYet : earnedLine(context, row),
            background: row == null ? c.card2 : c.kesriSoft,
            foreground: row == null ? c.muted : c.kesriInk,
          ),
        ),
        block(l.badgeWhatItMarks, l.badgeMarks(b)),
        block(l.badgeHowEarned, l.badgeHow(b, morningBanis: morning)),
        const SizedBox(height: 16),
        Row(
          children: [
            if (prev != null)
              TextButton(onPressed: () => context.pushReplacement(Routes.badge(prev.id)), child: Text('← ${prev.latin}')),
            const Spacer(),
            if (next != null)
              TextButton(onPressed: () => context.pushReplacement(Routes.badge(next.id)), child: Text('${next.latin} →')),
          ],
        ),
      ],
    );
  }
}
