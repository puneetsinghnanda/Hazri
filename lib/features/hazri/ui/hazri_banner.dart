import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../sangat/data/account_repository.dart';
import '../data/hazri_controller.dart';
import '../domain/hazri.dart';

/// Designs 58 and 59 — whether you have turned up today.
///
/// This is what the app is named after. Hazri is marked by **one** paath or
/// **one** sitting of simran; it is not the goal, and a day with one bani
/// read is a day somebody was present, whatever else was on the list.
///
/// It appears only once the sangat setup is done, which is the reader's own
/// constraint: before that, Today already carries the join banner, and two
/// banners stacked is two things shouting at somebody who came to read.
class HazriBanner extends ConsumerWidget {
  const HazriBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(hasJoinedSangatProvider)) return const SizedBox.shrink();

    final c = context.colors;
    final l = L.of(context);
    final hazri = ref.watch(hazriTodayProvider);
    final marked = hazri.isMarked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HazriCard(
        colour: marked ? c.sageSoft : c.card2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: marked ? c.sage.withValues(alpha: 0.18) : c.card,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AppIcon(
                marked ? HazriIconData.check : HazriIconData.sunArc,
                size: 20,
                color: marked ? c.sage : c.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    marked ? l.hazriMarked : l.hazriNotYet,
                    style: HazriText.bodyStrong
                        .copyWith(color: marked ? c.sage : c.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    marked ? hazriLine(context, ref, hazri) : l.hazriHow,
                    style: HazriText.caption.copyWith(color: c.ink2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Marked at 5:52 AM, with Japji Sahib".
///
/// The bani's name comes from the content database and is never typed here
/// (CLAUDE.md rule 3). Until it has loaded, or for a bani this build does not
/// carry, the time alone is said rather than a slug or a guess.
String hazriLine(BuildContext context, WidgetRef ref, Hazri hazri) {
  final l = L.of(context);
  final at = hazri.markedAt;
  if (at == null) return l.hazriHow;
  final time = HazriDates.of(context).time(at);

  if (hazri.bySimran) return l.hazriMarkedAtWith(time, l.hazriSimran);

  final banis = ref.watch(banisProvider).value;
  final bani = banis?.where((b) => b.id == hazri.baniId).firstOrNull;
  if (bani == null) return l.hazriMarkedAt(time);
  return l.hazriMarkedAtWith(time, bani.name(l.localeName));
}
