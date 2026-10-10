import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../../audio/data/notification_access.dart';
import '../../sangat/data/sangat_controller.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/notification_switches.dart';
import '../data/reminders_controller.dart';
import '../domain/reminder_plan.dart';
import 'exact_alarm_card.dart';

export 'exact_alarm_card.dart' show exactAlarmsAllowedProvider;

/// Design 50, as 02-notifications §9 has it: one switch per kind, the
/// permission card, the exact-alarm note and the way into diagnostics.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final allowed = ref.watch(notificationsAllowedProvider).value ?? true;
    final on = ref.watch(notificationSwitchesProvider);
    final member = ref.watch(sangatMemberProvider);

    Widget row(NotificationKind kind, String title, String subtitle) => SettingsRow(
          title: title,
          subtitle: subtitle,
          trailing: Switch(
            value: on.contains(kind),
            onChanged: (v) async {
              await ref.read(notificationSwitchesProvider.notifier).set(kind, v);
              await ref.read(reminderSchedulerProvider).reschedule();
            },
          ),
        );

    return HazriScreen(
      title: l.notifTitle,
      children: [
        if (!allowed) ...[
          const _Blocked(),
          const SizedBox(height: 12),
        ],
        SettingsSection(
          title: l.notifKindsHeading,
          children: [
            row(NotificationKind.amritVela, l.notifKindAmritVela, l.notifKindAmritVelaSub),
            row(NotificationKind.goalBani, l.notifKindGoals, l.notifKindGoalsSub),
            row(NotificationKind.calendar, l.notifKindCalendar, l.notifKindCalendarSub),
            row(NotificationKind.hazriNudge, l.notifKindHazri, l.notifKindHazriSub),
            if (member) row(NotificationKind.sangat, l.notifKindSangat, l.notifKindSangatSub),
          ],
        ),
        const ExactAlarmCard(padding: EdgeInsets.only(top: 12)),
        SettingsSection(
          title: l.notifDiagnostics,
          children: [
            SettingsRow(
              title: l.notifDiagnostics,
              subtitle: l.notifDiagnosticsSub,
              onTap: () => context.push(Routes.notificationDiagnostics),
            ),
          ],
        ),
        const SizedBox(height: 14),
        HazriCard(
          colour: c.card2,
          child: Text(l.notifNoAds, style: HazriText.bodySmall.copyWith(color: c.ink2)),
        ),
      ],
    );
  }
}

/// DP3: Android is not letting anything through. Tapping asks; once Android
/// has recorded a refusal it opens the app's notification settings.
class _Blocked extends ConsumerWidget {
  const _Blocked();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    return HazriCard(
      colour: c.kesriSoft,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.notificationRationale, style: HazriText.body.copyWith(color: c.kesriInk)),
          const SizedBox(height: 12),
          PrimaryButton(
            label: l.actionAllow,
            onPressed: () async {
              final ok = await ref.read(notificationsAllowedProvider.notifier).allow();
              if (ok) await ref.read(reminderSchedulerProvider).reschedule();
            },
          ),
        ],
      ),
    );
  }
}
