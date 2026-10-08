# 7. Simran and the globe

Rewritten 2026-10-07 with Puneet Singh Nanda. It replaces the earlier version
of this file entirely, including its "sitting now" heartbeat and "sat today"
counts. Every decision in Section 11 was confirmed by the owner on 2026-10-07.

## 0. Implementation directive (mandatory, read first)

1. **No inference.** Every behaviour, field, endpoint, limit and string comes from this document.
2. **The UI stays as it is** (owner, 2026-10-07): the wordmark, ੴ rule, verse, globe, legend and controls of the current screen. This document changes what the legend says, what the dots mean and where their numbers come from.
3. **Stop on ambiguity.** If anything required is missing or contradictory, stop and ask the developer.
4. **A sitting never needs the network.** Attendance and the globe are extras: when the server cannot be reached the sitting runs, is logged and marks hazri exactly as offline (`04-goals.md` §4.4).
5. **Server access follows the Profile PRD**: every call goes through the `api` Cloud Function under `/api/v1` with the anonymous ID token (`01-accounts.md` §6.0); Firestore rules deny all client access.
6. **No person is identifiable from the globe.** Nothing finer than a city from the app's own list, and no uid, name or count of one that could single somebody out beyond what a city total already shows.
7. **Strings are localised** in `pa`, `hi` and `en`; the implementer writes `pa` and `hi` and the owner verifies them (`01-accounts.md` §13.9).
8. **Done means tested.** Section 10 passes, `flutter analyze` is clean and `flutter test` passes.

## 1. Overview and requirement traceability

The Simran screen runs a sitting of Naam Simran and shows a globe of the sangat. Everybody with a profile is placed on the globe by the city in their profile, which is set when the profile is created. The first time somebody opens the app each day, the app marks their attendance once. The globe shows three kinds of dot: you, the people who opened the app today, and everybody else.

| Req # | Requirement (summary) | Where specified |
| --- | --- | --- |
| M1 | The UI stays as it is | 0.2 |
| M2 | With no simran goal, a sitting is 5 minutes | 4.1 |
| M3 | With Naam Simran in the goal, its minutes are the sitting's length | 4.1 |
| M4 | Three legend entries: You (orange, blinking on your city), Live (green), Here today (blue) | 2, 4.4, 8.1 |
| M5 | Dots grow with the number of users in a city | 4.5 |
| M6 | The first app open of the day marks attendance, once, with a local flag so no second call is made that day | 4.2, 6.1 |
| M7 | Opening Simran fetches the globe, counted by country, state and city, as light as possible | 4.3, 6.2 |
| M8 | The globe refreshes every 2 minutes | 4.3 |
| M9 | Server schema for this | 5 |

## 2. Definitions

| Term | Meaning |
| --- | --- |
| User | A profile (`01-accounts.md` §4.1). An install without a profile has no city: it sees the globe but is not on it and is not counted (S-9). |
| City | The profile's city, chosen from the app's city list when the profile is created (`01-accounts.md` §13 D9). It changes only when the person edits their profile (§13 D11 there). |
| Day | The calendar day in India Standard Time (UTC+05:30), the same for every user, so the whole globe resets at one moment. `dayIst` = `YYYY-MM-DD`. |
| Attendance | The call in 6.1, made once on the first app open of a day (4.2) |
| Live | A user whose last attendance was on today's `dayIst` |
| Counted | Every profile there is, including people who have since uninstalled the app |
| You | The user holding the phone |

### 2.1 The three dots, and how the counts split

Each counted user is drawn exactly once:

| Dot | Colour | Who | Count in a city |
| --- | --- | --- | --- |
| You | Orange, blinking | The user holding the phone | 1, in your own city only |
| Live | Green | Other users whose attendance is marked today | `live` − 1 in your city once your own attendance is marked, else `live` |
| Here today | Blue | Other counted users not marked today | `counted` − `live`, less 1 more in your city while your own attendance is not yet marked |

