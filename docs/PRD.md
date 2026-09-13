# Ang Sang — Product Requirements Document (Phase 1)

| | |
|---|---|
| Product | **Ang Sang** (ਅੰਗ ਸੰਗ · अंग संग) — "Your daily Nitnem — always with you" |
| Owner | Puneet Singh (individual developer) |
| Document | PRD v1.0 · Phase 1 (Launch) · 11 September 2026 |
| Platform | **Android first (Phase 1 & 2). iOS in Phase 3** from the same codebase |
| Tech stack | **Flutter** (Dart 3), Material 3 with a custom theme |
| Audience of this doc | Claude Code (implementer) and the product owner |

---

## 0. How to use this document (read first, Claude Code)

**Package layout**

```
ang-sang-phase1/
├─ PRD.md                      ← this document (source of truth for behaviour)
└─ design/
   ├─ screens.json             ← index of every screen: name, title, frame size, designed theme, file stem
   ├─ tokens.json              ← colours (light + dark), fonts, type scale, radii, sizes
   ├─ html/NN-Name.light.html  ← visual spec per screen, light theme (open in a browser)
   ├─ html/NN-Name.dark.html   ← same screen, dark theme
   ├─ html/00-Foundations.html ← design-system sheet (colours, type, components, motif)
   ├─ screens/NN-Name.{light,dark}.png ← 2× renders of each screen
   └─ data/                    ← dev fixtures: sample-japji.json, sample-hukamnama.json, gurpurab-558.sample.json
```

Live design canvas (all screens side by side, with notes): https://claude.ai/code/artifact/f601efc5-8bb5-4b87-8dfc-fc70dd4f08c5

**Rules for implementation**

1. **The HTML files are the visual spec, not code to port.** Frames are 390 × 844 CSS px = 390 × 844 dp. Match layout, spacing, radii, colours and type from the HTML/CSS; build with Flutter widgets. Artboards titled "full scroll" are taller than a phone and show the whole scrolling content.
2. **Behaviour comes from this PRD.** Where a design and this PRD disagree, the PRD wins. Flag the conflict in the PR description.
3. **Never create, paraphrase, auto-translate or AI-generate Gurbani text, Gurbani audio, meanings or images of the Gurus.** All Gurbani and meanings come only from the content pipeline (§8). Sample text in the designs and `design/data/` is a placeholder. English/Hindi meanings in the designs are placeholder paraphrases.
4. **No ads SDKs, no login, no own server in Phase 1.** Network is used only for Firebase (Analytics/Crashlytics), the daily Hukamnama fetch and Play Asset Delivery.
5. **All UI strings are localised** (Punjabi, Hindi, English) from day one. No hard-coded user-facing strings.
6. **Keep platform-specific code behind interfaces** (§6.4) so the iOS app in Phase 3 needs new adapters, not rewrites.
7. Work milestone by milestone (§15). Each milestone ends with passing tests, `flutter analyze` clean, and a short changelog.
8. Copy these rules into the repo's `CLAUDE.md` at M0 so they apply to every session.

---

## 1. Product summary

Ang Sang is a free, offline-first Nitnem app in Punjabi, Hindi and English. Its promise:

- **All seven Nitnem banis, Ardas and Sukhmani Sahib**, with audio, in Gurmukhi, Devanagari and Roman, with simple meanings in three languages.
- **Text follows the paath**: the current line and word are highlighted and the page auto-scrolls with the audio.
- **Paath keeps playing** when the app is minimised or the phone is locked.
- **Reminders at the user's own times** or automatically from local sunrise/sunset.
- A gentle **Nitnem Diary**, **Paath goals**, **Daily Simran (5 min)**, the **daily Hukamnama** with a share card, and a **Gurpurab / Nanakshahi calendar**.
- **Works offline · No login · No ads on Gurbani — ever.**

### 1.1 Target users

| Persona | Needs |
|---|---|
| Daily Nitnem keeper (25–60), India & diaspora | Reliable text, audio for commute, reminders, resume where left |
| Hindi-reading Sikh / Sehajdhari families | Correct Devanagari with meanings in Hindi; Hindi UI |
| Learner / diaspora youth | Roman transliteration, English meanings, follow-along audio |
| Elders | Very large text, big buttons, simple screens (Elder mode) |

### 1.2 Principles (non-negotiable)

1. **Respect (maryada) first.** No ads or promotions near Gurbani. No points or XP for Gurbani. No guilt-tripping streak messages. Gurbani in notifications is limited to bani names.
2. **Accuracy.** Only reviewed text and licensed meanings. Every source is credited in About.
3. **Offline by default.** Everything except the daily Hukamnama refresh works with no network.
4. **Calm design.** "Amrit Vela" visual language: dawn-mist light, deep-night dark, Neela (navy) + Kesri (saffron), the day-arc motif.
5. **Budget phones matter.** Small download, fast start, smooth scrolling on 3 GB RAM devices.

---

## 2. Goals and success metrics

| Goal | Metric (Firebase Analytics) | Target at 90 days |
|---|---|---|
| Habit | Share of active days with ≥1 Nitnem bani completed | ≥ 60 % |
| Retention | Day-30 retention | ≥ 25 % |
| Follow-along value | Share of bani sessions with audio playing | ≥ 40 % |
| Simran | Daily Simran completions per weekly active user | ≥ 2 |
| Growth | Hukamnama share cards sent per weekly active user | ≥ 0.5 |
| Quality | Crash-free users | ≥ 99.5 % |
| Store | Play rating | ≥ 4.6 |

---

## 3. Scope

### 3.1 Phase 1 — in scope (features 1.1–1.17)

| # | Feature | Design files |
|---|---|---|
| 1.1 | Splash + 3 intro screens | 01–04 |
| 1.2 | Setup: language → reading preferences & elder mode → reminders; audio downloads in background | 05–08 |
| 1.3 | Today: Hukamnama card, Start/Continue Nitnem, day arc | 09, 10 |
| 1.4 | Nitnem list grouped into Amrit Vela, Evening, Bedtime (+ More banis) | 12 |
| 1.5 | Reader: scripts, meanings, pause marks, Larivaar, text size, next/prev bani, resume, keep screen on | 13–16 |
| 1.6 | Follow audio: line + word highlight, auto-scroll, "Back to paath", tap a line to jump | 13, 15 |
| 1.7 | Audio: one paathi, morning banis back-to-back, speed, ±10 s, full-screen player | 17 |
| 1.8 | Background playback: notification & lock-screen controls, Bluetooth, pause for calls / unplugged headphones, sleep timer | 18 |
| 1.9 | Nitnem Diary: calendar, gentle streak with grace days, Google backup | 26 |
| 1.10 | Reminders per bani: Auto (sunrise/sunset) or My time; move a bani to Morning/Evening/Bedtime | 07, 08, 23, 27 |
| 1.11 | Daily Hukamnama: saved offline, shareable image card | 24, 25 |
| 1.12 | Elder mode | 11 |
| 1.13 | Daily Simran — 5 minutes | 21 |
| 1.14 | Gurpurab & Nanakshahi calendar with reminders | 22 |
| 1.15 | Paath goals: several goals, daily tracking, a reminder per goal | 19, 20 |
| 1.16 | Settings | 27 |
| 1.17 | About, credits & privacy | 27 (About section) |

**Content in Phase 1:** Japji Sahib, Jaap Sahib, Tav Prasad Savaiye, Chaupai Sahib, Anand Sahib (Amrit Vela); Rehras Sahib (Evening); Kirtan Sohila (Bedtime); Ardas and Sukhmani Sahib (More banis). SGPC versions by default.

### 3.2 Out of scope for Phase 1 (do not build; keep hooks where noted)

Sign-in, sync, any backend; Sangat Paath; Global Naam Simran / Simran Circle; family view; Gurbani Vichar AI; extended banis; invite links; home-screen widgets; Report an error; Ask a question; pronunciation practice; more voices; Chromecast; Live Kirtan; Saakhis; badges; Sehaj Path; daily quotes; any payments. **iOS app** (Phase 3).

### 3.3 Roadmap context

