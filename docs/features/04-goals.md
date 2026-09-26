# 4. Goals

Rewritten 2026-09-25 against the reader's five scenarios. This file is the
record of what was decided and what is still open.

---

## 4.1 Purpose

A goal is something somebody chose to keep up: *Japji, once a day* or *simran,
eleven minutes, every day* or *Sukhmani, three times a week for a month*. It is
**not** hazri. Hazri is turning up; a goal is finishing the list.

## 4.2 The model

A goal is **one row per thing** — one bani, or simran. "My goal" in the plural
sense is several rows. That is what lets a goal be paath-only, simran-only, or
both, with no extra machinery.

`Goals`: `id, baniId, minutes?, timesPerDay, durationType, days?, untilDate?,
startDate, reminderTime?, endedOn?, active, createdAt, updatedAt`
`GoalTicks`: `id, goalId, localDate, source, at`

`baniId` is a content.db bani id, or the sentinel `kSimranGoalId` for simran.
`minutes` is how long a sitting is and is null for a bani.

### The one rule (`GoalCalculator`)

**G1 — the window.** A goal asks something of a day if that day is on or after
`startDate` and on or before `lastDayOf(goal)`, where the last day is the
earliest of: `startDate + days − 1`, `untilDate`, and `endedOn`. Open-ended
goals have no last day.

**G2 — outside the window the goal is absent, not unmet.** This is the whole
basis of the Diary's dots.

**G3 — met means met.** A goal is met on a day when its ticks on that day reach
`timesPerDay`. Not one tick. Not "any".

**G4 — one function.** `outcomeOn(goals, ticks, day)` returns `GoalDay(inScope,
met)`. Today's card, the Diary grid and the Diary day screen all call it and
**nothing re-derives it**.

### Crediting

**G5.** A completion credits its goals from inside the repository —
`creditGoalsFor` from `logCompletion`'s callers, and from inside `logSimran`
for simran — so a new path cannot forget. Extra paath beyond `timesPerDay` is
not counted twice.

**G6.** Undoing a completion takes back only the ticks the app added
automatically. A tick added by hand on the Goals screen is the person's and
stays.

### Stopping

**G7.** Stopping a goal **archives** it: `endedOn` = today, `active` = false,
every tick kept. The days it covered keep their marks.

**G8.** `forgetGoal` erases the row and its ticks, for a goal set by mistake.
It is the only destructive option and is named as such.

**G9.** Starting a stopped goal again inserts a **new row from today**. One row
carries one stretch of days; reopening the old one would pull the paused gap
back into scope and darken all of it.

## 4.3 What is missing

1. **No weekly goals.** `timesPerDay` and a duration in days is all there is.
   "Three times a week" cannot be expressed, and it is the commonest real goal
   after "every day".
2. **No goal history screen.** Archived goals have all their data and nowhere
   to be seen. Somebody who kept Japji for 40 days should be able to look at
   that.
3. **Points and badges (§3.2) are blocked** on D14: §0 says "No points or XP
   for Gurbani" and a points system fed by reading Gurbani is what that
   sentence exists to prevent.
4. **The goal-complete sheet is all-or-nothing.** It fires when every goal is
   met. With five goals it may never fire.
5. **No sense of a streak per goal**, only the global nitnem streak.

## 4.4 Scenarios

**Success**

| Given | When | Then |
|---|---|---|
| Japji ×1 daily | Japji is read | The goal is met; Today says 1 of 1; the Diary's green dot lights |
| Japji ×3 daily | One paath | Not met. Today says 0 of 1 done, the dot stays dark, the ring shows a third |
| Japji ×3 daily | Three paath | Met, everywhere, at the same moment |
| Simran 11 min | A sitting completes | Credited; hazri marked; both, independently |
| Simran 11 min | A sitting ended at 4 min | Nothing credited. An incomplete sitting marks nothing, anywhere |
| A 7-day goal, all kept | Day 8 | Days 1–7 green; day 8 has no second dot at all |
| A finished goal + a live one | The live one is met | Green. The finished one does not spoil it |
| A goal stopped on the 22nd | Looking at the month | 1st–22nd have two dots as they were; the 23rd has one |
| A goal started today | Looking at last month | No second dot on any of those days |
| Every goal met | The last tick | The completion sheet, once, that day only |

**Failure**

| Given | When | Then |
|---|---|---|
| No goals at all | Any day | One dot. Today shows the "set a goal" card, not "0 of 0" |
| A goal for a bani not in content.db | Loading | The row is skipped and reported, never a crash or a blank name |
| A tick and then the bani is unticked in the Diary | — | Only the automatic tick is removed; a hand tick survives |
| Two devices both credit the same goal | Sync | Ticks are UUID rows, so they merge; the cap at `timesPerDay` is applied on read, not on write |
| The clock moves backwards across midnight | — | Ticks are keyed by local date string, so a day never merges into its neighbour |
| A goal whose `startDate` is in the future | Today | Not in scope, not counted, and shown as starting on a date |
| 50 goals | Today's card | Scrolls; the ring is the sum of targets, not of rows |

## 4.5 Proposed additions

**Weekly goals.** Add `perWeek` alongside `timesPerDay`; `outcomeOn` gains a
week-scope branch. A weekly goal is met when the week's ticks reach the target,
and a day inside an unmet week is *neutral*, not failed — it gets no second
dot until the week closes. This needs a decision on what the Diary shows
mid-week, which is G-1 below.

**Goal history.** A screen listing archived goals with their span, how many
days were kept, and the best run. All data already exists.

**Per-goal streaks.** Derived, never stored, from ticks within the window.

## 4.6 Open decisions

| # | Decision | Default |
|---|---|---|
| G-1 | What the Diary shows mid-week for a weekly goal | Neutral until the week closes, then one verdict applied to the week. Never a red day inside a week that could still be met |
| G-2 | Should the completion sheet fire per goal, or only when all are done? | Only when all are done, as now. A sheet that appears five times a day stops meaning anything |
| G-3 | D14: may a points system score Gurbani when §0 forbids it? | **Blocker.** Score simran, sewa and diary days; never a bani read. Or amend §0 in the same commit |
| G-4 | Can a goal be shared into a group as a personal goal? | Not in this pass. Group goals are §8 and are a different thing |

## 4.7 Acceptance

- `test/features/goal_day_test.dart` — the five scenarios, already written.
- A test per row of §4.4, both tables.
- A test that Today's card and `diaryMonth` agree for every combination of
  `timesPerDay` ∈ {1,3} × ticks ∈ {0,1,3}.
- A test that archiving keeps ticks and `forgetGoal` does not.
