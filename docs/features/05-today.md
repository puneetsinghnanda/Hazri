# 5. Today — the home screen

Updated 2026-10-07 to agree with the specifications written that day:
`01-accounts.md` (the greeting and the profile banner, §8.4), `04-goals.md`
(the Set Goal card, the goal widget and `verdictOn`, §7.1), `07-simran.md`
(attendance) and `08-sangat.md` (the Sangat lives in its own tab). Where this
file and those disagree, they win. Section 5.10 lists what changed.

---

## 5.1 Purpose

Answer one question in the first second: **have I turned up today, and what is
next?** Everything else on the screen is secondary to that.

## 5.2 What exists today

Top to bottom (`today_screen.dart`):

1. `TabHeader`: menu button, "Today", the date (Gregorian and Nanakshahi).
2. `HazriBanner` (designs 58/59): kesri gradient when marked, saying what
   marked it and at what time; a quiet card saying "not marked yet" otherwise.
   Shown to everybody.
3. `_GoalsCard` (design 30): "n of m done today" across all goals, with a
   ring; `_NoGoalsCard` when there are none.
4. The Vichar card: ਅੱਜ ਦਾ ਵਿਚਾਰ, the day's line, share and Explore, which opens the day's line in full (owner, 2026-10-10; it used to open the library).
5. The Nitnem call to action: Start or Continue, naming the bani and its
   minutes, opening the reader at the saved line.
6. The Gurpurab card when one is near.
7. The join-the-sangat banner, until joined or dismissed.

`ElderTodayScreen` is a separate widget for elder mode.

What is wrong with it: there is no greeting and no way to a profile; the goals
card counts goals, not goal items, and uses `GoalCalculator`; the join banner
stacks on the hazri banner; elder mode is a fork that has drifted twice; the
call to action does not know about goals.

## 5.3 Order of the screen

| # | Element | Shown when | Source |
| --- | --- | --- | --- |
| 1 | App bar: menu, the Hazri mark and name, a person icon opening `/profile`; under them the greeting (`Welcome, {name}` in `ProfileLoaded`, else `Welcome`) and the date | Always | T11, T8, `01-accounts.md` §8.4 |
| 2 | `ProfileBanner`: "Set up your profile" | Only in `ProfileNone` or `ProfileUnavailable`. Not dismissible | `01-accounts.md` §8.4 |
| 3 | Hazri banner | Always, unless marked and closed for the day | T1, T1a |
| 4 | Streak card | When the hazri streak is 2 days or more | T12 |
| 5 | Set Goal card, or the goal widget | Always, one or the other | `04-goals.md` §7.1 |
| 6 | Call to action | When `content.db` has a bani to offer | T4 |
| 6a | Gurmat Quiz: the calendar leaf (1A, no buttons) and the quiz card (D), drawn as 113 | When `content.db` has quiz topics; in elder mode too | `14-quiz.md` QZ9 |
| 6b | Saakhis card (option C, design 113; was 110) | When `content.db` has a saakhi; in elder mode too | `13-saakhi.md` SK11, SK15 |
| 7 | Vichar card | When the dataset has a line for the date | T6 |
| 8 | Gurpurab card | When one is near | unchanged |

There is no join-the-sangat banner. The Sangat is reached from its tab and the
menu (`08-sangat.md` §8.1).

## 5.4 The behaviour

**T1. Hazri is the first card, always.** Only the app bar and, when there is
no profile, the profile banner sit above it. It reads only
`hazri(today)` (`04-goals.md` HZ1–HZ4: any completion, or a sitting of 300
seconds or more). It needs no profile, no network and no goal, and it is never
hidden before it is marked.

**T1a. A marked banner can be closed for the day** (owner, 2026-10-10). Once
today's hazri is marked the banner carries a close button (`actionClose`).
Closing it folds the banner away in about 300 ms and the cards below move up
with it; the day is kept in `hazri_banner_closed_v1` (a local date key), so it
stays closed through restarts that day. The next day it is back, unmarked. An
unmarked banner has no close button.

**T2. One banner of each kind, none stacking.** The profile banner shows only
without a profile and goes the moment one exists. The join-the-sangat banner is
removed, so hazri never shares the top of the screen with an invitation.

**T3. The goal card is `04-goals.md` §7.1 and nothing of its own.** No goal
ever: the Set Goal card with `goalSetCardSubtitleFirst`. Last goal completed:
the same card with `goalSetCardSubtitleAgain`. An active goal: the goal widget,
`itemsMet` of `itemsInScope` from `verdictOn(today)` with a ring, and one row
per in-scope item ("1 of 3" for a bani; minutes and a tick for simran). Tapping
the header opens Goals; tapping a row opens the reader or the Simran menu.

