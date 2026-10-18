# Hazri — Architecture, data and storage

| | |
|---|---|
| Document | Architecture, database schema, storage on the phone, server schema, APIs and Functions |
| Written | 2026-10-08, from the feature specifications of 2026-10-07 and 2026-10-08 |
| Companion to | `docs/PRD.md` (what the app does and the plan to build it) and `docs/features/` (the rules of each feature) |

## 0. How to read this document

**This is the one home for how Hazri is built and where its data lives.**
Every table, column, preference key, Firestore collection, endpoint and
Cloud Function is defined here and nowhere else. The feature files describe
behaviour and cite this document for the data; the PRD describes the product
and the build plan.

- **Moved sections keep their source numbering.** Most of the schema below
  was written inside a feature file and moved here word for word on
  2026-10-08. Each moved block says where it came from, and its headings
  carry the source file's tag and section, e.g. "04-goals §5.4
  `completions`". A reference anywhere to `04-goals.md` §5.4 therefore still
  lands: the feature file has a pointer at §5, and the heading is here.
  Bare references inside a moved block ("GI3", "4.2", "§6.0") are to its
  source file.
- **Precedence.** The PRD wins over everything; where a feature file's rule
  and the data shape here disagree, the rule wins and both are fixed in the
  same commit. A change to any table, key, collection or endpoint is made
  here, in the same commit as the code.
- **Status.** This is the **target** of the Phase 2 build. Where the code on
  the branch still has something older (the v4 goal tables, the direct
  Firestore sangat, diary sync), §11 lists it and what replaces it.

## 1. System overview

### 1.1 The parts

| Part | What it is | Where |
|---|---|---|
| The app | Flutter, Android only, offline-first. Everything a reader needs — reading, listening, the calendar, the diary, goals, hazri, badges — runs from the phone's own databases with the radio off | `lib/` |
| `content.db` | Read-only SQLite bundled in the APK: banis, lines, meanings, audio timings, the calendar, cities, the daily Vichar | `assets/content/content.db`, built by `tools/content_pipeline/` |
| `user.db` | The reader's own record: completions, sittings, goals, badges, reading position, the Sangat outbox | App storage, drift |
| Preferences | `shared_preferences`: settings, caches and once-a-day flags | App storage |
| Firebase project `hazri-dfcc1` | Blaze plan, `asia-south1` (Mumbai) | Google Cloud |
| Firebase Auth | **Anonymous only** for the app; Google sign-in only on the admin website | — |
| Cloud Function `api` | One HTTPS function, Express, every client read and write under `/api/v1` | `functions/` |
| Scheduled and triggered Functions | Sangat counting and resets, notification dispatch, badge facts | `functions/` |
| Firestore | Native mode, `asia-south1`. **No client access at all**: rules deny everything; only the Functions read and write it | — |
| Firebase Cloud Messaging | Sangat pushes only | — |
| Firebase Hosting, site `hazri-dfcc1` | `/api/**` rewrite to `api`, `/verify`, `/j/<code>`, `/.well-known/assetlinks.json` | `public/` (the profile spec writes `hosting/public/`; the repository's folder is `public/`) |
| Firebase Hosting, site `hazri-admin-d4b72` | The admin website | A separate source folder, named when it is built |
| Mail | Brevo or similar through its API, key in Secret Manager (`01-accounts.md` W6; the PRD text's Trigger Email extension is superseded by W6) | — |
| Firebase Analytics | In the build with collection **off**; sends nothing in Phase 2 | — |

### 1.1a Principles the architecture serves

1. **The phone is the truth for practice.** Completions, sittings, goals and
   badges live in `user.db`. The server holds only copies for restore
   (weekly backup) and what is genuinely shared (the Sangat, the globe).
2. **Derived, never stored twice.** Hazri, goal state, streaks and badge
   counts are computed from rows; only the fact of a badge being earned is
   stored (§10.2).
3. **No client touches Firestore.** Every read and write goes through the
   `api` Function with the anonymous ID token; rules deny all (§5.11).
4. **Reads are what bill** (§10.1). Today, Nitnem, the Diary and the reader
   cost nothing; the globe is one snapshot document.
5. **Nothing that reads, plays, shows the calendar or writes the diary waits
   on the network.**

### 1.2 The request path, and the backend and app stacks

*Moved here from `docs/features/01-accounts.md` §3 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


The app never reads or writes Firestore directly. All data access goes through one HTTPS Cloud Function (api) that uses the Admin SDK; Firestore security rules deny all client access.

```text
[Flutter Android app]
| Firebase Anonymous Auth -> ID token
| HTTPS Authorization: Bearer <ID token>
v
[Firebase Hosting https://{{FIREBASE_PROJECT_ID}}.web.app]
|-- /api/** -> rewrite -> Cloud Function "api" (asia-south1, Express)
|-- /verify -> static fallback page (verify/index.html)
|-- /.well-known/assetlinks.json -> Android App Links verification
v
[Cloud Function "api"] --Admin SDK--> [Firestore (asia-south1)]
|-- writes docs to "mail" collection
v
[Trigger Email extension] --SMTP--> user inbox

User taps link in email -> Android opens app via App Link -> app calls POST /api/v1/tokens/verify
```

#### 01-accounts §3.1 Backend stack

- Firebase Cloud Functions 2nd gen, Node.js 20, TypeScript.

- Packages: firebase-functions, firebase-admin, express.

- One exported function: export const api = onRequest({ region: "asia-south1" }, app); where app is the Express app.

- Express routes are mounted with the full /api/v1 prefix (Hosting forwards the full path).

- Firestore in Native mode, location asia-south1.

- Firebase Authentication with only the **Anonymous** provider enabled.

- Email delivery: official Firebase Extension **Trigger Email from Firestore** (firebase/firestore-send-email), collection name mail, configured with {{SMTP_CONNECTION_URI}} and {{EMAIL_FROM}}.

- Firebase Hosting serves the API rewrite, the fallback page and assetlinks.json.

#### 01-accounts §3.2 App stack

- Flutter (stable channel), Android only, minSdkVersion 24. *(Amended, §13 D4.)*

- Packages: firebase_core, firebase_auth, http, shared_preferences, app_links, flutter_riverpod.

- State management: Riverpod Notifier / NotifierProvider only.

- Navigation: the app's existing go_router. *(Amended, §13 D3: the PRD's Navigator 1.0 calls below are read as their go_router equivalents.)*

- Firebase configured with FlutterFire CLI (flutterfire configure), producing lib/firebase_options.dart.


## 2. The app

### 2.1 Packages

What the app uses, and what Phase 2 adds or removes. Versions are chosen at
implementation time (latest stable); a package that is not in this list is
not added without a line here.

| Concern | Package | Status |
|---|---|---|
| State | `flutter_riverpod` (Notifier / NotifierProvider) | In use |
| Navigation and deep links | `go_router` (top-level `redirect` handles incoming links); `app_links` for App Links | `go_router` in use; `app_links` added (`01-accounts.md` §3.2) |
| Local databases | `drift`, `sqlite3_flutter_libs`, `path_provider`, `path` | In use |
| Preferences | `shared_preferences` | In use |
| Audio | `just_audio`, `audio_service`, `audio_session` | In use |
| Reader | `scrollable_positioned_list`, `wakelock_plus` | In use |
| Sharing | `share_plus` | In use |
| Local notifications | `flutter_local_notifications`, `timezone`, `flutter_timezone` | In use |
| Background work | WorkManager (a Flutter plugin for it) for the weekly backup (`10-backup.md` §8.1) | Added |
| Firebase | `firebase_core`, `firebase_auth` (Anonymous), `firebase_analytics` (collection off), `firebase_messaging` (Sangat only) | `firebase_messaging` added |
| Firestore client | `cloud_firestore` | **Removed**: no client access (§5.11) |
| HTTP | `http`, for the `api` Function | Added (`01-accounts.md` §3.2) |
| Network state | `connectivity_plus`, to flush the Sangat outbox when the network returns | In use |
| Install referrer | A Play Install Referrer plugin, read once on first launch for an invite code (`08-sangat.md` IV6) | Added |
| SVG, i18n | `flutter_svg`, `intl`, `flutter_localizations` | In use |

No ad, attribution or tracking SDK, ever (CLAUDE.md rule 4).

### 2.2 Folder layout and layers

```
lib/
  main.dart            bootstrap: Firebase, databases, audio handler, notifications, runApp
  app/                 MaterialApp.router, routes, the five-tab shell, the menu sheet
  core/
    theme/             tokens.json -> HazriColors (ThemeExtension), type, icons
    l10n/              ARB files (pa, hi, en) and generated code
    db/                drift: content_db.dart, user_db.dart, migrations
    backend/           kSiteBase, the API client and auth (01-accounts §2.5)
    settings/          AppSettings + SettingsController (shared_preferences)
    time/              Clock, NOAA SolarService, Nanakshahi calendar, formatting
    widgets/           AppMark, ProgressRing, cards, chips, buttons
  features/<feature>/
    data/              repositories and controllers
    domain/            models and pure logic (verdictOn, hazriStreak, evaluateBadges, ReminderPlanner)
    ui/                screens and widgets
```

Feature-first and layered: **UI → controllers (Riverpod) → repositories →
data sources** (`user.db`, `content.db`, preferences, the `api` client).
Repositories expose drift `watch()` streams; providers derive UI state. Pure
domain functions take rows and return answers, so the rule that decides a
thing lives in exactly one place:

| Question | The one function | Spec |
|---|---|---|
| Was today hazri? Were the goals met? | `verdictOn(day, items, completions, sittings)` | `04-goals.md` §4.6 |
| How long is the hazri streak? | `hazriStreak(day)` → `current`, `longest` | `09-diary.md` D9, D12 |
| Which badges are earned? | `evaluateBadges()` | `12-badges.md` §4.2 |
| What notifications are due? | `ReminderPlanner.plan(...)` | `02-notifications.md` §6.2 |
| Who is on the globe, in which colour? | The snapshot split of `07-simran.md` §2.1 | `07-simran.md` |

The only code that inserts a completion is `completeBani`
(`06-nitnem.md`); it logs the row, queues it for the Sangat and asks for
re-planning. Time comes from an injectable `Clock`, so every rule is
testable with a fake one.

### 2.3 Platform interfaces

Platform-shaped code sits behind an interface so it can be faked in tests and
a second platform would need adapters, not rewrites (CLAUDE.md rule 6).

| Interface | Android adapter |
|---|---|
| `ReminderService` | `flutter_local_notifications`, exact alarms when allowed, 60 pending at most |
| `NotificationPermission` | `POST_NOTIFICATIONS` (13+) |
| Background work | WorkManager |
| Push | `firebase_messaging` |
| Store links | Play Store |

### 2.4 Profile client: files and routes

*Moved here from `docs/features/01-accounts.md` §8.1 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


```text
lib/
main.dart # init Firebase, ProviderScope, MaterialApp, routes, navigatorKey
firebase_options.dart # generated by flutterfire configure
config/app_config.dart # Section 2 values
models/profile.dart # Profile (fromJson/toJson of Profile DTO)
models/api_exception.dart # ApiException, NetworkException
validation/validators.dart # Section 5
services/auth_service.dart # ensureSignedIn(), getIdToken()
services/api_client.dart # HTTP + auth header + 401 retry + timeout
services/profile_api.dart # one method per endpoint in Section 6
services/profile_cache.dart # shared_preferences read/write/clear
services/deep_link_service.dart # app_links listener -> navigation
state/profile_controller.dart # ProfileState + ProfileController (Notifier)
screens/home_screen.dart
screens/profile_setup_screen.dart
screens/profile_screen.dart
screens/email_sent_screen.dart
screens/link_result_screen.dart
widgets/profile_banner.dart
widgets/change_email_dialog.dart
util/messages.dart # shared error strings (8.10)

functions/src/
index.ts app.ts config.ts auth.ts errors.ts validation.ts quota.ts tokens.ts email.ts routes/profile.ts routes/tokens.ts

hosting/public/
.well-known/assetlinks.json verify/index.html
```

**As built (2026-10-08)**, following this repository's layout rather than
the PRD's flat one: `lib/features/profile/domain/` (`profile.dart`,
`validators.dart`), `data/` (`profile_api.dart`, `profile_cache.dart`,
`profile_controller.dart`, `incoming_link.dart`, which is the
DeepLinkService as a go_router `redirect` per §13 D3) and `ui/` (the five
screens, `change_email_dialog.dart`, `profile_banner.dart`, `messages.dart`,
`city_field.dart`, `city_picker_sheet.dart`). The API client and auth are
`lib/core/backend/`. "Home" is Today.

Named routes: / HomeScreen, /profile-setup ProfileSetupScreen, /profile ProfileScreen, /email-sent EmailSentScreen (argument EmailSentArgs{purpose, email, cooldownSeconds}), /link-result LinkResultScreen (argument String token).

### 2.5 Profile client: services and the profile cache

*Moved here from `docs/features/01-accounts.md` §8.2 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


**AuthService.ensureSignedIn():** if FirebaseAuth.instance.currentUser == null, call signInAnonymously(). Called before every API request. **getIdToken(forceRefresh)** returns currentUser!.getIdToken(forceRefresh).

**ApiClient.request(method, path, body):**

1.  ensureSignedIn(), then get the ID token.

2.  Send with headers Authorization: Bearer \<token\> and Content-Type: application/json, timeout 15 s.

3.  On 401: get token with forceRefresh: true, retry once. A second 401 throws ApiException.

4.  2xx → return decoded JSON. Non-2xx → throw ApiException(statusCode, code, message, fields, retryAfterSeconds, purpose) parsed from the error body.

