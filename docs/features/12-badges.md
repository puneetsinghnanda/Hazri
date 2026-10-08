# 12. Badges

Written 2026-10-08 with Puneet Singh Nanda. It is PRD §3.2, "Points and
badges", as decided that day: **badges, and no points.** It resolves PRD
decisions D11 (the names) and D14 (points and Gurbani), and every decision in
Section 12 was confirmed by the owner on 2026-10-08 unless it says otherwise.

## 0. Implementation directive (mandatory, read first)

1. **No inference.** Every rule, threshold, field and endpoint comes from this document.
2. **No points, ever.** No score, no XP, no total, no exchange rate between banis. PRD §0's "No points or XP for Gurbani" stays true as written.
3. **Derived, never a second record of practice.** Every badge is a rule over rows that already exist: `completions` and `simranSessions` (`04-goals.md` §5), and two Sangat facts the server already holds (5). Nothing counts paath beside the Diary. The only new stored data is which badges were earned and when (4).
4. **Nothing is ever taken away.** No decay, no expiry, no reset. A missed day costs nothing.
5. **Never a ranking.** No leaderboard, no comparison with anybody, no "ahead of others".
6. **Strings are localised** in `pa`, `hi` and `en` (CLAUDE.md rule 5).
7. **Stop on ambiguity.** If anything required is missing or contradictory, stop and ask.

## 1. Requirement traceability

| Req # | Requirement (owner, 2026-10-08) | Where |
| --- | --- | --- |
| BR1 | Ten named badges awarded for what the person does in the app | 2, 3 |
| BR2 | Not points, and not minutes of bani recited: days and milestones | 0.2, 3 |
| BR3 | Gyani is replaced by Vichari; Pracharak by Satsangi | 2 |
| BR4 | Vichari is hazri on 365 days, with no condition on meanings | 3 |
| BR5 | A missed day resets nothing; counts are totals, not runs | 3, HC3 |
| BR6 | Hazri is counted on the phone from local data | 3.1 |
| BR7 | The hazri count is recalculated, not stored; earned badges are stored | 3.1, 4 |
| BR8 | Earned badges are in the weekly backup and come back on restore | 6 |
| BR9 | Days already in the Diary count when badges ship | 7.3 |
| BR10 | Satsangi counts members who join groups the person created | 3, 5 |
| BR11 | Nitnemi counts the five morning banis only | 3.1 |
| BR12 | A badge is announced in the app, in a bottom sheet with the badge, its name and its details, and a button to all badges | 7.2 |
| BR13 | A Badges page in the profile: earned badges in colour, the rest greyed, each with its name and how it is earned | 7.1 |
| BR14 | Earned badges show in the left menu under the name and city | 7.1 |

## 2. The badges

| # | `badgeId` | Name | Gurmukhi | Devanagari (draft) | What it marks |
| --- | --- | --- | --- | --- | --- |
| 1 | `JIGYASU` | Jigyasu | ਜਿਗਿਆਸੂ | जिज्ञासु | The seeker: the first hazri |
| 2 | `SHARDHALU` | Shardhalu | ਸ਼ਰਧਾਲੂ | श्रद्धालु | Coming back with shardha |
| 3 | `ABHYASI` | Abhyasi | ਅਭਿਆਸੀ | अभ्यासी | One who practises: the habit is forming |
| 4 | `NITNEMI` | Nitnemi | ਨਿਤਨੇਮੀ | नितनेमी | Keeps the Nitnem |
| 5 | `SIMRANI` | Simrani | ਸਿਮਰਨੀ | सिमरनी | Settled in Simran |
| 6 | `PAATHI` | Paathi | ਪਾਠੀ | पाठी | Has read every bani through, Sukhmani Sahib included |
| 7 | `SEVADAR` | Sevadar | ਸੇਵਾਦਾਰ | सेवादार | Sewa in the sangat: group goals carried to their end |
| 8 | `GURSIKH` | Gursikh | ਗੁਰਸਿੱਖ | गुरसिख | The whole of it held together over months |
| 9 | `SATSANGI` | Satsangi | ਸਤਿਸੰਗੀ | सतसंगी | Brought others into the sangat |
| 10 | `VICHARI` | Vichari | ਵੀਚਾਰੀ | वीचारी | The long road: a year of days |

Names a person receives from the community, not from an app, are excluded on
purpose: Khalsa, Sant, Brahmgyani, Granthi, Bhai Sahib, and now Gyani and
Pracharak (PRD §3.2, D11). The Gurmukhi and Devanagari spellings want a native
ear before release (D11).

