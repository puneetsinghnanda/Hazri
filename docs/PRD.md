# Hazri — Product Requirements Document

| | |
|---|---|
| Product | **Hazri** (ਹਾਜ਼ਰੀ · हाज़िरी). From Amrit Vela to bedtime, mark your hazri to Waheguru |
| Owner | Puneet Singh Nanda |
| Version | **2.0, 2026-10-08.** Replaces PRD v1.0 (Phase 1, 11 September 2026) entirely; v1.0 is in git history and is not a reference for anything |
| Platform | Android only, Flutter. iOS is off the roadmap (2026-09-22) |
| Backend | Firebase project `hazri-dfcc1`, Blaze plan, Cloud Functions and Firestore in `asia-south1` |
| Audience | The product owner, and Claude Code as the implementer |

---

## 0. How to use this document

### 0.1 The four documents

| Document | Holds | Use it for |
|---|---|---|
| **`docs/PRD.md`** (this) | What Hazri is, every feature and its decided behaviour, the screens, privacy, and the plan to build it | Deciding what to build, in what order, and what "done" means |
| **`docs/features/NN-*.md`** | One file per feature: numbered rules a test can cite, exact strings in three languages, given/when/then scenarios, the acceptance checklist | Building and testing a feature |
| **`docs/ARCHITECTURE.md`** | The app's structure, every table in `content.db` and `user.db`, preferences and local flags, Firestore collections, the API and the Cloud Functions, deployment and cost | Anything about data, storage or the server |
| **`design/canvas.html`** | Every screen, by feature, marked *new*, *current*, *superseded* or *reference*. Published at <https://claude.ai/artifact/Fz2WJs5tPF9nUWPgkgBkR8> | What a screen looks like |

### 0.2 Which one wins

1. **The decisions of 2026-10-07 and 2026-10-08 are final** and override
   anything written before them, in any document or in the code.
2. **This PRD wins** over a feature file, and a feature file over
   `ARCHITECTURE.md`. A disagreement is a defect: fix both in the same commit
   and note it in the PR description.
3. **Written behaviour wins over a design.** Only screens marked *new* or
   *current* are the visual spec; a *superseded* screen is history.
4. **Change the documents with the code.** A change to behaviour changes the
   feature file (and this PRD where it is summarised) in the same commit; a
   change to data changes `ARCHITECTURE.md`.

### 0.3 Rules for every change

These are also in `CLAUDE.md` and apply to every session.

1. **Designs are the visual spec, not code to port.** `design/html/NN-*.{light,dark}.html` are 390 × 844 CSS px = 390 × 844 dp. Match layout, spacing, radii, colours and type; build with Flutter widgets. `design/tokens.json` is the source of colour, type and shape.
2. **Never create, paraphrase, auto-translate or AI-generate Gurbani text, Gurbani audio, meanings, or images of the Gurus.** Every line of Gurbani and every meaning comes from `content/source/` through `tools/content_pipeline/build_content_db.py`. Nothing Gurbani-related is typed into Dart. The same holds for everything the app says about Sikhi (the Vichar library).
3. **No ad SDKs, no tracking or attribution SDKs, no advertising ID, no password and no sign-in screen, ever.** What Phase 2 may send is the closed list of §8.
4. **Nothing needed to read a bani, hear it, see the calendar, keep the diary, set goals or mark hazri may need the network.**
5. **Every user-facing string is localised** in Punjabi, Hindi and English from the first commit; `test/core/l10n_test.dart` fails on a missing key.
6. **Platform-specific code sits behind an interface.**
7. **Every change ends with `flutter analyze` clean and `flutter test` passing**, and a feature is done only when its feature file's acceptance checklist passes.

---

## 1. The product

### 1.1 What Hazri is

Hazri is a free Nitnem app for Android in Punjabi, Hindi and English. Its
centre is one idea: **hazri** — turning up before Waheguru each day. Reading
one bani, or sitting five minutes of Naam Simran, marks the day present. It
needs no account, no network and no goal, and it is kept on the phone.

Around it:

- **All seven Nitnem banis, Ardas and Sukhmani Sahib**, in Gurmukhi,
  Devanagari and Roman, with meanings where reviewed meanings exist, and a
  recitation for each that the text follows line by line.
- **Daily goals** the reader chooses — any bani, any number of times a day,
  for as long as they choose, and Naam Simran by the minute — judged
  separately from hazri.
- **A Diary** of every day: hazri and goal at a glance, every paath listed,
  and the hazri streak, told gently.
- **Simran** with a globe of the sangat: everybody with a profile, by city,
  and who has opened the app today.
- **The Sangat**: groups working together toward one shared goal — three
  built-in groups anybody can join, and private groups for a family,
  Gurdwara or circle.
- **Badges** for days kept, never points.
- **Notifications** at Amrit Vela, for each goal, for Gurpurabs and Sikh
  events, and for the Sangat.
- **An optional profile** — name, email, city — that puts the reader on the
  globe, lets them create groups, and keeps a weekly backup they can restore
  on a new phone. There is never a password or a sign-in screen.
- **ਅੱਜ ਦਾ ਵਿਚਾਰ**, one line of Gurbani a day, and the **Gurpurab and
  Nanakshahi calendar**.

**Works offline. No login. No ads on Gurbani, ever.**

### 1.2 Who it is for

| Person | Needs |
|---|---|
| The daily Nitnem keeper, 25–60, in India and the diaspora | Reliable text, the recitation for the commute, a reminder at Amrit Vela, resuming where they left off |
| Hindi-reading Sikh and Sehajdhari families | Correct Devanagari, Hindi meanings where they exist, a Hindi app |
| Learners and diaspora youth | Roman transliteration, English meanings, the text following the recitation |
| Elders | Very large text, big targets, simple screens |
| A family, Gurdwara or circle | A shared goal — 101 Sukhmani Sahib, 40 days of Japji — counted together |

### 1.3 Principles (non-negotiable)

1. **Maryada first.** No ads or promotions near Gurbani. **No points or XP
   for Gurbani.** No guilt: nothing ever says a streak broke, a day was
   missed, or somebody is behind. Gurbani in notifications is limited to bani
   names. No badge, sheet or count on the reader, the player or a Simran
   sitting.
2. **Accuracy.** Only reviewed text and reviewed meanings, every source
   credited; nothing generated (rule 2 of §0.3).
3. **Offline by default.** Reading, listening, the calendar, the Diary, goals,
   hazri and badges work with the radio off. Only the Sangat, the globe, the
   profile and the backup use the network, and their failure never blocks
   anything else.
4. **Opt-in, and private by default.** The profile is optional and the Sangat
   is opt-in: somebody who never makes a profile or joins a group uses the
   whole app entirely on their own phone. Nobody is ranked, and nobody's
   shortfall is shown.
5. **One rule, one place.** Hazri, the goal state, the streak and badge counts
   are each decided by one function, which every screen calls.
6. **Calm design.** The Amrit Vela visual language: dawn-mist light,
   deep-night dark, Neela (navy) and Kesri (saffron).
7. **Budget phones matter.** Fast start, smooth scrolling on 3 GB of RAM.

### 1.4 Success measures

Measured from Phase 3, when analytics collection is switched on (§8); Phase 2
collects nothing.

| Goal | Measure | Target at 90 days |
|---|---|---|
| Habit | Share of active days with hazri | ≥ 60 % |
| Retention | Day-30 retention | ≥ 25 % |
| Follow-along | Share of bani sessions with audio | ≥ 40 % |
| Quality | Crash-free users | ≥ 99.5 % |
| Store | Play rating | ≥ 4.6 |

---

## 2. Scope and roadmap

### 2.1 Phases

| Phase | Theme | State |
|---|---|---|
| **1 · Launch** | The best daily Nitnem app: free, offline, no login, no server | Built. Its reader, recitation, calendar and Vichar carry into Phase 2 (§4) |
| **2 · Together** (this build) | Hazri, goals, the Diary, notifications, an optional profile with a weekly backup, the Simran globe, the Sangat, and an admin website. Firebase on Blaze. Android only | **Specified 2026-10-07/08; to be built** in the order of §11 |
| **3 · Depth** | Seven things, and nothing else (§2.3) | Badges specified and designed; the rest not started |

There is no phase after 3.

### 2.2 Phase 2: in scope

| # | Feature | PRD | Rules |
|---|---|---|---|
| 1 | First run | §4.1 | `03-first-run.md` |
| 2 | Today | §4.2 | `05-today.md` |
| 3 | Hazri and goals | §4.3 | `04-goals.md` |
| 4 | Nitnem list, reader, recitation, background playback | §4.4–4.7 | `06-nitnem.md` |
| 5 | Simran and the globe | §4.8 | `07-simran.md` |
| 6 | Diary | §4.9 | `09-diary.md` |
| 7 | Notifications | §4.10 | `02-notifications.md` |
| 8 | Profile: setup, email verification, restore, edit | §4.11 | `01-accounts.md` |
| 9 | Weekly backup and restore | §4.12 | `10-backup.md` |
| 10 | Sangat | §4.13 | `08-sangat.md` |
| 11 | ਅੱਜ ਦਾ ਵਿਚਾਰ and the Vichar library | §4.15 | — |
| 12 | Gurpurab and Nanakshahi calendar | §4.16 | — |
| 13 | Elder mode | §4.17 | `05-today.md` T5 |
| 14 | Menu, Settings, About, Privacy | §4.18 | — |
| 15 | Admin website | §4.19 | `11-admin.md` |
| — | Platform, testing rules | §11 | `00-platform.md`, `ARCHITECTURE.md` |

**Badges** (§4.14, `12-badges.md`) are Phase 3 item 3.2, specified and
designed ahead; they are built last in the Phase 2 order (§11.3) because
they depend on the goals schema and, for two badges, on the Sangat.

**Not in Phase 2:** group chat or any free text between members; public or
listed custom groups; join approval; groups on the globe; diary export
(Y-3); a free-text note per day; two phones sharing one profile at once;
deleting a profile; Rehras, Kirtan Sohila and Daily Simran reminders (N-2);
a full-screen player.

### 2.3 Phase 3: the seven