5.  SocketException, TimeoutException, http.ClientException, or FirebaseAuthException with code network-request-failed → throw NetworkException.

6.  No other automatic retries.

**ProfileCache** (shared_preferences key profile_cache_v1), value = JSON of the Profile DTO plus ownerUid:

- write(profile): stores DTO + ownerUid = currentUser.uid.

- read(): returns null and deletes the key if missing, not valid JSON, or ownerUid != currentUser?.uid.

- clear(): removes the key.


### 2.6 What runs when

Nothing on this list blocks a screen. Every network step is fire-and-forget
from the UI's point of view, and its failure changes nothing a reader sees
beyond what the feature file says.

| When | What | Spec |
|---|---|---|
| Launch, before the first frame | Redirect: onboarding done → Today, else Welcome. No branded splash | `03-first-run.md` F1 |
| Launch | Anonymous sign-in starts, alongside everything else | `01-accounts.md` §8.3, `03-first-run.md` F4 |
| Launch | The profile is read from its cache, then refreshed (`GET /profile`) | `01-accounts.md` §8.2–8.3 |
| Launch | `ReminderScheduler.reschedule()` asks for `POST_NOTIFICATIONS` (Android shows it only while it has no answer) and plans the next 7 days, 60 pending at most | `02-notifications.md` CM2, `03-first-run.md` F6 |
| Launch and resume | `closeGoalIfBlank()` | `04-goals.md` BG2 |
| Launch and resume, first of the IST day, with a profile | Attendance: `POST /presence/attendance`, then the local flag | `07-simran.md` AT1–AT2 |
| Launch, resume, network back, after a write | Flush the Sangat outbox | `08-sangat.md` §5.1 |
| Launch, after any completion, sitting, Diary edit, Sangat facts, restore | `evaluateBadges()`, off the UI thread | `12-badges.md` EV2 |
| Launch, once a day, with a profile, until both are earned | Fetch the two Sangat badge facts | `12-badges.md` SF4 |
| After a completion, sitting, Diary edit or goal-item change | Re-plan notifications | `04-goals.md` RM3 |
| Simran tab open | Fetch the globe snapshot, then every 2 minutes | `07-simran.md` §4.3 |
| Sunday 00:00 local + up to 60 min, with a profile and a network | WorkManager job `weekly-backup`; caught up at the next chance if missed | `10-backup.md` BK1–BK2, §8.1 |
| Local midnight with the app open | Today rolls over: hazri, items in scope, the streak strip, the CTA | `05-today.md` T10 |
| FCM token refresh, language or time-zone change, with a profile and a group | `POST /devices/fcm-token` | `02-notifications.md` FT2 |


## 3. Storage on the phone

### 3.1 What is stored where

| Store | Holds | Survives | Backed up |
|---|---|---|---|
| `content.db` | Everything the app ships: banis, lines, meanings, timings, calendar, cities, the daily Vichar | Replaced when `content_version` changes | No; it ships with the app |
| `user.db` | The reader's own record (§3.3–3.7) | Uninstall: only through Android backup | Android Auto Backup; with a profile, the weekly server backup of the tables in `10-backup.md` §3.1 |
| `shared_preferences` | Settings, the profile cache, once-a-day flags, small caches (§3.8–3.9) | As `user.db` | Android Auto Backup only |
| `assets/audio` | The recitations, in the APK | Ships with the app | No |
| `assets/geo/world.bin` | The globe's coastlines and borders | Ships with the app | No |

**What never leaves the phone:** reading positions, notification and app
settings, grace days, and anything at all for a person with no profile and
no group. The weekly backup sends only goals, goal items, completions,
sittings and earned badges, and only with a profile.

### 3.2 `content.db` (read-only, bundled)

Built by `tools/content_pipeline/build_content_db.py` from `content/source/`
and bundled at `assets/content/content.db`. On first run, and whenever
`meta.content_version` differs from the stamp file `content.version`, it is
copied to `getApplicationSupportDirectory()/content.db` and opened read-only
(`PRAGMA query_only`). Drift `schemaVersion` 1; content version 8 at the time
of writing. **Nothing in it is ever written by the app** (rule 3).

| Table | Columns | Holds |
|---|---|---|
| `source` | id, name, author?, kind, licence?, url?, notes?, publisher?, pub_date? | Every text, meaning, calendar and transliteration source, for credits |
| `bani` | id, slug, name_en, name_pa, name_hi, category, default_slot, sort, est_minutes, author_en?, has_text | The nine banis. `default_slot`: JAPJ, JAAP, TVPS, CHAU, ANND `morning`; REHR `evening`; SOHL `bedtime`; ARDS, SUKH `none` |
| `bani_version` | id, bani_id, code, label_en/pa/hi?, is_default, line_count | One version each today, `sgpc` |
| `line` | id, bani_version_id, idx, section_label_en/pa/hi?, kind, gurmukhi, devanagari, roman, visraam_json?, word_count, word_align, source_id?, source_ref?, pauri?, ends_pauri? | Every line in three scripts, with pause marks |
| `meaning` | (line_id, lang, is_alt) PK, text, source_id?, kind, note? | Reviewed meanings; Hindi only for the four banis in Sri Guru Granth Sahib Ji; `kind` `commentary` for the Faridkot teeka |
| `voice` | id, name?, credit_en/pa/hi? | Empty: the paathi is uncredited until a credit is agreed |
| `audio_track` | id, bani_version_id, voice_id?, pack, file, duration_ms?, bytes? | One recitation per bani, a file under `assets/audio/` |
| `timing` | audio_track_id PK, json | Line and word timings, verified by ear and locked |
| `simran_track` | id, file, duration_ms?, bytes?, json | The 5-minute Naam Simran recitation, with its envelope and onsets |
| `vichar` | idx, gurmukhi, meaning_pa, meaning_en | The 200 lines of ਅੱਜ ਦਾ ਵਿਚਾਰ |
| `nanakshahi_month` | (ns_year, idx) PK, name_en/pa/hi, start_date, days | Nanakshahi 558 and the first month of 559 |
| `calendar_event` | id, ns_year, date, kind, name_en, name_pa?, name_hi?, ns_label?, default_remind, supplementary | 147 events, 52 flagged to remind |
| `city` | id, name_en/pa/hi, country_code, lat, lon, tz, **state_code** (added by `07-simran.md` §5.1, here §5.5) | 92 cities; the list a profile's city is chosen from |
| `quote` | id, gurmukhi, devanagari, roman, attribution_en/pa/hi?, source_id? | Quotations shown in the app |
| `meta` | key, value | `content_version`, `source_digest`, `ik_onkar` |

The audio itself is **bundled in the APK** under `assets/audio/` — AAC-LC,
mono, 44.1 kHz, about 64 kbps, about 81 MB for the nine banis and the Simran
recitation. There are no Play asset packs and nothing is streamed. Masters
live on the `audio-masters` GitHub release (`audio/README.md`).

### 3.3 `user.db`: goals, goal items, completions and sittings (schema 5)

*Moved here from `docs/features/04-goals.md` §5 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


Four tables carry this feature: `goals`, `goalItems`, `completions` and `simranSessions`. They live in the phone's drift database. `goalTicks` is removed, because goal progress is now read from completions and sittings (CR5).

#### 04-goals §5.1 Conventions (aligned with the Profile PRD)

| Convention | Profile PRD (Firestore) | This feature (`user.db`) |
| --- | --- | --- |
| Field names | camelCase | camelCase in Dart; drift maps them to snake_case columns |
| Document / row ID | Firestore auto ID | UUID v4 string generated on the phone. A future sync uses the same value as the Firestore document ID. |
| Owner | `ownerUid` / `profileId` on the document | None locally: one install is one user. Added only in the cloud path (6). |
| Timestamps | Firestore `Timestamp`, server time | `DATETIME` in UTC, phone time, set by the app |
| `createdAt` / `updatedAt` | On every document | On every table; `updatedAt` changes on every write |
| Enums | UPPER_SNAKE strings (`VERIFY_EMAIL`, `ACTIVE`) | UPPER_SNAKE strings |
| Calendar dates | n/a | `TEXT` `YYYY-MM-DD`, local day |
| Deletion | Status change, no delete feature | Goals and items are never deleted. Completions and sittings are soft-deleted with `deletedAt`, so an undo can sync. |

#### 04-goals §5.2 `goals`

One row per goal. At most one row has `completedOn` = null (GL3).

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `id` | TEXT (PK) | no | UUID v4 |
| `startDate` | TEXT | no | `YYYY-MM-DD`, the day the goal was created |
| `completedOn` | TEXT | yes | `YYYY-MM-DD` of the first blank day (BG1, BG2). Null while active. |
| `createdAt` | DATETIME | no | UTC |
| `updatedAt` | DATETIME | no | UTC, every write |

#### 04-goals §5.3 `goalItems`

One row per stretch of one bani (or simran) inside a goal. A target edit adds a row with the same `seriesId` (GI6).

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `id` | TEXT (PK) | no | UUID v4 |
| `goalId` | TEXT | no | References `goals.id` |
| `seriesId` | TEXT | no | Equals `id` on the first row; copied to rows created by a target edit. "Day N of M" counts from the series' first `startDate`. |
| `itemType` | TEXT | no | `BANI` or `SIMRAN` |
| `baniId` | TEXT | yes | `content.db` bani ID. Required for `BANI`, null for `SIMRAN`. |
| `timesPerDay` | INTEGER | no | `BANI`: 1–11. `SIMRAN`: always 1. |
| `simranMinutes` | INTEGER | yes | `SIMRAN`: 5–120. Null for `BANI`. |
| `durationType` | TEXT | no | `EVERY_DAY`, `DAYS` or `UNTIL_DATE` |
| `durationDays` | INTEGER | yes | `DAYS` only: 1–365, counted from the series start |
| `startDate` | TEXT | no | `YYYY-MM-DD`, today on insert |
| `endDate` | TEXT | yes | Computed per GI4. Null for `EVERY_DAY`. |
| `removedOn` | TEXT | yes | `YYYY-MM-DD` set by GI6 or GI7. The item is out of scope from this day. |
| `reminderTime` | TEXT | yes | `HH:mm`, 24-hour local time. Null = reminder off. |
| `createdAt` | DATETIME | no | UTC |
| `updatedAt` | DATETIME | no | UTC, every write |

#### 04-goals §5.4 `completions`

One row per recitation of one bani. Read by hazri (HZ1) and goals (4.6).

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `id` | TEXT (PK) | no | UUID v4 |
| `localDate` | TEXT | no | `YYYY-MM-DD` of the day it counts for |
| `baniId` | TEXT | no | `content.db` bani ID |
| `slot` | TEXT | no | `MORNING`, `EVENING`, `BEDTIME` or `NONE`. Kept for the Nitnem list; not used by hazri or goals. |
| `source` | TEXT | no | `READER`, `AUDIO`, `DIARY`, `RESTORED` or `MIGRATED` |
| `completedAt` | DATETIME | no | UTC |
| `updatedAt` | DATETIME | no | UTC, every write |
| `deletedAt` | DATETIME | yes | Set by Diary − (CR3). Rows with it set are ignored everywhere. |

No uniqueness on (`localDate`, `baniId`, `slot`). The current duplicate check in `logCompletion` is removed (CR5).

#### 04-goals §5.5 `simranSessions`

One row per Naam Simran sitting.

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `id` | TEXT (PK) | no | UUID v4 |
| `localDate` | TEXT | no | `YYYY-MM-DD` |
| `startedAt` | DATETIME | no | UTC |
| `durationS` | INTEGER | no | Actual seconds sat, ≥ 0 |
| `completed` | BOOLEAN | no | True when the sitting reached the timer's planned length |
| `count` | INTEGER | no | Utterances counted, default 0 (existing) |
| `source` | TEXT | no | `TIMER`, `DIARY`, `RESTORED` or `MIGRATED` |
| `updatedAt` | DATETIME | no | UTC, every write |
| `deletedAt` | DATETIME | yes | Set by Diary − (CR4) |

#### 04-goals §5.6 Indexes and integrity

| Index | Table (columns) | Serves |
| --- | --- | --- |
| `idx_goal_items_goal` | `goalItems` (`goalId`) | Items of the active goal |
| `idx_goals_completed` | `goals` (`completedOn`) | Finding the active goal |
| `idx_completions_date` | `completions` (`localDate`) | Day and month reads |
| `idx_simran_date` | `simranSessions` (`localDate`) | Day and month reads |

GL3 and GI1 are enforced by the repository inside the same transaction as the write, not by a database constraint.

#### 04-goals §5.7 Repository operations

Every write runs in one drift transaction and sets `updatedAt`. After each one the app re-plans reminders (RM3).

| Operation | Writes |
| --- | --- |
| `addItem(spec)` | Creates the goal if none is active (GL2), then inserts the item (GI1, GI2, GI4) |
| `editReminder(itemId, time?)` | Updates `reminderTime` in place |
| `editDuration(itemId, spec)` | Updates `durationType`, `durationDays`, `endDate` in place; new `endDate` ≥ today |
| `editTarget(itemId, target)` | GI6: ends the old row, inserts the new one (or updates in place on its start day) |
| `removeItem(itemId)` | Sets `removedOn` = today (GI7); then BG1 |
| `closeGoalIfBlank()` | BG2 |
| `logCompletion(baniId, source)` | Inserts into `completions` (CR1–CR3) |
| `undoLatestCompletion(baniId, day)` | Sets `deletedAt` on the newest live row (CR3) |
| `logSitting(durationS, completed, source)` | Inserts into `simranSessions` (HZ4, CR4) |
| `undoLatestSitting(day)` | Sets `deletedAt` on the newest live row (CR4) |
| `watchDay(day)` / `watchMonth(month)` | Read only; streams feed `verdictOn` (4.6) |

