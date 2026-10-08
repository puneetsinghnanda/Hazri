# 3. First run: splash, intro, setup

Reworked as one flow on 2026-09-26. Updated 2026-10-07 to agree with the
specifications written that day: `01-accounts.md` (the profile is created from
Today, never in setup), `02-notifications.md` (reminders are on by default),
`07-simran.md` (the city comes from the profile) and `08-sangat.md` (invites
can arrive before setup). Where this file and those disagree, they win.
Section 3.10 lists what changed.

---

## 3.1 Purpose

Get somebody from tapping the icon to reading a bani with as little between
them and it as possible, while collecting the things the app genuinely cannot
work without, and nothing else.

## 3.2 What exists today

```
Android system splash (SplashScreen API, app mark on #0C0F24)
  -> Hazri's own branded splash, held 1500 ms, first launch only
  -> Intro, 3 screens
  -> Setup 1: language
  -> Setup 2: reading preferences + elder mode
  -> Setup 3: reminders, city, notification permission, exact-alarm permission
  -> Today
```

`splash_screen.dart` reads `onboardingDone`: true goes straight to Today, false
waits 1500 ms and goes to the intro. The router redirects anyone not onboarded
to the intro and anyone onboarded away from it.

What is wrong with it: two splashes; everything asked up front, before a line
of Gurbani has been seen; the city asked before it means anything; permissions
asked before the reader knows what they are for; no skip; and nothing asked
again later.

## 3.3 The flow

```
Android system splash
  -> Welcome      (first run only)
  -> Language
  -> How you read
  -> Today        (profile banner, Set Goal card; 3.5)
  -> Join screen  (only if an invite arrived; F7)
```

Nothing else is part of setup. No profile, no city, no reminder and no
Sangat. The one thing that appears outside these steps is Android's own
notification prompt at launch (F5, F-5).

## 3.4 The behaviour

**F1. One splash, not two.** The branded splash hold is deleted. The Android
system splash covers the launch and shows the app mark; Flutter's first frame
follows it. `Routes.splash` stops being a screen and becomes a redirect made
before the first frame: onboarding done → Today; not done → Welcome. Nothing
is ever held in front of anybody for a fixed time.

**F2. Three questions, then the app.**

- **Welcome** (owner, 2026-10-08: option D, "a day with Hazri"): one screen. The app mark and name; the headline `welcomeTitleLead` with `welcomeTitleWord` ("Waheguru") in kesri; then one day as a timeline of five cards, which is how the app's features are introduced: the 04:00 Amrit Vela reminder, the hazri marked, the daily goal, the sangat group, the streak in the diary. The timeline is a fixed illustration, the same on every phone, never the reader's own data. One button, **Begin**. No carousel, no dots, no swipe.
- **Language:** ਪੰਜਾਬੀ / हिन्दी / English. Applies the moment it is tapped, which is also the demonstration.
- **How you read:** script and text size, shown against a real line of Gurbani from `content.db`. Elder mode is offered here as one obvious option ("Larger text and simpler screens").

