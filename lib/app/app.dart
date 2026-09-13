import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/gen/app_localizations.dart';
import '../core/settings/settings_controller.dart';
import '../core/theme/hazri_theme.dart';
import '../features/reminders/data/reminders_controller.dart';
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
    _replan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app is the cheapest moment to notice that the day, the
    // time zone or the sunrise has moved on (PRD 1.10).
    if (state == AppLifecycleState.resumed) _replan();
  }

  /// Rebuilds the rolling reminder window.
  void _replan() {
    if (!ref.read(settingsProvider).onboardingDone) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(reminderSchedulerProvider).reschedule(),
    );
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
