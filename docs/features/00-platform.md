# 0. Platform: how we stop shipping broken things

What every other file assumes. Decided 2026-09-26. Since 2026-10-08 the
backend, data and cost model are in `docs/ARCHITECTURE.md`; this file keeps
the testing rules every feature is held to, and the platform decisions.

---

## 0.1 to 0.4: moved to `docs/ARCHITECTURE.md`

On 2026-10-08 the backend, the data model and the cost model moved to
[`docs/ARCHITECTURE.md`](../ARCHITECTURE.md), the one home for how Hazri is
built and where its data lives:

| Was here | Now |
|---|---|
| 0.1 The backend is Blaze; the spend controls; the Functions contract (FN1–FN6) | ARCHITECTURE §5.1–5.3 |
| 0.1 "Functions to write" (`onMemberWrite`, `setRole`, `approveListing`, `expirePresence`, `healAdminless`, …) | **Retired.** That list belonged to the sangat design the specifications of 2026-10-07 replaced; the current Functions are ARCHITECTURE §7 |
| 0.2 Firestore, as it stands (`users/{uid}`, `users/{uid}/diary`, `presence/{day}/cities`, …) | **Retired** with that design; every current collection is ARCHITECTURE §5.1 |
| 0.3 The cost model is the data model (M1–M3) | ARCHITECTURE §10.1 |
| 0.4 Derived, never stored twice | ARCHITECTURE §10.2 |

What still holds from 0.1, unchanged: the project is `hazri-dfcc1` on Blaze;
Blaze closed D13; rule 4 holds in full; nothing a reader needs to read a
bani, hear it, see the calendar or keep the diary may require the network.

## 0.5 How we stop shipping broken things

The last fortnight's defects were not caught by 475 passing tests. That is the
thing to fix, and it is not "write more unit tests".

**1. Scenarios before code.** Each feature file lists its scenarios as
given/when/then. They become the tests. A scenario nobody can write is a rule
nobody has decided.

**2. Test at the seam the bug lives at.** The reminder planner had nine good
unit tests and was correct; both its bugs sat *either side* of it — in the
seeding before, and the manifest after. Unit-testing a pure function proves
the function and nothing else.

**3. Config is code and gets tested.** `test/android/manifest_test.dart` and
`window_theme_test.dart` exist because an Android resource nothing in Dart can
see broke the app twice. `firestore.rules` gets the same treatment: emulator
tests that each rule allows what it should and refuses what it should not.
Untested rules are how the invite bug shipped.

**4. A guard nobody has seen fail is not a guard.** Break it on purpose, watch
it go red, then fix it. This caught a manifest test of mine that passed
against a file I *thought* I had broken and had not.

**5. Some things only a phone can tell you** — notifications arriving, alarms
surviving battery optimisation, audio behaving on a call. The diagnostics
screen (§2.6) exists so a report is "here is what the phone says" rather than
"it does not work".

**6. Every fix names its evidence.** "Fixed" means a test that failed before
and passes now, or a screenshot from a phone. Four rounds of notification
fixes went out on reasoning alone and not one of them could have worked.

## 0.6 Open decisions

| # | Decision | Status |
|---|---|---|
| P1 | Spend cap | **Closed.** ₹2,000/month, alerts at 50/90/100% |
| P2 | Functions region | **Closed: `asia-south1` (Mumbai)**, following the database. Firestore triggers work there |
| P7 | Firestore triggers impossible in `asia-south2` | **Closed 2026-09-26** by moving the database to `asia-south1`. No data was migrated: there were no users |
| P3 | Emulator in CI | Yes. Rules are security, and untested rules shipped the invite bug |
| P4 | Disable Gemini and Vertex APIs | **Closed 2026-09-26.** Both disabled |
| P5 | Does diary sync default on? | **Closed 2026-10-07.** Diary sync is replaced by the weekly backup, which runs whenever a profile exists, with no switch (`10-backup.md` B-3, `09-diary.md` Y-4) |
| P6 | Firestore backups | **Reopened.** PITR and the 90-day daily backups were configured on the `asia-south2` database and went with it. They are per-database and must be set again on the new one: PITR at 7 days (Firestore's maximum), daily backups at 90 days. PITR's earliest version time is the moment it is enabled, so the window fills out over the following week. A restore creates a **new** database — it cannot be done in place |
| P8 | `firestore.rules` republished on the new database | **Closed 2026-09-26.** Worth keeping the reason: a new database starts in **locked mode**, every read and write refused, and the app reports that as `SangatRefused` rather than as offline |