| # | Item | State |
|---|---|---|
| 3.1 | **Report an issue / feedback.** The one place free text the reader typed leaves the phone, because they pressed send; never through analytics; the privacy screen names it | Not started |
| 3.2 | **Badges** | **Specified and designed** (§4.14) |
| 3.3 | **Sehaj Path and the marker.** Either a marker of where the reader is in a Saroop (no scripture shipped), or the full 1430 Angs in the app (a content programme gated on the text licence) | **Blocked on D12** |
| 3.4 | **Rate the app.** Play's In-App Review API, never on the way out of a failure or after a report, plus a plain "Rate on Play" row | Not started |
| 3.5 | **A digital Gurdwara visit.** Start with Google's existing Street View where it exists; commission a 360° tour only where a Gurdwara committee has agreed in writing. The first feature that needs the network to work | Not started |
| 3.6 | **Analytics collection switched on**, with Crashlytics and a working opt-out; the privacy screen changes in the same release (§8) | Not started |
| 3.7 | **Notifications** | **Moved into Phase 2** and specified (§4.10); a badge and a met goal are in-app sheets, not notifications |

### 2.4 Off the roadmap

Removed on 2026-09-22, not deferred: the recitation check, kids' kantth mode
and Gurmukhi letters, Gurdwara Connect, the Wear OS Simran counter,
home-screen widgets, Ask a question, pronunciation practice, more voices,
Cast to TV, Live Kirtan, Saakhis, daily quotes, the iPhone app, and the
earning ideas (Dasvandh, a Plus plan, sponsorships, a Paath marketplace).
The 23-screen Phase 3 design set drawn for that list (`design/html/62-*` to
`84-*` on `claude/eloquent-edison-qsjll0`) is superseded and must not be
merged.

---

## 3. The app at a glance

### 3.1 Hazri, goals, streak, badges: how they fit

| Idea | What marks it | Needs | Shown on |
|---|---|---|---|
| **Hazri** | One completed bani, or one Naam Simran sitting of 5 minutes or more, on a local day | Nothing: no goal, no profile, no network | Today's hazri banner; the Diary's orange dot |
| **Goal** | Every goal item in scope that day met (its bani × its times a day; Simran for its minutes) | A goal the reader set | Today's goal widget; the Diary's green dot |
| **Hazri streak** | Consecutive days with hazri marked (any paath, or 5 minutes of Naam Simran; owner 2026-10-10); grace days silent | Nothing | Today's streak card from 2 days; the Diary's now-and-longest card |
| **Badges** | Totals of days and milestones, never runs | Nothing (two need a profile) | The profile, the menu, the Badges page |
| **Sangat** | Each paath of a group's bani, or each minute of Naam Simran for a Simran group, counted toward the group | Joining a group | The Sangat tab |

All of them read the same rows — `completions` and `simranSessions` in
`user.db` — through one function each, so no two screens can disagree. A
day can never have a met goal without hazri.

### 3.2 Navigation

```
First launch:  Android system splash → Welcome → Language → How you read → Today
               (→ Join screen, only if an invite arrived before setup)
Every launch:  Android system splash → Today, or the deep-link target

Bottom navigation:  Today · Nitnem · Simran · Sangat · Diary
Elder mode:         Today · Nitnem · Diary   (Simran and Sangat stay reachable)

Menu (menu button on each tab header; design 99):
  navy header — avatar, name and city (or "Set up your profile"), Badges n of 10
  and the row of ten — then
  Your profile · Badges · Notifications · Audio and voice · Text size and script ·
  Language · Privacy and my data · About and credits
```

**Pushed screens.** Reader (and its text sheet) · Vichar and the Vichar
library · Gurpurab calendar · Goals (Add goal, Edit item sheets) · Diary day
· Profile, Profile setup, Edit profile, Email sent, Link result, Restore my
data · Badges, One badge · Notifications (and diagnostics) · Sangat: Create
group, Join, Group, Invite, Report · Settings · About and credits · Privacy
· Licences.

**Sheets.** The goal-complete sheet (once a day), a badge earned (once per
badge), the share sheet, the speed and sleep sheet.

**Rules.** Today alone has the navy app bar; every other tab draws its own
header with the menu button. Back from a tab returns to Today, and from
Today exits. Notification taps open their route on top of Today. Links use
`hazri://` and App Links on `hazri-dfcc1.web.app` and
`hazri-dfcc1.firebaseapp.com` (`/verify`, `/j/<code>`).

---

## 4. Features

Each feature gives its purpose, the decided behaviour, its screens, and where
its rules and data are. The feature file holds the numbered rules, the exact
strings and the scenarios; cite those in tests.

### 4.1 First run

**Purpose.** Reach Gurbani in under 30 seconds, and introduce what Hazri is
on one screen. *Rules: `03-first-run.md`. Screens: 91, 92, 93, 94.*

- **Android's own splash only** (design 91): the app mark on `#0C0F24`. No
  branded splash and no fixed hold; the first route is a redirect made before
  the first frame (onboarding done → Today, else Welcome) (F1).
- **Welcome** (design 92, option D, "a day with Hazri", chosen 2026-10-08):
  the app mark and name; the headline *From Amrit Vela to bedtime, mark your
  hazri to* **Waheguru.** (the last word in kesri); a timeline of one day in
  five cards that introduces the features — the 04:00 Amrit Vela reminder,
  the hazri marked with Japji Sahib, the daily goal (1 of 2), the sangat group
  (68 of 101 Sukhmani Sahib, together), the 12-day streak in the diary — and
  one button, **Begin**. The timeline is a fixed illustration, never the
  reader's data. No carousel, no dots, no swipe.
- **Language** (design 93): ਪੰਜਾਬੀ / हिन्दी / English, applied the moment it
  is tapped; it also sets the script and meaning defaults.
- **How you read** (design 94): script and text size against a real line from
  `content.db`, and elder mode offered as "Larger text and simpler screens".
  **Skip** allowed (Gurmukhi, standard size).
- **Then Today.** That is the whole of setup, and it needs no network.
- **Never in setup:** the profile, a city, reminders, exact alarms, the
  Sangat. Android's notification prompt appears at app start, over Welcome on
  a first launch (F6). The audio is bundled, so there is no download step.
- An invite link, install-referrer code, or verification link that arrives
  before setup is held and handled when setup completes (F7). Setup resumes
  where it was left (F8).
- **One city, the profile's.** Without a profile there is no city and nothing
  guesses one (CY1–CY3).

**Removed:** the branded splash (design 01), the three intro pages (02–04),
the reminders step and reminder-time sheet (07, 08), the city picker.

### 4.2 Today

**Purpose.** One look says whether today's hazri is marked, how the goal
stands, and the single most useful next thing. *Rules: `05-today.md`.
Screens: 85 (with profile and streak), 86 (first day, no profile), 61 (goal
complete).*

Top to bottom:

1. **The navy app bar** (option D, chosen 2026-10-07), Today only: a band of
   `primary` (Neela `#262C63`; `card2` in dark) with bottom corners of 28 dp;
   the menu button, the sunrise mark and **Hazri** in Baloo Paaji 2 at 22 sp,
   and the round person button that opens the profile; under them
   **Welcome, {name}** (or **Welcome**) at 24 sp and the date, Gregorian and
   Nanakshahi, at 13 sp. The first card overlaps the band by 32 dp (T11).
2. **The profile banner**, "Set up your profile", only without a profile, not
   dismissible (`01-accounts.md` §8.4).
3. **The hazri banner**, always, for everybody, from `verdictOn(today).hazri`
   (T1).
4. **The streak card** (option 3, chosen 2026-10-07): the number over *days
   of Nitnem in a row*, and the last seven days as weekday initials over dots,
   saffron for a day that counts, today's ringed. **Shown only from 2 days**;
   nothing is ever said when a streak ends; a grace day keeps the count and
   its dot stays unlit. Tapping opens the Diary (T12).
5. **The Set Goal card**, or **the goal widget**: items met of items in scope
   with a ring, a row per item (T3, `04-goals.md` §7.1).
6. **The call to action**: a paath in progress (Continue at the saved line);
   else the first unmet goal item; else the current slot's first bani not done;
   else the next slot's (T4).
7. **ਅੱਜ ਦਾ ਵਿਚਾਰ** card (§4.15).
8. **The Gurpurab card** when an event is within 7 days, else today's
   Nanakshahi date.

**Rules.** No join-the-sangat banner and no Sangat number on Today (T2, T7).
Every card opens what it describes; a card with no data is left out, never
blank (T6). Today works entirely offline; the attendance call never delays it
(T7). The goal-complete sheet shows once a day when the goal is met (T9).
Midnight rolls Today over with the app open (T10). Elder mode is this same
screen at larger sizes (T5).

**Removed:** the day arc, the separate elder Today, the join banner, the
Daily Simran tile.

### 4.3 Hazri and goals

**Purpose.** Hazri is turning up; a goal is finishing what the reader chose.
They are judged independently. *Rules: `04-goals.md`. Screens: 19 (Goals), 47
(Add goal), 42 (Log a paath), 61. Data: ARCHITECTURE §3.3.*

- **Hazri:** at least one completion, or one sitting of 300 s or more, on the
  local day. Shorter sittings are stored and mark nothing (HZ1–HZ4).
- **A goal holds items.** Any bani from `content.db`, or Naam Simran. Each
  item has its own **times a day** (1–11; Simran: minutes 5–120, presets 5,
  11, 21, 31), its own **duration** (every day; N days, 40 the preset, up to
  365; or until a date within a year), and its own **reminder** (off by
  default; 19:30 pre-filled when switched on).
- **One active goal.** Adding an item with no active goal creates one. At most
  one item per bani, and one Simran item, in scope at a time; choosing a bani
  already in scope opens it for editing (GL1–GL4, GI1).
- **Editing never changes a past day:** a new target starts a new row from
  today in the same series; removing an item sets `removedOn`; nothing is
  ever hard-deleted. Removing the last item completes the goal; a completed
  goal is never reopened (GI6–GI8, BG1–BG3).
- **Every paath is a row:** the reader reaching the last line, the recitation
  reaching the end, or **+** in the Diary. Reading and listening in one
  opening count once (CR1–CR6).
- **One verdict:** `verdictOn(day)` returns hazri, items in scope, items met
  and the goal state (`NONE`, `MET`, `NOT_MET`). Today, the Goals screen and
  both Diary screens call it (§4.6 of the file).
- **The goal-complete sheet** (design 61) shows once a day when the goal is
  met, never for a backfilled day (CE1).
- **With no goal**, Today shows the Set Goal card, first-time or again
  wording (GL1).

### 4.4 The Nitnem list

