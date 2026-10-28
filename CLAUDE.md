# Hazri — working rules

These are the implementation rules from the PRD (`docs/PRD.md` §0.3). They
apply to every session in this repository.

**The documents** (2026-10-08):

| Document | Holds |
|---|---|
| `docs/PRD.md` (v2.0) | The product, every feature and its decided behaviour, privacy, and the implementation plan (§11). **Wins over everything below** |
| `docs/features/NN-*.md` | Per feature: numbered rules, exact strings, scenarios, acceptance |
| `docs/ARCHITECTURE.md` | **The one home for structure and data**: the app's layers, every `content.db` and `user.db` table, preferences and local flags, Firestore, the API, the Functions, deployment, cost |
| `design/canvas.html` | Every screen, marked new, current or superseded |

The decisions of 2026-10-07 and 2026-10-08 are final and override anything
written before them. PRD v1.0 (Phase 1) was replaced, not edited; it is in
git history and is not a reference.


1. **The design files are the visual spec, not code to port.**
   `design/html/NN-*.{light,dark}.html` are 390 x 844 CSS px = 390 x 844 dp.
   Match layout, spacing, radii, colours and type; build with Flutter widgets.
   `design/tokens.json` is the source of truth for colour, type and shape, and
   is mirrored in `lib/core/theme/`. **Only screens marked *new* or *current*
   on `design/canvas.html` are the spec**; a *superseded* one is history (see
   "The designs" below).
2. **Behaviour comes from the PRD and `docs/features/`; data from
   `docs/ARCHITECTURE.md`.** Where a design and the written behaviour
   disagree, the writing wins. **Where the PRD and a feature file disagree,
   the PRD wins** and both are fixed in the same commit; a change to a table,
   key, collection or endpoint is made in `ARCHITECTURE.md`. Note any
   conflict in the PR description.
3. **Never create, paraphrase, auto-translate or AI-generate Gurbani text,
   Gurbani audio, meanings, or images of the Gurus' faces.** A saakhi may
   show a Guru's figure, AI art included, with only light where the face
   would be (owner, 2026-10-21; `docs/features/13-saakhi.md` SK2). Every line of Gurbani and
   every meaning in the app comes from `content/source/` through
   `tools/content_pipeline/build_content_db.py`. Nothing Gurbani-related is
   typed into Dart.
4. **No ad SDKs, no third-party tracking or attribution SDKs, no login,
   ever.** Phase 1 goes further: it makes no network requests at all and
   `INTERNET` is removed from the merged manifest. **Phase 2 restores
   `INTERNET`** and adds Firebase. What it may then send is a closed list,
   each item named by a feature file (PRD §8): the anonymous sign-in; **a
   profile the person chooses to make** (name, email, city, phone if given)
   with its verification and restore mail; with a profile, the **daily
   attendance mark** and the **weekly backup**; for a Sangat member, their
   paath toward their groups and an FCM token; with a profile, a **Gurmat
   Quiz** started online (its topic and the five answers), and their first
   name, initial, city and quiz points on the leaderboards. Without a profile
   the quiz sends nothing and earns no points (`docs/features/14-quiz.md`,
   2026-10-27). No client touches Firestore:
   everything goes through the `api` Cloud Function. **Firebase Analytics ships in Phase 2 with collection off and
   sends nothing** (`setAnalyticsCollectionEnabled(false)` at start-up);
   Crashlytics is not added at all until Phase 3, which is where collection is
   switched on and the opt-out becomes live. PRD §8 is the per-phase table
   and the privacy screen is its reader-facing copy — neither is allowed to
   run ahead of the other, so the screen is rewritten in the same change that
   ships the profile, attendance and the backup. Across every phase, in
   analytics: no PII, no free text; and everywhere: no
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
   `ReminderService`). **iOS is off the roadmap** (PRD §2.4, 2026-09-22);
   the discipline stays because it is also what makes these parts testable,
   and the 60-pending reminder cap inherited from iOS stays with it.
7. Every change ends with `flutter analyze` clean and `flutter test` passing.

## The roadmap

