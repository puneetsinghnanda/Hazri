# 2. Notifications

The feature with the worst record in this project: four rounds of fixes went
out before a single notification appeared on a phone.

---

## 2.1 Purpose

Arrive at the time somebody chose, say one useful thing, and open the right
screen when tapped. Never nag, never shame, never claim something untrue.

## 2.2 How it works, end to end

Six stages. **A break in any one of them is total silence, and stages 1 and 6
are invisible to every test we had.**

```
1. Manifest        ScheduledNotificationReceiver declared?   <- was missing
2. Permission      POST_NOTIFICATIONS granted?
3. Rows            the five defaults seeded?                 <- was a screen side effect
4. Plan            ReminderPlanner.plan -> occurrences
5. Schedule        zonedSchedule via AlarmManager
6. Delivery        exact vs inexact, doze, OEM battery killer
```

**Stage 1.** `flutter_local_notifications` 18.0.1 declares **no receivers** in
its own manifest. The app must declare `ScheduledNotificationReceiver` (posts
the notification when the alarm fires) and `ScheduledNotificationBootReceiver`
(re-arms after a reboot, a clock change, a timezone change). Hazri had only the
second. Every alarm fired into a component that did not exist; `zonedSchedule`
threw nothing and `pendingNotificationRequests()` looked healthy. Held by
`test/android/manifest_test.dart`.

**Stage 2.** Android 13+ denies `POST_NOTIFICATIONS` until granted.
`reschedule()` now asks before giving up, and the notifications screen shows a
card when it is refused.

**Stage 3.** Five default rows — `slot:morning`, `slot:evening`,
`slot:bedtime`, `simran`, `gurpurab` — seeded inside `reschedule()`.

**Stage 4.** `ReminderPlanner.plan` over a rolling **7 days**, capped at **60
pending**. Auto times come from `SolarService`: Amrit Vela = sunrise − 90 min
to the nearest 5; Rehras = sunset; Sohila = sunset + 3h30, clamped 21:00–23:30.
A slot already completed today is suppressed for today only. Gurpurab fires
only on the **eve of a day the calendar flags**. Goal reminders are built in
memory from live goals that carry a `reminderTime`.

**Stage 5.** `zonedSchedule` with `exactAllowWhileIdle` when
`SCHEDULE_EXACT_ALARM` is granted, `inexactAllowWhileIdle` otherwise. Four
channels so each can be tuned in system settings: `nitnem_reminders`,
`daily_simran`, `gurpurab`, `paath_goals`.

**Stage 6.** Not in our control and not currently visible. Inexact alarms can
run late. Xiaomi, Oppo, Vivo, Samsung kill background alarms by policy.

## 2.3 Wrong or missing

1. **No diagnostics.** The single biggest process failure here. Nothing in the
   app can say what the phone thinks, so four rounds were spent inferring.
2. **`USE_EXACT_ALARM` is deliberately not declared**, so most phones fall back
   to inexact and a 4:40 reminder may arrive at 5:10. Nothing tells anybody.
3. **Nothing about battery optimisation**, though `battery_help_screen.dart`
   exists and is barely reachable.
4. **No push at all** — now unblocked by Blaze.
5. **Notification actions are unused.** `notifActionStartNitnem` and
   `notifActionStart` exist as strings and are attached to nothing.
6. **Only 10 of 147 calendar events have Punjabi names and none has Hindi**, so
   an event notification says English to somebody who chose Punjabi.

## 2.4 The behaviour

### Local — needs no account, works with the radio off

| # | Notification | Fires | Default |
|---|---|---|---|
| N1 | Amrit Vela | sunrise − 90 min, or a fixed time | on |
| N2 | Rehras | sunset, or fixed | on |
| N3 | Kirtan Sohila | sunset + 3h30, clamped | on |
| N4 | Daily Simran | fixed, 06:00 | on |
| N5 | Gurpurab | 20:00 on the **eve** of a flagged day, naming it | on |
| N6 | Sikhi event | 20:00 on the eve, for `default_remind` events that are not Gurpurabs | **off** |
| N7 | Sangrand | 20:00 on the eve of the Nanakshahi month turning | on |
| N8 | Per goal | the goal's own `reminderTime` | on when a time is set |
| N9 | A bani left part-read | once, 3h after leaving it, same day only | off |
| N10 | Badge earned | when earned | on (see §3.2, D11/D14) |

### Pushed — needs an account, a network and the sangat

| # | Notification | Trigger |
|---|---|---|
| P1 | You were added to a sangat | Function on membership create |
| P2 | The group's day, consolidated | Scheduled Function, one per group per day |
| P3 | Somebody joined your group | Function, to the admin only |
| P4 | The group goal is nearly over | Function, 2 days before `endsAt` |
| P5 | The group goal is reached | Function on the total crossing the target |
| P6 | A new Vichar entry | Function on publish. **off** by default |
| P7 | The line you reported is corrected | Function, to the reporter only |

