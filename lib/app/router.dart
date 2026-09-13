import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/settings/settings_controller.dart';
import '../features/about/ui/about_screen.dart';
import '../features/about/ui/licences_screen.dart';
import '../features/about/ui/privacy_screen.dart';
import '../features/diary/ui/diary_screen.dart';
import '../features/goals/ui/goals_screen.dart';
import '../features/gurpurab/ui/gurpurab_screen.dart';
import '../features/vichar/ui/vichar_screen.dart';
import '../features/nitnem/ui/nitnem_screen.dart';
import '../features/onboarding/ui/intro_screen.dart';
import '../features/onboarding/ui/setup_screen.dart';
import '../features/onboarding/ui/splash_screen.dart';
import '../features/reader/ui/reader_screen.dart';
import '../features/reminders/data/reminder_service.dart';
import '../features/reminders/ui/battery_help_screen.dart';
import '../features/settings/ui/settings_screen.dart';
import '../features/simran/ui/simran_screen.dart';
import '../features/today/ui/today_screen.dart';
import 'shell.dart';

/// Named routes, so no screen has to spell a path out by hand.
abstract final class Routes {
  static const splash = '/';
  static const intro = '/intro';
  static const today = '/today';
  static const nitnem = '/nitnem';
  static const simran = '/simran';
  static const diary = '/diary';
  static const settings = '/settings';
  static const vichar = '/vichar';
  static const gurpurab = '/gurpurab';
  static const goals = '/goals';
  static const about = '/about';
  static const privacy = '/privacy';
  static const licences = '/licences';
  static const batteryHelp = '/reminders-help';

  static String setup(int step) => '/setup/$step';

  static String reader(String slug, {int? line, bool autoplay = false}) {
    final q = <String>[
      if (line != null) 'line=$line',
      if (autoplay) 'autoplay=1',
    ];
    return '/reader/$slug${q.isEmpty ? '' : '?${q.join('&')}'}';
  }
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.intro, builder: (_, _) => const IntroScreen()),
      GoRoute(
        path: '/setup/:step',
        builder: (_, state) =>
            SetupScreen(step: int.tryParse(state.pathParameters['step'] ?? '1') ?? 1),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.today, builder: (_, _) => const TodayScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.nitnem, builder: (_, _) => const NitnemScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.simran, builder: (_, _) => const SimranScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.diary, builder: (_, _) => const DiaryScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/reader/:slug',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ReaderScreen(
          slug: state.pathParameters['slug']!,
          initialLine: int.tryParse(state.uri.queryParameters['line'] ?? ''),
          autoplay: state.uri.queryParameters['autoplay'] == '1',
        ),
      ),
      GoRoute(path: Routes.vichar, builder: (_, _) => const VicharScreen()),
      GoRoute(path: Routes.gurpurab, builder: (_, _) => const GurpurabScreen()),
      GoRoute(path: Routes.goals, builder: (_, _) => const GoalsScreen()),
      GoRoute(path: Routes.about, builder: (_, _) => const AboutScreen()),
      GoRoute(path: Routes.privacy, builder: (_, _) => const PrivacyScreen()),
      GoRoute(path: Routes.licences, builder: (_, _) => const LicencesScreen()),
      GoRoute(path: Routes.batteryHelp, builder: (_, _) => const BatteryHelpScreen()),
    ],
    redirect: (context, state) {
      final settings = ref.read(settingsProvider);
      final loc = state.matchedLocation;
      final inOnboarding = loc == Routes.intro || loc.startsWith('/setup');
      if (loc == Routes.splash) return null;
      if (!settings.onboardingDone && !inOnboarding) return Routes.intro;
      if (settings.onboardingDone && inOnboarding) return Routes.today;
      return null;
    },
  );

  // A notification tap navigates once the router exists.
  final reminders = ref.read(reminderServiceProvider);
  reminders.onTap = router.go;
  final pending = reminders.pendingPayload;
  if (pending != null) {
    reminders.pendingPayload = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => router.go(pending));
  }

  ref.onDispose(() => reminders.onTap = null);
  return router;
});
