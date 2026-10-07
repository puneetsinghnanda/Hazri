# 9. Diary

Updated 2026-10-07 to agree with the specifications written that day:
`04-goals.md` (the dots, the day screen, editing), `10-backup.md` (backup and
restore replace diary sync) and `08-sangat.md` (Diary edits count toward
groups). Where this file and those disagree, they win. Section 9.9 lists what
changed.

---

## 9.1 Purpose

A record of days that happened: what was read, what was sat, whether hazri was
marked and whether the goal was met. Not a scoreboard, and never a reproach.

## 9.2 What exists today

**The month** (`/diary`, design 57): a header, a streak card, a grid of days
and the month's stats. **The day** (`/diary/<date>`, design 56): the
Nanakshahi date, the hazri banner, the goal line, rows for each bani and
simran, and the day's stats. **The streak**: consecutive nitnem days ending
today or yesterday, with two grace days per calendar month granted
automatically. The month is read by `diaryMonth`.

The code still follows the earlier model (one completion per bani per slot per
day, goal ticks, `GoalCalculator`). `04-goals.md` §10.2 lists what changes.

## 9.3 The behaviour

**D1. A record, not a judgement.** No red, no crosses, no "missed". An unlit
dot is an unlit dot.

**D2. The dots are `04-goals.md` §4.7.** The first dot is hazri (orange when
marked, grey when not). The second dot appears only on a day that had a goal
item in scope: green when the goal was met, grey when not. Future days and days
before the first recorded day (`04-goals.md` DV3) have no dots. The legend
shows the goal entry only when some day that month had a goal (`04-goals.md`
§7.4).

**D3. Hazri and the goal are separate**, and the two dots say so. Green never
appears without orange (`04-goals.md` DV1).

**D4. One rule.** Both dots come from `verdictOn` (`04-goals.md` §4.6), the
same function Today and the Goals screen use. Nothing here re-derives them.

**D5. The day screen is `04-goals.md` §7.5**: the hazri line; the goal block
when the day had a goal; every bani completed that day with its count, times
and source (Read, Listened, Marked in Diary, Restored, Carried over); simran
sittings with minutes and "stopped early"; and + and − for each bani and
Naam Simran.

**D6. Editing: today and the 7 days before it**, then read-only, and the screen
says which before anybody tries (`04-goals.md` §3 `DIARY_EDIT_WINDOW_DAYS`).
"+" adds one completion (or one sitting); "−" undoes the newest one, whatever
its source (`04-goals.md` CR3, CR4). The Diary itself has no daily cap.

**D7. Edits reach the sangat.** A "+" or "−" for a bani or simran that a group
of the person's counts is added to the Sangat outbox. Toward a group, at most
3 Diary additions per member per group per day count (`08-sangat.md` CT4,
CT5); the Diary still shows every one.

**D8. Grace days are silent.** Granted automatically, two a month, never
announced, never a prompt, never something to spend deliberately. Unchanged.

**D9. The streak counts nitnem.** A bani of slot `none` (Ardas, Sukhmani Sahib)
marks hazri and does not extend the nitnem streak (`06-nitnem.md` B3).

**D10. Everything works offline.** The Diary reads and writes only `user.db`.

**D11. Backup and restore are `10-backup.md`.** Completions and sittings are
backed up weekly with a profile. A restore adds what the phone lacks and never
changes what it has (RS3, RS4). There is no diary sync switch and no per-day
sync any more.

## 9.4 Scenarios

| # | Given | When | Then |
| --- | --- | --- | --- |
| Y-a | Japji read on a day | Opening the month | Orange first dot |
| Y-b | A day with simran only (5 min or more) | — | Orange; hazri needs no paath |
| Y-c | A day with no goal item in scope | — | One dot |
| Y-d | A goal of two items, one met | — | Orange and a grey second dot |
| Y-e | Both met | — | Orange and green |
| Y-f | A month with no goals at all | Opening it | One dot per day and no goal entry in the legend |
| Y-g | Japji read twice on a day | Opening that day | "Japji Sahib ×2" with both times |
| Y-h | Three days back | + Rehras | Logged on that date; that day's verdict recomputed |
| Y-i | Thirty days back | Tapping it | Opens read-only and says so |
| Y-j | One missed day, grace left | — | A grace label; the streak continues; nothing is said |
| Y-k | Sukhmani Sahib only | — | Hazri marked; nitnem streak unchanged |
| Y-l | Member of a Japji group | + Japji five times today | Diary shows 5; the group counts 3 |
| Y-m | A future day | Tapping it | Not tappable, dimmed |
| Y-n | Days before the first recorded day | — | No dots |
| Y-o | A goal stopped on the 22nd | Looking at the month | 1st–22nd unchanged; from the 23rd one dot |
| Y-p | App data cleared, profile and data restored | Opening the month | Every backed-up day as before; anything after the last backup missing |
| Y-q | The device time zone changes | — | Days keep their stored local date; none merges into its neighbour |
| Y-r | `user.db` migration fails | Opening | A real error; the diary must never be silently lost |
| Y-s | Ten years of history | Opening a month | Only that month is read |

## 9.5 Proposed additions (not in scope yet)

- **A year view:** twelve rows of dots.
- **A month summary:** days marked, days the goal was met, simran minutes, banis by name. No comparison with anybody.

## 9.6 Open decisions

| # | Decision | Status |
| --- | --- | --- |
| Y-1 | The 7-day edit window | **Decided:** 7 days (`04-goals.md` §3) |
| Y-2 | Two-phone sync conflicts | **Decided:** no two-phone sync. One phone owns the profile at a time; restore merges row by row (`10-backup.md`) |
| Y-3 | Export the diary as a file | **Open.** Default: not built now |
| Y-4 | Does diary sync default on? | **Decided:** the weekly backup runs whenever a profile exists; there is no switch (`10-backup.md` B-3) |

## 9.7 Acceptance

- A test per row of 9.4.
- One test feeding Today, the Goals screen, the Diary grid and the day screen the same rows, and checking they agree (`04-goals.md` §9).
- A test that a month with no goals renders one dot per day and no legend entry.
- A test that the Diary renders fully with no profile and no network.

## 9.8 Out of scope

- A free-text note per day. `user.db` has no note, and the earlier version of this file was wrong to describe one.
- Search, export and the proposals in 9.5 until they are decided.

## 9.9 What changed on 2026-10-07

| Before | Now | Source |
| --- | --- | --- |
| Dots from `GoalCalculator.outcomeOn` | From `verdictOn` | `04-goals.md` §4.6 |
| Tick rows, one completion per bani per slot per day | + and − with counts; every paath a row | `04-goals.md` CR3, CR5 |
| "Days before install have no dots" | Days before the first recorded day | `04-goals.md` DV3 |
| `forgetGoal` could erase a goal's days | No hard delete; removing keeps history | `04-goals.md` GI7 |
| Per-day diary sync, last writer wins | Weekly backup; restore merges row by row | `10-backup.md` |
| A per-day note | None exists | 9.8 |
| Diary edits only local | Also counted toward groups, at most 3 a day per group | `08-sangat.md` CT4 |