**A paath logged by one member is not its own notification.** In a family of
six that is six a day. It belongs inside P2's digest, which is why P2 is a
digest.

### Rules that bind every one of them

- **R1.** §0 of the PRD: *Gurbani in notifications is limited to bani names.*
  No line of Gurbani in a body, no ਅੱਜ ਦਾ ਵਿਚਾਰ in a push.
- **R2.** No streak notifications, no loss framing, nothing that says somebody
  missed, lost or is behind (§12).
- **R3.** Nothing names another person's shortfall. A digest says what the
  group did; it never reports that one member did nothing.
- **R4.** Silence windows: nothing between 22:30 and 04:00 except reminders the
  person set themselves; nothing while a simran sitting is running; nothing
  while the reader is open.
- **R5.** At most **2** unconfigured notifications a day. Reminders somebody
  set are exempt and uncapped.
- **R6.** Every category has its own switch. Every pushed category is off until
  somebody joins the sangat, because until then there is nobody to push to.
- **R7.** Every notification carries a route and opens the right screen.

## 2.5 Scenarios

**Success**

| Given | When | Then |
|---|---|---|
| A fresh install, permission granted | The app starts | 5 defaults seeded; a week of occurrences scheduled; pending > 0 |
| Tomorrow is a flagged Gurpurab | 20:00 today | One notification, naming that day's event |
| Tomorrow is nothing | 20:00 today | Nothing. Not "Tomorrow is a Gurpurab" |
| The calendar has run out of year | Any evening | Silence, not a guess |
| Japji completed at 05:00 | The Amrit Vela time passes | Suppressed for today only; tomorrow's stands |
| A goal set for 18:40 | 18:40 | One notification, saying where the day stands, opening Goals |
| A goal stopped this morning | 18:40 | Nothing |
| The phone reboots | Boot completes | The window is re-armed by the boot receiver |
| The timezone changes mid-flight | Landing | Re-planned against the new zone |
| A notification is tapped | — | The named screen opens, even from cold start |

**Failure**

| Given | When | Then |
|---|---|---|
| `ScheduledNotificationReceiver` absent | Anything | **The manifest test fails in CI.** This must never reach a phone again |
| Permission never granted | App start | Asked once; if refused, the notifications screen says reminders cannot arrive and offers the ask |
| Permission revoked while installed | Next resume | The card reappears; nothing is scheduled; nothing pretends |
| Exact alarms denied | Scheduling | Falls back to inexact, **and the screen says reminders may be a few minutes late** |
| An OEM battery killer | Alarms dropped | Diagnostics shows pending > 0 and last-delivered empty; the battery help screen is one tap away |
| 20 goals each with a time | Planning | Capped at 60 pending, nearest first; nothing silently vanishes |
| The event has no Punjabi name, reader is Punjabi | N6 | Falls back to English and is **not** machine-translated |
| No network | Any local reminder | Arrives normally. A local reminder must never need the radio |
| No account | Any pushed category | Not shown as on. Shown as needing the sangat |
| The push token is stale | A Function pushes | The Function removes the dead token; no retry storm |

## 2.6 The diagnostics screen — build this first

Reachable from Notifications. Not a debug build only; this is how a reader
tells us what is wrong.

- Notifications allowed: yes/no
- Exact alarms allowed: yes/no, with what it costs
- Battery optimisation: whether the app is exempt
- Scheduled and waiting: **n**
- The next three, with their times
- Last delivered: when, or never
- **Send one now** — proves stages 1, 2 and 5 in one tap
- **Send one in two minutes** — proves stage 6, which is the one nobody can
  reason about

Had this existed a fortnight ago it would have found the manifest bug in one
tap, because "send one now" would have failed too.

## 2.7 Open decisions

| # | Decision | Default |
|---|---|---|
| N-1 | Declare `USE_EXACT_ALARM`? It makes reminders exact with no prompt, but Play may audit it and it is meant for alarm/calendar apps | **No.** A nitnem reminder five minutes late is fine; being pulled from the Play Store is not. Say it on screen instead |
| N-2 | Digest hour for P2 | 21:00 local per member, not per group — a group can span timezones |
| N-3 | Does N9 (part-read) risk feeling like nagging? | Off by default, once per day maximum, never for a bani begun in the last hour |

## 2.8 Acceptance

- `test/android/manifest_test.dart` green, and **proven** by breaking it.
- `reschedule()` tested end to end, not just `plan()`.
- A test per row of §2.5, both tables.
- Emulator tests for every Function in the pushed table.
- Device: diagnostics shows pending > 0; "send one now" arrives; a scheduled
  one arrives two minutes later; one arrives after a reboot.