#### 04-goals §5.8 Migration from schema version 4

One transaction, run once on upgrade:

1. Rename the old `goals` table to `goals_v4`. Create `goals` and `goalItems` as above.
2. If `goals_v4` has rows, create one goal. `startDate` is the earliest old `startDate`. `completedOn` is null if any old row is still in scope today; otherwise it is the day after the latest old last day.
3. Copy each old row to `goalItems` with the same `id`, `seriesId` = `id`, and these values:
    - `itemType`: `SIMRAN` when `baniId` = `simran`, else `BANI`.
    - `durationType`: `everyDay`, `days` and `until` become `EVERY_DAY`, `DAYS` and `UNTIL_DATE`.
    - `simranMinutes` from `minutes`; `endDate` per GI4.
    - `removedOn`: the day after old `endedOn`, when set.
4. In `goalTicks`, turn each `manual` tick into one row with `source` = `MIGRATED`: a completion for a bani goal, or a sitting of `minutes` × 60 s for a simran goal. Drop every `auto` tick, because a completion already stands behind it. Drop `goalTicks` and `goals_v4`.
5. In `completions`, map `source` values `read`, `listen`, `manual` and `restored` to `READER`, `AUDIO`, `DIARY` and `RESTORED`. Map `slot` to upper case, set `updatedAt` = `completedAt`, and drop the unused `goalId` column.
6. In `simranSessions`, set `source` = `TIMER` and `updatedAt` = `startedAt`.

Old rows may overlap for the same bani. GI1 applies only to new writes, and `verdictOn` judges each in-scope item separately, so history is unchanged.

### 3.4 Cloud sync readiness of those tables

*Moved here from `docs/features/04-goals.md` §6 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


This feature sends nothing to the cloud. Until a sync feature ships, **uninstalling the app or clearing its data loses every goal, completion and dot**. Once it ships, a profile restore brings goals and diary entries back as of the last weekly sync (`01-accounts.md` §13 D8).

A weekly phone-to-cloud backup is specified in `10-backup.md`, and the paths below are its. The schema above is ready for it without another migration:

- Every row has a UUID `id`, which identifies it inside the backup documents.
- Every row has `updatedAt`, so a sync can send only rows changed since the last run.
- Undo is a soft delete (`deletedAt`), so it can be sent like any other change.

The intended Firestore shape follows the Profile PRD's rules: documents under the owning profile, and written only by the `api` Cloud Function.

| Local table | Firestore path (`10-backup.md` §5) |
| --- | --- |
| `goals` | `profiles/{profileId}/backupGoals/{goalId}` |
| `goalItems` | Inside its goal's `backupGoals` document |
| `completions` | `profiles/{profileId}/backupWeeks/{weekId}` |
| `simranSessions` | `profiles/{profileId}/backupWeeks/{weekId}` |

The owner has amended Profile PRD §12 so that restore brings these tables back (`01-accounts.md` §13 D8 and 13.2).

### 3.5 `user.db`: the Sangat outbox, and the read-only copy

*Moved here from `docs/features/08-sangat.md` §5 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


#### 08-sangat §5.1 Paath waiting to be sent (`sangatOutbox`, in `user.db`)

Every completion and every sitting is added to the outbox when it is recorded, and a retraction is added when one is undone, unless the person belongs to no group (then nothing is queued). The app sends the outbox when it starts, on resume, when the network returns, and right after adding to it. The server works out which groups each one counts for.

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `id` | TEXT (PK) | no | The completion's or sitting's `id` (`04-goals.md` §5.4–5.5) |
| `kind` | TEXT | no | `BANI` or `SIMRAN` |
| `baniId` | TEXT | yes | For `BANI` |
| `durationS` | INTEGER | yes | For `SIMRAN` |
| `source` | TEXT | no | The row's `source` |
| `at` | DATETIME | no | `completedAt` or `startedAt`, UTC |
| `action` | TEXT | no | `ADD` or `RETRACT` |
| `createdAt` | DATETIME | no | UTC |

A row is deleted when the server confirms it. Sending the same row twice changes nothing on the server (7.12). An `ADD` and a `RETRACT` of the same `id` still waiting are both sent, in order.

#### 08-sangat §5.2 Read-only copy of what the server sent

The app keeps the last response of 7.1, 7.2 and 7.3 for each group (shared preferences, key `sangat_cache_v1`, JSON), and the last 7.15 globe of each group under `sangat_globe_cache_v1` (a JSON map of group id to the reply, 08-sangat GG8). Opening a screen shows the copy at once with `sangatUpdatedAt`, asks the server, and replaces it with the reply. Offline, the copy stays with its time. The phone never edits it; it is cleared on `markNone()` (`01-accounts.md` §8.3) when the person had no memberships without a profile.

### 3.6 `user.db`: `badges` (schema 6)

*Moved here from `docs/features/12-badges.md` §4.1 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `badgeId` | TEXT (PK) | no | One of Section 2 |
| `earnedOn` | TEXT | no | `YYYY-MM-DD`, the local date the app first found the rule met |
| `announcedAt` | DATETIME | yes | UTC; when its sheet was shown (7.2), or when it was marked as never to be shown (7.3, 6) |
| `createdAt` | DATETIME | no | UTC |
| `updatedAt` | DATETIME | no | UTC, every write |

Migration 5 → 6 creates the table empty. Nothing else changes.


### 3.7 `user.db`: the other tables, and the schema versions

Drift, file `getApplicationDocumentsDirectory()/user.db`. Version 4 on the
branch today. Besides the tables of §3.3–3.6:

| Table | Columns | Phase 2 |
|---|---|---|
| `reading_progress` | bani_version_id PK, line_idx, audio_pos_ms, updated_at | **Kept.** The saved place in each bani, written every 5 s and on close (`06-nitnem.md` B4, B7). Not backed up |
| `grace_days` | local_date PK, month_key | **Kept.** Two a month, granted silently (`09-diary.md` D8). Not backed up |
| `event_reminder_overrides` | event_id PK, enabled | **Kept.** The per-event bell on the calendar (`02-notifications.md` §9) |
| `reminders` | id, target_type, target_id, mode, anchor?, offset_min?, time_hhmm?, days_mask, slot_override?, updated_at | **Retired.** No reminder row is stored any more; every occurrence is derived when planning (`02-notifications.md` §6.2, `04-goals.md` RM4). The v5 migration drops the table (added here, 2026-10-08, to `04-goals.md` §5.8) |
| `goal_ticks` | id, goal_id, local_date, source, at | **Retired** by the v5 migration (§3.3, step 4) |

**Schema versions.**

| Version | Change | Spec |
|---|---|---|
| 4 | As on the branch today | — |
| 5 | `goals` rebuilt and `goalItems` added; `completions` and `simranSessions` gain `source`, `updatedAt`, `deletedAt`; `goalTicks` folded into completions and sittings and dropped | `04-goals.md` §5.8 (here §3.3) |
| 5 | `sangatOutbox` | `08-sangat.md` §5.1 (here §3.5) |
| 6 | `badges` | `12-badges.md` §4.1 (here §3.6) |

Every migration runs in one transaction and has a test that opens a database
of the previous version with real-shaped rows and checks them afterwards.

### 3.8 Preferences

`shared_preferences`. Every key is listed here; a key not listed is not
added. The *Phase 2* column is the target.

| Key | Type | Default | Phase 2 |
|---|---|---|---|
| `app_locale` | `pa` / `hi` / `en` | Device language if pa or hi, else en | Kept |
| `script` | gurmukhi / devanagari / roman | By language: pa and en Gurmukhi, hi Devanagari | Kept |
| `show_roman_under_gurmukhi` | bool | true for en, else false | Kept |
| `meanings_on` | bool | true | Kept |
| `meanings_lang` | `pa` / `hi` / `en` | The app language | Kept |
| `visraam_on` | bool | true | Kept |
| `larivaar_on` | bool | false | Kept |
| `reader_font_size` | double, 16–40 | 22 | Kept; never below 30 in elder mode |
| `keep_screen_on` | bool | true | Kept |
| `follow_audio` | bool | true | Kept |
| `theme` | system / light / dark | system | Kept |
| `elder_mode` | bool | false | Kept |
| `speed` | double | 1.0 | Kept |
| `onboarding_done` | bool | false | Kept |
| `analytics_enabled` | bool | false | Kept, never written in Phase 2 |
| `goal_complete_sheet_shown_on` | date | — | Kept (`04-goals.md` CE1) |
| `notif_on_amrit_vela`, `notif_on_goal_reminders`, `notif_on_sikh_calendar`, `notif_on_hazri_nudge`, `notif_on_sangat` | bool | true | **New.** One switch per kind, keyed by its channel (`02-notifications.md` CM7) |
| `hazri_banner_closed_v1` | String | — | **New** (2026-10-10). The local date the marked hazri banner was closed on (`05-today.md` T1a) |
| `city_id` | String | `new_delhi` | **Removed.** One city, the profile's; none without a profile (`03-first-run.md` CY1–CY3) |
| `simran_minutes` | int | 5 | **Removed.** The sitting is 5 minutes or the goal item's minutes (`07-simran.md` S-7) |
| `exact_alarm_asked` | bool | false | **Removed.** Exact alarms are never asked (`02-notifications.md` DP2) |
| `diary_sync`, `sync_wifi_only` | bool | false, true | **Removed** with diary sync (`10-backup.md` B-4) |
| `pending_verification_email`, `last_opened_with`, `last_auth_state` | String | — | **Removed** with the old account code (`01-accounts.md` W1) |

Settings that change what is shown apply at once; changing the app language
also resets the script, the meaning language and the Roman line to that
language's defaults, and re-plans notifications (`02-notifications.md` CM6).

### 3.9 Local flags and caches named by the feature files

#### 3.9.1 Simran and the globe

*Moved here from `docs/features/07-simran.md` §7 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


| Key | Meaning |
| --- | --- |
| `presence_attendance_v1` | `dayIst` of the last successful attendance (AT1) |
| `presence_attendance_at_v1` | When that attendance succeeded, ISO 8601 UTC by the phone's clock, so the globe knows whether a snapshot already counts you (07-simran CT1) |
| `presence_snapshot_v1` | The last snapshot received, so the globe draws at once on the next open (GB3) |

#### 3.9.2 Weekly backup

*Moved here from `docs/features/10-backup.md` §7 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


| Key | Where | Meaning |
| --- | --- | --- |
| `backup_last_at_v1` | shared_preferences | Watermark, UTC ISO string |
| `backup_running_since_v1` | shared_preferences | `startedAt` of a backup in progress (BK7) |
| `sangat_member_v1` | shared_preferences | Whether this install belongs to an active Sangat group, from the last 7.1/7.2 answer; turns the outbox on (08-sangat §5.1). Added 2026-10-08 |
| `install_referrer_read_v1`, `sangat_pending_code_v1` | shared_preferences | The Play install referrer was read (IV6), and the invite code it carried, kept until setup is done. Added 2026-10-08 |
| `held_link_v1` | shared_preferences | An App Link (`/j/<code>`, `/verify`) opened before setup, as the in-app route it resolves to, opened once setup completes (`03-first-run.md` F7). Added 2026-10-08 |
| `backup_next_due_v1` | shared_preferences | When the weekly job is next due, local ISO string; an app open after it runs the catch-up (BK2). Added 2026-10-08 |

No `user.db` table is added. Every backed-up row already has `id`, `updatedAt` and, for diary rows, `deletedAt` (`04-goals.md` §5.1).

#### 3.9.3 Badges: the Sangat facts

*Moved here from `docs/features/12-badges.md` §5.3 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


- **SF4.** The app calls 5.2 when the Sangat tab opens and once a day at app start, only in `ProfileLoaded` and only while `SEVADAR` or `SATSANGI` is not yet earned. Once both are earned it never calls again.
- **SF5.** The response is cached in shared_preferences (`badge_sangat_facts_v1`) and fed to `evaluateBadges()`. A failed call changes nothing and is not shown.


#### 3.9.4 The rest

| Key | Meaning | Spec |
|---|---|---|
| `profile_cache_v1` | The profile DTO and the uid that owns it (§2.5) | `01-accounts.md` §8.2 |
| `snoozed:{reminderId}:{day}` | A goal reminder already snoozed once that day | `02-notifications.md` §6.3 |

### 3.10 Android backup

`android:allowBackup="true"` with `dataExtractionRules` and
`fullBackupContent` that include `user.db*` and the shared preferences and
exclude `content.db` and caches (`01-accounts.md` D5). Switching backup off
would lose the diary on a new phone for everybody without a profile.


## 4. Local notifications

Planned on the phone by `ReminderPlanner.plan` (pure) and scheduled by
`ReminderService`, on a rolling 7-day window of at most 60 pending. **No
reminder rows are stored**: every occurrence is derived from goal items, the
calendar and the day's state at planning time (`02-notifications.md` §6.2,
`04-goals.md` RM4). The manifest declares both
`ScheduledNotificationReceiver` and the boot receiver; without the first no
scheduled notification can ever appear (CLAUDE.md, "Known gaps").

### 4.1 Identifiers and channels

*Moved here from `docs/features/02-notifications.md` §6.1 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


