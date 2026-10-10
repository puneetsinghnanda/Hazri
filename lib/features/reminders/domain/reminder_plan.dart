import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../../core/db/user_db.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/time/clock.dart';
import '../../goals/domain/day_verdict.dart';

/// The kinds of notification Hazri sends, the closed list of
/// 02-notifications.md §3. Each has its own switch (CM7) and channel (§6.1).
enum NotificationKind {
  amritVela('amrit_vela'),
  goalBani('goal_reminders'),

  /// Gurpurabs and other Sikh events share one switch and one channel (§9).
  calendar('sikh_calendar'),
  hazriNudge('hazri_nudge'),
  sangat('sangat');

  const NotificationKind(this.channelId);

  /// The kind's name in ARCHITECTURE §4.1, and the key of its switch
  /// (`notif_on_<channelId>`, §3.8).
  final String channelId;

  /// The Android channel it is posted on. The first channels were created at
  /// default importance, which sounds but never shows a pop-up, and Android
  /// keeps a channel's importance once it exists, so the reminders moved to
  /// new channels at high importance (2026-10-09, ARCHITECTURE §4.1).
  String get androidChannelId => '${channelId}_v2';
}

/// A button on a notification (§5.6). [route] is opened when it is tapped;
/// a null route only dismisses ("Later"); [snooze] re-sends once in 15
/// minutes without opening the app (§6.3).
@immutable
class NotificationAction {
  const NotificationAction({required this.id, required this.label, this.route, this.snooze = false});

  final String id;
  final String label;
  final String? route;
  final bool snooze;

  @override
  bool operator ==(Object other) =>
      other is NotificationAction &&
      other.id == id &&
      other.label == label &&
      other.route == route &&
      other.snooze == snooze;

  @override
  int get hashCode => Object.hash(id, label, route, snooze);
}

/// One notification due at one instant, with its text already in the planned
/// language (CM3, CM6).
@immutable
class PlannedNotification {
  const PlannedNotification({
    required this.reminderId,
    required this.kind,
    required this.at,
    required this.title,
    required this.body,
    required this.route,
    this.actions = const [],
    this.progress,
  });

  /// `amrit-vela`, `goal-item:{itemId}`, `event:{eventId}`, `hazri-nudge`
  /// (§6.1), which with the day gives a stable [notificationId].
  final String reminderId;
  final NotificationKind kind;
  final DateTime at;
  final String title;
  final String body;

  /// The route a tap opens.
  final String route;
  final List<NotificationAction> actions;

  /// Items met of items in scope, for the goal reminder's progress bar.
  final (int, int)? progress;

  /// Stable for one reminder on one day, so re-planning replaces rather than
  /// duplicates.
  int get notificationId => ReminderPlanner.notificationIdFor(reminderId, at);

  @override
  String toString() => 'PlannedNotification($reminderId @ $at: $title)';
}

/// One calendar event, as the planner needs it (§4.3).
@immutable
class PlannerEvent {
  const PlannerEvent({
    required this.id,
    required this.date,
    required this.kind,
    required this.name,
    required this.remind,
  });

  final String id;

  /// `YYYY-MM-DD`.
  final String date;

  /// `prakash`, `gurgaddi`, `joti-jot`, `shaheedi`, `sangrand`, …
  final String kind;

  /// The name in the reader's language, or English where that is missing
  /// (CE4). Never machine-translated.
  final String name;

  /// `default_remind`, or the reader's own per-event switch (CE1).
  final bool remind;
}

/// Everything the planner reads (§6.2). Built by the scheduler from the
/// databases, the profile and the settings; the planner itself is pure.
@immutable
class PlannerInput {
  const PlannerInput({
    required this.now,
    required this.enabled,
    required this.items,
    required this.todayCompletions,
    required this.todaySittings,
    required this.banis,
    this.events = const [],
    this.profileName,
    this.cityName,
    this.sunrise,
    this.streakThroughToday,
    this.liveCount,
    this.quietUntil,
  });

  final DateTime now;

  /// The kinds switched on (CM7).
  final Set<NotificationKind> enabled;

  /// Every goal item; the planner keeps those in scope on each day.
  final List<GoalItem> items;
  final List<Completion> todayCompletions;
  final List<SimranSession> todaySittings;

  /// Bani id → name in the planned language, from `content.db`.
  final Map<String, String> banis;

  final List<PlannerEvent> events;

  /// Known only with a profile (§5: Monday's Amrit Vela, Friday's nudge).
  final String? profileName;
  final String? cityName;

