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
6. **Keep platform-specific code behind interfaces** so a second platform
   would need new adapters, not rewrites (`HukamnamaSource`,
   `ReminderService`). **iOS is off the roadmap** (PRD §17.2, 2026-09-22);
   the discipline stays because it is also what makes these parts testable,
   and the 60-pending reminder cap inherited from iOS stays with it.
7. Every change ends with `flutter analyze` clean and `flutter test` passing.

## The roadmap

Phase 2 is what this build is. **Phase 3 is seven things and nothing else**
(PRD §3.4): report an issue / feedback, points and badges, Sehaj Path and
the marker, rate the app, a digital Gurdwara visit, switching analytics
collection on, and notifications. There is no phase after it, and the
fifteen-item Phase 3 that used to be written down -- the iPhone app, Live
Kirtan, widgets, Saakhis, kids' mode and the rest -- was removed on
2026-09-22 rather than deferred.

**The 23-screen Phase 3 design set is superseded — do not merge it.**
`claude/eloquent-edison-qsjll0` carries 46 files, `design/html/62-*` to
`84-*`, plus `tools/design/phase3_screens.py` that draws them. They were
drawn on 2026-09-22 for the *old* Phase 3, so most of them are screens for
features that no longer exist anywhere on the roadmap -- the recitation
check, pronunciation practice, the kids' letters, saakhis, cast, live
kirtan, widgets, the watch, the iPhone. Nothing on this branch references
them and nothing should. Anything reconciling the two branches takes the
Phase 2 fixes and leaves that set behind; a design set for the seven items
in §3.4 would be a new one.

Three of the seven are blocked on a decision, not on code: the badge names
(D11), which Sehaj Path is meant (D12), and whether a points system may score
Gurbani when §0 says it may not (D14, a blocker on 3.2). **D13 is closed:**
the backend is Blaze with Cloud Functions.

**Notifications are mostly already here, and two of them were broken.** Five
local reminder kinds ship -- `amritVela`, `evening`, `bedtime`, `simran`,
`gurpurab` -- so the daily reminder and the Gurpurab alert are built. The
per-goal reminder is **not**: `ReminderIds.goal()` and its channel exist, but
nothing ever writes a reminder row for a goal, so none is ever planned. See
the two bugs under "Known gaps" below before believing any claim that a
notification works.

Only two things anybody has asked for genuinely need a push: being added to a
sangat, and the group's daily digest. **Both are now buildable** -- the
project is on Blaze and a Cloud Function is the sender. Every notification
that must reach *everybody* still has to stay local, because somebody who
never joins the sangat has no account and no token.

## The feature specifications

`docs/features/` is the behaviour spec, one file per feature, written
2026-09-26 after a fortnight in which every defect turned out to be a
**specification** failure showing up as a code failure: three screens each
deciding "were the goals met" differently, hazri hidden behind the sangat
because nobody had written down that it is local, a Gurpurab reminder firing
nightly because nobody had written down what should make it fire.

**Read the file for a feature before changing it, and change the file in the
same commit when the behaviour changes.** Each one carries numbered rules that
a test can cite, and success *and* failure scenarios written as given/when/then
so they become tests with no translation step. A rule nobody can write a
scenario for is not a rule yet.

`docs/features/00-platform.md` holds what they share: **the backend is Blaze
with Cloud Functions and is live** (`hazri-dfcc1`, spend cap ₹2,000/month --
this supersedes every "Spark has no Cloud Functions" note below), the
Firestore collections, **the cost model, which is the data model** (reads are
what bills, so Today, Nitnem, Diary and the reader cost zero and the globe is
one document per city per day), the Functions contract (`maxInstances: 10`,
`minInstances: 0`, never write to your own trigger, idempotent always), and
the testing rules that came out of how this went wrong -- above all: **test at
the seam the bug lives at**, and **a guard nobody has seen fail is not a
guard**.

