# 10. Weekly backup and restore

Written 2026-10-07 with Puneet Singh Nanda. It replaces the diary sync that
writes `users/{uid}/diary/{day}` directly from the phone
(`lib/features/sync/`), and it is what `01-accounts.md` §13 D8 (restore brings
back goals and diary entries) and `04-goals.md` §6 depend on.

Every decision in Section 11 was confirmed by the owner on 2026-10-07.

## 0. Implementation directive (mandatory, read first)

1. **No inference.** Every behaviour, field, endpoint, status code and limit comes from this document.
2. **The phone is the primary copy.** Goals and diary entries are stored on the phone, and everything keeps working with no network and no backup. The server copy exists for one purpose only: a restore, after the app's data is cleared or the phone is replaced. Nothing else reads it (owner, 2026-10-07).
3. **Stop on ambiguity.** If anything required is missing or contradictory, stop and ask the developer.
4. **Server access follows the Profile PRD.** The app never reads or writes Firestore directly. Everything goes through the `api` Cloud Function under `/api/v1`, authenticated with the anonymous ID token (`01-accounts.md` §6.0), and the Firestore rules deny all client access (§10.1 there).
5. **Strings are localised** in `pa`, `hi` and `en` (CLAUDE.md rule 5). English source text is in 8.4.
6. **Done means tested.** The feature is complete only when every item in Section 10 passes, `flutter analyze` is clean and `flutter test` passes.

## 1. Overview and requirement traceability

Once a week the app sends the server every row that changed since the last backup. After the app's data is cleared, or on a new phone, the user restores the profile by email link and then restores the data. A restore adds what the phone does not have and never overwrites newer data the phone already holds.

| Req # | Requirement (summary) | Where specified |
| --- | --- | --- |
| S1 | Every Sunday at 00:00 the app backs up its data to the server | 4.1, 6.2 |
| S2 | The backup holds goals, the profile and diary entries | 3, 5 |
| S3 | Sangat groups, their goals, members and members' completed banis are covered | 3.2 (by the sangat feature) |
| S4 | The data stays on the phone; the phone keeps working from it | 0.2, 4.4 |
| S5 | After the app's data is cleared, a button in the Profile section restores the data from the server | 4.3, 8.2 |
| S6 | A restore only adds or updates rows it receives; it never changes data the phone already has for another period, such as the current week | 4.3 |
| S7 | A server schema for the backup | 5 |
| S8 | An API to back up and restore | 6 |

## 2. Definitions

| Term | Meaning |
| --- | --- |
| Backup | Sending the server every local row whose `updatedAt` is later than the last successful backup |
| Restore | Downloading the server's rows and merging them into `user.db` under 4.3 |
| Week | Sunday to Saturday, by local date. `weekId` is the Sunday's date, `YYYY-MM-DD`. |
| Row | One row of a backed-up table (5.1), identified by its UUID `id` |
| Live row | A row with `deletedAt` null |
| Watermark | The phone-clock time a backup started, saved on the phone once the server has confirmed that whole backup (BK7). Rows with a later `updatedAt` are sent next time. It is compared only with `updatedAt` values, which also come from the phone's clock. |

## 3. What is backed up

### 3.1 Backed up by this feature

| Local table (`user.db`) | Defined in | Server location |
| --- | --- | --- |
| `goals` | `04-goals.md` §5.2 | `backupGoals/{goalId}` (5.4) |
| `goalItems` | `04-goals.md` §5.3 | Inside its goal's document (5.4) |
| `completions` | `04-goals.md` §5.4 | `backupWeeks/{weekId}` (5.5) |
| `simranSessions` | `04-goals.md` §5.5 | `backupWeeks/{weekId}` (5.5) |

### 3.2 Not copied by this feature

| Data | Why |
| --- | --- |
| Profile details | They already live on the server (`profiles/{profileId}`, `01-accounts.md` §4.1). A restore gets them back through the profile restore (§6.5 there). |
| Sangat groups, their goals, members, and members' completed banis | They live on the server as part of the sangat feature, which will define them. That feature document must say how they come back after a restore. |
| Reminders, settings, reading position, grace days | Not listed by the owner (11, B-6) |

## 4. Rules

### 4.1 When a backup runs

