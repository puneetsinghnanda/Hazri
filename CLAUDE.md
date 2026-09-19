# Hazri — working rules

These are the implementation rules from the PRD (`docs/PRD.md` §0). They apply
to every session in this repository.

1. **The design files are the visual spec, not code to port.**
   `design/html/NN-*.{light,dark}.html` are 390 x 844 CSS px = 390 x 844 dp.
   Match layout, spacing, radii, colours and type; build with Flutter widgets.
   `design/tokens.json` is the source of truth for colour, type and shape, and
   is mirrored in `lib/core/theme/`.
2. **Behaviour comes from the PRD.** Where a design and the PRD disagree, the
   PRD wins; note the conflict in the PR description.
3. **Never create, paraphrase, auto-translate or AI-generate Gurbani text,
   Gurbani audio, meanings, or images of the Gurus.** Every line of Gurbani and
   every meaning in the app comes from `content/source/` through
   `tools/content_pipeline/build_content_db.py`. Nothing Gurbani-related is
   typed into Dart.
4. **No ad SDKs, no third-party tracking or attribution SDKs, no login,
   ever.** Phase 1 goes further: it makes no network requests at all and
   `INTERNET` is removed from the merged manifest. **Phase 2 restores
   `INTERNET`** and adds Firebase. What it may then send is a closed list:
   an anonymous account, the sangat (groups, shared goals, the globe) and
   diary sync. **Firebase Analytics ships in Phase 2 with collection off and
   sends nothing** (`setAnalyticsCollectionEnabled(false)` at start-up);
   Crashlytics is not added at all until Phase 3, which is where collection is
   switched on and the opt-out becomes live. PRD §13.1 is the per-phase table
   and the privacy screen is its reader-facing copy — neither is allowed to
   run ahead of the other. Across every phase: no PII, no free text, no
   advertising ID (`AD_ID` stays out of the merged manifest) and ad
   personalisation off.
   Three things stay true across both phases and are not negotiable: **no
   password and no sign-in screen**; **no request is needed to read a bani,
   hear it, see the calendar or write the diary** — all of that is on the
   phone and works with the radio off; and **the sangat is opt-in**, so
   somebody who never joins it is reading, listening and keeping a diary
   entirely on their own phone.
5. **All UI strings are localised** in `pa`, `hi` and `en` from day one. No
   hard-coded user-facing strings; `test/core/l10n_test.dart` fails on a
   missing or untranslated key.
6. **Keep platform-specific code behind interfaces** so the iOS app in Phase 3
   needs new adapters, not rewrites (`HukamnamaSource`, `ReminderService`).
7. Every change ends with `flutter analyze` clean and `flutter test` passing.

## Layout

```
lib/
  app/          MaterialApp.router, routes, bottom-nav shell
  core/
    theme/      tokens -> HazriColors (ThemeExtension), type, icons
    l10n/       ARB files (pa, hi, en) + generated
    db/         drift: content.db (read-only, bundled) and user.db
    settings/   AppSettings + SettingsController (shared_preferences)
    time/       Clock, NOAA SolarService, Nanakshahi calendar, formatting
    widgets/    AppMark, DayArc, ProgressRing, cards, chips, buttons
  features/     onboarding today nitnem reader diary reminders hukamnama
                simran gurpurab goals settings about
                each: data/ (repos, controllers) domain/ (models, logic) ui/
tools/content_pipeline/   builds assets/content/content.db
content/source/           the reviewed source files the pipeline reads
design/                   tokens.json, screens.json, HTML specs, PNG renders
```

## Regenerating

```bash
python3 tools/content_pipeline/build_content_db.py   # assets/content/content.db
flutter gen-l10n                                      # lib/core/l10n/gen
dart run build_runner build                           # drift *.g.dart
```

**`firestore.rules` is not deployed by any of these.** It is published by
hand, in the Firebase console under Firestore Database -> Rules, or with the
Firebase CLI. Changing the file in git changes nothing in the project, and
the failure mode is quiet: Firestore answers every write and refuses it,
which the app reports as though it were offline. Any change to that file is
only half done until it is published.

## Audio

Masters are **not** in git; they live on the `audio-masters` GitHub release.
See `audio/README.md` for how to fetch one, rebuild the shipping AAC, generate
timings and verify the alignment acoustically.

The paathi is deliberately uncredited: there is no name placeholder anywhere in
the app. Add the credit to `voice` in the content pipeline when one is agreed.

## Known gaps in this build

### Phase 2

- **`firestore.rules` must be published by hand and is not, automatically.**
  See "Regenerating" above. Every group write and the globe depend on the
  current file being live in the console; until it is, writes are refused and
  the app says so (`SangatRefused`), which is not the same as being offline
  and must never be reported as though it were.
- **A verification or restore link is pasted, not tapped.** Android App Links
  need an `assetlinks.json` carrying the release signing fingerprint, and
  there is no keystore yet (Phase 3). Pasting the link needs nothing, so both
  flows work today; the intent filter is the Phase 3 change, and the screens
  do not otherwise move.
- **An invite is a pasted link or the code off the end of it**, for the same
  reason.
- **A listed group cannot be listed from the app.** `listed` is refused by the
  rules on create and pinned on update, so a group made on a phone is always
  private. Listing happens out of band after somebody reads the name, which
  is the whole answer to "what stops a hurtful name appearing to strangers".
  There is no admin tool for that yet: it is an edit in the console.
- **The sangat's numbers are counted, never stored.** `count()` and `sum()`
  aggregation queries give the member count, the group total and the globe's
  headline. Do not add a counter field to a group document: every member can
  write that document, so every member could lie about it, and Spark has no
  Cloud Function to keep an honest one.
