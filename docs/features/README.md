# Feature specifications

One file per feature. Each says what exists today, what is wrong with it, what
the behaviour **will** be, and every scenario — success and failure — that the
behaviour has to survive.

| # | Feature | File |
|---|---|---|
| 1 | User profile: setup, email verification, restore | [`01-accounts.md`](01-accounts.md) |
| 2 | Notifications | [`02-notifications.md`](02-notifications.md) |
| 3 | First run: splash, intro, setup | [`03-first-run.md`](03-first-run.md) |
| 4 | Goals and hazri | [`04-goals.md`](04-goals.md) |
| 5 | Today (the home screen) | [`05-today.md`](05-today.md) |
| 6 | Nitnem and the reader | [`06-nitnem.md`](06-nitnem.md) |
| 7 | Simran and the globe | [`07-simran.md`](07-simran.md) |
| 8 | Sangat: groups, roles, invites | [`08-sangat.md`](08-sangat.md) |
| 9 | Diary | [`09-diary.md`](09-diary.md) |
| 10 | Weekly backup and restore | [`10-backup.md`](10-backup.md) |

`00-platform.md` holds what they all share: the backend, the data model, and
the testing rule that comes out of how this went wrong.

---

## Why these exist

The app was built from screen designs with no written behaviour spec, so each
screen worked out its own logic. That is not a guess — it is what the defects
of the last fortnight have all been:

- Today, the diary grid and the diary day screen each decided "were the goals
  met" differently. Three answers, one question.
- Hazri was hidden behind the sangat on the home screen, because nobody had
  written down that hazri is a local, account-free thing.
- The Gurpurab reminder fired every night claiming tomorrow was a Gurpurab,
  because nobody had written down what should make it fire.
- Reminder defaults were seeded as a side effect of a screen being looked at,
  so a phone that never opened that screen scheduled nothing.
- `ScheduledNotificationReceiver` was missing from the manifest, so no
  notification could ever appear, whatever the Dart did.

Every one of those is a **specification** failure that showed up as a code
failure. None of them was caught by a unit test, because a unit test can only
check the logic somebody wrote, not the logic nobody decided.

## What each file must contain

1. **Purpose** — what this is for the person holding the phone, in a sentence.
2. **Today** — what is actually built, with file paths, honestly.
3. **Wrong or missing** — with the evidence.
4. **The behaviour** — the decided rules, numbered so a test can cite one.
5. **Scenarios** — success *and* failure, written as
   *given / when / then*, so each becomes a test with no translation step.
6. **Backend** — what the server does, if anything.
7. **Open decisions** — what is still the owner's call, with a default.
8. **Acceptance** — the checks that must exist and pass before it is done.

A rule nobody can write a scenario for is not a rule yet.

## The order to build in

**Nothing is implemented until every feature has its technical
specification** (owner, 2026-10-07). The specifications are written first,
all of them, and building starts after; a feature whose file is still the
old one is not ready to build.

Once building starts, feature order is not preference, it is dependency:

1. **00-platform** — the backend and the data model everything else assumes.
2. **02-notifications** — half-broken in the reader's hands right now.
3. **04-goals** and **09-diary** — one shared rule, already half done.
4. **01-accounts** — the gate the sangat sits behind.
5. **08-sangat** — needs accounts and the backend.
6. **07-simran** — needs the backend for live presence.
7. **05-today**, **06-nitnem** — mostly consolidation once the rest is settled.
8. **03-first-run** — last, because it introduces everything else and should
   be designed once the rest has stopped moving.