- **BK1. Weekly.** The app schedules a backup for Sunday 00:00 local time, with a random delay of 0–60 minutes so that every phone in one time zone does not call the server in the same minute. It uses Android WorkManager with a network constraint.
- **BK2. Catch-up.** If the phone was off, offline or asleep at that time, the backup runs at the first chance after it: when WorkManager's constraint is met or when the app is next opened, whichever comes first. A missed week is never skipped; the next backup carries everything since the watermark.
- **BK3. By hand.** The Profile screen has `backupNowButton` (8.2), which runs the same backup at once.
- **BK4. Only with a profile.** A backup runs only while the profile state is `ProfileLoaded` (`01-accounts.md` §8.3). Without a profile there is nothing to restore the data to, so nothing is sent.
- **BK5. Only the owner.** The server accepts a backup only from the uid that currently owns the profile (`owners/{uid}`). After the profile is restored onto another phone, the old phone's backups get `404 NO_PROFILE` and it stops (4.4).

### 4.2 What a backup sends

- **BK6. Changes only.** The app sends every row of the tables in 3.1 whose `updatedAt` is later than the watermark, soft-deleted rows included. The first backup sends everything.
- **BK7. Chunks.** Rows go in requests of at most `BACKUP_MAX_ROWS_PER_REQUEST` rows. The watermark moves forward only after the last chunk is confirmed, to the `startedAt` time the app recorded before reading the first row. A row changed while a backup is running is therefore sent again next time, never missed.
- **BK8. Idempotent.** Sending the same rows twice leaves the server unchanged (the merge in 4.3 applies on the server too), so a retry after a lost response is safe.
- **BK9. Server merge.** For each row the server keeps the version with the later `updatedAt`, and on a tie keeps what it has. It never deletes a row because a request left it out. A newly installed phone that has not restored therefore cannot wipe the server's history by backing up its few new rows.

### 4.3 Restore

- **RS1. Where.** The Profile screen has `restoreDataButton` (8.2). It is enabled only in `ProfileLoaded`.
- **RS2. After clearing data.** Clearing the app's data also removes the anonymous sign-in, so the phone has a new uid and no profile. The user first restores the profile by email link (`01-accounts.md` §8.8 and R2); after `PROFILE_RESTORED` the app offers the data restore straight away (8.3).
- **RS3. Merge, row by row**, inside one drift transaction per downloaded page:

| Local state of the row | Server row | Result |
| --- | --- | --- |
| Missing | Live | Inserted |
| Missing | Soft-deleted | Inserted as soft-deleted, so the deletion is remembered |
| Present | `updatedAt` later than local | Local row replaced by the server row |
| Present | `updatedAt` equal or earlier | Local row kept unchanged |
| Present, not on the server | — | Kept unchanged |

- **RS4. Never touches what it did not receive.** A restore never deletes a local row, and never changes a row the server did not send. Data the phone holds for the current week, or for any day after the last backup, stays exactly as it is.
- **RS5. One active goal.** If both the phone and the server have an active goal (`completedOn` null) and they are different goals, the phone's goal stays active. The server's goal is stored with `completedOn` = the phone goal's `startDate`, and its in-scope items get `removedOn` = the same date, so `04-goals.md` GL3 still holds and no day loses its history. (B-7)
- **RS6. Afterwards.** The watermark is left as it was: on a cleared phone it is empty, so the next backup sends everything, restored rows included, and the merge makes that harmless (BK9). Rows written on this phone before the restore are therefore never skipped. `closeGoalIfBlank()` runs (`04-goals.md` BG2), reminders are re-planned and the Diary and Home re-read. A restore never starts a backup on its own.
- **RS7. Interrupted.** A restore cut off part-way keeps the pages already merged. Running it again is safe, because the merge is idempotent.
- **RS8. Honest about the gap.** The restore screen says the copy is as of `lastBackupAt` and that anything done after it is not included (`restoreAsOf`, 8.4).

### 4.4 Failure and status

- **ST1.** A failed backup is retried by WorkManager with exponential backoff, and again at the next app open. Nothing is shown until the last successful backup is more than `BACKUP_STALE_DAYS` old; then the Profile screen shows `backupStale`.
- **ST2.** `404 NO_PROFILE` on a backup or restore calls `markNone()` (`01-accounts.md` §8.3) and cancels the weekly schedule.
- **ST3.** `429 RATE_LIMITED` waits for `retryAfterSeconds` and is not reported as an error.
- **ST4.** Errors use the Profile PRD's shared messages (`01-accounts.md` §8.10), localised.

