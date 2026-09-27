import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/settings/settings_controller.dart';
import '../features/about/ui/about_screen.dart';
import '../features/about/ui/licences_screen.dart';
import '../features/about/ui/privacy_screen.dart';
import '../features/sangat/domain/incoming_link.dart';
import '../features/sangat/ui/account_screen.dart';
import '../features/sangat/ui/create_group_screen.dart';
import '../features/sangat/ui/group_goal_screen.dart';
import '../features/sangat/ui/group_invite_screen.dart';
import '../features/sangat/ui/group_screen.dart';
import '../features/sangat/ui/join_by_link_screen.dart';
import '../features/sangat/ui/restore_screen.dart';
import '../features/sangat/ui/sangat_screen.dart';
import '../features/sangat/ui/join_sangat_screen.dart';
import '../features/sangat/ui/verify_email_screen.dart';
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
import '../features/sync/ui/sync_screen.dart';
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

  /// Diary sync (design 49).
  static const sync = '/sync';

  /// Joining the sangat (design 32). Pushed from the sheet, never a tab: the
  /// sangat is opt-in and nothing routes here on its own.
  static const sangatJoin = '/sangat/join';

  /// The account (design 33), and the verification behind it (design 34).
  /// Nothing else in the app links to [verifyEmail]: asking somebody to
  /// confirm an address belongs here and only here.
  /// Coming back to an account on a new phone (designs 53, 54, 52). The
  /// address is passed along so somebody who just typed it does not type it
  /// again.
  static String restore({String? email}) =>
      email == null ? '/restore' : '/restore?email=${Uri.encodeComponent(email)}';

  static const account = '/account';
  static const verifyEmail = '/account/verify';

  /// The Sangat tab, and everything under it. A group id is opaque and comes
  /// from Firestore, so it is never composed by hand.
  static const sangat = '/sangat';
  static const createGroup = '/sangat/create';
  static const joinByLink = '/sangat/link';

  static String group(String id) => '/sangat/g/$id';
  static String groupGoal(String id) => '/sangat/g/$id/goal';
  static String groupInvite(String id) => '/sangat/g/$id/invite';
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
      GoRoute(path: Routes.sync, builder: (_, _) => const SyncScreen()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: Routes.sangatJoin, builder: (_, _) => const JoinSangatScreen()),
      GoRoute(path: Routes.createGroup, builder: (_, _) => const CreateGroupScreen()),
      GoRoute(
        path: Routes.joinByLink,
        builder: (_, state) =>
            JoinByLinkScreen(arrivedWith: state.uri.queryParameters['code']),
      ),
      GoRoute(
        path: '/sangat/g/:id',
        builder: (_, state) => GroupScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/sangat/g/:id/goal',
        builder: (_, state) => GroupGoalScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/sangat/g/:id/invite',
        builder: (_, state) => GroupInviteScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/restore',
        builder: (_, state) =>
            RestoreScreen(email: state.uri.queryParameters['email']),
      ),
      GoRoute(path: Routes.account, builder: (_, _) => const AccountScreen()),
      GoRoute(
        path: Routes.verifyEmail,
        builder: (_, state) =>
            VerifyEmailScreen(arrivedWith: state.uri.queryParameters['link']),
      ),
      GoRoute(path: Routes.licences, builder: (_, _) => const LicencesScreen()),
      GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: Routes.batteryHelp, builder: (_, _) => const BatteryHelpScreen()),
    ],
    redirect: (context, state) {
      // A link Android handed us, before anything else decides where to go.
      //
      // Before the onboarding gate on purpose. The one moment a tapped link
      // matters most is somebody restoring on a new phone, and that phone has
      // not been set up -- so a gate that sends every unfinished install to
      // the intro would swallow exactly the link it was opened for.
      final incoming = IncomingLink.from(state.uri);
      switch (incoming) {
        case SignInLink(url: final url):
          return '${Routes.verifyEmail}?link=${Uri.encodeQueryComponent(url)}';
        case InviteLink(groupId: final id):
          return '${Routes.joinByLink}?code=${Uri.encodeQueryComponent(id)}';
        case NotOurLink():
          break;
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