| Phase | Theme | Items |
|---|---|---|
| **1 · Launch (this PRD)** | Best daily Nitnem app. Free, offline, no login, no own server. **Android only.** | 1.1–1.17 |
| **2 · Together** | Server added (Firebase; Vercel for extras). Still free. Android only. | 2.1 Optional sign-in & diary sync · 2.2 Sangat Paath · 2.3 Global Naam Simran · 2.4 Family view · 2.5 Simran Circle · 2.6 Gurbani Vichar AI (curated knowledge base only, cites Ang/teeka) · 2.7 Extended banis · 2.8 Invite links on own domain |
| **3 · Depth + iOS** | Harder to copy; second platform | 3.1 Recitation check · 3.2 Kids' kantth mode & Gurmukhi letters · 3.3 Gurdwara Connect · 3.4 Wear OS Simran counter (+ Apple Watch after iOS) · 3.5 Home-screen widgets (Android + iOS) · 3.6 Report an error · 3.7 Ask a question · 3.8 Pronunciation practice · 3.9 More voices · 3.10 Cast to TV · 3.11 Live Kirtan (with SGPC written permission) · 3.12 Saakhis (never depicting the Gurus) · 3.13 Badges · 3.14 Sehaj Path marker · 3.15 Daily quotes · **3.16 iOS app (iPhone) from the same Flutter codebase — see §17.2** |
| Later | Earning (after forming a non-profit/company) | Dasvandh, Plus plan, occasion pages, gurdwara plans, sewa sponsorship, Paath marketplace, grants |

---

## 4. Platforms and tech stack

### 4.1 Platform targets

| | Phase 1 (Android) |
|---|---|
| minSdk | 24 (Android 7.0) |
| targetSdk / compileSdk | **36 (Android 16)** — required by Google Play for new apps and updates from 31 Aug 2026 |
| Form factor | Phones, portrait only. Tablets run in phone layout (max content width 560 dp, centred) |
| Distribution | Google Play, Android App Bundle (AAB) with Play Asset Delivery packs |
| Store account | Personal developer account; closed test with ≥12 testers for 14 days before production |

Android 15+/16 behaviour to respect: enforced **edge-to-edge** (handle system-bar insets on every screen), **predictive back** enabled, **exact alarms denied by default** (user grant needed), `POST_NOTIFICATIONS` runtime permission (Android 13+), media foreground-service type (Android 14+).

### 4.2 Stack

| Concern | Choice | Notes |
|---|---|---|
| Framework | Flutter (latest stable), Dart 3, null-safe | One codebase for Android now, iOS in Phase 3 |
| Architecture | Feature-first, layered (UI → controllers → repositories → data sources) | See §6 |
| State management | `flutter_riverpod` (+ `riverpod_annotation`/generator) | Testable, no BuildContext in logic |
| Navigation | `go_router` | Deep links from notifications (`angsang://reader/japji?autoplay=1`) |
| Local database | `drift` (SQLite) | Two DBs: read-only **content.db** (bundled) and **user.db** |
| Simple prefs | `shared_preferences` | Language, script, theme, flags |
| Models | `freezed` + `json_serializable` | |
| Audio playback | `just_audio` | Gapless playlist, speed with pitch preserved (ExoPlayer) |
| Background/media session | `audio_service` | Notification, lock screen, Bluetooth/headset buttons, Android Auto-safe metadata |
| Audio focus & interruptions | `audio_session` | Calls, "becoming noisy" (unplug), ducking |
| Local notifications | `flutter_local_notifications` + `timezone` + `flutter_timezone` | Exact alarms when granted; boot/timezone reschedule |
| Background jobs | `workmanager` | Daily Hukamnama refresh + reminder re-scheduling |
| Audio asset packs | **Custom Kotlin plugin** wrapping Play Asset Delivery (`com.google.android.play:asset-delivery` + `-ktx`) via a platform channel | No official Flutter plugin; keep it in `packages/asset_packs/` with a Dart interface |
| Sunrise/sunset | Pure-Dart NOAA solar algorithm (own implementation, unit-tested) | No network needed |
| Location | Bundled city list (offline) + optional one-shot coarse location via `geolocator` | Location permission is optional |
| Localisation | `flutter_localizations` + `intl` + gen-l10n ARB files (`pa`, `hi`, `en`) | |
| Fonts | Bundled TTF: Noto Serif Gurmukhi, Noto Serif Devanagari, Mukta, Baloo Paaji 2 (all OFL) | Never fetch fonts at runtime |
| Keep screen on | `wakelock_plus` | Reader and Simran only |
| Share card | `RepaintBoundary` → PNG, `share_plus` | 1080 × 1920 |
| Scroll-to-line | `scrollable_positioned_list` | Variable-height lines with alignment |
| HTTP | `dio` (or `http`) | Hukamnama only |
| Analytics / crashes | `firebase_core`, `firebase_analytics`, `firebase_crashlytics` | No Auth/Firestore in Phase 1 |
| Haptics | Flutter `HapticFeedback` | Simran counting |
| Splash | `flutter_native_splash` (Android 12 SplashScreen API) | |
| Testing | `flutter_test`, `mocktail`, golden tests, `integration_test` | §14 |
| Lints | `very_good_analysis` or `flutter_lints` (strict) | |
| CI (optional) | GitHub Actions: analyze → test → build appbundle | |

**Package policy:** every dependency must support **Android and iOS** (for Phase 3) unless it sits behind a platform interface. No ads SDKs, no attribution/tracking SDKs.

---

## 5. Information architecture and navigation

```
First launch:  Splash → Intro 1 → Intro 2 → Intro 3 → Setup 1 Language → Setup 2 Reading → Setup 3 Reminders → Today
Every launch:  (system splash) → Today (or the deep-link target)

Bottom navigation (5 tabs):  Today · Nitnem · Simran · Diary · Settings
Elder mode navigation (3 tabs): Today · Nitnem · Settings

Pushed screens: Reader (+ text-settings sheet), Full-screen player, Hukamnama, Share card preview,
                Gurpurab calendar, Paath goals (+ Add goal sheet), Reminder time sheet, City picker,
                About & credits, Privacy, Open-source licences
```

Routes (go_router): `/intro`, `/setup/:step`, `/today`, `/nitnem`, `/simran`, `/diary`, `/settings`, `/reader/:baniSlug?line=&autoplay=`, `/player`, `/hukamnama`, `/gurpurab`, `/goals`, `/about`, `/privacy`.
Back from a tab root exits the app (predictive back). Notification taps open the target route on top of Today.

---

## 6. Architecture

### 6.1 Folder structure

```
lib/
  main.dart                  # bootstrap: Firebase, DBs, audio handler, notifications, runApp
  app/                       # MaterialApp.router, theme, router, l10n delegates
  core/
    theme/                   # AngSangColors (ThemeExtension), text styles from tokens.json
    l10n/                    # ARB files: app_en.arb, app_pa.arb, app_hi.arb
    db/                      # drift: content_db.dart, user_db.dart, migrations
    platform/                # interfaces + Android adapters (§6.4)
    analytics/               # typed event helpers
    time/                    # clock provider, solar calc, Nanakshahi date
    widgets/                 # shared widgets: DayArc, ProgressRing, Chip, Card, IconButton, BottomNav
  features/
    onboarding/  today/  nitnem/  reader/  audio/  diary/  reminders/
    hukamnama/   simran/ gurpurab/ goals/  settings/ about/
      └─ each: data/ (repos, sources)  domain/ (models, logic)  ui/ (screens, widgets, controllers)
packages/
  asset_packs/               # Kotlin plugin for Play Asset Delivery + Dart interface
tools/
  content_pipeline/          # builds assets/content/content.db from licensed sources (§8)
  timing_tool/               # simple web/desktop tool to verify & correct line/word timings
android/
  app/                       # manifest, backup rules, notification icons
  nitnem_audio/              # asset pack module (fast-follow)
  sukhmani_audio/            # asset pack module (on-demand)
assets/
  content/content.db         # bundled, read-only
  fonts/  images/  sounds/   # sounds: soft drone loop, end bell (licensed/royalty-free)
test/  integration_test/
```

### 6.2 Key runtime components

| Component | Responsibility |
|---|---|
| `ContentRepository` | Read-only queries on content.db (banis, versions, lines, meanings, tracks, timings, events, cities) |
| `ProgressRepository` | Resume points per bani, completions, diary queries |
| `AngSangAudioHandler` (audio_service) | Single source of truth for playback: queue, position, speed, sleep timer, media controls |
| `FollowController` | Maps audio position → current line/word; owns follow/detached state for the reader |
| `ReminderScheduler` | Computes occurrences (auto/fixed), schedules a rolling 7-day window, handles permissions |
| `SolarService` | Sunrise/sunset for the chosen city/coordinates and date |
| `HukamnamaRepository` | Fetch, cache (30 days), expose today's/latest |
| `CalendarService` | Nanakshahi date for any Gregorian date; upcoming Gurpurabs |
| `GoalsRepository` | Goals CRUD, daily progress |
| `SimranController` | 5-min session timer, count, sounds, logging |
| `AssetPackService` | Pack status/progress, fetch, file paths (platform interface) |
| `Analytics` | Typed events; respects the user's opt-out |

### 6.3 Reactive data flow

Repositories expose `Stream`s (drift `watch()`); Riverpod providers derive UI state. Audio state comes from `AudioHandler.playbackState`/`mediaItem` streams plus a position stream. Time-dependent UI (day arc, "Tomorrow · Gurpurab") uses an injectable `Clock` provider for testability.