| Kind | Reminder ID | Channel ID | Channel name key |
| --- | --- | --- | --- |
| Amrit Vela | `amrit-vela` | `amrit_vela` (Android: `amrit_vela_v2`) | `notifChannelAmritVela` (Amrit Vela) |
| Goal bani | `goal-item:{itemId}` | `goal_reminders` (Android: `goal_reminders_v2`) | `notifChannelGoals` (Goal reminders) |
| Gurpurab and events | `event:{eventId}` | `sikh_calendar` (Android: `sikh_calendar_v2`) | `notifChannelCalendar` (Gurpurab and Sikh events) |
| Hazri nudge | `hazri-nudge` | `hazri_nudge` (Android: `hazri_nudge_v2`) | `notifChannelHazri` (Hazri reminder) |
| Sangat | (push) | `sangat` (Android: `sangat_v2`) | `notifChannelSangat` (Sangat) |

On upgrade the old channels `nitnem_reminders`, `daily_simran`, `gurpurab` and `paath_goals` are deleted, so system settings shows only these five.

**Every channel is high importance** (2026-10-09), so a notification shows as
a pop-up and not only in the shade. The five were first created at default
importance, which plays the sound and shows nothing on screen; the reader
heard every test notification and saw none. Android keeps a channel's
importance once created, so the posted channels moved to `<id>_v2`
(`NotificationKind.androidChannelId`) and the five first ids are deleted on
upgrade. The plain id stays the kind's name here and the key of its switch
(`notif_on_<id>`, §3.8), so nobody's switches reset. The manifest's FCM
default channel is `sangat_v2`, so a push from a Function still naming
`sangat` lands there too. The old rows `slot:evening`, `slot:bedtime` and `simran` are removed (10.1).


## 5. Server: the Firebase project and Firestore

### 5.1 The project, and every collection at a glance

**`hazri-dfcc1`, Blaze plan, live.** Firestore Native, single region
`asia-south1` (Mumbai); Functions in the same region. The database was
recreated there on 2026-09-26 because `asia-south2` has no Firestore event
provider (§5.3). PITR (7 days) and daily backups (90 days) must be set on
this database (`00-platform.md` P6).

**Only the Functions read and write Firestore** (§5.11). Conventions for every
collection: camelCase fields, server timestamps, rules deny all
(`01-accounts.md` §4, here §5.4).

| Collection | One document per | Defined in |
|---|---|---|
| `profiles/{profileId}` | Profile; carries `cityId` and `lastSeenDay` for the globe | §5.4, §5.5 |
| `emailIndex/{emailHash}` | Email in use, for uniqueness and restore | §5.4 |
| `owners/{uid}` | Install uid that owns a profile | §5.4 |
| `verificationTokens/{tokenHash}` | Verify, restore and change-email link | §5.4 |
| `mail/{autoId}` | Outgoing mail | §5.4 |
| `presenceSnapshot/current` | The whole globe, counted by country, state and city | §5.5 |
| `groups/{groupId}` | Sangat group, built-in or custom | §5.6 |
| `groups/{groupId}/goals/{goalId}` | One goal of a group, current or past | §5.6 |
| `groups/{groupId}/goals/{goalId}/shards/{0..19}` | Built-in goal counter shard | §5.6 |
| `groups/{groupId}/members/{memberKey}` | Member and contribution | §5.6 |
| `contributions/{memberKey}_{id}` | Received outbox row; makes sending idempotent | §5.6 |
| `contributionCaps/{memberKey}_{groupId}_{dayIst}` | Diary + cap per day | §5.6 |
| `inviteCodes/{code}` | Live invite code | §5.6 |
| `memberships/{memberKey}` | "My groups" in one read | §5.6 |
| `groupLimits/{profileId}` | Raised custom-group limit | §5.6 |
| `groupReports/{groupId}_{memberKey}` | A report | §5.6 |
| `badgeFacts/{memberKey}` | Sevadar and Satsangi counts | §5.8 |
| `profiles/{profileId}/backupMeta/manifest` | Backup manifest | §5.7 |
| `profiles/{profileId}/backupGoals/{goalId}` | Backed-up goal and its items | §5.7 |
| `profiles/{profileId}/backupWeeks/{weekId}` | Backed-up completions and sittings of a week | §5.7 |
| `profiles/{profileId}/backupBadges/all` | Backed-up earned badges | §5.9 |
| `fcmTokens/{uid}` | Device push token, Sangat members only | §5.10 |
| `sangatNotices/{groupId}_{goalId}_{milestone}` | A milestone notice, sent once | §7.2 |
| `adminAudit/{autoId}` | Every admin change | `11-admin.md` AC5 |

**Retired** (in the earlier design, deployed for test data only, and not to be
used): `users/{uid}` and its `diary`, the old `groups` member shape with
roles, `presence/{day}/cities/...` with heartbeats, `aggregates`, client-read
`content/{doc=**}` (the Vichar library moves behind the API,
`01-accounts.md` §13.4).

### 5.2 Spend controls

*Moved here from `docs/features/00-platform.md` The spend controls, as configured on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


| Control | Value |
|---|---|
| Spend cap | **₹2,000 / month**, Firebase-generated caps per cappable service |
| Cappable services | Cloud Run, Cloud Run Functions, Gemini API, Vertex AI |
| Project budget alert | `Firebase Project hazri-dfcc1`, monthly, 50 / 90 / 100% |
| Expected actual spend | **₹0.** The free allowance does not go away on Blaze |

Three things about that cap which matter more than the number:

**C1 — Firestore cannot be capped.** It is not in the cappable list, and it is
our largest cost driver by a distance. The only protection there is the data
model (§0.3) and the budget *alert*.

**C2 — costs record up to 24 hours late**, so a cap can lag reality by a day.
A Function in a write-trigger-write loop could burn for hours before anything
pauses. **The cap is the last line, not the first.**

**C3 — a cap that trips takes the app's server side offline.** Pre-release
that is the right trade. After launch it is not, and it becomes an alert plus
a phone call instead.

**Gemini API and Vertex AI are disabled** (2026-09-26). Nothing in this
repository references either — no Gemini, no Vertex, no `generativelanguage`,
no `aiplatform`. They were the two most expensive things that could possibly
have run on this project, and disabling them removes the whole category rather
than alerting after the fact. **Do not re-enable either without a decision
recorded here**; two of the four generated spend caps now guard services that
cannot run.

### 5.3 The Functions contract

*Moved here from `docs/features/00-platform.md` The Functions contract — the real first line of defence on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


Every Cloud Function in this project:

**FN1 — `maxInstances: 10`.** Caps how wide a runaway can fan out. There is no
workload here that needs more.

**FN2 — `minInstances: 0`.** Min-instances is the only way to be billed while
nothing is happening.

**FN3 — never write to what triggers you** without a guard that provably
terminates. A Firestore-triggered Function that writes to its own trigger
collection is the loop that generates the horror stories. Where a Function
must write back, it writes to a *different* document and checks for a no-op
before writing.

**FN4 — idempotent, always.** Functions retry. A Function that maintains a
counter must be safe to run twice on the same event; recompute from source
rather than incrementing blind.

**FN5 — same region as Firestore, which is `asia-south1` (Mumbai).**
Firestore Native, single-region. A database's location is permanent, so it
picks the Functions region and not the other way round.

**It was `asia-south2` (Delhi) until 2026-09-26, and that was a dead end.**
Worth keeping the finding, because the documentation does not make it obvious
and somebody will be tempted by Delhi again. `asia-south2` has Eventarc, Cloud
Run and Cloud Functions — but **not the Firestore event provider**:

```
$ gcloud eventarc providers list --location=asia-south2
cloudaudit, workflows, clouddeploy, datastream, redis,
metastore, cloudfunctions, gkebackup, eventarc        <- no firestore

$ gcloud eventarc providers list --location=asia-south1 | grep firestore
firestore.googleapis.com                              <- present
```

A Firestore trigger must live in the same location as the database, so with
the database in `asia-south2` **no Firestore-triggered Function can exist at
all**. This is a regional gap, not a project misconfiguration, and the docs do
not make it obvious: Eventarc "being available" in a region is not the same as
the Firestore provider being available there.

**Resolved by moving the database**, the same day, while it still held nothing
but test rows. The alternatives — a scheduled reconcile instead of triggers,
or callables with a reconcile as backstop — were both workable and both worse,
and the window for moving cheaply closes the moment there are real readers.

The move, for the record: delete protection was already off, so it was
`databases delete`, then `databases create --location=asia-south1`. **The ID
`(default)` is not reusable immediately** — the create fails with
`FAILED_PRECONDITION ... retry in N seconds` for about five minutes. Wait and
retry; do not reach for a different database name.

**FN6 — every Function has an emulator test, including being run twice.**

### 5.4 Profiles: `profiles`, `emailIndex`, `owners`, `verificationTokens`, `mail`

*Moved here from `docs/features/01-accounts.md` §4 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


Five collections. Only the Cloud Function writes them. All timestamps are Firestore Timestamp; createdAt/updatedAt use FieldValue.serverTimestamp(), expiry comparisons use Timestamp.now() inside the function.

#### 01-accounts §4.1 profiles/{profileId}

profileId = Firestore auto-generated ID.

| Field                    | Type      | Nullable | Rule                                          |
|--------------------------|-----------|----------|-----------------------------------------------|
| profileId                | string    | no       | Same as document ID                           |
| ownerUid                 | string    | no       | Anonymous uid that currently owns the profile |
| name                     | string    | no       | Normalized per Section 5                      |
| email                    | string    | no       | Trimmed, as entered (case kept)               |
| emailNormalized          | string    | no       | Trimmed + lowercased                          |
| phone                    | string    | yes      | Normalised per Section 5 (§13 D2), or null    |
| cityId                   | string    | no       | A city ID from the app's city list (§13 D9). Replaces the free-text city. |
| lastSeenDay              | string    | yes      | IST day of the last attendance; written only by the attendance call, which leaves updatedAt alone (§13 D10) |
| emailVerified            | boolean   | no       | false on create                               |
| emailVerifiedAt          | timestamp | yes      | null until verified                           |
| createdAt                | timestamp | no       | Server timestamp                              |
| updatedAt                | timestamp | no       | Server timestamp on every write               |
| restoredAt               | timestamp | yes      | null; set on each successful restore          |
| emailQuota.lastSentAt    | timestamp | yes      | Last verification or restore email queued     |
| emailQuota.windowStartAt | timestamp | yes      | Start of current 24 h window                  |
| emailQuota.countInWindow | number    | no       | 0 on create                                   |

#### 01-accounts §4.2 emailIndex/{emailHash}

Guarantees one profile per email. emailHash = lowercase hex SHA-256 of emailNormalized.

| Field     | Type      | Rule                         |
|-----------|-----------|------------------------------|
| profileId | string    | Profile that owns this email |
| createdAt | timestamp | Server timestamp             |

#### 01-accounts §4.3 owners/{uid}

Guarantees one profile per install. Document ID = anonymous uid.

| Field     | Type      | Rule                      |
|-----------|-----------|---------------------------|
| profileId | string    | Profile owned by this uid |
| createdAt | timestamp | Server timestamp          |

#### 01-accounts §4.4 verificationTokens/{tokenHash}

tokenHash = lowercase hex SHA-256 of the raw token. The raw token is never stored.

| Field           | Type      | Rule                                  |
|-----------------|-----------|---------------------------------------|
| tokenHash       | string    | Same as document ID                   |
| profileId       | string    | Target profile                        |
| purpose         | string    | VERIFY_EMAIL or RESTORE_PROFILE       |
| requestingUid   | string    | uid that requested the email          |
| emailNormalized | string    | Email the link was sent to            |
| status          | string    | ACTIVE, USED or SUPERSEDED            |
| createdAt       | timestamp | Server timestamp                      |
| expiresAt       | timestamp | now + TTL for the purpose (Section 2) |
| usedAt          | timestamp | null until used                       |
| usedByUid       | string    | null until used                       |

A token is **expired** when Timestamp.now() \>= expiresAt. Status is not changed to express expiry.

#### 01-accounts §4.5 mail/{autoId}

Format required by the Trigger Email extension. The function only creates these documents.

| Field           | Type   | Rule                      |
|-----------------|--------|---------------------------|
| to              | string | profile.email (as stored) |
| message.subject | string | From Section 7.1          |
| message.text    | string | From Section 7.1          |
| message.html    | string | From Section 7.1          |

The extension adds a delivery field itself. The app never reads mail.

#### 01-accounts §4.6 Indexes (firestore.indexes.json)

```json
{
"indexes": [
{
"collectionGroup": "verificationTokens",
"queryScope": "COLLECTION",
"fields": [
{ "fieldPath": "profileId", "order": "ASCENDING" },
{ "fieldPath": "purpose", "order": "ASCENDING" },
{ "fieldPath": "status", "order": "ASCENDING" }
]
},
{
"collectionGroup": "verificationTokens",
"queryScope": "COLLECTION",
"fields": [
{ "fieldPath": "profileId", "order": "ASCENDING" },
{ "fieldPath": "status", "order": "ASCENDING" }
]
}
],
"fieldOverrides": []
}
```

### 5.5 Presence: cities, profile fields, `presenceSnapshot`

*Moved here from `docs/features/07-simran.md` §5 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


Only the Cloud Function reads and writes these. Conventions as `01-accounts.md` §4: camelCase, server timestamps, rules deny all.

#### 07-simran §5.1 City reference

`tools/content_pipeline/cities.json`, the source of the app's `city` table, gains a `state` field: an ISO 3166-2 subdivision code such as `IN-DL` or `CA-BC`. The pipeline writes it into `content.db` as `state_code`, and also writes `functions/src/cities.json` (id, country, state) so the app and the server read one list. Every city in it must have a state; the pipeline fails otherwise.

#### 07-simran §5.2 Fields on `profiles/{profileId}`