### 4.5 Constants

Put these in `lib/config/app_config.dart` and `functions/src/config.ts`.

| Constant | Value |
| --- | --- |
| `BACKUP_WEEKDAY_TIME` | Sunday 00:00 local |
| `BACKUP_JITTER_MINUTES` | 60 |
| `BACKUP_MAX_ROWS_PER_REQUEST` | 2000 |
| `BACKUP_STALE_DAYS` | 14 |
| `BACKUP_RATE_LIMIT` | 20 backup requests per profile per hour |
| `RESTORE_PAGE_WEEKS` | 26 weeks per restore page |

## 5. Server schema (Firestore, `asia-south1`)

### 5.1 Conventions

The same as the Profile PRD (`01-accounts.md` §4): only the Cloud Function reads and writes these documents, field names are camelCase, enums are UPPER_SNAKE, and server times are Firestore `Timestamp`s set with `FieldValue.serverTimestamp()`. Row fields copy the local columns of `04-goals.md` §5 one to one, with DATETIME values as Firestore `Timestamp`s and `YYYY-MM-DD` dates as strings.

Everything sits under the owning profile, so a profile restore (which moves `ownerUid`) carries the backup with it and nothing has to be re-keyed.

**Why weeks, not one document per row:** Firestore bills reads and writes per document, and reads are the meter that matters (`00-platform.md` §0.3). A year of diary is 52 documents to restore rather than several thousand, and a weekly backup writes one or two week documents rather than one per paath.

### 5.2 Paths

```text
profiles/{profileId}
  backupMeta/manifest
  backupGoals/{goalId}
  backupWeeks/{weekId}
```

### 5.3 `profiles/{profileId}/backupMeta/manifest`

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `lastBackupAt` | timestamp | yes | Server time the last backup request completed. Null before the first. |
| `lastBackupUid` | string | yes | uid that made it |
| `goalIds` | array of string | no | Every `backupGoals` document ID |
| `weeks` | map of `weekId` → number | no | Row count per week document |
| `rowCount` | number | no | Total rows across all documents |
| `schemaVersion` | number | no | 1 |
| `updatedAt` | timestamp | no | Server timestamp on every write |

### 5.4 `profiles/{profileId}/backupGoals/{goalId}`

One document per goal, holding the goal and all its items.

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `goal` | map | no | The `goals` row: `id`, `startDate`, `completedOn`, `createdAt`, `updatedAt` |
| `items` | map of `itemId` → map | no | Each `goalItems` row with every column of `04-goals.md` §5.3 |
| `serverUpdatedAt` | timestamp | no | Server timestamp on every write |

### 5.5 `profiles/{profileId}/backupWeeks/{weekId}`

One document per week that has any diary row. `weekId` is the Sunday of the row's `localDate`.

| Field | Type | Nullable | Rule |
| --- | --- | --- | --- |
| `weekId` | string | no | Same as the document ID |
| `completions` | map of `id` → map | no | `completions` rows whose `localDate` falls in the week: `id`, `localDate`, `baniId`, `slot`, `source`, `completedAt`, `updatedAt`, `deletedAt` |
| `simranSessions` | map of `id` → map | no | `simranSessions` rows in the week: `id`, `localDate`, `startedAt`, `durationS`, `completed`, `count`, `source`, `updatedAt`, `deletedAt` |
| `serverUpdatedAt` | timestamp | no | Server timestamp on every write |

A busy week holds a few hundred rows of about 200 bytes each, far below Firestore's 1 MiB document limit. The function refuses a write that would take a document over 900 KB (`413 BACKUP_TOO_LARGE`, 6.2).

### 5.6 Indexes and rules

No composite index is needed: every read is by document ID. The rules stay deny-all (`01-accounts.md` §10.1).

## 6. API

All endpoints are under `API_BASE_URL` (`/api/v1`) and follow `01-accounts.md` §6.0: Bearer ID token, the error body, `401 UNAUTHENTICATED` and `500 INTERNAL`. Every endpoint first reads `owners/{callerUid}`; when it is missing, or its profile's `ownerUid` is not the caller, it returns `404 NO_PROFILE`.

