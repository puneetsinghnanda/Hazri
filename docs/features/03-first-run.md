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

Nothing else is part of setup. No profile, no city, no reminder, no
permission, no Sangat.

## 3.4 The behaviour

**F1. One splash, not two.** The branded splash hold is deleted. The Android
system splash covers the launch and shows the app mark; Flutter's first frame
follows it. `Routes.splash` stops being a screen and becomes a redirect made
before the first frame: onboarding done → Today; not done → Welcome. Nothing
is ever held in front of anybody for a fixed time.

**F2. Three questions, then the app.**

- **Welcome:** one screen, the app mark and three lines saying what hazri means and what the app is for. One button, **Begin**. No carousel, no dots, no swipe.
- **Language:** ਪੰਜਾਬੀ / हिन्दी / English. Applies the moment it is tapped, which is also the demonstration.
- **How you read:** script and text size, shown against a real line of Gurbani from `content.db`. Elder mode is offered here as one obvious option ("Larger text and simpler screens").

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
| Notification permission | A short sheet on the first Today after setup explains the 04:00 Amrit Vela reminder, with **Allow** (the system dialog) and **Not now** (F6, F-5) |
| Exact alarms | Never asked. The Notifications screen notes that without them a reminder may arrive some minutes late (`02-notifications.md` DP2) |
| Audio download | The first time play is pressed, with its size (F-3) |
| The Sangat | Never during setup. It is its own tab |

**F6. Nothing is asked twice, and "Not now" is a real answer.** Each ask is
recorded. The notification permission is offered at most twice by the app:
the first-Today sheet, and once more when a goal item with a reminder time is
saved. After that only the Notifications screen card offers it
(`02-notifications.md` DP3). Reminders are planned whatever the answer; without
permission the Notifications screen says they cannot arrive.

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
`goalSetCardSubtitleFirst` (`04-goals.md` GL1), the call to action and the
notification sheet of F5. None of them blocks reading.

## 3.6 The city

Two things are called the city, and they are kept apart:

- **The profile city** (`cityId`) places the person on the globe. It is chosen in Profile Setup and changed only through Edit profile (`07-simran.md` AT5).
- **The Settings city** computes sunrise for the Amrit Vela notification's picture (`02-notifications.md` AV4) and the date line. It is never asked in setup. Until it is set it is the profile city when there is a profile, else New Delhi, and Settings says which (F-4).

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
| F-h | First Today | — | The notification sheet once; Allow shows the system dialog |
| F-i | "Not now" on the sheet | Later saving a goal item with a reminder time | Offered once more; after that only the Notifications screen card |
| F-j | Permission refused | Opening Notifications | The card; reminders shown as unable to arrive; nothing pretends |
| F-k | Recipient opens `/j/AB12-CD34`, installs from Play | First launch | Setup runs uninterrupted, then the Join screen with the code filled |
| F-l | Hazri installed, not onboarded | Tapping an invite App Link | Welcome; after setup, the Join screen with the code |
| F-m | Reinstall, profile existed | Profile banner → Profile Setup → restore by email | Profile restored; data restore offered (`10-backup.md` §8.3) |
| F-n | Elder mode on | The whole flow | Every step legible at 1.6× with 64 dp targets |
| F-o | Killed during setup | Reopening | Resumes; a half-finished setup never leaves the app unusable |
| F-p | `content.db` fails to open | First run | A real error naming the problem, not a blank screen |
| F-q | Upgrade from a build with `onboardingDone` | First open | Not re-onboarded; the notification sheet once if permission is not granted |
| F-r | No profile, Settings city never set | Amrit Vela picture | Sunrise for New Delhi, and Settings says so |

## 3.8 Migration

Existing installs have `onboardingDone: true` and never see the new flow. The
in-context asks apply to them too: it is how somebody who upgraded finally gets
asked for notification permission, the hole that cost four rounds. An install
that already has a Settings city keeps it.

## 3.9 Open decisions

| # | Decision | Status |
| --- | --- | --- |
| F-1 | Does Welcome survive, or go straight to Language? | **Default:** keep it; it is the only place the app introduces itself |
| F-2 | Elder mode offered, or detected from the system font scale? | **Default:** offered, and pre-selected when the font scale is 1.3 or more. Never forced |
| F-3 | Audio pack on Wi-Fi automatically? | **Default:** asked once at first play, then remembered. Never 80 MB unasked |
| F-4 | The Settings city: keep it, or always use the profile city? | **Open.** Default: keep it (3.6), following the profile city until set |
| F-5 | Notification permission: first-Today sheet, or the system dialog at app start as the code does now? | **Open.** Default: the sheet (F5), because Amrit Vela and the Hazri nudge are on by default and the earlier rule, "ask when a reminder is switched on", no longer has a moment to happen in |

## 3.10 What changed on 2026-10-07

| Before | Now | Source |
| --- | --- | --- |
| City asked when an Auto reminder time is set | No Auto times; profile city in Profile Setup, Settings city defaults | `07-simran.md`, 3.6 |
| Notification permission asked when a reminder is switched on | Reminders are on by default; a sheet on the first Today | `02-notifications.md` CM7, F-5 |
| Exact alarms asked after the first late reminder | Never asked; a note on the Notifications screen | `02-notifications.md` DP2 |
| The Sangat as a Today card | Its own tab; invites wait for setup | `08-sangat.md` IV6 |
| No profile anywhere | Profile from Today's banner, never in setup | `01-accounts.md` §8.4 |