**T4. The call to action names the single most useful next thing**, in this
order:

1. a paath in progress (opened and not completed today) → Continue, at the saved line;
2. the first goal item in scope today that is not yet met, in the goal's order → its bani, or the Simran menu with the item's minutes;
3. the current slot's first bani not completed today;
4. the next slot's first bani.

It says what it is and how long it takes. Which item is "not yet met" comes
from `verdictOn`, never from a count of its own.

**T5. Elder mode is a mode, not a screen.** One widget tree; elder mode changes
sizes, spacing and which of the secondary cards (7, 8) appear. The fork goes.

**T6. Every card opens the thing it describes**, and no card is a dead end. A
card with no data (no Vichar line for the date, no bani for the slot) is
omitted, never shown blank and never filled with an invented line.

**T7. Today works entirely offline.** Nothing on it waits on a network call.
The greeting comes from the profile cache (`01-accounts.md` §8.2), so the name
shows offline. The attendance call (`07-simran.md` AT1) runs at start and
resume, fire and forget, and Today never waits on it. Nothing on Today shows a
Sangat number.

**T8. The profile is one tap away.** The person icon in the header opens
`/profile` (`01-accounts.md` §8.4, §8.7); without a profile that screen offers
Set up profile.

**T9. The goal-complete sheet appears once a day**, when today's `goalState`
becomes `MET`, from wherever the last item was met, and never for a backfilled
past day (`04-goals.md` CE1).

**T10. Midnight rolls Today over** with the app open: hazri resets, the date
changes, items re-scope, the streak card's week moves on and the CTA is
recomputed. The day is the device's local date (`04-goals.md` §2).

**T11. The app bar** (owner, 2026-10-07: canvas option D). Today only; every
other tab keeps its own tab header.

- A band across the top, `primary` (Neela `#262C63`) in light and `card2` in dark, with bottom corners of radius 28 dp and white text.
- First row: the menu button (44 dp, white at 12% behind it), the sunrise mark and `appBarTitle` ("Hazri") in Baloo Paaji 2 at 22 sp, and the round person button (44 dp) on the right (T8).
- Second row: the greeting at 24 sp and, under it, the date (Gregorian and Nanakshahi) at 13 sp in white at 78%.
- The first card below overlaps the band by 32 dp: the profile banner when it is shown, else the hazri banner.
- In elder mode the band keeps its layout and the type grows with the rest of the screen.

**T12. The streak card** (owner, 2026-10-07: canvas option Streak 3). Under the
hazri banner, a card with the number of days (`todayStreakDays`, e.g. "12") over
`todayStreakCaption` ("days of Hazri in a row", owner 2026-10-10), and a strip of the last seven
days: a weekday initial over a dot, saffron for a day that counts toward the
streak and unlit otherwise, today's dot ringed. Tapping it opens the Diary.

- The number is `current` from `hazriStreak(today)` (`09-diary.md` D12), the same function the Diary uses.
- The card is shown only when `current` is 2 or more. Below that it is not shown at all: no "0 days", no "1 day", and nothing said when a streak ends.
- A grace day keeps the count going and its dot is unlit, saying nothing (`09-diary.md` D8).
- Today's dot lights the moment today's Nitnem is done; until then the count is the streak through yesterday.

## 5.5 Scenarios

