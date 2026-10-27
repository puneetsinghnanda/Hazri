import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/time/clock.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/saakhi_repository.dart';
import '../domain/saakhi.dart';

/// Design 111 (SK11): every saakhi as a card, the Punjabi name above the
/// English, the page count, the narration and its length.
class SaakhiLibraryScreen extends ConsumerWidget {
  const SaakhiLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final saakhis = ref.watch(saakhisProvider).value ?? const <Saakhi>[];
    final favourites = ref.watch(saakhiFavouritesProvider).value ?? const <String>{};
    return HazriScreen(
      title: l.saakhiTitle,
      subtitle: l.saakhiLibrarySubtitle,
      children: [
        const SizedBox(height: 8),
        if (saakhis.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text(
              l.saakhiEmpty,
              textAlign: TextAlign.center,
              style: HazriText.body.copyWith(color: c.muted),
            ),
          ),
        for (final s in saakhis)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SaakhiCard(saakhi: s, favourite: favourites.contains(s.id)),
          ),
      ],
    );
  }
}

class SaakhiCard extends StatelessWidget {
  const SaakhiCard({super.key, required this.saakhi, this.favourite = false});

  final Saakhi saakhi;
  final bool favourite;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final punjabi = saakhi.narrationIn('pa') != null;
    final narrated = punjabi || saakhi.narrationIn('en') != null;
    return HazriCard(
      padding: const EdgeInsets.all(10),
      onTap: () => context.push(Routes.saakhi(saakhi.id)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              saakhi.cover,
              width: 78,
              height: 118,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(width: 78, height: 118, color: c.card2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        saakhi.title.of('pa'),
                        style: HazriText.gurmukhi(14).copyWith(color: c.ink2, height: 1.35),
                      ),
                    ),
                    if (favourite) const Icon(Icons.favorite, size: 16, color: Color(0xFFE0574A)),
                  ],
                ),
                Text(
                  saakhi.title.of('en'),
                  style: HazriText.display22.copyWith(color: c.ink, fontSize: 17, height: 1.2),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    l.saakhiPages(saakhi.pageCount),
                    punjabi
                        ? l.saakhiNarrationPunjabi
                        : narrated
                        ? l.saakhiNarrationEnglish
                        : l.saakhiNarrationComing,
                  ].join(' · '),
                  style: HazriText.caption.copyWith(color: c.muted, fontSize: 12.5),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (narrated)
                      HazriChip(
                        label: '${l.saakhiListen} · ${l.saakhiMinutes(saakhi.minutes)}',
                        background: c.kesriSoft,
                        foreground: c.kesriInk,
                        minHeight: 40,
                        onTap: () => context.push(Routes.saakhi(saakhi.id, listen: true)),
                      ),
                    HazriChip(
                      label: l.saakhiReadShort,
                      background: c.card2,
                      foreground: c.ink2,
                      minHeight: 40,
                      onTap: () => context.push(Routes.saakhi(saakhi.id)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's saakhis, option C (owner, 2026-10-27, replacing the bare row of
/// 1A): one card with "Saakhis" and See all, the day's saakhi large with its
/// cover, Punjabi and English names, Listen and Read, then the others as
/// small covers under "More saakhis". The day's saakhi turns by date, the
/// same on every phone (SK11).
class SaakhiTodayRow extends ConsumerWidget {
  const SaakhiTodayRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final c = context.colors;
    final saakhis = ref.watch(saakhisProvider).value ?? const <Saakhi>[];
    if (saakhis.isEmpty) return const SizedBox.shrink();
    final today = ref.watch(clockProvider).today();
    final days = DateTime.utc(today.year, today.month, today.day).difference(DateTime.utc(1970)).inDays;
    final featured = saakhis[days % saakhis.length];
    final rest = [
      for (final s in saakhis)
        if (s.id != featured.id) s,
    ];
    return HazriCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.saakhiTitle, style: HazriText.display22.copyWith(color: c.ink, fontSize: 18)),
              ),
              TextButton(
                onPressed: () => context.push(Routes.saakhis),
                style: TextButton.styleFrom(foregroundColor: c.kesriInk, minimumSize: const Size(44, 44)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.saakhiSeeAll, style: HazriText.captionStrong.copyWith(color: c.kesriInk, fontSize: 13)),
                    AppIcon(HazriIconData.chevronRight, size: 14, color: c.kesriInk),
                  ],
                ),
              ),
            ],
          ),
          _Featured(saakhi: featured),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(l.saakhiMore.toUpperCase(), style: HazriText.eyebrow.copyWith(color: c.muted)),
            const SizedBox(height: 8),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: rest.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, i) => _CoverCard(saakhi: rest[i], width: 86, small: true),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The day's saakhi on Today's card (option C): its cover, then "Today's
/// saakhi", the Punjabi name, the English name, the Punjabi subtitle, and
/// Listen and Read (SK9a: Punjabi first).
class _Featured extends StatelessWidget {
  const _Featured({required this.saakhi});

  final Saakhi saakhi;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final narrated = saakhi.narration.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.push(Routes.saakhi(saakhi.id)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              saakhi.cover,
              width: 100,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(width: 100, height: 150, color: c.card2),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.saakhiOfTheDay.toUpperCase(), style: HazriText.eyebrow.copyWith(color: c.kesriInk)),
                const SizedBox(height: 4),
                Text(saakhi.title.of('pa'), style: HazriText.gurmukhi(17).copyWith(color: c.ink, height: 1.35)),
                Text(
                  saakhi.title.of('en'),
                  style: HazriText.display22.copyWith(color: c.ink2, fontSize: 15, height: 1.2),
                ),
                if (saakhi.subtitle.has('pa')) ...[
                  const SizedBox(height: 2),
                  Text(
                    saakhi.subtitle.of('pa'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: HazriText.gurmukhi(12.5, weight: FontWeight.w400).copyWith(color: c.muted, height: 1.4),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (narrated) ...[
                      Expanded(
                        child: PrimaryButton(
                          label: l.saakhiListen,
                          minHeight: 40,
                          onPressed: () => context.push(Routes.saakhi(saakhi.id, listen: true)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: PrimaryButton(
                        label: l.saakhiReadShort,
                        secondary: true,
                        minHeight: 40,
                        onPressed: () => context.push(Routes.saakhi(saakhi.id)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.saakhi, this.width = 118, this.small = false});

  final Saakhi saakhi;
  final double width;

  /// The "More saakhis" size on Today's card: smaller type, the chip kept.
  final bool small;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Semantics(
      button: true,
      label: saakhi.title.of('en'),
      child: GestureDetector(
        onTap: () => context.push(Routes.saakhi(saakhi.id)),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0x291B1D3A), blurRadius: 18, offset: Offset(0, 8))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                saakhi.cover,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF262C63)),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.45, 1],
                    colors: [Color(0x000C0F24), Color(0xE00C0F24)],
                  ),
                ),
              ),
              if (saakhi.minutes > 0)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0x8C0C0F24), borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 12, color: Colors.white),
                        Text(
                          l.saakhiMinutes(saakhi.minutes),
                          style: HazriText.captionStrong.copyWith(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 9,
                right: 9,
                bottom: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saakhi.title.of('pa'),
                      maxLines: 2,
                      style: HazriText.gurmukhi(
                        small ? 10 : 11.5,
                      ).copyWith(color: Colors.white.withValues(alpha: 0.85), height: 1.3),
                    ),
                    Text(
                      saakhi.title.of('en'),
                      maxLines: 3,
                      style: HazriText.bodyStrong.copyWith(color: Colors.white, fontSize: small ? 11 : 13, height: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
