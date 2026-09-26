# 0. Platform: the backend, the data, and how we stop shipping broken things

What every other file assumes. Decided 2026-09-26.

---

## 0.1 The backend moves to Blaze

**Decision: Firebase Blaze with Cloud Functions.** Spark is what made a long
list of things impossible, and each one has been sitting in "Known gaps" being
explained away on screen instead of built.

What it unlocks, feature by feature:

| Was impossible on Spark | Becomes possible |
|---|---|
| Any push notification at all | "You were added to a sangat", the group's daily digest, a goal reached, a corrected line |
| A group total nobody can forge | A counter a Function maintains; every member can currently write the document, so every member could lie |
| "Who is sitting right now" | Presence with a heartbeat and a server-side expiry |
| Approving a listed group | A callable, or an admin claim, instead of editing the console by hand |
| A daily digest at a fixed hour | A scheduled Function |

**Cost.** At the scale of this app the Blaze free allowance covers it: the free
tier is not removed when you add a card, it still applies, and only usage past
it bills. Reads are the thing to watch, which is why the globe is one document
per city per day rather than one per person.

**Set a budget alert and a hard spend cap before anything is deployed.** A
runaway loop in a Function is the only realistic way this costs real money, and
a cap turns that from a bill into an outage. This is the first task of the
backend work, not the last.

**What does not change.** Rule 4 holds in full: no ads, no third-party
tracking, no advertising ID, no PII, no free text except where the reader typed
it and pressed send (§3.1 feedback). The sangat stays opt-in. Nothing that a
reader needs to read a bani, hear it, see the calendar or write the diary may
require the network.

### Functions to write

| Function | Trigger | Does |
|---|---|---|
| `onMembershipCreated` | Firestore create on `groups/{g}/members/{uid}` | Push "you were added", bump the group's member count |
| `onMembershipDeleted` | Firestore delete | Decrement the count |
| `onPaathLogged` | Firestore write on a member's count | Recompute the group total; push if the goal is now reached |
| `dailyDigest` | Scheduled, per timezone bucket | One push per group per day with what the group did |
| `expirePresence` | Scheduled, every 5 min | Clear "sitting now" rows older than their heartbeat window |
| `approveListing` | Callable, admin only | Flip `listed` on a group after review |
| `onFeedback` | Firestore create | Notify the owner; nothing goes back to the reader automatically |

Every Function is idempotent and every one has a unit test with the emulator.
A Function that writes a counter must be safe to run twice.

## 0.2 The data model, in one place

Three stores, and the rule for which is which:

**`content.db`** — read-only, bundled in the APK, built by the content
pipeline. Banis, lines, meanings, timings, the Nanakshahi calendar, cities,
the 200 Vichar lines. Never written at runtime. Corrections ship in a release.

**`user.db`** (drift, on the phone) — completions, simran sessions, goals, goal
ticks, reminders, grace days, event overrides, reading progress. **This is the
source of truth for everything personal.** It works with the radio off. Schema
is at 4.

**Firestore** — only what is inherently shared or inherently off-device: the
account, group membership, group goals and counts, city presence, the Vichar
library, the diary *backup*. The diary's truth stays on the phone; Firestore
holds a copy for restoring onto a new one.

**The rule:** if a feature can be answered from `user.db`, it must be, and the
network may only make it better. Anything that breaks when the radio is off,
and is not the sangat, is a bug.

## 0.3 Derived, never stored twice

Hazri is derived from completions and sittings. Goal outcomes are derived from
goals and ticks. Streaks are derived from completions. **None of them gets a
column.** The one time this was violated in spirit — three screens each
deriving "goals met" their own way — produced the defect that started this
whole exercise.

Where something is expensive to derive, it is cached with the inputs it was
derived from, and invalidated by them. It is never written as a second truth.

## 0.4 How we stop shipping broken things

The last fortnight's defects were not caught by 475 passing tests. That is the
thing to fix, and it is not "write more unit tests".

**1. Scenarios before code.** Each feature file lists its scenarios as
given/when/then. They become the tests. A scenario nobody can write is a rule
nobody has decided.

**2. Test at the seam the bug lives at.** The reminder planner had nine good
unit tests and was correct; both its bugs sat *either side* of it — in the
seeding before, and the manifest after. Unit-testing a pure function proves
the function. Test `reschedule()` end to end, not `plan()`.

**3. Config is code and gets tested.** `test/android/manifest_test.dart` and
`window_theme_test.dart` exist because an Android resource nothing in Dart can
see broke the app twice. Firestore rules get the same treatment: the emulator
has a rules test suite, and every rule in `firestore.rules` needs a test that
it allows what it should and refuses what it should not.

**4. A guard nobody has seen fail is not a guard.** Break it on purpose, watch
the test go red, then fix it. This caught a manifest test of mine that passed
against a file I *thought* I had broken and had not.

**5. Some things only a phone can tell you.** Notifications actually arriving,
alarms surviving battery optimisation, the audio session behaving on a call.
For these the app gets a **diagnostics screen** — permission state, exact-alarm
state, pending count, next fire time, a "send one now" button — so a report is
"here is what the phone says" rather than "it does not work".

**6. Every fix names the evidence.** "Fixed" means a test that failed before
and passes now, or a phone screenshot. Four rounds of notification fixes went
out on reasoning alone and not one of them could have worked.

## 0.5 Open decisions

| # | Decision | Default if nobody chooses |
|---|---|---|
| P1 | Blaze spend cap figure | $10/month, alert at $2 |
| P2 | Which region for Functions | `asia-south1` (Mumbai) — most readers are in India |
| P3 | Emulator in CI, or unit tests only | Emulator: rules are security, and untested rules are how the invite bug shipped |
