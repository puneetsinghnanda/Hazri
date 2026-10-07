# 8. Sangat

Rewritten 2026-10-07 with Puneet Singh Nanda. It replaces the earlier version
of this file entirely, and with it the old sangat code (`01-accounts.md`
§13.3 W2). One decision is still open (13, SG-1); every other one was taken
by the owner on 2026-10-07.

## 0. Implementation directive (mandatory, read first)

1. **No inference.** Every behaviour, field, endpoint, limit and string comes from this document.
2. **The server is the source of truth** for groups, members, goals and totals. The phone keeps only a read-only copy of what the server last sent, for display (5.2), and a list of its own paath still to send (5.1).
3. **Server access follows the Profile PRD**: everything goes through the `api` Cloud Function under `/api/v1` with the Firebase ID token (`01-accounts.md` §6.0); Firestore rules deny all client access.
4. **No ranking.** Members are listed with their contributions but never ordered by them (4.6).
5. **No Gurbani** in group names set by the app, messages or notifications; bani names come from `content.db`.
6. **Strings are localised** in `pa`, `hi` and `en`. English source text is given here; the implementer writes `pa` and `hi` and the owner verifies them (`01-accounts.md` §13.9).
7. **Stop on ambiguity.** If anything required is missing or contradictory, stop and ask the developer.
8. **Done means tested.** Section 12 passes, `flutter analyze` is clean and `flutter test` passes.

## 1. Overview and requirement traceability

A Sangat group is a set of people working together toward one shared goal with an end date: so many paath of one bani, or so many sittings of Naam Simran. There are two kinds. **Built-in groups** are set up by the owner in the admin website (`11-admin.md`) and anybody can join or leave them. **Custom groups** are created by people with a profile for their family, Gurdwara or circle; they are private and joined only through an invite.

| Req # | Requirement (owner, 2026-10-07) | Where |
| --- | --- | --- |
| K1 | Four built-in groups: Amrit Vela Sangat, Simran Sangat, Daily Nitnem Sangat, Sukhmani Sahib Sangat | 4.1 |
| K2 | People join and leave built-in groups themselves | 4.1, 7 |
| K3 | Built-in groups are configured in an admin website, not in the app | 4.1, `11-admin.md` |
| K4 | Creating a custom group needs a profile; joining one does not | 4.2, 4.3 |
| K5 | Custom groups are private, joined by invite link or code, with no approval | 4.3, 4.4 |
| K6 | Each group has one goal for its whole life: one bani, or Naam Simran with a sitting length, a target and an end date of at most 365 days | 4.2, 4.5 |
| K7 | A group becomes inactive when its target is met or its end date passes, and keeps its history | 4.2 |
| K8 | A creator may have 5 active custom groups; support can raise it | 4.2, `11-admin.md` |
| K9 | Invites are shared through any app with a link and a code; the code lasts 30 days; installing from the link joins automatically | 4.4 |
| K10 | Every member's contribution is visible; the first 50 members are listed, then "N more members" | 4.6 |
| K11 | Members can report a group with a reason; support is emailed; the admin can disable or delete it | 4.7 |
| K12 | Diary "+" counts at most 3 a day toward a group | 4.5 |
| K13 | Paath done offline is sent when the phone is back online | 5.1 |
| K14 | Server schema and API | 6, 7 |

## 2. Definitions

| Term | Meaning |
| --- | --- |
| Built-in group | A permanent group created in the admin website. Anybody can join or leave it. Its goal resets (4.1). |
| Custom group | A group created in the app by a person with a profile. Private: it never appears in any list except its members' own. |
| Creator | The person who created a custom group. Built-in groups have no creator. |
| Member | Somebody who has joined a group. With a profile they are identified by their profile; without one, by their install's anonymous uid (4.3). |
| Goal | The group's one target: `BANI` (N paath of one bani) or `SIMRAN` (N sittings of at least M minutes). |
| Contribution | One completed paath of the goal's bani, or one Naam Simran sitting of at least the goal's minutes, by a member, counted toward the goal (4.5) |
| Group day | The calendar day in India Standard Time, the same for every group and member (owner, 2026-10-07). `dayIst` = `YYYY-MM-DD`. |
| Active / inactive | A group whose goal is running, or one that has ended. An inactive group can still be opened and read. |
| Disabled | A group the admin switched off after a report. It cannot be opened or joined. |

## 3. Constants

