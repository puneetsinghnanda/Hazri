import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/user_repository.dart';
import '../core/l10n/gen/app_localizations.dart';
import '../core/settings/settings_controller.dart';
import '../core/theme/hazri_theme.dart';
import '../features/reminders/data/reminders_controller.dart';
import '../features/backup/data/backup_controller.dart';
import '../features/profile/data/profile_controller.dart';
import '../features/sangat/data/sangat_controller.dart';
import '../features/sangat/data/sangat_device.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'router.dart';

class HazriApp extends ConsumerStatefulWidget {
  const HazriApp({super.key});

  @override
  ConsumerState<HazriApp> createState() => _HazriAppState();
}

class _HazriAppState extends ConsumerState<HazriApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Keeps the weekly backup in step with the profile from the first frame.
    ref.read(backupControllerProvider);
    // The Sangat: the outbox flag, its sender, the push token, and a
    // reconnect sending what waited offline (08-sangat §5.1, K13).
    ref.read(sangatMemberProvider);
    ref.read(sangatDeviceProvider);
    _online = Connectivity().onConnectivityChanged.listen((r) {
      if (!r.contains(ConnectivityResult.none)) unawaited(ref.read(outboxSenderProvider).send());
    });
    _replan();
  }

  StreamSubscription<List<ConnectivityResult>>? _online;

  @override
  void dispose() {
    _online?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app is the cheapest moment to notice that the day, the
    // time zone or the sunrise has moved on (PRD 1.10).
    if (state == AppLifecycleState.resumed) _replan();
  }

  /// Closes a goal whose items have all ended (04-goals BG2), then rebuilds
  /// the rolling reminder window.
  void _replan() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // BK2: a Sunday missed while the phone was off runs now.
      if (ref.read(profileControllerProvider) is ProfileLoaded) {
        unawaited(ref.read(backupControllerProvider).onProfileLoaded());
      }
      await ref.read(userRepositoryProvider).closeGoalIfBlank();
      unawaited(ref.read(outboxSenderProvider).send());
      unawaited(ref.read(sangatDeviceProvider).sync());
      await ref.read(installInviteProvider).readOnce();
      if (!ref.read(settingsProvider).onboardingDone) return;
      // IV6: an invite carried through the Play install, once setup is done.
      final code = await ref.read(installInviteProvider).take();
      if (code != null) ref.read(routerProvider).push(Routes.sangatJoin(code));
      await ref.read(reminderSchedulerProvider).reschedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    final elder = settings.elderMode;

    return MaterialApp.router(
      title: 'Hazri',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: settings.locale,
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      theme: HazriTheme.light(elder: elder),
      darkTheme: HazriTheme.dark(elder: elder),
      themeMode: settings.themeMode,
      builder: (context, child) {
        // UI screens follow the system font scale up to 1.3x without clipping
        // (PRD §11); the reader has its own size control.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