## 3. When each badge is earned

### 3.1 Definitions

| Term | Meaning |
| --- | --- |
| Hazri day | A `localDate` with at least one `completions` row, or one `simranSessions` row with `durationS` ≥ 300, `deletedAt` null in both. This is `hazri(day)` of `04-goals.md` HZ1, and nothing else. |
| Hazri count | The number of distinct hazri days. Calculated from `user.db`, never stored (BR7). |
| Nitnem day | A `localDate` on which every bani with `default_slot` = `morning` in `content.db` has at least one completion: today Japji Sahib, Jaap Sahib, Tav Prasad Savaiye, Chaupai Sahib and Anand Sahib. Rehras Sahib (`evening`) and Kirtan Sohila (`bedtime`) do not take part; they make a hazri day like any bani. **(BD-1)** |
| Simran day | A `localDate` with a `simranSessions` row of `durationS` ≥ 300 |
| Banis completed | The distinct `baniId`s that have ever had a completion |
| Goals reached | Sangat goals, custom or built-in, that reached `COMPLETED` while the person had a contribution of at least 1 to them (5) |
| Joins to my groups | The number of people who joined a custom group the person created, each person counted once per group, the creator never (5) |

### 3.2 Rules

| `badgeId` | Earned when | Counted from |
| --- | --- | --- |
| `JIGYASU` | Hazri count ≥ 1 | Phone |
| `SHARDHALU` | Hazri count ≥ 7 | Phone |
| `ABHYASI` | Hazri count ≥ 40 | Phone |
| `NITNEMI` | Nitnem days ≥ 40 | Phone |
| `SIMRANI` | Simran days ≥ 108 | Phone |
| `PAATHI` | Banis completed includes every bani in `content.db` (nine today, Ardas and Sukhmani Sahib among them) | Phone |
| `SEVADAR` | Goals reached ≥ 3 | Server fact (5), profile needed |
| `GURSIKH` | `NITNEMI`, `SIMRANI` and `PAATHI` all earned, and hazri count ≥ 180 | Phone |
| `SATSANGI` | Joins to my groups ≥ 5 | Server fact (5), profile needed |
| `VICHARI` | Hazri count ≥ 365 | Phone |

- **HC1. Days, not minutes.** A day counts the same however long its paath took, so an elder reading slowly, a five-minute sitting and a full Sukhmani Sahib are equal. Playback speed, audio left running and paath marked with Diary + change nothing.
- **HC2. Every source counts.** Reader, audio, Diary + and restored rows are completions like any other (`04-goals.md` CR3, CR5). A paath read from a gutka and marked in the Diary counts.
- **HC3. Totals, never runs.** Every count is a total over all time. Days need not be in a row, a missed day resets nothing, and no grace period exists or is needed. The Diary streak is separate (`09-diary.md`) and no badge ever reads it.
- **HC4. Ardas and Sukhmani Sahib** make a hazri day like any completion (`04-goals.md` HZ1). They do not make a Nitnem day, because they are not morning banis; both count toward `PAATHI`. Nor do Rehras Sahib and Kirtan Sohila (BD-1).
- **HC5. New banis.** If `content.db` gains a bani, `PAATHI` then needs it too for anybody who has not yet earned the badge. Nobody loses it (4.3).
- **HC6. Order.** A badge needs nothing but its own rule; only `GURSIKH` names other badges. Somebody who never joins the sangat can earn eight of the ten.

## 4. Earned badges on the phone

### 4.1 Table `badges` (`user.db`, schema version 6)

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `badgeId` | TEXT (PK) | no | One of Section 2 |
| `earnedOn` | TEXT | no | `YYYY-MM-DD`, the local date the app first found the rule met |
| `announcedAt` | DATETIME | yes | UTC; when its sheet was shown (7.2), or when it was marked as never to be shown (7.3, 6) |
| `createdAt` | DATETIME | no | UTC |
| `updatedAt` | DATETIME | no | UTC, every write |

Migration 5 → 6 creates the table empty. Nothing else changes.

### 4.2 Evaluation

