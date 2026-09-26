# 6. Nitnem: the list, the reader, the player

---

## 6.1 Purpose

The reason the app exists. Read or listen to a bani, with the line you are on
lit, and have the app remember where you stopped.

## 6.2 What exists today

**The list** (`/nitnem`, design 12) groups the nine banis by
`defaultSlot`: Amrit Vela (Japji, Jaap, Tav Prasad Savaiye, Chaupai, Anand),
Evening (Rehras), Bedtime (Kirtan Sohila), and More banis (Ardas, Sukhmani —
slot `none`).

**The reader** (designs 13–16) shows Gurmukhi with optional Devanagari and
Latin, meanings where they exist, pause marks, Larivaar, adjustable text size,
resume, keep-screen-on. `ReadingProgress` stores the line and audio position
per bani version.

**The player** — `audio_service` + `just_audio`, a foreground service, lock
screen and Bluetooth controls, speed 0.75×–1.5× with pitch preserved, ±10s,
previous/next bani, a sleep timer. Line highlighting comes from
`timing` rows; `indexAt` holds the last line that started rather than dropping
the highlight through a gap.

**Completion** (`logCompletion`) — a bani counts as completed when audio
reaches ≥95%, or the reader reaches the last line and stays 5s, or it is ticked
by hand. **One completion per bani per slot per day** is stored; extra paath
still credit goals, because `creditGoalsFor` is called separately by each
caller.

## 6.3 Wrong or missing

1. **Completion is computed in three places** — `reader_screen`,
   `audio_controller` and the diary's tick — each calling `logCompletion` and
   then `creditGoalsFor` and then `creditGroupsFor` in its own order. This is
   the same shape as the goals bug: three call sites that must each remember
   three things. One of them will forget.
2. **The 95% rule is invisible.** Somebody who listens to 94% and stops has no
   idea why it did not count.
3. **`isNitnemDay` and the streak disagree.** `DiaryDay.isNitnemDay` counts any
   completion including slot `none`; `streak()` excludes slot `none`. So a
   Sukhmani-only day marks hazri, lights the diary dot, and does not extend the
   streak. Nobody decided that.
4. **No partial credit for a long bani.** Sukhmani is over an hour. Stopping at
   the eighth ashtapadi records nothing but a reading position.
5. **Only one voice, and `voice` has no credit** — deliberate until a name is
   agreed, but the PRD's D9 is still open.
6. **No Sehaj Path** (§3.3, D12) — the marker, not the full 1430 Angs.

## 6.4 The behaviour

**B1 — one completion path.** A single `completeBani(baniId, slot, source)` in
the repository that logs the completion, credits goals, credits groups and
returns what changed. The three call sites call **that** and nothing else.
This is the §4 fix applied to banis.

**B2 — what counts as completed**, unchanged but written down: audio ≥95% of
the track, **or** the reader reaching the last line and staying ≥5s, **or** a
manual tick. One completion per bani per slot per day for the diary; every
completion credits goals and groups.

**B3 — a slot-`none` bani marks hazri and does not extend the nitnem streak.**
Ardas and Sukhmani are paath; the *nitnem* streak counts nitnem. Both rules
stated in one place so they cannot drift apart again.

**B4 — progress is per bani version**, so switching script or voice does not
lose the place.

**B5 — the player owns playback state**, the reader observes it. Highlighting
comes from `timing` via `indexAt` and from nowhere else.

**B6 — nothing about the recitation is invented.** No line without a timing
gets a guessed one; a squeezed line holds the previous highlight rather than
dropping it.

**B7 — a paath in progress survives** backgrounding, process death and a
reboot, at the line and audio position it had.

## 6.5 Scenarios

**Success**

| Given | When | Then |
|---|---|---|
| Japji open at line 1 | Scrolling to the last line and waiting 5s | Completed once; hazri marked; goals credited; group credited |
| Japji playing | Audio reaches 95% | Same, exactly once, whichever happens first |
| Japji already completed this morning | Read again | No second completion row; goals **do** get a second tick if the target allows |
| Rehras at line 40 | Backgrounding, killing, reopening | Continue Rehras, at line 40 |
| A paath playing | The phone locks | Audio continues; lock-screen controls work |
| A paath playing | A call arrives | Pauses; resumes if the call ends within 5 min |
| A paath playing | Headphones unplugged | Pauses and **never** resumes on the speaker |
| Sukhmani read fully | — | Hazri marked, diary dot lit, **nitnem streak unchanged** |
| Script switched mid-paath | — | Same line, same audio position |

**Failure**

| Given | When | Then |
|---|---|---|
| The audio pack is not downloaded | Pressing play | Offered the download with its size; the text is readable meanwhile |
| Audio stops at 94% | — | Not completed. The reader can see how far it got and tick by hand |
| Timings are missing for a bani | Playing | Audio plays, no highlight, and the screen says the alignment is not available. No guessed highlight |
| The track is shorter than the text | Playing | Extra lines have no span; `indexAt` holds the last one that started |
| Storage is full | Downloading | A real error naming it, and the text still reads |
| The media session fails to start | Launch | The app opens as a text-only reader — already handled in `main.dart` |
| Two completions race (reader and player both at the end) | — | One row. `logCompletion` dedupes on bani+slot+day |

## 6.6 Open decisions

| # | Decision | Default |
|---|---|---|
| B-1 | Partial credit for Sukhmani | A resumable reading position is enough for now; a "paath in progress" marker on Today is the smaller, better answer |
| B-2 | D12: Sehaj Path marker, or the full Saroop in the app? | The marker. The full text is ~100× the content we ship and gated on D1's licence |
| B-3 | D9: the paathi's credit | Still open. Nothing invented; the field stays empty until a name is agreed |

## 6.7 Acceptance

- One test that `completeBani` credits all three things, and a test that no
  other code path calls `logCompletion` directly.
- A test per row of §6.5.
- The three alignment checks in `audio/README.md` stay green; alignments are
  locked and must not be re-run.
