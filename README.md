# Hazri · ਹਾਜ਼ਰੀ · हाज़िरी

**Your daily Nitnem — always with you.**

An offline-first Nitnem app in Punjabi, Hindi and English. Works offline. No
login. No ads on Gurbani, ever.

Built to the Phase 1 PRD in [`docs/PRD.md`](docs/PRD.md), against the design
system in [`design/`](design).

## What this build contains

| Area | State |
|---|---|
| Japji Sahib | Complete — 385 lines in Gurmukhi, Devanagari and Roman, with vishraam marks and meanings in all three languages |
| Other eight banis | Listed everywhere, with a "not in this build" reader state, waiting on reviewed text |
| Reader | Scripts, meanings, vishraam, Larivaar, text size, resume, keep-screen-on, end-of-bani card |
| Today | Day arc, CTA state machine, Hukamnama card, Simran and Gurpurab tiles |
| Nitnem list | Slot sections with overrides, resume points, goal summary |
| Diary | Month grid, gentle streak with grace days, manual ticks, month stats |
| Reminders | NOAA sunrise/sunset, Auto and fixed times, rolling 7-day window, exact-alarm and notification permissions, per-maker battery help |
| Daily Simran | 5-minute ring timer, optional tap counter, sound choice, diary logging |
| Paath goals | Create, tick, pause, delete, per-goal reminder |
| Gurpurab calendar | Nanakshahi date, this week and coming up, per-event bell |
| Settings, About, Privacy, Licences | Complete |
| Elder mode | App-wide, 3-tab navigation, larger everything |
| Audio | Japji Sahib: 19 min recitation, plays offline, keeps going when the phone is locked. Line and word highlighting follow the paathi; tap a line to jump there. Speed toggle, ±10 s, sleep timer |
| Hukamnama fetch | **No source configured** — see below |

### Deliberate gaps

- **Audio for the other eight banis.** Japji Sahib has its recitation; the rest
  show a "not in this build" state rather than a dead control.
- **Line timings are unverified.** They are derived from the recording rather
  than hand-checked (see `audio/README.md`), and the PRD requires a human pass
  before release (§18, D3). The word highlight in particular is an estimate.
- **Hukamnama.** `HukamnamaSource` has only an `Unconfigured` implementation, so
  this build makes **no network requests at all** — `INTERNET` is removed from
  the merged manifest. The screen, the 30-day cache and the share card are
  built and wired; adding a permitted provider is one class (PRD §18, D4).
- **Calendar coverage.** The Nanakshahi Sangrand dates are derived from the
  supplied SGPC sample and cover **17 Aug – 15 Dec 2026**. Outside that range
  the app says the calendar has not shipped that far rather than computing a
  date it cannot vouch for (PRD §18, D8).

## Getting a test APK

Every push builds one. See
[`.github/workflows/README.md`](.github/workflows/README.md).

## Building locally

```bash
flutter pub get
python3 tools/content_pipeline/build_content_db.py   # assets/content/content.db
flutter gen-l10n
dart run build_runner build
flutter analyze
flutter test
flutter build apk --release --split-per-abi --target-platform android-arm64
```

## Content provenance

No Gurbani, meaning or transliteration is typed into Dart. Everything comes
from `content/source/` through `tools/content_pipeline/build_content_db.py`,
which records each source in the database so About can credit it:

| Content | Source |
|---|---|
| Gurbani text, English and Punjabi meanings | Shabad OS Database |
| Devanagari and Roman transliteration | gurmukhi-utils 3.2.2 (script conversion, not human-reviewed) |
| English | Bhai Manmohan Singh (SBMS), with Dr. Sant Singh Khalsa (DSSK) stored as an alternative |
| Punjabi | Prof. Sahib Singh (PSST), with Bhai Manmohan Singh stored as an alternative |
| Hindi | Faridkot Wala Teeka (NKFT) — Braj/Sadhukkari **commentary**, converted to Devanagari, shown collapsed and labelled as such |
| Gurpurab dates | SGPC Nanakshahi calendar sample, 558 NS |
| Fonts | Mukta, Baloo Paaji 2, Noto Serif Gurmukhi, Noto Serif Devanagari — SIL OFL |

Scholar review of the Gurmukhi and Devanagari text is still required before any
public release (PRD §16).