| Constant | Value |
| --- | --- |
| `GROUP_NAME_MAX` | 64 characters (Unicode code points, after trimming) |
| `CUSTOM_GROUP_MAX_MEMBERS` | 1,000 (built-in groups: no limit) |
| `CUSTOM_GROUPS_ACTIVE_DEFAULT` | 5 active custom groups per creator; the admin can set a higher number per person |
| `GOAL_DAYS_MIN` / `GOAL_DAYS_MAX` | 1 / 365, start day included |
| `GOAL_TARGET_MIN` / `GOAL_TARGET_MAX` | 1 / 1,000,000 |
| `SIMRAN_MINUTES_DEFAULT` / range | 5 / 5–120 (as `04-goals.md` §3) |
| `INVITE_CODE_TTL_DAYS` | 30 |
| `INVITE_CODE_ALPHABET` | `ABCDEFGHJKMNPQRSTUVWXYZ23456789` (no 0, O, 1, I or L), 8 characters, shown as `XXXX-XXXX` |
| `MEMBER_LIST_SIZE` | 50 |
| `DIARY_DAILY_CAP` | 3 Diary-added contributions per member per group per group day |
| `REPORT_NOTE_MAX` | 200 characters |

## 4. Rules

### 4.1 Built-in groups

- **BI1.** The four built-in groups at launch are Amrit Vela Sangat, Simran Sangat, Daily Nitnem Sangat and Sukhmani Sahib Sangat. Their names are set in `en`, `pa` and `hi` in the admin website (Punjabi: ਅੰਮ੍ਰਿਤ ਵੇਲਾ ਸੰਗਤ, ਸਿਮਰਨ ਸੰਗਤ, ਰੋਜ਼ਾਨਾ ਨਿਤਨੇਮ ਸੰਗਤ, ਸੁਖਮਨੀ ਸਾਹਿਬ ਸੰਗਤ; Hindi: अमृत वेला संगत, सिमरन संगत, दैनिक नितनेम संगत, सुखमनी साहिब संगत; to be confirmed by the owner).
- **BI2.** Nobody is a member until they join. Every user sees the list of built-in groups with Join or Leave, with or without a profile.
- **BI3.** Each has one goal at a time, set in the admin website: a bani or Naam Simran with minutes, a target, and a length in days.
- **BI4. Reset.** When the target is met, or when the end day passes unmet, the next group day a new goal starts with the same bani or minutes, target and length. The finished goal stays as history, with its total and every member's contribution.
- **BI5.** No member limit. Leaving and joining again is allowed at any time.

### 4.2 Custom groups

- **CG1. Creating** needs a profile (`ProfileLoaded`). Without one, Create shows the profile banner of `07-simran.md` NP3 with `sangatCreateNeedsProfile`.
- **CG2. Name:** 1–64 characters after trimming, any script. It is shown to members only.
- **CG3. Goal straight after.** Creating a group leads at once to setting its goal: `BANI` with a bani from `content.db`, or `SIMRAN` with minutes (default 5); a target; and an end day from today (IST) to today + 364. The start day is the day the goal is set. A group with no goal yet can be shared but counts nothing.
- **CG4. One goal for life.** The goal's type, bani, minutes and target cannot change. Only the end day can be changed, by the creator, to any day from today to start + 364.
- **CG5. Limit.** A creator may have at most their limit of **active** custom groups (default 5). Inactive groups do not count. Over the limit, Create shows `sangatLimitReached` with the support address.
- **CG6. Inactive** when the target is met (at once, mid-day) or after the end day has passed. An inactive group is read-only: its goal, total, history and every member's contribution stay and can be opened. It cannot be joined, and nothing more counts toward it.
- **CG7. Ending early.** The creator sets the end day to today; the group becomes inactive after today.
- **CG8. Deleting** is allowed only while the creator is the only member. It removes the group and everything in it. Otherwise there is no delete.
- **CG9. The creator cannot leave.** The creator can remove any other member (MB4).
- **CG10.** Group type (family, Gurdwara, circle) is not stored: every custom group behaves the same.

### 4.3 Members