Two cost facts worth knowing before touching the backend: **Firestore cannot
be spend-capped** -- it is not a cappable service, and it is the largest cost
driver -- and **costs record up to 24 hours late**, so the cap lags reality by
a day. `maxInstances` is the real protection; the cap is the last line.

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
public/                   Firebase Hosting: /verify and /j/<groupId>
```

## Regenerating

```bash
python3 tools/content_pipeline/build_content_db.py   # assets/content/content.db
python3 tools/geo/build_world_outline.py             # assets/geo/world.bin
flutter gen-l10n                                      # lib/core/l10n/gen
dart run build_runner build                           # drift *.g.dart
```

**Neither is the website.** `public/` is Firebase Hosting — `/verify`, where
an email verification link lands, and `/j/<groupId>`, where an invite does.
It goes live with `firebase deploy --only hosting` and **no workflow runs
that**, so a change to those pages changes nothing until somebody deploys by
hand. **First deployed 2026-09-27**, before which the site had never been
deployed at all and answered Firebase's *Site Not Found* — which is where
every verification link the app had ever sent had been landing. Both URLs come from `kSiteBase` in `lib/core/backend/backend.dart`; a
test holds that they share a host, because they were once on two and one of
them served nothing.

**`hazri.me` is registered and connected to nothing** (2026-09-26). It is a
Phase 3 asset: it is added *alongside* `hazri-dfcc1.web.app`, never instead,
because a verification link already sitting in an inbox has to keep working.
`docs/domain-setup.md` is the record set and the order to add it in; the DNS
is worth doing early (certificates and mail propagation each take up to a
day) and the app change is not. `docs/features/01-accounts.md` §1.7 lists the
seven steps, of which the app is the last one.

It has to be Firebase Hosting rather than anywhere cheaper: since Dynamic
Links shut down on 2025-08-25, Firebase Auth mints its email links on a
Firebase Hosting domain and nothing else. Hosting bandwidth is also not the
meter that bills — that is Firestore reads — so a static page costs nothing
that matters.

**`firestore.rules` is not deployed by any of these.** It is published by
hand, in the Firebase console under Firestore Database -> Rules, or with the
Firebase CLI. Changing the file in git changes nothing in the project, and
the failure mode is quiet: Firestore answers every write and refuses it,
which the app reports as though it were offline. Any change to that file is
only half done until it is published.

**The committed file is the live one as of 2026-09-26**, republished onto the
new `asia-south1` database. If you change it, say in the PR description that
it still has to be published, and do not treat a sangat bug as a code bug
until you have checked the console against git.

**The Firestore database was recreated in `asia-south1` (Mumbai) on
2026-09-26**, having been in `asia-south2` (Delhi). `asia-south2` has
Eventarc, Cloud Run and Cloud Functions but **not the Firestore event
provider**, so no Firestore-triggered Function could exist there at all --
and a trigger has to sit in the same location as the database. It held only
test data, so it was deleted and remade rather than designed around.
`docs/features/00-platform.md` has the detail, including that the `(default)`
id is not reusable for about five minutes after a delete. Nothing in the app
changed: `google-services.json` does not encode the region and the SDK finds
it.

## Builds

`.github/workflows/build.yml` analyzes, tests and builds the release APK on
every push, **but only a run started by hand keeps it** (Actions -> Build ->
Run workflow). A push still compiles the Android app, which is what catches a
Gradle or manifest break no widget test can see; it simply does not keep the
95 MiB.

**The kept copy is a pre-release, not an artifact** -- one rolling tag per
branch, `apk-<branch>`, replaced on the next hand-started run. That is not a
preference. The artifact store on this plan is 500 MB, the usage figure is
**account-wide rather than per repository**, and GitHub recalculates it only
every 6-12 hours -- so a run can build and check a perfectly good APK and
still be refused at the last step with *Artifact storage quota has been hit*,
which reads like a broken build and is not one. It did that three times,
including once when this repository held a single 94 MiB artifact, which is
how we learnt the figure is not local. **Release assets do not count against
that quota.** The artifact upload is still there as a convenience and is
marked `continue-on-error`, so it can no longer fail a run.
`.github/workflows/README.md` is the reader-facing version.

**A failed build must not destroy the release.** The publish step used to
`gh release delete --cleanup-tag` and then create -- so a build that produced
no APK deleted the working one somebody was still installing from, and failed
on the way to replacing it. It now checks the APK exists before touching
anything, and uses `gh release upload --clobber` on a release it creates or
edits rather than deletes, so there is never a window with no APK.

**Every CI build is signed with a different key, and nothing in the
repository fixes that.** `build.gradle.kts` signs the release build with
`signingConfigs.getByName("debug")`, and the workflow does nothing about a
keystore — so on each fresh GitHub runner the Android Gradle Plugin finds no
`~/.android/debug.keystore`, generates one with a fresh key pair, and throws
it away when the runner is destroyed. Three consequences, found 2026-09-27:

* **There is no "the" debug SHA-256 to register with Firebase.** Registering
  one is meaningless because the next build has another. Android App Links
  and `assetlinks.json` are therefore not merely waiting on a release
  keystore — they cannot work at all until *some* stable key signs the APK.
* **A new APK will not install over an old one.** Android refuses a package
  whose signature changed, so every build needs an uninstall first — and an
  uninstall takes `user.db` with it: the diary, the goals, every tick, and
  the anonymous account that cannot be recovered without a verified email.
  Anybody testing across builds has been starting again each time without
  necessarily realising why.
* **Phase 3's keystore decision (A-3) is really a Phase 2 one.** The fix is
  one keystore, kept out of git, held as a GitHub secret and used by the
  workflow.

**A double hyphen inside an XML comment makes AndroidManifest.xml
unparseable**, and the only thing that notices is
`:app:processReleaseMainManifest`, three minutes into a Gradle run, saying
"Error parsing AndroidManifest.xml" with no line number.
`test/android/manifest_test.dart` catches it in a second. That test was
verified by breaking the file on purpose and watching it fail -- a guard
nobody has seen fail is not a guard.

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
- **The Email/Password provider is enabled, and rule 4 now rests on the code
  alone.** Firebase's email link is a *mode* of that provider, not a provider
  of its own — the console's two switches move together — so
  `sendSignInLinkToEmail` cannot work without it. Until 2026-09-27 the
  project had **only Anonymous**, so every verification mail had been failing
  with `operation-not-allowed` since the day the code was written, and the
  app reported it as no signal. Enabling it was the fix and there was no
  alternative. What it costs: *no password, ever* used to be true twice, and
  is now true once. No account has a password, there is no sign-in screen,
  and nothing in `lib/` calls a password API —
  `test/features/no_password_test.dart` fails if one appears, and has been
  watched failing. `docs/features/01-accounts.md` A15 has the detail.
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
- **Reminders are seeded by the scheduler, not by a screen.** Until
  2026-09-23 the five default rows were written as a side effect of *watching*
  `remindersProvider`, and `ReminderScheduler.reschedule()` reads the table
  directly -- so on any phone where no screen listing reminders had been
  opened, including every phone that upgraded with onboarding already done,
  the read came back empty and **nothing was ever scheduled, silently**. The
  seeding now happens inside `reschedule()`. Do not move it back out: the
  planner had good unit tests throughout and they could not see this, because
  what was wrong sat either side of the pure function.
- **`ScheduledNotificationReceiver` must be declared in the manifest, and was
  not.** That is why no reminder ever arrived, and it had nothing to do with
  the Dart. `flutter_local_notifications` declares **no receivers** in its own
  manifest -- permissions and nothing else -- so the app must declare both of
  them; the plugin's README says it is "so that the plugin can actually show
  the scheduled notification(s)". Hazri declared the boot receiver and not
  this one, so every alarm fired into a component that did not exist.
  `zonedSchedule` threw nothing, the notifications sat in
  `pendingNotificationRequests()` looking perfectly healthy, and **four rounds
  of fixes to the scheduling code went out before anybody read the XML**.
  `test/android/manifest_test.dart` holds both receivers now. No widget test
  can see this: the fake service never touches the platform and `flutter test`
  never merges a manifest, so the file is the only place to check.
- **Nothing asked for POST_NOTIFICATIONS except setup step 3**, which is why
  a phone that upgraded with onboarding already done never received a single
  notification. Android 13+ denies it until granted; `reschedule()` read
  `areNotificationsEnabled()`, got false, cancelled everything and returned
  silently, at every app start, for ever. It now **asks** first -- the plugin
  shows the dialog only while Android has no recorded answer -- and the
  notifications screen carries a card saying reminders cannot arrive, with a
  button that asks and then falls through to the app's notification settings.
  `notificationsAllowedProvider` was dead code written for exactly this and
  wired to nothing; it is used now. This was real but it was **not** the reason
  the reader saw nothing -- their permission had been granted all along. See
  the receiver above.
- **The Gurpurab reminder is conditional on the calendar**, and used to fire
  every single night at 20:00 saying "Tomorrow is a Gurpurab" with the body
  "Gurpurab calendar" -- on the six nights in seven when it was not, and with
  no event named. `ReminderPlanner.plan` now takes `gurpurabDates` and emits
  an occurrence only on the eve of a day the calendar flags (`default_remind`,
  or the reader's own per-event override), and the body is that event's name.
  An empty set means silence, which is the right answer when the calendar has
  run out of year rather than a nightly guess.
- **A listed group cannot be listed from the app.** `listed` is refused by the
  rules on create and pinned on update, so a group made on a phone is always
  private. Asking to be listed writes `listingRequested`, and approving one is
  a console edit -- `docs/group-listing.md` is the procedure. There is no
  admin screen and no notification either way yet. On Blaze this becomes an
  `approveListing` callable rather than a console edit.
- **The sangat's numbers are counted on read, and are moving to being
  maintained.** `count()` and `sum()` aggregation queries give the member
  count, the group total and the globe's headline today. **Do not let a client
  write a counter field** -- every member can write the group document, so a
  client-written total is a total any member could forge. Now that the project
  is on Blaze the honest version is a Cloud Function maintaining it, which is
  what `docs/features/00-platform.md` specifies.
- **Group and global notifications are not built yet**, though they are no
  longer impossible: the project is on Blaze and a Cloud Function can send
  them. Screen 50 still shows them switched off and unavailable, and must keep
  saying so until the Functions are actually deployed.
- **The Vichar library is empty until entries are published.** Nothing in it
  is written in Dart -- see `docs/vichar-content.md` for the document shape.
  This is rule 3 applied past Gurbani to everything the app says about Sikhi.
- **Analytics ships with collection off** and sends nothing (PRD §13.1). The
  Settings switch is present and inert, and says so. Do not wire it up
  without also rewriting the privacy screen; the two are one promise.
- **Around a hundred and fifty Punjabi and Hindi UI strings added in Phase 2
  are mine** and want a native ear before release.
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
- **One rule decides whether a day's goals were met**, and it is
  `GoalCalculator.outcomeOn` / `appliesOn` in
  `lib/features/goals/domain/goal_progress.dart`. Today's card, the diary's
  month grid and the diary's day screen all call it. They used to answer the
  same question three ways: the grid counted a goal met on **one** tick,
  ignoring `timesPerDay`, so a goal of three paath lit its green dot after the
  first while Today still said nought of one; and it judged every goal that
  had ever started against every later day, so a goal that ended a fortnight
  ago darkened every day since and could never light again. Do not re-derive
  this anywhere.
- **A goal covers a window of days, and outside it the goal is absent rather
  than unmet.** The window runs from `startDate` to the earliest of: its
  length in days, its `untilDate`, and `endedOn`. That distinction is what
  the diary's dots are built on -- **one dot on a day with no goals, two on a
  day that had them** -- because a grey second dot on a day nobody set a goal
  says somebody failed, and they did not.
- **Stopping a goal archives it; it does not delete it.** `archiveGoal` sets
  `endedOn` and `active: false` and keeps every tick, so a goal kept from the
  1st to the 22nd leaves those twenty-two days exactly as they were.
  `deleteGoal` used to remove the row and its ticks and rewrite the month;
  it is now `forgetGoal`, for a goal set by mistake, and nothing in the UI
  calls it except the explicit Delete. Starting a stopped goal again inserts
  a **new row from today** rather than reopening the old one, because one row
  carries one stretch of days and reopening it would pull the whole gap back
  into scope.
- **The hazri banner is shown to everybody.** It used to return an empty box
  unless `hasJoinedSangat`, so the one thing the app is named after was
  invisible to the majority who never join -- against rule 4, which says the
  sangat is opt-in. The cost is that Today can carry the join banner and the
  hazri banner at once until the join banner is dismissed; the "Not now"
  memory that fixes that proprly lives on `claude/eloquent-edison-qsjll0`.
- **A goal's `reminderTime` is scheduled**, as a reminder row built in memory
  by `_goalReminders` rather than stored. It was displayed in three places and
  scheduled in none, so a goal set for 6:40 PM said 6:40 PM everywhere and
  never notified. Derived rather than stored so that adding, retiming or
  stopping a goal needs nothing kept in step.
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
- **The Nanakshahi calendar covers the whole of Nanakshahi 558**, 14 Mar 2026
  to 13 Mar 2027, built from `content/source/calendar-558.json` and
  `gurpurab-558.json`. 147 events across 12 kinds, 52 of them flagged
  `default_remind`. Dates outside the year report that rather than guessing,
  and 559 has to be added before March 2027. (This file and the README both
  used to say "17 Aug - 15 Dec 2026", which was an early sample and has been
  wrong for a while.)
- **Ten of the 147 event names have Punjabi and none has Hindi.** The names
  live in `content.db`, not in the ARB files, so `l10n_test` cannot see the
  gap and does not fail on it. Anything that shows an event name to a reader
  -- PRD §3.7's Sikhi-event notification above all -- needs those names
  first, or it says an English sentence to somebody who chose Punjabi.
