import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/settings/settings_controller.dart';
import '../features/about/ui/about_screen.dart';
import '../features/about/ui/licences_screen.dart';
import '../features/about/ui/privacy_screen.dart';
import '../features/sangat/ui/sangat_screen.dart';
import '../features/diary/ui/diary_day_screen.dart';
import '../features/diary/ui/diary_screen.dart';
import '../features/goals/ui/goals_screen.dart';
import '../features/gurpurab/ui/gurpurab_screen.dart';
import '../features/library/ui/library_entry_screen.dart';
import '../features/library/ui/library_screen.dart';
import '../features/vichar/ui/vichar_screen.dart';
import '../features/nitnem/ui/nitnem_screen.dart';
import '../features/onboarding/ui/intro_screen.dart';
import '../features/onboarding/ui/setup_screen.dart';
import '../features/onboarding/ui/splash_screen.dart';
import '../features/reader/ui/reader_screen.dart';
import '../features/reminders/data/reminder_service.dart';
import '../features/reminders/ui/battery_help_screen.dart';
import '../features/reminders/ui/notifications_screen.dart';
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

  /// One day in the diary (design 56). Inside the Diary branch, so the bottom
  /// nav stays put and back goes to the month.
  static String diaryDay(DateTime date) => '/diary/'
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  static const settings = '/settings';
  static const vichar = '/vichar';

  /// The reading-and-looking-up section (designs 43 to 46). Separate from
  /// [vichar], which is the one line from Sri Guru Granth Sahib Ji on Today.
  static const library = '/library';

  static String libraryEntry(String id) => '/library/$id';
  static const gurpurab = '/gurpurab';
  static const goals = '/goals';
  static const about = '/about';
  static const privacy = '/privacy';

  /// The Sangat tab. Rebuilt in step 6 (PRD §11.4).
  static const sangat = '/sangat';
  static const licences = '/licences';
  static const batteryHelp = '/reminders-help';

  /// Every notification Hazri can send, in one place (design 50).
  static const notifications = '/notifications';

  /// The five bottom-nav branches. Going to one of these switches tabs;
  /// pushing one would stack a second copy on top of the shell.
  static const tabs = {today, nitnem, simran, sangat, diary};

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
            routes: [GoRoute(path: Routes.sangat, builder: (_, _) => const SangatScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.diary,
                builder: (_, _) => const DiaryScreen(),
                routes: [
                  GoRoute(
                    path: ':date',
                    builder: (_, state) {
                      final date =
                          DateTime.tryParse(state.pathParameters['date'] ?? '');
                      return date == null
                          ? const DiaryScreen()
                          : DiaryDayScreen(
                              date: DateTime(date.year, date.month, date.day));
                    },
                  ),
                ],
              ),
            ],
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
      GoRoute(path: Routes.library, builder: (_, _) => const LibraryScreen()),
      GoRoute(
        path: '/library/:id',
        builder: (_, state) => LibraryEntryScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: Routes.gurpurab, builder: (_, _) => const GurpurabScreen()),
      GoRoute(path: Routes.goals, builder: (_, _) => const GoalsScreen()),
      GoRoute(path: Routes.about, builder: (_, _) => const AboutScreen()),
      GoRoute(path: Routes.privacy, builder: (_, _) => const PrivacyScreen()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: Routes.licences, builder: (_, _) => const LicencesScreen()),
      GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: Routes.batteryHelp, builder: (_, _) => const BatteryHelpScreen()),
    ],
    redirect: (context, state) {
      // An https link on one of our hosts that no route claims opens the
      // app rather than go_router's "no routes for location" page. The
      // verification, restore and invite links get their own handling with
      // the profile (step 4) and the Sangat (step 6).
      if (state.uri.hasScheme && state.uri.scheme.startsWith('http')) {
        return Routes.today;
      }

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