- **MB1. Joining without a profile** is allowed. The member is identified by their anonymous uid and shown as `sangatAnonymousName` ("Sangat member").
- **MB2. Creating a profile later** moves every membership and contribution of that uid to the profile, at once, in the profile-creation transaction (`01-accounts.md` §6.2). Clearing the app's data before creating a profile loses those memberships: there is nothing to restore them with.
- **MB3. With a profile**, memberships belong to the profile, not the phone, so a profile restore brings them back with nothing kept on the phone (`01-accounts.md` §6.5). The name shown is the profile's name and follows it when the profile is edited.
- **MB4. Removing.** The creator can remove a member. Leaving and removal keep the member's past contributions in the totals and history; the member's row shows as left.
- **MB5.** A removed member can join again with a valid invite.

### 4.4 Invites

- **IV1. Any member** of an active custom group can share its invite.
- **IV2. The code** belongs to the group and is valid for 30 days from when it was made. Sharing reuses the current code while it is valid; when it has expired, sharing makes a new one. The creator can also make a new one at any time ("Reset invite code"), which ends the old one at once.
- **IV3. Joining by link or code needs no approval** (owner, 2026-10-07).
- **IV4. The share** uses Android's share sheet, so the person chooses the app. Text: `sangatInviteMessage` (8.3) with the group name, the link `https://hazri-dfcc1.web.app/j/{code}` and the code.
- **IV5. The link page** (`public/j/index.html`):
    - With the app installed, the link is an App Link and opens the app on the Join screen with the code filled in (the same mechanism as `/verify`, `01-accounts.md` §7.3; the `/j` path is added to the intent filter).
    - Without the app, the page shows the code large with a Copy button, and a "Get Hazri" button to `https://play.google.com/store/apps/details?id={{ANDROID_PACKAGE_NAME}}&referrer=sangat_code%3D{code}`. The page carries Open Graph tags so the link previews in chat apps.
    - It never calls the API.
- **IV6. After installing,** the app reads the install referrer once on first launch with Google Play's Install Referrer library (approved by the owner, 2026-10-07). If it carries `sangat_code`, the app opens the Join screen with that code after onboarding. The referrer is read once and never sent anywhere.
- **IV7. Typing a code.** The Join screen accepts a code typed or pasted ("Paste code" button), with or without the hyphen, in any case. The app never reads the clipboard by itself.
- **IV8. Results:** joined; already a member (opens the group, no error); invalid or expired code (`sangatCodeInvalid`); group full (`sangatGroupFull`); group inactive (`sangatGroupEnded`); group disabled (`sangatCodeInvalid`).

### 4.5 Counting

- **CT1. What counts.** For a `BANI` goal, every completion of that bani (`04-goals.md` §5.4). For a `SIMRAN` goal, every sitting of at least the goal's minutes (`04-goals.md` §5.5), counting as one. **(SG-1)**
- **CT2. When.** A contribution counts when its group day falls between the goal's start and end day, on or after the day the member joined, while the member is a member and the group is active.
- **CT3. Every group.** One paath counts once in every group the member belongs to whose goal it matches (owner, 2026-10-07).
- **CT4. Diary cap.** Completions and sittings added with the Diary "+" (`source` = `DIARY`) count at most `DIARY_DAILY_CAP` per member per group per group day; the rest are accepted and ignored for the group. The Diary itself is not capped (owner, 2026-10-07).
- **CT5. Undo.** Diary "−" on a contribution takes it back from every group it counted in (owner, 2026-10-07).
- **CT6. Leaving** keeps what was contributed (owner, 2026-10-07).
- **CT7. After the end.** Once a goal has completed or expired, nothing more counts toward it, including late arrivals from the outbox.
- **CT8. Totals** are kept by the server only (6.4), never by a phone.
- **CT9. Group day.** A contribution's group day is the IST date of its `completedAt` (or `startedAt` for a sitting). "Today" in a group always means the IST day.

### 4.6 What members see

- **VS1. My groups:** active groups first, then inactive ones under `sangatEndedHeading`. Each shows name, goal, total of target, percentage and days left.
- **VS2. Built-in groups:** the four, with member count and Join or Leave.
- **VS3. A group:** name; goal (bani or Naam Simran with minutes, target, start and end); total, percentage, today's total, days left or "Ended on {date}"; member count; and the member list.
- **VS4. The member list** shows at most 50 members: those with a profile first, alphabetically by name, then "Sangat member" rows. Each row shows the name and that member's contribution to the goal. After 50, one line reads `sangatMoreMembers` ("450 more members"). No further loading.
- **VS5.** Nobody is shown a position, a rank, or who has not contributed.
- **VS6.** The creator's row carries `sangatCreatorLabel`.

### 4.7 Reports

