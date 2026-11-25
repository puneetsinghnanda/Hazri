import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../audio/data/notification_access.dart';

/// Whether Android will leave Hazri's reminders alone (02-notifications KA1,
/// owner 2026-11-19): `unused` is "Pause app activity if unused" switched
/// off for Hazri, `battery` is battery optimisation off. Null is unknown,
/// or a setting the phone does not have.
typedef KeepAwake = ({bool? unused, bool? battery});

final keepAwakeProvider = FutureProvider.autoDispose<KeepAwake>((ref) async {
  final s = ref.watch(systemSettingsProvider);
  return (unused: await s.unusedAppExempt(), battery: await s.ignoringBatteryOptimizations());
});

/// Something a person could switch for Hazri: a setting that is known and off.
bool keepAwakeNeeded(KeepAwake k) => k.unused == false || k.battery == false;

/// KA2: asked once, on its own sheet; then only on the Notifications page.
const kKeepAwakeAsked = 'keep_awake_asked_v1';

/// "Keep reminders coming" (KA1): why reminders can stop, and the two
/// settings that keep them, each with Open or a tick once it is done. It
/// reads the settings again whenever the app comes back from Android's.
class KeepRemindersCard extends ConsumerStatefulWidget {
  const KeepRemindersCard({super.key, this.inSheet = false});

  /// On the one-time sheet: no card around it, and Not now under it.
  final bool inSheet;

  @override
  ConsumerState<KeepRemindersCard> createState() => _KeepRemindersCardState();
}

class _KeepRemindersCardState extends ConsumerState<KeepRemindersCard> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(keepAwakeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final k = ref.watch(keepAwakeProvider).value;
    if (k == null) return const SizedBox.shrink();
    final settings = ref.read(systemSettingsProvider);

    Widget row(String title, String sub, bool? done, Future<bool> Function() open) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                    Text(sub, style: HazriText.caption.copyWith(color: c.ink2)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (done == true)
                Semantics(
                  label: l.keepAwakeDone,
                  child: AppIcon(HazriIconData.check, size: 24, color: c.sage),
                )
              else
                FilledButton(
                  onPressed: () => open(),
                  style: FilledButton.styleFrom(backgroundColor: c.primary, foregroundColor: c.onPrimary),
                  child: Text(l.keepAwakeOpen),
                ),
            ],
          ),
        );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.keepAwakeTitle, style: HazriText.display22.copyWith(color: c.ink, fontSize: 19)),
        const SizedBox(height: 6),
        Text(l.keepAwakeBody, style: HazriText.bodySmall.copyWith(color: c.ink2)),
        // Android 11 and later: the setting that sleeps an unused app.
        if (k.unused != null)
          row(l.keepAwakeUnusedTitle, l.keepAwakeUnusedSub, k.unused, settings.openUnusedAppSettings),
        // Every phone: Hazri's own page, where the battery options are.
        row(l.keepAwakeBatteryTitle, l.keepAwakeBatterySub, k.battery, settings.openAppSettings),
      ],
    );
    return widget.inSheet
        ? body
        : HazriCard(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), child: body);
  }
}

/// KA2: the card once, as a sheet, the first time the app opens to a tab with
/// a setting still to switch; never again after that, whatever is chosen.
Future<void> maybeShowKeepAwakeSheet(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  if (prefs.getBool(kKeepAwakeAsked) ?? false) return;
  final k = await ref.read(keepAwakeProvider.future);
  if (!keepAwakeNeeded(k) || !context.mounted) return;
  await prefs.setBool(kKeepAwakeAsked, true);
  if (!context.mounted) return;
  final l = L.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const KeepRemindersCard(inSheet: true),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.of(sheet).pop(), child: Text(l.keepAwakeLater)),
          ],
        ),
      ),
    ),
  );
}
