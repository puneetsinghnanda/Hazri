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
import '../features/goals/ui/goal_planner_screen.dart';
import '../features/saakhi/ui/saakhi_library_screen.dart';
import '../features/saakhi/ui/saakhi_reader_screen.dart';
import '../features/goals/ui/goals_screen.dart';
import '../features/gurpurab/ui/gurpurab_screen.dart';
import '../features/library/ui/library_entry_screen.dart';
import '../features/library/ui/library_screen.dart';
import '../features/vichar/ui/vichar_screen.dart';
import '../features/nitnem/ui/nitnem_screen.dart';
import '../features/onboarding/ui/setup_screen.dart';
import '../features/onboarding/ui/welcome_screen.dart';
import '../features/reader/ui/reader_screen.dart';
import '../features/reminders/data/reminder_service.dart';
import '../features/reminders/ui/battery_help_screen.dart';
import '../features/reminders/ui/notification_diagnostics_screen.dart';
import '../features/reminders/ui/notifications_screen.dart';
import '../features/settings/ui/settings_screen.dart';
import '../features/simran/ui/simran_screen.dart';
import '../features/today/ui/today_screen.dart';
import '../features/profile/data/incoming_link.dart';
import '../features/quiz/ui/quiz_board_screen.dart';
import '../features/quiz/ui/quiz_home_screen.dart';
import '../features/quiz/ui/quiz_me_screen.dart';
import '../features/quiz/ui/quiz_screen.dart';
import '../features/profile/ui/email_sent_screen.dart';
import '../features/profile/ui/link_result_screen.dart';
import '../features/profile/ui/profile_edit_screen.dart';
import '../features/profile/ui/profile_screen.dart';
import '../features/profile/ui/profile_setup_screen.dart';
import '../features/sangat/ui/create_group_screen.dart';
import '../features/sangat/ui/group_screen.dart';
import '../features/sangat/ui/join_screen.dart';
import '../features/badges/ui/badges_screen.dart';
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
  static const saakhis = '/saakhis';
  static String saakhi(String id, {bool listen = false}) => '/saakhis/$id${listen ? '?listen=1' : ''}';

  static String libraryEntry(String id) => '/library/$id';
  // The Gurmat Quiz (14-quiz.md).
  static const quiz = '/quiz';
  static String quizPlay(String topicId) => '/quiz/play/$topicId';
  static String quizBoard({String? scope}) => '/quiz/board${scope == null ? '' : '?scope=$scope'}';
  static const quizMe = '/quiz/me';
  static const gurpurab = '/gurpurab';
  static const goals = '/goals';
  static const goalPlan = '/goals/plan';
  static const about = '/about';
  static const privacy = '/privacy';

  /// The Sangat tab (08-sangat §8).
  static const sangat = '/sangat';
  static const sangatCreate = '/sangat-create';
  static String sangatJoin([String? code]) =>
      code == null ? '/sangat-join' : '/sangat-join?code=${Uri.encodeQueryComponent(code)}';
  static String sangatGroup(String id, {bool share = false}) => '/sangat-group/$id${share ? '?share=1' : ''}';
  static const licences = '/licences';

  /// Badges (12-badges UI2, UI4).
  static const badges = '/badges';
  static String badge(String id) => '/badges/$id';

  /// The profile (`01-accounts.md` §8, ARCHITECTURE §2.4).
  static const profile = '/profile';
  static const profileSetup = '/profile-setup';
  static const profileEdit = '/profile-edit';

  /// `extra`: an `EmailSentArgs`.
  static const emailSent = '/email-sent';

  /// Where a tapped `/verify?token=` link lands (§8.9).
  static String linkResult(String token) => '/link-result?token=${Uri.encodeQueryComponent(token)}';
  static const batteryHelp = '/reminders-help';

  /// Every notification Hazri can send, in one place (design 50).
  static const notifications = '/notifications';

  /// What the phone says about reminders (02-notifications DP4).
  static const notificationDiagnostics = '/notifications/diagnostics';

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

