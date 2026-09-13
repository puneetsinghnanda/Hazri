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

final _overridesProvider = FutureProvider<Map<String, bool>>(
  (ref) => ref.watch(userRepositoryProvider).eventOverrides(),
);

/// Gurpurabs and the Nanakshahi date (Design 22).
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

    final upcoming = events
        .where((e) => !DateTime.parse(e.date).isBefore(today))
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

    final name = switch (lang) {
      'pa' => event.namePa,
      'hi' => event.nameHi,
      _ => event.nameEn,
    };

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
                  if (lang != 'pa')
                    Text(
                      event.namePa,
                      style: HazriText.gurmukhi(13).copyWith(color: c.muted, height: 1.5),
                    ),
                  if (event.nsLabel != null)
                    Text(
                      event.nsLabel!,
                      style: HazriText.caption.copyWith(color: c.muted),
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