- **RP1.** Any member can report a group from its menu with a reason: Offensive name, Spam, Not about Sikhi, or Other. Other allows an optional note of up to 200 characters.
- **RP2.** The server stores the report and emails `support@hazri.me` through the email service of `01-accounts.md` §13.3 W6 with the group's ID, name, reason, note and the reporter's member key. The reporter sees `sangatReportSent`.
- **RP3.** One report per member per group; reporting again replaces the reason.
- **RP4.** The admin can disable or delete a group (`11-admin.md`). A disabled group disappears from every member's list and cannot be opened or joined.

## 5. On the phone

### 5.1 Paath waiting to be sent (`sangatOutbox`, in `user.db`)

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

### 5.2 Read-only copy of what the server sent

The app keeps the last response of 7.1, 7.2 and 7.3 for each group (shared preferences, key `sangat_cache_v1`, JSON). Opening a screen shows the copy at once with `sangatUpdatedAt`, asks the server, and replaces it with the reply. Offline, the copy stays with its time. The phone never edits it; it is cleared on `markNone()` (`01-accounts.md` §8.3) when the person had no memberships without a profile.

## 6. Server schema (Firestore, `asia-south1`)

Only the Cloud Functions read and write these. Conventions as `01-accounts.md` §4.

**Member key.** `p_{profileId}` for a member with a profile, `u_{uid}` for one without.

### 6.1 `groups/{groupId}`

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
| `goalTemplate` | map | yes | Built-in groups: `{ type, baniId, simranMinutes, target, lengthDays }` for resets |
| `createdAt` / `updatedAt` | timestamp | no | Server timestamps |

### 6.2 `groups/{groupId}/goals/{goalId}`

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `type` | string | no | `BANI` or `SIMRAN` |
| `baniId` | string | yes | `BANI` |
| `simranMinutes` | number | yes | `SIMRAN`, 5–120 |
| `target` | number | no | 1–1,000,000 |
| `startDay` / `endDay` | string | no | `dayIst`; at most 365 days inclusive |
| `status` | string | no | `ACTIVE`, `COMPLETED` (target met) or `EXPIRED` |
| `total` | number | no | Kept by the server (6.4) |
| `completedAt` | timestamp | yes | When the target was met |
| `sequence` | number | no | 1 for the first goal; built-in resets count up |
| `createdAt` | timestamp | no | Server timestamp |

### 6.3 `groups/{groupId}/members/{memberKey}`

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `memberKey` | string | no | Same as the document ID |
| `name` | string | yes | Profile name; null for `u_` members. Updated when the profile name changes. |
| `role` | string | no | `CREATOR` or `MEMBER` |
| `status` | string | no | `ACTIVE`, `LEFT` or `REMOVED` |
| `joinedDay` | string | no | `dayIst` of the latest join |
| `contribution` | number | no | Count toward the current goal, kept by the server |
| `sortName` | string | no | Lowercased name, or `~` for `u_` members so they sort last |
| `updatedAt` | timestamp | no | Server timestamp |

Contributions to earlier goals of a built-in group are kept in `groups/{groupId}/goals/{goalId}/members/{memberKey}` `{ contribution }`, written when the goal ends.

### 6.4 Totals

- `contributions/{memberKey}_{id}`: one document per received outbox row: `{ memberKey, kind, baniId, durationS, source, day, at, retracted, countedIn: [ "groupId/goalId", ... ] }`. It makes sending idempotent and lets a retraction find what to take back.
- A custom group's goal `total` and the member's `contribution` are incremented in the same transaction as the contribution document.
- A built-in goal could receive thousands of writes a minute, past Firestore's limit of about one write a second on one document. Its total is kept in 20 shards, `groups/{groupId}/goals/{goalId}/shards/{0..19}` `{ count }`, each contribution incrementing one chosen at random, and the scheduled Function `sangatTotals` adds them into `total` once a minute.
- Diary cap (CT4): `contributionCaps/{memberKey}_{groupId}_{dayIst}` `{ diaryCount }` is read and incremented in the same transaction.

### 6.5 Other collections

| Collection | Document | Fields |
| --- | --- | --- |
| `inviteCodes/{code}` | One per live code | `groupId`, `expiresAt` |
| `memberships/{memberKey}` | One per member key | `groupIds` (array of active memberships), `updatedAt`: answers "my groups" in one read |
| `groupLimits/{profileId}` | Only where the admin raised it | `limit`, `setBy`, `updatedAt` |
| `groupReports/{groupId}_{memberKey}` | One per reporter per group | `groupId`, `memberKey`, `reason`, `note`, `status` (`OPEN`, `ACTIONED`, `DISMISSED`), `createdAt` |