- **EV1. One function.** `evaluateBadges()` reads the counts of 3.1 from `user.db` and the cached Sangat facts (5.3), and inserts a row for every badge whose rule is met and which has no row yet, with `earnedOn` = today. It never updates or deletes a row.
- **EV2. When it runs:** after `completeBani` and every sitting saved (`06-nitnem.md` B1, `04-goals.md` HZ4), after every Diary + or −, at app start, after the Sangat facts arrive (5.3), and at the end of a restore (6.3).
- **EV3. Cost.** The counts are `COUNT(DISTINCT localDate)` queries on indexed columns of `user.db`; ten years of history is under 4,000 days. Evaluation runs off the UI thread and never delays a screen.
- **EV4. Backdated days.** A Diary + for a past day (`09-diary.md` D6) can complete a count; the badge's `earnedOn` is the day it was found, not the backdated day.

### 4.3 Never taken away

- **NT1.** A row in `badges` is never deleted. A Diary − that takes a count back below a threshold leaves the badge where it is.
- **NT2.** A restore never removes a badge the phone has (6.3).

## 5. The two Sangat facts

Sevadar and Satsangi depend on what happened in groups, which only the server
knows. Both need a profile: the facts are kept by profile and come back with
it.

### 5.1 Server: `badgeFacts/{memberKey}`

| Field | Type | Rule |
| --- | --- | --- |
| `goalsReached` | array of string | `"{groupId}/{goalId}"` of each goal reached (3.1). Stops growing at 3, which is all a badge needs. |
| `joins` | array of string | `"{groupId}/{memberKey}"` of each first join to a custom group this member created. Stops growing at 5. |
| `updatedAt` | timestamp | Server timestamp |

Arrays of keys, not counters, so a retried write adds nothing twice.

- **SF1. Goals reached.** A Firestore-triggered Function, `badgeGoalReached`, runs when a goal's `status` becomes `COMPLETED` (`08-sangat.md` §6.2). It reads the goal's members with `contribution` ≥ 1 (for a built-in group, the per-goal member documents written when the goal ends, §6.3 there), and adds the goal key to each one's `goalsReached` with `arrayUnion`, skipping any already holding 3. It writes only `badgeFacts`, never the goal it was triggered by, and is idempotent (`00-platform.md` Functions contract).
- **SF2. Joins.** `POST /api/v1/sangat/join` (`08-sangat.md` 7.8) gains one step in its transaction: when a member document is created for the first time in a custom group, the creator's `badgeFacts.joins` gets `"{groupId}/{memberKey}"` by `arrayUnion`, unless it already holds 5. A member who leaves and joins again is the same key and adds nothing.
- **SF3. Adoption.** When a profile is created, `badgeFacts/u_{uid}` is merged into `badgeFacts/p_{profileId}` in the same transaction as the other `u_` documents (`08-sangat.md` MB2, `01-accounts.md` §13 D12).

### 5.2 API: `GET /api/v1/badges/sangat`

Profile needed. Reads `badgeFacts/{callerMemberKey}`: one read.

| Status | Body |
| --- | --- |
| 200 | `{ "goalsReached": 2, "joins": 5 }` (array lengths; 0 when the document does not exist) |
| 404 | `NO_PROFILE` |

### 5.3 On the phone

- **SF4.** The app calls 5.2 when the Sangat tab opens and once a day at app start, only in `ProfileLoaded` and only while `SEVADAR` or `SATSANGI` is not yet earned. Once both are earned it never calls again.
- **SF5.** The response is cached in shared_preferences (`badge_sangat_facts_v1`) and fed to `evaluateBadges()`. A failed call changes nothing and is not shown.

## 6. Backup and restore

`10-backup.md` gains the `badges` table (owner, 2026-10-08).

### 6.1 What is sent

- **BB1.** The weekly backup (`10-backup.md` BK1–BK9) sends `badges` rows changed since the watermark, in the same `POST /api/v1/backup` request as `badges: [ { badgeId, earnedOn, announcedAt, createdAt, updatedAt } ]`.
- **BB2.** The hazri count is not sent: it comes back from the restored completions and sittings (BR7).

### 6.2 Server

`profiles/{profileId}/backupBadges/all`: one document, `{ badges: { [badgeId]: row }, serverUpdatedAt }`. Ten rows at most. The server merge for a badge keeps the earlier `earnedOn`, and `announcedAt` when either side has one.

`GET /api/v1/backup/badges` returns `{ "badges": [ ... ] }`, one read.

### 6.3 Restore