- **Group and global notifications cannot be sent.** They need a push from a
  server and Phase 2 has none. Screen 50 shows them switched off and
  unavailable rather than pretending.
- **The Vichar library is empty until entries are published.** Nothing in it
  is written in Dart -- see `docs/vichar-content.md` for the document shape.
  This is rule 3 applied past Gurbani to everything the app says about Sikhi.
- **Analytics ships with collection off** and sends nothing (PRD §13.1). The
  Settings switch is present and inert, and says so. Do not wire it up
  without also rewriting the privacy screen; the two are one promise.
- **Sixty-odd Punjabi and Hindi UI strings added in Phase 2 are mine** and
  want a native ear before release.

### Content and audio


- **All nine banis now have text and a recitation.** Japji came from a
  schema-1.0 source file; the other eight are schema 2.0 and are loaded by
  `build_bani_v2()`. Daily Simran has its own recitation, which is not a bani
  and lives in `simran_track` rather than `audio_track`.
- **Meanings are not evenly covered.** Every bani has English and (bar Ardas)
  Punjabi; Hindi exists only for the four that are in Sri Guru Granth Sahib,
  because the Faridkot teeka covers that scripture alone. The reader shows
  what exists and nothing is machine-translated to fill a gap. Ardas has
  Punjabi for 9 of its 27 lines.
- **Schema-2.0 banis carry no section labels.** Their source files derive
  `unit` mechanically from the Gurmukhi numerals in the closing dandas and say
  outright that those are not editorial labels, so the unit number is stored
  and no word is invented for it. Japji keeps its labels because its source
  file names its sections.
- **All nine alignments have been checked by ear and are locked. Do not
  re-align any of them.** `timings/verified.json` records who listened, keyed
  by a hash of the exact timings they heard, so re-aligning a bani drops it
  back to unverified rather than carrying somebody's word onto a file they
  never checked -- and that acceptance cannot be given again by anybody but
  the person who gave it. If a correction is genuinely needed, it is a `pin`
  plus `--repin`, which is a remap of the existing alignment, and the bani
  goes back to unverified until it is listened to again.
- **A recitation does not always say what the text carries**, and this is the
  failure mode to expect. `timings/audio-start.json` records, per bani, where
  a recording starts saying the text (`seconds`), which line ranges it
  actually covers (`lines`), any passage the reciter says more than once
  (`repeat`), any stretch filled with something the text does not have
  (`skipAudio`), any line held to a time somebody heard (`pin`), and the lines
  either side of it to leave alone (`hold`). A pin without holds either side
  spreads its correction over the whole recording -- that is what threw Tav
  Prasad Savaiye's opening out -- so bracket one unless the whole timeline is
  adrift.
  `repeat` must come from a person who listened: duplicating a line that is
  said once lets the warp split one utterance into two plausible-looking
  halves, which is how Jaap and Rehras both got a repeat they did not need.
  A pinned line stops being evidence, so keep the anchors file for lines that
  are not pinned. Chaupai, for instance, says the chaupais
  through ॥੪੦੧॥ and then the ਦੋਹਰਾ, and nothing between. Nothing is ever cut
  from a recording; the audio still plays, those seconds simply belong to no
  line.
- **Three checks, and they see different things.** The pause check cannot see
  a constant shift -- a boundary pushed onto the next pause still lands in a
  pause. Anchors (`<bani>.anchors.json`, times taken by ear that the aligner
  never sees) catch that, and are the only thing that can. `text_vs_audio.py`
  catches text the recitation never says, by comparing the reciter's phrasing
  rate against the lines assigned. Run all three; `audio/README.md` has the
  current numbers and what is still outstanding -- Rehras and Jaap each have
  a stretch near the end that is still unexplained, and Sukhmani has
  thirty-seven pins and one anchor left, so nothing independent still checks
  it: its timings are the owner's ear written down, not a measurement.
  `verify_timings.py` also lists lines the warp gave under 100 ms a word,
  which is a line squeezed to nothing rather than aligned. It does not vote on
  the verdict -- Jaap has twenty and is accepted, because its reciter barely
  stops between lines -- but it found both of Sukhmani's chapter breaks
  before anybody listened to them, and both turned out to be four and five
  seconds out. `build_preview.py` marks the same lines with a diamond so they
  can be listened to directly.

  A squeezed line is not as bad as it reads: `indexAt` holds the last line
  that started through a gap rather than dropping the highlight, so Sukhmani's
  ਸਲੋਕੁ shows for the 0.78s until the next line begins even though its own
  span is 30ms. The end time is still wrong and there is no honest way to
  invent a better one.

- **A full align writes `<slug>.raw.json` beside the timings**, which is the
  warp's own answer before any pin, and `--repin` starts from that. A pin is
  only a remap of a finished alignment, so a round of corrections costs 0.3
  seconds rather than the thirty-five minutes Sukhmani takes to warp; it is
  checked byte-for-byte against a full run. Keep the raw file in git or
  `--repin` has nothing to work from on a fresh clone.

- **`build_preview.py` is the fast way to check an alignment.** It bakes every
  bani's lines and timings into one HTML file that takes a recitation from
  your own disk through a file picker -- no APK, no CI, no upload -- and shows
  which line the timings put under the voice, with its exact start time.

- **The daily Hukamnama is gone**, replaced by ਅੱਜ ਦਾ ਵਿਚਾਰ (PRD 1.11): 200
  bundled lines from Sri Guru Granth Sahib Ji, one a day by date, shareable as
  text or as an image. It needs no network, which is what the Hukamnama did
  need. The dataset carries no Ang numbers and the app does not invent one.
- **The Nanakshahi calendar covers 17 Aug - 15 Dec 2026 only**, derived from
  the supplied SGPC sample. Dates outside it report that rather than guessing.