/// The root navigator, for a sheet shown from outside any screen (the badge
/// announcement).
GlobalKey<NavigatorState> get rootNavigatorKey => _rootKey;

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    routes: [
      // 03-first-run F1: no screen of its own; the redirect below decides
      // before the first frame.
      GoRoute(path: Routes.splash, builder: (_, _) => const SizedBox.shrink()),
      GoRoute(path: Routes.intro, builder: (_, _) => const WelcomeScreen()),
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
      GoRoute(path: Routes.saakhis, builder: (_, _) => const SaakhiLibraryScreen()),
      GoRoute(
        path: '/saakhis/:id',
        builder: (_, state) => SaakhiReaderScreen(
          id: state.pathParameters['id']!,
          listen: state.uri.queryParameters['listen'] == '1',
        ),
      ),
      GoRoute(
        path: '/library/:id',
        builder: (_, state) => LibraryEntryScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: Routes.quiz, builder: (_, _) => const QuizHomeScreen()),
      GoRoute(
        path: '/quiz/play/:topic',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => QuizScreen(topicId: state.pathParameters['topic']!),
      ),
      GoRoute(
        path: '/quiz/board',
        builder: (_, state) => QuizBoardScreen(scope: state.uri.queryParameters['scope']),
      ),
      GoRoute(path: Routes.quizMe, builder: (_, _) => const QuizMeScreen()),
      GoRoute(path: Routes.gurpurab, builder: (_, _) => const GurpurabScreen()),
      GoRoute(path: Routes.goals, builder: (_, _) => const GoalsScreen()),
      GoRoute(path: Routes.goalPlan, builder: (_, _) => const GoalPlannerScreen()),
      GoRoute(path: Routes.about, builder: (_, _) => const AboutScreen()),
      GoRoute(path: Routes.privacy, builder: (_, _) => const PrivacyScreen()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: Routes.licences, builder: (_, _) => const LicencesScreen()),
      GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsScreen()),
      GoRoute(
        path: Routes.notificationDiagnostics,
        builder: (_, _) => const NotificationDiagnosticsScreen(),
      ),
      GoRoute(path: Routes.batteryHelp, builder: (_, _) => const BatteryHelpScreen()),
      GoRoute(path: Routes.sangatCreate, builder: (_, _) => const CreateGroupScreen()),
      GoRoute(
        path: '/sangat-join',
        builder: (_, state) => JoinScreen(code: state.uri.queryParameters['code']),
      ),
      GoRoute(
        path: '/sangat-group/:id',
        builder: (_, state) => GroupScreen(
          groupId: state.pathParameters['id']!,
          offerShare: state.uri.queryParameters['share'] == '1',
        ),
      ),
      GoRoute(path: Routes.badges, builder: (_, _) => const BadgesScreen()),
      GoRoute(
        path: '/badges/:id',
        builder: (_, state) => BadgeDetailScreen(badgeId: state.pathParameters['id']!),
      ),
      GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
      GoRoute(path: Routes.profileSetup, builder: (_, _) => const ProfileSetupScreen()),
      GoRoute(path: Routes.profileEdit, builder: (_, _) => const ProfileEditScreen()),
      GoRoute(
        path: Routes.emailSent,
        builder: (_, state) => state.extra is EmailSentArgs
            ? EmailSentScreen(args: state.extra! as EmailSentArgs)
            : const ProfileScreen(),
      ),
      GoRoute(
        path: '/link-result',
        builder: (_, state) => LinkResultScreen(token: state.uri.queryParameters['token'] ?? ''),
      ),
    ],
    redirect: (context, state) {
      // A tapped link arrives here as the whole URI (D3). /verify goes to
      // the Link Result screen, once per token per process (§8.9); any other
      // https link on one of our hosts opens the app rather than
      // go_router's "no routes for location" page.
      final settings = ref.read(settingsProvider);
      final link = incomingLinkRoute(state.uri);
      if (link != null) {
        // 03-first-run F7: a link that arrives before setup waits for it.
        if (settings.onboardingDone) return link;
        if (link != Routes.today) {
          holdLink(ref.read(sharedPreferencesProvider), link);
        }
        return Routes.intro;
      }

      final loc = state.matchedLocation;
      final inOnboarding = loc == Routes.intro || loc.startsWith('/setup');
      // F1: the splash is a redirect, never a screen held for a time.
      if (loc == Routes.splash) {
        return settings.onboardingDone ? Routes.today : Routes.intro;
      }
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
