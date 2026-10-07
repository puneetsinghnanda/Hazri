# 7. Simran and the globe

Rewritten 2026-10-07 with Puneet Singh Nanda. It replaces the earlier version
of this file entirely, including its "sitting now" heartbeat and "sat today"
counts. Decisions in Section 11 not marked **Decided** carry a default the
owner has not confirmed yet; per §0.3, stop and ask before building a part
that rests on one.

## 0. Implementation directive (mandatory, read first)

1. **No inference.** Every behaviour, field, endpoint, limit and string comes from this document.
2. **The UI stays as it is** (owner, 2026-10-07): the wordmark, ੴ rule, verse, globe, legend and controls of the current screen. This document changes what the legend says, what the dots mean and where their numbers come from.
3. **Stop on ambiguity.** If anything required is missing or contradictory, stop and ask the developer.
4. **A sitting never needs the network.** The check-in and the globe are extras: when the server cannot be reached the sitting runs, is logged and marks hazri exactly as offline (`04-goals.md` §4.4).
5. **Server access follows the Profile PRD**: every call goes through the `api` Cloud Function under `/api/v1` with the anonymous ID token (`01-accounts.md` §6.0); Firestore rules deny all client access.
6. **No person is identifiable from the globe.** Nothing finer than a city from the app's own list, and no uid, name or count of one that could single somebody out beyond what a city total already shows.
7. **Strings are localised** in `pa`, `hi` and `en`; the implementer writes `pa` and `hi` and the owner verifies them (`01-accounts.md` §13.8).
8. **Done means tested.** Section 10 passes, `flutter analyze` is clean and `flutter test` passes.

## 1. Overview and requirement traceability

The Simran screen runs a sitting of Naam Simran and shows a globe of the sangat. Every install tells the server once a day which city it is in. The globe shows three kinds of dot: you, the people who opened the app today, and everybody else.

| Req # | Requirement (summary) | Where specified |
| --- | --- | --- |
| M1 | The UI stays as it is | 0.2 |
| M2 | With no simran goal, a sitting is 5 minutes | 4.1 |
| M3 | With Naam Simran in the goal, its minutes are the sitting's length | 4.1 |
| M4 | Three legend entries: You (orange, blinking on your city), Live (green), Here today (blue) | 2, 4.4, 8.1 |
| M5 | Dots grow with the number of users in a city | 4.5 |
| M6 | Every app open calls the API to mark the user's entry | 4.2, 6.1 |
| M7 | Opening Simran fetches the globe, counted by country, state and city, as light as possible | 4.3, 6.2 |
| M8 | The globe refreshes every 2 minutes | 4.3 |
| M9 | Server schema for this | 5 |

## 2. Definitions

| Term | Meaning |
| --- | --- |
| User | One install of the app, identified by its anonymous Firebase uid (`01-accounts.md` §1). A profile is not needed. |
| City | The city chosen in Settings from the app's own list (`cityId`, `content.db` table `city`). Never the free-text city of the profile, and never a GPS position. |
| Day | The calendar day in India Standard Time (UTC+05:30), the same for every user, so the whole globe resets at one moment. `dayIst` = `YYYY-MM-DD`. **(S-3)** |
| Check-in | The call in 6.1, made when the app is opened (4.2) |
| Live | A user whose last check-in was on today's `dayIst` |
| Counted | A user whose last check-in was within the last `PRESENCE_ACTIVE_DAYS` days. Installs that have gone quiet drop out, so an uninstalled phone is not counted for ever. **(S-4)** |
| You | The user holding the phone |

### 2.1 The three dots, and how the counts split

Each counted user is drawn exactly once:

| Dot | Colour | Who | Count in a city |
| --- | --- | --- | --- |
| You | Orange, blinking | The user holding the phone | 1, in your own city only |
| Live | Green | Other users who checked in today | `live` − 1 in your city (you are live once you have checked in), else `live` |
| Here today | Blue | Other counted users who have not checked in today | `counted` − `live` |

**Example** (with the default of S-2): the system counts 1,000 users and 500 of them, including you, opened the app today. The globe draws 1 orange, 499 green and 500 blue. Delhi counts 40 users with 25 live: someone outside Delhi sees a green dot of 25 and a blue dot of 15 there; someone in Delhi who opened the app today sees an orange dot, a green dot of 24 and a blue dot of 15.

## 3. Constants