### 6.6 Indexes

- `members` (collection group): `status` ascending, `sortName` ascending, for the member list.
- `groups`: `kind` ascending, `status` ascending, for the built-in list and the admin website.
- `groupReports`: `status` ascending, `createdAt` descending.

## 7. API

All under `/api/v1/sangat`, following `01-accounts.md` §6.0. Every endpoint works with an anonymous ID token unless it says it needs a profile. Errors use the shared error body; codes are listed per endpoint.

| # | Method and path | Body | Does | Errors |
| --- | --- | --- | --- | --- |
| 7.1 | `GET /groups/mine` | — | Active and inactive groups of the caller's member key, with name, goal, total, percentage, days left | — |
| 7.2 | `GET /groups/built-in` | — | The built-in groups with names in all three languages, current goal, total, member count, and whether the caller is a member | — |
| 7.3 | `GET /groups/{groupId}` | — | Group, current goal, today's total, member count, the first 50 members (VS4), and the caller's role. Members only for custom groups. | `404 GROUP_NOT_FOUND` (also for a disabled group or a non-member) |
| 7.4 | `POST /groups` | `{ name }` | Creates a custom group with the caller as creator. Needs a profile. | `400 VALIDATION_ERROR`, `404 NO_PROFILE`, `409 GROUP_LIMIT_REACHED` |
| 7.5 | `POST /groups/{groupId}/goal` | `{ type, baniId?, simranMinutes?, target, endDay }` | Sets the goal once. Creator only. | `400 VALIDATION_ERROR`, `403 NOT_CREATOR`, `409 GOAL_ALREADY_SET` |
| 7.6 | `PATCH /groups/{groupId}/goal` | `{ endDay }` | Changes the end day (CG4, CG7). Creator only. | `400 VALIDATION_ERROR`, `403 NOT_CREATOR`, `409 GROUP_INACTIVE` |
| 7.7 | `DELETE /groups/{groupId}` | — | Deletes when the creator is the only member (CG8) | `403 NOT_CREATOR`, `409 GROUP_HAS_MEMBERS` |
| 7.8 | `POST /join` | `{ code }` | Joins by invite (IV8) | `404 CODE_INVALID`, `409 GROUP_FULL`, `409 GROUP_INACTIVE` |
| 7.9 | `POST /groups/{groupId}/join` and `POST /groups/{groupId}/leave` | — | Joins or leaves a built-in group; leave also works for custom-group members other than the creator | `404 GROUP_NOT_FOUND`, `409 CREATOR_CANNOT_LEAVE` |
| 7.10 | `DELETE /groups/{groupId}/members/{memberKey}` | — | Removes a member (MB4). Creator only. | `403 NOT_CREATOR`, `404 MEMBER_NOT_FOUND` |
| 7.11 | `POST /groups/{groupId}/invite` | `{ reset?: true }` | Returns `{ code, link, expiresAt }`, making a new code when expired or when the creator asks to reset | `403 NOT_CREATOR` (reset only), `409 GROUP_INACTIVE` |
| 7.12 | `POST /contributions` | `{ items: [ { id, kind, baniId?, durationS?, source, at, action } ] }`, at most 200 | For each item not seen before: finds the caller's active groups whose goal it matches (CT1–CT4, CT7), records it (6.4) and updates totals. A `RETRACT` takes back what its `ADD` counted. Returns the ids processed. | `400 VALIDATION_ERROR` |
| 7.13 | `POST /groups/{groupId}/report` | `{ reason, note? }` | Stores the report and emails support (RP1–RP3) | `400 VALIDATION_ERROR`, `404 GROUP_NOT_FOUND` |

Success bodies return the same shapes the app caches (5.2). Profile creation (`01-accounts.md` §6.2) gains one step: within its transaction, every `u_{callerUid}` membership, contribution and cap document is rewritten under `p_{profileId}` (MB2).

### 7.14 Scheduled and triggered Functions

All follow `00-platform.md` §0.1 (`maxInstances: 10`, idempotent, never writing their own trigger).

