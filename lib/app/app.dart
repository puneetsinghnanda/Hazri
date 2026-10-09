import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/user_repository.dart';
import '../core/l10n/gen/app_localizations.dart';
import '../core/settings/settings_controller.dart';
import '../core/theme/hazri_theme.dart';
import '../core/time/clock.dart';
import '../features/hazri/data/hazri_controller.dart';
import '../features/hazri/ui/goal_complete_sheet.dart';
import '../features/reminders/data/reminders_controller.dart';
import '../features/backup/data/backup_controller.dart';
import '../features/profile/data/profile_controller.dart';
import '../features/sangat/data/sangat_controller.dart';
import '../features/sangat/data/sangat_device.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../features/simran/data/presence_repository.dart';
import '../features/badges/data/badge_controller.dart';
import '../features/badges/ui/badge_widgets.dart';
import '../features/simran/data/simran_controller.dart';
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
    // 12-badges AN1, UI7: a waiting badge's sheet shows when a tab is on
    // screen, never over the reader or a running Simran sitting.
    final router = ref.read(routerProvider);
    router.routerDelegate.addListener(_announceBadge);
    ref.listenManual(pendingBadgeProvider, (_, _) => _announceBadge());
    ref.listenManual(simranSessionProvider, (_, s) {
      if (!s.active) _announceBadge();
    });
    // Design 61, once on the day the last goal item is met, over whatever is
    // showing (05-today T9: "from wherever the last item was met"). It
    // follows the state rather than a tap, because the paath that meets it
    // can be in the reader, the player or the Diary.
    ref.listenManual(goalsAllDoneTodayProvider, (was, isNow) {
      if (!isNow || (was ?? false)) return;
      final cue = ref.read(goalCompleteCueProvider);
      final today = ref.read(clockProvider).today();
      if (!cue.shouldShowFor(today)) return;
      cue.markShown(today);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = rootNavigatorKey.currentContext;
        if (context != null && context.mounted) showGoalCompleteSheet(context);
      });
    });
    // Keeps the weekly backup in step with the profile from the first frame.
    ref.read(backupControllerProvider);
    // The Sangat: the outbox flag, its sender, the push token, and a
    // reconnect sending what waited offline (08-sangat §5.1, K13).
    ref.read(sangatMemberProvider);
    ref.read(sangatDeviceProvider);
    // AT2: a profile created later in the day marks attendance at once.
    ref.listenManual(profileControllerProvider, (was, now) {
      if (now is ProfileLoaded && was is! ProfileLoaded) {
        unawaited(ref.read(presenceServiceProvider).markAttendance());
      }
    });
    _online = Connectivity().onConnectivityChanged.listen((r) {
      if (!r.contains(ConnectivityResult.none)) unawaited(ref.read(outboxSenderProvider).send());
    });
    _replan();
  }

  StreamSubscription<List<ConnectivityResult>>? _online;

  void _announceBadge() {
    final badge = ref.read(pendingBadgeProvider);
    if (badge == null) return;
    final path = ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path;
    if (!Routes.tabs.contains(path)) return;
    if (ref.read(simranSessionProvider).active) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    ref.read(pendingBadgeProvider.notifier).state = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) showBadgeEarnedSheet(context, badge);
    });
  }

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
      // 12-badges EV2 at start (LS1: history counts), and the Sangat facts
      // once a day (SF4).
      unawaited(ref.read(badgeControllerProvider).evaluate());
      unawaited(ref.read(badgeControllerProvider).refreshFacts(daily: true));
      // 07-simran AT1: once per IST day, with a profile.
      unawaited(ref.read(presenceServiceProvider).markAttendance());
      // 03-first-run F6: Android's prompt at every start, over Welcome on a
      // first launch; reminders are planned whatever the answer.
      unawaited(ref.read(reminderSchedulerProvider).reschedule());
      await ref.read(installInviteProvider).readOnce();
      if (!ref.read(settingsProvider).onboardingDone) return;
      // IV6: an invite carried through the Play install, once setup is done.
      final code = await ref.read(installInviteProvider).take();
      if (code != null) ref.read(routerProvider).push(Routes.sangatJoin(code));
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