Drawn as designs 91 (Android's splash), 92 (Welcome), 93 (Language) and 94
(How you read), 2026-10-08. The app's name on every one of them is Hazri
(`appName`, `appNameNative`); designs 02-08 are the Phase 1 set and say
"Ang Sang", and are superseded.

| Key | English |
| --- | --- |
| `welcomeTitleLead` | From Amrit Vela to bedtime, mark your hazri to |
| `welcomeTitleWord` | Waheguru. |
| `welcomeAmritVelaTime` | 4:00 AM |
| `welcomeAmritVela` | Amrit Vela |
| `welcomeAmritVelaSub` | A gentle reminder, Japji Sahib is ready |
| `welcomeHazriTime` | 5:10 AM |
| `welcomeHazriSub` | With Japji Sahib (title: the existing "Today's hazri is marked") |
| `welcomeGoalTime` | 6:30 PM |
| `welcomeGoal` | Daily goal · 1 of 2 done |
| `welcomeGoalSub` | Japji Sahib, and 11 minutes of Simran |
| `welcomeSangatTime` | 9:00 PM |
| `welcomeSangat` | Your sangat group |
| `welcomeSangatSub` | 68 of 101 Sukhmani Sahib, together |
| `welcomeStreakTime` | Night |
| `welcomeStreak` | 12 days in a row |
| `welcomeStreakSub` | Kept in your diary |
| `welcomeBegin` | Begin |

Times in the timeline are formatted for the reader's language and are part
of the illustration, not read from the clock. Bani names come from
`content.db` like everywhere else.
| `setupLanguageNote` | You can change it any time in Settings. |
| `elderModeSetup` | Larger text and simpler screens |

Punjabi and Hindi are drafted with the implementation and verified by the
owner (`01-accounts.md` §13.9).

Then Today. That is the whole of setup, and it needs no network.

**F3. The profile is never part of setup.** Today shows the greeting `Welcome`
and the non-dismissible profile banner until a profile exists (`01-accounts.md`
§8.4). Profile Setup is reached from that banner, the person icon on Today, the
globe's banner (`07-simran.md` NP3) and Create in the Sangat (`08-sangat.md`
CG1). Somebody reinstalling restores their profile from Profile Setup by email
link, and is then offered the data restore (`10-backup.md` §8.3).

**F4. The anonymous sign-in never blocks setup.** It starts at launch
(`01-accounts.md` §8.3) and runs alongside setup. Offline, setup completes and
Today shows `ProfileUnavailable`'s banner.

**F5. Everything else is asked in context, once, when it first matters:**

| Asked | When |
| --- | --- |
| Name, email, city | In Profile Setup, when the person chooses to make a profile (F3). The city is picked from the app's list (`01-accounts.md` §13 D9) |
| Notification permission | Android's own prompt, straight away at app start, with no screen of Hazri's before it (F6, F-5) |
| Exact alarms | Never asked. The Notifications screen notes that without them a reminder may arrive some minutes late (`02-notifications.md` DP2) |
| Audio download | The first time play is pressed, with its size (F-3) |
| The Sangat | Never during setup. It is its own tab |

**F6. The notification prompt is Android's, at app start.** Reminders are on
by default (`02-notifications.md` CM7), so `ReminderScheduler.reschedule()`
requests `POST_NOTIFICATIONS` at every app start, as the code does now; on a
first launch that is over Welcome. Android shows its prompt only while it has
no recorded answer and stops showing it after a second "Don't allow", so the
app never nags. After that only the Notifications screen card offers it
(`02-notifications.md` DP3). Reminders are planned whatever the answer;
without permission the Notifications screen says they cannot arrive. Every
other ask is recorded and made once.

**F7. An invite that arrives before setup waits for it.** An App Link
`/j/<code>` opened before onboarding, or a `sangat_code` from the install
referrer (read once on first launch, `08-sangat.md` IV6), is held and opens the
Join screen with the code filled when setup completes. Setup itself is never
interrupted by it. A verification or restore link opened before onboarding is
held the same way and handled when setup completes.

**F8. Setup is resumable and skippable.** Backgrounding mid-setup returns to
the same step with what was chosen kept. **Skip** on How you read is allowed:
Gurmukhi at the standard size, and Settings has all of it.

**F9. The reader reaches Gurbani in under 30 seconds.** The acceptance bar for
the whole flow, and it is measurable.

## 3.5 After setup

The first Today (`05-today.md`) carries `Welcome`, the profile banner, the
hazri banner "not marked yet", the Set Goal card with
`goalSetCardSubtitleFirst` (`04-goals.md` GL1) and the call to action. None
of them blocks reading.

## 3.6 The city

There is one city, the profile city (owner, 2026-10-07, F-4).

- **CY1.** The city is the profile's `cityId`, chosen in Profile Setup and changed only through Edit profile (`07-simran.md` AT5). It is never asked in setup.
- **CY2.** It places the person on the globe and gives the sunrise in the Amrit Vela notification (`02-notifications.md` AV4).
- **CY3. Without a profile there is no city.** Nothing guesses one and nothing defaults to New Delhi: the Amrit Vela notification goes without the sunrise picture, and the Monday message falls back as `02-notifications.md` CM1 says.
- **CY4.** The separate city in Settings is removed.