### 6.4 Platform interfaces (iOS-ready)

| Interface | Android adapter (Phase 1) | iOS adapter (Phase 3) |
|---|---|---|
| `AssetPackService` | Play Asset Delivery (fast-follow / on-demand) | Apple-hosted Background Assets packs (or first-run download from own storage) |
| `ExactReminderPermission` | `SCHEDULE_EXACT_ALARM` status + open settings | Always "granted" (not applicable) |
| `NotificationPermission` | `POST_NOTIFICATIONS` (13+) | `UNUserNotificationCenter` authorisation |
| `ReminderScheduler` window | 7 days rolling | Same, but capped at 60 pending (iOS limit 64) |
| `BackupInfo` | Android Auto Backup (Google account) | iCloud device backup |
| `HapticsService` | Vibration | Taptic |
| `StoreLinks` | Play Store URL | App Store URL |

---

## 7. Data model

### 7.1 content.db (bundled, read-only, versioned)

```
source(id, name, author, kind[text|meaning|translit|audio|calendar], licence, url, notes)
bani(id, slug, name_en, name_pa, name_hi, category[nitnem|other], default_slot[morning|evening|bedtime|none],
     sort, est_minutes)
bani_version(id, bani_id, code[sgpc|taksal|akj|...], label_en/pa/hi, is_default)
line(id, bani_version_id, idx, section_label_en/pa/hi   -- e.g. "Pauri 1 of 38"
     , kind[heading|mangal|verse|rahao|end], gurmukhi, devanagari, roman
     , visraam_json   -- [{"w":3,"t":"short"|"long"}] word indices
     , word_count, source_id, source_ref)
meaning(line_id, lang[pa|hi|en], text, source_id)
voice(id, name, credit_en/pa/hi)
audio_track(id, bani_version_id, voice_id, pack[nitnem_audio|sukhmani_audio], file, duration_ms, bytes)
timing(audio_track_id, json)                       -- see 7.3
nanakshahi_month(ns_year, idx, name_en/pa/hi, start_date)   -- Sangrand dates
calendar_event(id, ns_year, date, kind[gurpurab|sangrand|puranmashi|masya|shaheedi|other],
     name_en/pa/hi, ns_label, default_remind)
city(id, name_en/pa/hi, country_code, lat, lon, tz)
meta(key, value)                                    -- content_version, built_at
```

Copy `content.db` from assets to app storage on first run and whenever `content_version` changes.

### 7.2 user.db (drift, backed up)

All rows use UUID v4 ids and `updated_at` (UTC) so Phase 2 sync can be added without migration pain.

```
reading_progress(bani_version_id PK, line_idx, audio_pos_ms, updated_at)
completion(id, local_date, bani_id, slot, source[read|listen|manual], goal_id?, completed_at)
simran_session(id, local_date, started_at, duration_s, count, completed bool)
goal(id, bani_id, times_per_day, duration_type[every_day|days|until], days?, until_date?,
     start_date, reminder_time?, active, created_at, updated_at)
goal_tick(id, goal_id, local_date, source[auto|manual], at)
reminder(id, target_type[slot|bani|simran|gurpurab|goal], target_id, mode[auto|fixed|off],
     anchor[sunrise|sunset]?, offset_min?, time_hhmm?, days_mask, slot_override?, updated_at)
grace_day(local_date PK, month_key)
event_reminder_override(event_id PK, enabled)
hukamnama_cache(date PK, payload_json, source, fetched_at)
```

Prefs (`shared_preferences`): `app_locale`, `script[gur|dev|rom]`, `show_roman_under_gurmukhi`, `meanings_on`, `meanings_lang`, `visraam_on`, `larivaar_on`, `reader_font_size`, `keep_screen_on`, `follow_audio`, `theme[auto|light|dark]`, `elder_mode`, `city_id`/`lat`/`lon`, `voice_id`, `speed`, `onboarding_done`, `exact_alarm_asked`, `analytics_enabled`.

### 7.3 Timing file format (per audio track)

```json
{
  "track": "japji_sgpc_voice1", "durationMs": 1144000, "version": 3,
  "lines": [
    { "line": 0, "s": 1200, "e": 9800,
      "w": [[1200,1900],[1900,2600],[2600,3400]] }
  ]
}
```

`line` = `line.idx`; `w` = word start/end ms in Gurmukhi word order. Words may be omitted for a line (line-level highlight only). Lines not recited (e.g. headings) are absent.

---

## 8. Content and asset pipeline (`tools/content_pipeline`)

A repeatable script (Dart or Python) that builds `assets/content/content.db`. **Nothing Gurbani-related is typed by hand in app code.**

| Content | Source (to confirm — see §18) | Pipeline rules |
|---|---|---|
| Gurbani text (Gurmukhi Unicode), Devanagari, Roman | BaniDB (Khalis Foundation) banis data, subject to licence approval; alternative: another openly licensed Gurbani database | Store Unicode, not legacy ASCII fonts. Validate that Devanagari and Roman word counts equal Gurmukhi word counts per line; if not, mark the line `word_align=false` (line-only highlight) and list it in a report for scholar review |
| Vishraam (pause marks) | Same source (vishraam data) | Map to `short`/`long` per word index |
| Meanings pa / hi / en | Licensed teeka/translations (e.g., Prof. Sahib Singh for Punjabi; an approved Hindi teeka; an approved English translation) | Store `source_id` for credits. No machine translation |
| Bani versions | SGPC Rehat Maryada versions (default) | Phase 1 ships SGPC only unless alternate text **and** audio exist |
| Audio | Commissioned recordings with written rights assignment (one paathi, SGPC versions) | Mono AAC (.m4a) 64 kbps, loudness-normalised (−16 LUFS), no music. Until final audio exists, use clearly labelled dev placeholders |
| Timings | Forced alignment of final audio against the text, then human verification in `tools/timing_tool` | Line timings must be verified by a human. Word timings: aligner output, fallback = split line duration by syllable weight |
| Gurpurab & Nanakshahi | Official SGPC calendar (jantri) for the NS year | Bundle current + next NS year when available; update yearly via app update |
| Cities | Open city dataset (e.g., GeoNames cities with population > 15 000, CC-BY — credit it) | Names in en; pa/hi names for top Indian + diaspora cities |

**Audio packs (Play Asset Delivery)**

| Pack | Delivery | Contents | Est. size* |
|---|---|---|---|
| `nitnem_audio` | fast-follow (downloads right after install, during setup) | Japji, Jaap, Tav Prasad Savaiye, Chaupai, Anand, Rehras, Sohila, Ardas | ~58 MB |
| `sukhmani_audio` | on-demand (user taps download) | Sukhmani Sahib | ~36 MB |

\*Placeholders; real sizes come from final recordings. Keep the base AAB download ≤ 25 MB.

`AssetPackService` API (Dart): `Stream<PackState> watch(pack)`, `Future<void> fetch(pack)`, `Future<String?> pathFor(pack, file)`, `Future<void> requestCellularConsent()`. States: `notInstalled | pending | downloading(bytes,total) | transferring | completed | failed(code) | waitingForWifi`. Debug/local: support `bundletool --local-testing`; sideloaded builds fall back to `assets/audio_dev/`.

---
## 9. Feature specifications

Each feature lists design references, behaviour and acceptance criteria (AC). "Design NN" = `design/html/NN-*.html` / `design/screens/NN-*.png`.

### 1.1 Splash and intro — Design 01–04

**Behaviour**
- System splash (Android 12 SplashScreen API): app mark on `#0C0F24`. Then the branded splash (Design 01) for ≤1.5 s **on first launch only**; later launches go straight to Today.
- Three intro pages in a `PageView` (swipe or **Next**; last page **Get started**):
  1. *Your Nitnem, always with you*: day arc mock, chips "Works offline · No login · No ads on Gurbani".
  2. *Read along as the paath is recited*: highlighted line mock, "Phone locked — paath keeps playing".
  3. *In your language, at your pace*: three scripts, meanings languages, elder mode chip.
- Language pill **ਪੰ / हि / En** top-left switches the app locale instantly (and pre-selects it in Setup 1). Default = device locale if pa/hi, else en.
- **Skip** (top-right) → Setup 1. Page dots show position. Intros are shown in dark theme as designed, unless the user has already picked Light.
- Intro art is built from real widgets (day arc, line cards), not bitmaps, so it localises.

**AC**
- [ ] Fresh install shows Splash → 3 intros → Setup; reinstall with restored backup skips to Today if `onboarding_done`.
- [ ] Switching the language pill re-renders all intro text within one frame, no restart.
- [ ] Skip from any intro page lands on Setup 1.