*Rules: `06-nitnem.md`. Screen: 12.*

- The nine banis by `default_slot`: **Amrit Vela** (Japji Sahib, Jaap Sahib,
  Tav Prasad Savaiye, Chaupai Sahib, Anand Sahib), **Evening** (Rehras Sahib),
  **Bedtime** (Kirtan Sohila), **More banis** (Ardas, Sukhmani Sahib).
- Each row: a progress ring (empty, partial with a resume point, done today),
  the name in the app language and in Gurmukhi, and the length or the resume
  point. Tapping opens the reader at the saved line.
- **Play all** on a slot with more than one bani with audio (today the Amrit
  Vela five) queues them back to back, gaplessly.

### 4.5 The reader

*Rules: `06-nitnem.md`. Screens: 13, 14, 15, 16, 48 (complete).*

- **Top bar:** back; the bani's name and, under it, the Gurmukhi name and the
  current section; the script switch **ਅ / अ / A**; **Aa** for the text sheet.
- **Text sheet:** text size 16–40 (default 22; never below 30 in elder mode);
  show meanings, and their language (Punjabi, Hindi, English); Roman under
  Gurmukhi; pause marks (vishraam: short teal, long kesri); Larivaar (words
  joined, one span per word kept for highlighting); keep screen on while
  reading (default on); follow audio (default on). Changes apply live and are
  the same settings as in Settings.
- **Defaults by language:** Punjabi — Gurmukhi, Punjabi meanings; Hindi —
  Devanagari, Hindi meanings; English — Gurmukhi with Roman under it,
  English meanings.
- **Meanings** come only from `content.db`. Where a line has none in the
  chosen language nothing is shown; nothing is translated to fill a gap. The
  Faridkot teeka is shown as "Commentary" behind a disclosure.
- **Resume:** the top visible line and the audio position are saved every
  5 seconds and on close, per bani version (B4, B7); opening returns to that
  line, 30 % down the screen. A paath survives backgrounding, process death
  and a reboot.
- **Completion:** the last line visible for 5 seconds (`READER`), or the
  recitation reaching 95 % (`AUDIO`); once between them in one opening
  (B2). It goes through `completeBani` and nowhere else (B1).
- **End card:** "{bani} complete · Logged in your diary · {time of this
  completion}"; when this was what marked today's hazri, it says so. **Start
  again**, and **Next bani** in the same slot (or **Back to Nitnem**).
- **Never** an ad, a promotion, a badge or a count on this screen.

### 4.6 The recitation, following along, and the player

*Rules: `06-nitnem.md` B5–B6. Screens: 13, 15.*

- **Every bani has a recitation**, bundled in the app (§5), and line and word
  timings checked by ear and locked. Nothing about a recitation is invented:
  no guessed timing, and a squeezed line holds the previous highlight (B6).
- **Following:** the current line on the highlight colour, past lines muted;
  the current word in the word colour with a kesri underline where word
  timings exist. When the line changes it scrolls to 30 % from the top (250 ms,
  ease-out) unless already between 15 % and 60 %.
- **Scrolling by hand detaches** the page; the highlight carries on, a pill
  reads **Back to paath · line {n}**, and the player says "Auto-scroll
  paused". Either re-attaches.
- **Tap a line** to seek to it; play or pause is unchanged.
- **The player bar** in the reader: status, speed, elapsed and total, a
  scrubber, previous, −10 s, play/pause, +10 s, next, and the speed and sleep
  sheet. **Speeds** 0.75, 0.9, 1.0, 1.1, 1.25, 1.5, pitch kept, the same list
  in Settings. **Sleep timer** Off, 15, 30, 60 minutes, with a 5-second fade.
- **The mini player** above the bottom navigation while anything is loaded:
  progress, play/pause, title, time and stop; tapping opens the bani.
- There is no full-screen player. Design 17 drew one in Phase 1 and it was never built; whether it comes back is open (D15, default no).

### 4.7 Background playback

*Rules: `06-nitnem.md` B7, scenarios N-f to N-h, N-o. Screen: 18.*

- A media session and foreground service: the notification and lock screen
  carry previous, −10 s, play/pause, +10 s, next; Bluetooth and headset
  buttons work.
- A call or another app taking audio focus pauses, and playback resumes when
  the interruption ends if it was playing; a short interruption ducks to 30 %.
- **Unplugging headphones or losing Bluetooth pauses and never resumes on the
  speaker.**
- If the media session cannot start, the app opens as a text-only reader.
- Without notification permission, the reader says lock-screen controls are
  off and offers to allow them.

### 4.8 Simran and the globe

**Purpose.** A sitting of Naam Simran, and a sense of the sangat sitting
with you. *Rules: `07-simran.md`. Screens: 88 (at rest), 89 (a sitting
running), 90 (no profile). Data: ARCHITECTURE §5.5, §6.2.*

- **The screen as it ships stays** (owner, 2026-10-07): the serif wordmark,
  the ੴ rule, the verse, the globe, the legend and the controls. Only the
  legend, the dots and their numbers change.
- **The sitting** is 5 minutes, or the minutes of the Naam Simran goal item
  in scope today. It plays the bundled recitation; ਵਾਹਿਗੁਰੂ drifts off the
  globe once per utterance, from the measured onsets. During a sitting the
  countdown takes the presence line's place, with Pause and End. A sitting
  stopped early is saved with its real length; 300 s or more marks hazri.
  **A sitting never needs the network** (§0.4 of the file).
- **Attendance:** the first app open of each IST day, with a profile, marks
  attendance once (`POST /presence/attendance`), then a local flag stops a
  second call that day (AT1–AT2).
- **The globe:** opening Simran fetches one snapshot, refreshed every
  2 minutes, counted by country, state and city. Every profile is counted by
  its city, including people who have since uninstalled.
- **Three dots:** **You** (orange, blinking, on your city), **Live** (green:
  others who opened the app today, IST), **Here today** (blue: everybody else
  counted). One is taken off your city's count for yourself. Dots grow with
  the count.
- **The threads** (decided 2026-10-08): lines from your dot to every other,
  as design 29 drew them. **Without a profile** there is no orange dot, the
  threads join every dot into one web, and a non-dismissible banner under the
  legend offers a profile (NP1–NP3, DR7).
- **Privacy:** nobody is named; nothing finer than a city is shown or stored.
- **Removed:** the Settings simran length, "sitting now" heartbeats and "sat
  today" counts (S-7, S-8).

### 4.9 Diary

**Purpose.** A record of every day, never a judgement. *Rules: `09-diary.md`,
`04-goals.md` §4.7, §7.4–7.5. Screens: 87 (the month), 56 (one day).*

- **Two dots a day, from `verdictOn`:** the first is hazri — orange, or grey
  when not marked; the second appears **only on a day that had a goal item in
  scope** — green when met, grey when not. Green never appears without
  orange. No dots on future days or before the first recorded day. No red, no
  crosses, no "missed" (D1–D4, DV1–DV3).
- **The day** (design 56): the hazri line, the goal block when there was one,
  every bani completed with its count, times and source (Read, Listened,
  Marked in Diary, Restored, Carried over), Simran sittings with their minutes,
  and **+** and **−** for each bani and for Naam Simran.