| Constant | Value |
| --- | --- |
| `SIMRAN_DEFAULT_MINUTES` | 5 (shared with `04-goals.md` §3) |
| `GLOBE_REFRESH_SECONDS` | 120 |
| `GLOBE_SNAPSHOT_SECONDS` | 120 (how often the server rebuilds the globe) |
| `GLOBE_CACHE_SECONDS` | 60 (how long a function instance serves the snapshot from memory) |
| `PRESENCE_ACTIVE_DAYS` | 90 **(S-4)** |
| `DOT_MIN_RADIUS_PX` / `DOT_MAX_RADIUS_PX` | 3 / 14 |
| `YOU_BLINK_PERIOD_MS` | 1600 |

## 4. Rules

### 4.1 The sitting

- **SM1.** The sitting's length is `simranMinutes` of the simran goal item in scope today (`04-goals.md` §4.2), else `SIMRAN_DEFAULT_MINUTES`. The begin button shows it before the sitting starts. The Settings length (`settings.simranMinutes`) is removed. **(S-7)**
- **SM2.** Pause, Resume, End, survival across backgrounding and process death, and what a sitting stopped early records are unchanged and are specified by `04-goals.md` HZ1–HZ4: a sitting of 5 minutes or more marks hazri; it meets a simran goal only at the goal's minutes.
- **SM3.** The check-in and the globe never delay, block or change a sitting.

### 4.2 Check-in (marking the entry)

- **CI1. When.** On every app start and every return to the foreground, the app checks in **unless** it already has a successful check-in for today's `dayIst` with the current `cityId`. So the call is made at most once a day, plus once after a change of city.
- **CI2. Who.** Every install, with or without a profile or the sangat, once it has a city. **(S-6)**
- **CI3. What is sent:** the `cityId` and nothing else. The server takes the uid from the ID token and the day from its own clock.
- **CI4. Fire and forget.** A failed check-in is retried at the next start or resume. It is never shown to the user and never blocks a screen.
- **CI5. Change of city** in Settings triggers a check-in at once (CI1), which moves the user to the new city on the server.

### 4.3 Fetching the globe

- **GB1.** Opening the Simran tab calls `GET /api/v1/presence/globe` (6.2) at once, then every `GLOBE_REFRESH_SECONDS` while the tab is visible, and again on return to the foreground. It stops when the tab is not visible.
- **GB2.** The response is one snapshot for everybody, built by the server every `GLOBE_SNAPSHOT_SECONDS` (5.4), so the call costs the same whether one person or a million are watching. It is not personalised: the app works out "You" itself (2.1).
- **GB3.** While a fetch fails, the globe keeps the last snapshot it had and shows `globeStale` under the legend once the snapshot is more than 10 minutes old. With no snapshot at all, only your own dot is drawn and the presence line reads `globeOffline`.

### 4.4 Drawing

- **DR1. Your dot** is orange and blinks with period `YOU_BLINK_PERIOD_MS` on your city's `lat`/`lon` from `content.db`. It is drawn from the phone's own settings, so it shows even offline. With reduced motion on, it does not blink.
- **DR2. Live and Here today** are drawn per city from the snapshot, with the counts of 2.1. A count of 0 draws nothing.
- **DR3. Three dots in one city** sit side by side so none hides another: Here today 1.5 radii west of the city's point, Live 1.5 radii east, and You on the point itself, drawn last.
- **DR4. Legend:** `simranLegendYou` (orange), `simranLegendLive` (green), `simranLegendHere` (blue), in that order.
- **DR5. Presence line:** `globeLiveCount` with the snapshot's total `live`.

### 4.5 Dot size

- **SZ1.** Radius in logical pixels = `DOT_MIN_RADIUS_PX` + (`DOT_MAX_RADIUS_PX` − `DOT_MIN_RADIUS_PX`) × √(count ÷ largest count among all green and blue dots in the snapshot), rounded to one decimal. Area therefore grows with the number of people, and the largest city always draws at the maximum.
- **SZ2.** A dot on the far side of the globe is not drawn (as now).

### 4.6 Privacy

- **PV1.** The server stores, per user, only the uid, the `cityId`, the last check-in day and the first check-in day (5.2). No name, no email, no position, no device data.
- **PV2.** The snapshot holds city totals only. No uid ever leaves the server.
- **PV3.** This sends data for people who never join the sangat, which changes CLAUDE.md rule 4 and PRD §13.1. The privacy screen and §13.1 are rewritten in the same change that ships it. **(S-6)**

## 5. Server schema (Firestore, `asia-south1`)

Only the Cloud Function reads and writes these. Conventions as `01-accounts.md` §4: camelCase, server timestamps, rules deny all.

