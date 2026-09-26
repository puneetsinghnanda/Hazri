# 5. Today — the home screen

---

## 5.1 Purpose

Answer one question in the first second: **have I turned up today, and what is
next?** Everything else on the screen is secondary to that.

## 5.2 What exists today

Top to bottom (`today_screen.dart`):

1. `TabHeader` — menu button, "Today", the date (Gregorian + Nanakshahi).
2. `HazriBanner` — designs 58/59. Kesri gradient when marked, saying what
   marked it and at what time; a quiet card saying "not marked yet" otherwise.
   **As of this week it is shown to everybody**, not only sangat members.
3. `_GoalsCard` — design 30. "n of m done today", a ring with the fraction
   across all targets, and one row per goal with its time or count. Falls back
   to `_NoGoalsCard` when there are none.
4. The Vichar card — ਅੱਜ ਦਾ ਵਿਚਾਰ, the day's line, share and Explore.
5. The Nitnem call to action — Start or Continue, naming the bani and its
   minutes, deep-linking into the reader at the saved line.
6. The Gurpurab card when one is near.
7. The join-the-sangat banner, until joined.

`ElderTodayScreen` is a separate widget for elder mode with a bigger CTA, and
it now carries the hazri banner and the goal-complete listener too.

## 5.3 Wrong or missing

1. **Two banners can stack.** Hazri and the join invitation both show until the
   sangat banner is dismissed. The "Not now" memory that fixes this exists on
   `claude/eloquent-edison-qsjll0` and is not on this branch.
2. **Elder Today is a fork, not a mode.** It duplicates layout and has already
   drifted twice — it had no hazri banner and no completion sheet. Every change
   to Today must be made twice, and one of them gets forgotten.
3. **The day arc is gone** and the PRD (1.3) still describes it.
4. **The CTA does not know about goals.** It offers the next nitnem bani even
   when the outstanding thing is a simran goal.
5. **Nothing shows the streak** on Today, though the diary computes one.

## 5.4 The behaviour

**T1 — hazri is the first thing, always.** Above everything but the header. It
needs no account, no network and no goal. It is never hidden.

**T2 — one banner at a time.** Priority: hazri always shows; the join
invitation shows only if not joined **and** not dismissed. Dismissal is
remembered for ever and the sangat stays reachable from its tab and the menu.

**T3 — the goals card is the second thing**, and shows the shared rule from §4
and nothing of its own.

**T4 — the CTA names the single most useful next action**, in this order:
an unfinished paath in progress → the current slot's first unread bani → an
unmet goal (bani or simran) → the next slot's bani. It says what it is and how
long it takes.

**T5 — elder mode is a mode, not a screen.** One widget tree, elder mode
changing sizes, spacing and which of the secondary cards appear. The fork goes.

**T6 — every card is tappable to the thing it describes**, and no card is a
dead end.

**T7 — Today works entirely offline.** Nothing on it may wait on a network
call. Sangat numbers, when shown, come from cache and are marked stale rather
than spinning.

## 5.5 Scenarios

**Success**

| Given | When | Then |
|---|---|---|
| Nothing done today | Opening Today | "Not marked yet", never "missed". The CTA offers the slot's first bani |
| Japji read at 05:10 | Opening Today | Hazri marked, saying Japji and 5:10 AM |
| A simran sitting done, no paath | Opening Today | Hazri marked, saying Daily Simran |
| Japji half read | Opening Today | "Continue Japji Sahib", opening at the saved line |
| No goals | Opening Today | The card invites setting one; no "0 of 0" |
| 1 of 3 goals met | Opening Today | "1 of 3 done" and a third of the ring |
| All goals met | The last tick, from anywhere | The card updates and the completion sheet appears once |
| Elder mode on | Opening Today | Same content, bigger; hazri and the sheet both present |
| Aeroplane mode | Opening Today | Everything but sangat numbers; nothing spins |

**Failure**

| Given | When | Then |
|---|---|---|
| Not joined, banner not dismissed | Opening Today | Hazri **and** the invitation. Hazri is on top |
| Not joined, banner dismissed | Opening Today | Hazri only. The invitation never returns |
| Midnight passes with the app open | — | Today rolls over: hazri resets, the date changes, goals re-scope |
| The device clock jumps a day | — | The app follows the device's local date. It does not try to be cleverer |
| `content.db` has no bani for the slot | — | The CTA is hidden, not broken, and the rest of the screen stands |
| The Vichar dataset has no line for the date | — | The card is omitted. No blank card, no invented line |

## 5.6 Open decisions

| # | Decision | Default |
|---|---|---|
| T-1 | Does the day arc come back, or does the PRD change? | The PRD changes. The goals card answered the same question with a number instead of a clock face |
| T-2 | Streak on Today? | A quiet line under hazri, never a score, and never mentioned when it breaks |
| T-3 | Merging elder mode into one tree — now or later? | Now. It has drifted twice in a fortnight |

## 5.7 Acceptance

- Widget tests for every row of §5.5, in all three languages.
- A test that Today renders fully with the account repository returning null.
- A test that Today makes **no** network call on build.
- Golden renders at 390×844, light and dark, normal and elder.