**Example:** the system counts 1,000 users and 500 of them, including you, opened the app today. The globe draws 1 orange, 499 green and 500 blue. Delhi counts 40 users with 25 live: someone outside Delhi sees a green dot of 25 and a blue dot of 15 there; someone in Delhi who opened the app today sees an orange dot, a green dot of 24 and a blue dot of 15.

## 3. Constants

| Constant | Value |
| --- | --- |
| `SIMRAN_DEFAULT_MINUTES` | 5 (shared with `04-goals.md` §3) |
| `GLOBE_REFRESH_SECONDS` | 120 |
| `GLOBE_SNAPSHOT_SECONDS` | 120 (how often the server rebuilds the globe) |
| `GLOBE_CACHE_SECONDS` | 60 (how long a function instance serves the snapshot from memory) |
| `DOT_MIN_RADIUS_PX` / `DOT_MAX_RADIUS_PX` | 3 / 14 |
| `YOU_BLINK_PERIOD_MS` | 1600 |

## 4. Rules

### 4.1 The sitting

- **SM1.** The sitting's length is `simranMinutes` of the simran goal item in scope today (`04-goals.md` §4.2), else `SIMRAN_DEFAULT_MINUTES`. The begin button shows it before the sitting starts. The Settings length (`settings.simranMinutes`) is removed. **(S-7)**
- **SM2.** Pause, Resume, End, survival across backgrounding and process death, and what a sitting stopped early records are unchanged and are specified by `04-goals.md` HZ1–HZ4: a sitting of 5 minutes or more marks hazri; it meets a simran goal only at the goal's minutes.
- **SM3.** Attendance and the globe never delay, block or change a sitting.

### 4.2 Attendance (marking the entry)

- **AT1. Once a day.** On the first app start or return to the foreground of a `dayIst`, the app calls `POST /api/v1/presence/attendance` (6.1). On success it saves that day locally (`presence_attendance_v1`, 7) and makes no further attendance call until the day changes.
- **AT2. Only with a profile.** The call is made only in `ProfileLoaded` (`01-accounts.md` §8.3). A profile created later in the day marks attendance at once.
- **AT3. Nothing is sent.** The body is empty. The server finds the profile from the uid (`owners/{uid}`), takes the day from its own clock, and never receives a city: the city is already on the profile.
- **AT4. Fire and forget.** A failed call leaves the local flag unset, so it is retried at the next start or resume that day. It is never shown and never blocks a screen.
- **AT5. City.** The city is set when the profile is created and changes only through Edit profile (`01-accounts.md` §13 D11). Attendance never sends or changes it; the next snapshot shows the person in their new city.

### 4.3 Fetching the globe

- **GB1.** Opening the Simran tab calls `GET /api/v1/presence/globe` (6.2) at once, then every `GLOBE_REFRESH_SECONDS` while the tab is visible, and again on return to the foreground. It stops when the tab is not visible.
- **GB2.** The response is one snapshot for everybody, built by the server every `GLOBE_SNAPSHOT_SECONDS` (5.4), so the call costs the same whether one person or a million are watching. It is not personalised: the app works out "You" itself (2.1).
- **GB3.** While a fetch fails, the globe keeps the last snapshot it had and shows `globeStale` under the legend once the snapshot is more than 10 minutes old. With no snapshot at all, only your own dot is drawn and the presence line reads `globeOffline`.

### 4.4 Drawing