| Function | Trigger | Does |
| --- | --- | --- |
| `sangatTotals` | Every minute | Adds each active built-in goal's shards into `total`; marks a goal `COMPLETED` when `total` reaches `target` |
| `sangatRollover` | 00:05 IST daily | Expires goals past `endDay`; makes custom groups `INACTIVE` (CG6); starts the next goal of each built-in group whose goal completed or expired (BI4) |
| `sangatProfileSync` | Profile name change | Updates `name` and `sortName` on that member's rows |
| `sangatMilestone`, `sangatDispatch` | As `02-notifications.md` §8.2 | Sangat notifications |

## 8. App behaviour

### 8.1 Sangat tab

1. **My groups** (VS1), with **Create group** and **Join with a code**.
2. **Built-in groups** (VS2).
3. With no network and no copy yet, `sangatOffline`.

### 8.2 Screens

| Screen | Contents |
| --- | --- |
| Create group | Name field (64), then Set goal: Bani or Naam Simran; bani picker from `content.db` or minutes (5–120, default 5); target; end date (up to 365 days). Then Share invite. |
| Join | Code field (`XXXX-XXXX`), "Paste code", Join. Filled automatically from an App Link or the install referrer. |
| Group | VS3 and VS4. Menu: Share invite; for the creator also Change end date, Reset invite code, Remove member (on a member row), Delete (CG8); for others Leave; for all Report. |
| Report | The four reasons, the note for Other, Send. |

### 8.3 Strings

| Key | English |
| --- | --- |
| `sangatTitle` | Sangat |
| `sangatMyGroups` | My groups |
| `sangatBuiltInGroups` | Join the sangat |
| `sangatEndedHeading` | Ended |
| `sangatCreate` | Create group |
| `sangatJoinWithCode` | Join with a code |
| `sangatJoin` | Join |
| `sangatLeave` | Leave |
| `sangatCreateNeedsProfile` | Create your profile to start a group of your own. |
| `sangatLimitReached` | You have {limit} active groups. To start more, write to support@hazri.me. |
| `sangatGroupName` | Group name |
| `sangatGoalBani` | Paath of one bani |
| `sangatGoalSimran` | Naam Simran |
| `sangatGoalTarget` | Target |
| `sangatGoalEnds` | Ends on |
| `sangatGoalSummaryBani` | {target} {bani} by {date} |
| `sangatGoalSummarySimran` | {target} sittings of {minutes} min by {date} |
| `sangatProgress` | {total} of {target} · {pct}% |
| `sangatToday` | {count} today |
| `sangatDaysLeft` | {days} days left |
| `sangatEndedOn` | Ended on {date} |
| `sangatMembers` | {count} members |
| `sangatMoreMembers` | {count} more members |
| `sangatAnonymousName` | Sangat member |
| `sangatCreatorLabel` | Started this group |
| `sangatShareInvite` | Share invite |
| `sangatInviteMessage` | Join "{group}" on Hazri: {target} {goal} together by {date}. Tap {link} or enter code {code} in the app. |
| `sangatResetCode` | Reset invite code |
| `sangatPasteCode` | Paste code |
| `sangatCodeInvalid` | This code isn't valid. Ask for a new invite. |
| `sangatGroupFull` | This group is full. |
| `sangatGroupEnded` | This group has ended. |
| `sangatChangeEndDate` | Change end date |
| `sangatRemoveMember` | Remove from group |
| `sangatDeleteGroup` | Delete group |
| `sangatReport` | Report group |
| `sangatReportReasonOffensive` | Offensive name |
| `sangatReportReasonSpam` | Spam |
| `sangatReportReasonOffTopic` | Not about Sikhi |
| `sangatReportReasonOther` | Other |
| `sangatReportSent` | Thank you. We'll look into it. |
| `sangatUpdatedAt` | Updated {time} |
| `sangatOffline` | Can't reach the sangat right now |

## 9. Notifications

As `02-notifications.md` §4.5 and §8, plus the two added on 2026-10-07: "{name} joined {group}", once a day to the creator, and "{group} has ended", to every member (`02-notifications.md` 5.5-E and 5.5-F). Members without a profile get no push: push needs a profile (`02-notifications.md` FT1).

## 10. Scenarios

