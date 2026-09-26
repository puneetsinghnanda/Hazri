# 0. Platform: the backend, the data, and how we stop shipping broken things

What every other file assumes. Decided 2026-09-26, updated the same day once
Blaze was live.

---

## 0.1 The backend is Blaze, and it is live

**Firebase project `hazri-dfcc1`, Blaze plan, active.** Spark is what made a
long list of things impossible, and each one had been sitting in "Known gaps"
being explained away on screen instead of built.

| Was impossible on Spark | Now |
|---|---|
| Any push notification at all | FCM with a Cloud Function sender |
| A group total nobody can forge | A Function maintains it; every member can write the group document, so a client-written counter could always be a lie |
| "Who is sitting right now" | Presence with a heartbeat and a server-side sweep |
| Approving a listed group | A callable, not a console edit |
| A daily digest at a fixed hour | A scheduled Function |

**This closes D13** (what sends a push). Blaze and Cloud Functions; the Vercel
cron alternative is dropped, along with the service-account key it would have
needed off-device.

**What does not change.** Rule 4 holds in full: no ads, no third-party
tracking, no advertising ID, no PII, and no free text except where the reader
typed it and pressed send (§3.1 feedback). The sangat stays opt-in. Nothing a
reader needs to read a bani, hear it, see the calendar or write the diary may
require the network.

### The spend controls, as configured

| Control | Value |
|---|---|
| Spend cap | **₹2,000 / month**, Firebase-generated caps per cappable service |
| Cappable services | Cloud Run, Cloud Run Functions, Gemini API, Vertex AI |
| Project budget alert | `Firebase Project hazri-dfcc1`, monthly, 50 / 90 / 100% |
| Expected actual spend | **₹0.** The free allowance does not go away on Blaze |

Three things about that cap which matter more than the number:

**C1 — Firestore cannot be capped.** It is not in the cappable list, and it is
our largest cost driver by a distance. The only protection there is the data
model (§0.3) and the budget *alert*.

**C2 — costs record up to 24 hours late**, so a cap can lag reality by a day.
A Function in a write-trigger-write loop could burn for hours before anything
pauses. **The cap is the last line, not the first.**

**C3 — a cap that trips takes the app's server side offline.** Pre-release
that is the right trade. After launch it is not, and it becomes an alert plus
a phone call instead.

**Gemini API and Vertex AI are to be disabled** (APIs & Services → Enabled
APIs). Nothing in this repository references either — no Gemini, no Vertex, no
`generativelanguage`, no `aiplatform`. They are the two most expensive things
that could possibly run on this project, and disabling them removes the whole
category rather than alerting after the fact.

### The Functions contract — the real first line of defence

Every Cloud Function in this project:

**FN1 — `maxInstances: 10`.** Caps how wide a runaway can fan out. There is no
workload here that needs more.

**FN2 — `minInstances: 0`.** Min-instances is the only way to be billed while
nothing is happening.

**FN3 — never write to what triggers you** without a guard that provably
terminates. A Firestore-triggered Function that writes to its own trigger
collection is the loop that generates the horror stories. Where a Function
must write back, it writes to a *different* document and checks for a no-op
before writing.

**FN4 — idempotent, always.** Functions retry. A Function that maintains a
counter must be safe to run twice on the same event; recompute from source
rather than incrementing blind.

**FN5 — same region as Firestore.** Cross-region calls add latency and egress
for nothing. **Check the existing Firestore location before choosing** — a
Firestore database's location is permanent once set, so the database decides
the region, not the other way round.

**FN6 — every Function has an emulator test, including being run twice.**

### Functions to write

| Function | Trigger | Does |
|---|---|---|
| `onMemberWrite` | `groups/{g}/members/{uid}` write | Maintains `memberCount` and `total`; pushes P1, P3, P5 |
| `setRole` | Callable | Promote/demote, admin-only, enforces "a group always has an admin" |
| `removeMember` | Callable | Admin-only |
| `approveListing` | Callable | Owner-only; flips `listed` after review |
| `dailyDigest` | Scheduled | One push per group per member timezone |
| `expirePresence` | Scheduled, 5 min | Clears stale "sitting now" heartbeats |
| `healAdminless` | Scheduled, daily | Promotes the earliest-joined member of a group with no admin |
| `onVerified` | Auth / callable | Sets `verified`; a client that can write it can claim anyone's email |
| `onFeedback` | `feedback/{id}` create | Notifies the owner (§3.1) |

## 0.2 Firestore, as it stands

The collections already deployed and governed by `firestore.rules`:

```
users/{uid}                      name, city, email, verified
users/{uid}/diary/{day}          the diary backup — a copy, never the truth
groups/{groupId}                 name, kind, goal, listed, listingRequested
groups/{groupId}/members/{uid}   name, count, role (admin | member)
presence/{day}/cities/{cityId}   city, lat, lon, count
aggregates/{doc}                 server-written only, no client may write
content/{doc=**}                 the Vichar library; any signed-in phone reads
```

Being added:

```
groups/{groupId}                 + memberCount, total   (Function-maintained)
presence/{day}/cities/{cityId}   + sittingNow           (Function-maintained)
presence/{day}/cities/{c}/live/{uid}   beatAt           (client heartbeat)
users/{uid}/tokens/{token}       an FCM registration token per device
feedback/{id}                    §3.1; write-only to the reader, read to owner
```

**A deletion leaves nothing behind.** A subcollection does not go with its
parent, so deleting an account must explicitly remove `diary`, `tokens` and
every membership row. A Function finishes what the client could not reach.

## 0.3 The cost model is the data model

Firestore bills per document read. Every design choice below exists for that
reason and must not be undone for convenience:

| Screen | Reads | Why it is that shape |
|---|---|---|
| Today, Nitnem, Diary, the reader | **0** | Entirely from `user.db`. The network may improve them; it may never be required |
| Simran globe | 1 aggregation + ≤300 docs | **One document per city per day, not per person.** At a hundred thousand readers, per-person would be a hundred thousand reads every time somebody opened Simran |
| A group | 1 group doc | Not an aggregation over members. This is what the maintained `total` is for |
| The sangat tab | 1 per group joined | Read by id from the account's own array; the collection is never queried |

**Three rules that follow:**

**M1 — if it can be answered from `user.db`, it must be.** Anything that
breaks with the radio off, and is not the sangat, is a bug.

**M2 — never query a collection where a document id is known.** `list` is shut
in the rules for exactly this reason; `get` by id is what the app does.

**M3 — a counter a client can write is a counter a client can forge.** Every
shared number is either Function-maintained or aggregated, never client-set.

## 0.4 Derived, never stored twice

Hazri is derived from completions and sittings. Goal outcomes are derived from
goals and ticks. Streaks are derived from completions. **None of them gets a
column.** The one time this was violated in spirit — three screens each
deriving "goals met" their own way — produced the defect that started this
whole exercise.

Where something is expensive to derive it is cached with the inputs it came
from, and invalidated by them. It is never written as a second truth.

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
| P2 | Functions region | **Follows the Firestore location**, which is permanent. Check the console before the first deploy |
| P3 | Emulator in CI | Yes. Rules are security, and untested rules shipped the invite bug |
| P4 | Disable Gemini and Vertex APIs | **Do it.** Unused, and the most expensive possible accident |
| P5 | Does diary sync default on? | No. Opt-in, like the rest of the sangat |