### 1.2 Setup — Design 05–08

Three steps with a 3-dash progress indicator. **Back** returns to the previous step. Nothing is required except language.

**Step 1 · Language (05):** options ਪੰਜਾਬੀ / हिन्दी / English (radio cards). Sets `app_locale`, default `meanings_lang` and default script (pa→Gurmukhi, hi→Devanagari, en→Gurmukhi with Roman under it). Footer: "Works offline · No login · No ads on Gurbani". **Continue**.

**Step 2 · Reading (06):** script cards (Gurmukhi / Devanagari / Roman) previewing a real line; text size slider (live preview); **Elder mode** toggle; "Bani versions follow the SGPC Rehat Maryada — Change" (opens the versions sheet; SGPC only unless others exist). **Continue**.

**Step 3 · Reminders (07, 08):**
- Rows: Amrit Vela (Auto · before sunrise), Rehras Sahib, Kirtan Sohila, Daily Simran, Gurpurab days (evening before). Each row shows mode + a time pill. Tapping a row opens the **Reminder time sheet** (08).
- Defaults: Amrit Vela **Auto**; Rehras **Auto (sunset)**; Sohila **My time 22:00**; Daily Simran **My time 06:00**; Gurpurab **evening before 20:00 + morning 07:00**. (Design shows sample times like 8:00 PM/10:30 PM.)
- "Allow on-time reminders" card (Android 12+ only, hidden if already granted): explains that Android asks once so Amrit Vela reminders arrive to the minute. **Allow** → `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`; on return, card collapses to "On-time reminders allowed" or stays with "Not now — reminders may arrive a few minutes late".
- Notification permission (`POST_NOTIFICATIONS`, Android 13+) is requested when the user reaches this step, with a one-line rationale shown first.
- "Using **{city}** for sunrise and sunset — Change": default city from device time zone (Asia/Kolkata → New Delhi, Europe/London → London, America/Toronto → Toronto, …); Change opens the city picker (search, offline) with an optional "Use my location" (coarse, one-shot).
- Audio download card: "Saving Nitnem audio for offline use — x of y MB" with a progress bar driven by `nitnem_audio`. If on mobile data and Play requires consent, show "Download on Wi-Fi only / Use mobile data".
- **Begin my Nitnem** → sets `onboarding_done`, schedules reminders, logs `onboarding_complete`, goes to Today.

**Reminder time sheet (08)** — modal bottom sheet, radius 28:
- Title "{Bani} reminder". Segmented choice: **Auto** ("At sunset · 6:28 PM today" / "Before sunrise · 4:30 AM today") or **My time** ("Same time every day").
- Time wheel (hour · minute in 5-min steps · AM/PM; 24-h if the device uses 24-h).
- **Repeat** day chips M–S (default all).
- **Show in my day**: Morning / Evening / Bedtime — moves this bani to that section of the Nitnem list and the day arc (slot override).
- "Turn off this reminder" text button. **Save**.

**AC**
- [ ] Audio pack download starts as soon as Setup 1 is shown and continues if the user leaves the app.
- [ ] Denying notification or exact-alarm permission never blocks setup; Settings shows how to enable later.
- [ ] Changing the city updates Auto times shown on the rows immediately.

### 1.3 Today — Design 09 (English, light), 10 (Hindi, dark)

**Layout (top → bottom):** header (app mark + "Ang Sang", help icon), date ("Friday, 11 September", localised), greeting "Sat Sri Akal ji" (ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਜੀ / सत श्री अकाल जी); **Day arc card**; **CTA button**; **Today's Hukamnama card**; two tiles (Daily Simran, next Gurpurab); bottom nav.

**Day arc (`DayArc` widget)**
- Semicircular track with three nodes: Amrit Vela, Rehras, Sohila, each labelled with its time ("Rehras · 8 PM"). Node states: `done` (filled sage + check), `active` (kesri ring), `todo` (outline).
- Sun dot marks "now". Position `t = clamp((now − (amritVela − 30 min)) / ((sohila + 30 min) − (amritVela − 30 min)), 0, 1)` along the arc.
- Centre: "**n of 5**" (morning banis done today) and a subline ("Japji Sahib in progress", "Morning Nitnem complete", "Rehras at 8:00 PM"). After Amrit Vela, centre switches to the current slot.
- Slot times come from the reminder settings (Auto or My time), even if the reminder is off.

**CTA** (primary button, full width) — state machine:
| State | Label |
|---|---|
| Nothing started today, morning slot | ▶ Start my Nitnem · 63 min |
| A bani in progress (resume point exists today) | ▶ Continue {Bani} · {n} min left |
| Morning done, before Rehras | ▶ Start Rehras Sahib · 18 min |
| Rehras done, before Sohila | ▶ Start Kirtan Sohila · 5 min |
| All done | ✓ Today's Nitnem complete (secondary style) → opens Diary |
Tap → Reader for that bani with autoplay if audio is available and the user last used audio; otherwise reader only.

**Hukamnama card:** "Today's Hukamnama" + "Ang 666 · Dhanasari"; first line in the chosen script; its meaning in `meanings_lang`; actions **Listen** (hidden unless a licensed audio source is configured, §1.11), **Share card**, **Read**. Offline/stale: shows the last saved one with "Saved {date}".

**Tiles:** *Daily Simran* ("0 of 5 min" / "Done today ✓") → Simran tab. *Gurpurab* tile shows the next calendar event within 7 days ("Tomorrow · Gurpurab — Pehla Prakash Purab"); if none, shows today's Nanakshahi date ("26 Bhadon 558") → Gurpurab calendar.

**Help icon** → bottom sheet "How Ang Sang works" (3 short tips + link to About).

**AC**
- [ ] CTA state is correct for each row of the table (unit + widget tests with a fake clock).
- [ ] Today renders fully offline with no Hukamnama ever fetched (card shows "Hukamnama will appear when you're online").
- [ ] Hindi UI: every string on Today is Hindi (Design 10).

### 1.4 Nitnem list — Design 12

- Header "Nitnem", subline "SGPC version · Change", chip "Audio saved offline" (or "Downloading 42 %" / "Audio not downloaded — Download").
- **My paath goals** summary card ("1 of 3 done today · Chaupai Sahib 3 of 5") → Paath goals. Hidden if no goals, replaced by "Set a paath goal" link.
- Sections: **Amrit Vela** ("5 banis · about 63 min", **Play all**), **Evening** ("Your time · 8:00 PM" or "At sunset · 6:28 PM"), **Bedtime**, **More banis** (Ardas, Sukhmani Sahib). Section membership respects slot overrides.
- Row: progress ring (empty / partial with resume / done today ✓), English name + Gurmukhi name, trailing text = "2:04 in" (resume), "14 min" (duration), reminder time, or "36 MB" download chip for on-demand audio.
- Tap row → Reader (resume position). **Play all** → queue all Amrit Vela banis in order, open Reader on the first.
- Sukhmani Sahib without audio: row opens the reader; the player bar offers "Download audio · 36 MB".

**AC**
- [ ] Moving Rehras to Morning (via sheet) moves its row to Amrit Vela and the day arc updates.
- [ ] Done-today ticks match Diary data.

### 1.5 Reader — Design 13 (following), 14 (meanings & pause marks), 15 (Hindi, scrolled away), 16 (dark)

**Top bar:** back; title (English name) + subline (Gurmukhi name · section label e.g. "Pauri 1 of 38", updates with scroll); script switch **ਅ / अ / A**; **Aa** → Text settings sheet.

**Text settings sheet:** text size slider (16–40, live), Show meanings (on/off + language pa/hi/en), Roman under Gurmukhi (on/off), Pause marks (vishraam) on/off, Larivaar on/off, Keep screen on, Follow audio on/off.

**Body:** `ScrollablePositionedList` of lines. Each line = Gurbani text in chosen script (+ optional Roman line in muted small text) + optional meaning (ink2, 14–15 sp). Headings/mangal centred. Line-end markers (॥੧॥) kept as in source. With pause marks on, a legend row shows "● Short pause ● Long pause" and the marked words are coloured per Design 14. Larivaar removes spaces between words (word spans stay separate for highlighting).

**Resume:** on open, scroll to `reading_progress.line_idx` (top third). Save progress (top visible line and audio position) every 5 s and on pause/exit.

**End of bani:** a closing card "✓ {Bani} complete — Next: {Next bani} ▶". Log a completion (§1.9). **Next/previous bani** also available from the player bar.

**Keep screen on** while the reader is visible (default on). **No ads, no promos, no badges** on this screen, ever.

**AC**
- [ ] Switching script keeps the same line at the same screen position.
- [ ] Text size 40 with meanings on scrolls at 60 fps on a mid-range device (profile build).
- [ ] Larivaar + follow audio still highlights the correct word.

