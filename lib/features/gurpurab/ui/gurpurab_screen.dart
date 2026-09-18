import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../domain/calendar_display.dart';

final _overridesProvider = FutureProvider<Map<String, bool>>(
  (ref) => ref.watch(userRepositoryProvider).eventOverrides(),
);

/// Whether the list is showing the whole calendar or only the Gurpurabs.
///
/// The bundled year carries 147 entries -- shaheedi divas, jorh melas,
/// historical days and every Sangrand, Puranmashi and Masya alongside the
/// Gurpurabs. All of it is worth having and none of it should bury the days
/// most people open this screen for, so the list starts on Gurpurabs.
final _gurpurabsOnlyProvider = StateProvider<bool>((ref) => true);

/// The Sikh calendar and today's Nanakshahi date (Design 22).
///
/// Dates come only from the bundled SGPC jantri; a date the shipped data does
/// not cover says so rather than showing a computed guess (PRD 1.14).
class GurpurabScreen extends ConsumerWidget {
  const GurpurabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final dates = HazriDates.of(context);
    final today = ref.watch(clockProvider).today();
    final calendar = ref.watch(nanakshahiCalendarProvider).value;
    final events = ref.watch(calendarEventsProvider).value ?? const <CalendarEventRow>[];
    final overrides = ref.watch(_overridesProvider).value ?? const <String, bool>{};

    final gurpurabsOnly = ref.watch(_gurpurabsOnlyProvider);
    final upcoming = events
        .where((e) => !DateTime.parse(e.date).isBefore(today))
        .where((e) => !gurpurabsOnly || e.isGurpurab)
        .toList();
    final thisWeek = upcoming
        .where((e) => DateTime.parse(e.date).difference(today).inDays <= 7)
        .toList();
    final later = upcoming
        .where((e) => DateTime.parse(e.date).difference(today).inDays > 7)
        .toList();

    final ns = calendar?.dateFor(today);

    return HazriScreen(
      title: l.gurpurabTitle,
      children: [
        HazriCard(
          colour: c.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.gurpurabTodayNanakshahi,
                style: HazriText.eyebrow.copyWith(
                  color: c.onPrimary.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ns?.labelWithYear(lang) ?? l.gurpurabNoData,
                style: HazriText.display26.copyWith(color: c.onPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                dates.longDateWithYear(today),
                style: HazriText.bodySmall.copyWith(
                  color: c.onPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        if (ns == null && calendar != null && !calendar.isEmpty) ...[
          const SizedBox(height: 10),
          HazriCard(
            colour: c.card2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              l.gurpurabNoDataBody(
                dates.shortDate(calendar.coveredFrom!),
                dates.shortDate(calendar.coveredToInclusive!),
              ),
              style: HazriText.bodySmall.copyWith(color: c.ink2),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            AppIcon(HazriIconData.bell, size: 16, color: c.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.gurpurabRemindersLine,
                style: HazriText.caption.copyWith(color: c.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _FilterChips(
          gurpurabsOnly: gurpurabsOnly,
          onChanged: (v) => ref.read(_gurpurabsOnlyProvider.notifier).state = v,
        ),
        const SizedBox(height: 16),
        if (thisWeek.isNotEmpty) ...[
          Eyebrow(l.gurpurabThisWeek),
          const SizedBox(height: 8),
          for (final e in thisWeek)
            _EventRow(event: e, today: today, overrides: overrides),
          const SizedBox(height: 16),
        ],
        if (later.isNotEmpty) ...[
          Eyebrow(l.gurpurabComingUp),
          const SizedBox(height: 8),
          for (final e in later) _EventRow(event: e, today: today, overrides: overrides),
        ],
        if (upcoming.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Text(
              l.gurpurabNoneUpcoming,
              textAlign: TextAlign.center,
              style: HazriText.body.copyWith(color: c.muted),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          l.gurpurabFooter,
          textAlign: TextAlign.center,
          style: HazriText.caption.copyWith(color: c.muted),
        ),
      ],
    );
  }
}

class _EventRow extends ConsumerWidget {
  const _EventRow({required this.event, required this.today, required this.overrides});

  final CalendarEventRow event;
  final DateTime today;
  final Map<String, bool> overrides;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final dates = HazriDates.of(context);
    final date = DateTime.parse(event.date);
    final days = date.difference(today).inDays;
    final reminding = overrides[event.id] ?? event.defaultRemind;

    final name = event.nameFor(lang);
    final gurmukhi = event.gurmukhiUnder(lang);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HazriCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: c.card2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    dates.monthAbbrUpper(date),
                    style: HazriText.caption.copyWith(fontSize: 10, color: c.muted),
                  ),
                  Text('${date.day}', style: HazriText.display22.copyWith(color: c.ink)),
                  Text(
                    dates.weekdayAbbr(date),
                    style: HazriText.caption.copyWith(fontSize: 10, color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: HazriText.bodyStrong.copyWith(color: c.ink),
                        ),
                      ),
                      if (days <= 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.kesriSoft,
                            borderRadius: BorderRadius.circular(HazriRadius.chip),
                          ),
                          child: Text(
                            days == 0 ? l.today : l.tomorrow,
                            style: HazriText.caption.copyWith(
                              fontSize: 11,
                              color: c.kesriInk,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (gurmukhi != null)
                    Text(
                      gurmukhi,
                      style: HazriText.gurmukhi(13).copyWith(color: c.muted, height: 1.5),
                    ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Tag(calendarKindLabel(l, event.kind)),
                      if (event.nsLabel != null)
                        Text(
                          event.nsLabel!,
                          style: HazriText.caption.copyWith(color: c.muted),
                        ),
                      if (event.supplementary)
                        Text(
                          l.gurpurabSupplementary,
                          style: HazriText.caption.copyWith(color: c.muted),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l.reminderGurpurabDays,
              onPressed: () async {
                await ref
                    .read(userRepositoryProvider)
                    .setEventOverride(event.id, !reminding);
                ref.invalidate(_overridesProvider);
              },
              icon: AppIcon(
                reminding ? HazriIconData.bell : HazriIconData.noSound,
                size: 20,
                color: reminding ? c.kesriInk : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// All days, or only the Gurpurabs.
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.gurpurabsOnly, required this.onChanged});

  final bool gurpurabsOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Row(
      children: [
        _Chip(
          label: l.gurpurabFilterGurpurabsOnly,
          selected: gurpurabsOnly,
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: l.gurpurabFilterAll,
          selected: !gurpurabsOnly,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HazriRadius.chip),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.kesriSoft : c.card2,
          borderRadius: BorderRadius.circular(HazriRadius.chip),
          border: Border.all(color: selected ? c.kesriInk : c.card2),
        ),
        child: Text(
          label,
          style: HazriText.caption.copyWith(
            color: selected ? c.kesriInk : c.muted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// The document's Type column, shown so the stored type is visible rather
/// than only filterable.
class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: c.card2,
        borderRadius: BorderRadius.circular(HazriRadius.chip),
      ),
      child: Text(
        label,
        style: HazriText.caption.copyWith(fontSize: 10.5, color: c.ink2),
      ),
    );
  }
}
