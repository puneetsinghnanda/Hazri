# 7. Simran and the globe

---

## 7.1 Purpose

Five to thirty-one quiet minutes of Naam Simran, and the sense — honestly
conveyed — that you are not doing it alone.

## 7.2 What exists today

**The screen** follows the reader's mock-up of 2026-09-20, which supersedes
design 29: "Daily Simran" in a serif wordmark, a kicker, ੴ between two fading
rules (read from content.db, never typed in Dart), a verse, then the globe, the
presence line, the legend and the controls. One screen whether or not a sitting
is running — the countdown takes the presence line's place.

**The globe** is an orthographic projection of Natural Earth 1:110m coastlines
stored as TopoJSON arcs in `assets/geo/world.bin` (594 arcs, 4,527 points,
19 KiB). Each point carries its sin and cos so a frame of the spin costs no
trigonometry. It turns in both axes under a finger.

**A sitting** — `SimranSession` with `runningSince`, `banked`, `elapsed`,
`total`. Begin, Pause, End. The length comes from an open simran goal if there
is one, otherwise Settings. ਵਾਹਿਗੁਰੂ drifts off the globe, one word per
utterance, from `SimranTrack.onsets`.

**Presence** — one document per **city** per **day**:
`presence/{day}/cities/{cityId}` with `{city, lat, lon, count}`. Written by
`markSitting` when a sitting **completes**. Read with a `sum()` aggregation for
the headline and an ordered query capped at 300 cities for the dots. Re-read
every 45 seconds while the tab is open, after a sitting, and on resume.

## 7.3 Wrong or missing

**The screen says "here today" and the reader reads "sitting now".** Those are
different things, and the gap is the single biggest problem with this feature:

1. **Presence is only written when a sitting finishes.** Two people sitting
   together see nothing of each other until they each stop.
2. **Two people in the same city are one dot.** By design — the globe knows
   cities, not people — but it reads as a bug when you are testing with two
   phones in one house.
3. **No account, no globe.** `simranPresenceProvider` returns empty without an
   account, and your own dot is drawn from Settings on the phone. So the screen
   looks identical whether the fetch worked or never happened.
4. **The count can be inflated.** The rules pin an update to exactly +1, but
   nothing stops somebody calling it repeatedly. Spark had no Function to fix
   that. Blaze does.
5. **Design 29's month total and country count are not shown**, because nothing
   counts them.
6. **A sitting is lost if the process dies.** `runningSince` is in memory.

## 7.4 The behaviour

### The sitting

**S1.** Length comes from an open simran goal, else the Settings default, else
5 minutes. Shown on the button before it starts.

**S2.** Pause banks the elapsed time and stops the recitation. End logs what
was banked. A sitting under its full length is logged as **not completed** and
marks nothing — not hazri, not a goal.

**S3.** A sitting survives backgrounding and process death: `runningSince` is
persisted, and on resume the elapsed time is recomputed from the clock.

**S4.** The screen keeps the display on while visible, and the timer keeps
running when it is not.

### Presence — the honest version

**S5.** Two separate ideas, named separately on screen, never conflated:

- **Sitting now** — people in a sitting at this moment. A heartbeat every
  30 seconds; a Function expires anything older than 2 minutes.
- **Sat today** — completed sittings today. What exists now.

**S6.** The globe shows **sitting now** as the live, breathing layer, and **sat
today** as the quieter one. The headline names which it is counting.

**S7.** Still one document per city, not per person. The cost model is the
design: a read per active city, not per member. **No uid, no name, no position
finer than the city somebody chose themselves** — the globe must not be able
to identify anybody.

**S8.** Two people in one city remain one dot, sized by the count, and the
headline says "2 here". This is stated on the legend so it is not read as a
bug.

**S9.** Your own city is lit from Settings, needs no account, and **adds
nothing to the count**. Somebody who never joins the sangat sees where they
are and an honest zero for everybody else.

**S10.** Counts a client cannot be trusted with are maintained by a Function.
The client increments its own city's "sitting now" and the Function reconciles.

## 7.5 Scenarios

**Success**

| Given | When | Then |
|---|---|---|
| No account | Opening Simran | The globe, own city lit, "you are the first here today" — never an error |
| A simran goal of 11 min | Begin | An 11-minute sitting, logged as 11 minutes |
| No goal | Begin | The Settings length, 5 by default |
| A sitting running | Pause, then Resume | The clock holds and continues; the recitation follows |
| A sitting running | Pause, then End | What was sat is logged; if short of the length, not completed |
| A full sitting | It completes | Hazri marked, simran goal credited, city count +1, globe re-read |
| Two people, different cities, both sitting | During the sitting | **Both dots live**, under "sitting now" |
| Two people, same city, both sitting | During | One dot, "2 here" |
| A sitting running | Backgrounding for 3 minutes | The countdown is correct on return |
| A sitting running | The process is killed | On reopening, the sitting is still running with the right elapsed time |

**Failure**

| Given | When | Then |
|---|---|---|
| No network | Begin and complete | The sitting runs, is logged locally, hazri marks. The globe says it could not reach the sangat |
| Firestore rules not published | Marking | `SangatRefused`, said as "our end, not yours" — never as offline |
| No city chosen | Opening Simran | Asked for one, with why. The globe still turns |
| The recitation is missing | A sitting | It runs silently; no ਵਾਹਿਗੁਰੂ words, because there are no onsets to take them from |
| Reduced motion is on | Any time | The globe is still, the words do not appear, the sitting is unchanged |
| A client spams `markSitting` | — | The Function reconciles; the displayed count cannot be inflated indefinitely |
| The app is killed mid-sitting and not reopened | 2 minutes later | The heartbeat lapses and the Function removes them from "sitting now" |
| 300+ cities active | — | The dots cap at 300; the headline counts all of them via aggregation |

## 7.6 Backend

- `presence/{day}/cities/{cityId}` — `{city, lat, lon, satToday}` as now.
- **New:** `presence/{day}/cities/{cityId}/live/{uid}` — `{beatAt}`, written
  every 30s while sitting, deleted on end. A Function sweeps stale rows every
  5 minutes and maintains `sittingNow` on the city document so the client
  reads one document, not a subcollection.
- **New:** monthly totals and a country count, written by a scheduled Function
  — which is what design 29 always wanted and nothing could supply.

## 7.7 Open decisions

| # | Decision | Default |
|---|---|---|
| S-1 | Does "sitting now" replace "here today" or sit beside it? | Beside. Both are true and they answer different questions; the headline names which |
| S-2 | Heartbeat interval vs battery | 30s while the screen is on, none while it is off — a sitting with the screen off still counts locally, it simply is not broadcast |
| S-3 | Design 29's third legend colour, "in the sangat" | Still not shown: a member's city is on their private user document and membership rows carry a name, not a place. Needs a decision about storing city on the membership |

## 7.8 Acceptance

- A test that an incomplete sitting marks nothing anywhere.
- A test that a sitting survives process death with the right elapsed time.
- Emulator test: the sweep Function expires a stale heartbeat.
- Device: two phones, two cities, both sitting, both dots live.
- Device: two phones, one city, one dot saying 2.