- **Editing:** today and the 7 days before it; earlier days are read-only and
  the screen says so before anybody tries. **+** adds one completion (or one
  sitting of the larger of 5 minutes and the day's goal minutes); **−** undoes
  the newest, whatever its source (D6, CR3–CR4). Edits also reach the Sangat,
  at most 3 Diary additions a day per group (D7).
- **The streak card** (design 87, option 2, chosen 2026-10-07): **days in a
  row now** in saffron, a rule, **your longest**. When "now" is under 2 only
  "longest" shows; when both are, no card. From `hazriStreak(day)`, the same
  function Today's card calls. It counts hazri days, so Ardas, Sukhmani Sahib
  and a 5-minute sitting extend it (D9, D12; owner, 2026-10-10).
- **Grace days** — two a month — are granted silently and never mentioned
  (D8).
- No diary-sync switch: the weekly backup replaces it (D11). Everything works
  offline (D10).

### 4.10 Notifications

**Purpose.** A small, closed set, each in calm words, approved in all three
languages. *Rules and exact text: `02-notifications.md`. Screen: 50.
Data: ARCHITECTURE §4, §5.10, §7.2.*

| Kind | When (phone time) | Condition | By |
|---|---|---|---|
| **Amrit Vela** | 04:00 | Every day; seven weekday messages; opens the first goal bani, else Japji Sahib; with a profile, the sunrise picture for the profile city | Phone |
| **Goal bani** | The item's own reminder time | The item is in scope and not yet met; one 15-minute snooze | Phone |
| **Gurpurab** | 06:00 on the day | Prakash, Gurgaddi, Joti Jot events the calendar flags, or the reader switched on | Phone |
| **Sikh event** | 07:00 on the day | Any other flagged or switched-on event, Shaheedi Purabs included | Phone |
| **Hazri nudge** | 07:00 | No active goal and no hazri yet today; seven messages; opens a 5-minute sitting | Phone |
| **Sangat digest** | 21:00, the member's own time | Member of a group with an active goal and paath recorded that day; final-days wording on the last two | FCM |
| **Sangat milestones** | At once, 07:00–20:59, else held to 07:00 | 25, 50, 75 % and completion, each once | FCM |
| **New members** | 20:00, the creator's time | Somebody joined the creator's custom group | FCM |
| **Group ended** | The member's next 21:00 | A custom group ended by its end date | FCM |

- **On by default.** Android's own permission prompt appears at app start; a
  refusal leaves a card on the Notifications screen. **Exact alarms are never
  asked**; the screen notes that without them a reminder may arrive minutes
  late (F6, DP2–DP3).
- **No daily cap, no emoji**, never "Happy" for a Shaheedi or Joti Jot day,
  nothing naming who has not taken part, nothing during a Simran sitting
  (moved to its end). Gurbani in a notification is limited to bani names.
- A message needing data the phone lacks at planning (a name, a streak, a
  live count) falls back to that rotation's Sunday message (CM1, CM3).
- **Planned on the phone** for 7 days ahead, at most 60 pending, re-planned at
  start, on resume, after every completion, sitting, Diary edit and goal
  change, on a time-zone change and after boot (CM2).
- **The Notifications screen** (design 50): one switch per kind (Gurpurab and
  events share one; Sangat only for members), the permission card, the
  exact-alarm note, and diagnostics.
- **Removed:** the Rehras, Kirtan Sohila and Daily Simran reminders, the
  evening-before Gurpurab message, the old channels (N-2, open).
- **A badge earned and a goal met are in-app sheets**, never notifications.

### 4.11 Profile

**Purpose.** An optional profile — no login, no password — that puts the
reader on the globe, lets them create groups, and lets them restore their
data on a new phone. *Rules: `01-accounts.md` (the owner's Profile PRD with
the amendments of §13). Screens: 100 (profile, with badges), 101 (edit
profile), 34 (verify email), 35 (privacy and my data); Profile setup follows
the file. Data: ARCHITECTURE §2.4–2.5, §5.4, §6.1.*

- **Every install signs in anonymously and silently.** The reader never sees
  a login screen.
- **Created from Today's banner**, the person icon, the globe's banner, or
  Create in the Sangat — never in setup. Name, email and city required; phone
  optional, stored as typed (digits and a leading +). The city is chosen from
  the app's list of 92 cities; somebody not on it picks the nearest (D2, D9).
- **Email verification by link**, sent by the server (Brevo or similar), opened
  in the app by an App Link; the app shows "verified" only after the server
  has recorded it.
- **An email already in use** offers to confirm it and restore that profile;
  a restore happens only after the link sent to that address is opened. After
  a restore the app offers **Restore my data** (§4.12).
- **Edit profile:** name, city and email; the phone number is not editable. A
  verified email changes only when the new address is confirmed, and the old
  one keeps restoring until then (D11, E-1).
- **The profile screen** (design 100, owner 2026-10-10, replacing 98): a
  navy identity card with name, city, email and its verification, and three
  numbers -- days of Hazri, days in a row, badges earned; the **Badges**
  shelf (§4.14); **Edit profile** and **Back up now** side by side; the last
  backup's date and the phone on one line; **Restore my data**.
- **Edit profile** (design 101, owner 2026-10-10): today's sunrise and
  sunset in the chosen city first, with what it was changed from; then name,
  city and the email with **Change email** in its row.
- **Profile creation adopts** the install's Sangat memberships and badge facts
  (D12, `12-badges.md` SF3).
- **Not built:** deleting a profile, a password, any other sign-in.

### 4.12 Weekly backup and restore

**Purpose.** A profile's goals and diary come back on a new phone. *Rules:
`10-backup.md`. Data: ARCHITECTURE §3.9.2, §5.7, §6.4.*

- **Only with a profile.** Every Sunday at 00:00 local time, plus up to an
  hour's random delay, and by hand with **Back up now**, the app sends every
  goal, goal item, completion, sitting and earned badge changed since the last
  backup. Any network; caught up at the next chance if missed (BK1–BK9).
- **Restore my data** (after a profile restore) merges row by row: it adds
  what the phone lacks, keeps the newer of two versions, never deletes, and
  never touches what it did not receive. With two different active goals the
  phone's stays active and the server's is stored as completed (RS1–RS7).
- **Honest about the gap:** the restore screen says the copy is as of the last
  backup and that anything after it is not included (RS8).
- **Not backed up:** reading positions, reminders, settings, grace days; the
  profile and the Sangat already live on the server. Backups are kept while
  the profile exists.

### 4.13 Sangat

**Purpose.** People working together toward one shared goal with an end
date. *Rules: `08-sangat.md`. Screens: 38 (Sangat), 31 (group), 39 (create),
40 (set goal), 41 (invite), 52 (code problems), 32 and 36 (joining); drawn
before the file, which wins where they differ. Data: ARCHITECTURE §3.5, §5.6,
§6.3.*

- **A group has one goal for life:** so many paath of one bani, or so many
  minutes of Naam Simran (every sitting adds its minutes; decided
  2026-10-09), with a target (1 to 1,000,000) and an end day within 365 days. "Today" for a group is the IST
  day.
- **Three built-in groups** — Amrit Vela Sangat, Simran Sangat, Sukhmani
  Sahib Sangat — run from the admin website. Anybody joins or leaves, with or
  without a profile; no member limit. When a goal is met or runs out, the next
  starts the following day with the same template; finished goals stay as
  history (BI1–BI5).
- **Custom groups** need a profile to create (up to 5 active; support can
  raise it). A name of 1–64 characters, then the goal at once. Private: they
  appear only in their members' lists. Up to 1,000 members. Only the end day
  can change, and only by the creator. A group is inactive when its target is
  met or its end day passes, and stays readable. The creator can remove
  members, cannot leave, and can delete only while alone (CG1–CG10).
- **Joining without a profile** is allowed, as "Sangat member"; creating a
  profile later carries the memberships with it (MB1–MB5).
- **Invites:** any member shares a link and a code (`XXXX-XXXX`, valid 30
  days) through Android's share sheet; joining needs no approval. The link
  opens the app's Join screen with the code filled; without the app, the
  link page shows the code and a Play link that carries it through install,
  and the app reads it once on first launch. The app never reads the
  clipboard by itself (IV1–IV8).
- **Counting:** every completion of the goal's bani, or sitting of at least
  its minutes, by a member, between the goal's start and end, counts once in
  every group whose goal it matches. Diary + counts at most 3 a day per group;
  Diary − takes it back. Leaving keeps what was given. Totals are kept by the
  server only (CT1–CT9).
- **Offline:** paath waits in an outbox on the phone and is sent when the
  network returns (§5.1 of the file).
- **What members see:** my groups (active first), the built-in groups, and a
  group's goal, total, percentage, today's total, days left and members with
  their contributions — never ordered by them, no rank, nobody shown as
  having given nothing; the first 50, then "N more members" (VS1–VS6).
- **Reports:** any member can report a group (offensive name, spam, not about
  Sikhi, other with a note); support is emailed; the admin can disable or
  delete it (RP1–RP4).
- **Not built:** chat or messages, public groups, approval, more than one bani
  a group, changing a goal's target, groups on the globe.

### 4.14 Badges

**Purpose.** Mark the days a reader has kept — never points, never a ranking.
*Phase 3 item 3.2, specified and designed 2026-10-08. Rules: `12-badges.md`.
Screens: 95–99. Data: ARCHITECTURE §3.6, §5.8–5.9, §6.5.*

| # | Badge | Gurmukhi | Marks | Earned when |
|---|---|---|---|---|
| 1 | Jigyasu | ਜਿਗਿਆਸੂ | The seeker | The first hazri |
| 2 | Shardhalu | ਸ਼ਰਧਾਲੂ | Coming back with shardha | Hazri on 7 days |
| 3 | Abhyasi | ਅਭਿਆਸੀ | One who practises | Hazri on 40 days |
| 4 | Nitnemi | ਨਿਤਨੇਮੀ | Keeps the Nitnem | **The five morning banis** — Japji, Jaap, Tav Prasad Savaiye, Chaupai, Anand Sahib (`default_slot` = `morning`) — all on one day, on 40 days |
| 5 | Simrani | ਸਿਮਰਨੀ | Settled in Simran | A sitting of 5 minutes or more on 108 days |
| 6 | Paathi | ਪਾਠੀ | Has read every bani through | Every bani in `content.db` completed at least once |
| 7 | Sevadar | ਸੇਵਾਦਾਰ | Sewa in the sangat | 3 sangat goals reached that the reader contributed to |
| 8 | Gursikh | ਗੁਰਸਿੱਖ | The whole of it held together | Nitnemi, Simrani and Paathi, and hazri on 180 days |
| 9 | Satsangi | ਸਤਿਸੰਗੀ | Brought others into the sangat | 5 people joined groups the reader created |
| 10 | Vichari | ਵੀਚਾਰੀ | The long road | Hazri on 365 days |

- **No points, no XP, no total, no exchange rate between banis.** Counts are
  **totals, never runs**: a missed day resets nothing. **Nothing is ever taken
  away.** Never a ranking or a comparison.
- **Derived from the Diary's own rows**; only which badges were earned, and
  when, is stored. Eight are counted on the phone and need no profile;
  Sevadar and Satsangi come from the server and need one.
- **Days already in the Diary count** when badges ship; only the highest
  earned is announced. Earned badges are in the weekly backup and come back
  on restore without being announced again.
- **Excluded names:** Khalsa, Sant, Brahmgyani, Granthi, Bhai Sahib, Gyani,
  Pracharak — names Sikhi confers, not an app.

**Screens** (chosen 2026-10-08 from four options a screen):

| Design | Option | Screen |
|---|---|---|
| 95 | 1C | **A badge earned:** a compact bottom sheet in the app — the badge, "New badge", its name and what it marks, "Your badges n of 10" with the ten (the new one ringed), **Done** and **See all badges**. Once, the next time a non-Gurbani screen is open. **Never a system notification** |
| 96 | 2A | **Badges:** "n of 10 earned · Hazri on N days", two per row; earned ones in colour with their date, the rest greyed with their name, how to earn them and "Not yet" |
| 97 | 3B | **One badge:** a full page — "Badge n of 10", the badge, the Earned chip or "Not yet", *What it marks*, *How it is earned* (for Nitnemi the five bani names from `content.db`), previous and next |
| 98 | 4B | **In the profile:** a Badges section under the profile card, all ten five to a row, "See all 10". **Replaced on 2026-10-10 by design 100**, the same ten on two shelves of five under a navy identity card (§4.11) |
| 99 | 5C | **In the menu:** a navy header with the avatar, name and city, "Badges n of 10" and the row of ten; Badges is also a menu row |

No progress meters anywhere. No badge on Today, on the reader, the player or
a Simran sitting. The Diary has no badges row.

### 4.15 ਅੱਜ ਦਾ ਵਿਚਾਰ and the Vichar library

**ਅੱਜ ਦਾ ਵਿਚਾਰ** (bundled, offline). One line of Sri Guru Granth Sahib Ji a
day from 200 reviewed lines in `content.db`, each with a Punjabi and an
English meaning. The line is chosen by date (days since 1970-01-01 modulo
200), so every phone shows the same line on the same day. Hindi readers see
the Punjabi meaning until a reviewed Hindi one exists. The dataset has no Ang
numbers and none is invented.

- **Today card:** "Today's Vichar", "Sri Guru Granth Sahib Ji", the line, its
  meaning, **Explore** (the library) and **Share**; tapping opens the Vichar
  screen (the line, the Punjabi and English meanings, Share, "More to read").
- **Share:** as text (line, meaning, attribution, "Read daily on Hazri"), or as
  an image (1080 × 1350, its own paper palette with a kesri border and ੴ, the
  same in either theme).

**The Vichar library** (needs the network). Articles and reference entries
on Gurdwaras, the Guru Sahiban, banis and Sikh days, with search and kind
filters. **Nothing in it is written in Dart** — it is published content
(`docs/vichar-content.md`), and rule 2 of §0.3 applies to it. It moves
behind the API (`01-accounts.md` §13.4). It is empty until entries are
published. Screens 43–46.

### 4.16 Gurpurab and Nanakshahi calendar

*Screen: 22.* Nanakshahi 558 (14 March 2026 – 13 March 2027) from the SGPC
jantri, 147 events in 12 kinds, 52 flagged to remind.

- A header with today's Nanakshahi date and the Gregorian date; **This week**
  and **Coming up**; a filter for Gurpurabs only or all days (Sangrand,
  Puranmashi, Masya and the rest).
- Each event: date block, name in the app language (English where a
  translation does not exist yet), Gurmukhi name, Nanakshahi label, Today or
  Tomorrow, and a **bell** that switches its notification on or off
  (§4.10).
- Outside the bundled year the screen says the data is not in this build.
  **Nanakshahi 559 must be added before March 2027.** Only 10 of 147 event
  names have Punjabi and none Hindi; filling them is content work (§5).

### 4.17 Elder mode

Offered in setup and in Settings. One app, larger: text at least 1.6× and
the reader never below 30; touch targets at least 64 dp; three tabs (Today,
Nitnem, Diary) with Simran and Sangat still reachable; Today is the same
screen at larger sizes (`05-today.md` T5). It never hides content. The
system font scale is respected up to 1.3×.

### 4.18 Menu, Settings, About and privacy

- **Menu** (design 99): §3.2. *Your profile* opens the profile (or Profile
  setup); *Badges* the Badges page; *Notifications* the Notifications screen;
  *Audio and voice*, *Text size and script* and *Language* the matching part
  of Settings; *Privacy and my data*; *About and credits*.
- **Settings** (design 27, pushed): Language; Reading (script, meanings and
  their language, Roman under Gurmukhi, pause marks, Larivaar, text size, keep
  screen on, follow audio); Audio (speed, lock-screen controls); Bani versions
  (SGPC); Notifications (opens §4.10's screen); Display (theme Auto, Light,
  Dark; elder mode); About (credits, privacy, the analytics switch shown as
  off and inert, licences, version). **Removed:** the reminder rows, the
  sunrise-and-sunset city, the diary-sync row.
- **About and credits:** what Hazri is; every source from `content.db`'s
  `source` table (text, transliteration, meanings and teeka, calendar); city
  data; fonts (SIL OFL); the recitation (bundled, never streamed; the paathi
  uncredited until a credit is agreed, D9); "Works offline · No login · No ads
  on Gurbani".
- **Privacy and my data** (design 35): the reader's copy of §8. Rewritten in
  the same release that ships the profile, attendance and the backup.
- **Licences:** Flutter's licence page with the font licences.

### 4.19 Admin website

**Purpose.** One person runs the built-in groups, acts on reports and helps
people. *Rules: `11-admin.md`. Data: ARCHITECTURE §6.6, §8.5.*

- A separate site, `hazri-admin-d4b72.web.app`, linked from nowhere. **Google
  sign-in, on this site only**, accepted for the one admin email; the server
  checks it on every request. Any other account can do nothing.
- **Dashboard:** opened the app today, total and new profiles, active custom
  groups, built-in groups with their progress, Sangat paath today, open
  reports — counted when the page opens or on Refresh, never polled.
- **Built-in groups:** create and edit (names in three languages, the goal
  template), start, history, disable or enable. Editing changes the next goal,
  never the running one.
- **Reports:** disable, enable, delete (typing the name to confirm), dismiss.
- **People:** look up a profile by email; set the custom-group limit (5–100).
- Every change is written to an audit log. English only. No third-party
  analytics. The app is unchanged: still no sign-in screen and no password.

---

## 5. Content and audio

Rule 2 of §0.3 governs all of it: nothing Gurbani-related is written,
paraphrased, translated or generated by the app or by anybody building it.

| Content | State | Source and rules |
|---|---|---|
| **Text** | All nine banis, SGPC versions, Gurmukhi, Devanagari, Roman, with pause marks | Shabad OS database and `gurmukhi-utils`, through the pipeline. Japji is schema 1.0; the other eight schema 2.0 (`build_bani_v2()`). Schema-2.0 banis carry no section labels and none is invented |
| **Meanings** | English for every bani; Punjabi for all but Ardas (9 of 27 lines); Hindi only for the four banis in Sri Guru Granth Sahib Ji (the Faridkot teeka) | The reader shows what exists; nothing is machine-translated |
| **Recitations** | One per bani and one for Naam Simran, bundled in the app (about 81 MB of AAC) | Masters on the `audio-masters` release; `audio/README.md` rebuilds them |
| **Timings** | Line and word timings for all nine, **checked by ear and locked** | Never re-align; a correction is a `pin` and `--repin`, and the bani goes back to unverified until listened to again (`timings/verified.json`) |
| **ਅੱਜ ਦਾ ਵਿਚਾਰ** | 200 lines with Punjabi and English meanings | `content/source/vichar/gurbani-200.json` |
| **Calendar** | Nanakshahi 558, 147 events | `calendar-558.json`, `gurpurab-558.json`; **559 due before March 2027**; event names need Punjabi (10 of 147 done) and Hindi (none) |
| **Cities** | 92, each to carry a state code for the globe | `tools/content_pipeline/cities.json`; the pipeline fails on a city without a state (`07-simran.md` §5.1) |
| **The Vichar library** | Empty until entries are published | `docs/vichar-content.md` |

The paathi is uncredited; a credit is added to `voice` in the pipeline when
one is agreed (D9). Regenerating: `python3
tools/content_pipeline/build_content_db.py`.

---

## 6. Design

### 6.1 The design system

`design/tokens.json`, mirrored in `lib/core/theme/` as `HazriColors`.

- **Colour:** light and dark tokens — `bg`, `card`, `card2`, `ink`, `ink2`,
  `muted`, `rule`, `primary`, `onPrimary`, `kesri`, `kesriSoft`, `kesriInk`,
  `sage`, `sageSoft`, `teal`, `hl`, `word`, `scrim`. In dark, `primary`
  becomes kesri.
- **Type:** UI Mukta; headlines and big numbers Baloo Paaji 2; Gurbani Noto
  Serif Gurmukhi and Noto Serif Devanagari; the Simran wordmark Playfair
  Display (Latin only; other scripts fall back to the Noto serifs). Fonts are
  bundled, never fetched.
- **Shape:** cards 20 dp with the token shadow (light) or a hairline (dark);
  buttons 16 dp, at least 52 dp tall; chips fully round; sheets 28 dp at the
  top; Today's app bar 28 dp at the bottom.
- **Motion:** 200–250 ms ease-out; the line highlight cross-fades in 150 ms;
  nothing bouncy or celebratory on a Gurbani screen, and no confetti, sound or
  vibration for a badge.
- **Theme:** Auto, Light, Dark; every screen is drawn in both.
- **Icons:** 24 dp outline, 1.8 stroke, round caps.

### 6.2 The screens

`design/canvas.html` shows every screen by feature, marked *new*, *current*,
*superseded* or *reference*, and is published at
<https://claude.ai/artifact/Fz2WJs5tPF9nUWPgkgBkR8>. Phase 2 screens are
generated by `tools/design/build_phase2.py` (never edited by hand), checked
by `tools/design/check_structure.py`. Appendix A is the full index.

**Chosen by the owner** from three or four options each:

| Date | Feature | Choice | Designs |
|---|---|---|---|
| 2026-10-07 | Today | App bar D (navy, Today only); streak option 3 (the week strip) | 85, 86 |
| 2026-10-07 | Diary | Streak option 2 (now and longest) | 87 |
| 2026-10-08 | Simran | The screen as it ships, with design 29's threads; a web of threads without a profile | 88, 89, 90 |
| 2026-10-08 | First run | Android's splash only; Welcome option D, "a day with Hazri" | 91–94 |
| 2026-10-08 | Badges | 1C sheet, 2A page, 3B one badge, 4B profile section, 5C menu header | 95–99 |

Screens drawn before their feature file — Goals (19, 47, 42), the Sangat
(38, 31, 39, 40, 41, 52, 32, 36) and the account screens (34, 35) — are
current with the note that the file wins where they differ.

---

## 7. Language and accessibility

- **Three languages** for every string — Punjabi (Gurmukhi), Hindi, English —
  in ARB files; `l10n_test` fails on a missing key. Bani and event names come
  from `content.db`. The Punjabi and Hindi drafted by the implementer are
  verified by the owner before release (`01-accounts.md` §13.9).
- **Dates and times** localised (`pa_IN`, `hi_IN`, `en_IN`); the device's 12-
  or 24-hour clock; Western digits in the UI; Gurbani keeps its own numerals.
- **Accessibility:** TalkBack labels on every icon button; the reader's lines
  expose their text; the current line changing is **not** announced, so it
  never talks over the paath; touch targets at least 48 dp (64 in elder
  mode); body contrast at least 4.5:1 in both themes; system font scale up to
  1.3×.

---

## 8. Privacy, data and analytics

### 8.1 What leaves the phone

Nothing leaves the phone for somebody who never makes a profile or joins a
group, except the anonymous sign-in. The closed list for Phase 2:

| What | When | Sent |
|---|---|---|
| Anonymous sign-in | At launch | An install id, by Firebase Auth |
| **A profile** | Only when the reader makes one | Name, email, city (from the list), phone if given; verification and restore mail to that email |
| **Attendance** | Once a day, with a profile | That the profile opened the app on that IST day |
| **Weekly backup** | With a profile | Goals, goal items, completions, sittings, earned badges |
| **Sangat contributions** | For a member of a group | Each paath or sitting that could count, from the outbox |
| **An FCM token** | With a profile **and** a group | The device's push token, its language and time zone |
| **Analytics** | Never in Phase 2 | Firebase Analytics ships with collection off (`setAnalyticsCollectionEnabled(false)` at start-up); the Settings switch is shown off and inert |

**Never, in any phase:** an advertising ID (`AD_ID` removed from the merged
manifest), ad personalisation, location (the city is chosen from a list),
free text in analytics, anything sold or shared. The globe shows a city and
a count, never a name; the Sangat shows a member's name only to the members
of their group.

### 8.2 By phase

| | Phase 1 | Phase 2 | Phase 3 |
|---|---|---|---|
| `INTERNET` | Removed | **Restored** | Present |
| Firebase SDKs | None | Core, Auth (Anonymous), Analytics (off), Messaging (Sangat only). **No client Firestore** | The same, plus Crashlytics |
| Analytics | n/a | **Off**; sends nothing | **On**, with a working opt-out that stops Analytics and Crashlytics |
| Feedback (3.1) | n/a | n/a | What the reader typed and sent; never through analytics |

### 8.3 The privacy screen

The privacy screen is this section in the reader's words, and it **never
runs ahead of what the build does**. It is rewritten in the same release that
ships the profile, attendance and the backup: nothing is sent unless you
make a profile or join a group; what each of those sends; that analytics are
not collected; that the globe shows your city and never your name. In Phase 3
it names analytics as a fourth category and points at the switch. It must
match Google Play's Data safety form exactly.

---

## 9. Android

- **minSdk 24, targetSdk and compileSdk 36.** Phones, portrait; tablets in
  phone layout. Edge-to-edge with insets handled on every screen; predictive
  back.
- **Permissions:** `POST_NOTIFICATIONS` (asked at app start); `SCHEDULE_EXACT_ALARM`
  (declared, never asked; never `USE_EXACT_ALARM`); `RECEIVE_BOOT_COMPLETED`;
  `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MEDIA_PLAYBACK`; `WAKE_LOCK`;
  `VIBRATE`; `INTERNET`. `AD_ID` removed.
- **Receivers:** `ScheduledNotificationReceiver` and the boot receiver must
  both be declared, or no scheduled notification can appear; the audio
  service and media-button receiver. `test/android/manifest_test.dart` holds
  them and has been watched failing.
- **Launch mode `singleTask`**, so a tapped link returns to the running app.
- **App Links** on `hazri-dfcc1.web.app` and `hazri-dfcc1.firebaseapp.com`
  (`/verify`, `/j/<code>`), `autoVerify`, release fingerprint only; the
  `hazri://` scheme.
- **Backup:** `allowBackup="true"`, including `user.db` and preferences,
  excluding `content.db`.
- **Signing:** one release key from four GitHub secrets; never in git. A
  build without them is signed with a throwaway key and cannot install over a
  release build. `docs/signing.md`.
- **Builds:** CI analyses, tests and builds the APK on every push; a run
  started by hand keeps it as a rolling pre-release `apk-<branch>`. A failed
  build never deletes the last good APK.
- **`hazri.me`** is registered and connected to nothing; it is added
  alongside `hazri-dfcc1.web.app`, never instead (`docs/domain-setup.md`).

---

## 10. Non-functional requirements

| Area | Requirement |
|---|---|
| Start-up | Today interactive within 1.5 s on a 2022 mid-range phone, 3 s on a 3 GB budget phone; no network call on the path |
| Smoothness | The reader scrolls and highlights at 60 fps; no frame over 16 ms in a 10-minute profile run |
| Follow-along | The highlight within 100 ms (target), 150 ms (maximum) of the timing data, at every speed |
| Offline | Everything but the Sangat, the globe, the profile, the backup and the Vichar library works in airplane mode |
| Battery | Position ticks only while the reader or a player is visible; the globe refreshes every 2 minutes only while Simran is open |
| Cost | Today, Nitnem, the reader and the Diary read no Firestore document; the globe one per fetch (ARCHITECTURE §10) |
| Reliability | Crash-free users ≥ 99.5 %; every database migration tested on real-shaped data |
| Security | No secrets in git; Firestore denies every client; admin checked on the server; the keystore never committed |
| Size | The APK carries the audio (about 81 MB of it); nothing else large is bundled |

---

## 11. Implementation plan

### 11.1 How every step is built

1. **Read the feature file first**, then write its scenarios as tests before
   the code; a scenario nobody can write is a rule nobody has decided.
2. **Test at the seam the bug lives at.** A pure function's unit test proves
   the function and nothing else; the manifest, the rules, the migration and
   the platform calls get their own tests (`00-platform.md` §0.5).
3. **A guard nobody has seen fail is not a guard.** Break it on purpose, watch
   it fail, then fix it.
4. **One rule, one function.** Nothing re-derives hazri, the goal state, the
   streak or a badge.
5. **Each step ends** with `flutter analyze` clean, `flutter test` passing, the
   Functions' and rules' emulator tests passing, and the feature file's
   acceptance checklist met; then the hand deploys of §11.5.
6. **The documents move with the code**: the feature file, this PRD where it
   summarises, `ARCHITECTURE.md` for data.
7. **Code comments that cite PRD v1.0 sections** ("PRD 1.12", "PRD §13") are
   corrected to this document as each step touches the file.

### 11.2 Before step 1

| Needed | From | For |
|---|---|---|
| Brevo (or similar) API credentials, stored in Secret Manager | Owner | Step 4: verification and restore mail. Until then the sender is written against the API and switching it on is configuration (W6) |
| PITR (7 days) and daily backups (90 days) on the `asia-south1` database | Owner, in the console | Before any real user data (P6) |
| Flutter in the working environment, or CI as the only check | Owner / setup script | Every step (rule 7) |
| A `functions/` TypeScript project and the Firestore emulator in CI | Step 1 | Every server step |

### 11.3 The order

The order is dependency, not preference: each step needs the ones before it.

| Step | Build | Needs | Ships |
|---|---|---|---|
| 1 | **Platform** | — | The `api` Function, the emulator in CI, the Vichar library behind the API |
| 2 | **Notifications**, local kinds | — | Amrit Vela, Gurpurab and events, the hazri nudge, the Notifications screen |
| 3 | **Goals and Diary** | 2 | `user.db` v5, `verdictOn`, `completeBani`, Goals, the Diary, goal reminders, the Diary streak |
| 4 | **Profile** | 1 | The profile, links by email, Edit profile; the old account, sangat and presence code removed; deny-all rules live |
| 5 | **Weekly backup** | 3, 4 | Back up now, the weekly job, Restore my data; diary sync removed |
| 6 | **Sangat and the admin website** | 1, 4 | Groups, invites, counting, Sangat pushes, the admin site |
| 7 | **Simran and the globe** | 4 | Attendance, the snapshot, the new legend, threads and web |
| 8 | **Today and Nitnem** | 3, 4 | Today rebuilt, the menu, the reader and player fixes |
| 9 | **Badges** | 3; 4, 5 for the profile section and backup; 6 for Sevadar and Satsangi | All five badge screens |
| 10 | **First run** | everything | Android's splash, Welcome, Language, How you read |
| 11 | **Release** | everything | §13 |

### 11.4 Each step

**Step 1 — Platform.**
- *Add:* `functions/` (Node 20, TypeScript, Express), the one `api` Function
  in `asia-south1` behind the Hosting rewrite `/api/**`; the common rules of
  ARCHITECTURE §6.1 (`01-accounts.md` §6.0): token check, error shape, rate
  limits; the Functions contract (`maxInstances: 10`, `minInstances: 0`); the
  Firestore emulator and rules tests in CI; `lib/core/backend` API client with
  the 401 retry and timeout.
- *Move:* the Vichar library from client-read `content/vichar/entries` to an
  API endpoint.
- *Tests:* the common rules, both paths of each; a Function run twice.
- *Done when:* `api` is deployed and answers; CI runs the emulator.

**Step 2 — Notifications (local).**
- *Change:* `ReminderPlanner.plan` stays pure and gains its new inputs;
  `reschedule()` seeds nothing and reads no stored rows; five channels
  (`amrit_vela`, `goal_reminders`, `sikh_calendar`, `hazri_nudge`, `sangat`);
  the old channels and rows deleted on upgrade.
- *Add:* the approved messages in three languages; the rotations and the
  Sunday fallback; the move-to-the-end of a sitting; the Notifications screen
  (design 50) with diagnostics.
- *Remove:* the Rehras, Kirtan Sohila and Daily Simran reminders, the
  evening-before Gurpurab, the reminder rows in Settings, the exact-alarm ask.
- *Tests:* the planner at every rule; the manifest receivers (kept); a phone
  check of a 04:00 notification arriving.
- *Done when:* `02-notifications.md` §11 passes for the local kinds; goal-bani
  reminders wait for step 3 and Sangat pushes for step 6.

**Step 3 — Goals and Diary.**
- *Data:* `user.db` v5 (ARCHITECTURE §3.3 and §3.7): `goals` and `goalItems`,
  `completions` and `simranSessions` with `source`, `updatedAt`,
  `deletedAt`; `goal_ticks` folded in and dropped; the `reminders` table
  dropped. A migration test on real-shaped v4 rows.
- *Add:* `verdictOn`, `hazriStreak`, `completeBani` as the only insert path;
  the Goals screen, the Add goal and Edit item sheets, the goal-complete
  sheet; the Diary month with two dots and the streak card (87); the day
  screen with + and − (56); goal-bani reminders.
- *Remove:* `GoalCalculator.outcomeOn`, `creditGoalsFor` at the call sites,
  `forgetGoal`, `archiveGoal`, per-day uniqueness of completions.
- *Tests:* one test feeding Today, Goals, the Diary grid and the day screen
  the same rows and checking they agree; every combination for DV1.
- *Done when:* `04-goals.md` §9 and `09-diary.md` §9.7 pass.

**Step 4 — Profile.**
- *Remove* (W1–W4, §13.4 of the file): the existing account code, the whole
  old Sangat (`lib/features/sangat/`), the old presence writes and globe
  counts, `cloud_firestore`, the Email/Password provider's use; publish the
  **deny-all `firestore.rules`**. Between this step and steps 6 and 7 the
  Sangat tab and the globe show their offline state in test builds.
- *Server:* `profiles`, `emailIndex`, `owners`, `verificationTokens`, `mail`;
  the profile, link and edit endpoints; the Brevo sender.
- *App:* anonymous sign-in at launch; the profile cache; Profile setup with
  the city list; the profile screen; Email sent and Link result; Edit
  profile; the profile banner and person icon on Today; App Links for
  `/verify` (kept).
- *Privacy:* rewrite the privacy screen for the profile (§8.3).
- *Remove:* the `city_id` preference and the Settings city.
- *Done when:* `01-accounts.md` §11 passes, both paths of every rule; a
  verification and a restore completed end to end on a phone.

**Step 5 — Weekly backup.**
- *Server:* `backupMeta`, `backupGoals`, `backupWeeks`, `backupBadges` (empty
  until step 9); the backup endpoints.
- *App:* the WorkManager job `weekly-backup`; Back up now and Restore my data
  on the profile screen; the restore merge; the restore screen's honest gap.
- *Remove:* `lib/features/sync/`, the `/sync` screen, `diary_sync`,
  `sync_wifi_only`.
- *Privacy:* the privacy screen names the backup.
- *Done when:* `10-backup.md` §10 passes; a clear-data-and-restore on a phone
  brings the diary back.

**Step 6 — Sangat and the admin website.**
- *Server:* every collection of ARCHITECTURE §5.6; the Sangat endpoints;
  `sangatTotals`, `sangatRollover`, `sangatProfileSync`, `sangatDispatch`,
  `sangatMilestone`; `fcmTokens`; reports mailed to support.
- *App:* the Sangat tab, Create, Set goal, Join, Group, Invite and Report; the
  outbox and its flush; the invite link page `public/j/`; the install
  referrer; `firebase_messaging` and the Sangat notifications.
- *Admin:* the `hazri-admin-d4b72` site — Google sign-in for the admin email,
  dashboard, built-in groups, reports, people, the audit log; create and
  start the three built-in groups.
- *Done when:* `08-sangat.md` §12, `02-notifications.md` §11 and
  `11-admin.md` §8 pass; the rules test that no client can read anything.

**Step 7 — Simran and the globe.**
- *Content:* a state code for each of the 92 cities in `cities.json`; the
  pipeline writes `state_code` and `functions/src/cities.json`.
- *Server:* `lastSeenDay`; `buildGlobeSnapshot`; the presence endpoints.
- *App:* attendance once a day with its flag; the snapshot every 2 minutes
  while Simran is open; the legend You, Live, Here today; dot sizes; the
  threads, and the web and banner without a profile; the sitting's length
  from the goal.
- *Remove:* the Settings Simran length, `simran_minutes`, heartbeats and "sat
  today".
- *Privacy:* the privacy screen names attendance and the city on the globe.
- *Done when:* `07-simran.md` §10 passes.

**Step 8 — Today and Nitnem.**
- *Today:* the navy app bar, the order of §4.2, the streak card, the goal
  widget, the CTA order, the Gurpurab card; elder mode as one tree
  (`ElderTodayScreen` removed); the join banner and the day arc removed.
- *Menu:* design 99's items (its badges header arrives in step 9).
- *Nitnem:* `completeBani` everywhere; and the defects found on 2026-10-08:
  the end card's time is the completion's, not the hazri time; the sleep
  timer marks only the chosen length; Settings offers all six speeds; the
  calendar's empty text says what it covers; stale strings ("Japji Sahib
  plays offline", the "Hukamnama share card" comment) corrected.
- *Done when:* `05-today.md` §5.7 and `06-nitnem.md` §6.6 pass, golden renders
  of 85 and 86 in both themes and normal and elder sizes.

**Step 9 — Badges.**
- *Data:* `user.db` v6 `badges`; `badgeFacts`, `badgeGoalReached`, the join
  count in the join transaction; `GET /badges/sangat`; `backupBadges`.
- *App:* `evaluateBadges()` at every trigger, off the UI thread; the earned
  sheet (95), the Badges page (96), one badge (97), the profile section (98),
  the menu header (99); history counted on first run, only the highest
  announced.
- *Done when:* `12-badges.md` §9 passes; the eight phone badges can ship
  before step 6 if the order changes.

**Step 10 — First run.**
- *Remove:* the branded splash, the three intro pages, the reminders setup
  step.
- *Add:* the redirect before the first frame; Welcome (92), Language (93), How
  you read (94); held invites and links; resumable setup.
- *Done when:* every scenario of `03-first-run.md` §3.7 passes; a fresh install reaches
  Gurbani in under 30 seconds.

### 11.5 Deployed by hand

No workflow deploys the server. A step that changes one of these is only
done once it is deployed, and its PR says so (ARCHITECTURE §9).

| Change | Command | Steps |
|---|---|---|
| Rules and indexes | `firebase deploy --only firestore` | 4, 6, 7, 9 |
| Functions | `firebase deploy --only functions` | 1, 4–7, 9 |
| Public site (`/verify`, `/j/`, `assetlinks.json`) | `firebase deploy --only hosting` | 4, 6 |
| Admin site | `firebase deploy --only hosting:admin` | 6 |

### 11.6 What on the branch is replaced

ARCHITECTURE §11 lists everything in today's code that the target replaces,
and which step removes it.

---

## 12. Testing

- **Unit:** every numbered rule at its boundary and one past it, from rows in
  an in-memory `user.db`; `verdictOn`, `hazriStreak`, `evaluateBadges`, the
  notification planner; solar times, the Nanakshahi date, the timing lookup.
- **Agreement:** one test feeds Today, Goals, the Diary grid and the day
  screen the same rows and checks they agree.
- **Migrations:** v4 → v5 → v6 on real-shaped data.
- **Server:** every endpoint's success and failure paths on the emulator;
  every Function run twice; rules refuse every client read and write.
- **Config is code:** the manifest (receivers, permissions, `singleTask`, the
  keystore never tracked, no double hyphen in a comment), `firebase.json`
  (dotfiles deployed), App Link hosts, `assetlinks.json` against the signing
  key.
- **Widget and golden:** every *new* and *current* screen in both themes; Today
  in three languages and at elder sizes.
- **Language:** `l10n_test` over every key in three languages.
- **On a phone:** notifications arriving (and after a reboot), background
  playback through a call and an unplug, a verification and a restore end to
  end, a backup and restore after clearing data. Android 10, 13, 14 and 16,
  on Samsung, Xiaomi and a Pixel, and one 3 GB phone.
- **Content:** the three alignment checks stay green; alignments stay locked.

---

## 13. Release checklist

- [ ] Every step of §11 done and deployed; CI green on the release commit.
- [ ] Text and meanings licences confirmed for every source (D1); recitation
      rights in writing (D3).
- [ ] Punjabi and Hindi strings, and the badge names, checked by a native
      reader.
- [ ] The privacy screen matches §8 and Play's Data safety form; the privacy
      policy URL live.
- [ ] PITR and daily Firestore backups on (P6); spend alerts at 50/90/100 %.
- [ ] Release signing key in place; `assetlinks.json` deployed with its
      fingerprint; App Links verified on a phone.
- [ ] Nanakshahi 559 added before March 2027.
- [ ] Closed testing with at least 12 testers for 14 days; then production.
- [ ] Store listing in three languages; "No ads on Gurbani, ever".

---

## 14. Open decisions

Each has a default the build follows until the owner decides; only D12
blocks anything (Phase 3 item 3.3).

| # | Question | Default | Where |
|---|---|---|---|
| D1 | Licences for the text and meanings in `content.db` | Confirm each source before public release | `source` table |
| D3 | Written rights for the recitations | Needed before public release | — |
| D9 | The paathi's credit | Uncredited; nothing invented | `voice` |
| D11 | Native check of the badge spellings (Gurmukhi, Devanagari) | Drafts until checked | `12-badges.md` BD-3 |
| D12 | Sehaj Path: the marker, or the full Saroop | The marker; **blocks 3.3** | §2.3 |
| D15 | A full-screen player (design 17) | Not in Phase 2 | §4.6 |
| P6 | Firestore PITR and daily backups on `asia-south1` | Set them: 7 days, 90 days | `00-platform.md` |
| E-1 | Changing a verified email | Waits until the new address is confirmed | `01-accounts.md` §13.8 |
| W6 | Brevo credentials | The owner supplies them | `01-accounts.md` §13.10 |
| N-1 | Monday's hazri nudge needs a live count | Usually the Sunday fallback | `02-notifications.md` |
| N-2 | Rehras, Kirtan Sohila, Daily Simran reminders; "added to a sangat"; new Vichar; corrected line | Removed | `02-notifications.md` |
| F-1–F-3 | Welcome kept; elder mode offered; audio asked at first play | As written; audio is bundled, so F-3 does not arise | `03-first-run.md` |
| T-1, T-3 | The day arc; elder mode as one tree | No arc; one tree | `05-today.md` |
| B-1 | Partial credit for Sukhmani Sahib | A resumable position is enough | `06-nitnem.md` |
| Y-3 | Export the diary | Not built | `09-diary.md` |

**Closed:** D13 (Blaze with Cloud Functions, 2026-09-26); D11's names and D14
(badges, no points, 2026-10-08); P5 (diary sync replaced by the weekly
backup, 2026-10-07).

---

## Appendix A — Screen index

Generated from `design/canvas.html`. **Only *new* and *current* screens are the visual spec;** a *superseded* one is history and says what replaced it. Every screen has `.light` and `.dark` HTML in `design/html/`; where a screen and its feature file differ, the file wins.


**Today** — `05-today.md`

| Screen | Title | Status | Note |
|---|---|---|---|
| `85-TodayAppBar` | Today, with the app bar and streak | **new** | App bar D and streak option 3, chosen 7 Oct. 05-today.md T11, T12 |
| `86-TodayNoProfile` | Today, first day, no profile | **new** | The profile banner overlaps the app bar; no streak yet. 05-today.md T-a |
| `61-GoalComplete` | All of today's goals are done | current | Shown once a day when the goal is met. 04-goals.md CE1 |
| `58-TodayHazri` | Today, hazri marked | superseded | Replaced by 85 |
| `59-TodayNotYet` | Today, hazri not yet | superseded | Replaced by 85 and 86 |
| `60-TodayPunjabi` | Today in Punjabi | superseded | Same layout as 85, in Punjabi |
| `30-Today` | Today, Phase 2 | superseded | Replaced by 85 |
| `09-Today` | Today, Phase 1 | superseded | Replaced by 85 |
| `10-TodayHindi` | Today in Hindi, Amrit Vela dark | superseded | Same layout as 85, in Hindi |
| `11-ElderMode` | Elder mode, Punjabi | superseded | Elder mode is 85 at larger sizes, not its own screen. 05-today.md T5 |

**Diary** — `09-diary.md`

| Screen | Title | Status | Note |
|---|---|---|---|
| `87-DiaryStreak` | Diary, the month, with the streak | **new** | Streak option 2, chosen 7 Oct. 09-diary.md D12 |
| `56-DiaryToday` | Diary, one day | current | The day screen of 04-goals.md 7.5 |
| `57-Diary` | Diary, the month, Phase 2 | superseded | Replaced by 87; grace days are never shown (09-diary.md D8) |
| `26-Diary` | Nitnem Diary, Phase 1 | superseded | Replaced by 87 |

**First run** — `03-first-run.md`

| Screen | Title | Status | Note |
|---|---|---|---|
| `91-SystemSplash` | Android's splash | **new** | The app mark on #0C0F24, drawn by Android while the app starts. 03-first-run.md F1 |
| `92-Welcome` | Welcome | **new** | Option D, chosen 8 Oct: a day with Hazri, from the 04:00 reminder to the streak, and Begin. F2 |
| `93-SetupLanguage` | Language | **new** | Applies the moment it is tapped. F2 |
| `94-SetupReading` | How you read | **new** | Script and size against a real line; elder mode; Skip. F2, F8 |
| `05-SetupLanguage` | Setup, language, Phase 1 | superseded | Says Ang Sang; replaced by 93 |
| `06-SetupReading` | Setup, how you read, Phase 1 | superseded | Replaced by 94 |
| `02-IntroAlwaysWithYou` | Intro 1, Always with you | superseded | One Welcome screen, no carousel. 03-first-run.md F2 |
| `03-IntroReadAlong` | Intro 2, Read along | superseded | One Welcome screen, no carousel |
| `04-IntroYourLanguage` | Intro 3, Your language | superseded | One Welcome screen, no carousel |
| `07-SetupReminders` | Setup, reminders | superseded | Not part of setup; reminders are on by default |
| `08-ReminderTime` | Pick your own reminder time | superseded | Amrit Vela is 04:00; goal items carry their own time. 02-notifications.md |

**Nitnem and the reader** — `06-nitnem.md`

| Screen | Title | Status | Note |
|---|---|---|---|
| `12-NitnemList` | Nitnem list | current |  |
| `13-ReaderFollowing` | Reader, following the audio | current |  |
| `14-ReaderMeanings` | Reader, meanings and pause marks | current |  |
| `15-ReaderHindiScrolled` | Reader in Hindi, scrolled away | current |  |
| `16-ReaderNight` | Reader, Amrit Vela dark | current |  |
| `48-ReaderComplete` | Reader, complete | current |  |
| `17-Player` | Full-screen player | superseded | No full-screen player (PRD 4.6, D15); the paathi is uncredited |
| `18-BackgroundPlayback` | Notification and lock screen | current |  |

**Goals** — `04-goals.md`

| Screen | Title | Status | Note |
|---|---|---|---|
| `19-PaathGoals` | Paath goals | current |  |
| `47-AddGoal` | Add a goal | current |  |
| `42-LogPaath` | Log a paath | superseded | No manual logging: paath count from completions and the Diary + (04-goals CR1-CR4, 08-sangat CT1) |
| `20-AddGoal` | Add a paath goal, Phase 1 | superseded | Replaced by 47 |

**Simran** — `07-simran.md`

| Screen | Title | Status | Note |
|---|---|---|---|
| `88-Simran` | Simran, at rest | **new** | Threads from your dot to every other, as design 29. Legend You, Live, Here today. 07-simran.md SM1, DR1-DR6 |
| `89-SimranSitting` | Simran, a sitting running | **new** | The countdown takes the presence line's place; Pause and End. ਵਾਹਿਗੁਰੂ drifts off the globe |
| `90-SimranNoProfile` | Simran, no profile | **new** | No orange dot, so the threads join every dot into one web; the profile banner under the legend. 07-simran.md NP1-NP3, DR7 |
| `29-Simran` | Simran, Phase 2 | superseded | Replaced by 88 |
| `21-DailySimran` | Daily Simran, Phase 1 | superseded | Replaced by 88 and 89 |

**Sangat** — `08-sangat.md`

| Screen | Title | Status | Note |
|---|---|---|---|
| `38-SangatHome` | Sangat | current |  |
| `31-GroupDetail` | Group, shared goal | current |  |
| `39-CreateGroup` | Create a group | current |  |
| `40-SetGoal` | Shared goal | current |  |
| `41-Invite` | Invite | current |  |
| `52-CodeProblems` | That code did not work | current |  |
| `32-Profile` | Join the sangat | current |  |
| `36-UnlockSheet` | Join the sangat, sheet | current |  |
| `53-RestoreOrNew` | Restore, or start fresh | current |  |
| `54-Restored` | Your sangat is back | current |  |

**Vichar**

| Screen | Title | Status | Note |
|---|---|---|---|
| `43-Vichar` | Vichar | current |  |
| `44-VicharArticle` | Vichar, an article | current |  |
| `45-VicharTopic` | Vichar, a reference entry | current |  |
| `46-VicharSearch` | Vichar, search | current |  |
| `24-Hukamnama` | Hukamnama | superseded | The daily Hukamnama is gone; replaced by Vichar |
| `25-ShareCard` | Hukamnama share card | superseded | Goes with the Hukamnama |

**Calendar and notifications** — `02-notifications.md`

| Screen | Title | Status | Note |
|---|---|---|---|
| `22-GurpurabCalendar` | Gurpurab and Nanakshahi calendar | current |  |
| `50-Notifications` | Notifications screen | current | One switch per kind. 02-notifications.md section 9 |
| `23-Notifications` | Reminder notifications, Phase 1 | superseded | Messages are 02-notifications.md section 5 |

**Badges** — `12-badges.md`

| Screen | Title | Status | Note |
|---|---|---|---|
| `95-BadgeEarned` | A badge earned | **new** | Option 1C: a bottom sheet over Today with the badge, its name and the set of ten; Done and See all badges. 12-badges.md UI1, UI2 |
| `96-Badges` | Badges, all ten | **new** | Option 2A: a two-column grid, earned in colour with the date, the rest greyed with how to earn them. UI3 |
| `97-BadgeDetail` | One badge, opened | **new** | Option 3B: a full page with what it marks and how it is earned; previous and next. UI4 |
| `98-ProfileBadges` | Your profile, with badges | **new** | Option 4B: a Badges section under the profile card, all ten, See all opens 96. UI5 |
| `99-MenuBadges` | Menu, with badges | **new** | Option 5C: the earned set under name and city in a navy header; Badges is a menu row. UI6 |

**Menu, settings and account** — `01-accounts.md`

| Screen | Title | Status | Note |
|---|---|---|---|
| `37-SettingsMenu` | Menu | superseded | Replaced by 99 |
| `27-Settings` | Settings | current |  |
| `33-Account` | Your account | superseded | Replaced by 98 |
| `34-VerifyEmail` | Verify your email | current |  |
| `35-PrivacyData` | Privacy and my data | current |  |
| `49-Sync` | Sync | superseded | No sync switch; a weekly backup runs with a profile. 10-backup.md |

**Reference**

| Screen | Title | Status | Note |
|---|---|---|---|
| `00-Foundations` | Foundations, the design system | reference | Colours, type and components |
| `28-GlobeVariants` | Globe variants | reference | Options explored for the globe |

---

## Appendix B — Decision log, 2026-10-07 and 2026-10-08

The decisions these two days took, in one place. Each is final and overrides
anything earlier. The feature file named holds the detail.

| Date | Decision | File |
|---|---|---|
| 10-07 | Hazri is one completed bani or one Simran sitting of 5 minutes or more; goals are judged apart; one active goal of items, each with its own target, duration and reminder; nothing hard-deleted | `04-goals.md` |
| 10-07 | Every paath is a row; reading and listening in one opening count once; `completeBani` is the only insert | `04-goals.md`, `06-nitnem.md` |
| 10-07 | Diary: two dots, + and − for today and 7 days back; grace days silent | `09-diary.md` |
| 10-07 | Notifications: the closed list; reminders on by default; Android's prompt at app start; exact alarms never asked; Gurpurab 06:00, events 07:00 on the day; no daily cap; no emoji; Rehras, Sohila and Simran reminders removed | `02-notifications.md` |
| 10-07 | Profile: optional, anonymous auth, no password; city from the list; restore brings back goals and diary; Edit profile (name, email, city); go_router, minSdk 24, backup on, `singleTask` | `01-accounts.md` §13 |
| 10-07 | The old sangat, account and presence code is removed and rebuilt; everything through the `api` Function; rules deny all | `01-accounts.md` W1–W4 |
| 10-07 | Weekly backup on Sunday 00:00 with a profile, any network, Back up now, merge-only restore, kept while the profile exists | `10-backup.md` |
| 10-07 | Sangat: three built-in groups, private custom groups by invite, one goal for life, Simran goals count sittings, Diary + capped at 3 a day per group, IST group day, no ranking | `08-sangat.md` |
| 10-07 | Admin website, Google sign-in for the admin only | `11-admin.md` |
| 10-07 | Simran: the screen stays; attendance once a day; globe by profile city; You, Live, Here today; IST day; everybody counted; no profile, no dot | `07-simran.md` |
| 10-07 | One city, the profile's; none without a profile | `03-first-run.md` |
| 10-07 | First run: no profile, city, reminders or Sangat in setup | `03-first-run.md` |
| 10-07 | Today: the navy app bar (D) on Today only; the week-strip streak card (3) from 2 days; CTA puts an unmet goal before the slot's bani; no join banner | `05-today.md` |
| 10-07 | Diary: the now-and-longest streak card (2) | `09-diary.md` |
| 10-08 | Simran: design 29's threads back; a web of threads without a profile | `07-simran.md` S-11 |
| 10-08 | First run: Android's splash only; Welcome option D, "a day with Hazri"; the app is named Hazri everywhere | `03-first-run.md` |
| 10-08 | Badges, no points; ten names with Vichari and Satsangi; totals never runs; thresholds 1, 7, 40, 40, 108, all banis, 3, 180, 5, 365; recalculated, stored only when earned; in the backup; history counts | `12-badges.md` |
| 10-08 | Nitnemi counts the five morning banis; a badge is announced by an in-app sheet; designs 1C, 2A, 3B, 4B, 5C | `12-badges.md` BD-1, BD-11, BD-12 |
| 10-08 | This PRD replaces v1.0; architecture, schema and storage live in `docs/ARCHITECTURE.md` | — |