### 1.6 Follow audio — Design 13, 15

**Highlight:** past lines muted (`muted` colour); **current line** on `hl` background with 12 dp radius; **current word** in `word` colour with a 2 dp underline; future lines normal. Update on every position tick (target ≤100 ms latency; interpolate between ticks using `DateTime.now()` and speed).

**Lookup:** binary search `lines[].s/e` then `w[]` for the current position. Lines with no word timings get line-only highlight.

**Auto-scroll:** when the current line changes, animate (250 ms, easeOut) so it sits at ~30 % from the top (`alignment: 0.3`). Don't scroll if the line is already fully visible between 15 % and 60 % of the viewport.

**Detach / Back to paath:** any user drag or fling sets `follow=detached`: auto-scroll stops, highlight continues, and a floating pill appears above the player bar: "↑ Back to paath · line {n}" (arrow points up/down relative to the current line), and the player chip reads "Auto-scroll paused". Tap pill → re-attach and scroll to the current line.

**Tap a line to jump:** tap on any line seeks audio to that line's start (`s`) and re-attaches. Playback state (playing/paused) is unchanged.

**No audio:** follow features are hidden; the reader works as a normal scroller.

**AC**
- [ ] With a 20-minute track, highlight never drifts >150 ms from timing data at speeds 0.75×, 1.0×, 1.5× (automated test with a fake player clock).
- [ ] Scrolling away and waiting 2 minutes, then tapping Back to paath lands on the correct current line.
- [ ] Reopening the app from the notification while playing shows the reader already on the current line.

### 1.7 Audio and full-screen player — Design 17

