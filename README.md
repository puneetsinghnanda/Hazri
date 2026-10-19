# Hazri · ਹਾਜ਼ਰੀ · हाज़िरी

**From Amrit Vela to bedtime, mark your hazri to Waheguru.**

A free Nitnem app for Android, in Punjabi, Hindi and English. Read or listen
to all seven Nitnem banis, Ardas and Sukhmani Sahib; mark the day present
with one bani or five minutes of Naam Simran; set daily goals; keep a diary;
sit Simran with the sangat on a globe; and work toward a shared goal with a
family, Gurdwara or circle.

**Works offline. No login, no password. No ads on Gurbani, ever.**

---

## Where the project is

**Phase 1** (the offline Nitnem app) and **Phase 2** are built. Every Phase 2
feature was specified with the owner on 7 and 8 October 2026, the screens
that changed were redesigned and chosen, and all ten steps of the plan in
[`docs/PRD.md`](docs/PRD.md) §11 are on the branch `claude/pensive-hawking-k87ese`.
It is being tested on the owner's phone ahead of the Play Store.

| | |
|---|---|
| Platform | Android only (minSdk 24, target 36), Flutter |
| Backend | Firebase `hazri-dfcc1` on Blaze: Anonymous Auth, the `api` Cloud Function plus scheduled and triggered Functions, Firestore and Functions in `asia-south1`, FCM for the Sangat, Brevo for profile mail |
| Website | **[hazri.me](https://hazri.me)**, the home page, also at `hazri-dfcc1.web.app` |
| Admin | [hazri-admin-d4b72.web.app](https://hazri-admin-d4b72.web.app), for the one admin account |
| Test APK | [the latest build](https://github.com/puneetsinghnanda/Hazri/releases/download/apk-claude/pensive-hawking-k87ese/app-arm64-v8a-release.apk) (arm64), replaced on every hand-started run |
| Phase 3 | Seven items (PRD §2.3). Badges were specified early and are already built |

## What Phase 2 brought

| Feature | In short |
|---|---|
| **Hazri** | One completed bani, or a Naam Simran sitting of 5 minutes or more, marks the day — no goal, profile or network needed |
| **Goals** | Any bani any number of times a day, and Naam Simran by the minute, each for as long as you choose, each with its own reminder |
| **Today** | A navy Hazri app bar, the hazri banner, a week-strip streak, the goal widget and the one next thing to do |
| **Diary** | Two dots a day — hazri and goal — every paath listed, + and − for a week back, the streak now and at its longest |
| **Notifications** | Amrit Vela at 04:00, one per goal, Gurpurabs and Sikh events on the day, a gentle hazri nudge, and the Sangat's evening digest |
| **Profile** | Optional: name, email, city. No password, no sign-in screen; email verified by link; restore on a new phone by link |
| **Weekly backup** | With a profile, goals and the diary are backed up each Sunday and can be restored |
| **Simran and the globe** | A sitting of 5 minutes or the goal's length; the sangat on a globe by city — you, those here today, everybody else |
| **Sangat** | Three built-in groups anybody can join, and private groups by invite, each working toward one shared goal |
| **Badges** | Ten badges for days kept — never points, never a ranking (a Phase 3 item, built early) |
| **First run** | Android's splash, one Welcome screen, language, how you read — Gurbani in under 30 seconds |
| **Admin website** | One person runs the built-in groups and acts on reports |

## What else is in the app

- **All nine banis** in Gurmukhi, Devanagari and Roman, with pause marks,
  Larivaar, text size, resume and keep-screen-on; meanings where reviewed
  ones exist.
- **A recitation for every bani**, bundled in the app (about 81 MB),
  following the text line by line and word by word, with timings checked by
  ear; tap a line to jump; speed, ±10 s, sleep timer; plays on with the
  phone locked.
- **ਅੱਜ ਦਾ ਵਿਚਾਰ**: one line of Sri Guru Granth Sahib Ji a day, shareable as
  text or an image. Plus the **Gurpurab and Nanakshahi calendar** for
  Nanakshahi 558.
- **A group's own globe**: the goal ring wraps the group's members by city,
  every dot tied to the ring, and the last hour's paath arriving as light.
- Elder mode, Settings, About and the privacy screen.

## The documents

| Document | What it is |
|---|---|
| [`docs/PRD.md`](docs/PRD.md) | **Start here.** The product, every feature and its decided behaviour, privacy, and the implementation plan. Wins over everything else |
| [`docs/features/`](docs/features) | One file per feature: numbered rules, exact strings in three languages, scenarios, acceptance |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | How it is built and where data lives: the app's layers, every table on the phone, preferences, Firestore, the API, the Functions, deployment, cost |
| [`design/canvas.html`](design/canvas.html) | Every screen by feature, marked new, current or superseded ([published](https://claude.ai/artifact/Fz2WJs5tPF9nUWPgkgBkR8), private to the owner) |
| [`CLAUDE.md`](CLAUDE.md) | Working rules for every change, and what is known about the code as it is |
| [`audio/README.md`](audio/README.md) | Rebuilding the recitations and checking their timings |

## Repository

```
lib/                      the Flutter app (feature-first: data / domain / ui)
assets/                   content.db, the recitations, fonts, the globe outline
content/source/           the reviewed source files every line of Gurbani comes from,
                          and timings/, the locked alignments
tools/content_pipeline/   builds assets/content/content.db
tools/design/             generates the Phase 2 screens in design/html/
tools/audio_pipeline/     builds the recitations and their timings
design/                   tokens.json, every screen in light and dark, canvas.html
public/                   Firebase Hosting: the home page, /verify, /j/<code>, assetlinks.json
tools/site/               builds public/index.html (the home page)
functions/                the api Cloud Function and the scheduled / triggered ones
admin/                    the admin website
docs/                     PRD, architecture, feature specifications
audio/                    how to rebuild and check the recitations
```

## Building

```bash
flutter pub get
python3 tools/content_pipeline/build_content_db.py   # assets/content/content.db
flutter gen-l10n                                      # lib/core/l10n/gen
dart run build_runner build                           # drift *.g.dart
python3 tools/site/build.py                           # public/index.html, the home page
flutter analyze
flutter test
flutter build apk --release --split-per-abi --target-platform android-arm64
```

Every change ends with `flutter analyze` clean and `flutter test` passing.

**A test APK:** every push builds one, but only a run started by hand keeps
it, as the rolling pre-release `apk-<branch>` (Actions → Build → Run
workflow; see [`.github/workflows/README.md`](.github/workflows/README.md)).
The release APK is signed with one key from four GitHub secrets
([`docs/signing.md`](docs/signing.md)); without them a throwaway key is used,
and that build cannot install over a release one.

**The server is deployed by hand.** No workflow deploys Firestore rules,
Functions or Hosting; a change to any of them is done only once it is
deployed (ARCHITECTURE §9):

```bash
firebase deploy --only firestore         # rules and indexes
firebase deploy --only functions
firebase deploy --only hosting:public    # hazri.me: the home page, /verify, /j/, assetlinks.json
npm --prefix admin run build && firebase deploy --only hosting:admin   # the admin website
```

## Content

**No Gurbani, meaning or transliteration is ever typed, paraphrased,
translated or generated.** Everything comes from `content/source/` through
`tools/content_pipeline/build_content_db.py`, which records each source so the
About screen can credit it.

| Content | Source |
|---|---|
| Gurbani text, English and Punjabi meanings | Shabad OS Database (Shabadaarth, Bhai Manmohan Singh, Dr. Sant Singh Khalsa, Prof. Sahib Singh's Sri Guru Granth Darpan, and the Dasam Granth and Nitnem translations it carries) |
| Devanagari and Roman | gurmukhi-utils 3.2.2 (script conversion) |
| Hindi | Faridkot Wala Teeka — a commentary, shown collapsed and labelled as such, for the four banis in Sri Guru Granth Sahib Ji |
| Calendar | SGPC Nanakshahi calendar (jantri), Nanakshahi 558 — **559 must be added before March 2027** |
| Fonts | Mukta, Baloo Paaji 2, Playfair Display, Noto Serif Gurmukhi, Noto Serif Devanagari — SIL OFL |
| Globe | Natural Earth 1:110m (public domain) |

Meanings are uneven, and nothing fills the gaps: English for every bani,
Punjabi for all but most of Ardas, Hindi only where the Faridkot teeka
exists. The paathi is uncredited until a credit is agreed.

**Before public release:** scholar review of the Gurmukhi and Devanagari
text, confirmed licences for every source and written rights for the
recitations, and a native check of the Punjabi and Hindi UI strings
(PRD §13).
