import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../sangat/data/account_repository.dart';
import '../../settings/ui/screen_scaffold.dart';
import '../data/diary_sync.dart';
import '../domain/sync_status.dart';

/// Design 49 — what sync does, when, and the two switches that govern it.
///
/// The screen's job is to make one thing unmistakable: **your paath is on
/// this phone either way**. Sync decides whether the diary can come back on a
/// new phone and nothing else, so no state here is an error and none of them
/// asks anybody to do something before they carry on reading.
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final settings = ref.watch(settingsProvider);
    final joined = ref.watch(hasJoinedSangatProvider);
    final status = ref.watch(syncStatusProvider).value ?? const SyncOff();

    final (title, subtitle, colour, icon) = switch (status) {
      Synced(at: final at) => (
          l.syncStateSynced,
          '${l.syncStateSyncedSub} · ${HazriDates.of(context).time(at)}',
          c.sage,
          HazriIconData.check,
        ),
      Sending(days: final days) => (
          l.syncStateSending(days),
          l.syncStateSyncedSub,
          c.teal,
          HazriIconData.arrowUp,
        ),
      SyncWaiting(forWifi: true) => (
          l.syncStateWifi,
          l.syncStateWifiSub,
          c.kesriInk,
          HazriIconData.noSound,
        ),
      SyncWaiting() => (
          l.syncStateWaiting,
          l.syncStateWaitingSub,
          c.kesriInk,
          HazriIconData.noSound,
        ),
      SyncOff() => (
          l.syncStateOff,
          l.syncStateOffSub,
          c.muted,
          HazriIconData.lock,
        ),
    };

    return HazriScreen(
      title: l.syncTitle,
      subtitle: l.syncSubtitle,
      children: [
        const SizedBox(height: 6),
        HazriCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon(icon, size: 20, color: colour),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: HazriText.caption.copyWith(color: c.ink2)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        HazriCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SettingsRow(
                title: l.syncMyDiary,
                subtitle: joined ? null : l.syncNeedsAccount,
                trailing: Switch(
                  value: settings.diarySync,
                  // Without an account there is nowhere to sync to, so the
                  // switch says so rather than turning on and failing later.
                  onChanged: joined
                      ? (v) async {
                          await ref.read(settingsProvider.notifier).setDiarySync(v);
                          if (v) await ref.read(diarySyncProvider).push();
                        }
                      : null,
                ),
              ),
              Divider(height: 1, color: c.rule),
              SettingsRow(
                title: l.syncWifiOnly,
                subtitle: l.syncWifiOnlySub,
                trailing: Switch(
                  value: settings.syncWifiOnly,
                  onChanged: settings.diarySync
                      ? (v) => ref.read(settingsProvider.notifier).setSyncWifiOnly(v)
                      : null,
                ),
              ),
            ],
          ),
        ),
        if (settings.diarySync) ...[
          const SizedBox(height: 14),
          PrimaryButton(
            label: l.syncNow,
            secondary: true,
            onPressed: () => ref.read(diarySyncProvider).push(),
          ),
        ],
        const SizedBox(height: 18),
        HazriCard(
          colour: c.card2,
          child: Text(
            l.syncWorksWithout,
            style: HazriText.bodySmall.copyWith(color: c.ink2),
          ),
        ),
      ],
    );
  }
}
