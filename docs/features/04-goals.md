# 4. Goals and Hazri

Written 2026-10-07 with Puneet Singh Nanda. It replaces the earlier version of
this file entirely. It is also kept as a Claude Doc
("Feature Document: Goals and Hazri"); the two must stay identical, so a
change to one is made to the other in the same commit.

This document is the single source of truth for Goals and Hazri. Where an
earlier version of this file, or any other file, says something different,
this one wins.

## 0. Implementation directive (mandatory, read first)

1. **No inference.** Every behaviour, field, rule, limit and screen state comes from this document. Do not add, rename, merge or "improve" anything. Where `02-notifications.md`, `05-today.md`, `07-simran.md` or `09-diary.md` say otherwise about goals or hazri, this document wins.
2. **No extra features.** Section 10 lists what is out of scope. Weekly goals, per-goal streaks, points, badges and group goals are not built.
3. **Stop on ambiguity.** If anything needed to proceed is missing or contradictory, stop and ask the developer. Do not pick a default.
4. **Everything works offline.** Goals, hazri and the Diary read and write only the phone's local database (`user.db`). No network request is made by anything in this document.
5. **One rule, one function.** Whether a day has hazri and whether a day's goal was met are each decided by exactly one function (Section 4.6). Home, the Goals screen, the Diary grid and the Diary day screen call it and never re-derive it.
6. **Repository conventions win over the Profile PRD's code conventions.** Strings are localised in `pa`, `hi` and `en` (English source strings are given here; keys live in the ARB files). Navigation is the app's existing `go_router`; local storage is the existing drift `user.db`. The Profile PRD's *data* conventions (field tables, ID and timestamp rules, enum style) are followed (Section 5).
7. **Never type Gurbani.** Bani names and text come from `content.db`. No bani name is hard-coded in Dart, including in reminder text.
8. **Done means tested.** The feature is complete only when every item in Section 9 passes, `flutter analyze` is clean and `flutter test` passes.

## 1. Overview and requirement traceability

Two features run side by side and are judged independently. **Hazri** is turning up: one completed bani, or one Naam Simran sitting of at least 5 minutes, marks the day present. A **goal** is finishing a chosen list of banis (and optionally Naam Simran) a set number of times each day. Every goal completion is also a completion, so a day can never have a met goal without hazri.

| Req # | Requirement (summary) | Where specified |
| --- | --- | --- |
| G1 | With no active goal, Home shows a card asking the user to set a daily goal | 4.1, 7.1 |
| G2 | Any bani, and Naam Simran, can be added to the goal | 4.2, 7.2 |
| G3 | Each bani has its own times-per-day target | 3, 4.2, 7.2 |
| G4 | Each bani has its own duration (every day, N days, or until a date) | 4.2, 7.2 |
| G5 | Each bani can have its own reminder | 4.8, 7.6 |
| G6 | With an active goal, Home shows how many goal items are achieved today | 7.1 |
| G7 | A met goal day is marked in the Diary; tapping a day shows what was recited and completed | 4.6, 4.7, 7.4, 7.5 |
| G8 | Removing items keeps the goal running while one remains; an empty goal is completed, history kept | 4.3 |
| H1 | Any completed bani marks hazri, whether or not it is in a goal and whether or not a goal exists | 4.4 |
| H2 | A completed Naam Simran sitting of at least 5 minutes marks hazri | 4.4 |
| H3 | The Diary shows two dots per day: orange for hazri, green for the goal | 4.7, 7.4 |
| H4 | The second dot appears only on days that had a goal item in scope | 4.7 |
| H5 | Green without orange is impossible | 4.7 |
| H6 | A goal of one bani, completed, marks hazri and meets the goal | 4.7, 8 |

## 2. Definitions

