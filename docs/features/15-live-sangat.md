# 15 · Live sangat

Written 2026-11-18 with the owner, after five rounds of design between
2026-11-17 and 2026-11-18. The screens are designs 125-129, drawn by
`tools/design/build_phase2.py`; the three scenes are
`tools/design/live_scenes.js`. **Designed, not built**: nothing here is in the
app until the owner says to build it, and the privacy change in §8 ships in the
same release as the feature or not at all.

This file also changes the Sangat tab (`08-sangat.md` §8.1): it becomes two
tabs, Discover and My groups (LS2-LS4).

---

## 1. Purpose

Three groups that are always on, which anybody can join and sit with at any
hour: Naam Simran, Mool Mantar and Chaupai Sahib. Each plays its recitation
continuously, with the sangat on a turning globe or in its own scene, and shows
how many people are listening right now. It is meant to feel like sitting in
a live sangat: open it at 03:00 or at noon and it is already going.

## 2. What it is

**LS1. Three live groups, made by the system.** They are not created by
anybody, not edited in the admin website, and never end:

| Group | Kind | Recitation | Scene |
|---|---|---|---|
| Naam Simran | Meditation | the owner's 30-second ਵਾਹਿਗੁਰੂ clip | **The globe**: the world turning, a thread of light from every city with a listener up to ਵਾਹਿਗੁਰੂ |
| Mool Mantar | Meditation | the owner's Mool Mantar clip | **ੴ among the stars**: thirteen stars join into a circle round ੴ through the loop and let go |
| Chaupai Sahib | Jaap | the owner's Chaupai Sahib clip | **The jot in the shield**: a diya's flame under a turning dome of light |

The recordings are the owner's, given to the app as files. None is generated,
paraphrased or made by a machine (CLAUDE.md rule 3), and none is fetched: they
ship in the APK under `assets/live/`.

**LS1a. Live is true, and the audio is on the phone.** The recording is
bundled and played in a seamless loop; it is not streamed. What is live is
the sangat: everybody in the group hears the same second of the recording at
the same moment (LS6), and the counts and the people joining are real (LS7,
LS8). Nothing on screen claims a broadcast, a server or a Gurdwara that the
sound comes from.

## 3. The Sangat tab

**LS2. Two tabs, Discover first.** The Sangat tab has two tabs, **Discover**
and **My groups · N** (N is how many groups you are in, live, built-in and
your own). It opens on My groups when you are in any group, and on Discover
when you are in none. The choice is made each time the tab opens; it does
not remember the last tab.

**LS3. Discover** (design 125): the three live groups as a row of tall cards,
all three on screen; then the built-in groups (`08-sangat.md` VS2), each with
its goal, a progress bar, members, percent and days left, and Join or Joined;
then a card for your own group, with Create group and Join with a code. Your
own groups are private and joined only by invite (`08-sangat.md` K5), so
Discover never lists them.

**LS4. A live card** shows its scene, LIVE, its kind and name, how many are
listening, and Join, or Joined once you are in it. Tapping it opens the live
group (LS5).

**LS4a. My groups** (design 126): Create group and Join group at the top;
then **Live, you are in**, each live group you joined with how many are
listening, your minutes there today and **Listen**; then **Running**, each
group with its ring, goal, a chip for the days left, one for what you gave
today and one for its members (and "built-in"); then **Ended**, muted.

## 4. A live group

**LS5. The page** (design 127, option A): the scene fills the screen. At the
top: back, LIVE, the listening count and Share. Under them the group's kind
and name, and "Live sangat · always on · N cities". Down the left side, the
last three people who joined (LS8). At the foot: Join, or **Joined ·
listening** once you are in; the sound; and a sleep timer. Below them the
group as a sheet you pull up (LS9).

**LS6. The sound.** Opening the page starts the recording, looped without a
gap. Its position is the seconds since 00:00 IST modulo the clip's length, so
every phone is at the same second. It plays on with the screen locked, like a
recitation, and stops when you leave the page, press pause or the sleep
timer runs out. It needs no connection.

**LS7. Listening count** (`liveListening`): people who had a live group's
page playing in the last ten minutes, counted by the server (§8) and shown
as a number, never as names. "N cities" is how many cities they are in.
With no connection the page plays, and the count and cities say they are
waiting.

**LS8. Joined from.** When somebody with a profile joins a live group, the
page shows "{first name} {initial}. joined from {city}" for a short while, as
the quiz leaderboards show a name (`14-quiz.md`). Somebody without a profile
joins without being shown.

**LS9. The group** (design 128): this month's goal of minutes as a ring
("212,480 of 500,000 min", the days left), three figures (the sangat today,
yours today, yours this month) and the members, A to Z. The goal is set by
the owner once a month and starts again on the 1st.

**LS10. Sitting** (design 129, option D): Sit starts a timed sitting with
the group's recording. The controls go, the scene dims a little, and the
countdown sits under it with live today and here today either side
(`07-simran.md` CT3), with Pause and End. A sitting is counted exactly as a
Naam Simran sitting is: in `simran_sessions`, toward hazri and toward a Naam
Simran goal item (`04-goals.md`). Listening without Sit counts toward
nothing.