- One voice in Phase 1 (`voice_id` fixed; Settings shows the paathi's name). Speed 0.75×, 0.9×, 1.0×, 1.1×, 1.25×, 1.5× (pitch preserved). ±10 s buttons. Previous/next bani.
- **Player bar** (in reader): "Following audio" chip, speed chip, elapsed/total, seek bar, controls ⏮ ↺10 ⏯ ↻10 ⏭. Tap title area → full-screen player.
- **Full-screen player** (dark): "Now playing · Morning Nitnem · 1 of 5", Gurmukhi + English bani name, elapsed/total · section, the current line (large Gurmukhi), paathi credit, **Open reader**, chips Speed / Sleep timer / Voice, **Up next** queue with durations.
- **Play all** creates a gapless queue (just_audio playlist). Queue advances automatically; each finished bani is logged as a completion with `source=listen`.
- Audio files are read from the asset-pack path; if missing → "Download audio" CTA.

### 1.8 Background playback — Design 18

- `audio_service` media session + foreground service (type `mediaPlayback`). Notification (channel "Playback", low importance, no sound): title = English bani name, subtitle = "Ang Sang · Morning Nitnem 1 of 5", Gurmukhi name as album/description, app mark artwork; actions ⏮ ↺10 ⏯ ↻10 ⏭ (compact: ↺10 ⏯ ↻10).
- Lock screen shows the same media controls; Bluetooth/headset buttons map play/pause/next/previous.
- **Interruptions** (`audio_session`): phone call / other app takes focus → pause, resume if the interruption ends within 5 min and we were playing; transient notification → duck; **headphones unplugged / Bluetooth disconnected** → pause, **never** auto-resume on the speaker.
- **Sleep timer:** Off / 15 min / 30 min / 60 min / End of this bani / After Kirtan Sohila; fade out over 5 s.
- Swiping the app away from recents stops playback and removes the notification.
- Position is saved every 5 s so a process death resumes correctly.

**AC (manual QA on Android 10, 13, 14, 16; Samsung + Xiaomi)**
- [ ] Locking the phone for 30 min with Play all keeps playing through bani changes.
- [ ] Incoming call pauses; ending the call resumes.
- [ ] Unplugging wired headphones pauses and does not resume.
- [ ] Sleep timer "After Kirtan Sohila" stops after Sohila ends.

### 1.9 Nitnem Diary — Design 26

- Header "Nitnem Diary", month switcher ("Sep 2026 ‹ ›").
- Streak card: "**11 days in a row** — A gentle streak. Missed a day? Grace days keep it going. 2 left this month."
- Month grid (Mon-first, localised day letters): each day shows three segments for Amrit Vela / Rehras / Sohila (filled when that slot has ≥1 completion); grace days labelled "GRACE"; today outlined; future days blank. Legend below.
- Stats row for the month: counts of Japji · Rehras · Sohila · Simran.
- Footer: "Kept on this phone. Backed up to your Google account."
- Tap a day (today or up to 7 days back) → sheet to tick/untick banis and Simran manually (`source=manual`).

**Completion rules**
- A bani counts as **completed** when (a) audio reaches ≥ 95 % of the track, or (b) the reader reaches the last line and the user stays ≥ 5 s, or (c) the user ticks it manually. One completion per bani per slot per day for the diary (extra paaths still count toward goals).
- **Nitnem day** = at least one Nitnem bani completed that local day.
- **Streak** = consecutive Nitnem days ending today or yesterday. A missed day is automatically covered by a **grace day** if the month still has one left (2 per calendar month); grace days never go negative and never trigger warnings.
- No push notifications about streaks in Phase 1. No "you broke your streak" copy anywhere.

**Backup:** Android Auto Backup includes `user.db` and prefs; excludes `content.db`, audio and caches (`data_extraction_rules.xml` + `full_backup_content.xml`).

**AC**
- [ ] Unit tests cover streak + grace logic across month boundaries and DST/time-zone changes.
- [ ] Uninstall → reinstall on same Google account restores diary (manual QA with `bmgr`).

### 1.10 Reminders — Design 07, 08, 23, 27

**Reminder targets:** Amrit Vela (slot), Rehras Sahib, Kirtan Sohila, Daily Simran, Gurpurab days, each Paath goal. (Any bani moved to another slot follows that slot's reminder.)

**Auto times** (computed daily from `SolarService` for the chosen location):
| Target | Auto rule (default offset) |
|---|---|
| Amrit Vela | sunrise − 90 min, rounded to nearest 5 min |
| Rehras Sahib | sunset, rounded to nearest 5 min |
| Kirtan Sohila | sunset + 3 h 30 min, clamped 21:00–23:30 |
Offsets are adjustable later (store `offset_min`); Phase 1 UI shows only Auto vs My time.

**Scheduling**
- Rolling window: schedule occurrences for the next 7 days (total pending ≤ 60 to stay iOS-compatible). Re-plan on: app start, any settings change, daily `workmanager` job (~03:00), `BOOT_COMPLETED`, `TIME_SET`, `TIMEZONE_CHANGED`, `LOCALE_CHANGED`, city change.
- Use exact scheduling (`exactAllowWhileIdle`) when `canScheduleExactAlarms` is true; otherwise inexact and show a small hint in Settings.
- Channels: "Nitnem reminders" (default importance, sound on), "Daily Simran", "Gurpurab", "Paath goals", "Playback". Users can tune each channel in system settings.

**Notification copy (Design 23)** — calm, never guilt-inducing, no Gurbani lines beyond bani names:
| Reminder | Title | Body | Actions |
|---|---|---|---|
| Amrit Vela | Amrit Vela | Japji Sahib is ready — sunrise today is at 6:04 AM. | Start Nitnem · Later |
| Daily Simran | Daily Simran | Five quiet minutes of Waheguru Simran. | Begin · Skip today |
| Gurpurab (evening before) | Tomorrow is a Gurpurab | Pehla Prakash Purab, Sri Guru Granth Sahib Ji · 27 Bhadon | Open calendar |
| Rehras | Rehras Sahib | Your evening bani, at the time you chose — 18 minutes. | Start · Later |
| Paath goal | {Bani} | Your paath goal for today — {n} of {m} done. | Start · Later |
"Later" snoozes 15 min (once). "Skip today" cancels today's Simran reminder. "Start" deep-links to the reader (autoplay if audio downloaded) or Simran screen. Reminders for a slot are **suppressed** if that slot is already completed today.

**Help:** Settings → Reminders → "Reminders not arriving?" opens a short page explaining battery optimisation per maker (Samsung, Xiaomi, Vivo/Oppo, OnePlus) with a button to `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` only if the user chooses.

**AC**
- [ ] Unit tests: Auto time for New Delhi, London, Vancouver on solstices and DST change days (±2 min vs NOAA reference).
- [ ] Changing a reminder to My time 20:00 fires at 20:00 ± 1 min with exact alarm allowed (manual QA, Doze on).
- [ ] After reboot, reminders still fire.

### 1.11 Daily Hukamnama — Design 24 (screen), 25 (share card)

- **Source:** `HukamnamaSource` interface. Default implementation: the chosen provider for Sri Darbar Sahib's daily Hukamnama (candidate: BaniDB API "today's Hukamnama"; confirm terms, §18). Payload: date, Ang, raag, writer, lines (Gurmukhi + Devanagari + Roman), meanings (pa/hi/en if available).
- **Fetch:** on app start if the cached date < today's IST date and time ≥ 04:00 IST (Hukamnama is issued early morning in Amritsar); daily `workmanager` job with network constraint; manual pull-to-refresh on the Hukamnama screen. Cache the last 30 days in `hukamnama_cache`. Diaspora users simply see the latest available one with its date.
- **Screen:** top bar with script switch; header card "Sri Darbar Sahib, Amritsar · Friday, 11 September · Ang 666 · Raag Dhanasari · Guru Ram Das Ji"; "Meaning in {lang}" selector; lines with meanings; "Rahao" line emphasised; actions **Listen** (feature-flagged — shown only if a licensed/permitted audio source is configured; SGPC has stated relaying its content without permission is not allowed), **Share card**; footer "Saved for offline reading · updated 4:02 AM".
- **Share card (1080 × 1920 PNG):** dark card (Design 25): app mark + "Ang Sang", "Today's Hukamnama", date + "Sri Darbar Sahib", the first two lines (Gurmukhi), the first line in Devanagari, English meaning of the first two lines, "Ang 666 · Raag Dhanasari · Guru Ram Das Ji", footer "Read daily on Ang Sang" + store link text. Rendered offscreen, previewed, then shared with `share_plus` (WhatsApp Status friendly). Card language follows `meanings_lang`.

**AC**
- [ ] Airplane mode on day 2 shows day 1's Hukamnama with its date.
- [ ] Share card text never overflows for long Hukamnamas (truncate after the Rahao line or 2 lines with "…read in Ang Sang").

### 1.12 Elder mode — Design 11

- Toggle in Setup 2 and Settings → Display. Applies app-wide: text ≥1.6× (reader minimum 30 sp), touch targets ≥ 64 dp, high-contrast colours, no small chips, no swipe-to-dismiss, bottom nav with **3 tabs** (Today, Nitnem, Settings) and larger labels.
- Elder Today (Design 11): "Large text on" chip; greeting; date; big primary card "Start Nitnem · from Japji Sahib · 63 min"; card "Listen to today's Hukamnama · Ang 666"; Amrit Vela status card (big ring, "5 banis · Japji Sahib in progress"); Rehras card with time.
- Elder mode never hides content (Simran, Diary remain reachable from Today/Settings).
- Phase 3 hook: "Set up a parent's phone by QR" — not in Phase 1.

### 1.13 Daily Simran — Design 21

- Simran tab. Title "Daily Simran — 5 quiet minutes of Naam Simran". Large ring timer (5:00 counting down) with ਵਾਹਿਗੁਰੂ in the centre (script follows the user's choice), "2:14 left of 5:00", **End** button.
- **Count:** optional — "Tap anywhere on the screen to count each Waheguru". Each tap increments the counter with light haptic; count shown under the ring.
- **Sound:** Silence / Soft drone / Bell at the end (bundled licensed sounds; no Gurbani audio here).
- Timer keeps running if the screen locks or the app is minimised (store start time; schedule an end-bell notification with sound as fallback). Screen stays on while visible.
- Completion (≥ 5 min) logs `simran_session(completed=true)` → Diary + Today tile "Done today ✓". Ending early logs a partial session (not counted as done).
- Below: "Done 9 of the last 10 days · Logged in Diary" and a static quote card "ਸਿਮਰਉ ਸਿਮਰਿ ਸਿਮਰਿ ਸੁਖੁ ਪਾਵਉ ॥ — Sukhmani Sahib" (from content.db).

### 1.14 Gurpurab & Nanakshahi calendar — Design 22

- Header card (primary): "TODAY · NANAKSHAHI — 26 Bhadon, 558 — Friday, 11 September 2026".
- Info line: "Reminders the evening before and on the morning of each day."
- Sections **This week** and **Coming up** (next 90 days; "Show more" loads the rest of the NS year). Row: date block (MON / day / weekday), event name (English or UI language), Gurmukhi name, Nanakshahi label ("27 Bhadon"), "Tomorrow"/"Today" chip, **bell** toggle (per-event override of the Gurpurab reminder).
- Filter icon: show Gurpurabs only / include Sangrand, Puranmashi, Masya.
- Footer: "Dates follow the SGPC calendar. They ship with the app and update once a year."
- **Nanakshahi date:** `CalendarService` uses bundled `nanakshahi_month.start_date` (Sangrand) rows: day = days since the month's Sangrand + 1; year label from the table. Unit-test against the SGPC jantri.
- If the current date is beyond bundled data: show "Update Ang Sang to see next year's calendar".

### 1.15 Paath goals — Design 19 (list), 20 (add sheet)

- Screen "Paath goals": summary "My paath goals — 1 of 3 done today · Fri, 11 Sep"; goal cards (max 10 active): progress ring, bani name (EN + Gurmukhi), rule text ("Once a day" / "5 times a day" / "For 40 days · 1 extra paath a day"), status ("Done today", "3 of 5 today", "Day 12 of 40 · pending"), reminder time. Tap → start the bani in the reader. "+1" button for manual ticks. Overflow: edit, pause, delete.
- **Add goal sheet:** Bani chips (Japji, Chaupai, Sukhmani, Anand, Rehras, More… → full bani list); **How many times a day** stepper 1–21 ("about 20 min each"); **For how long**: Every day / 40 days (or custom N days) / Until a date; **Reminder**: time + on/off; **Save goal**.
- Progress: every completed paath of that bani (read/listen) adds a `goal_tick` for each active goal for that bani, up to `times_per_day`; manual +1 allowed. A goal ends automatically after its duration and shows a gentle "Goal complete" card (text only; no badges or points).
- Footer: "Goals, counts and reminders stay on this phone and appear in your Diary."
- Entry points: Nitnem list card, Settings → Reminders → Paath goals, Diary.

### 1.16 Settings — Design 27

Sections and items (all persist immediately):
1. **Language** — App language: ਪੰਜਾਬੀ / हिन्दी / English (segmented).
2. **Reading** — Gurbani script (also switchable in reader) · Show meanings (language) · Pause marks · Larivaar · Text size · Keep screen on while reading · Follow audio.
3. **Audio** — Voice (paathi name) · Playback speed · Nitnem audio "Saved on this phone · 58 MB" (Remove / Download) · Sukhmani Sahib audio "Download when needed · 36 MB".
4. **Bani versions** — Rehras Sahib: SGPC · Anand Sahib (morning): Full · 40 pauris.
5. **Reminders** — Amrit Vela · Rehras Sahib · Kirtan Sohila · Daily Simran · Gurpurab days · Paath goals ("3 goals") · On-time reminders status ("Allowed — reminders arrive to the minute" / "Allow") · Sunrise & sunset for {city} · Reminders not arriving?
6. **Display** — Theme: Auto / Light / Dark · Elder mode.
7. **Diary** — Back up to Google account (status + link to system backup settings).
8. **About** — About & credits · Privacy · Share anonymous usage & crash reports (toggle) · Open-source licences · "Ang Sang {version}".

### 1.17 About, credits and privacy

- **About & credits:** app purpose; paathi name and recording credit; text source(s) with licence; meaning/teeka sources; transliteration source; calendar source (SGPC); city data credit; fonts (OFL); contact email; Play Store link; "No ads on Gurbani. No login. Works offline."
- **Privacy:** plain-language summary + link to the full policy on the project domain (hosted on Vercel). States: no account, no personal data collected; anonymous usage analytics and crash reports via Firebase (can be turned off); diary stays on the phone and in the user's own Google backup; location (if used) stays on the phone and is only used for sunrise/sunset.
- Must match the Play **Data safety** form exactly.

---
## 10. Design system implementation

Source: `design/tokens.json` and `design/html/00-Foundations.html`.

- **Colours:** implement `AngSangColors extends ThemeExtension` with every token in `tokens.json → color.light/dark` (`bg, card, card2, ink, ink2, muted, rule, primary, onPrimary, kesri, kesriSoft, kesriInk, sage, sageSoft, teal, hl, word, scrim`). Build the Material `ColorScheme` from them (primary, surface, onSurface, outline…). Note: in dark theme **primary becomes Kesri** (#F2A24E) and onPrimary is dark.
- **Type:** UI = Mukta; display/headlines & big numbers = Baloo Paaji 2; Gurbani = Noto Serif Gurmukhi / Noto Serif Devanagari. Body 15 sp / 1.45; eyebrow 12 sp, 600, uppercase, +0.08 em; buttons 16 sp 600. Reader defaults: Gurmukhi 22 sp, Devanagari 21 sp, Roman 18 sp, line height 1.7.
- **Shape:** cards 20 dp radius with the token shadow (light) / 1 px hairline (dark); buttons 16 dp radius, min height 52 dp; chips fully rounded; bottom sheets 28 dp top radius; nav active pill 58 × 32 dp on `kesriSoft`.
- **Motif:** the day arc (semicircle + sun + horizon) is the brand mark and appears in the app icon, splash, Today and intros. Build `AppMark` and `DayArc` as reusable widgets (CustomPainter).
- **Icons:** 24 dp outline, 1.8 stroke, round caps. Recreate the SVG paths from the HTML as `SvgPicture` assets or a small icon set; Material Symbols Rounded is acceptable for generic ones.
- **Motion:** 200–250 ms ease-out for most transitions; line highlight cross-fades 150 ms; no bouncy or celebratory animations on Gurbani screens.
- **Theme:** Auto (system) / Light / Dark. Designs show both; each screen has a `.light` and `.dark` render.
- **App icon:** app mark (navy arc, saffron sun) on `#F4F3F8`; adaptive icon + monochrome (Android 13 themed icons).

---

## 11. Localisation and accessibility

- Locales: `pa` (Gurmukhi script UI), `hi`, `en`. ARB keys named by feature (`today_cta_continue`). Use ICU plurals/placeholders. All strings — including notification text, share-card labels and store listing — are in three languages. Provide a `l10n_check` test that fails if any key is missing in a locale.
- Bani and event names come from content.db in all three languages.
- Dates: localised month/weekday names (`intl` with `pa_IN`, `hi_IN`, `en_IN`/`en_GB`). Times follow the device 12/24-h setting. Use Western digits in UI; Gurbani keeps its own numerals.
- Accessibility: TalkBack labels for every icon button; reader lines expose text semantics; current-line change is **not** announced (would interrupt paath); minimum touch target 48 dp (64 in elder mode); support system font scale up to 1.3× without clipping in UI screens (reader uses its own size); contrast ≥ 4.5:1 for body text in both themes.

---

## 12. Android platform specifics

**Manifest permissions**

| Permission | Why | When requested |
|---|---|---|
| `INTERNET`, `ACCESS_NETWORK_STATE` | Hukamnama, Firebase, asset packs | Normal |
| `POST_NOTIFICATIONS` | Reminders (13+) | Setup step 3 |
| `SCHEDULE_EXACT_ALARM` | On-time reminders (12+) | "Allow on-time reminders" card; never `USE_EXACT_ALARM` (reserved for alarm/calendar apps) |
| `RECEIVE_BOOT_COMPLETED` | Re-schedule reminders after reboot | Normal |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Background paath | Normal |
| `WAKE_LOCK` | Playback / Simran timer | Normal |
| `ACCESS_COARSE_LOCATION` | Optional "Use my location" for sunrise/sunset | Only when tapped |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Optional, from the help page | Only if the user chooses (justify in Play declaration) |

- **Backup:** `android:allowBackup="true"`, `dataExtractionRules` + `fullBackupContent` include `user.db*` and shared prefs; exclude `content.db`, asset packs, caches.
- **Asset packs:** Gradle `com.android.asset-pack` modules `nitnem_audio` (fast-follow) and `sukhmani_audio` (on-demand); app `assetPacks = [":nitnem_audio", ":sukhmani_audio"]`. Test with `bundletool build-apks --local-testing`.
- **Media:** `audio_service` `AudioServiceActivity`/`AudioService` wiring, notification small icon (monochrome mark), `android:foregroundServiceType="mediaPlayback"`.
- **Edge-to-edge & predictive back:** `enableOnBackInvokedCallback=true`; handle `MediaQuery.viewPadding` everywhere; transparent system bars matching theme.
- **R8/ProGuard:** keep rules for Play Core, Firebase, audio_service.
- **Signing:** Play App Signing; upload key stored outside the repo.

---

## 13. Analytics, privacy and non-functional requirements

**Analytics events** (no PII, no free text; respect `analytics_enabled`):
`onboarding_step{step}`, `onboarding_complete{lang,script,elder}`, `bani_open{bani,source}`, `bani_complete{bani,slot,mode(read|listen)}`, `audio_play{bani,speed}`, `follow_detach`, `follow_back`, `play_all`, `sleep_timer_set{value}`, `reminder_set{target,mode}`, `reminder_open{target}`, `exact_alarm_result{granted}`, `hukamnama_view`, `hukamnama_share`, `simran_complete{count_used}`, `goal_create{bani,times,duration}`, `goal_tick`, `gurpurab_view`, `setting_change{key}`, `audio_pack_state{pack,state}`.
User properties: `app_lang`, `script`, `elder_mode`, `theme`.

**Privacy:** no accounts, no advertising ID (`com.google.android.gms.permission.AD_ID` removed from the merged manifest; Analytics ad personalisation disabled), no location upload. Opt-out toggle disables Analytics and Crashlytics collection.

**Non-functional**

| Area | Requirement |
|---|---|
| Size | Base AAB download ≤ 25 MB; audio in packs only |
| Start-up | Cold start to interactive Today ≤ 1.5 s on a mid-range 2022 phone; ≤ 3 s on a 3 GB RAM budget phone |
| Smoothness | Reader scroll and highlight at 60 fps (no jank > 16 ms in profile mode for a 10-minute run) |
| Sync accuracy | Highlight within 100 ms (target) / 150 ms (max) of timing data |
| Battery | Position ticks only while reader/player UI is visible; background playback uses the media session only |
| Offline | Everything except Hukamnama refresh and pack downloads works in airplane mode |
| Reliability | Crash-free users ≥ 99.5 %; DB migrations tested |
| Security | No secrets in the repo; Firebase config via `google-services.json` (not committed for release builds if the repo is public) |

---

## 14. Testing strategy

- **Unit:** solar calculations; Auto reminder times; rolling schedule builder (≤ 60 pending); streak & grace; completion rules; goal progress; Nanakshahi date; timing lookup (binary search, word interpolation); CTA state machine; Hukamnama cache freshness.
- **Widget / golden:** every screen in `design/screens.json`, light + dark, en + pa + hi for Today, Reader, Settings. Compare against `design/screens/*.png` by eye during review (goldens protect against regressions, not pixel-match to HTML).
- **Integration (`integration_test`):** onboarding flow; open reader → play → auto-scroll → detach → Back to paath → tap line seek; Play all advancing banis; reminder deep link opens reader; Simran session logs to Diary.
- **Manual QA matrix:** Android 10 / 13 / 14 / 16 on Samsung, Xiaomi/Redmi, Pixel (or emulator), one 3 GB RAM device. Background playback, Bluetooth car kit, calls, unplug, Doze, reboot, time-zone change, low storage, pack download on mobile data.
- **Content QA:** pipeline report of word-alignment mismatches; scholar review sign-off of Devanagari for all Phase 1 banis before release.

---

## 15. Implementation milestones (for Claude Code)

Work in order. Each milestone = one or more PRs with tests; demo build at the end.

| # | Milestone | Deliverables | Done when |
|---|---|---|---|
| M0 | Scaffold | Flutter project `ang_sang` (org id e.g. `app.angsang`), flavors `dev`/`prod`, lints, Riverpod, go_router, theme from tokens, fonts, l10n skeleton (3 locales), Firebase wired (dev), CI | App runs with themed empty tabs in 3 languages |
| M1 | Content DB | `tools/content_pipeline` producing `content.db` (dev fixture from `design/data/` until licensed data arrives), drift schemas, `ContentRepository` | Unit tests pass; Japji renders from DB |
| M2 | Reader | Reader screen, scripts, meanings, vishraam, larivaar, text sheet, resume, keep-screen-on, next/prev | Matches Design 13–16 (no audio) |
| M3 | Audio + follow | Asset-pack plugin (+ dev fallback), `AngSangAudioHandler`, player bar, full player, timing lookup, highlight, auto-scroll, Back to paath, tap-to-seek, Play all | Follow-audio ACs pass with placeholder audio + timings |
| M4 | Background playback | Media notification, lock screen, Bluetooth, interruptions, sleep timer, process-death resume | 1.8 manual ACs pass |
| M5 | Onboarding + Today + Nitnem list | Splash, intros, setup 1–3 (without real scheduling), Today (day arc, CTA), Nitnem list | Fresh-install flow end to end |
| M6 | Reminders | Solar service, city picker, reminder model + sheet, scheduler, permissions, boot/time-zone handling, notification actions & deep links, help page | 1.10 ACs pass |
| M7 | Diary + goals + Simran | Completion logging, Diary screen, streak/grace, manual ticks, Paath goals + sheet + reminders, Daily Simran | 1.9, 1.13, 1.15 ACs pass |
| M8 | Hukamnama + share | Source adapter, cache, workmanager job, screen, share card | 1.11 ACs pass |
| M9 | Gurpurab | Calendar service, events screen, per-event reminders, Today tile | 1.14 done |
| M10 | Settings, elder mode, About | Settings screen, elder mode app-wide, About/credits/privacy/licences, analytics opt-out | 1.12, 1.16, 1.17 done |
| M11 | Hardening | Performance passes, accessibility, goldens, QA matrix, backup rules, R8, store assets | NFRs met; closed test build uploaded |

---

## 16. Release checklist (Google Play, personal account)

- [ ] Final licensed text, meanings, audio and verified timings in the build (no placeholders; search the repo for `PLACEHOLDER`).
- [ ] Scholar review sign-off for Gurmukhi and Devanagari text.
- [ ] targetSdk 36; AAB with asset packs; tested via internal testing track.
- [ ] Closed testing with ≥ 12 testers opted in for 14 continuous days; fix feedback; apply for production.
- [ ] Data safety form (analytics + crash data, not shared, not used for ads; no personal info), content rating (IARC), target audience (not directed at children), ads declaration = **No ads**.
- [ ] Exact-alarm and foreground-service (media playback) declarations completed.
- [ ] Privacy policy URL live on the project domain (Vercel).
- [ ] Store listing in English, Punjabi and Hindi; screenshots from the designs' real screens; keywords ਨਿਤਨੇਮ, नितनेम, Nitnem, Gutka Sahib, Japji Sahib, Sukhmani Sahib; "No ads on Gurbani, ever" in the description.
- [ ] Launch timing: ideally before Guru Nanak Dev Ji's Prakash Purab (24 Nov 2026).

---

## 17. Future-ready notes

### 17.1 Phase 2 hooks (build now, cheaply)

- UUID ids + `updated_at` on all user rows (sync-ready). Repositories behind interfaces so a `FirestoreDiarySync` can be added.
- Deep-link router already handles `angsang://` and can add `https://{domain}/…` App Links for invites.
- Reader and audio are bani-agnostic: extended banis are a content.db update.
- A `featureFlags` provider (local JSON) to hide unfinished features.

### 17.2 Phase 3 — iOS app (same Flutter codebase)

Decision: **Android only in Phases 1–2; iPhone app ships in Phase 3.** Everything in Phase 1 must stay iOS-portable.

| Area | Android (Phase 1) | iOS work in Phase 3 |
|---|---|---|
| Accounts & cost | Play personal account ($25 once) | Apple Developer Program ($99/year); seller name shown on the App Store |
| Build machine | Any PC | Mac with Xcode, or a cloud build service (e.g., Codemagic) |
| Testing | Closed test 12 × 14 days | TestFlight; App Store review |
| Audio packs | Play Asset Delivery | `AssetPackService` iOS adapter: Apple-hosted Background Assets packs (newer iOS) or first-run download from own storage (Phase 2 server); On-Demand Resources as legacy option |
| Background audio | Foreground service | `UIBackgroundModes: audio`; `audio_service` iOS setup; Now Playing info & remote commands |
| Reminders | Exact alarm permission + rolling 7-day window | No exact-alarm permission; **max 64 pending local notifications** → scheduler cap of 60 (already built in) |
| Notification permission | `POST_NOTIFICATIONS` | Provisional/standard authorisation prompt |
| Background refresh (Hukamnama) | WorkManager | `BGAppRefreshTask` best effort + fetch on open |
| Backup | Android Auto Backup | iCloud device backup of app documents |
| Sign-in (from Phase 2) | Google | Must also offer Sign in with Apple or an equivalent privacy-focused login if third-party login is used (App Store guideline 4.8) |
| Widgets (3.5) | Jetpack Glance/AppWidget | WidgetKit (Swift extension) via `home_widget` |
| Watch (3.4) | Wear OS Simran counter | Apple Watch Simran counter (watchOS, Swift) |
| Design | Material 3 custom | Same design; iOS swipe-back, Cupertino date/time pickers where natural, safe-area insets |
| Store | Play listing | App Store listing in 3 languages, privacy "nutrition label" |

---

## 18. Open decisions and blockers

| # | Item | Needed by | Default if undecided |
|---|---|---|---|
| D1 | **Gurbani text licence** — BaniDB is NPOSL-3.0 (non-profit, no revenue); confirm eligibility or get BaniDB Alliance approval; else choose another licensed source | Before public release (blocker) | Build pipeline source-agnostic; use fixtures in dev |
| D2 | Meanings/teeka sources for pa, hi, en and their licences | M1 content freeze | Ship with meanings off for any language not licensed |
| D3 | **Audio**: commission paathi recordings with written rights assignment (SGPC versions) | M3 final timings | Placeholder audio in dev |
| D4 | Hukamnama provider + terms; Hukamnama audio permission | M8 | Text only, Listen hidden |
| D5 | Bani versions beyond SGPC (Taksal/AKJ) | M2 | SGPC only |
| D6 | Analytics consent for EEA/UK users | M10 | Opt-out toggle; ask on first launch if device region is EEA/UK |
| D7 | Domain for privacy policy & share links | M10 | — |
| D8 | Full SGPC 558 (and 559) calendar data | M9 | Sample file only |
| D9 | Paathi display name/credit | M10 | "[Paathi name]" placeholder |
| D10 | Report an error | — | Phase 3 (confirmed by owner) |

---

## Appendix A — Screen index

| File stem | Screen | Feature | Frame | Designed theme |
|---|---|---|---|---|
| `00-Foundations` | Foundations — design system | Design system | 1280×1580 | light |
| `01-Splash` | Splash — first open | 1.1 | 390×844 | dark |
| `02-IntroAlwaysWithYou` | Intro 1 · Always with you | 1.1 | 390×844 | dark |
| `03-IntroReadAlong` | Intro 2 · Read along | 1.1 | 390×844 | dark |
| `04-IntroYourLanguage` | Intro 3 · Your language | 1.1 | 390×844 | dark |
| `05-SetupLanguage` | 1 · Setup — language | 1.2 | 390×844 | light |
| `06-SetupReading` | 2 · Setup — reading | 1.2 | 390×844 | light |
| `07-SetupReminders` | 3 · Setup — reminders (full scroll) | 1.2 / 1.10 | 390×1010 | light |
| `08-ReminderTime` | Pick your own reminder time | 1.10 | 390×844 | light |
| `09-Today` | Today (English) | 1.3 | 390×844 | light |
| `10-TodayHindi` | Today — हिन्दी, Amrit Vela dark | 1.3 | 390×844 | dark |
| `11-ElderMode` | Elder mode — ਪੰਜਾਬੀ | 1.12 | 390×844 | light |
| `12-NitnemList` | Nitnem list (full scroll) | 1.4 | 390×1230 | light |
| `13-ReaderFollowing` | Reader — following the audio | 1.5 / 1.6 | 390×844 | light |
| `14-ReaderMeanings` | Reader — meanings & pause marks | 1.5 | 390×844 | light |
| `15-ReaderHindiScrolled` | Reader — हिन्दी, scrolled away → Back to paath | 1.6 | 390×844 | light |
| `16-ReaderNight` | Reader — Amrit Vela dark | 1.5 | 390×844 | dark |
| `17-Player` | Full-screen player | 1.7 | 390×844 | dark |
| `18-BackgroundPlayback` | Minimised — notification & lock screen | 1.8 | 390×880 | dark |
| `19-PaathGoals` | Paath goals | 1.15 | 390×844 | light |
| `20-AddGoal` | Add a paath goal | 1.15 | 390×844 | light |
| `21-DailySimran` | Daily Simran — 5 minutes | 1.13 | 390×844 | dark |
| `22-GurpurabCalendar` | Gurpurab & Nanakshahi calendar (full scroll) | 1.14 | 390×1370 | light |
| `23-Notifications` | Reminder notifications | 1.10 | 390×844 | dark |
| `24-Hukamnama` | Hukamnama | 1.11 | 390×900 | light |
| `25-ShareCard` | Hukamnama share card (WhatsApp Status) | 1.11 | 360×640 | dark |
| `26-Diary` | Nitnem Diary | 1.9 | 390×844 | light |
| `27-Settings` | Settings (full scroll) | 1.16 / 1.17 | 390×2240 | light |

Every screen except Foundations has both `.light` and `.dark` HTML and PNG. The **designed theme** column is how the screen appears on the canvas; implement both.

*Sample content:* English and Hindi meanings in the designs are placeholder paraphrases; the paathi name, durations and download sizes are placeholders; Gurbani lines are from Japji Sahib, Sukhmani Sahib and the 11 Sep 2026 Hukamnama (Ang 666); Gurpurab dates follow the SGPC calendar for 558 NS.