No new collection. Two fields of the profile (`01-accounts.md` §4.1, amended by §13 D9 and D10) carry everything:

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `cityId` | string | no | A `cities.json` id, set at creation, changed only by a profile update |
| `lastSeenDay` | string | yes | `dayIst` of the last attendance; null until the first. Written only by 6.1, which does not change `updatedAt`. |

#### 07-simran §5.3 Index

```json
{ "collectionGroup": "profiles", "queryScope": "COLLECTION",
  "fields": [ { "fieldPath": "cityId", "order": "ASCENDING" },
              { "fieldPath": "lastSeenDay", "order": "ASCENDING" } ] }
```

#### 07-simran §5.4 `presenceSnapshot/current`

One document, rebuilt by the scheduled function `buildGlobeSnapshot` every `GLOBE_SNAPSHOT_SECONDS`:

1. For each city in `cities.json`, two `count()` aggregation queries on `profiles`: `cityId == city` (counted) and `cityId == city && lastSeenDay == today` (live).
2. Cities with a counted total of 0 are left out.
3. The result is written as below. It replaces the previous document.

| Field | Type | Rule |
| --- | --- | --- |
| `day` | string | `dayIst` it was built for |
| `builtAt` | timestamp | Server time |
| `live` | number | Total live users |
| `counted` | number | Total counted users |
| `countries` | map | `{ "IN": { "l": 480, "c": 950, "s": { "IN-DL": { "l": 25, "c": 40, "k": { "new_delhi": [25, 40] } } } } }`: `l` live, `c` counted, `s` states, `k` cities as `[live, counted]` |

Counting on a schedule rather than keeping counters means no document is written by more than one attendance, so a burst at Amrit Vela cannot run into Firestore's per-document write limit, and the numbers can never drift.

### 5.6 Sangat: groups, goals, members, totals

*Moved here from `docs/features/08-sangat.md` §6 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


Only the Cloud Functions read and write these. Conventions as `01-accounts.md` §4.

**Member key.** `p_{profileId}` for a member with a profile, `u_{uid}` for one without.

#### 08-sangat §6.1 `groups/{groupId}`

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `kind` | string | no | `BUILT_IN` or `CUSTOM` |
| `name` | string | yes | Custom groups: as entered |
| `names` | map | yes | Built-in groups: `{ en, pa, hi }` |
| `creatorKey` | string | yes | Custom groups: `p_{profileId}` |
| `status` | string | no | `ACTIVE`, `INACTIVE` or `DISABLED` |
| `endedOn` | string | yes | `dayIst` it became inactive |
| `endReason` | string | yes | `TARGET_MET`, `END_DATE` or `ADMIN` |
| `currentGoalId` | string | yes | Null until a goal is set |
| `memberCount` | number | no | Active members, kept by the server |
| `inviteCode` | string | yes | Custom groups: current code |
| `inviteExpiresAt` | timestamp | yes | Custom groups |
| `goalTemplate` | map | yes | Built-in groups: `{ type, baniId, target, lengthDays }` for resets (`simranMinutes` null) |
| `createdAt` / `updatedAt` | timestamp | no | Server timestamps |

#### 08-sangat §6.2 `groups/{groupId}/goals/{goalId}`

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `type` | string | no | `BANI` or `SIMRAN` |
| `baniId` | string | yes | `BANI` |
| `simranMinutes` | number | yes | Always null since 2026-10-09: a `SIMRAN` goal counts minutes, every sitting adding its whole minutes (`08-sangat.md` SG-1). `total`, `dayTotals` and a member's `contribution` are then minutes |
| `target` | number | no | 1–1,000,000 |
| `startDay` / `endDay` | string | no | `dayIst`; at most 365 days inclusive |
| `status` | string | no | `ACTIVE`, `COMPLETED` (target met) or `EXPIRED` |
| `total` | number | no | Kept by the server (6.4) |
| `completedAt` | timestamp | yes | When the target was met |
| `sequence` | number | no | 1 for the first goal; built-in resets count up |
| `createdAt` | timestamp | no | Server timestamp |

#### 08-sangat §6.3 `groups/{groupId}/members/{memberKey}`

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `memberKey` | string | no | Same as the document ID |
| `name` | string | yes | Profile name; null for `u_` members. Updated when the profile name changes. |
| `role` | string | no | `CREATOR` or `MEMBER` |
| `status` | string | no | `ACTIVE`, `LEFT` or `REMOVED` |
| `joinedDay` | string | no | `dayIst` of the latest join |
| `contribution` | number | no | Count toward the current goal, kept by the server |
| `sortName` | string | no | Lowercased name, or `~` for `u_` members so they sort last |
| `cityId` | string | yes | The member's profile city (07-simran §5.1), for the group's globe (GG2). Null for `u_` members. Set on create, join and adoption, changed with the profile's city by `sangatProfileSync`, and filled on the member's next counted paath when missing (rows from before 2026-10-17) |
| `lastAddDay` | string | yes | `dayIst` of the member's latest counted paath toward the current goal (CT9), for the globe's green (GG3). Set in the contribution's transaction, never moved backwards; null until the first |
| `updatedAt` | timestamp | no | Server timestamp |

Contributions to earlier goals of a built-in group are kept in `groups/{groupId}/goals/{goalId}/members/{memberKey}` `{ contribution }`, written when the goal ends.

#### 08-sangat §6.4 Totals

- `contributions/{memberKey}_{id}`: one document per received outbox row: `{ memberKey, kind, baniId, durationS, source, day, at, retracted, countedIn: [ "groupId/goalId", ... ], groupIds, countedCount, cityId, createdAt }`. `cityId` (since 2026-10-17) is the caller's profile city when it was received, or null, for the light of GG4. It makes sending idempotent and lets a retraction find what to take back.
- A custom group's goal `total` and the member's `contribution` are incremented in the same transaction as the contribution document.
- A built-in goal could receive thousands of writes a minute, past Firestore's limit of about one write a second on one document. Its total is kept in 20 shards, `groups/{groupId}/goals/{goalId}/shards/{0..19}` `{ count }`, each contribution incrementing one chosen at random, and the scheduled Function `sangatTotals` adds them into `total` once a minute.
- Diary cap (CT4): `contributionCaps/{memberKey}_{groupId}_{dayIst}` `{ diaryCount }` is read and incremented in the same transaction.

#### 08-sangat §6.4a `groups/{groupId}/globe/current` (2026-10-17, GG1–GG9)

One document per group, built by 7.15 when it is older than `GROUP_GLOBE_SECONDS`, never by a phone.

| Field | Type | Rule |
| --- | --- | --- |
| `goalId` | string | The goal it was built for; a different current goal makes it stale |
| `day` | string | `dayIst` it counts "today" for |
| `cities` | map | `cityId` → `[today, members]`: active members with that profile city, and how many of them have `lastAddDay` = `day` |
| `unplaced` | map | `{ today, members }` for active members with no city (`u_` members, and rows not yet filled) |
| `recent` | array | At most `GROUP_ARRIVALS_MAX` `{ cityId \| null, at, amount }`, newest first: contributions counted in `{groupId}/{goalId}` and not retracted, received in the last `GROUP_ARRIVALS_MINUTES` |
| `builtAt` | timestamp | Server time of the build |

**Building it.** A custom group reads its active member rows (at most `CUSTOM_GROUP_MAX_MEMBERS`, fields `cityId` and `lastAddDay` only). A built-in group, too large for that, runs two `count()` aggregations per city of the reference list on its active members (`cityId` =, and `cityId` = with `lastAddDay` =) and takes `unplaced` as `memberCount` less the placed. Both then read `recent` with one query on `contributions` (`groupIds` array-contains, `createdAt` ≥ now − 60 min, newest first, 3 × `GROUP_ARRIVALS_MAX`), keeping the first `GROUP_ARRIVALS_MAX` that are not retracted and whose `countedIn` holds the current goal. Two requests rebuilding at once write the same numbers (FN4). A built-in group runs the "today" count only for cities that have members. `recent[].at` is when the server received the paath (`createdAt`), which is what the hour and the order use. A city not in the reference list counts under `unplaced`. Once a goal has ended its last globe is served as it was, with no rebuild and no arrivals (GG9); if none was stored, one is built once. A retraction does not move `lastAddDay` back, so that member stays green until the day turns.

#### 08-sangat §6.5 Other collections

| Collection | Document | Fields |
| --- | --- | --- |
| `inviteCodes/{code}` | One per live code | `groupId`, `expiresAt` |
| `memberships/{memberKey}` | One per member key | `groupIds` (array of active memberships), `updatedAt`: answers "my groups" in one read |
| `groupLimits/{profileId}` | Only where the admin raised it | `limit`, `setBy`, `updatedAt` |
| `badgeFacts/{memberKey}` | One per member key with a fact | `goalsReached`, `joins`, `updatedAt`: the two Sangat facts for Sevadar and Satsangi (`12-badges.md` §5), added 2026-10-08 |
| `groupReports/{groupId}_{memberKey}` | One per reporter per group | `groupId`, `memberKey`, `reason`, `note`, `status` (`OPEN`, `ACTIONED`, `DISMISSED`), `createdAt` |

#### 08-sangat §6.6 Indexes

- `members` (collection group): `status` ascending, `sortName` ascending, for the member list.
- `members` (collection): `status`, `cityId`; `status`, `cityId`, `lastAddDay`; and `status`, `lastAddDay`, ascending, for a built-in group's globe counts (6.4a: the last gives today's count of members with no city).
- `contributions`: `groupIds` array-contains, `createdAt` descending, for a group's recent arrivals (6.4a).
- `groups`: `kind` ascending, `status` ascending, for the built-in list and the admin website.
- `groupReports`: `status` ascending, `createdAt` descending.

### 5.7 Weekly backup

*Moved here from `docs/features/10-backup.md` §5 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


#### 10-backup §5.1 Conventions

The same as the Profile PRD (`01-accounts.md` §4): only the Cloud Function reads and writes these documents, field names are camelCase, enums are UPPER_SNAKE, and server times are Firestore `Timestamp`s set with `FieldValue.serverTimestamp()`. Row fields copy the local columns of `04-goals.md` §5 one to one, with DATETIME values as Firestore `Timestamp`s and `YYYY-MM-DD` dates as strings.

Everything sits under the owning profile, so a profile restore (which moves `ownerUid`) carries the backup with it and nothing has to be re-keyed.

**Why weeks, not one document per row:** Firestore bills reads and writes per document, and reads are the meter that matters (`00-platform.md` §0.3). A year of diary is 52 documents to restore rather than several thousand, and a weekly backup writes one or two week documents rather than one per paath.

#### 10-backup §5.2 Paths

```text
profiles/{profileId}
  backupMeta/manifest
  backupGoals/{goalId}
  backupWeeks/{weekId}
  backupBadges/all          (12-badges.md §6.2)
```

#### 10-backup §5.3 `profiles/{profileId}/backupMeta/manifest`

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `lastBackupAt` | timestamp | yes | Server time the last backup request completed. Null before the first. |
| `lastBackupUid` | string | yes | uid that made it |
| `goalIds` | array of string | no | Every `backupGoals` document ID |
| `weeks` | map of `weekId` → number | no | Row count per week document |
| `rowCount` | number | no | Total rows across all documents |
| `schemaVersion` | number | no | 1 |
| `updatedAt` | timestamp | no | Server timestamp on every write |

#### 10-backup §5.4 `profiles/{profileId}/backupGoals/{goalId}`

One document per goal, holding the goal and all its items.

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `goal` | map | no | The `goals` row: `id`, `startDate`, `completedOn`, `createdAt`, `updatedAt` |
| `items` | map of `itemId` → map | no | Each `goalItems` row with every column of `04-goals.md` §5.3 |
| `serverUpdatedAt` | timestamp | no | Server timestamp on every write |

#### 10-backup §5.5 `profiles/{profileId}/backupWeeks/{weekId}`

One document per week that has any diary row. `weekId` is the Sunday of the row's `localDate`.

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `weekId` | string | no | Same as the document ID |
| `completions` | map of `id` → map | no | `completions` rows whose `localDate` falls in the week: `id`, `localDate`, `baniId`, `slot`, `source`, `completedAt`, `updatedAt`, `deletedAt` |
| `simranSessions` | map of `id` → map | no | `simranSessions` rows in the week: `id`, `localDate`, `startedAt`, `durationS`, `completed`, `count`, `source`, `updatedAt`, `deletedAt` |
| `serverUpdatedAt` | timestamp | no | Server timestamp on every write |

A busy week holds a few hundred rows of about 200 bytes each, far below Firestore's 1 MiB document limit. The function refuses a write that would take a document over 900 KB (`413 BACKUP_TOO_LARGE`, 6.2).

#### 10-backup §5.6 Indexes and rules

No composite index is needed: every read is by document ID. The rules stay deny-all (`01-accounts.md` §10.1).

### 5.8 Badge facts: `badgeFacts`

*Moved here from `docs/features/12-badges.md` §5.1 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


| Field | Type | Rule |
| --- | --- | --- |
| `goalsReached` | array of string | `"{groupId}/{goalId}"` of each goal reached (3.1). Stops growing at 3, which is all a badge needs. |
| `joins` | array of string | `"{groupId}/{memberKey}"` of each first join to a custom group this member created. Stops growing at 5. |
| `updatedAt` | timestamp | Server timestamp |

Arrays of keys, not counters, so a retried write adds nothing twice.

