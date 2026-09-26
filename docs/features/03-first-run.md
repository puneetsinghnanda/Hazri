# 3. First run: splash, intro, setup

Reworked as one flow. Decided 2026-09-26.

---

## 3.1 Purpose

Get somebody from tapping the icon to reading a bani with as little between
them and it as possible — while collecting the two things the app genuinely
cannot work without, and nothing else.

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

`splash_screen.dart` reads `onboardingDone`: if true it goes straight to Today
with no delay; if false it waits 1500 ms then goes to the intro. The router
redirects anyone not onboarded back to the intro, and anyone onboarded away
from it. Audio downloads start in the background (PRD 1.2).

## 3.3 Wrong or missing

1. **Two splashes.** The system one and then a branded one. The second is a
   1.5-second wall in front of somebody who came to read.
2. **Everything is asked up front.** Language, script, text size, elder mode,
   city, reminder times and two permissions — before a single line of Gurbani
   has been seen. The person has no context for any of it.
3. **The city is asked before it means anything.** It exists to compute sunrise
   for Amrit Vela. Asked at setup it is a form field; asked when setting an
   Amrit Vela reminder it is obvious.
4. **Permissions are asked at their worst moment** — before the reader knows
   what a reminder is for. A refusal here is permanent and, until this week,
   silent.
5. **No skip.** Every step must be walked through.
6. **Nothing is asked again later.** Tap Later once and it is Settings or
   nothing.

## 3.4 The behaviour

### F1. One splash, not two

Delete the branded splash hold entirely. The Android system splash covers the
launch; Flutter's first frame follows it. `Routes.splash` stops being a screen
and becomes a redirect decision made before the first frame:

- onboarding done → Today
- not done → Welcome

Nothing is held in front of anybody for a fixed time, ever. **The app mark
still shows** — on the system splash, which is what that API is for.

### F2. Three questions, then the app

Only what the app cannot start without:

**Welcome** — one screen. What hazri means and what the app is for, in three
lines and the app mark. One button: **Begin**. No carousel, no dots, no swipe.

**Language** — ਪੰਜਾਬੀ / हिन्दी / English. Applies immediately as it is tapped,
which is also the demonstration.

**How you read** — script and text size, shown against a real line of Gurbani
so the choice is visible rather than abstract. Elder mode is offered here as
**one** obvious option ("Larger text and simpler screens"), not buried.

Then Today. That is the whole of setup.

### F3. Everything else is asked in context, once, when it first matters

| Asked | When |
|---|---|
| The city | The first time an Auto reminder time is set, or the first time Today shows a sunrise. Never as a form field |
| Notification permission | The first time a reminder is switched on — not before |
| Exact alarms | Only if they set a reminder and only after the first one lands late. Never up front |
| Audio download | The first time they press play, with the size |
| The sangat | Never during setup. It is opt-in and it is a Today card they can ignore for ever |

### F4. Nothing is asked twice, and "Later" is a real answer

Each ask is recorded. A refused ask is offered again only when the person does
the thing it is for, and never more than twice in total.

### F5. Setup is resumable and skippable

Backgrounding mid-setup returns to the same step. **Skip** on the reading
screen is allowed; the defaults are Gurmukhi at the standard size, and
Settings has all of it.

### F6. The reader reaches Gurbani in under 30 seconds

This is the acceptance bar for the whole flow, and it is measurable.

## 3.5 Scenarios

**Success**

| Given | When | Then |
|---|---|---|
| A fresh install | Tapping the icon | System splash, then Welcome. No 1.5s hold, no second splash |
| At Welcome | Begin, pick Punjabi, pick script, Done | On Today, in Punjabi, in under 30 seconds |
| At the language step | Tapping हिन्दी | The step itself redraws in Hindi immediately |
| Setup done | Reopening the app | Straight to Today. No splash, no intro |
| Setup skipped at the reading step | — | Gurmukhi, standard size, Today. Settings still has everything |
| Backgrounded mid-setup | Reopening | The same step, with what was chosen kept |
| Never set a reminder | Ever | Never asked for notification permission. The app is silent and complete |
| Sets an Amrit Vela reminder | Choosing Auto | *Then* asked for a city, with a reason |

**Failure**

| Given | When | Then |
|---|---|---|
| Notification permission refused at F3 | — | The reminder is saved and shown as unable to arrive, with a way back. Setup is never blocked |
| Location/city cannot be determined | Auto chosen | Falls back to the chosen city, then to New Delhi, and says which |
| Elder mode on | The whole flow | Every step is legible at 1.6× with 64dp targets. Elder mode is tested through setup, not only after it |
| The app is killed during setup | Reopening | Resumes; a half-finished setup never leaves the app unusable |
| `content.db` fails to open | First run | A real error naming the problem, not a blank screen or a spinner |
| Upgrading from a build that had onboarding | First open | Not re-onboarded. `onboardingDone` is honoured and the new asks happen in context |

## 3.6 Migration

Existing installs have `onboardingDone: true` and must never see the new flow.
The in-context asks (F3) apply to them too, which is a **feature**: it is how
somebody who upgraded finally gets asked for notification permission — the
exact hole that cost four rounds.

## 3.7 Open decisions

| # | Decision | Default |
|---|---|---|
| F-1 | Does Welcome survive at all, or go straight to language? | Keep it. One screen that says what hazri means is the app introducing itself, and it is the only place that ever does |
| F-2 | Elder mode on the reading screen, or detected from the system font scale? | Offer it, **and** pre-select it when the system font scale is ≥1.3. Never force it |
| F-3 | Does the audio pack download on wifi automatically? | Ask once at first play, then remember. Never download 80 MB unasked |

## 3.8 Acceptance

- A test that walks install → reading a bani and asserts the step count.
- A test that no permission is requested anywhere in setup.
- A test that an existing install with `onboardingDone` never sees Welcome.
- Golden renders of every step in all three languages and in elder mode.
- Device: time the run. Under 30 seconds or it is not done.
