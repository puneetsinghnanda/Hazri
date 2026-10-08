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

/// UI5, design 98: the profile's Badges section, all ten five to a row.
class ProfileBadgesSection extends ConsumerWidget {
  const ProfileBadgesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final earned = earnedIds(ref.watch(earnedBadgesProvider).value ?? const []);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: HazriCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(l.badgesTitle, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                const Spacer(),
                TextButton(onPressed: () => context.push(Routes.badges), child: Text(l.badgesSeeAll)),
              ],
            ),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.72,
              children: [
                for (final b in BadgeId.values)
                  InkWell(
                    onTap: () => context.push(Routes.badge(b.id)),
                    child: Column(
                      children: [
                        BadgeEmblem(badge: b, earned: earned.contains(b), size: 46),
                        const SizedBox(height: 4),
                        Text(b.latin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HazriText.caption.copyWith(
                                fontSize: 10.5, color: earned.contains(b) ? c.ink : c.muted)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Earned 8 Oct 2026".
String earnedLine(BuildContext context, BadgeRow row) =>
    L.of(context).badgeEarnedOn(HazriDates.of(context).shortDate(parseLocalDateKey(row.earnedOn)));