### 6.1 `GET /api/v1/backup/manifest`

Returns the manifest, or an empty one when no backup exists yet. 2 reads (owner and manifest).

| Status | Body |
| --- | --- |
| 200 | `{ "lastBackupAt": "2026-10-04T00:31:12.000Z" \| null, "goalIds": [...], "weeks": { "2026-09-27": 41 }, "rowCount": 412 }` |
| 404 | `NO_PROFILE` |

### 6.2 `POST /api/v1/backup`

Request:

```json
{
  "goals": [ { "goal": { ... }, "items": [ { ... } ] } ],
  "completions": [ { ... } ],
  "simranSessions": [ { ... } ],
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

### 6.3 `GET /api/v1/backup/goals`

Returns every `backupGoals` document: `{ "goals": [ { "goal": {...}, "items": [...] } ] }`. One read per goal.

### 6.4 `GET /api/v1/backup/weeks?from={weekId}&limit={n}`

Returns up to `n` week documents (`n` ≤ `RESTORE_PAGE_WEEKS`), oldest first, starting at `from`: `{ "weeks": [ { "weekId": "...", "completions": [...], "simranSessions": [...] } ], "next": "{weekId}" | null }`. The app pages until `next` is null.

### 6.5 Cost per user

| Operation | Firestore reads | Firestore writes |
| --- | --- | --- |
| A normal weekly backup (one week and one goal changed) | 2 + 2 documents read for the merge | 3 (week, goal, manifest) |
| Restore of one year | 2 + goals + 52 | none |

## 7. Local storage on the phone

| Key | Where | Meaning |
| --- | --- | --- |
| `backup_last_at_v1` | shared_preferences | Watermark, UTC ISO string |
| `backup_running_since_v1` | shared_preferences | `startedAt` of a backup in progress (BK7) |

No `user.db` table is added. Every backed-up row already has `id`, `updatedAt` and, for diary rows, `deletedAt` (`04-goals.md` §5.1).

## 8. App behaviour

### 8.1 Background work

One unique periodic WorkManager job, `weekly-backup`, re-enqueued after each run for the next Sunday 00:00 plus jitter (BK1), with a network constraint. It is registered when the profile reaches `ProfileLoaded` and cancelled on `markNone()`.

### 8.2 Profile screen

Below the profile rows, shown only in `ProfileLoaded`:

- `backupLastLine` with the local date and time of `lastBackupAt`, or `backupNever`.
- `backupStale` instead, after `BACKUP_STALE_DAYS` without a successful backup (ST1).
- `backupNowButton`: runs a backup now (BK3) and shows progress, then `backupDone`.
- `restoreDataButton`: opens a confirmation (`restoreConfirmTitle`, `restoreConfirmBody` with `restoreAsOf`), then restores (4.3) with progress, then `restoreDone` with the number of rows added.

### 8.3 After a profile restore

After `200 PROFILE_RESTORED` (`01-accounts.md` §8.9), the Link Result screen adds `restoreDataButton` under its message, so the person restoring a phone is not left to find it on the Profile screen.

### 8.4 Strings

| Key | English |
| --- | --- |
| `backupLastLine` | Last backed up {date} |
| `backupNever` | Not backed up yet |
| `backupStale` | Not backed up for over two weeks |
| `backupNowButton` | Back up now |
| `backupDone` | Backed up |
| `restoreDataButton` | Restore my goals and diary |
| `restoreConfirmTitle` | Restore from backup? |
| `restoreConfirmBody` | This adds your goals and diary from the backup to this phone. Nothing already on this phone is removed. |
| `restoreAsOf` | Backup from {date}. Anything after that is not included. |
| `restoreDone` | Restored {count} entries |
| `restoreNothing` | There is no backup to restore yet |

## 9. Scenarios

### 9.1 Backup

| # | Given | When | Then |
| --- | --- | --- | --- |
| K-1 | Profile, 30 rows changed this week | Sunday 00:00 + jitter, online | One request, `BACKUP_SAVED`, watermark moves |
| K-2 | Phone off all Sunday | Turned on Monday | Backup runs Monday and carries the whole week (BK2) |
| K-3 | No profile | Sunday | Nothing is sent (BK4) |
| K-4 | 5,000 changed rows | Backup | Three requests, `final` only on the last; watermark moves after the third |
| K-5 | Response lost after the server wrote | Retry | Same rows sent again; server unchanged (BK8) |
| K-6 | A Japji completion added during a backup | Next week | That row is sent again (BK7) |
| K-7 | Phone cleared, profile restored, data not yet restored, two new paath | Sunday | The two rows are merged into the server; the server's history stays (BK9) |
| K-8 | Profile restored onto a second phone | The first phone's Sunday backup | `404 NO_PROFILE`; first phone stops backing up (ST2) |
| K-9 | A Diary − on last Thursday | Sunday | That completion is sent with `deletedAt` set; server keeps it as soft-deleted |

### 9.2 Restore

| # | Given | When | Then |
| --- | --- | --- | --- |
| R-1 | App data cleared | Profile restored by email link, then `restoreDataButton` | Goals and every backed-up completion and sitting are back; the Diary shows the old dots |
| R-2 | Server backup up to last Sunday; the phone has this week's rows | Restore | This week's rows are unchanged; earlier rows are added (RS4) |
| R-3 | The same completion on phone and server, server's newer | Restore | Phone row replaced by the server's |
| R-4 | The same completion, phone's newer | Restore | Phone row kept |
| R-5 | A row deleted on the server copy, missing on the phone | Restore | Inserted as soft-deleted; not shown anywhere |
| R-6 | Active goal on the phone and a different active goal on the server | Restore | Phone goal stays active; server goal stored as completed on the phone goal's start date (RS5) |
| R-7 | No backup exists | Restore | `restoreNothing`; nothing changes |
| R-8 | Network drops on page 2 of 3 | — | Page 1 kept; running it again finishes the rest (RS7) |
| R-9 | Restore run twice | — | The second run changes nothing |

## 10. Acceptance checklist

**Backend (Jest + emulators)**

- [ ] Every status of 6.1–6.4, including `NO_PROFILE` for a caller that no longer owns the profile.
- [ ] BK9 merge: newer wins, ties keep the server's, an omitted row is never deleted.
- [ ] The same request sent twice gives identical documents (BK8).
- [ ] `413 BACKUP_TOO_LARGE` at the 900 KB limit; `429` at the rate limit.
- [ ] Rules unit test: a client cannot read or write any path in 5.2.

**App (flutter_test)**

- [ ] Change detection by watermark, including soft-deleted rows (BK6), and the watermark rule of BK7.
- [ ] RS3 merge table, one test per row, and RS4: a local row the server did not send is never changed.
- [ ] RS5 with two active goals.
- [ ] Every row of Section 9.
- [ ] Profile screen states of 8.2; `l10n_test.dart` with every key of 8.4.

**Manual, on a real phone**

- [ ] Clear the app's data, restore the profile by email link, restore data: the Diary matches what it showed before.
- [ ] The weekly job runs after the phone has been off over a Sunday.

## 11. Decisions

| # | Question | Decision |
| --- | --- | --- |
| B-1 | "Sunday 12 midnight": the night between Saturday and Sunday, phone local time? | **Decided 2026-10-07:** Yes, plus up to 60 minutes of jitter |
| B-2 | A "Back up now" button as well as the weekly run? | **Decided 2026-10-07:** Yes (BK3) |
| B-3 | Back up only when a profile exists? | **Decided 2026-10-07:** Yes (BK4). Without one there is no way to restore. |
| B-4 | Wi-Fi only, as the current diary sync's setting allows? | **Decided 2026-10-07: any network.** The Wi-Fi-only setting is removed. |
| B-5 | What does the backup hold? | **Decided 2026-10-07:** goals and diary entries only, which live on the phone; the server copy exists only for a restore. Profile and sangat data are not copied (3.2). |
| B-6 | Should reminders, settings or grace days be backed up? | **Decided 2026-10-07:** No |
| B-7 | Two active goals at restore | **Decided 2026-10-07:** Keep the phone's; store the server's as completed (RS5) |
| B-8 | How long are backups kept? | **Decided 2026-10-07:** Indefinitely, while the profile exists |

## 12. Out of scope

- Real-time or per-change sync, and syncing between two phones at once (a profile has one owner at a time).
- Backing up the content database, audio or anything the app ships with.
- Browsing or editing a backup anywhere except through restore.
- Deleting a backup. There is no delete feature for profiles either (`01-accounts.md` §12).
