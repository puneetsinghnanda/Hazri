import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/user_db.dart' show BadgeRow;
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/badge_controller.dart';
import '../domain/badges.dart';
import 'badge_text.dart';

/// A badge's emblem (designs 95–99): kesri with a white mark when earned,
/// outlined grey when not. No meter, ever (UI3).
class BadgeEmblem extends StatelessWidget {
  const BadgeEmblem({super.key, required this.badge, required this.earned, this.size = 56, this.ring = false});

  final BadgeId badge;
  final bool earned;
  final double size;

  /// The new one, ringed in the sheet's row (AN1).
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = earned ? '#ffffff' : '#${(c.muted.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: earned
            ? const RadialGradient(
                center: Alignment(-0.3, -0.4),
                colors: [Color(0xFFF7B76A), Color(0xFFD9730D)],
              )
            : null,
        color: earned ? null : c.card2,
        border: ring
            ? Border.all(color: c.kesri, width: 2.5)
            : earned
                ? Border.all(color: c.kesriSoft, width: size > 60 ? 5 : 3)
                : Border.all(color: c.rule, width: 1.5),
      ),
      alignment: Alignment.center,
      child: SvgPicture.string(
        '<svg viewBox="0 0 24 24" fill="none" stroke="$ink" stroke-width="1.8" '
        'stroke-linecap="round" stroke-linejoin="round"><path d="${badge.emblemPath}"/></svg>',
        width: size * 0.48,
        height: size * 0.48,
      ),
    );
  }
}

/// Earned ids, from the live rows.
Set<BadgeId> earnedIds(List<BadgeRow> rows) =>
    {for (final r in rows) BadgeId.byId(r.badgeId)}.whereType<BadgeId>().toSet();

/// The ten in a row, earned in kesri, the rest outlined (UI5, UI6, AN1).
class BadgeRow10 extends ConsumerWidget {
  const BadgeRow10({super.key, this.size = 26, this.ringed, this.onTap});

  final double size;
  final BadgeId? ringed;
  final void Function(BadgeId)? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earned = earnedIds(ref.watch(earnedBadgesProvider).value ?? const []);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final b in BadgeId.values)
          GestureDetector(
            onTap: onTap == null ? null : () => onTap!(b),
            child: BadgeEmblem(badge: b, earned: earned.contains(b), size: size, ring: b == ringed),
          ),
      ],
    );
  }
}

/// AN1, design 95: one quiet sheet; Done, or See all badges.
Future<void> showBadgeEarnedSheet(BuildContext context, BadgeId badge) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) {
        final c = sheet.colors;
        final l = L.of(sheet);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BadgeEmblem(badge: badge, earned: true, size: 84),
                const SizedBox(height: 12),
                Eyebrow(l.badgeEarnedNew),
                const SizedBox(height: 4),
                Text(badge.latin, style: HazriText.display22.copyWith(color: c.ink)),
                Text(badge.nameFor(l.localeName), style: HazriText.gurmukhi(18).copyWith(color: c.ink2)),
                const SizedBox(height: 8),
                Text('${l.badgeMarks(badge)} · ${l.badgeRule(badge)}',
                    textAlign: TextAlign.center, style: HazriText.bodySmall.copyWith(color: c.ink2)),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final n = (ref.watch(earnedBadgesProvider).value ?? const []).length;
                    return Row(
                      children: [
                        Text(l.badgeEarnedYours, style: HazriText.captionStrong.copyWith(color: c.ink)),
                        const Spacer(),
                        Text(l.badgesMenuCount(n), style: HazriText.caption.copyWith(color: c.muted)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                BadgeRow10(ringed: badge),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: l.badgeEarnedDone,
                        secondary: true,
                        onPressed: () => Navigator.of(sheet).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: l.badgeEarnedSee,
                        onPressed: () {
                          Navigator.of(sheet).pop();
                          context.push(Routes.badges);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

/// UI5, design 100 (owner 2026-10-10, replacing 98): the profile's Badges
/// card. All ten stand five to a row on two shelves, with their names,
/// earned in kesri and the rest grey; a tap opens the badge (UI4), "See all
/// 10" the Badges page (UI2).
class ProfileBadgesSection extends ConsumerWidget {
  const ProfileBadgesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final earned = earnedIds(ref.watch(earnedBadgesProvider).value ?? const []);

    Widget cell(BadgeId b) {
      final on = earned.contains(b);
      return Semantics(
        button: true,
        label: on ? b.latin : '${b.latin}, ${l.badgeNotYet}',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push(Routes.badge(b.id)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BadgeEmblem(badge: b, earned: on, size: 46),
                const SizedBox(height: 4),
                // One line, held to one height, so the names line up on the
                // shelf even where a long one is scaled down to fit.
                SizedBox(
                  height: 15,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      b.latin,
                      maxLines: 1,
                      style: HazriText.caption.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: on ? c.ink : c.ink2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget shelf(List<BadgeId> row) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < row.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(child: cell(row[i])),
                  ],
                ],
              ),
            ),
            // The shelf the five stand on.
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.card2, Color.alphaBlend(c.ink.withValues(alpha: 0.06), c.card2)],
                ),
                boxShadow: const [BoxShadow(color: Color(0x141B1D3A), blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: const SizedBox(height: 8),
            ),
          ],
        );

    const all = BadgeId.values;
    return HazriCard(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.badgesTitle, style: HazriText.bodyStrong.copyWith(color: c.ink, fontSize: 16)),
              ),
              TextButton(
                onPressed: () => context.push(Routes.badges),
                style: TextButton.styleFrom(
                  foregroundColor: c.kesriInk,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(
                  l.badgesSeeAll,
                  style: HazriText.bodySmall.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: c.kesriInk),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          shelf(all.sublist(0, 5)),
          const SizedBox(height: 10),
          shelf(all.sublist(5)),
        ],
      ),
    );
  }
}

/// "Earned 8 Oct 2026".
String earnedLine(BuildContext context, BadgeRow row) =>
    L.of(context).badgeEarnedOn(HazriDates.of(context).shortDate(parseLocalDateKey(row.earnedOn)));