- **BB3. Order.** After goals and weeks (`10-backup.md` RS1–RS8), the restore fetches badges and merges each row: missing locally, inserted; present, `earnedOn` becomes the earlier of the two. A restored row with no `announcedAt` gets one set to now, so **a restore never announces a badge**.
- **BB4. Then evaluate.** `evaluateBadges()` runs once the restore finishes. A badge it finds then is inserted with `announcedAt` set, silently: it was almost certainly earned before and lost in the gap since the last backup.
- **BB5. The gap.** Anything after the last Sunday backup is not in the server copy. A badge earned in that week and lost with the phone comes back as soon as its count is reached again; nothing else can be done without sending data more often, and the owner chose not to (BD-4).
- **BB6. No profile, no backup.** Without a profile there is no backup (`10-backup.md` BK4); badges live on the phone only, like the Diary.

## 7. In the app

### 7.1 Where badges are seen

Chosen by the owner on 2026-10-08 from four options a screen (BD-12). The
designs are `design/html/95-*` to `99-*`; this section wins where they differ.

- **UI1. Three ways in, none on Today.** The profile's Badges section (UI5), the menu header (UI6) and the menu row `badgesTitle` all open the Badges page (UI2). The earned sheet's `badgeEarnedSee` opens it too (AN1). Today does not show badges, and the Diary has no badges row.
- **UI2. The Badges page** (design 96, option 2A). A pushed screen titled `badgesTitle`, under it `badgesSummary` ("{earned} of 10 earned · Hazri on {count} days"), then the ten badges in the order of Section 2, **two per row**. Each card holds the emblem, the name in the reader's script large, the transliterated name, the rule `badgeRule{Id}`, and either `badgeEarnedOn` with the date or `badgeNotYet` ("Not yet").
  - **Earned** badges are in colour: the kesri emblem, the card in `card`, the name in `ink`.
  - **Not earned** badges are greyed: the emblem in outline on `card2`, the name and rule in `muted`. They still show the name and how to earn it, so the page is the one place every badge is explained.
- **UI3. No progress meters.** No bar, percentage or "12 days to go" on any badge, on any screen. What a badge marks and how it is earned are said; how far away it is, is not (owner, 2026-10-08).
- **UI4. One badge** (design 97, option 3B). Tapping a card on UI2 or UI5 pushes a full page, not a sheet: `badgeNumber` ("Badge {n} of 10"), the emblem at 128 dp, the name in the reader's script and transliterated, then the chip `badgeEarnedOn` or `badgeNotYet`, then two cards: `badgeWhatItMarks` with `badgeMarks{Id}`, and `badgeHowEarned` with `badgeHow{Id}`. At the foot, the previous and next badge by name, in the order of Section 2. For `NITNEMI`, `badgeHow{Id}` takes the five bani names from `content.db` (rule 3), never from the ARB file.
- **UI5. In the profile** (design 98, option 4B). The profile screen (`01-accounts.md`) carries a Badges section under the profile card, before email, phone and backup: the heading `badgesTitle`, the link `badgesSeeAll` ("See all 10"), and all ten emblems five to a row with their names, earned in colour and the rest greyed. A tap on an emblem opens UI4; See all opens UI2. Design 98 replaces design 33.
- **UI6. In the menu** (design 99, option 5C). The menu's header is navy (`#262C63`, `card2` in dark) and holds the avatar, the name and the city as today, then `badgesMenuCount` ("Badges" … "{earned} of 10") and the ten emblems in one row, earned in kesri, the rest outlined. The whole block opens UI2. Below it, `badgesTitle` is a menu row after Your profile. Design 99 replaces design 37. With no profile the header has no name or city (`01-accounts.md`) and still shows the row of ten.
- **UI7. Never on a Gurbani screen.** No badge, sheet or count appears on the reader, the player or the Simran sitting (PRD §0, §8 "no badges on this screen, ever").

### 7.2 When a badge is earned

- **AN1. One quiet sheet, once** (design 95, option 1C). A badge whose `announcedAt` is null is shown in a bottom sheet the next time the app is on a screen that is not a Gurbani screen (UI7). The sheet is compact: the emblem, the eyebrow `badgeEarnedNew` ("New badge"), the name transliterated and in the reader's script, `badgeMarks{Id}` with the rule, then `badgeEarnedYours` ("Your badges") with `{earned} of 10` and the row of ten emblems, the new one ringed, and two buttons: `badgeEarnedDone` ("Done") and `badgeEarnedSee` ("See all badges"), which opens UI2. `announcedAt` is set when the sheet is shown. It is in the app, never a system notification (AN3, BD-11).
- **AN2. One at a time.** If several are waiting, one sheet shows the highest in the order of Section 2 and marks the rest announced.
- **AN3. No system notification.** A badge is always earned while the app is open, so the sheet is the announcement. `02-notifications.md` stays a closed list; PRD §3.7's `badge` row is this sheet.
- **AN4. No sound, no confetti, no vibration.**

