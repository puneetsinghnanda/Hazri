import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/surfaces.dart';
import '../../audio/data/notification_access.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/reminder_service.dart';
import '../data/reminders_controller.dart';
import '../domain/reminder_plan.dart';

/// What the phone says, so a report is "here is what Android says" rather
/// than "it does not work" (02-notifications DP4).
@immutable
class _Diagnosis {
  const _Diagnosis({
    required this.allowed,
    required this.exact,
    required this.batteryExempt,
    required this.pending,
    required this.next,
    required this.last,
  });

  final bool allowed;
  final bool exact;
  final bool? batteryExempt;
  final int pending;
  final List<PlannedNotification> next;
  final String? last;
}

final _diagnosisProvider = FutureProvider.autoDispose<_Diagnosis>((ref) async {
  final service = ref.read(reminderServiceProvider);
  final now = ref.read(clockProvider).now();
  return _Diagnosis(
    allowed: await service.notificationsAllowed(),
    exact: await service.canScheduleExact(),
    batteryExempt: await ref.read(systemSettingsProvider).ignoringBatteryOptimizations(),
    pending: await service.pendingCount(),
    next: [for (final n in service.lastPlan) if (n.at.isAfter(now)) n].take(3).toList(),
    last: await service.lastShownTitle(),
  );
});

class NotificationDiagnosticsScreen extends ConsumerWidget {
  const NotificationDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final d = ref.watch(_diagnosisProvider).value;
    final dates = HazriDates.of(context);
    String yesNo(bool? v) => v == null ? '—' : (v ? l.yes : l.no);

    Future<void> send({Duration? after}) async {
      final scheduler = ref.read(reminderSchedulerProvider);
      final names = ReminderScheduler.channelNames(l);
      await ref.read(reminderServiceProvider).sendTest(
            PlannedNotification(
              reminderId: 'diagnostic',
              kind: NotificationKind.amritVela,
              at: ref.read(clockProvider).now().add(after ?? Duration.zero),
              title: l.notifDiagTestTitle,
              body: l.notifDiagTestBody,
              route: '/notifications',
            ),
            names[NotificationKind.amritVela]!,
            after: after,
          );
      scheduler.requestReschedule();
      ref.invalidate(_diagnosisProvider);
    }

    return HazriScreen(
      title: l.notifDiagnostics,
      children: [
        SettingsSection(
          title: l.notifDiagnosticsSub,
          children: [
            SettingsRow(title: l.notifDiagAllowed, value: yesNo(d?.allowed)),
            SettingsRow(title: l.notifDiagExact, value: yesNo(d?.exact)),
            SettingsRow(title: l.notifDiagBattery, value: yesNo(d?.batteryExempt)),
            SettingsRow(title: l.notifDiagPending, value: '${d?.pending ?? '—'}'),
            SettingsRow(title: l.notifDiagLast, value: d?.last ?? '—'),
          ],
        ),
        SettingsSection(
          title: l.notifDiagNext,
          children: [
            if (d == null || d.next.isEmpty)
              SettingsRow(title: l.notifDiagNone)
            else
              for (final n in d.next)
                SettingsRow(
                  title: n.title,
                  subtitle: '${dates.shortDate(n.at)} · ${dates.time(n.at)}',
                ),
          ],
        ),
        const SizedBox(height: 12),
        PrimaryButton(label: l.notifDiagSendNow, onPressed: () => send()),
        const SizedBox(height: 10),
        PrimaryButton(
          label: l.notifDiagSendSoon,
          onPressed: () => send(after: const Duration(minutes: 2)),
        ),
        const SizedBox(height: 10),
        Text(l.notifNoAds, style: HazriText.caption.copyWith(color: c.muted)),
      ],
    );
  }
}