## 3.7 Scenarios

| # | Given | When | Then |
| --- | --- | --- | --- |
| F-a | A fresh install | Tapping the icon | System splash, then Welcome. No 1.5 s hold, no second splash |
| F-b | At Welcome | Begin, Punjabi, a script, Done | On Today, in Punjabi, in under 30 seconds |
| F-c | At Language | Tapping हिन्दी | The step redraws in Hindi immediately |
| F-d | Setup done | Reopening | Straight to Today |
| F-e | Skip at How you read | — | Gurmukhi, standard size, Today |
| F-f | Backgrounded mid-setup | Reopening | The same step, choices kept |
| F-g | Setup done, offline | First Today | `Welcome`, profile banner, Set Goal card; no spinner |
| F-h | A fresh install | First launch | Android's notification prompt over Welcome; setup continues whatever the answer |
| F-i | "Don't allow" twice | Later app starts | No prompt; the Notifications screen card offers the setting |
| F-j | Permission refused | Opening Notifications | The card; reminders shown as unable to arrive; nothing pretends |
| F-k | Recipient opens `/j/AB12-CD34`, installs from Play | First launch | Setup runs uninterrupted, then the Join screen with the code filled |
| F-l | Hazri installed, not onboarded | Tapping an invite App Link | Welcome; after setup, the Join screen with the code |
| F-m | Reinstall, profile existed | Profile banner → Profile Setup → restore by email | Profile restored; data restore offered (`10-backup.md` §8.3) |
| F-n | Elder mode on | The whole flow | Every step legible at 1.6× with 64 dp targets |
| F-o | Killed during setup | Reopening | Resumes; a half-finished setup never leaves the app unusable |
| F-p | `content.db` fails to open | First run | A real error naming the problem, not a blank screen |
| F-q | Upgrade from a build with `onboardingDone` | First open | Not re-onboarded; Android's prompt if it has no answer yet |
| F-r | No profile | 04:00 Amrit Vela | The text only, no sunrise picture and no city |
| F-s | Profile in Amritsar | 04:00 Amrit Vela | The picture with Amritsar's sunrise |

## 3.8 Migration

Existing installs have `onboardingDone: true` and never see the new flow. The
in-context asks apply to them too: it is how somebody who upgraded finally gets
asked for notification permission, the hole that cost four rounds. A city
already saved in Settings is dropped; the profile city takes over (CY4).

## 3.9 Open decisions

| # | Decision | Status |
| --- | --- | --- |
| F-1 | Does Welcome survive, or go straight to Language? | **Default:** keep it; it is the only place the app introduces itself |
| F-2 | Elder mode offered, or detected from the system font scale? | **Default:** offered, and pre-selected when the font scale is 1.3 or more. Never forced |
| F-3 | Audio pack on Wi-Fi automatically? | **Default:** asked once at first play, then remembered. Never 80 MB unasked |
| F-4 | The Settings city: keep it, or always use the profile city? | **Decided 2026-10-07:** the profile city only; without a profile, no city (3.6) |
| F-5 | Notification permission: a sheet first, or Android's prompt at app start? | **Decided 2026-10-07:** Android's prompt at app start (F6) |

## 3.10 What changed on 2026-10-07

| Before | Now | Source |
| --- | --- | --- |
| City asked when an Auto reminder time is set; a separate Settings city | One city, the profile's; none without a profile | 3.6, F-4 |
| Notification permission asked when a reminder is switched on | Reminders are on by default; Android's prompt at app start | `02-notifications.md` CM7, F-5 |
| Exact alarms asked after the first late reminder | Never asked; a note on the Notifications screen | `02-notifications.md` DP2 |
| The Sangat as a Today card | Its own tab; invites wait for setup | `08-sangat.md` IV6 |
| No profile anywhere | Profile from Today's banner, never in setup | `01-accounts.md` §8.4 |
