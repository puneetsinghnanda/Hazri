import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/reminder_service.dart';
import '../data/reminders_controller.dart';

/// Whether Android lets Hazri deliver to the minute (DP2). Read again every
/// time the app comes back, so the card goes the moment it is allowed.
final exactAlarmsAllowedProvider = FutureProvider<bool>(
  (ref) => ref.read(reminderServiceProvider).canScheduleExact(),
);

/// DP2 (2026-10-10): asks for Android's "Alarms & reminders".
///
/// Without it every reminder is an inexact alarm, which Android may hold back
/// by up to three quarters of the wait (a 15:30 reminder planned in the
/// morning can come in the evening) and never by less than ten minutes. The
/// owner set a 15:30 reminder and the two-minute test and received neither.
/// Shown only while it is not allowed; empty otherwise.
class ExactAlarmCard extends ConsumerWidget {
  const ExactAlarmCard({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exact = ref.watch(exactAlarmsAllowedProvider).value ?? true;
    if (exact) return const SizedBox.shrink();
    final c = context.colors;
    final l = L.of(context);
    return Padding(
      padding: padding,
      child: HazriCard(
        colour: c.kesriSoft,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(HazriIconData.clock, size: 20, color: c.kesriInk),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l.notifExactNote, style: HazriText.bodySmall.copyWith(color: c.kesriInk)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: l.notifExactAllow,
              onPressed: () async {
                await ref.read(reminderServiceProvider).requestExactAlarms();
                ref.invalidate(exactAlarmsAllowedProvider);
                await ref.read(reminderSchedulerProvider).reschedule();
              },
            ),
          ],
        ),
      ),
    );
  }
}