### 7.3 When badges ship

- **LS1. History counts.** The first `evaluateBadges()` after the update awards every badge the existing Diary already meets.
- **LS2. Quietly.** Of those, only the highest is announced (AN2); every other is inserted with `announcedAt` set.

### 7.4 Strings

| Key | English |
| --- | --- |
| `badgesTitle` | Badges |
| `badgesSummary` | {earned} of 10 earned · Hazri on {count} days |
| `badgesSeeAll` | See all 10 |
| `badgesMenuCount` | {earned} of 10 |
| `badgeEarnedOn` | Earned {date} |
| `badgeNotYet` | Not yet |
| `badgeNumber` | Badge {n} of 10 |
| `badgeWhatItMarks` | What it marks |
| `badgeHowEarned` | How it is earned |
| `badgeEarnedNew` | New badge |
| `badgeEarnedYours` | Your badges |
| `badgeEarnedDone` | Done |
| `badgeEarnedSee` | See all badges |
| `badgeMarks{Id}` | What it marks, Section 2, one key per badge |
| `badgeHow{Id}` | The rule in full for UI4, one key per badge, ending "The days need not be in a row." where it counts days. NITNEMI: "{banis}, all five on the same day, on 40 days. The days need not be in a row.", `{banis}` filled from `content.db` |
| `badgeRule{Id}` | JIGYASU: Your first hazri. SHARDHALU: Hazri on 7 days. ABHYASI: Hazri on 40 days. NITNEMI: The five morning banis on 40 days. SIMRANI: Simran of 5 minutes or more on 108 days. PAATHI: Every bani read through once. SEVADAR: 3 sangat goals reached with you. GURSIKH: Nitnemi, Simrani, Paathi and hazri on 180 days. SATSANGI: 5 people joined groups you created. VICHARI: Hazri on 365 days. |

The badge names themselves are the Gurmukhi, Devanagari and Latin of Section 2, chosen by the reader's language and script.

## 8. Scenarios

| # | Given | When | Then |
| --- | --- | --- | --- |
| B-1 | Fresh install | First Japji Sahib read | `JIGYASU` earned; its sheet shows when the reader is closed |
| B-2 | Hazri on 39 days, then a week away | Hazri again | `ABHYASI` earned; the week away cost nothing |
| B-3 | Hazri on 40 days | A Diary − takes it to 39 | `ABHYASI` stays |
| B-4 | 39 Nitnem days; today Japji, Jaap, Tav Prasad Savaiye and Chaupai done | Anand Sahib read | Today is the 40th Nitnem day; `NITNEMI` is earned |
| B-4a | Today all seven Nitnem banis but Chaupai Sahib done | — | Not a Nitnem day: Rehras Sahib and Kirtan Sohila do not stand in for a morning bani |
| B-4b | Today the five morning banis done, Rehras Sahib and Kirtan Sohila not | — | A Nitnem day |
| B-5 | Only Sukhmani Sahib read on a day | — | A hazri day; not a Nitnem day |
| B-6 | Simran of 4 minutes on 200 days | — | No simran days; no `SIMRANI` |
| B-7 | Everything but Ardas completed | Ardas read | `PAATHI` earned |
| B-8 | No profile, 400 hazri days | — | Eight badges at most; `SEVADAR` and `SATSANGI` not shown as reachable without a profile |
| B-9 | Member of 3 groups whose goals completed, contribution ≥ 1 in each | Sangat tab opens | `goalsReached` 3; `SEVADAR` earned |
| B-10 | Created a group; 5 people joined; one left | Sangat tab opens | `joins` 5; `SATSANGI` earned and kept |
| B-11 | One person joins, leaves, joins the same group again | — | Counted once |
| B-12 | Existing user with 120 hazri days updates the app | First open | `JIGYASU`, `SHARDHALU`, `ABHYASI` earned; only `ABHYASI` is announced |
| B-13 | Badge earned on Tuesday, phone lost on Thursday, last backup Sunday | Restore on a new phone | Badges up to Sunday restored silently; Tuesday's comes back when its count is reached again |
| B-14 | Restore of a profile with 5 badges | Restore finishes | Five badges, original dates, no sheet |
| B-15 | Three badges earned by one action | — | One sheet, for the highest |
| B-16 | Reading in the reader | A badge is earned | Nothing shows until the reader is left |
| B-16a | `ABHYASI` waiting to be announced | Today is shown | The sheet of design 95; See all badges opens the Badges page |
| B-16b | Four badges earned | The Badges page is opened | Four cards in colour with their dates; six greyed with their names, rules and "Not yet" |
| B-16c | A greyed badge on the Badges page | Tapped | Its full page, with how it is earned and "Not yet"; no meter |
| B-16d | Four badges earned | The menu is opened | The ten emblems under the name and city, four in kesri; a tap opens the Badges page |
| B-17 | `content.db` adds a tenth bani | Somebody without `PAATHI` | Needs the new bani too; anybody who has it keeps it |
| B-18 | 365 hazri days, never opened meanings | — | `VICHARI` earned |