  /// Sunrise for a date at the profile city (AV4), or null with no city.
  final DateTime? Function(DateTime date)? sunrise;

  /// The Nitnem streak through today, when today's Nitnem is done (CM4).
  final int? streakThroughToday;

  /// Today's live count of the sangat, rarely known (N-1).
  final int? liveCount;

  /// A Simran sitting runs until then: nothing fires before it (CM5).
  final DateTime? quietUntil;
}

/// Reader slugs by `content.db` bani id, for notification routes.
const kBaniSlugs = <String, String>{
  'JAPJ': 'japji-sahib',
  'JAAP': 'jaap-sahib',
  'TVPS': 'tav-prasad-savaiye',
  'CHAU': 'chaupai-sahib',
  'ANND': 'anand-sahib',
  'REHR': 'rehras-sahib',
  'SOHL': 'kirtan-sohila',
  'ARDS': 'ardas',
  'SUKH': 'sukhmani-sahib',
};

/// Plans every local notification for the next 7 days, nearest first, at
/// most 60 pending (CM2). Text is fixed at planning time (CM3).
abstract final class ReminderPlanner {
  static const windowDays = 7;
  static const maxPending = 60;

  static const amritVelaHour = 4;
  static const gurpurabHour = 6;
  static const eventHour = 7;
  static const hazriNudgeHour = 7;

  /// The rotation index for a date: Sunday is 1, Saturday 7 (§2).
  static int rotationDay(DateTime d) => d.weekday % 7 + 1;

  static List<PlannedNotification> plan(L l, PlannerInput input) {
    final out = <PlannedNotification>[];
    final today = DateTime(input.now.year, input.now.month, input.now.day);
    final todayKey = localDateKey(today);
    final todayVerdict =
        verdictOn(todayKey, input.items, input.todayCompletions, input.todaySittings);

    for (var d = 0; d < windowDays; d++) {
      final day = today.add(Duration(days: d));
      final key = localDateKey(day);
      final inScopeItems = [for (final i in input.items) if (inScope(i, key)) i];

      if (input.enabled.contains(NotificationKind.amritVela)) {
        out.add(_amritVela(l, input, day, inScopeItems));
      }
      if (input.enabled.contains(NotificationKind.goalBani)) {
        final verdict = d == 0 ? todayVerdict : null;
        for (final item in inScopeItems) {
          final n = _goal(l, input, day, item, inScopeItems, verdict);
          if (n != null) out.add(n);
        }
      }
      if (input.enabled.contains(NotificationKind.calendar)) {
        for (final e in input.events) {
          if (e.date == key && e.remind) out.add(_event(l, e, day));
        }
      }
      if (input.enabled.contains(NotificationKind.hazriNudge)) {
        // HN1/HN3: only with no active goal that day and no hazri yet.
        final noGoal = inScopeItems.isEmpty;
        final noHazri = d > 0 || !todayVerdict.hazri;
        if (noGoal && noHazri) out.add(_hazriNudge(l, input, day));
      }
    }

    final quiet = input.quietUntil;
    final due = <PlannedNotification>[
      for (final n in out)
        if (n.at.isAfter(input.now))
          // CM5: due during a sitting → moved to the moment it ends.
          if (quiet != null && n.at.isBefore(quiet)) _moved(n, quiet) else n,
    ]..sort((a, b) => a.at.compareTo(b.at));
    return due.length <= maxPending ? due : due.sublist(0, maxPending);
  }

  static PlannedNotification _moved(PlannedNotification n, DateTime to) => PlannedNotification(
        reminderId: n.reminderId,
        kind: n.kind,
        at: to,
        title: n.title,
        body: n.body,
        route: n.route,
        actions: n.actions,
        progress: n.progress,
      );

  /// The first goal bani in scope that day, else Japji Sahib (AV3).
  static String _firstBani(PlannerInput input, List<GoalItem> items) =>
      items.where((i) => i.itemType == ItemType.bani).map((i) => i.baniId!).firstOrNull ?? 'JAPJ';

  static String _readerRoute(String baniId) => '/reader/${kBaniSlugs[baniId] ?? baniId.toLowerCase()}';

  /// Whether a weekday message needing data may use it: only when planned
  /// within 24 hours of firing (CM3).
  static bool _near(PlannerInput input, DateTime at) =>
      at.difference(input.now) <= const Duration(hours: 24);