**LS11. Joining and leaving.** Join needs a profile, as joining a built-in
group does. Leave is in the page's ⋮ menu with a confirmation, as for a
built-in group (`08-sangat.md` VS2). Listening needs neither: anybody can
open a live group and hear it.

## 5. The scenes

**LS12. Drawn by the app, not played as video**, as the globe on the Simran
tab is. Each loops every 30 seconds and breathes every 6, matched to its
recording's rhythm when the clips arrive. With Android's battery saver on, or
with reduced motion, a scene is a still frame. The globe draws the same
coastlines and borders as `assets/geo/world.bin`.

**LS13. Words in a scene come from where they always do.** ਵਾਹਿਗੁਰੂ is
`simranWaheguru` in the ARB files; ੴ is `ikOnkarProvider` from `content.db`.
Neither is typed into Dart (CLAUDE.md rule 3).

**LS14. No face is drawn**: the scenes have no people in them at all.

## 6. Strings

| Key | English |
|---|---|
| `sangatTabDiscover` | Discover |
| `sangatTabMine` | My groups · {count} |
| `liveTag` | LIVE |
| `liveListening` | {count} listening |
| `liveCities` | Live sangat · always on · {count} cities |
| `liveJoinedFrom` | {name} joined from {city} |
| `liveJoinedListening` | Joined · listening |
| `liveSwipeUp` | Swipe up for the group |
| `liveYouAreIn` | Live, you are in |
| `liveListen` | Listen |
| `liveWaiting` | Waiting for the sangat… |
| `liveKindMeditation` | Meditation |
| `liveKindJaap` | Jaap |

The three names are proper nouns by script, as the badge names are.

## 7. Building it

At build time, in this order, each in the same commit as its test:

1. The two tabs and their default (LS2-LS4a), with no live groups yet.
2. The live page with its bundled recording and clock position (LS5, LS6),
   offline.
3. The scenes (LS12-LS14).
4. The server side: the listening count and the join feed (§8), the
   privacy screen and PRD §8 in the same commit.
5. Sitting (LS10).

`docs/ARCHITECTURE.md` gets the collections and endpoints of §8 at step 4.

## 8. Privacy and cost

**LS15. What it sends**, a new line on PRD §8's closed list, shipped with the
rewritten privacy screen: while a live group's page plays, with a profile, a
**listening mark** every five minutes (the group and nothing else; the city
is the profile's). Joining a live group sends what joining a built-in group
sends. Without a profile nothing is sent and you are not counted.

**LS16. Counted by the server, never by a client**, as the Sangat totals are
(`08-sangat.md`): marks are written to shards and the counts rebuilt at most
every two minutes, so a thousand listeners cost about 300,000 writes a day,
well inside the spend cap. `maxInstances` stays 10.

## 9. Scenarios

**S-1 · A new person opens Sangat.** Given no profile and no group, when the
Sangat tab opens, then it shows Discover with the three live cards first.

**S-2 · A member opens Sangat.** Given you are in Gill Parivar, when the tab
opens, then it shows My groups, with Create group and Join group at the top.

**S-3 · Same second on two phones.** Given two phones with the right time,
when both open Naam Simran, then both play the same second of the recording.

**S-4 · Offline.** Given no connection, when Naam Simran opens, then the
recording plays and the scene turns, and the count says it is waiting.

**S-5 · Joined from.** Given Harpreet Kaur of Ludhiana with a profile, when
she joins Mool Mantar, then others on its page see "Harpreet K. joined from
Ludhiana".

**S-6 · Without a profile.** Given no profile, when somebody listens to
Chaupai Sahib, then nothing is sent, they are not counted, and Join asks them
to make a profile.

**S-7 · Sit counts as simran.** Given a Naam Simran goal of 11 minutes, when
somebody sits 11 minutes in the live Naam Simran group, then the goal item is
met and hazri is marked.

**S-8 · Listening is not sitting.** Given somebody listens for an hour without
Sit, then no simran session, hazri or goal is recorded.

**S-9 · Battery saver.** Given battery saver on, when a live page opens, then
the scene is still and the recording plays.

## 10. Open decisions

| # | Question | Default |
|---|---|---|
| LS-1 | The three recordings | The owner supplies them; nothing ships without them |
| LS-2 | Count listeners without a profile, without a city | No: with a profile only, as attendance is |
| LS-3 | A switch to hide yourself from "joined from" | None, as on the quiz boards; revisit before release |
| LS-4 | The monthly goal of each live group | 500,000 minutes, set by the owner in the admin website |
| LS-5 | Punjabi and Hindi for the strings | Claude's draft, to be checked |

## 11. Acceptance

- The Sangat tab opens on the right tab for a member and for somebody in no group.
- All three live groups play offline from the APK, at the same second on two phones.
- The counts are real, from the server, and nothing is sent without a profile.
- The privacy screen and PRD §8 list the listening mark in the release that sends it.
- `flutter analyze` clean and `flutter test` passing, with S-1 to S-9 as tests.