### 5.1 City reference

`tools/content_pipeline/cities.json`, the source of the app's `city` table, gains a `state` field: an ISO 3166-2 subdivision code such as `IN-DL` or `CA-BC`. The pipeline writes it into `content.db` as `state_code`, and also writes `functions/src/cities.json` (id, country, state) so the app and the server read one list. Every city in it must have a state; the pipeline fails otherwise.

### 5.2 `presenceUsers/{uid}`

One document per install.

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `cityId` | string | no | A `cities.json` id |
| `lastDay` | string | no | `dayIst` of the last check-in |
| `firstDay` | string | no | `dayIst` of the first check-in |
| `updatedAt` | timestamp | no | Server timestamp on every write |

### 5.3 Index

```json
{ "collectionGroup": "presenceUsers", "queryScope": "COLLECTION",
  "fields": [ { "fieldPath": "cityId", "order": "ASCENDING" },
              { "fieldPath": "lastDay", "order": "ASCENDING" } ] }
```

### 5.4 `presenceSnapshot/current`

One document, rebuilt by the scheduled function `buildGlobeSnapshot` every `GLOBE_SNAPSHOT_SECONDS`:

1. For each city in `cities.json`, two `count()` aggregation queries on `presenceUsers`: `lastDay == today` (live) and `lastDay >= today − PRESENCE_ACTIVE_DAYS + 1` (counted).
2. Cities with a counted total of 0 are left out.
3. The result is written as below. It replaces the previous document.

| Field | Type | Rule |
| --- | --- | --- |
| `day` | string | `dayIst` it was built for |
| `builtAt` | timestamp | Server time |
| `live` | number | Total live users |
| `counted` | number | Total counted users |
| `countries` | map | `{ "IN": { "l": 480, "c": 950, "s": { "IN-DL": { "l": 25, "c": 40, "k": { "new_delhi": [25, 40] } } } } }`: `l` live, `c` counted, `s` states, `k` cities as `[live, counted]` |

Counting on a schedule rather than keeping counters means no document is written by more than one check-in, so a burst at Amrit Vela cannot run into Firestore's per-document write limit, and the numbers can never drift.

## 6. API

Both endpoints follow `01-accounts.md` §6.0 (Bearer ID token, error body, `401`, `500`).

### 6.1 `POST /api/v1/presence/checkin`

Request: `{ "cityId": "new_delhi" }`

1. `cityId` not in `cities.json` → `400 VALIDATION_ERROR` (`fields.cityId`).
2. Read `presenceUsers/{callerUid}`. If its `lastDay` is today and its `cityId` matches, return 200 without writing.
3. Otherwise set `cityId`, `lastDay` = today, `updatedAt`, and `firstDay` = today when the document is new.

| Status | Body |
| --- | --- |
| 200 | `{ "result": "CHECKED_IN", "day": "2026-10-07" }` |
| 400 | `VALIDATION_ERROR` |

Cost: 1 read and at most 1 write per user per day.

### 6.2 `GET /api/v1/presence/globe`

Returns the snapshot of 5.4 exactly as stored, with `builtAt` as an ISO string. A function instance keeps the snapshot in memory for `GLOBE_CACHE_SECONDS`, so the endpoint reads Firestore at most once a minute per instance, at most 10 instances (`00-platform.md` §0.1), whatever the number of viewers. City names and positions are never sent: the app has them in `content.db`.

| Status | Body |
| --- | --- |
| 200 | The snapshot, gzip-compressed |
| 503 | `GLOBE_NOT_READY` when no snapshot has been built yet |

### 6.3 Cost

| Item | Firestore cost |
| --- | --- |
| Check-ins | 1 read + ≤ 1 write per user per day |
| Snapshot | 2 aggregations per city every 2 minutes (each 1 read per 1,000 users matched, minimum 1): about 2 × cities × 720 reads a day |
| Globe reads | ≤ 10 instances × 1 read a minute |

## 7. Local storage on the phone

| Key | Meaning |
| --- | --- |
| `presence_checkin_v1` | `{ "day": "YYYY-MM-DD", "cityId": "..." }` of the last successful check-in (CI1) |
| `presence_snapshot_v1` | The last snapshot received, so the globe draws at once on the next open (GB3) |

## 8. App behaviour

### 8.1 Screen

Unchanged layout (0.2). The legend shows the three entries of DR4; the presence line shows DR5; the globe draws DR1–DR3 with the sizes of 4.5.