- **SF1. Goals reached.** A Firestore-triggered Function, `badgeGoalReached`, runs when a goal's `status` becomes `COMPLETED` (`08-sangat.md` §6.2). It reads the goal's members with `contribution` ≥ 1 (for a built-in group, the per-goal member documents written when the goal ends, §6.3 there), and adds the goal key to each one's `goalsReached` with `arrayUnion`, skipping any already holding 3. It writes only `badgeFacts`, never the goal it was triggered by, and is idempotent (`00-platform.md` Functions contract).
- **SF2. Joins.** `POST /api/v1/sangat/join` (`08-sangat.md` 7.8) gains one step in its transaction: when a member document is created for the first time in a custom group, the creator's `badgeFacts.joins` gets `"{groupId}/{memberKey}"` by `arrayUnion`, unless it already holds 5. A member who leaves and joins again is the same key and adds nothing.
- **SF3. Adoption.** When a profile is created, `badgeFacts/u_{uid}` is merged into `badgeFacts/p_{profileId}` in the same transaction as the other `u_` documents (`08-sangat.md` MB2, `01-accounts.md` §13 D12).

### 5.9 Badge backup: `backupBadges`

*Moved here from `docs/features/12-badges.md` §6.2 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


`profiles/{profileId}/backupBadges/all`: one document, `{ badges: { [badgeId]: row }, serverUpdatedAt }`. Ten rows at most. The server merge for a badge keeps the earlier `earnedOn`, and `announcedAt` when either side has one.

`GET /api/v1/backup/badges` returns `{ "badges": [ ... ] }`, one read.

### 5.10 Device tokens: `fcmTokens`

*Moved here from `docs/features/02-notifications.md` §8.1 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


- **FT1.** The app uses `firebase_messaging`. It registers a token only when the person has a profile **and** belongs to at least one group, and removes it when they leave their last group, switch Sangat notifications off, or lose the profile (`markNone()`).
- **FT2.** `POST /api/v1/devices/fcm-token` with `{ "token": "...", "locale": "pa", "tz": "Asia/Kolkata" }`, also called on `onTokenRefresh`, on a language change and on a time-zone change. `DELETE /api/v1/devices/fcm-token` removes it. Both follow `01-accounts.md` §6.0 and return `404 NO_PROFILE` without a profile.
- **FT3.** A profile restore (`01-accounts.md` §6.5) deletes the old uid's token document, so the old phone stops receiving.

`fcmTokens/{uid}`, written only by the `api` function:

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `profileId` | string | no | Owner of the uid (`owners/{uid}`) |
| `token` | string | no | The FCM registration token |
| `locale` | string | no | `pa`, `hi` or `en` |
| `tz` | string | no | IANA time zone of the phone |
| `utcOffsetMin` | number | no | The zone's current UTC offset in minutes, refreshed with each call, used to find who is at 21:00 |
| `updatedAt` | timestamp | no | Server timestamp |

Index: `utcOffsetMin` ascending, for the hourly dispatcher.

### 5.11 `firestore.rules`: deny all client access

*Moved here from `docs/features/01-accounts.md` §10.1 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


```text
rules_version = '2';
service cloud.firestore {
match /databases/{database}/documents {
match /{document=**} {
allow read, write: if false;
}
}
}
```

### 5.12 `firebase.json`

*Moved here from `docs/features/01-accounts.md` §10.2 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


The ignore list must not contain \*\*/.\*, otherwise .well-known/assetlinks.json is not deployed.

```json
{
"firestore": { "rules": "firestore.rules", "indexes": "firestore.indexes.json" },
"functions": [{ "source": "functions", "codebase": "default", "runtime": "nodejs20" }],
"hosting": {
"public": "hosting/public",
"ignore": ["firebase.json", "**/node_modules/**"],
"rewrites": [
{ "source": "/api/**", "function": { "functionId": "api", "region": "asia-south1" } },
{ "source": "/verify", "destination": "/verify/index.html" }
],
"headers": [
{ "source": "/.well-known/assetlinks.json", "headers": [{ "key": "Content-Type", "value": "application/json" }] }
]
}
}
```


## 6. The API

One HTTPS Cloud Function, `api` (Express, `asia-south1`), reached through the
Hosting rewrite `/api/**`. Every request carries the install's Firebase ID
token (`Authorization: Bearer`); the admin routes additionally require the
admin's Google token (`11-admin.md` AC3). The common rules — errors, rate
limits, the 401 retry, timeouts — are `01-accounts.md` §6.0, here in §6.1.

| Area | Endpoints | Here |
|---|---|---|
| Profile and links | `GET/POST /profile`, `PATCH /profile`, `PATCH /profile/email`, `POST /profile/verification-email`, `POST /profile/restore-request`, `POST /tokens/verify` | §6.1 (`PATCH /profile` is `01-accounts.md` §13.8) |
| Presence | `POST /presence/attendance`, `GET /presence/globe` | §6.2 |
| Sangat | Groups, joins, invites, goals, members, reports, the outbox | §6.3 |
| Backup | `GET /backup/manifest`, `POST /backup`, `GET /backup/goals`, `GET /backup/weeks`, `GET /backup/badges` | §6.4, §5.9 |
| Badges | `GET /badges/sangat` | §6.5 |
| Devices | `POST` and `DELETE /devices/fcm-token` | §5.10 |
| Admin | `/admin/*` | §6.6 |

### 6.1 Profile, tokens and the common rules

*Moved here from `docs/features/01-accounts.md` §6 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


