import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/hazri_controller.dart';
import '../domain/hazri.dart';

/// Designs 58 and 59 — whether you have turned up today.
///
/// This is what the app is named after. Hazri is marked by **one** paath or
/// **one** sitting of simran; it is not the goal, and a day with one bani
/// read is a day somebody was present, whatever else was on the list.
///
/// It is shown to everybody. It used to be behind `hasJoinedSangat`, to keep
/// it from stacking under the join banner -- which meant the one thing the
/// app is named after was invisible to everybody who had not joined the
/// sangat, and rule 4 says the sangat is opt-in. Somebody who never joins
/// reads, listens, keeps a diary and marks their hazri, and now sees it.
///
/// Once marked it can be closed for the rest of the day (05-today T1a, owner
/// 2026-10-10): it folds away and the cards below move up. It comes back the
/// next morning, unmarked, and it can never be closed before it is marked.
class HazriBanner extends ConsumerWidget {
  const HazriBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hazri = ref.watch(hazriTodayProvider);
    final today = localDateKey(ref.watch(clockProvider).now());
    final closed = hazri.isMarked && ref.watch(hazriBannerClosedProvider) == today;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, alignment: Alignment.topCenter, child: child),
      ),
      child: closed
          ? const SizedBox(key: ValueKey('closed'), width: double.infinity)
          : _Banner(
              key: const ValueKey('open'),
              hazri: hazri,
              onClose: hazri.isMarked
                  ? () => ref.read(hazriBannerClosedProvider.notifier).close(today)
                  : null,
            ),
    );
  }
}

/// The day a marked banner was closed on (`hazri_banner_closed_v1`, a local
/// date key), or null.
class HazriBannerClosed extends Notifier<String?> {
  static const key = 'hazri_banner_closed_v1';

  @override
  String? build() => ref.read(sharedPreferencesProvider).getString(key);

  Future<void> close(String day) async {
    state = day;
    await ref.read(sharedPreferencesProvider).setString(key, day);
  }
}

final hazriBannerClosedProvider =
    NotifierProvider<HazriBannerClosed, String?>(HazriBannerClosed.new);

class _Banner extends ConsumerWidget {
  const _Banner({super.key, required this.hazri, this.onClose});

  final Hazri hazri;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
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
            if (onClose != null)
              IconButton(
                onPressed: onClose,
                tooltip: l.actionClose,
                visualDensity: VisualDensity.compact,
                icon: AppIcon(HazriIconData.close, size: 18, color: c.sage),
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
