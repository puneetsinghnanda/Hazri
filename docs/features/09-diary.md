# 9. Diary

---

## 9.1 Purpose

A record of days that happened — what was read, what was sat, whether hazri was
marked and whether the goals were met. Not a scoreboard, and never a reproach.

## 9.2 What exists today

**The month** (`/diary`, design 57) — a header, a streak card, a grid of days
and the month's stats. Each day cell carries the date and **dots**:

- Dot one, kesri: **hazri** — one paath or one sitting. Always drawn.
- Dot two, sage: **goals met** — drawn **only on a day that had goals**,
  as of this week.

A grace day shows a label instead. Future days are dimmed and not tappable.

**The day** (`/diary/<date>`, design 56, a pushed screen since this week) — the
Nanakshahi date, the hazri banner saying what marked the day and at what time,
the goals line (new this week), tick rows for each bani and simran, the day's
stats, and the note.

**Editing** — today and up to 7 days back can be ticked and unticked by hand.
Older days open read-only and say so on the screen rather than refusing entry.

**The streak** — consecutive nitnem days ending today or yesterday, with **two
grace days per calendar month** granted automatically. Grace days never go
negative and never trigger a warning. No "you broke your streak" copy exists
anywhere, by rule.

**The data** — `DiaryDay {date, slots, isGrace, simran, goals}` from
`diaryMonth`, which reads completions, simran sessions, grace days, goals and
ticks for the month and calls `GoalCalculator.outcomeOn` per day.

## 9.3 Wrong or missing

1. **The stats row is thin.** Paath count, simran minutes and the streak. It
   does not say which banis, or how the month compares to the last.
2. **The note is per day and barely surfaced** — no search, no list, nothing
   that makes a diary feel like a diary somebody keeps.
3. **The 7-day edit window is arbitrary and unexplained.** Why not 14?
4. **`isNitnemDay` counts slot-`none` banis and the streak does not** — §6's
   B3 decides it; the diary must follow the same rule.
5. **Sync is per day, last-writer-wins**, and a genuine two-phone conflict
   silently picks one.
6. **No month-to-month view**, no year, no export of the diary itself — the
   privacy export deliberately excludes it because it never leaves the phone.

## 9.4 The behaviour

**D1 — the diary is a record, not a judgement.** No red, no crosses, no
"missed". An unlit dot is an unlit dot.

**D2 — dots:** one on a day with no goals, two on a day that had them. A grey
second dot on a day nobody set a goal says somebody failed, and they did not.
The legend shows the goals entry only if some day that month had goals.

**D3 — hazri and goals are independent**, and the two dots say so. Most days
the first is lit and the second is not; that is the honest picture, not a
failure.

**D4 — the day screen answers three questions**: was hazri marked and by what,
were the goals met, and what exactly was done. It currently answers all three
as of this week.

**D5 — the past is editable for 7 days**, then read-only, and the screen says
which it is before the reader tries.

**D6 — grace days are silent.** Granted automatically, two a month, never
announced, never a prompt, never something to spend deliberately.

**D7 — everything in the diary works with the radio off.** Sync is a backup,
not the source.

**D8 — one rule for goals**, `GoalCalculator.outcomeOn`, shared with Today and
the day screen. Never re-derived.

## 9.5 Scenarios

**Success**

| Given | When | Then |
|---|---|---|
| A day with Japji read | Opening the month | Kesri dot lit on that day |
| A day with simran only | — | Kesri dot lit; hazri does not need a paath |
| A day with no goals | — | **One** dot |
| A day with 2 goals, 1 met | — | Two dots, the second unlit |
| A day with 2 goals, both met | — | Two dots, both lit |
| A month with no goals at all | Opening it | One dot per day and no goals entry in the legend |
| Tapping a day | — | The day screen, with hazri, the goal outcome and the tick rows |
| A day 3 days back | Ticking Rehras | Logged on that date; goals for that date credited |
| A day 30 days back | Tapping it | Opens read-only and says so |
| One missed day, grace left | — | A grace label; the streak continues; nothing is said about it |
| Sukhmani only | — | Hazri lit, diary dot lit, nitnem streak unchanged (B3) |

**Failure**

| Given | When | Then |
|---|---|---|
| A future day | Tapping it | Not tappable, dimmed |
| The month is the install month | Days before install | No dots, no goals, and not counted as failures |
| A goal existed and was deleted with `forgetGoal` | — | Those days lose their second dot — the data is gone. This is why stopping archives instead |
| Two phones edit the same day | Sync | Merged per slot, not replaced wholesale. A tick on one phone and a different tick on the other must both survive |
| The device timezone changes | — | Days are keyed by local date string; a day never merges into its neighbour |
| `user.db` migration fails | Opening | A real error; the diary is the one thing that must never be silently lost |
| 10 years of history | Opening the month | Only that month is read; the query is bounded already |

## 9.6 Proposed additions

**A year view** — twelve rows of dots. Cheap, and the first thing that makes
somebody feel they have kept something up.

**Notes brought forward** — a list of days that have notes, searchable. A
diary nobody can re-read is a log.

**An honest month summary** — days marked, days with goals met, simran minutes,
banis by name. No comparison to other people, ever.

## 9.7 Open decisions

| # | Decision | Default |
|---|---|---|
| Y-1 | The 7-day edit window | Keep it and say why on the screen: a diary you can rewrite at will is not a record |
| Y-2 | Conflict resolution for two-phone sync | Merge per slot, union of completions. Never last-writer-wins on a whole day |
| Y-3 | Export the diary | Yes, as JSON, from the diary rather than the privacy screen — the privacy export is about what *we* hold, and the diary is not that |

## 9.8 Acceptance

- A test per row of §9.5.
- A test that the month grid and Today agree for every goal shape.
- A test that a month with no goals renders one dot per day and no legend
  entry.
- A test that the diary renders fully with no account and no network.