  static PlannedNotification _amritVela(
    L l,
    PlannerInput input,
    DateTime day,
    List<GoalItem> items,
  ) {
    final at = DateTime(day.year, day.month, day.day, amritVelaHour);
    final baniId = _firstBani(input, items);
    final bani = input.banis[baniId] ?? baniId;
    final route = _readerRoute(baniId);
    final open = NotificationAction(id: 'open', label: l.notifActionOpenBani(bani), route: route);
    final start = NotificationAction(id: 'nitnem', label: l.notifActionStartNitnem, route: '/nitnem');
    final begin5 = NotificationAction(id: 'simran', label: l.notifActionBeginMinutes(5), route: '/simran');

    (String, String, List<NotificationAction>) fallback() =>
        (l.notifAv1Title, l.notifAv1Body(bani), [open, start]);

    final near = _near(input, at);
    final (title, body, actions) = switch (rotationDay(day)) {
      2 => (near && input.profileName != null && input.cityName != null && input.sunrise?.call(day) != null)
          ? (
              l.notifAv2Title(input.profileName!),
              l.notifAv2Body(input.cityName!, _hhmm(input.sunrise!(day)!)),
              [start],
            )
          : fallback(),
      3 => (l.notifAv3Title, l.notifAv3Body, [start]),
      4 => (near && (input.streakThroughToday ?? 0) >= 3)
          ? (
              l.notifAv4Title(input.streakThroughToday!),
              l.notifAv4Body(input.streakThroughToday!),
              [start],
            )
          : fallback(),
      5 => (l.notifAv5Title, l.notifAv5Body(bani), [open]),
      6 => (l.notifAv6Title(_weekday(l, day)), l.notifAv6Body, [start, begin5]),
      7 => (l.notifAv7Title, l.notifAv7Body, [start]),
      _ => fallback(),
    };
    return PlannedNotification(
      reminderId: 'amrit-vela',
      kind: NotificationKind.amritVela,
      at: at,
      title: title,
      body: body,
      route: route,
      actions: actions,
    );
  }

  static PlannedNotification? _goal(
    L l,
    PlannerInput input,
    DateTime day,
    GoalItem item,
    List<GoalItem> inScopeItems,
    DayVerdict? verdict,
  ) {
    final time = item.reminderTime;
    if (time == null) return null;
    final parts = time.split(':');
    final at = DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
    final isToday = verdict != null;
    // GR2/RM3: not on a day the item is already met.
    if (isToday && itemMet(item, input.todayCompletions, input.todaySittings)) return null;
    final progress = isToday ? (verdict.itemsMet, verdict.itemsInScope) : (0, inScopeItems.length);
    final snooze = NotificationAction(id: 'snooze', label: l.notifActionSnooze, snooze: true);

    if (item.itemType == ItemType.simran) {
      final m = item.simranMinutes ?? 5;
      return PlannedNotification(
        reminderId: 'goal-item:${item.id}',
        kind: NotificationKind.goalBani,
        at: at,
        title: l.notifGoalSimranTitle(m),
        body: l.notifGoalSimranBody,
        route: '/simran',
        actions: [
          NotificationAction(id: 'simran', label: l.notifActionBeginMinutes(m), route: '/simran'),
          snooze,
        ],
        progress: progress,
      );
    }

    final baniId = item.baniId!;
    final bani = input.banis[baniId] ?? baniId;
    final route = _readerRoute(baniId);
    final done = isToday
        ? input.todayCompletions.where((c) => c.deletedAt == null && c.baniId == baniId).length
        : 0;
    final end = item.endDate;
    final String body;
    if (end == null) {
      body = l.notifGoalBaniOpenBody(done, item.timesPerDay);
    } else {
      final start = parseLocalDateKey(item.startDate);
      final dayN = day.difference(start).inDays + 1;
      final total = parseLocalDateKey(end).difference(start).inDays + 1;
      body = l.notifGoalBaniBody(done, item.timesPerDay, dayN, total);
    }
    return PlannedNotification(
      reminderId: 'goal-item:${item.id}',
      kind: NotificationKind.goalBani,
      at: at,
      title: l.notifGoalBaniTitle(bani),
      body: body,
      route: route,
      actions: [
        NotificationAction(id: 'open', label: l.notifActionOpenBani(bani), route: route),
        snooze,
      ],
      progress: progress,
    );
  }

  static const _gurpurabKinds = {'prakash', 'gurgaddi', 'joti-jot'};

