# 15 · Live sangat

Written 2026-11-18 with the owner, after five rounds of design between
2026-11-17 and 2026-11-18. The screens are designs 125-129, drawn by
`tools/design/build_phase2.py`; the three scenes are
`tools/design/live_scenes.js`. **Built 2026-11-18**, once the owner's
recordings arrived: `lib/features/live/` (the scenes ported to
`live_scene.dart`), `functions/src/routes/live.ts`, the loops in
`assets/live/` from `tools/live/build_loops.py`, and the privacy change of
§8 in the same release.

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
| Naam Simran | Meditation | the owner's ਵਾਹਿਗੁਰੂ recording (`Waheguru_Naam_Simran.mp3`), 0-59 s, looped at 56 s | **The globe**: the world turning, a thread of light from every city with a listener up to ਵਾਹਿਗੁਰੂ |
| Mool Mantar | Meditation | the owner's Mool Mantar recording (`Mool_Mantra_Final.mp3`), whole, looped at 128.65 s | **ੴ among the stars**: thirteen stars join into a circle round ੴ through the loop and let go |
| Chaupai Sahib | Jaap | the app's own Chaupai Sahib recitation (`assets/audio/chaupai-sahib.m4a`, owner 2026-11-18), 0.45-211 s, looped at 208.04 s | **The jot in the shield**: a diya's flame under a turning dome of light |

The recordings are the owner's, given to the app as files. None is generated,
paraphrased or made by a machine (CLAUDE.md rule 3), and none is fetched: they
ship in the APK under `assets/live/`.

**LS1b. The seam** (owner, 2026-11-18: "make some good transition while
repeating, so it feels natural"). Each loop is baked by
`tools/live/build_loops.py`: the recording's last seconds are crossfaded,
equal-power, into its first (3 s for Naam Simran, 4 s for Mool Mantar, 2.5 s
for Chaupai Sahib), and the file starts just after the faded-in part, so
playing it on repeat has no gap and no jump in level. The masters are not in
git (`audio/README.md`).

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
last three people who joined (LS8). At the foot: Join (nothing in its place
once you are in, owner 2026-11-19); the sound; and a sleep timer, the moon,
which stops the sound after 15, 30 or 60 minutes, a tap at a time. Below them the
group as a sheet you pull up (LS9).

**LS6. The sound.** Opening the page starts the recording, looped without a
gap. Its position is the seconds since 00:00 IST modulo the clip's length, so
every phone is at the same second. It plays on with the screen locked, like a
recitation, and stops when you leave the page, press pause or the sleep
timer runs out. It needs no connection.

**LS7. Listening count** (`liveListening`): people who had a live group's
page playing in the last **24 hours** (owner, 2026-11-19; it was ten
minutes), counted by the server (§8) and shown as a number, never as names.
Join and Leave show at once: they make the server count again on the next
read. "N cities" is how many cities they are in.
With no connection the page plays, and the count and cities say they are
waiting.

**LS7b. You are in the count at once** (owner, 2026-11-19). Opening a live
group puts you in its count on your own phone straight away: the server's
last count plus one, and your city if it is new, for 24 hours from when you
listened, with or without a profile and joined or not. Once the server's
count holds you (`youCounted`) the phone stops adding you, so you are never
counted twice. When you listened is kept on the phone (`live_heard_v1`) and
never sent.

**LS7a. Minutes listened** (owner, 2026-11-18). Every minute a live group's
page plays is counted, for you and for the sangat. Yours are counted on the
phone, a row per group per day in `user.db`, so they are exact and need no
connection. The sangat's are counted by the server from the listening marks
(§8), five minutes a mark, and shown for today and this month (IST). Minutes
listened are a figure to see, never a goal, a ranking, hazri or a badge.

**LS8. Joined from.** When somebody with a profile joins a live group, the
page shows "{first name} {initial}. joined from {city}" for a short while, as
the quiz leaderboards show a name (`14-quiz.md`). Everybody with a profile is
shown; there is no switch to hide (owner, 2026-11-18). Somebody without a
profile joins without being shown.

**LS9. The group** (design 128): **no goal** (owner, 2026-11-18: a live group
is always on and has nothing to reach). Instead, **minutes listened** (LS7a):
the sangat today and this month, large, then yours today and this month;
then the members, A to Z, each with their minutes this month.

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
| `liveSwipeUp` | Swipe up for the group |
| `liveYouAreIn` | Live, you are in |
| `liveListen` | Listen |
| `liveYouListened` | You listened {minutes} min today |
| `liveMinutesListened` | Minutes listened |
| `liveSangatToday` | The sangat today |
| `liveSangatMonth` | The sangat this month |
| `liveYoursToday` | Yours today |
| `liveYoursMonth` | Yours this month |
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

**S-8a · Minutes listened.** Given you listen to Naam Simran for 15 minutes
with the screen locked, when you open My groups, then it says you listened 15
min today, offline as well as online.

**S-9 · Battery saver.** Given battery saver on, when a live page opens, then
the scene is still and the recording plays.

## 10. Open decisions

| # | Question | Default |
|---|---|---|
| LS-1 | The three recordings | **Decided 2026-11-18**: two from the owner, and Chaupai Sahib from the app's own recitation (LS1, LS1b) |
| LS-5 | Punjabi and Hindi for the strings | Claude's draft; the owner will check |

**Decided 2026-11-18 (owner):** LS-2, listeners without a profile are not
counted; LS-3, everybody with a profile is shown in "joined from", with no
switch; LS-4, live groups have **no goal**: minutes listened are counted and
shown instead (LS7a, LS9).

## 11. Acceptance

- The Sangat tab opens on the right tab for a member and for somebody in no group.
- All three live groups play offline from the APK, at the same second on two phones.
- The counts are real, from the server, and nothing is sent without a profile.
- The privacy screen and PRD §8 list the listening mark in the release that sends it.
- `flutter analyze` clean and `flutter test` passing, with S-1 to S-9 as tests.