| Term | Meaning |
| --- | --- |
| Day | A calendar day on the phone's local clock, midnight to midnight. Stored as `localDate` = `YYYY-MM-DD`, computed once at write time and never recomputed. Rehras read at 00:30 counts for the new day. |
| Completion | One recitation of one bani, recorded as one row in `completions` (5.4). Reading again later the same day is a second completion. |
| Simran sitting | One run of the Naam Simran timer, recorded as one row in `simranSessions` (5.5) with its actual length in seconds. |
| Hazri | A day has hazri when it has at least one completion, or at least one simran sitting of `HAZRI_SIMRAN_MIN_SECONDS` or longer. |
| Goal | The container for the user's goal items. At most one goal is active at a time (5.2). |
| Goal item | One bani, or Naam Simran, inside a goal, with its own target, duration and reminder (5.3). |
| In scope | A goal item is in scope on a day when that day lies inside the item's window (4.2). A goal day exists only when at least one item is in scope. |
| Item met | A bani item is met on a day when that day's completions of its bani reach `timesPerDay`. A simran item is met when that day has one sitting of at least `simranMinutes` minutes. |
| Goal met | Every item in scope that day is met. |
| Blank goal | A goal with no item in scope today and none starting later. A blank goal is completed (4.3). |

## 3. Fixed constants

Put these in `lib/features/goals/domain/goal_constants.dart`. No other file may hard-code them.

