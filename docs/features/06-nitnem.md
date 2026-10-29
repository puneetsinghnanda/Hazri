# 6. Nitnem: the list, the reader, the player

Updated 2026-10-07 to agree with the specifications written that day:
`04-goals.md` (what a completion is and what it feeds), `08-sangat.md` (the
outbox) and `02-notifications.md` (reminders). Where this file and those
disagree, they win. Section 6.9 lists what changed.

---

## 6.1 Purpose

The reason the app exists. Read or listen to a bani, with the line you are on
lit, and have the app remember where you stopped.

## 6.2 What exists today

**The list** (`/nitnem`, design 12) groups the nine banis by `defaultSlot`:
Amrit Vela (Japji, Jaap, Tav Prasad Savaiye, Chaupai, Anand), Evening
(Rehras), Bedtime (Kirtan Sohila), and More banis (Ardas, Sukhmani; slot
`none`).

**The reader** (designs 13–16) shows Gurmukhi with optional Devanagari and
Latin, meanings where they exist, pause marks, Larivaar, adjustable text size,
resume and keep-screen-on. `ReadingProgress` stores the line and audio position
per bani version.

**The player**: `audio_service` + `just_audio`, a foreground service, lock
screen and Bluetooth controls, speed 0.75×–1.5× with pitch kept, ±10 s,
previous and next bani, a sleep timer. Line highlighting comes from `timing`
rows; `indexAt` holds the last line that started through a gap.

**Completion** today is logged in three places (reader, player, Diary), each
also calling `creditGoalsFor`, and stored once per bani per slot per day. Both
change (B1, B2).

## 6.3 The behaviour

**B1. One completion path.** A single repository call,
`completeBani(baniId, source)`, does everything a completion causes, in one
transaction: inserts the `completions` row (`04-goals.md` §5.4), adds it to the
Sangat outbox when the person belongs to a group (`08-sangat.md` §5.1), and
asks for reminders to be re-planned (`02-notifications.md` CM2). The reader,
the player and the Diary call that and nothing else. Goals need no crediting:
they are read from completions (`04-goals.md` CR5).

**B2. What counts as completed:**

- the reader reaching the last line and staying there 5 seconds (`source` `READER`);
- the audio reaching 95% of the track (`source` `AUDIO`);
- "+" in the Diary (`source` `DIARY`).

Reading and listening in the same opening of a bani count once between them
(`04-goals.md` CR2). Reading the same bani again later is another completion:
every paath is its own row (`04-goals.md` CR5).

**B3. A slot-`none` bani marks hazri and does not extend the nitnem streak.**
Ardas and Sukhmani Sahib are paath; the nitnem streak counts nitnem. They do
count toward a goal or a Sangat group whose bani they are.

**B4. Progress is per bani version**, so switching script or voice keeps the
place.

**B5. The player owns playback state**; the reader observes it. Highlighting
comes from `timing` via `indexAt` and nowhere else.

**B6. Nothing about the recitation is invented.** No line without a timing
gets a guessed one; a squeezed line holds the previous highlight. The nine
alignments are locked (CLAUDE.md, "Content and audio").

**B7. A paath in progress survives** backgrounding, process death and a reboot,
at its line and audio position.

**B8. Opening from a notification.** "Open {bani}" in a notification opens the
reader on that bani at its saved line (`02-notifications.md` AV3, GR4).

**B9. The list is one card per part of the day, tinted by its light**
(design 2A, owner 2026-10-29, from options at
<https://claude.ai/artifact/TeEFvQWsDLcdPGzbP1qsws> and
<https://claude.ai/artifact/6WhAUJtt97RenQZku5nwi3>): Amrit Vela in dawn
saffron, Evening in sunset peach, Before sleep in a soft lavender (never the
navy of a dark card, owner 2026-10-29), each fading to the card's own colour;
More banis plain. The header, Play all and the bani rows inside are
unchanged.

## 6.4 Scenarios

| # | Given | When | Then |
| --- | --- | --- | --- |
| N-a | Japji open at line 1 | Scroll to the last line and wait 5 s | One completion; hazri marked; the goal recomputed; added to the outbox if in a group |
| N-b | Japji playing | Audio reaches 95% | One completion |
| N-c | Japji read and played in one opening | Both reach the end | One completion |
| N-d | Japji already read this morning | Read again in the evening | A second completion; a goal of ×2 is met |
| N-e | Rehras at line 40 | Backgrounding, killing, reopening | Continue Rehras at line 40 |
| N-f | A paath playing | The phone locks | Audio continues; lock-screen controls work |
| N-g | A paath playing | A call arrives | Pauses; resumes if the call ends within 5 minutes |
| N-h | A paath playing | Headphones unplugged | Pauses and never resumes on the speaker |
| N-i | Sukhmani Sahib read fully | — | Hazri marked; nitnem streak unchanged; counts in a Sukhmani Sahib group |
| N-j | Script switched mid-paath | — | Same line, same audio position |
| N-k | Audio pack not downloaded | Pressing play | Offered the download with its size; the text reads meanwhile |
| N-l | Audio stops at 94% | — | Not completed; "+" in the Diary is there for a paath done away from the app |
| N-m | Timings missing for a bani | Playing | Audio plays, no highlight, and the screen says so |
| N-n | Storage full | Downloading | A real error naming it; the text still reads |
| N-o | The media session fails to start | Launch | The app opens as a text-only reader |
| N-p | Offline | Completing a bani | Completion stored; the outbox sends it when the network returns |
| N-q | "Open Japji Sahib" tapped in the 04:00 notification | — | Reader on Japji Sahib at its saved line |

## 6.5 Open decisions

| # | Decision | Default |
| --- | --- | --- |
| B-1 | Partial credit for Sukhmani Sahib | A resumable reading position is enough for now |
| B-2 | D12: a Sehaj Path marker, or the full Saroop in the app? | Phase 3; the marker. The full text is gated on D1's licence |
| B-3 | D9: the paathi's credit | Open. Nothing invented; the field stays empty until a name is agreed |

## 6.6 Acceptance

- One test that `completeBani` writes the completion, the outbox row and asks for re-planning, and a test that no other code inserts into `completions`.
- A test per row of 6.4.
- The three alignment checks in `audio/README.md` stay green; alignments are locked.

## 6.7 Out of scope

- Per-slot reminders for Rehras and Kirtan Sohila: removed from the notification list on 2026-10-07 (`02-notifications.md` N-2).

## 6.8 Dependencies

Completion feeds hazri and goals (`04-goals.md`), the Sangat (`08-sangat.md`),
the weekly backup (`10-backup.md`) and reminders (`02-notifications.md`).

## 6.9 What changed on 2026-10-07

| Before | Now | Source |
| --- | --- | --- |
| One completion per bani per slot per day | Every paath is a row | `04-goals.md` CR5 |
| `completeBani` logs, credits goals, credits groups | Logs, queues for the Sangat, re-plans reminders; goals need no credit | `04-goals.md` CR5, `08-sangat.md` §5.1 |
| Manual tick | Diary "+" and "−" | `04-goals.md` CR3 |
| Duplicate completions deduped on bani + slot + day | Reader and player in one opening count once; separate readings count separately | `04-goals.md` CR2 |