## 9. Acceptance checklist

- [ ] Unit: every rule of 3.2 at its threshold and one below, from rows in an in-memory `user.db`.
- [ ] Unit: totals, not runs: days far apart reach every threshold (HC3).
- [ ] Unit: `evaluateBadges()` never deletes or updates a row (NT1); a Diary − below a threshold keeps the badge.
- [ ] Unit: AN2 announces only the highest; LS2 on first run.
- [ ] Unit: restore merge keeps the earlier `earnedOn` and never announces (BB3, BB4).
- [ ] Backend (emulator): `badgeGoalReached` idempotent, never writes its trigger, stops at 3; join adds to `joins` once per person per group, stops at 5; `u_` facts adopted on profile creation.
- [ ] Widget: no progress meter on the page, the badge page, the profile or the menu (UI3); nothing about badges on the reader, player or sitting (UI7).
- [ ] Widget: earned cards in colour, the rest greyed with name and rule (UI2); the menu header and the profile section both open the page (UI5, UI6).
- [ ] Unit: a Nitnem day needs exactly the `default_slot` = `morning` banis (B-4, B-4a, B-4b).
- [ ] `l10n_test` covers every key of 7.4 in `pa`, `hi`, `en`.

## 10. Dependencies

`04-goals.md` (hazri, completions, sittings), `06-nitnem.md` B1 (where completions are made), `09-diary.md` (+ and −, the streak that stays separate), `08-sangat.md` (goals, joins, MB2), `10-backup.md` (BB1–BB6), `01-accounts.md` (profile, adoption).

## 11. Out of scope

- Points, totals, levels, leaderboards, comparisons.
- Sharing a badge outside the app.
- A system notification for a badge.
- Badges for minutes, for meanings read, or for any one bani read more than another.

## 12. Decisions

| # | Question | Decision |
| --- | --- | --- |
| BD-1 | What counts as a Nitnem day for `NITNEMI` | **Decided 2026-10-08:** the five morning banis only, those with `default_slot` = `morning` in `content.db` |
| BD-2 | Points, or minutes of bani recited | **Decided 2026-10-08:** neither. Days and milestones from existing data. Resolves PRD D14: §0 stands, and §3.2 is "Badges" |
| BD-3 | Names | **Decided 2026-10-08:** Vichari replaces Gyani; Satsangi replaces Pracharak. Resolves the name question of D11; spellings still want a native ear |
| BD-4 | Thresholds | **Decided 2026-10-08:** 1, 7, 40, 40, 108, all banis, 3, 180, 5, 365 |
| BD-5 | Missed days | **Decided 2026-10-08:** totals, never runs; nothing resets; no grace needed |
| BD-6 | Hazri count stored or recalculated | **Decided 2026-10-08:** recalculated from `user.db`; only earned badges are stored |
| BD-7 | Backup | **Decided 2026-10-08:** in the weekly backup, restored silently, with the week's gap accepted |
| BD-8 | Satsangi's measure | **Decided 2026-10-08:** people who joined groups you created |
| BD-9 | Existing users | **Decided 2026-10-08:** past days count; only the highest badge earned is announced |
| BD-10 | Vichari and meanings | **Decided 2026-10-08:** no condition on meanings; hazri on 365 days |
| BD-11 | How a badge is announced | **Decided 2026-10-08:** in the app, in a bottom sheet with the badge, its name and details and a button to all badges; never a system notification (AN1–AN4) |
| BD-12 | The designs | **Decided 2026-10-08** from four options a screen: the earned sheet 1C (design 95), the Badges page 2A (96), one badge 3B (97), the profile 4B (98), the menu 5C (99). 98 replaces 33 and 99 replaces 37 |