| Constant | Value |
| --- | --- |
| `HAZRI_SIMRAN_MIN_SECONDS` | 300 (5 minutes) |
| `SIMRAN_DEFAULT_MINUTES` | 5 (the Simran menu's timer when no simran goal item is in scope) |
| `TIMES_PER_DAY_MIN` / `TIMES_PER_DAY_MAX` | 1 / 11 (bani items) |
| `SIMRAN_GOAL_MINUTES_MIN` / `SIMRAN_GOAL_MINUTES_MAX` | 5 / 120 |
| `SIMRAN_GOAL_MINUTES_PRESETS` | 5, 11, 21, 31 (plus Custom) |
| `DURATION_DAYS_MIN` / `DURATION_DAYS_MAX` | 1 / 365 |
| `DURATION_DAYS_PRESET` | 40 |
| `UNTIL_DATE_MAX_AHEAD_DAYS` | 365 (from today) |
| `DIARY_EDIT_WINDOW_DAYS` | 7 (today and the 7 days before it can be edited) |
| `REMINDER_DEFAULT_TIME` | 19:30 (pre-filled when the user switches a reminder on; reminders start off) |

`SIMRAN_GOAL_MINUTES_MIN` equals the hazri threshold on purpose: a simran item can never be met by a sitting too short to mark hazri.

## 4. Business rules

Each rule has an ID that tests cite. Goals never write anything of their own about a day: they are judged from completions and sittings, so the same record decides hazri and the goal.

### 4.1 Goal life cycle

- **GL1.** With no active goal, Home shows the Set Goal card (7.1). This includes first launch and the day after a goal completes.
- **GL2.** Adding an item when no goal is active creates a goal (`startDate` = today) and the item in one transaction.
- **GL3.** At most one goal is active (`completedOn` is null). Adding an item while a goal is active adds it to that goal.
- **GL4.** A completed goal is never reopened. The next item added creates a new goal.

### 4.2 Goal items

- **GI1.** At most one item per bani, and one simran item, is in scope at a time. Choosing a bani that already has an in-scope item opens that item for editing instead.
- **GI2.** An item's `startDate` is always today. Future start dates are not offered.
- **GI3. The window.** A day is in scope when `startDate <= day <= lastDay`. `lastDay` is the earliest of `endDate` and the day before `removedOn`. When both are null the item is open-ended.
- **GI4. Duration to end date**, computed on save:
    - `EVERY_DAY`: `endDate` = null.
    - `DAYS`: `endDate` = series start + `durationDays` − 1. A 40-day item started on 1 Oct ends on 9 Nov.
    - `UNTIL_DATE`: `endDate` = the chosen date, from today to today + `UNTIL_DATE_MAX_AHEAD_DAYS`.
- **GI5.** A simran item has `timesPerDay` = 1 and a required `simranMinutes`.
- **GI6. Editing** never changes a past day's verdict:
    - Reminder only: updated in place.
    - Duration: updated in place. The new `endDate` must be today or later.
    - Target (`timesPerDay` or `simranMinutes`): the old row gets `removedOn` = today; a new row starts today with the same `seriesId`, duration, `endDate` and reminder. If the old row's `startDate` is today, it is updated in place instead.
- **GI7. Removing** an item sets `removedOn` = today. It is out of scope from today; every earlier day keeps its verdict. An item removed on its start day was never in scope. There is no hard delete.
- **GI8.** After `lastDay` an item is out of scope and stays in the database.
- **GI9.** If an item's `baniId` is not in `content.db`, the app sets `removedOn` = today on load and logs a warning. Past days are unchanged; the app never crashes or shows a blank name.

### 4.3 Blank goal

- **BG1.** Removing the last in-scope item, with no other item ending later, sets the goal's `completedOn` = today in the same transaction. From today the goal is empty, so today has no second dot even if items were met earlier today.
- **BG2.** When the last items end by duration, `completedOn` = the day after the latest `lastDay`. `closeGoalIfBlank()` writes it at app start, on resume and at the day change.
- **BG3.** A completed goal and all its items stay in the database. The Diary keeps every dot they produced.

### 4.4 Hazri

- **HZ1.** `hazri(day)` is true when the day has at least one completion, or at least one sitting with `durationS >= HAZRI_SIMRAN_MIN_SECONDS`. Rows with `deletedAt` set are ignored.
- **HZ2.** Hazri does not depend on goals. It is marked with no goal, with a goal, and for banis outside the goal.
- **HZ3.** A sitting shorter than 300 s is stored and marks nothing.
- **HZ4.** The Simran menu's timer length is `simranMinutes` of the simran item in scope today, else `SIMRAN_DEFAULT_MINUTES`. A sitting stopped early is saved with its actual `durationS` and `completed` = false. One stopped at 7 of 11 minutes marks hazri but does not meet the goal.

### 4.5 Recording completions

- **CR1. Reader.** Reaching the last line of a bani logs one completion (`source` = `READER`).
- **CR2. Audio.** Playback reaching the end logs one completion (`source` = `AUDIO`). Reading and listening in the same opening of a bani log at most one completion between them.
- **CR3. Diary +.** On an editable day, + beside a bani logs one completion (`source` = `DIARY`). − sets `deletedAt` on that bani's newest completion that day, whatever its source.
- **CR4. Diary simran.** + logs a sitting with `durationS` = the larger of 300 and that day's in-scope `simranMinutes` × 60 (`source` = `DIARY`). − sets `deletedAt` on that day's newest sitting.
- **CR5.** Completions have no per-day uniqueness. Reading Japji three times is three rows.
- **CR6.** Completions beyond the target are kept and shown. They never count twice, because met means `count >= timesPerDay`.

### 4.6 The day verdict (one function)

`DayVerdict verdictOn(day, items, completions, sittings)` in `lib/features/goals/domain/day_verdict.dart` is pure and returns:

| Field | Type | Rule |
| --- | --- | --- |
| `hazri` | bool | HZ1 |
| `itemsInScope` | int | Items whose window contains `day` (GI3) |
| `itemsMet` | int | In-scope bani items with completions of that bani ≥ `timesPerDay`, plus an in-scope simran item with a sitting ≥ `simranMinutes` × 60 s |
| `goalState` | `NONE` / `MET` / `NOT_MET` | `NONE` if `itemsInScope` = 0; `MET` if `itemsMet` = `itemsInScope`; else `NOT_MET` |

Home, the Goals screen, the Diary grid and the Diary day screen all call it. Nothing re-derives hazri or goal state.

### 4.7 Diary dots

| Day | First dot (hazri) | Second dot (goal) |
| --- | --- | --- |
| Future, or before the first recorded day (DV3) | none | none |
| Today or past, `goalState` = `NONE` | orange if `hazri`, else grey | none |
| Today or past, `NOT_MET` | orange if `hazri`, else grey | grey (today stays grey until met) |
| Today or past, `MET` | orange (always, by DV1) | green |

- **DV1. Green implies orange.** `MET` needs at least one in-scope item met. A met bani item has at least one completion (`timesPerDay` ≥ 1). A met simran item has a sitting of at least 5 minutes (`SIMRAN_GOAL_MINUTES_MIN` = 5). Either one marks hazri. A test checks every combination (9).
- **DV2. A single-bani goal.** Completing that bani once (`timesPerDay` = 1) turns both dots on together.
- **DV3. The first recorded day** is the earliest `localDate` in `completions` or `simranSessions`, or `startDate` in `goals`, whichever comes first. Days before it show no dots, so the months before somebody started using the app are not shown as missed. With no rows at all, only today shows a dot.

### 4.8 Reminders

- **RM1.** Each item has its own `reminderTime` (`HH:mm`, local). Null means off, which is the default.
- **RM2.** The reminder fires once a day at `reminderTime` on each day the item is in scope.
- **RM3.** It does not fire on a day the item is already met. Reminders are re-planned after every completion, sitting, Diary edit and item change.
- **RM4.** Reminder rows are derived from items when planning; they are not stored. The notification ID is `ReminderIds.goal(itemId)`. They count toward the existing 60-pending cap.
- **RM5.** The title is the bani's name from `content.db` in the app language (simran: the existing localised Naam Simran label). The body is the string `goalReminderBody` (7.7).
- **RM6.** If notification permission is denied, the Goals screen shows the existing "reminders cannot arrive" card.

### 4.9 Celebration

- **CE1.** When today's `goalState` changes to `MET`, the goal-complete sheet is shown once that day (the existing `GoalCompleteCue`). It is never shown for a backfilled past day.

## 5. Local database schema (`user.db`, schema version 5)

Four tables carry this feature: `goals`, `goalItems`, `completions` and `simranSessions`. They live in the phone's drift database. `goalTicks` is removed, because goal progress is now read from completions and sittings (CR5).

### 5.1 Conventions (aligned with the Profile PRD)

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

### 5.2 `goals`

One row per goal. At most one row has `completedOn` = null (GL3).

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `id` | TEXT (PK) | no | UUID v4 |
| `startDate` | TEXT | no | `YYYY-MM-DD`, the day the goal was created |
| `completedOn` | TEXT | yes | `YYYY-MM-DD` of the first blank day (BG1, BG2). Null while active. |
| `createdAt` | DATETIME | no | UTC |
| `updatedAt` | DATETIME | no | UTC, every write |

### 5.3 `goalItems`

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

### 5.4 `completions`

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

### 5.5 `simranSessions`

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

### 5.6 Indexes and integrity

| Index | Table (columns) | Serves |
| --- | --- | --- |
| `idx_goal_items_goal` | `goalItems` (`goalId`) | Items of the active goal |
| `idx_goals_completed` | `goals` (`completedOn`) | Finding the active goal |
| `idx_completions_date` | `completions` (`localDate`) | Day and month reads |
| `idx_simran_date` | `simranSessions` (`localDate`) | Day and month reads |

GL3 and GI1 are enforced by the repository inside the same transaction as the write, not by a database constraint.

### 5.7 Repository operations

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

### 5.8 Migration from schema version 4

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

## 6. Cloud sync readiness (not built here)

This feature sends nothing to the cloud. Until a sync feature ships, **uninstalling the app or clearing its data loses every goal, completion and dot**. Once it ships, a profile restore brings goals and diary entries back as of the last weekly sync (`01-accounts.md` §13 D8).

A weekly phone-to-cloud sync is planned as its own feature document. The schema above is ready for it without another migration:

- Every row has a UUID `id`, which becomes the Firestore document ID.
- Every row has `updatedAt`, so a sync can send only rows changed since the last run.
- Undo is a soft delete (`deletedAt`), so it can be sent like any other change.

The intended Firestore shape follows the Profile PRD's rules: documents under the owning profile, and written only by the `api` Cloud Function.

| Local table | Firestore path (future) |
| --- | --- |
| `goals` | `profiles/{profileId}/goals/{id}` |
| `goalItems` | `profiles/{profileId}/goalItems/{id}` |
| `completions` | `profiles/{profileId}/completions/{id}` |
| `simranSessions` | `profiles/{profileId}/simranSessions/{id}` |

The owner has amended Profile PRD §12 so that restore brings these tables back (`01-accounts.md` §13 D8 and 13.2).

## 7. App behaviour by screen

String keys in `backticks` are listed with their English text in 7.7.

### 7.1 Home (Today)

| State | Shown |
| --- | --- |
| No goal ever created | Set Goal card: title `goalSetCardTitle`, subtitle `goalSetCardSubtitleFirst`. Not dismissible. Tap opens Add Goal (7.2). |
| Last goal completed (GL1) | Same card, subtitle `goalSetCardSubtitleAgain` |
| Active goal | Goal widget (below) |

The goal widget shows:

- **Header:** `goalWidgetTitle` and `goalWidgetProgress` (`itemsMet` of `itemsInScope` from `verdictOn(today)`), with a ring filled to `itemsMet / itemsInScope`. Tapping the header opens the Goals screen.
- **One row per in-scope item:** the bani name from `content.db` (simran: the existing localised label). Bani progress uses `goalTimesOfTarget`, e.g. "1 of 3". Simran shows `goalSimranMinutes` and a tick once met.
- **Row tap:** opens the reader for a bani, or the Simran menu for simran.

The existing hazri banner on Home is unchanged. It is shown to everybody and reads only `hazri(today)`.

### 7.2 Add Goal and Edit Item sheet

1. **Choose:** the featured banis (`JAPJ`, `CHAU`, `SUKH`, `ANND`, `REHR`), then More… for the rest of `content.db`, then Naam Simran. An item already in scope carries `goalInGoalBadge`; choosing it opens Edit (GI1).
2. **Target:**
    - Bani: `goalTimesPerDay` stepper, 1–11, default 1.
    - Simran: minute chips 5, 11, 21, 31 and Custom (5–120), default 11 (design 47). A custom value outside 5–120 shows `goalValidationMinutes` and nothing saves.
3. **Duration** (`goalDuration`): `goalDurationEveryDay` (default), `goalDurationDays` (stepper 1–365, default 40), or `goalDurationUntil` (date picker from today to today + 365).
4. **Reminder:** `goalReminder` switch, off by default. Switching it on shows a time picker set to 19:30.
5. **Save:** `goalSave` when adding, `goalEditSave` when editing. Calls `addItem`, or `editReminder`, `editDuration` and `editTarget` for whatever changed (5.7).

In Edit, a new end date before today shows `goalEndDateInPast` and nothing saves.

### 7.3 Goals screen

- Lists in-scope items of the active goal in creation order.
- Each row shows the name, the rule and today's progress. Rules read like "3 times a day · every day", "11 min · `goalDayOfTotal`" or "once a day · until 31 Dec". The reminder time shows when one is set.
- Each row's menu has Edit (7.2) and `goalRemove`.
- Remove asks first: `goalRemoveConfirmTitle` / `goalRemoveConfirmBody`, buttons Cancel and `goalRemove`. Confirming calls `removeItem`.
- An add button opens 7.2. With no active goal, the screen shows the Set Goal card from 7.1.
- No manual "+1" tick exists. Completions come only from CR1–CR4.
- If notification permission is denied and any item has a reminder, the RM6 card shows at the top.

### 7.4 Diary month grid

- Each day cell draws the dots in 4.7: orange is the existing hazri colour token, green is the existing goal colour token (`sage`), grey is the muted token.
- The legend always shows `diaryLegendHazri`. It shows `diaryLegendGoal` only when at least one day in the month has `goalState` ≠ `NONE`.
- Tapping today or a past day opens the day screen. Future days do nothing.

### 7.5 Diary day screen

1. **Hazri line:** `diaryHazriMarked` or `diaryNoHazri`.
2. **Goal block**, only when `goalState` ≠ `NONE`: `diaryGoalSummary`, then one row per in-scope item with "`count` of `timesPerDay`" (bani) or "minutes of `simranMinutes` min" (simran, best sitting), and a tick when met.
3. **Recited:** every bani with a live completion that day, in or out of the goal, as name × count. Each completion shows its local time and source label: `diarySourceRead`, `diarySourceListened`, `diarySourceDiary`, `diarySourceRestored` or `diarySourceMigrated`. Simran sittings show minutes, time, and `diarySimranStoppedEarly` when `completed` = false.
4. **Editing**, for today and the 7 days before it: every bani in `content.db` and Naam Simran has + and − (CR3, CR4). − is disabled when the count is 0. Older days are read-only and show `diaryReadOnly`.

Every change re-runs `verdictOn` for that day, so both dots update at once.

### 7.6 Reminders

Set per item in 7.2 and planned by the existing `ReminderScheduler` under RM1–RM6. Tapping a goal notification opens the reader for that bani, or the Simran menu.

### 7.7 Strings

English source text. `pa` and `hi` are required in the ARB files from day one and need a native speaker's review. Reuse an existing key where its English is identical.

| Key | English |
| --- | --- |
| `goalSetCardTitle` | Set a daily goal |
| `goalSetCardSubtitleFirst` | Choose the banis you want to recite each day. |
| `goalSetCardSubtitleAgain` | Your last goal is complete. Set a new one. |
| `goalWidgetTitle` | Today's goal |
| `goalWidgetProgress` | {met} of {total} done |
| `goalTimesOfTarget` | {done} of {target} |
| `goalSimranMinutes` | {minutes} min |
| `goalInGoalBadge` | In your goal |
| `goalTimesPerDay` | Times a day |
| `goalDuration` | How long |
| `goalDurationEveryDay` | Every day |
| `goalDurationDays` | For {n} days |
| `goalDurationUntil` | Until {date} |
| `goalDayOfTotal` | Day {n} of {total} |
| `goalReminder` | Reminder |
| `goalSave` | Add to goal |
| `goalEditSave` | Save |
| `goalRemove` | Remove |
| `goalRemoveConfirmTitle` | Remove {name}? |
| `goalRemoveConfirmBody` | It leaves your goal from today. Days already recorded stay as they are. |
| `goalEndDateInPast` | Choose today or a later date. |
| `goalValidationMinutes` | Enter 5 to 120 minutes. |
| `goalReminderBody` | Time for your daily goal |
| `diaryHazriMarked` | Hazri marked |
| `diaryNoHazri` | No hazri |
| `diaryGoalSummary` | Goal: {met} of {total} met |
| `diaryLegendHazri` | Hazri |
| `diaryLegendGoal` | Goal met |
| `diarySourceRead` | Read |
| `diarySourceListened` | Listened |
| `diarySourceDiary` | Marked in Diary |
| `diarySourceRestored` | Restored |
| `diarySourceMigrated` | Carried over |
| `diarySimranStoppedEarly` | stopped early |
| `diaryReadOnly` | Days more than 7 days ago can't be changed. |

## 8. Scenarios

Each row behaves exactly as stated and becomes one test. "Orange" and "green" are the Diary dots for that day.

### 8.1 Hazri without goals

| # | Given | When | Then |
| --- | --- | --- | --- |
| H-1 | No goal | Japji is read to the end | Orange. No second dot. Home still shows the Set Goal card. |
| H-2 | No goal | A 5-minute simran sitting completes | Orange |
| H-3 | No goal | Simran stopped at 4 min 59 s | Grey. The sitting is stored and marks nothing. |
| H-4 | No goal | Japji read halfway, reader closed | Grey. Nothing is recorded. |
| H-5 | No goal | Nothing all day | Grey first dot, no second dot |
| H-6 | Goal of Japji only | Rehras (not in the goal) is read | Orange; second dot grey |

### 8.2 Goals

| # | Given | When | Then |
| --- | --- | --- | --- |
| G-1 | Fresh install | Home opens | Set Goal card with `goalSetCardSubtitleFirst` |
| G-2 | Goal: Japji ×1 | Japji is read | Orange and green together; Home shows 1 of 1 (DV2) |
| G-3 | Goal: Japji ×3 | Japji is read once | Orange; second dot grey; Home row shows 1 of 3; widget shows 0 of 1 done |
| G-4 | Goal: Japji ×3 | Third reading | Green; widget 1 of 1; celebration sheet once (CE1) |
| G-5 | Goal: Japji ×1, Simran 11 min | Japji read; simran stopped at 7 min | Orange; second dot grey; simran row not met (HZ4) |
| G-6 | Goal: Simran 11 min | An 11-minute sitting completes | Orange and green |
| G-7 | Goal: Japji ×1 | Japji read twice | Green; Diary shows Japji ×2; met once, not twice (CR6) |
| G-8 | Goal met today | Japji read again in the evening | No second celebration sheet |
| G-9 | Goal: Japji ×1 with reminder 06:00 | Japji read at 05:30 | No reminder fires today (RM3) |
| G-10 | Goal: Japji ×1 with reminder 06:00, permission denied | Goals screen opens | RM6 card shown |
| G-11 | Japji in scope | User chooses Japji in Add Goal | Edit opens for the existing item (GI1) |

### 8.3 Duration, editing and removal

| # | Given | When | Then |
| --- | --- | --- | --- |
| E-1 | Japji ×1 for 7 days from 1 Oct, all kept | 8 Oct | 1–7 Oct green; 8 Oct no second dot; goal completed on 8 Oct; Home shows `goalSetCardSubtitleAgain` |
| E-2 | Japji and Rehras in goal | Rehras removed on 20 Oct | Goal continues with Japji; days up to 19 Oct unchanged; from 20 Oct only Japji is judged |
| E-3 | Japji only, met earlier today | Japji removed today | Goal completed today; today has no second dot; earlier days unchanged (BG1) |
| E-4 | Item added today | Removed today | Never in scope; no day changes |
| E-5 | Japji ×1 kept 1–10 Oct | On 11 Oct target changed to ×3 | 1–10 Oct stay green; from 11 Oct three readings are needed (GI6) |
| E-6 | Japji for 40 days, day 12 | Duration changed to 60 days | End date moves to series start + 59; days 1–11 unchanged |
| E-7 | Japji for 40 days | End date set to yesterday | `goalEndDateInPast`; nothing saves |
| E-8 | Japji in scope with reminder | Reminder time changed | Only the reminder moves; no verdict changes |
| E-9 | Goal completed yesterday | User adds Japji today | A new goal starts today (GL4); the old one stays completed |

### 8.4 Diary editing

| # | Given | When | Then |
| --- | --- | --- | --- |
| D-1 | Goal: Japji ×1; 3 days ago grey and grey | + Japji on that day | That day orange and green |
| D-2 | Japji read in the reader today, goal Japji ×1 | − Japji today | Count 0; grey and grey; the reader's completion has `deletedAt` set |
| D-3 | Rehras read today, goal Japji ×1 | − Japji is disabled (count 0) | No change |
| D-4 | A day 8 days ago | Day screen opens | Read-only with `diaryReadOnly` |
| D-5 | Simran goal 11 min | + simran on yesterday | Sitting of 660 s; orange and green |
| D-6 | No goal | + simran on yesterday | Sitting of 300 s; orange; no second dot |
| D-7 | Any day | Day screen opens | Lists every bani completed, in or out of goal, with count, time and source |

### 8.5 Boundaries and failures

| # | Given | When | Then |
| --- | --- | --- | --- |
| B-1 | Rehras finished at 23:59:50 | Saved at 00:00:05 | Counts for the day `localDate` was computed on: the day the reader reached the last line |
| B-2 | Reading at 00:30 | — | Counts for the new day |
| B-3 | Phone clock moved back a day | A bani is read | Stored under the clock's current date; existing rows unchanged |
| B-4 | Item for a bani missing from `content.db` | App starts | `removedOn` = today, warning logged, no crash, past days unchanged (GI9) |
| B-5 | Reader and audio both reach the end in one opening | — | One completion (CR2) |
| B-6 | Upgrade from schema 4 with goals and manual ticks | App starts | Migration 5.8; every past day's dots match what v4 showed, except days whose only goal credit was an `auto` tick with no completion behind it |
| B-7 | App uninstalled and reinstalled | — | No goals and no history (6). Home shows the Set Goal card. |
| B-8 | Phone offline all day | Banis read, goals edited | Everything works; nothing is queued for the network |

## 9. Acceptance checklist

The feature is complete only when every item passes. Tests use `flutter_test` with an in-memory `UserDb` and a fake `Clock`.

**Domain (pure)**

- [ ] `verdictOn` unit tests for every rule in 4.4 and 4.6.
- [ ] DV1 property test: for every combination of `timesPerDay` in {1, 3}, bani completions in {0, 1, 3}, simran item in {none, 5, 11 min} and sitting length in {0, 299, 300, 660 s}, `goalState` = `MET` implies `hazri`.
- [ ] Window tests for GI3 and GI4: open-ended, `DAYS`, `UNTIL_DATE`, removed on its start day, removed mid-run.

**Repository (in-memory drift)**

- [ ] Every operation in 5.7, including GL2, GL3, GI1, GI6 (both branches), GI7, BG1 and BG2.
- [ ] Diary − soft-deletes the newest live row whatever its source (CR3, CR4).
- [ ] Two completions of one bani on one day are two rows (CR5).
- [ ] Migration 5.8 from a version-4 fixture holding active, archived and simran goals plus `auto` and `manual` ticks.

**Screens (widget tests)**

- [ ] Home: Set Goal card in both variants, goal widget counts and ring (7.1).
- [ ] Add/Edit sheet: limits, defaults, validation strings, in-scope badge (7.2).
- [ ] Goals screen: no +1 control exists; Remove asks first (7.3).
- [ ] Diary grid draws the dots in the 4.7 table; legend rule (7.4).
- [ ] Diary day screen: hazri line, goal block, recited list, edit window (7.5).
- [ ] Home, the Goals screen, the Diary grid and the day screen agree for the same data. One test feeds all four the same rows.

**Scenarios and project rules**

- [ ] One test per row of Section 8 (H-, G-, E-, D-, B-).
- [ ] `test/core/l10n_test.dart` passes with every key in 7.7 present in `pa`, `hi` and `en`.
- [ ] `flutter analyze` is clean and `flutter test` passes.

**Manual, on a real Android phone**

- [ ] A goal reminder arrives at its time, and does not arrive after the item is met that day.
- [ ] Airplane mode: the whole of Section 8.2 works.

## 10. Out of scope and changes to current code

### 10.1 Out of scope (do not build)

- Weekly goals ("3 times a week") and per-goal streaks.
- A history screen for completed goals or ended items. The data is kept; no screen shows it.
- Points and badges (blocked on D14).
- Group or sangat goals, and sharing a goal into a group.
- Goals with a future start date.
- Cloud sync, backup or restore of any table in Section 5 (6).
- Changes to grace days, the nitnem streak, the sangat's group credit or the hazri banner's design.

### 10.2 What changes against the current code (`claude/japji-sahib-app-anypeh`)

| Today | After this document | Rule |
| --- | --- | --- |
| Independent goal rows, each with its own start | One goal holding items | GL1–GL4 |
| `goalTicks` with `auto` and `manual` ticks | Removed; goals read completions and sittings | CR5, 5.8 |
| Goals screen "+1" tick (green without orange) | Removed | DV1, 7.3 |
| `logCompletion` refuses a second reading of a bani on a day, so ×3 goals could only be met through ticks | Every reading is a row | CR5 |
| Simran goal credited by any completed sitting | Needs a sitting ≥ `simranMinutes` | 4.6 |
| Hazri from any completed sitting | Needs ≥ 300 s | HZ1 |
| Stopping keeps the goal in scope today (`endedOn` = today) | Removal takes effect today (`removedOn` = today) | GI7, BG1 |
| Restarting copies an `untilDate` that may already be past | Restart is a new item from today with fresh duration | GI2, GI4 |
| Missing bani hidden on Goals screen but still counted | Item removed from today, history kept | GI9 |
| Future-start goal shown as "Complete" | Future starts do not exist | GI2 |
| Goal reminder on by default at 19:30, fires even when met | Off by default; skipped once met | RM1, RM3 |
| Delete erases a goal and its ticks | No hard delete; Remove only | GI7 |
| The earlier version of this file (2026-09-25) | Replaced by this document | 0 |
