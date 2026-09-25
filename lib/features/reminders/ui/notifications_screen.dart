import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/user_db.dart' show Reminder;
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/surfaces.dart';
import '../../audio/data/notification_access.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/reminders_controller.dart';
import '../domain/reminder_plan.dart';
import 'reminder_row.dart';

/// Design 50 — every notification Hazri can send, in one place.
///
/// The split down the middle is the honest part. **Your own practice** is set
/// by this phone: the alarms are scheduled locally, they arrive with the
/// radio off, and they are the ones that matter to somebody keeping a nitnem.
/// **Your groups** and **Global Simran** need a message pushed from a server,
/// and Phase 2 has no server that can send one — Spark has no Cloud
/// Functions. They are shown, switched off and unavailable, rather than
/// pretending to work or being hidden as though they were never planned.
/// Android is not letting any of this through.
///
/// Shown above the list rather than instead of it, so the reminders somebody
/// set are still visible and still theirs -- they simply cannot arrive yet.
/// Tapping asks for the permission, and once Android has recorded a refusal
/// it opens the app's notification settings, which is then the only way back.
class _Blocked extends ConsumerWidget {
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
          Text(
            l.notificationRationale,
            style: HazriText.body.copyWith(color: c.kesriInk),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: l.actionAllow,
            onPressed: () =>
                ref.read(notificationsAllowedProvider.notifier).allow(),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];
    // Whether Android will show any of this at all. Everything below is a
    // list of reminders that cannot arrive while this is false, and the screen
    // used to list them anyway -- which is how a phone stayed silent for days
    // with a page of switches saying otherwise.
    final allowed = ref.watch(notificationsAllowedProvider).value ?? true;

    return HazriScreen(
      title: l.notifTitle,
      children: [
        if (!allowed) ...[
          _Blocked(),
          const SizedBox(height: 12),
        ],
        SettingsSection(
          title: l.notifOwnPractice,
          children: [
            for (final id in ReminderIds.defaults)
              ReminderRow(
                reminderId: id,
                reminder: reminders.where((r) => r.id == id).firstOrNull,
                showDivider: false,
              ),
          ],
        ),
        SettingsSection(
          title: l.notifYourGroups,
          children: [
            _Later(title: l.notifGoalClose, subtitle: l.notifGoalCloseSub),
            _Later(title: l.notifSomeoneJoined, subtitle: l.notifSomeoneJoinedSub),
            _Later(title: l.notifGroupSummary, subtitle: l.notifGroupSummarySub),
          ],
        ),
        SettingsSection(
          title: l.notifGlobal,
          children: [
            _Later(title: l.notifLargeGatherings, subtitle: l.notifLargeGatheringsSub),
          ],
        ),
        const SizedBox(height: 14),
        HazriCard(
          colour: c.card2,
          child: Text(
            l.notifGroupsNotYet,
            style: HazriText.bodySmall.copyWith(color: c.ink2),
          ),
        ),
      ],
    );
  }
}

/// A notification that is planned and cannot be sent yet.
///
/// A dead switch is better than a live one that does nothing: this way the
/// screen shows what is coming without anybody turning something on and then
/// wondering for a week why it never arrived.
class _Later extends StatelessWidget {
  const _Later({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => SettingsRow(
        title: title,
        subtitle: subtitle,
        trailing: const Switch(value: false, onChanged: null),
      );
}