Phase 2 is what this build is. **Phase 3 is seven things and nothing else**
(PRD §2.3): report an issue / feedback, badges, Sehaj Path and
the marker, rate the app, a digital Gurdwara visit, switching analytics
collection on, and notifications. There is no phase after it, and the
fifteen-item Phase 3 that used to be written down -- the iPhone app, Live
Kirtan, widgets, Saakhis, kids' mode and the rest -- was removed on
2026-09-22 rather than deferred. **Saakhis came back on 2026-10-19** as a
Phase 2 feature (`docs/features/13-saakhi.md`): the Guru's face is never
shown, only light where it would be (2026-10-21); the lesson page is design D for every saakhi; nothing
about a saakhi is counted, and there is no Diary link.

**The Gurmat Quiz was added on 2026-10-27** as a Phase 2 feature
(`docs/features/14-quiz.md`, PRD §4.21), after six rounds of design: the
owner's 340-question bank in `content.db`, five questions drawn by the server,
ten points a right answer **with a profile only** (without one the quiz plays
on the phone, sends nothing and earns nothing), and top-20 leaderboards for each quiz and for
everyone, by day, week and month in IST. It is **the first points and the one
ranking in the app**, for quiz answers only: PRD §1.3 was amended for it and
for nothing else, and no question quotes Gurbani. **Built 2026-10-27**
(content version 10, `lib/features/quiz/`, `functions/src/quiz/`) and
**live the same day**: the owner deployed the Functions and the two
`quizScores` indexes, created the three TTL policies, and earned the first
points. Its screens are designs 113-119.

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

One of the seven is still blocked on a decision, not on code: which Sehaj
Path is meant (D12). **D11 and D14 were decided on 2026-10-08**: 3.2 is
badges with no points at all, so PRD §1.3 stands, and Gyani and Pracharak are
replaced by Vichari and Satsangi (`docs/features/12-badges.md`). **D13 is
closed:** the backend is Blaze with Cloud Functions.

**Badges are fully specified and designed** (2026-10-08), ahead of the rest
of Phase 3: ten badges counted in days from the Diary's own rows, **Nitnemi
counts the five morning banis** (`default_slot` = `morning`), a new badge is
announced by an **in-app bottom sheet, never a notification**, and the
screens are designs 95–99 — the sheet (1C), the Badges page (2A), one badge
(3B), the profile's Badges section (4B, replacing 33) and the menu's navy
header with the earned set under the name and city (5C, replacing 37).

**Notifications are built to their specification**
(`docs/features/02-notifications.md`, 2026-10-07): Amrit Vela at 04:00, a
reminder per goal item at its own time, Gurpurabs at 06:00 and other Sikh
events at 07:00, a hazri nudge at 07:00 with no goal and no hazri, and three
pushes by Cloud Function -- the Sangat at 21:00, new members to a group's
creator, a group ending. Reminders are on by default and Android's permission
prompt comes at app start. Every notification that must reach *everybody*
stays local, because somebody with no profile and no group has no token.

## The feature specifications

`docs/features/` holds the rules of each feature, one file per feature, written
2026-09-26 after a fortnight in which every defect turned out to be a
**specification** failure showing up as a code failure: three screens each
deciding "were the goals met" differently, hazri hidden behind the sangat
because nobody had written down that it is local, a Gurpurab reminder firing
nightly because nobody had written down what should make it fire.

**All twelve files exist** (2026-10-08), written with the owner on
2026-10-07 and 2026-10-08, so the owner's condition -- *nothing is
implemented until every feature has its technical specification* -- is met.
`docs/PRD.md` §4 covers every one of them, and **PRD §11 is the
implementation plan** — the order (platform, notifications, goals and diary,
profile, backup, sangat and admin, simran, today and nitnem, badges, first
run), what each step adds, removes, migrates and deploys, and when it is
done. Each file's open questions have a default the build follows; PRD §14
lists them. **Schema and storage sections were moved out of the files into
`docs/ARCHITECTURE.md`** on 2026-10-08, word for word, keeping their
numbering, with a pointer left where each was.

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

## The designs

`design/canvas.html` is **every screen on one page, by feature**, each marked
*new*, *current*, *superseded* or *reference*, with the feature file it
follows and, for a superseded one, what replaced it. It opens on "Current
only". It is published as an artifact at
<https://claude.ai/artifact/Fz2WJs5tPF9nUWPgkgBkR8>; republish it after
changing it, with every new or changed `design/html/` file. PRD Appendix A
is the same list in text, generated from it.