Six endpoints under API_BASE_URL (https://{{FIREBASE_PROJECT_ID}}.web.app/api/v1). All request and response bodies are JSON (Content-Type: application/json).

#### 01-accounts §6.0 Common rules

**Authentication middleware (all endpoints):** read header Authorization: Bearer \<idToken\>; verify with admin.auth().verifyIdToken(idToken); set callerUid = decoded.uid. Missing or invalid → 401 UNAUTHENTICATED.

**Error body (every non-2xx):**

```json
{ "error": { "code": "ERROR_CODE", "message": "Human readable text", "fields": { "name": "..." }, "retryAfterSeconds": 42, "purpose": "VERIFY_EMAIL" } }
```

fields only for VALIDATION_ERROR; retryAfterSeconds only for RATE_LIMITED; purpose only for token errors. Omit keys that do not apply.

**Profile DTO (returned wherever profile appears):**

```json
{ "profileId": "abc", "name": "Harpreet Kaur", "email": "Harpreet@Example.com", "phone": "+919876543210", "cityId": "amritsar", "emailVerified": false, "createdAt": "2026-09-28T10:00:00.000Z" }
```

phone may be null. Never return ownerUid, emailNormalized, emailQuota or token data.

**Unexpected exceptions:** log with logger.error, respond 500 INTERNAL with message Something went wrong.

**Email quota check** (used by 6.3 and 6.4, evaluated inside the transaction on the target profile's emailQuota, now = Timestamp.now()):

1.  If lastSentAt != null and now - lastSentAt \< 60 s → 429 RATE_LIMITED, retryAfterSeconds = 60 - elapsed (rounded up).

2.  If windowStartAt == null or now - windowStartAt \>= 86400 s → the new window starts: windowStartAt = now, countInWindow = 1.

3.  Else if countInWindow \>= 5 → 429 RATE_LIMITED, retryAfterSeconds = 86400 - (now - windowStartAt) (rounded up).

4.  Else countInWindow = countInWindow + 1.

5.  Always set lastSentAt = now when the send proceeds.

**Token creation** (used by 6.3 and 6.4): rawToken = crypto.randomBytes(32).toString("base64url") (43 characters); tokenHash = sha256Hex(rawToken); link = VERIFY_LINK_BASE + "?token=" + rawToken. Before creating, in the same transaction, query verificationTokens where profileId == X, purpose == P, status == "ACTIVE" and set each to SUPERSEDED. Only the newest link for a purpose works.

#### 01-accounts §6.1 GET /api/v1/profile — read caller's profile (Req 6, 9)

Logic: read owners/{callerUid}. If missing → 404. Else read profiles/{profileId} and return it. If the profile document is missing or its ownerUid != callerUid, delete owners/{callerUid} and return 404.

| Status | Body                                       |
|--------|--------------------------------------------|
| 200    | { "profile": \<Profile DTO\> }             |
| 404    | error NO_PROFILE, message No profile found |
| 401    | error UNAUTHENTICATED                      |

#### 01-accounts §6.2 POST /api/v1/profile — create profile (Req 2, 3, 8)

Request: { "name": "...", "email": "...", "phone": "9876543210" \| "" \| null, "cityId": "..." }

Logic:

1.  Normalize and validate per Section 5. Any failure → 400 VALIDATION_ERROR with every failing field in fields (key = field name, value = the Section 5 message).

2.  Compute emailNormalized and emailHash.

3.  In one Firestore transaction: read owners/{callerUid} → exists → 409 PROFILE_ALREADY_EXISTS. Read emailIndex/{emailHash} → exists → 409 EMAIL_EXISTS. Else create profiles/{newId} (Section 4.1 defaults), emailIndex/{emailHash}, owners/{callerUid}.

4.  Return 201 with the new profile (read it back after commit so timestamps are resolved).

| Status    | Body                                                                          |
|-----------|-------------------------------------------------------------------------------|
| 201       | { "profile": \<Profile DTO\> }                                                |
| 400       | error VALIDATION_ERROR + fields                                               |
| 409       | error EMAIL_EXISTS, message An account with this email already exists         |
| 409       | error PROFILE_ALREADY_EXISTS, message A profile already exists on this device |
| 401 / 500 | per 6.0                                                                       |

EMAIL_EXISTS must not return any data of the existing profile.

#### 01-accounts §6.3 POST /api/v1/profile/verification-email — send verify link (Req 4)

Request body: {}.

Logic, in one transaction: read owners/{callerUid} → missing → 404 NO_PROFILE. Read the profile. If emailVerified == true → 409 EMAIL_ALREADY_VERIFIED. Run the quota check. Supersede active VERIFY_EMAIL tokens, create the new token doc (purpose VERIFY_EMAIL, requestingUid = callerUid, TTL 86400 s), update emailQuota and updatedAt, create the mail doc with template 7.1-A.

| Status    | Body                                                                                         |
|-----------|----------------------------------------------------------------------------------------------|
| 200       | { "result": "VERIFICATION_EMAIL_SENT", "email": "\<profile.email\>", "cooldownSeconds": 60 } |
| 404       | error NO_PROFILE                                                                             |
| 409       | error EMAIL_ALREADY_VERIFIED, message Your email is already verified                         |
| 429       | error RATE_LIMITED, message Please wait before requesting another email + retryAfterSeconds  |
| 401 / 500 | per 6.0                                                                                      |

#### 01-accounts §6.4 POST /api/v1/profile/restore-request — send restore link (Req 8)

Request: { "email": "..." }

Logic:

1.  Validate email per Section 5 → failure → 400 VALIDATION_ERROR (fields.email).

2.  In one transaction: read owners/{callerUid} → exists → 409 DEVICE_HAS_PROFILE. Read emailIndex/{emailHash} → missing → 404 EMAIL_NOT_FOUND. Read the profile. Run the quota check. Supersede active RESTORE_PROFILE tokens for that profile, create the token (purpose RESTORE_PROFILE, requestingUid = callerUid, TTL 3600 s), update emailQuota and updatedAt, create the mail doc with template 7.1-B addressed to the stored profile.email.

| Status    | Body                                                                                    |
|-----------|-----------------------------------------------------------------------------------------|
| 200       | { "result": "RESTORE_EMAIL_SENT", "email": "\<profile.email\>", "cooldownSeconds": 60 } |
| 400       | error VALIDATION_ERROR                                                                  |
| 404       | error EMAIL_NOT_FOUND, message No account found for this email                          |
| 409       | error DEVICE_HAS_PROFILE, message A profile already exists on this device               |
| 429       | error RATE_LIMITED + retryAfterSeconds                                                  |
| 401 / 500 | per 6.0                                                                                 |

#### 01-accounts §6.5 POST /api/v1/tokens/verify — consume a link (Req 4, 5, 8)

Request: { "token": "\<rawToken\>" }

Logic:

1.  If token is not a string matching ^\[A-Za-z0-9\_-\]{43}\$ → 400 INVALID_REQUEST.

2.  tokenHash = sha256Hex(token). In one transaction read verificationTokens/{tokenHash}.

3.  Missing, or status == SUPERSEDED → 404 TOKEN_INVALID (include purpose when the doc exists).

4.  Read profiles/{token.profileId} (always exists; no delete feature).

5.  **If purpose == VERIFY_EMAIL:**

    - status == USED: if profile emailVerified == true → 200 EMAIL_ALREADY_VERIFIED; else 409 TOKEN_ALREADY_USED.

    - Expired → 410 TOKEN_EXPIRED.

    - Profile emailNormalized != token.emailNormalized → 404 TOKEN_INVALID.

    - Else set profile emailVerified = true, emailVerifiedAt = serverTimestamp (only if currently null), updatedAt; set token status = USED, usedAt, usedByUid = callerUid. Commit, then return 200 EMAIL_VERIFIED.

    - isOwner = (profile.ownerUid == callerUid). Include profile only when isOwner is true.

6.  **If purpose == RESTORE_PROFILE:**

    - status == USED → 409 TOKEN_ALREADY_USED.

    - Expired → 410 TOKEN_EXPIRED.

    - Profile emailNormalized != token.emailNormalized → 404 TOKEN_INVALID.

    - token.requestingUid != callerUid → 403 RESTORE_WRONG_DEVICE.

    - owners/{callerUid} exists → 409 DEVICE_HAS_PROFILE.

    - Else: oldUid = profile.ownerUid; delete owners/{oldUid}; create owners/{callerUid}; update profile ownerUid = callerUid, emailVerified = true, emailVerifiedAt (only if null), restoredAt, updatedAt; set this token USED, usedAt, usedByUid; set every other ACTIVE token of this profile (any purpose) to SUPERSEDED. Commit, then return 200 PROFILE_RESTORED with profile.

| Status    | Body                                                                                                                    |
|-----------|-------------------------------------------------------------------------------------------------------------------------|
| 200       | { "result": "EMAIL_VERIFIED", "purpose": "VERIFY_EMAIL", "isOwner": true, "profile": \<DTO, only if isOwner\> }         |
| 200       | { "result": "EMAIL_ALREADY_VERIFIED", "purpose": "VERIFY_EMAIL", "isOwner": bool, "profile": \<DTO, only if isOwner\> } |
| 200       | { "result": "PROFILE_RESTORED", "purpose": "RESTORE_PROFILE", "isOwner": true, "profile": \<DTO\> }                     |
| 400       | error INVALID_REQUEST, message Invalid link                                                                             |
| 404       | error TOKEN_INVALID, message This link is invalid or has been replaced by a newer link                                  |
| 409       | error TOKEN_ALREADY_USED, message This link has already been used                                                       |
| 410       | error TOKEN_EXPIRED, message This link has expired                                                                      |
| 403       | error RESTORE_WRONG_DEVICE, message Open this link on the phone where you requested the restore                         |
| 409       | error DEVICE_HAS_PROFILE                                                                                                |
| 401 / 500 | per 6.0                                                                                                                 |

Note: clicking a restore link proves ownership of the email, so it also sets emailVerified = true. After a restore, the old install loses access; its next GET returns 404 (Section 9).

#### 01-accounts §6.6 PATCH /api/v1/profile/email — change unverified email (Req 10)

The email can be changed only while emailVerified == false. A successful change also sends a verification link to the new email, so the quota check applies to the change itself.

Request: { "email": "\<new email\>" }

Logic (Firestore transactions must do all reads before any write):

1.  Normalize and validate email per Section 5 → failure → 400 VALIDATION_ERROR (fields.email).

2.  In one transaction, reads: owners/{callerUid} → missing → 404 NO_PROFILE. Read the profile. emailVerified == true → 409 EMAIL_ALREADY_VERIFIED. New emailNormalized equals the profile's emailNormalized → 400 EMAIL_UNCHANGED. Read emailIndex/{newEmailHash} → exists → 409 EMAIL_EXISTS. Run the quota check (6.0). Query all ACTIVE tokens of this profile (any purpose).

3.  Same transaction, writes: delete emailIndex/{oldEmailHash}; create emailIndex/{newEmailHash} (profileId, createdAt); update profile email (trimmed), emailNormalized, emailQuota, updatedAt (emailVerified stays false); set every queried ACTIVE token to SUPERSEDED; create a new VERIFY_EMAIL token for the new email (requestingUid = callerUid, TTL 86400 s); create the mail doc with template 7.1-A addressed to the new email.

4.  Return 200 with the updated profile (read back after commit).

| Status    | Body                                                                             |
|-----------|----------------------------------------------------------------------------------|
| 200       | { "result": "EMAIL_CHANGED", "profile": \<Profile DTO\>, "cooldownSeconds": 60 } |
| 400       | error VALIDATION_ERROR + fields.email                                            |
| 400       | error EMAIL_UNCHANGED, message This is already your email                        |
| 404       | error NO_PROFILE                                                                 |
| 409       | error EMAIL_ALREADY_VERIFIED, message A verified email can't be changed          |
| 409       | error EMAIL_EXISTS, message An account with this email already exists            |
| 429       | error RATE_LIMITED + retryAfterSeconds                                           |
| 401 / 500 | per 6.0                                                                          |

The old email is released at once: another install may create a profile with it. Links sent to the old email stop working (superseded, and 6.5 checks emailNormalized).

### 6.2 Presence

*Moved here from `docs/features/07-simran.md` §6 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


Both endpoints follow `01-accounts.md` §6.0 (Bearer ID token, error body, `401`, `500`).

#### 07-simran §6.1 `POST /api/v1/presence/attendance`

Request body: `{}`.

1. Read `owners/{callerUid}`; missing → `404 NO_PROFILE`. Read the profile.
2. If `lastSeenDay` is already today, return 200 without writing.
3. Otherwise set `lastSeenDay` = today. `updatedAt` is not changed.

| Status | Body |
| --- | --- |
| 200 | `{ "result": "ATTENDANCE_MARKED", "day": "2026-10-07" }` |
| 404 | `NO_PROFILE` |

Cost: 2 reads and at most 1 write per user per day. The app's local flag (AT1) means a second call that day is not made at all.

#### 07-simran §6.2 `GET /api/v1/presence/globe`

Returns the snapshot of 5.4 exactly as stored, with `builtAt` as an ISO string. A function instance keeps the snapshot in memory for `GLOBE_CACHE_SECONDS`, so the endpoint reads Firestore at most once a minute per instance, at most 10 instances (`00-platform.md` §0.1), whatever the number of viewers. City names and positions are never sent: the app has them in `content.db`.

| Status | Body |
| --- | --- |
| 200 | The snapshot, gzip-compressed |
| 503 | `GLOBE_NOT_READY` when no snapshot has been built yet |

#### 07-simran §6.3 Cost

| Item | Firestore cost |
| --- | --- |
| Attendance | 2 reads + ≤ 1 write per user per day |
| Snapshot | 2 aggregations per city every 2 minutes (each 1 read per 1,000 users matched, minimum 1): about 2 × cities × 720 reads a day |
| Globe reads | ≤ 10 instances × 1 read a minute |

### 6.3 Sangat, and its scheduled and triggered Functions

*Moved here from `docs/features/08-sangat.md` §7 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


All under `/api/v1/sangat`, following `01-accounts.md` §6.0. Every endpoint works with an anonymous ID token unless it says it needs a profile. Errors use the shared error body; codes are listed per endpoint.

| # | Method and path | Body | Does | Errors |
| --- | --- | --- | --- | --- |
| 7.1 | `GET /groups/mine` | — | Active and inactive groups of the caller's member key, with name, goal, total, percentage, days left | — |
| 7.2 | `GET /groups/built-in` | — | The built-in groups with names in all three languages, current goal, total, member count, and whether the caller is a member | — |
| 7.3 | `GET /groups/{groupId}` | — | Group, current goal, today's total, member count, the first 50 members (VS4), and the caller's role. Members only for custom groups. | `404 GROUP_NOT_FOUND` (also for a disabled group or a non-member) |
| 7.4 | `POST /groups` | `{ name }` | Creates a custom group with the caller as creator. Needs a profile. | `400 VALIDATION_ERROR`, `404 NO_PROFILE`, `409 GROUP_LIMIT_REACHED` |
| 7.5 | `POST /groups/{groupId}/goal` | `{ type, baniId?, target, endDay }` (a `simranMinutes` from an older app is ignored) | Sets the goal once. Creator only. | `400 VALIDATION_ERROR`, `403 NOT_CREATOR`, `409 GOAL_ALREADY_SET` |
| 7.6 | `PATCH /groups/{groupId}/goal` | `{ endDay }` | Changes the end day (CG4, CG7). Creator only. | `400 VALIDATION_ERROR`, `403 NOT_CREATOR`, `409 GROUP_INACTIVE` |
| 7.7 | `DELETE /groups/{groupId}` | — | Deletes when the creator is the only member (CG8) | `403 NOT_CREATOR`, `409 GROUP_HAS_MEMBERS` |
| 7.8 | `POST /join` | `{ code }` | Joins by invite (IV8) | `404 CODE_INVALID`, `409 GROUP_FULL`, `409 GROUP_INACTIVE` |
| 7.9 | `POST /groups/{groupId}/join` and `POST /groups/{groupId}/leave` | — | Joins or leaves a built-in group; leave also works for custom-group members other than the creator | `404 GROUP_NOT_FOUND`, `409 CREATOR_CANNOT_LEAVE` |
| 7.10 | `DELETE /groups/{groupId}/members/{memberKey}` | — | Removes a member (MB4). Creator only. | `403 NOT_CREATOR`, `404 MEMBER_NOT_FOUND` |
| 7.11 | `POST /groups/{groupId}/invite` | `{ reset?: true }` | Returns `{ code, link, expiresAt }`, making a new code when expired or when the creator asks to reset | `403 NOT_CREATOR` (reset only), `409 GROUP_INACTIVE` |
| 7.12 | `POST /contributions` | `{ items: [ { id, kind, baniId?, durationS?, source, at, action } ] }`, at most 200 | For each item not seen before: finds the caller's active groups whose goal it matches (CT1–CT4, CT7), records it (6.4) and updates totals. A `RETRACT` takes back what its `ADD` counted. Returns the ids processed. | `400 VALIDATION_ERROR` |
| 7.15 | `GET /groups/{groupId}/globe` | — | The group's globe (6.4a) as `{ day, builtAt, cities: { cityId: [today, members] }, unplaced: { today, members }, recent: [ { cityId, at, amount } ] }`, building it again first when it is older than `GROUP_GLOBE_SECONDS` or was built for another goal or day. Not personalised: the app takes the caller off (GG3). Members only for custom groups, as 7.3 | `404 GROUP_NOT_FOUND` |
| 7.13 | `POST /groups/{groupId}/report` | `{ reason, note? }` | Stores the report and emails support (RP1–RP3) | `400 VALIDATION_ERROR`, `404 GROUP_NOT_FOUND` |

Success bodies return the same shapes the app caches (5.2). Profile creation (`01-accounts.md` §6.2) gains one step: within its transaction, every `u_{callerUid}` membership, contribution, cap and `badgeFacts` document is rewritten under `p_{profileId}` (MB2, `12-badges.md` SF3). Joining (7.8) also records the join for the creator's Satsangi badge (`12-badges.md` SF2), and `badgeGoalReached` runs when a goal is completed (SF1).

#### 08-sangat §7.14 Scheduled and triggered Functions

All follow `00-platform.md` §0.1 (`maxInstances: 10`, idempotent, never writing their own trigger).

| Function | Trigger | Does |
| --- | --- | --- |
| `sangatTotals` | Every minute | Adds each active built-in goal's shards into `total`; marks a goal `COMPLETED` when `total` reaches `target` |
| `sangatRollover` | 00:05 IST daily | Expires goals past `endDay`; makes custom groups `INACTIVE` (CG6); starts the next goal of each built-in group whose goal completed or expired (BI4) |
| `sangatProfileSync` | Profile name change | Updates `name` and `sortName` on that member's rows |
| `sangatMilestone`, `sangatDispatch` | As `02-notifications.md` §8.2 | Sangat notifications |

### 6.4 Weekly backup

*Moved here from `docs/features/10-backup.md` §6 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


All endpoints are under `API_BASE_URL` (`/api/v1`) and follow `01-accounts.md` §6.0: Bearer ID token, the error body, `401 UNAUTHENTICATED` and `500 INTERNAL`. Every endpoint first reads `owners/{callerUid}`; when it is missing, or its profile's `ownerUid` is not the caller, it returns `404 NO_PROFILE`.

#### 10-backup §6.1 `GET /api/v1/backup/manifest`

Returns the manifest, or an empty one when no backup exists yet. 2 reads (owner and manifest).

| Status | Body |
| --- | --- |
| 200 | `{ "lastBackupAt": "2026-10-04T00:31:12.000Z" \| null, "goalIds": [...], "weeks": { "2026-09-27": 41 }, "rowCount": 412 }` |
| 404 | `NO_PROFILE` |

#### 10-backup §6.2 `POST /api/v1/backup`

Request:

```json
{
  "goals": [ { "goal": { ... }, "items": [ { ... } ] } ],
  "completions": [ { ... } ],
  "simranSessions": [ { ... } ],
  "badges": [ { ... } ],
  "final": true
}
```

Logic:

1. Validate. Every row has a UUID `id` and the fields of `04-goals.md` §5 with their types and enum values. More than `BACKUP_MAX_ROWS_PER_REQUEST` rows, or any invalid row, returns `400 VALIDATION_ERROR` with `fields` naming the first bad row, and nothing is written.
2. Rate limit: over `BACKUP_RATE_LIMIT` returns `429 RATE_LIMITED` with `retryAfterSeconds`.
3. Group the rows by target document: one per goal, and one per `weekId`.
4. For each target document, in a transaction: read it, merge every row by BK9, refuse with `413 BACKUP_TOO_LARGE` if the result would exceed 900 KB, and write it.
5. Update the manifest: `goalIds`, `weeks` row counts, `rowCount`, `updatedAt`. When `final` is true, also set `lastBackupAt` and `lastBackupUid`.

| Status | Body |
| --- | --- |
| 200 | `{ "result": "BACKUP_SAVED", "rowsReceived": 412, "documentsWritten": 3, "lastBackupAt": "..." \| null }` (`lastBackupAt` only when `final` is true) |
| 400 | `VALIDATION_ERROR` + `fields` |
| 404 | `NO_PROFILE` |
| 413 | `BACKUP_TOO_LARGE`, message `This week's backup is too large` |
| 429 | `RATE_LIMITED` + `retryAfterSeconds` |

#### 10-backup §6.3 `GET /api/v1/backup/goals`

Returns every `backupGoals` document: `{ "goals": [ { "goal": {...}, "items": [...] } ] }`. One read per goal.

#### 10-backup §6.4 `GET /api/v1/backup/weeks?from={weekId}&limit={n}`

Returns up to `n` week documents (`n` ≤ `RESTORE_PAGE_WEEKS`), oldest first, starting at `from`: `{ "weeks": [ { "weekId": "...", "completions": [...], "simranSessions": [...] } ], "next": "{weekId}" | null }`. The app pages until `next` is null.

#### 10-backup §6.4a `GET /api/v1/backup/badges`

Returns `{ "badges": [ ... ] }` from `backupBadges/all`, one read. The restore calls it after the weeks; merging and the rule that a restore never announces a badge are `12-badges.md` §6.3.

#### 10-backup §6.5 Cost per user

| Operation | Firestore reads | Firestore writes |
| --- | --- | --- |
| A normal weekly backup (one week and one goal changed) | 2 + 2 documents read for the merge | 3 (week, goal, manifest) |
| Restore of one year | 2 + goals + 52 | none |

### 6.5 Badges

*Moved here from `docs/features/12-badges.md` §5.2 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


Profile needed. Reads `badgeFacts/{callerMemberKey}`: one read.

| Status | Body |
| --- | --- |
| 200 | `{ "goalsReached": 2, "joins": 5 }` (array lengths; 0 when the document does not exist) |
| 404 | `NO_PROFILE` |

### 6.6 Admin

*Moved here from `docs/features/11-admin.md` §5 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


All under `/api/v1/admin`, admin-only (AC3), following `01-accounts.md` §6.0.

| Method and path | Does |
| --- | --- |
| `GET /dashboard` | The figures of 4.1 |
| `GET /groups?kind=&status=` | Groups for 4.2 and 4.3, 50 at a time with a cursor |
| `POST /groups/built-in` | Create a built-in group `{ names, goalTemplate }` |
| `PATCH /groups/{groupId}` | Edit names or goal template (the running goal takes the template's target and length, 11-admin §4.2); set `status` `ACTIVE` or `DISABLED` |
| `POST /groups/{groupId}/start` | Start a built-in group's first goal |
| `DELETE /groups/{groupId}` | Delete a group `{ confirmName }` |
| `GET /groups/{groupId}/history` | Past goals |
| `GET /reports?status=` | Reports, newest first |
| `PATCH /reports/{reportId}` | `{ status: "DISMISSED" \| "ACTIONED" }` |
| `GET /people?email=` | The profile of 4.4 |
| `PUT /people/{profileId}/group-limit` | `{ limit }` |
| `GET /banis` | Bani IDs and names for the goal form |

Errors: `403 NOT_ADMIN`, `404 NOT_FOUND`, `400 VALIDATION_ERROR`, `409 CONFIRM_MISMATCH`.


## 7. Scheduled and triggered Functions

### 7.1 Every Function besides `api`

All obey the contract of §5.3: `maxInstances: 10`, `minInstances: 0`,
idempotent, never writing what triggers them, an emulator test that runs
each twice.

| Function | Trigger | Does | Defined in |
|---|---|---|---|
| `sangatTotals` | Every minute | Adds built-in goals' shards into `total`; marks a goal completed at its target | §6.3 (`08-sangat.md` §7.14) |
| `sangatRollover` | 00:05 IST daily | Expires goals past their end day, makes ended custom groups inactive, starts built-in groups' next goal | §6.3 |
| `sangatProfileSync` | Profile name change | Updates the member's name on their rows | §6.3 |
| `sangatDispatch` | Hourly | The 21:00 digest, the creator's 20:00 new-members message, waiting milestone notices | §7.2 |
| `sangatMilestone` | Firestore update | Milestone notices at 25/50/75/100 % | §7.2 |
| `badgeGoalReached` | A goal's `status` becomes `COMPLETED` | Adds the goal to each contributor's `badgeFacts.goalsReached`; joins are counted inside the join transaction | `12-badges.md` SF1–SF2, §5.8 |
| `buildGlobeSnapshot` | Every `GLOBE_SNAPSHOT_SECONDS` | Rebuilds `presenceSnapshot/current` from `count()` queries on `profiles` | §5.5 |

The earlier list of Functions (`onMemberWrite`, `setRole`, `approveListing`,
`expirePresence`, `healAdminless` and the rest) belonged to the retired
design and is not built.

### 7.2 Notification Functions

*Moved here from `docs/features/02-notifications.md` §8.2 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


All Functions follow `00-platform.md` §0.1: `maxInstances: 10`, `minInstances: 0`, idempotent, never writing the document that triggers them.

| Function | Trigger | Does |
| --- | --- | --- |
| `sangatDispatch` | Cloud Scheduler, every hour at :00 | Finds tokens whose local time is now 21:00 and sends each member the digest (5.5-A, C in the final two days, or F for a group that has ended) for each of their groups (SG2, SG4, SG8). At 20:00 local, sends creators 5.5-E for members who joined since the last run (SG7). Also delivers milestone notices waiting for a member's 07:00 (SG3). |
| `sangatMilestone` | Firestore `onDocumentUpdated` on the group's progress document, which the Sangat feature's counting Function maintains | When the percentage crosses 25, 50, 75 or 100, creates `sangatNotices/{groupId}_{goalId}_{milestone}` with create-if-absent (so it is sent once), then sends 5.5-B or D at once to members whose local time is 07:00–20:59, and leaves the rest for `sangatDispatch`. |

### 7.3 Notification cost

*Moved here from `docs/features/02-notifications.md` §8.4 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


| Item | Firestore |
| --- | --- |
| Token registration | 2 reads + 1 write per change (profile and owner check, then the token) |
| Hourly dispatch | 1 query over the tokens at 21:00 that hour, plus 1 read per group they belong to |
| Milestone | 1 read of the group's members' tokens + 1 create per milestone |

FCM itself does not bill.


## 8. Email links, App Links, Hosting and the Android build

Four things must agree or Android silently opens a browser instead of the
app: the `autoVerify` intent filter, both hosts declared (`web.app` and
`firebaseapp.com`), the SHA-256 in `assetlinks.json` matching the key CI
signs with, and that file being **deployed** (`firebase.json` must not ignore
dotfiles). Three are held by tests; the deploy is by hand. Only the release
fingerprint is listed (`01-accounts.md` D6).

### 8.1 Digital Asset Links

*Moved here from `docs/features/01-accounts.md` §7.2 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


```json
[
{
"relation": ["delegate_permission/common.handle_all_urls"],
"target": {
"namespace": "android_app",
"package_name": "{{ANDROID_PACKAGE_NAME}}",
"sha256_cert_fingerprints": ["<release signing SHA-256>"]
}
}
]
```

*(Amended: only the release signing fingerprint is published, §13 D6.)*

### 8.2 Android intent filter

*Moved here from `docs/features/01-accounts.md` §7.3 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


```xml
<meta-data android:name="flutter_deeplinking_enabled" android:value="false" />
<intent-filter android:autoVerify="true">
<action android:name="android.intent.action.VIEW" />
<category android:name="android.intent.category.DEFAULT" />
<category android:name="android.intent.category.BROWSABLE" />
<data android:scheme="https" android:host="{{FIREBASE_PROJECT_ID}}.web.app" android:pathPrefix="/verify" />
</intent-filter>
```

The main activity keeps android:launchMode="singleTask" and the default taskAffinity. The \<application\> tag keeps android:allowBackup="true". *(Amended, §13 D5 and D7.)*

### 8.3 Browser fallback page

*Moved here from `docs/features/01-accounts.md` §7.4 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


Shown only when Android does not hand the link to the app (app not installed, or link opened on a computer). It never calls the API.

- Title and heading: Open this link in the app

- Paragraph: Open this link on the Android phone where the app is installed.

- Button Open in app: href is built by inline JavaScript from location.search as intent://{{FIREBASE_PROJECT_ID}}.web.app/verify\<location.search\>#Intent;scheme=https;package={{ANDROID_PACKAGE_NAME}};end.

- Link Get the app on Google Play → https://play.google.com/store/apps/details?id={{ANDROID_PACKAGE_NAME}}.

- Self-contained HTML, inline CSS, no external resources.

### 8.4 Android build settings

*Moved here from `docs/features/01-accounts.md` §10.3 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


- android/app/build.gradle(.kts): minSdk = 24; applicationId = "{{ANDROID_PACKAGE_NAME}}". *(Amended, §13 D4.)*

- AndroidManifest.xml: \<uses-permission android:name="android.permission.INTERNET" /\>, android:allowBackup="true", plus Section 7.3. *(Amended, §13 D5.)*

### 8.5 The admin website build

*Moved here from `docs/features/11-admin.md` §3 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


- A single-page app in TypeScript, built with Vite, using the Firebase JS SDK for Auth only. All data goes through the `api` function; Firestore rules still deny every client.
- English only: it has one user.
- Deployed with `firebase deploy --only hosting:admin`, by hand, like the public site.
- **As built (2026-10-08):** `admin/`, vanilla TypeScript with Vite and the
  Firebase JS SDK's Auth. Its Firebase web config (`apiKey`, `appId`) comes
  from `admin/.env.local`, made by copying `admin/env.example`; the API base is
  `https://hazri-dfcc1.web.app/api/v1/admin` (cross-origin, allowed by
  `ADMIN_ORIGINS` in `functions/src/config.ts`).


## 9. Deployment

### 9.1 What is deployed by hand

No workflow deploys any of these. A change to one is only half done until it
is deployed, and the PR description says so.

| What | Command |
|---|---|
| `firestore.rules`, indexes | `firebase deploy --only firestore` |
| Functions | `firebase deploy --only functions` |
| Public site (`/verify`, `/j/<code>`, `assetlinks.json`) | `firebase deploy --only hosting` |
| Admin website | `firebase deploy --only hosting:admin` |

CI (`.github/workflows/build.yml`) analyses, tests and builds the APK; the
Functions and rules additionally run against the emulator (`00-platform.md`
P3).

### 9.2 First-time project setup

*Moved here from `docs/features/01-accounts.md` §10.4 on 2026-10-08, word for word. Section numbers and bare references inside it are that file's.*


1.  Create the Firebase project; set Firestore location asia-south1; enable Authentication → Anonymous.

2.  Upgrade to the Blaze plan (required for Cloud Functions and extensions).

3.  Install extension firebase/firestore-send-email: collection mail, SMTP URI {{SMTP_CONNECTION_URI}}, default FROM {{EMAIL_FROM}}.

4.  Run flutterfire configure for Android.

5.  Fill assetlinks.json fingerprints (./gradlew signingReport for debug/upload; Play Console → App integrity for Play signing).

6.  firebase deploy --only firestore,functions,hosting.

7.  Check https://{{FIREBASE_PROJECT_ID}}.web.app/.well-known/assetlinks.json returns the JSON.

8.  Install the app and run adb shell pm get-app-links {{ANDROID_PACKAGE_NAME}}; the host must show verified.


## 10. The cost model, and what is never stored

### 10.1 The cost model is the data model

Firestore bills per document read and **cannot be spend-capped**; costs
record up to 24 hours late. `maxInstances` is the real protection and the cap
the last line.

| Screen or job | Firestore | Why |
|---|---|---|
| Today, Nitnem, the reader, the Diary, Goals, Badges | **0** | Entirely from `user.db` |
| Attendance | 2 reads, at most 1 write, once a day per profile | The local flag stops a second call (`07-simran.md` AT1) |
| The globe | 1 read per fetch | One snapshot document, not one per person or per city |
| The Sangat tab | 1 read for "my groups", then 1 per group shown | `memberships/{memberKey}` answers the list |
| A contribution | A transaction on the contribution, the member and the goal (a shard for built-in goals) | Idempotent by the contribution id |
| Weekly backup | See `10-backup.md` §6.5 (here §6.4) | Changes only |
| Notifications | See §7.3 | FCM itself does not bill |

**M1 — if it can be answered from `user.db`, it must be.** Anything that
breaks with the radio off, and is not the Sangat or the globe, is a bug.

**M2 — never query a collection where a document id is known.**

**M3 — a counter a client can write is a counter a client can forge.** Every
shared number is kept by a Function.

### 10.2 Derived, never stored twice

Hazri, the goal state, the streak and the badge counts are derived from
completions and sittings by one function each (§2.2). **None of them gets a
column.** The only stored fact is that a badge was earned and when. Where
something is expensive to derive it is cached with the inputs it came from
and invalidated by them, never written as a second truth.


## 11. What on the branch today is replaced

The code on `claude/pensive-hawking-k87ese` predates the specifications of
2026-10-07. This is what it has that the target above replaces; the PRD's
implementation plan (§11 there) removes each in the step named.

| On the branch today | Replaced by | Step |
|---|---|---|
| `cloud_firestore` on the client, writing `users/{uid}`, `groups/{id}`, `groups/{id}/members/{uid}`, `presence/{day}/cities/{cityId}` directly | The `api` Function; rules deny all (§5.11) | Platform, Sangat, Simran |
| `users/{uid}/diary/{day}` diary sync (`lib/features/sync/`), `/sync` screen, `diary_sync` and `sync_wifi_only` | Weekly backup (§5.7, §6.4) | Backup |
| Email-link sign-in through Firebase Auth's own mailer (`sendSignInLinkToEmail`), the Email/Password provider | Profile links sent by the `api` Function through Brevo; Anonymous provider only (§6.1) | Accounts |
| The Vichar library read from `content/vichar/entries` | The same entries served by the API (`01-accounts.md` §13.4) | Platform |
| `user.db` v4: `goals` with `goal_ticks`, `completions` one per bani per slot per day | v5 and v6 (§3.3–3.7) | Goals and Diary |
| `reminders` table and five reminder kinds (`slot:morning`, `slot:evening`, `slot:bedtime`, `simran`, `gurpurab`) | Derived occurrences; five channels (§4.1) | Notifications |
| `city_id` preference, the Settings city picker | The profile's `cityId` | Accounts, Simran |
| Branded splash route, three intro pages, the reminders setup step | Android's splash, Welcome, Language, How you read | First run |
| `ElderTodayScreen` | Today at larger sizes | Today |