  static PlannedNotification _event(L l, PlannerEvent e, DateTime day) {
    final gurpurab = _gurpurabKinds.contains(e.kind);
    final at = DateTime(day.year, day.month, day.day, gurpurab ? gurpurabHour : eventHour);
    // CE3: celebration for prakash and gurgaddi, remembrance for joti-jot and
    // shaheedi, plain otherwise. Never "Happy".
    final (title, body) = switch (e.kind) {
      'prakash' || 'gurgaddi' => (l.notifGurpurabTitle(e.name), l.notifGurpurabBody),
      'joti-jot' => (l.notifRememberTitle(e.name), l.notifRememberBody),
      'shaheedi' => (l.notifRememberTitle(e.name), l.notifRememberBody),
      _ => (l.notifEventTitle(e.name), l.notifEventBody),
    };
    return PlannedNotification(
      reminderId: 'event:${e.id}',
      kind: NotificationKind.calendar,
      at: at,
      title: title,
      body: body,
      route: '/gurpurab',
      actions: [NotificationAction(id: 'calendar', label: l.notifActionSeeCalendar, route: '/gurpurab')],
    );
  }

  static PlannedNotification _hazriNudge(L l, PlannerInput input, DateTime day) {
    final at = DateTime(day.year, day.month, day.day, hazriNudgeHour);
    final begin = NotificationAction(id: 'simran', label: l.notifActionBeginMinutes(5), route: '/simran');
    final later = NotificationAction(id: 'later', label: l.notifActionLater);
    final near = _near(input, at);
    (String, String, List<NotificationAction>) fallback() =>
        (l.notifHn1Title, l.notifHn1Body, [begin, later]);
    final (title, body, actions) = switch (rotationDay(day)) {
      2 => (near && input.liveCount != null)
          ? (l.notifHn2Title(input.liveCount!), l.notifHn2Body, [begin])
          : fallback(),
      3 => (l.notifHn3Title, l.notifHn3Body, [begin]),
      4 => (
          l.notifHn4Title,
          l.notifHn4Body,
          [NotificationAction(id: 'goal', label: l.notifActionSetGoal, route: '/goals'), begin],
        ),
      5 => (l.notifHn5Title, l.notifHn5Body, [begin]),
      6 => input.cityName != null
          ? (
              l.notifHn6Title(input.cityName!),
              l.notifHn6Body,
              [NotificationAction(id: 'hazri', label: l.notifActionOpenHazri, route: '/today')],
            )
          : fallback(),
      7 => (l.notifHn7Title, l.notifHn7Body, [begin]),
      _ => fallback(),
    };
    return PlannedNotification(
      reminderId: 'hazri-nudge',
      kind: NotificationKind.hazriNudge,
      at: at,
      title: title,
      body: body,
      route: '/simran',
      actions: actions,
    );
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// The day's name in the app's language (`{weekday}`, §5).
  static String _weekday(L l, DateTime d) {
    // Loads intl's bundled symbols for every locale, synchronously, unless
    // something (Flutter's localisations) already has: the planner must not
    // depend on a screen having been built first.
    initializeDateFormatting();
    try {
      return DateFormat('EEEE', l.localeName).format(d);
    } on Object {
      return DateFormat('EEEE', 'en').format(d);
    }
  }

  /// Every id [notificationIdFor] can return is below this; a snooze copy
  /// ([snoozeBit]) and the diagnostics test ([diagnosticId]) are above it, so
  /// a re-plan never touches them.
  static const plannedIdLimit = 100000 * 400;

  static bool isPlannedId(int id) => id < plannedIdLimit;

  /// Set on a snoozed copy's id (§6.3).
  static const snoozeBit = 0x40000000;

  /// "Send one now" and "Send one in two minutes" (DP4).
  static const diagnosticId = 0x20000000;

  /// Today's goal reminders, and their snoozed copies, for the items already
  /// met: one still showing is taken away (GR2, RM3).
  static Set<int> metToday(PlannerInput input) {
    final today = DateTime(input.now.year, input.now.month, input.now.day);
    final key = localDateKey(today);
    return {
      for (final i in input.items)
        if (i.reminderTime != null &&
            inScope(i, key) &&
            itemMet(i, input.todayCompletions, input.todaySittings)) ...[
          notificationIdFor('goal-item:${i.id}', today),
          notificationIdFor('goal-item:${i.id}', today) ^ snoozeBit,
        ],
    };
  }

  /// A small, stable integer per reminder per day.
  static int notificationIdFor(String reminderId, DateTime at) {
    final dayOfYear = DateTime(at.year, at.month, at.day).difference(DateTime(at.year)).inDays;
    var h = 0;
    for (final c in reminderId.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return (h % 100000) * 400 + dayOfYear + 1;
  }
}