| # | Given | When | Then |
| --- | --- | --- | --- |
| T-a | Fresh install, setup done, online | Opening Today | `Welcome`; profile banner; hazri "not marked yet"; Set Goal card (first); CTA offers the slot's first bani |
| T-b | Profile saved as Harpreet | Back on Today | `Welcome, Harpreet`; the profile banner has gone |
| T-c | Profile exists, aeroplane mode, cold start | Opening Today | `Welcome, Harpreet` from the cache; no banner; nothing spins |
| T-d | No cache, never online since install | Opening Today | `Welcome`; profile banner (`ProfileUnavailable`); the rest of the screen complete |
| T-e | Japji read at 05:10 | Opening Today | Hazri marked, saying Japji Sahib and 5:10 AM |
| T-f | A 5-minute sitting, no paath | Opening Today | Hazri marked, saying Naam Simran |
| T-g | A 4-minute sitting only | Opening Today | Not marked yet |
| T-h | Goal Japji ×3 and Simran 11 min; Japji read once | Opening Today | Widget "0 of 2", rows "1 of 3" and "11 min"; CTA offers Japji Sahib |
| T-i | Same goal, Japji ×3 done | Opening Today | "1 of 2"; CTA offers the Simran menu with 11 min |
| T-j | Both met by the last sitting | The sitting ends | "2 of 2"; the sheet once; reading again shows no second sheet |
| T-k | Last goal completed yesterday | Opening Today | Set Goal card with `goalSetCardSubtitleAgain` |
| T-l | Rehras half read | Opening Today | CTA "Continue Rehras Sahib" at the saved line, ahead of any goal item |
| T-m | Elder mode on | Opening Today | Same content and order, larger; hazri, the goal card and the sheet all present |
| T-n | The app open across midnight | — | Hazri resets, date changes, items re-scope |
| T-o | The device clock jumps a day | — | Follows the device's local date; nothing cleverer |
| T-p | `content.db` has no bani for the slot | — | CTA hidden; the rest stands |
| T-q | No Vichar line for the date | — | The card is omitted |
| T-r | Member of a Sangat group | Opening Today | No Sangat banner or number on Today |
| T-s | Person icon tapped, no profile | — | Profile screen with Set up profile |
| T-t | Nitnem done each of the last 12 days, today included | Opening Today | Streak card "12", seven saffron dots, today ringed |
| T-u | Streak of 11 through yesterday, nothing yet today | Opening Today | "11"; six saffron dots and today's unlit and ringed; reading Japji lights it and shows "12" |
| T-v | No Nitnem yesterday or today | Opening Today | No streak card; nothing said |
| T-w | No profile | Opening Today | App bar with `Welcome`; the profile banner overlaps the band; the hazri banner below it |
| T-x | Diary tab opened | — | Its own tab header, no app bar |

## 5.6 Open decisions

| # | Decision | Status |
| --- | --- | --- |
| T-1 | Does the day arc come back? | **Default:** no. The goal widget answers the same question with a number |
| T-2 | Streak on Today? | **Decided 2026-10-07:** yes, as the week-strip card (T12); in the Diary as the two-number card (`09-diary.md` D12) |
| T-3 | Merge elder mode into one tree now or later? | **Default:** now, with this rework |
| T-4 | `01-accounts.md` §8.4 has an app bar titled "Hazri"; the app has no brand bar (CLAUDE.md) | **Decided 2026-10-07:** the navy app bar of T11, on Today only. CLAUDE.md's "no brand bar" now describes the other tabs |
| T-5 | CTA order puts an unmet goal item before the slot's bani (T4) | **Decided 2026-10-07:** as written, because the goal is what the person chose |

## 5.7 Acceptance

- Widget tests for every row of 5.5, in all three languages.
- A test that Today renders fully in `ProfileNone`, `ProfileUnavailable` and `ProfileLoaded(isStale: true)`.
- A test that Today makes **no** network call on build and that a hanging attendance call changes nothing on screen.
- One test feeding Today, the Goals screen and the Diary the same rows and checking they agree (`04-goals.md` §9).
- Golden renders at 390×844, light and dark, normal and elder.

## 5.7a Strings

| Key | English |
| --- | --- |
| `appBarTitle` | Hazri |
| `todayStreakDays` | {count} (the number alone, formatted for the language) |
| `todayStreakCaption` | days of Hazri in a row |

Punjabi and Hindi are drafted with the implementation and verified by the
owner (`01-accounts.md` §13.9).

## 5.8 Out of scope

- Sangat numbers or banners on Today.

## 5.9 Dependencies

Greeting and banner: `01-accounts.md`. Hazri, goals, the sheet: `04-goals.md`.
CTA: `06-nitnem.md`. Attendance: `07-simran.md`.

## 5.10 What changed on 2026-10-07

| Before | Now | Source |
| --- | --- | --- |
| No greeting, no route to a profile | `Welcome, {name}`, the profile banner and a person icon | `01-accounts.md` §8.4 |
| Goals card counts goals, "n of m done" | Goal widget counts items in scope via `verdictOn` | `04-goals.md` §7.1 |
| `_NoGoalsCard` | Set Goal card, two subtitles, not dismissible | `04-goals.md` GL1 |
| Join-the-sangat banner, dismissible | Removed; the Sangat is its own tab | `08-sangat.md` §8.1 |
| CTA: slot bani before goals | Paath in progress, then unmet goal item, then slot bani | T4, T-5 |
| Sangat numbers from cache, marked stale | No Sangat number on Today | T7 |
| Simran marks hazri | Only a sitting of 300 s or more | `04-goals.md` HZ1, HZ3 |
| Tab header "Today" | Navy Hazri app bar with the greeting, Today only | T11 |
| No streak on Today | Week-strip streak card from 2 days | T12 |