### 8.2 Strings

| Key | English |
| --- | --- |
| `simranLegendYou` | You (existing) |
| `simranLegendLive` | Live |
| `simranLegendHere` | Here today (existing key, new meaning) **(S-1)** |
| `globeLiveCount` | {count} live today |
| `globeStale` | Last updated {time} |
| `globeOffline` | Can't reach the sangat right now |

## 9. Scenarios

| # | Given | When | Then |
| --- | --- | --- | --- |
| G-1 | No simran goal | Opening Simran | Begin shows 5 minutes |
| G-2 | Simran goal of 11 minutes in scope | Opening Simran | Begin shows 11 minutes |
| G-3 | First open of the day, city Delhi | App starts | One check-in; the server has `lastDay` = today |
| G-4 | Already checked in today | App resumed five times | No further calls |
| G-5 | City changed from Delhi to Amritsar | Saving Settings | Check-in at once; the next snapshot counts the user in Amritsar |
| G-6 | 1,000 counted, 500 live including you | Simran opens | 1 orange, 499 green, 500 blue across their cities |
| G-7 | Delhi: 40 counted, 25 live; you are in Amritsar | Simran opens | Delhi shows green 25 and blue 15 |
| G-8 | Delhi: 40 counted, 25 live; you are in Delhi and live | Simran opens | Delhi shows orange, green 24 and blue 15 |
| G-9 | Simran open | 2 minutes pass | One fetch; dots update |
| G-10 | Simran tab not visible | 10 minutes pass | No fetches |
| G-11 | Offline | Opening Simran | Your dot blinks; last snapshot drawn if one is saved, else `globeOffline`; the sitting works |
| G-12 | A user last seen 91 days ago | Next snapshot | Not counted |
| G-13 | 00:00 IST passes with Simran open | Next snapshot | Everybody not yet checked in on the new day moves from green to blue |
| G-14 | An unknown `cityId` sent | Check-in | `400`; nothing stored |
| G-15 | 20,000 check-ins in 5 minutes | — | Each writes only its own document; the next snapshot counts them |
| G-16 | Reduced motion on | Simran open | Your dot does not blink; nothing else changes |

## 10. Acceptance checklist

- [ ] Unit: the count split of 2.1 for you inside and outside a city, live and not live.
- [ ] Unit: SZ1 radii, including a snapshot where every count is equal.
- [ ] Unit: CI1 calls at most once per `dayIst` and again on a city change.
- [ ] Unit: SM1 length from the goal, else 5.
- [ ] Backend (emulator): check-in statuses and idempotence; the snapshot counts live and counted correctly across a day change and the 90-day edge; `GLOBE_NOT_READY` before the first build.
- [ ] Rules test: clients cannot read or write `presenceUsers` or `presenceSnapshot`.
- [ ] Pipeline: fails when a city has no `state`.
- [ ] Device: two phones in two cities show each other as green within 4 minutes of opening the app.

## 11. Decisions

| # | Question | Default used above |
| --- | --- | --- |
| S-1 | The labels: "Live" (green) is users who opened the app today, and "Here today" (blue) is everybody else in the sangat. "Here today" reads as "opened today", so should the blue entry say something like "Sangat" instead? | The owner's labels, as written |
| S-2 | Are you counted inside the green? The owner's example (1,000 users, 500 today: 1 orange, 500 green, 499 blue) puts you in neither green nor the 500 | You are drawn once, as orange; green is the other live users (1, 499, 500) |
| S-3 | Whose midnight starts "today"? | India Standard Time for everybody |
| S-4 | How long does a quiet install stay counted? | 90 days since its last check-in |
| S-5 | The city lists have no state; add one to each of the 92 cities? | Yes (5.1) |
| S-6 | Every install now sends its city daily, including people who never join the sangat. That changes CLAUDE.md rule 4 and the privacy screen. Should there be a switch to stay off the globe? | Sent by every install; no switch. Rule 4, PRD §13.1 and the privacy screen change with it |
| S-7 | Is the Settings simran length removed, so a sitting is always 5 minutes or the goal's minutes? | Removed |
| S-8 | The old "sitting now" heartbeat and "sat today" counts go entirely? | Yes |

## 12. Out of scope

- The sitting's controls, the recitation and ਵਾਹਿਗੁਰੂ drifting off the globe: unchanged.
- Showing who anybody is, or any position finer than a city.
- Month totals and country counts (design 29) beyond what the snapshot already carries.
- Sangat groups on the globe: the sangat feature document will say whether they appear.
