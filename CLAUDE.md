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
python3 tools/geo/build_world_outline.py             # assets/geo/world.bin
flutter gen-l10n                                      # lib/core/l10n/gen
dart run build_runner build                           # drift *.g.dart
```

**`firestore.rules` is not deployed by any of these.** It is published by
hand, in the Firebase console under Firestore Database -> Rules, or with the
Firebase CLI. Changing the file in git changes nothing in the project, and
the failure mode is quiet: Firestore answers every write and refuses it,
which the app reports as though it were offline. Any change to that file is
only half done until it is published.

**The committed file is the live one as of 2026-09-22** -- the `get`/`list`
split that lets a newcomer read the group their invite code names. If you
change it, say in the PR description that it still has to be published, and
do not treat a sangat bug as a code bug until you have checked the console
against git.

## Builds

`.github/workflows/build.yml` analyzes, tests and builds the release APK on
every push, **but only a run started by hand keeps it** (Actions -> Build ->
Run workflow). A push still compiles the Android app, which is what catches a
Gradle or manifest break no widget test can see; it simply does not store the
95 MiB. A hand-started run publishes the APK to a **pre-release tagged
`apk-<branch>`**, replaced on the next run of that branch, because releases
are not counted against the artifact quota below; it also attaches the same
file to the run as an artifact, kept three days, when the quota allows.

That is a storage limit, not a preference. The allowance on this plan is
500 MB and one APK is about 95 MiB, so five fill it -- and then every run
fails at the last step with *Artifact storage quota has been hit*, which
looks exactly like a broken build and is not one. GitHub also recalculates
the usage figure only **every 6-12 hours**, so deleting artifacts does not
free space immediately. `.github/workflows/README.md` is the reader-facing
version.

`[skip ci]` skips a run, and GitHub matches it **anywhere in the commit
message**, body included -- which has already cost one build that was meant
to happen. Put it in the subject when you mean it and nowhere at all when
you do not.

## The globe

`assets/geo/world.bin` is the coastlines and land borders design 29 draws,
built from `tools/geo/countries-110m.json` (npm `world-atlas@2.0.2`, whose
data is Natural Earth 1:110m — public domain). Both files are in git, so a
fresh clone rebuilds the asset with no network.

It is stored as TopoJSON **arcs**, not country polygons: an arc shared by two
countries appears once, so a frontier is one stroke rather than two laid on
top of each other, and nothing is filled over the sea. The painter holds each
point's sin and cos rather than its degrees and finishes the projection with
the angle-addition identity, so a frame of the spin costs no trigonometry at
all.

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
  and must never be reported as though it were. The file in git went live on
  2026-09-22, so the gap is the next change to it, not this one.
- **A verification or restore link is pasted, not tapped.** Android App Links
  need an `assetlinks.json` carrying the release signing fingerprint, and
  there is no keystore yet (Phase 3). Pasting the link needs nothing, so both
  flows work today; the intent filter is the Phase 3 change, and the screens
  do not otherwise move.
- **An invite is a pasted link or the code off the end of it**, for the same
  reason. The group id *is* the invite, so `get` on a group document is open
  to anybody signed in who knows the id, and `list` is not -- that split is
  what lets a newcomer join, and it went live on 2026-09-22. Under the older
  rule, which gated `read` on `isMember`, `join` could not read the group it
  was about to join and every code was refused with "something went wrong at
  our end". If that message comes back, check the console before the Dart.
- **A listed group cannot be listed from the app.** `listed` is refused by the
  rules on create and pinned on update, so a group made on a phone is always
  private. Asking to be listed writes `listingRequested`, and approving one is
  a console edit -- `docs/group-listing.md` is the procedure. There is no
  admin screen and no notification either way yet.
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
- **Around a hundred and fifty Punjabi and Hindi UI strings added in Phase 2
  are mine** and want a native ear before release.
- **There is no branded splash.** The reader asked for it to go (2026-09-22);
  the router opens on Today and redirects a first launch to the intro. The
  Android 12 system splash -- the app mark on the launch colour, drawn by the
  platform before Flutter has a frame -- is all that shows, and cannot be
  removed. Design 01 stays in `design/screens/` as the record.
- **The diary's day is the hazri and the goals, nothing else.** It used to
  list every nitnem bani with a tick, which made it a checklist of seven
  paaths nobody had set. Now the first row is the hazri -- lit by any paath
  or sitting, and tickable by hand for a paath read away from the phone,
  which is stored as a completion with `kHazriMarkId` and no bani behind it
  -- and the rows under it are the goals that were running that day. A goal
  ticked there records the paath (which marks the hazri) and ticks that one
  goal; unticking takes both back. The day's stats are goals met and days in
  a row.
- **The tab header keeps no gutter of its own.** Every tab lays it out inside
  a ListView that already has one, and it used to add the gutter again, so
  the menu button sat 40 dp in while the cards sat at 20. Design 30 is 20.
- **A simran sitting rings a notification when its time is up**, scheduled
  at Begin and cancelled at Pause and End (PRD 1.13's fallback). With the
  recitation playing the media session keeps the process alive and the
  ticker ends the sitting itself; with the phone locked and no voice, the
  bell is the only thing that says the time is up. `replaceSchedule` drops it
  with everything else, so a re-plan mid-sitting loses the bell -- accepted.
- **The simran recitation loops** for a sitting longer than its five
  minutes (`PaathTrack.loop`), which is what the goal sheet had promised and
  the player had not done. The drifting ਵਾਹਿਗੁਰੂ follows the player's own
  playhead while the simran track is loaded, not the sitting's clock, which
  ran fifteen or twenty seconds ahead of the voice on a real phone.
- **The presence line says "could not reach the sangat" on a failed read**
  (`SangatPresence.unreachable`) rather than "you are the first here
  today"; the poll runs only while the Simran tab is the one in front and
  the app is resumed. Others' dots are design 29's green, the one the
  legend names.
- **PRD 1.13's tap-to-count, sound picker and Today tile are gone**, with
  the 2026-09-20 mock-up. `simran_session.count` is always 0. Someone with
  no Naam Simran goal has no Simran entry on Today at all; the tab is the
  way in.
- **Simran's length has no Settings row.** `simranMinutes` is read but
  nothing writes it; a Naam Simran goal is how a sitting gets a length other
  than five minutes. Either add the row or delete the setting.
- **A sitting does not survive the process dying.** The session is in
  memory; with no recitation there is no foreground service, and a frozen
  process loses the elapsed time. Persisting `runningSince` is the fix.
- **After "Not now" on the join sheet, Today shows the hazri card** in the
  join banner's place (`sangatDeclined`). The account card in the menu and
  the Sangat tab remain the ways into the sangat. Before this, somebody who
  declined never saw the thing the app is named after.
- **Restore (designs 53, 54) is reached from a line on the join screen**,
  "Already joined? Bring my account back". Joining never looks the address
  up, so the other route to it -- an address that already has an account --
  could not happen from a join.
- **There is no brand bar.** Every tab draws its own header -- the menu
  button, the tab's name, a line under it -- because the designs put the
  screen's name there and the app's name above every screen made Today look
  like it was still starting up. Settings is pushed from that menu and is no
  longer a tab.
- **The Simran tab follows the reader's mock-up of 2026-09-20**, which
  supersedes design 29 for that screen: the globe, the legend and the two
  colours are design 29's, and the serif wordmark, the ੴ rule and the verse
  are the mock-up's. **That mock-up is not in the repository** -- it was a
  screenshot in the session it was built in, so this paragraph and the
  screen itself are the only record of it. Its headline, "One Name. / A
  Brighter World.", was taken out afterwards to give the globe the room;
  `simranHeadline*` is still in the ARB files, unused, and a test holds that
  it stays off the screen. One screen whether or not a sitting is running --
  the countdown takes the presence line's place while one is. Two things design
  29 has are still not shown: its month total and country count, because
  neither is stored anywhere and a number nobody counted is worse than no
  number; and its third legend colour, "in the sangat", because a member's
  city is on their own private user document and the membership rows carry a
  name, not a place.
- **The globe re-reads presence every 45 seconds while its tab is open**,
  and after a sitting is marked, and on resume. It used to read once, when
  the provider was first touched, and never again -- so two people sitting
  together never saw each other. Your own dot always showed because it is
  drawn from Settings on the phone, not from the server, which made the bug
  look like a drawing problem rather than a fetching one.
- **A simran sitting credits its goal from inside the repository**, in
  `logSimran` and `removeSimranOn`, not at the three call sites that reach
  them -- the timer finishing, a tick in the Diary, a sync restore. Each of
  those used to have to remember, and none of them did, so a day was marked
  as hazri while the goal beside it stayed undone. A bani still credits at
  its call sites; if a fourth simran path appears, it inherits this one.
- **Two people in the same city are one dot**, sized by the count and lit as
  yours. The globe knows cities, not people, so there is no second dot to
  draw; the headline counts them.
- **ਵਾਹਿਗੁਰੂ drifts off the globe while a sitting runs**, one word for each
  utterance, taken from `SimranTrack.onsets` — the times the recitation was
  measured at when the app was built. With no recitation there are no words:
  a rhythm of its own would be the screen saying something it does not know.
- **Design 29's "turn the globe with your hand" is gone** with the header it
  sat in; the mock-up puts the kicker there instead. The gesture is still
  there and now works in both directions, but nothing on screen says so.
- **Playfair Display is bundled for the Simran screen only.** It is the one
  screen set in a serif. The subset is Latin, so Gurmukhi and Devanagari fall
  through to the Noto serifs -- which means a Punjabi or Hindi headline is
  set in a different face from an English one, by design rather than by
  accident.

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