| # | Given | When | Then |
| --- | --- | --- | --- |
| S-1 | No profile | Opens Sangat | Built-in groups with Join; Create shows the profile banner |
| S-2 | No profile | Joins Simran Sangat | Member as "Sangat member"; sittings of at least its minutes count |
| S-3 | S-2 | Creates a profile | Memberships and contributions move to the profile; the row shows the name |
| S-4 | Profile | Creates "Gill Parivar", goal 5,000 Japji Sahib by 31 Dec | Group active; Share invite offered |
| S-5 | Five active custom groups | Creates a sixth | `GROUP_LIMIT_REACHED` |
| S-6 | Five active, one ended | Creates another | Allowed |
| S-7 | A member shares the invite to WhatsApp | Recipient with Hazri taps the link | App opens on Join with the code; one tap joins |
| S-8 | Recipient without Hazri | Taps link, installs from Play | First launch offers to join with the code (install referrer) |
| S-9 | Code older than 30 days | Joining | `sangatCodeInvalid`; the next share makes a new code |
| S-10 | Creator resets the code | Old link used | `sangatCodeInvalid` |
| S-11 | Member in two groups with Japji goals | Reads Japji | Counts 1 in each |
| S-12 | Member adds 5 Japji with Diary "+" today | — | Diary shows 5; each group counts 3 |
| S-13 | Japji read offline | Signal returns | Outbox sent; totals rise once |
| S-14 | S-13 sent twice after a lost reply | — | Counted once |
| S-15 | Diary "−" on a counted Japji | — | Taken back from each group |
| S-16 | Simran group of 11 min | A 7-minute sitting | Not counted; Hazri still marked |
| S-17 | Target reached at 14:00 | — | Goal completed; custom group inactive at once; later paath not counted |
| S-18 | Built-in goal met on the 10th | 00:05 IST on the 11th | New goal with the same settings; the old one in history |
| S-19 | Built-in goal ends unmet | Next day | Same reset |
| S-20 | Creator sets end date to today | After today | Inactive, history kept |
| S-21 | Creator alone in the group | Delete | Deleted |
| S-22 | Group with members | Creator tries to leave or delete | Not offered; server refuses |
| S-23 | Creator removes a member | — | Row shows as left; contribution stays in the total |
| S-24 | Group of 500 | Opened | 50 rows, names alphabetical then "Sangat member", then "450 more members" |
| S-25 | Group at 1,000 members | Somebody joins | `sangatGroupFull` |
| S-26 | A member reports "Spam" | — | Report stored; support emailed; "Thank you" |
| S-27 | Admin disables the group | Members refresh | Gone from their lists; link invalid |
| S-28 | Offline | Opens a group | Last copy with its time |
| S-29 | Profile restored on a new phone | Opens Sangat | All memberships there, from the server |
| S-30 | 50,000 members read Japji within a minute in a built-in group | — | Shards absorb it; total correct within a minute |

## 11. Privacy and cost

- Each counted paath sends its bani or sitting length, its time and its source to the server. The privacy screen will be redesigned to say so (owner, 2026-10-07: later).
- Reads: opening a group costs the group, its goal and up to 50 member rows (about 52 reads); the copy on the phone (5.2) is shown first and the app does not poll.
- Writes: each paath writes one contribution document and one total per custom group it counts in; built-in groups write a shard instead.

## 12. Acceptance checklist

- [ ] Backend (emulator): every endpoint and error of Section 7; idempotent contributions; Diary cap; retraction; join by expired, reset and valid codes; group full; creator rules; profile creation adopting `u_` memberships; `sangatTotals` and `sangatRollover` across a day change and a reset.
- [ ] Rules test: no client can read or write any collection in Section 6.
- [ ] App: outbox add, send, retry and delete; cache shown first and replaced; Join filled from an App Link and from a fake install referrer; every screen of 8.2.
- [ ] Every key of 8.3 in `pa`, `hi` and `en`.
- [ ] Device: link opens the app; Play install joins via the referrer; an offline paath counts after reconnecting.

## 13. Decisions

| # | Question | Decision |
| --- | --- | --- |
| SG-1 | Does a Simran goal count sittings of at least M minutes (1,000 sittings of 11 min), or total minutes (10,000 minutes)? | **Open.** Written as sittings, matching personal goals; total minutes would change CT1, the goal form and the summary string |
| SG-2 | Built-in group names in Punjabi and Hindi | Proposed in BI1; the owner to confirm |
| — | Every other rule | Decided by the owner on 2026-10-07 |

## 14. Out of scope

- Group chat, messages, photos, or any free text between members beyond the group name.
- Public or listed custom groups.
- Approval of joins.
- More than one bani per group, or changing a goal's target.
- Groups on the Simran globe.