- **DR1. Your dot** is orange and blinks with period `YOU_BLINK_PERIOD_MS` on your profile city's `lat`/`lon` from `content.db`. It is drawn from the cached profile on the phone, so it shows even offline. Without a profile there is no orange dot (NP1). With reduced motion on, it does not blink.
- **DR2. Live and Here today** are drawn per city from the snapshot, with the counts of 2.1. A count of 0 draws nothing.
- **DR3. Three dots in one city** sit side by side so none hides another: Here today 1.5 radii west of the city's point, Live 1.5 radii east, and You on the point itself, drawn last.
- **DR4. Legend:** `simranLegendYou` (orange), `simranLegendLive` (green), `simranLegendHere` (blue), in that order.
- **DR5. Presence line:** `globeLiveCount` with the snapshot's total `live`.
- **DR6. Threads** (owner, 2026-10-08, from design 29): a thread runs from your dot to every other dot drawn on the visible side of the globe, green and blue alike. Each is a quadratic curve bowed sideways by 14% of its length, kesri (`#F2A24E`), 0.7 logical px wide at 28% opacity, drawn under the dots. A thread to a dot on the far side is not drawn (SZ2). With at most two dots per city on the list, there are never more than about 190 threads, so they are always drawn. Without a profile there is no dot to start from, so DR7 draws the threads instead. They do not move except with the globe.
- **DR7. Threads without a profile** (owner, 2026-10-08): every dot is still connected. The threads join all the dots into one web: the shortest tree that reaches every dot (each dot linked to the web by its shortest great-circle link, Prim's algorithm), plus a thread from each dot to its 2 nearest. Each pair is drawn once, in the style of DR6, and only when both ends are on the visible side. The web is computed when a snapshot arrives, never per frame; with about 184 dots it is under 600 threads.

### 4.4a Without a profile

- **NP1.** Somebody without a profile sees the globe exactly as everybody else does: the snapshot is fetched (4.3) and every green and blue dot drawn, with nobody taken off for themselves, because they are not counted.
- **NP2.** There is no orange dot and no attendance call. The threads are drawn as a web joining all the dots (DR7).
- **NP3.** A banner under the legend reads `globeProfileBanner`. Tapping it opens Profile Setup (`01-accounts.md` §8.5). It is not dismissible, and it goes as soon as a profile exists, at which point the orange dot appears and attendance is marked (AT2).

### 4.5 Dot size

- **SZ1.** Radius in logical pixels = `DOT_MIN_RADIUS_PX` + (`DOT_MAX_RADIUS_PX` − `DOT_MIN_RADIUS_PX`) × √(count ÷ largest count among all green and blue dots in the snapshot), rounded to one decimal. Area therefore grows with the number of people, and the largest city always draws at the maximum.
- **SZ2.** A dot on the far side of the globe is not drawn (as now).

### 4.6 Privacy

- **PV1.** Attendance stores one more field on the profile, the last day it was marked (`lastSeenDay`, 5.2). No device data and no position finer than the profile's city.
- **PV2.** The snapshot holds city totals only. No uid, profile ID or name ever leaves the server through it.
- **PV3.** Only people who created a profile are on the globe, and they gave their city when they did. The privacy screen and PRD §13.1 still change to say that the profile's city is shown on the globe as a count and that the day of the last visit is recorded.

## 5. Server schema (Firestore, `asia-south1`)

Only the Cloud Function reads and writes these. Conventions as `01-accounts.md` §4: camelCase, server timestamps, rules deny all.

### 5.1 City reference

`tools/content_pipeline/cities.json`, the source of the app's `city` table, gains a `state` field: an ISO 3166-2 subdivision code such as `IN-DL` or `CA-BC`. The pipeline writes it into `content.db` as `state_code`, and also writes `functions/src/cities.json` (id, country, state) so the app and the server read one list. Every city in it must have a state; the pipeline fails otherwise.

### 5.2 Fields on `profiles/{profileId}`

No new collection. Two fields of the profile (`01-accounts.md` §4.1, amended by §13 D9 and D10) carry everything:

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `cityId` | string | no | A `cities.json` id, set at creation, changed only by a profile update |
| `lastSeenDay` | string | yes | `dayIst` of the last attendance; null until the first. Written only by 6.1, which does not change `updatedAt`. |

### 5.3 Index

```json
{ "collectionGroup": "profiles", "queryScope": "COLLECTION",
  "fields": [ { "fieldPath": "cityId", "order": "ASCENDING" },
              { "fieldPath": "lastSeenDay", "order": "ASCENDING" } ] }
```

### 5.4 `presenceSnapshot/current`

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

## 6. API

Both endpoints follow `01-accounts.md` §6.0 (Bearer ID token, error body, `401`, `500`).

### 6.1 `POST /api/v1/presence/attendance`

Request body: `{}`.

1. Read `owners/{callerUid}`; missing → `404 NO_PROFILE`. Read the profile.
2. If `lastSeenDay` is already today, return 200 without writing.
3. Otherwise set `lastSeenDay` = today. `updatedAt` is not changed.

| Status | Body |
| --- | --- |
| 200 | `{ "result": "ATTENDANCE_MARKED", "day": "2026-10-07" }` |
| 404 | `NO_PROFILE` |

Cost: 2 reads and at most 1 write per user per day. The app's local flag (AT1) means a second call that day is not made at all.

### 6.2 `GET /api/v1/presence/globe`

Returns the snapshot of 5.4 exactly as stored, with `builtAt` as an ISO string. A function instance keeps the snapshot in memory for `GLOBE_CACHE_SECONDS`, so the endpoint reads Firestore at most once a minute per instance, at most 10 instances (`00-platform.md` §0.1), whatever the number of viewers. City names and positions are never sent: the app has them in `content.db`.

| Status | Body |
| --- | --- |
| 200 | The snapshot, gzip-compressed |
| 503 | `GLOBE_NOT_READY` when no snapshot has been built yet |

### 6.3 Cost

| Item | Firestore cost |
| --- | --- |
| Attendance | 2 reads + ≤ 1 write per user per day |
| Snapshot | 2 aggregations per city every 2 minutes (each 1 read per 1,000 users matched, minimum 1): about 2 × cities × 720 reads a day |
| Globe reads | ≤ 10 instances × 1 read a minute |

## 7. Local storage on the phone

| Key | Meaning |
| --- | --- |
| `presence_attendance_v1` | `dayIst` of the last successful attendance (AT1) |
| `presence_snapshot_v1` | The last snapshot received, so the globe draws at once on the next open (GB3) |

## 8. App behaviour

### 8.1 Screen

Unchanged layout (0.2), drawn as designs 88, 89 and 90. The legend shows the three entries of DR4; the presence line shows DR5; the globe draws DR1–DR3 with the sizes of 4.5, and the threads of DR6.

### 8.2 Strings

| Key | English |
| --- | --- |
| `simranLegendYou` | You (existing) |
| `simranLegendLive` | Live |
| `simranLegendHere` | Here today (existing key, new meaning) **(S-1)** |
| `globeLiveCount` | {count} live today |
| `globeStale` | Last updated {time} |
| `globeOffline` | Can't reach the sangat right now |
| `globeProfileBanner` | Create your profile to see yourself on the globe |

## 9. Scenarios

| # | Given | When | Then |
| --- | --- | --- | --- |
| G-1 | No simran goal | Opening Simran | Begin shows 5 minutes |
| G-2 | Simran goal of 11 minutes in scope | Opening Simran | Begin shows 11 minutes |
| G-3 | Profile in Delhi, first open of the day | App starts | One attendance call; the profile's `lastSeenDay` is today; the local flag is set |
| G-4 | Attendance already marked today | App resumed five times | No further calls |
| G-5 | Attendance call failed this morning | App resumed in the afternoon | Called again, because the flag was never set |
| G-6 | No profile | Simran opens | Other users' green and blue dots, uncorrected for self; no orange dot; `globeProfileBanner` shown; no attendance call |
| G-6a | No profile, banner shown | Profile created | Banner gone; orange dot on the chosen city; attendance marked |
| G-7 | 1,000 profiles, 500 marked today including you | Simran opens | 1 orange, 499 green, 500 blue across their cities |
| G-8 | Delhi: 40 profiles, 25 marked today; you are in Amritsar | Simran opens | Delhi shows green 25 and blue 15 |
| G-9 | Delhi: 40 profiles, 25 marked today; you are in Delhi and marked | Simran opens | Delhi shows orange, green 24 and blue 15 |
| G-10 | A user uninstalled the app months ago | Next snapshot | Still counted, in blue |
| G-11 | Simran open | 2 minutes pass | One fetch; dots update |
| G-12 | Simran tab not visible | 10 minutes pass | No fetches |
| G-13 | Offline | Opening Simran | Your dot blinks; last snapshot drawn if one is saved, else `globeOffline`; the sitting works |
| G-14 | 00:00 IST passes | Next snapshot | Everybody not yet marked on the new day moves from green to blue; the next app open marks again |
| G-15 | 20,000 attendances in 5 minutes | — | Each writes only its own profile; the next snapshot counts them |
| G-16 | Reduced motion on | Simran open | Your dot does not blink; nothing else changes |
| G-17 | Profile in Amritsar; dots in Delhi, Southall and Toronto, Toronto on the far side | Simran open | Two threads from Amritsar, to Delhi and Southall; none to Toronto |
| G-18 | No profile; dots in Europe, the Gulf and India | Simran open | One web of threads joining every visible dot; Europe is linked to the Gulf, not left on its own |
| G-19 | The globe is turned by hand | — | The threads turn with it; one whose far end goes over the horizon disappears |

## 10. Acceptance checklist

- [ ] Unit: the count split of 2.1 for you inside and outside a city, live and not live.
- [ ] Unit: SZ1 radii, including a snapshot where every count is equal.
- [ ] Widget: DR6 threads to every visible dot, none to the far side. Unit: DR7's web reaches every dot (one connected component) and draws each pair once.
- [ ] Unit: AT1 calls at most once per `dayIst`, sets the flag only on success, and AT2 never calls without a profile.
- [ ] Unit: SM1 length from the goal, else 5.
- [ ] Backend (emulator): attendance statuses and idempotence, and that it leaves `updatedAt` alone; the snapshot counts live and counted correctly across a day change; `GLOBE_NOT_READY` before the first build.
- [ ] Rules test: clients cannot read or write `profiles` or `presenceSnapshot`.
- [ ] Pipeline: fails when a city has no `state`.
- [ ] Device: two phones in two cities show each other as green within 4 minutes of opening the app.

## 11. Decisions

| # | Question | Decision |
| --- | --- | --- |
| S-1 | Legend labels | **Decided 2026-10-07:** as the owner wrote them. Live (green) is opened the app today; Here today (blue) is everybody else. |
| S-2 | Is the user counted in the green? | **Decided 2026-10-07:** no, one is taken off for yourself (2.1) |
| S-3 | Whose midnight starts "today"? | **Decided 2026-10-07:** India Standard Time for everybody |
| S-4 | Who is counted? | **Decided 2026-10-07:** every profile, including people who have uninstalled the app |
| S-5 | Add a state to each city | **Decided 2026-10-07:** yes (5.1) |
| S-6 | Is the city sent daily? | **Decided 2026-10-07:** no. The city is set when the profile is created and changes only when the profile is updated. The daily call marks attendance only, once, with a local flag (4.2). |
| S-7 | Settings simran length | **Decided 2026-10-07:** removed |
| S-8 | Old "sitting now" and "sat today" | **Decided 2026-10-07:** removed |
| S-9 | Somebody without a profile | **Decided 2026-10-07:** sees everybody else on the globe, has no orange dot, is not counted, and gets a banner to create a profile (4.4a) |
| S-10 | The profile's city comes from the app's list of 92 cities | **Decided 2026-10-07:** yes; somebody whose city is not on it picks the nearest. Cities are added through `tools/content_pipeline/cities.json`. |
| S-11 | Connecting lines on the globe | **Decided 2026-10-08:** yes, design 29's threads from your dot to every other (DR6); without a profile, a web joining all the dots (DR7) |

## 12. Out of scope

- The sitting's controls, the recitation and ਵਾਹਿਗੁਰੂ drifting off the globe: unchanged.
- Showing who anybody is, or any position finer than a city.
- Month totals and country counts (design 29) beyond what the snapshot already carries.
- Sangat groups on the globe: the sangat feature document will say whether they appear.