The Phase 2 screens are **drawn by `tools/design/build_phase2.py`**, never by
hand: edit the generator, run it, then `python3 tools/design/check_structure.py`.
Numbers 62–84 belong to the superseded Phase 3 set and are not reused.

Chosen by the owner, 2026-10-07 and 2026-10-08, from three or four options
each:

| Feature | Designs | Choice |
|---|---|---|
| Today | 85, 86 | App bar D (navy, Today only) and streak option 3 (the week strip) |
| Diary | 87 | Streak option 2: now and longest |
| Simran | 88, 89, 90 | The screen as it ships, with design 29's threads; a web of threads without a profile |
| First run | 91, 92, 93, 94 | Android's splash only; Welcome option D, "a day with Hazri" |
| Badges | 95, 96, 97, 98, 99 | 1C sheet, 2A page, 3B one badge, 4B profile section, 5C menu header |
| Profile and Sangat (2026-10-10) | 100, 101, 102, 103 | Profile D (identity card and badge shelf, replaces 98), Edit profile C (Today in your city, then one card of fields), Sangat C (dashboard tiles, built-ins as rows), group H (ring in a navy band, timeline, Sit for the paath) |
| A group's globe (2026-10-17) | 104, 105 | Option C for custom and built-in groups: the goal ring wraps the group's globe, members as counts per city, every dot tied to the ring by a dashed line (GG4a, 2026-10-18), paath of the last hour arriving as light along it (`08-sangat.md` GG1-GG10); replaces 103 and, for a custom group, 31 |
| Goals as one page (2026-10-19) | 106 | Option C of four: the day as a timeline, every paath at its own time; once a day each, reminders always on and movable (`04-goals.md` GI10, RM1, 7.2); replaces 47 |
| Vichar articles (2026-10-19) | 107, 108, 109 | A calendar card for a Gurpurab, photo-led for a gurdwara, a timeline for a day of history (`docs/vichar-content.md` Layouts) |
| Saakhis (2026-10-25) | 111, 112 (110 superseded) | The library, and the menu as a left drawer, option A (replaces 99; Gurmat Quiz under Saakhis since 2026-10-27). Today's option 1A, a row of covers (110), was **replaced 2026-10-27 by option C**, one card with the day's saakhi large and the others small, drawn in 113; the reader is `design/saakhi/reader.template.html` (`13-saakhi.md`) |
| Gurmat Quiz (2026-10-27) | 113-119 | Today: the calendar leaf 1A with no buttons and the quiz card D (2026-10-28, from four options), above the Saakhis card (113, with the saakhis' option C), a question (114), result 4B (115), leaderboard 5A and 5B (116, 117), quiz page 6A (118), Your quiz 7A (119); the category drawings are read from `lib/features/quiz/ui/quiz_drawings.dart` (`14-quiz.md`) |

Screens drawn before their feature file (goals, sangat, account) are marked
current with a note that the file wins where they differ.

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
  features/     about audio backup badges diary goals gurpurab hazri library
                nitnem onboarding profile quiz reader reminders saakhi sangat
                settings simran today vichar
                each: data/ (repos, controllers) domain/ (models, logic) ui/
android/                  Reminders.kt (alarms and posting), MainActivity.kt
functions/                the `api` Cloud Function and the scheduled / triggered ones
admin/                    the admin website (Vite + TypeScript), hosting:admin
tools/content_pipeline/   builds assets/content/content.db
content/source/           the reviewed source files the pipeline reads
docs/                     PRD.md, ARCHITECTURE.md, features/ (one file per feature)
design/                   tokens.json, screens.json, HTML specs, PNG renders
                          canvas.html: every screen on one page, by feature
public/                   Firebase Hosting: the home page, /verify and /j/<groupId>
tools/site/               builds public/index.html (the home page)
tools/design/             draws the Phase 2 screens (build_phase2.py)
firestore.rules, firestore.indexes.json, firebase.json, .firebaserc
```

## Regenerating

```bash
python3 tools/content_pipeline/build_content_db.py   # assets/content/content.db
python3 tools/geo/build_world_outline.py             # assets/geo/world.bin
flutter gen-l10n                                      # lib/core/l10n/gen
dart run build_runner build                           # drift *.g.dart
```

**Neither is the website.** `public/` is Firebase Hosting — `/verify`, where
an email verification link lands, `/j/<groupId>`, where an invite does, and
since 2026-10-18 **the home page** at `/`: the sangat's globe, the phone tour,
the Gurpurab calendar and the guides, in English, and since 2026-10-19 **a story page for
every day of the calendar** at `/gurpurab/<slug>` (`docs/site-stories.md`: 102 pages from
`tools/site/articles/*.json`, photos from Wikimedia Commons still to be reviewed). It is **built, not edited**:
change `tools/site/template.html` or its data and run
`python3 tools/site/build.py`, which writes `public/index.html`; the phone
screens it shows are `public/img/*.webp`. It collects nothing -- the "notify
me" box was taken out before it went live, so the site sends no data
anywhere.
It goes live with `firebase deploy --only hosting` and **no workflow runs
that**, so a change to those pages changes nothing until somebody deploys by
hand. **First deployed 2026-09-27**, before which the site had never been
deployed at all and answered Firebase's *Site Not Found* — which is where
every verification link the app had ever sent had been landing. Both URLs come from `kSiteBase` in `lib/core/backend/backend.dart`; a
test holds that they share a host, because they were once on two and one of
them served nothing.

**`https://hazri.me` is live on Firebase Hosting** (Namecheap, connected 2026-10-19; `docs/domain-setup.md` has the zone as it stands). It serves the same `public/` as `hazri-dfcc1.web.app`; `www.hazri.me` redirects to it (CNAME to `hazri-dfcc1.web.app`, added 2026-10-19), and the app still points at `hazri-dfcc1.web.app`. It is a
Phase 3 asset: it is added *alongside* `hazri-dfcc1.web.app`, never instead,
because a verification link already sitting in an inbox has to keep working.
`docs/domain-setup.md` is the record set and the order to add it in; the DNS
is worth doing early (certificates and mail propagation each take up to a
day) and the app change is not. §1.7 of the earlier accounts spec
(`git show cc1c967:docs/features/01-accounts.md`) lists the seven steps, of which the app
is the last one.

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
every push **that touches the app** -- since 2026-10-19 a push that changes only
the website, docs, designs, admin or Functions does not build, to save the
account's Actions minutes; the `paths` lists in the workflow are what counts,
and a test that reads a new file outside them must add it there -- **but only a
run started by hand keeps it** (Actions -> Build ->
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

**The release APK is signed with one key, from four GitHub secrets**, and
falls back to a throwaway one when they are absent. Until 2026-09-27 there
was no fallback and no key: `build.gradle.kts` always used the debug config
and the workflow kept no keystore, so each fresh runner found no
`~/.android/debug.keystore`, the Android Gradle Plugin generated one with a
new key pair, and it died with the runner. Every build was signed
differently, which meant a new APK could not install over an old one
(Android refuses a package whose signature changed), so every build cost an
uninstall — and an uninstall takes `user.db` with it: the diary, the goals,
every tick, and an anonymous account with no recovery. It also made App
Links impossible, because `assetlinks.json` names one SHA-256 and there was
never one to name.

The secrets are `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`. `docs/signing.md` is how to
make the key and set them. The workflow decodes the keystore into
`RUNNER_TEMP`, never the checkout, writes `android/key.properties`, and
prints which certificate actually signed the APK — read out of the APK
rather than assumed, because that SHA-256 is the one `assetlinks.json` has
to carry and a mismatch fails App Link verification in silence.

**Without the secrets the build still works**, on a fork or a fresh clone,
signed with a throwaway key and a warning in the log. It will not install
over a release-signed build.

**The keystore is the one file in this project that cannot be replaced.**
Lose it and the app can never be updated under the same identity; leak it
and anybody can sign a package Android and `assetlinks.json` both accept as
Hazri. `android/.gitignore` refuses it, and `test/android/manifest_test.dart`
asks git what is actually tracked rather than trusting that — a `git add -f`
would get past the ignore file and the commit would not look like the one
that mattered. Watched failing.

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

## State of the build (2026-10-27)

**Phase 2 is built**: all ten steps of PRD §11, in that order, on this
branch, and since then Saakhis (2026-10-25) and the Gurmat Quiz
(2026-10-27). The older code each step replaced -- the first sangat (listed groups,
counted-on-read totals, the join banner), diary sync, the 45-second presence
read, the Settings city, the branded splash and intro pages, elder Today as a
fork, the Rehras / Kirtan Sohila / Daily Simran reminders -- is gone, and
`docs/ARCHITECTURE.md` §11 is the record of what went. What follows is what
is true of the code now, then what is live, then what is still open.

### What the app does

- **Goals, the Diary and Hazri** (steps 2-3): `user.db` schema 6 (5 added
  goals of items, `completions`, `simran_sessions`; 6 added `badges`).
  `verdictOn` in `lib/features/goals/domain/day_verdict.dart` is the one rule
  Today, the Goals screen, the Diary grid and the day screen all call. The
  v4 -> v5 migration (04-goals §5.8) is tested on a hand-built v4 database.
  **Since 2026-10-19 the goal is one page** (`GoalPlannerScreen`, design
  106): every paath once a day (GI10), every reminder on at the paath's own
  time from `GoalConstants.reminderDefaults` (Naam Simran 05:30 ... Kirtan
  Sohila 19:00, RM1). `normaliseGoalItems()` at start and after a restore
  turns an older goal into that shape without touching a past day.
- **Notifications** (`02-notifications.md`): five local kinds --
  `amritVela`, `goalBani` (one per goal item at its own time), `calendar`
  (Gurpurabs 06:00, other Sikh events 07:00), `hazriNudge`, `sangat` --
  planned by the pure `ReminderPlanner.plan` for 7 days every time anything
  is written (`UserRepository.onChanged`). They are **scheduled and posted by
  Hazri's own Android code** (`android/.../Reminders.kt`, DP7, 2026-10-11),
  not by `flutter_local_notifications`: on the owner's phone not one reminder
  the plugin scheduled ever showed, while an alarm set straight through
  Android arrived to the second (Diagnostics' alarm test, DP6). The plugin is
  kept for "Send one now", a foreground Sangat push, the channels and the
  permissions. The Sangat's three pushes (21:00 digest, new members to the
  creator, a group ending) are sent by the `sangatDispatch` Function. A badge
  or a met goal is an in-app sheet, never a notification.
- **Profile** (step 4): anonymous sign-in, Setup / Profile / Edit / Email
  sent / Link result, `/verify` links through the router's redirect, the
  profile's city as the only city (without a profile, sunrise times fall
  back to fixed ones). Verification and restore mail is sent by the `api`
  Function through **Brevo** (`BREVO_API_KEY` is a Functions secret, never
  in git; the domain is authenticated in the `hazri.me` zone). Without the
  key the endpoints answer `503 EMAIL_NOT_CONFIGURED` and the app says so.
  No account has a password, there is no sign-in screen, and nothing in
  `lib/` calls a password API -- `test/features/no_password_test.dart` fails
  if one appears.
- **Weekly backup** (step 5): a one-off WorkManager job `weekly-backup`
  re-enqueued for each Sunday 00:00 plus jitter, a catch-up at app open,
  Back up now and Restore on the Profile screen. The watermark compares with
  `>=` because drift keeps seconds; a repeat row is harmless (BK8).
- **Sangat** (step 6, `08-sangat.md`), all through the `api` Function:
  three built-in groups with Join/Leave, private custom groups with one goal
  and an end date, invites by link or code, the outbox in `user.db` (queued
  only while `sangat_member_v1` says the install is in a group), reports, and
  the push token. Totals are **maintained by the server** from shards
  (`sangatTotals`, every minute) -- never written by a client. **Each group
  has its own globe** (GG1-GG10, designs 104/105): members as counts per
  city, every dot tied to the ring by a dashed line (GG4a), the last hour's
  paath arriving as light along it, rebuilt by the server at most every 2
  minutes. A member row from before rows carried a city is filled from the
  profile on the group's first globe build (`citiesFilled`). The install
  referrer is read in `MainActivity.kt` with Google's `installreferrer`
  library directly: the Flutter plugin uses the `kotlinOptions` block Kotlin
  2.4 rejects.
- **Admin website** (`admin/`, `11-admin.md`): `https://hazri-admin-d4b72.web.app`,
  Google sign-in for the one admin address only. Editing a built-in group's
  template changes the **running** goal's target and length at once, and
  its bani from the next goal (owner, 2026-10-18).
- **Simran and the globe** (step 7, `07-simran.md`): one shared snapshot
  from `GET /presence/globe`, fetched on opening the tab and every 2 minutes
  while it is visible; attendance once per IST day with a profile; You
  (orange, blinking), Live (green), Here today (blue); dots sized by SZ1
  (one person is your dot's size, full at 25); threads from your dot (DR6)
  and a web joining the rest (DR7), as arcs with light along them (DR8);
  pinch or double tap to zoom (ZM1-ZM3); tap a dot for its city (TT1-TT3).
  The presence line counts you the way the dots do (CT1, CT2). ਵਾਹਿਗੁਰੂ drifts
  off the globe during a sitting, one word per utterance from
  `SimranTrack.onsets`; with no recitation there are no words. The screen's
  serif wordmark, ੴ rule and verse come from the owner's mock-up of
  2026-09-20, which is not in the repository; `simranHeadline*` is unused and
  a test holds it off the screen. Playfair Display (Latin only) is bundled
  for this screen alone, so Gurmukhi and Devanagari fall through to the Noto
  serifs by design.
- **Today and Nitnem** (step 8): the navy band on Today only (T11) -- every
  other tab draws its own header -- the streak card with the week strip
  (T12), the CTA order of T4, elder mode as one tree.
- **Badges** (step 9): `evaluateBadges` runs after every write, at start,
  after the Sangat facts and silently after a restore; the sheet waits until
  a tab is showing and never interrupts a sitting (UI7). Badge names live in
  `BadgeId` as proper nouns by script; everything else is in the ARB files.
- **First run** (step 10): Android's splash, Welcome, Language, How you read;
  `/` is a redirect, not a screen.
- **Saakhis** (`13-saakhi.md`, built 2026-10-25): four saakhis on the phone,
  `content.db` table `saakhi` (content version 9) from
  `content/source/saakhi/*.json` (content version 11 adds the owner's
  Punjabi narration, 2026-10-27, and a saakhi opens in Punjabi in every app
  language, SK9a; the Punjabi page timings are Claude's and want an ear,
  SK-23), pictures and narration under
  `assets/saakhi/` made by `tools/saakhi/build_assets.py` from the owner's
  masters in `saakhi-handoff/`. The reader turns pages with the narration
  (just_audio, its own player), the lesson is design D, Share makes a
  1080 x 1920 picture (the button says Share), hearts go in `user.db` schema
  7; the progress bars fill page by page and the last one fills at the end.
  Today shows one card, option C (design 113, 2026-10-27): the day's saakhi
  large -- days since 1970 modulo the count -- with Listen and Read, the
  others small; only those act, and it stays in elder mode. The menu is a
  left drawer (option A, `showMenuDrawer` in `lib/app/menu_sheet.dart`). A typed-in shabad ships
  only with a `checked` record naming its source (SK3); Bhai Lalo's Ang 105
  pankti was checked against BaniDB on 2026-10-25.
- **The Gurmat Quiz** (`14-quiz.md`, built and deployed 2026-10-27): 17
  topics and 340 questions in `content.db` (content version 10) from
  `content/source/quiz/`, imported from the owner's spreadsheet by
  `tools/content_pipeline/import_quiz.py`; the pipeline also writes the
  answer key to `functions/src/quiz-bank.json`, so a change to the bank
  needs `firebase deploy --only functions` as well as a new APK. The day's
  topic is the calendar event's or a rotation by the phone's date (QZ8).
  With a profile the server draws five questions (difficulty before
  freshness), scores them and keeps `quizSessions`, `quizPlayers`,
  `quizScores` and `quizBoards` (`deleteAt` TTL); every attempt adds to your
  total, a board counts your best per topic per IST day, and a first attempt
  at 0 still counts as played. **Without a profile the quiz plays on the
  phone, sends nothing and earns nothing** (QZ14). Today has two quiz cards
  (QZ9, 2026-10-28): the calendar leaf with the day's insight and no buttons,
  which on a day with an event opens its Vichar page (Know more, QZ11), and
  `QuizPickCard`, design D: today's topic with Start, your points, All
  quizzes, and the other categories as tiles opening the quiz page on that
  category (`/quiz?category=`). Neither fetches anything. A shared link is
  `<kSiteBase>/q/<topic>` and opens that quiz (`IncomingLink`).

### What is live, and what is deployed by hand

| Thing | Where | How it changes |
|---|---|---|
| Test APK | rolling pre-release `apk-claude/pensive-hawking-k87ese` | Actions -> Build -> Run workflow |
| Website, `/verify`, `/j/`, `assetlinks.json` | `https://hazri.me` (and `www.hazri.me`, redirecting) and `https://hazri-dfcc1.web.app` | `firebase deploy --only hosting:public` |
| Admin website | `https://hazri-admin-d4b72.web.app` | `npm --prefix admin run build && firebase deploy --only hosting:admin` |
| `api` and the scheduled / triggered Functions | `asia-south1` | `firebase deploy --only functions` |
| Firestore indexes and rules | `asia-south1` | `firebase deploy --only firestore` (rules: also the console) |

**No workflow deploys any of the server side.** A change to `functions/`,
`firestore.*`, `public/` or `admin/` is half done until somebody runs the
deploy, and the failure modes are quiet: an unpublished rule refuses every
write (reported as `SangatRefused`, never as offline), and a missing index
answers `500 INTERNAL` from the endpoint that needs it.

### Lessons the code still carries

- **A verification or restore link is tapped, and can still be pasted.**
  Four things have to agree or Android silently opens a browser instead, and
  all four fail the same invisible way: the `autoVerify` intent-filter, both
  hosts declared (`web.app` and `firebaseapp.com`), the SHA-256 in
  `public/.well-known/assetlinks.json` matching the key CI signs with, and
  that file being **deployed**. Hosting's default `"**/.*"` ignore rule once
  excluded `.well-known` silently; `test/android/firebase_hosting_test.dart`
  holds that now. `IncomingLink` keys on the `oobCode`, not the path.
- **`ScheduledNotificationReceiver` must be declared in the manifest** for
  the plugin path that remains. Its absence once meant no reminder ever
  arrived while `pendingNotificationRequests()` looked healthy, and four
  rounds of Dart fixes went out before anybody read the XML.
  `test/android/manifest_test.dart` holds both receivers.
- **POST_NOTIFICATIONS is asked for at app start**, not only in a setup
  step: a phone that upgraded past setup once never received a notification.
  The notifications screen says so when reminders cannot arrive.

### Still open

- **The quiz's `/q/` page needs a hosting deploy.** `public/q/index.html`
  and its `firebase.json` rewrite reach the website only with
  `firebase deploy --only hosting:public`; nobody has confirmed that has
  been run since 2026-10-27, and until it has, a shared quiz link lands on
  the website's 404. The questions are English for now (QZ6), and the
  Punjabi and Hindi topic names and labels are Claude's draft.
- **The Punjabi saakhi page timings want an ear** (SK-23). They were
  estimated from each page's share of the text and snapped to long pauses,
  not heard; a page that turns early or late is corrected in
  `narration.pa.page_starts`. The Punjabi lesson has no meaning cue
  (`meaning_at` is null).

- **`hazri.me` is not yet the app's host.** `kSiteBase` stays
  `hazri-dfcc1.web.app` until Phase 3 (`docs/domain-setup.md`), because a
  link already in somebody's inbox has to keep working.
- **The Vichar library is the website's 102 story pages** (2026-10-19),
  bundled with the `api` Function from `tools/site/articles/` and shown under
  four chips, Sikh days first (`docs/vichar-content.md`); nothing in it is
  written in Dart, and it reaches phones only after `firebase deploy --only functions`.
  The last list is saved on the phone and opens offline; a fresh one is
  fetched behind it once a session. Each entry names its **layout** --
  calendar card, photo-led or timeline, chosen by `layout_of` in
  `tools/site/articles.py` -- and the photo-led one draws its picture: the
  app loads no photo, because PRD §8 lists no photo host.
- **Analytics ships with collection off** and the Settings switch is inert
  and says so. Do not wire it up without rewriting the privacy screen.
- **Around a hundred and fifty Punjabi and Hindi UI strings are mine** and
  want a native ear before release; the website is English only.
- **CI's last step can fail after the APK is published** (2026-10-18, the
  post-run cache save), which marks a good run red. The release is still
  replaced; check the release before believing the colour.

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

- **The daily Hukamnama is gone**, replaced by ਅੱਜ ਦਾ ਵਿਚਾਰ (PRD §4.15): 200
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
  -- PRD §4.10's Sikh-event notification above all -- needs those names
  first, or it says an English sentence to somebody who chose Punjabi.
