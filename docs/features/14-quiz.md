# 14 · The Gurmat Quiz

Written 2026-10-27 with the owner, after six rounds of design between
2026-10-26 and 2026-10-27 (the round-6 page is the record of what was chosen;
the screens are numbered designs 113-119, drawn by
`tools/design/build_phase2.py`). The questions are the owner's bank, `Hazri_Sikh_Quiz_Question_Bank.xlsx`:
340 questions, twenty to a topic, seventeen topics.

This is the first feature in Hazri with points and a ranking. PRD §1.3 was
amended for it on the same day, and only for it (§2, QZ1).

---

## 1. Purpose

A short quiz on Sikh history and practice, offered by the day of the Sikh
calendar, that a family can take together and compare: five questions, ten
points for each right answer for somebody with a profile, and a leaderboard
for each quiz, today, this week and this month.

## 2. What it is not

**QZ1. Points are for knowledge, never for Gurbani practice.** The quiz is the
only place in the app with points or a ranking. Reading, listening, Simran,
hazri, goals, the streak, badges, the Sangat and saakhis stay uncounted and
unranked exactly as before (PRD §1.3). A quiz is not a Diary row, does not
mark hazri, is not a goal item, counts toward no badge and raises no
notification.

**QZ2. A question is never Gurbani.** No question or explanation quotes a line
of Gurbani; the bank has none today, and the pipeline fails on Gurmukhi in a
question, an option or an explanation. A question that needs a pankti waits
until the rules for one are written, as a saakhi's shabad's were
(`13-saakhi.md` SK3).

**QZ3. The quiz has no Guru's face.** The Gurus category's drawing is the
figure with light where the face would be, as on a saakhi (`13-saakhi.md`
SK2).

## 3. Content

**QZ4. Every question comes from the owner's bank.** Nothing is typed into
Dart and nothing is generated. `tools/content_pipeline/import_quiz.py` turns
the spreadsheet into `content/source/quiz/`, which is what git holds and what
the pipeline reads:

| File | Holds |
|---|---|
| `topics.json` | The seventeen topics: `id`, `category`, `sort`, the name in en, pa and hi, the row's glyph, and the Vichar page (`slug`) Know more opens on a day with no event |
| `<topic-id>.json` | That topic's questions: `id` (the bank's, `Q1` to `Q340`), `difficulty` (`easy`, `medium`, `hard`), the question, four options in the bank's order, the answer, the explanation, the source and its URLs, the reviewer's note, `retired`, and `since`, the content version that first shipped it |
| `days.json` | Calendar events that have a quiz: the event's exact English name in `calendar-558.json`, a short label for the card in en, pa and hi ("Prakash Purab", "Bandi Chhor Divas"), its topic, and its Vichar page |

`build_content_db.py` checks every reference (a topic in `days.json` exists,
an event name is in the calendar, a slug is in `tools/site/articles/`, an
answer is one of the four) and fails on any miss. It writes the tables of
ARCHITECTURE §3.2 into `content.db` and the same questions, with their
answers, into `functions/src/quiz-bank.json`, the way the Vichar library is
bundled with the `api` Function.

**QZ5. Question ids are never reused.** A corrected question keeps its id; a
withdrawn one is marked `retired` and is never drawn again. A new
spreadsheet is imported in full and must keep every existing id.

**QZ6. The questions are in English** in every app language until reviewed
Punjabi and Hindi exist (owner, 2026-10-26). Everything around them (labels,
buttons, the result, the boards) is in the ARB files in all three languages
(CLAUDE.md rule 5). Topic names are in all three, from `topics.json`.

**QZ7. The bank's notes and sources are never shown on the quiz.** They are
for review. The answer screen shows the explanation alone (owner, 2026-10-26:
"remove the source section"). The bank is credited once in About and
credits (`source` row `QUIZBANK`, naming its main references), not question
by question.

### 3.1 Topics and categories

Five categories, in this order, with an **All** chip before them (owner,
2026-10-27):

| Category | Topics | Quizzes |
|---|---|---|
| Gurus | The ten Gurus, then Sri Guru Granth Sahib Ji | 11 |
| Gurdwaras | Five Takhts, Historic Gurdwaras | 2 |
| Banis | Sikh Banis | 1 |
| Heroes | Sikh Heroes, Sikh History | 2 |
| Culture | Sikh Culture and Practices | 1 |

A Guru's row carries the Gurmukhi numeral (੧ to ੧੦), Sri Guru Granth Sahib
Ji's ੴ; the other topics carry their category's drawing.

## 4. Today's quiz

**QZ8. One topic a day, the same for everybody on that date.** The phone
decides it from `content.db` with no network, by the local date:

1. the day's calendar events that `days.json` maps to a topic, those mapped
   to a topic in the Gurus category first, then the calendar's order; the
   first one wins;
2. otherwise the topics in their `sort` order, by days since 1970-01-01
   modulo the number of topics (as ਅੱਜ ਦਾ ਵਿਚਾਰ picks its line).

**QZ9. Today has two quiz cards**, both after the Nitnem button and before
the Saakhis card (owner, 2026-10-26: "above saakhis"), both in elder mode too,
at elder sizes (owner, 2026-10-27).

*The calendar leaf* (design 1A): the weekday, the day and the month, the
Nanakshahi day and month, then the event's short label from `days.json` as the
eyebrow (or **Did you know?** on a day without one), the topic's name and one
insight. **It has no buttons** (owner, 2026-10-28: "this card is fine without
a button").

*The quiz card* (design D, owner 2026-10-28, from four options drawn at
<https://claude.ai/artifact/JcMB8TS6bEBCDnY6trRXKL>): **Gurmat Quiz** with,
with a profile, your points (or **+N today** once you have earned some today)
and **All quizzes**, which opens the quiz page; then today's topic as a
highlighted tile, its mark, **Today**, its name, "5 questions · 10 points
each" (without a profile "5 questions · plays on this phone") and **Start**;
then **Or pick another** and the other categories as drawn tiles (the five
that are not today's topic's, then All), each opening the quiz page on that
category. Nothing on it fetches: the points are those the phone already holds
(`quiz_me_v1`, ARCHITECTURE §3.9.4), so Today still costs no read.

**QZ10. The insight is the explanation of one of the topic's questions,
word for word**, never written for the card. It is chosen by the date from
the topic's easy questions that carry no reviewer's note, in id order.

**QZ11. Know more is the calendar leaf itself, on a day with an event**
(owner, 2026-10-28): when the day's event in `days.json` names a Vichar page,
a tap anywhere on the leaf opens it (`/library/<slug>`, design 107) and a small
arrow beside the eyebrow says so. On a day with no event the leaf is still: a
tap on it does nothing. (Until 2026-10-28 it was a Know more button, shown on
every day with a page, the topic's on a day with no event.)

**QZ12. Start goes straight into the first question** (owner, 2026-10-26),
with no intermediate screen.

## 5. A quiz

**QZ13. Five questions, drawn new every time** (owner, 2026-10-27): two easy,
two medium and one hard from the topic's twenty, in that order. A topic short
of one difficulty fills the place from the next harder one, then the next
easier one. Questions the player saw in their last two attempts at the topic
are avoided while the topic has enough others; the difficulty matters more
than freshness, so a recent question of the right difficulty is taken before
a fresh one of another.

**QZ14. With a profile, the server draws them** when the player presses
Start (`POST /quiz/sessions`, ARCHITECTURE §6.7), so a session is the
server's and is scored by the server's own answer key. The phone shows the
questions from `content.db` by id; nothing but the ids, the session and
later the five choices travel. **Without a profile nothing is sent at all**
(owner, 2026-10-27): the phone draws the five itself by QZ13's rule,
avoiding the questions of the last two attempts it remembers, and the quiz
runs exactly the same, without points (QZ31).

**QZ15. Each answer is marked at once on the phone:** the right option in
green, a wrong choice in red with the right one in green, then the
explanation under **Right** or **The answer is {answer}**, and only then
**Next question** (on the fifth, **See your result**); there is no button
before an answer. The screen is design A of round 8 (owner, 2026-10-28, from
four drawn at <https://claude.ai/artifact/5km4WFCna3yGmLRDHw6iWp>, design
114): the question on a navy stage with the topic's mark, five bars that turn
green or red as each answer is marked, "Question n of 5", the level and,
when the quiz can earn them, "10 points"; the options as white cards over the
stage's foot, each with a saffron letter. Options are
shown in the bank's order, because two of them say "both of the above".
There is no timer and no hint.

**QZ16. Without a connection the quiz still works, without points.** If a
profile's session cannot be started within 5 seconds, the phone draws the
five itself (QZ14) and the quiz runs the same; the result says **Points need
a connection** instead of the points. Nothing is queued to send later.

**QZ17. Leaving a quiz part-way loses it.** Closing it asks
"Leave the quiz? This quiz won't count." with **Keep going** and **Leave**.
An unsubmitted session expires after 30 minutes.

## 6. Points

**QZ18. Ten points for each right answer, with a profile**, so a quiz is
worth 0 to 50 (owner, 2026-10-26 and 2026-10-27). The server adds them up from the five choices
(`POST /quiz/sessions/{id}/answers`); a score from the phone is never
trusted (ARCHITECTURE §10.1 M3).

**QZ19. Every attempt earns points** (owner, 2026-10-27), for the player's
own total: the quiz page's total, each topic's "pts so far", and Your
numbers. A replay is a new set of five.

**QZ20. A leaderboard counts each player's best attempt at a topic on a day**
(owner, 2026-10-27), so replaying a quiz thirty times cannot outrank a player
who knew the answers. A topic's board for a day is that best; for a week or a
month, the sum of those daily bests; the Everyone board, the sum over every
topic. A player who improves their best moves up by the difference. The
day's first attempt at a topic is recorded even at 0, so the player counts
as having played (QZ28).

**QZ21. Days, weeks and months are IST**, as the Sangat's are: a day ends at
midnight IST, a week runs Monday to Sunday, a month is the calendar month.
The board says "resets at midnight IST".

**QZ22. Limits** (owner, 2026-10-27). At most 30 sessions per player per IST day; one
submission per session; a session submitted less than 10 seconds after it
started, or more than 30 minutes after, is refused and earns nothing. The
app says **You've taken a lot of quizzes today. Come back tomorrow.** when
the daily limit is reached, and offers the offline quiz (QZ16).

## 7. The result

**QZ23. The result is design 4B** (owner, 2026-10-26 and 2026-10-27): the
score out of 5 and **+N points** (without a profile, no points line, QZ31),
the topic, the five questions as one line
each with ✓ or ✕ (each opens that question's answer screen again), then the
share card, then **See the leaderboard · you are Nth** as the main button,
and **Done**.

**QZ24. The share card** reads **Can your family beat {score} out of 5?** and,
on an event day of a Guru's topic, **On {topic}'s {label}, share the quiz and
learn the story together.** (otherwise **Share the quiz and learn
together.**), with **Share the quiz** highlighted. Share makes a 1080 × 1920 image, built like a saakhi
page's (`13-saakhi.md` SK10): the topic, the score, the challenge line, and
a band "Take the same quiz · Free in the Hazri app" with the link
`https://hazri-dfcc1.web.app/q/<topic-id>`. It goes out through Android's
share sheet; the app itself sends nothing.

**QZ25. The link opens that topic's quiz** on a phone with Hazri (an App Link,
like `/j/<code>`), straight into its first question once setup is done
(`03-first-run.md` F7 holds it until then); on a phone without it, a page on
the website that names the quiz and points to the app.

**QZ26. The leaderboard button names the player's place on today's board for
that topic.** Without a profile it reads **See the leaderboard**, and above
the share card a line says **Make a profile to earn points and join the
leaderboard**, opening Profile setup. Offline (QZ16) the button is not
shown.

## 8. The leaderboards

**QZ27. Everyone with a profile is on the boards** (owner, 2026-10-26: "All
users will be in by default"). There is no opt-in and no switch. A player
without a profile has no points and is never listed (QZ31).

**QZ28. A board is the top twenty** (owner, 2026-10-26), design 5A: chips for
**Today**, **Week** and **Month**, then chips for **Everyone** and each
topic (today's topic first); each row the place, initials, the first name
and the surname's initial ("Manpreet S."), the city, and the points. The
player's own row is highlighted as **You**, and shown below the twenty with
its place when it is not among them. Under the list: "Top 20 · {n} played
today · resets at midnight IST". Equal points share a place; within it, who
reached the score first is listed first.

**QZ28a. An empty board points to the next one** (owner, 2026-10-28: a quiz
taken yesterday was nowhere on the board). The board opens on Today, and
Today's starts empty at midnight IST, so an earlier quiz is only on the
week's and the month's. An empty Today board says "Nobody has played this
one today yet. Today's board starts again at midnight IST; earlier quizzes
are on the week's and the month's." with **See this week**; an empty Week
board says so with **See this month**; an empty Month board says "Nobody has
scored yet. Be the first."

**QZ29. Without a profile the board is design 5B**: the same board, with a
card above it, **Make a profile to be on the leaderboard**, "Your quiz points
count from the day you make one. Just a name and your city.", and **Make a
profile**, which opens Profile setup. Fetching a board needs no profile and
sends nothing about the player.

**QZ30. A board is never more than two minutes old** and is built by the
server, at most every two minutes, only when somebody looks (ARCHITECTURE
§6.7), as a group's globe is. Opening a board costs one read for the board,
whoever opens it, and one more with a `count()` for the player's own place. A board that cannot be fetched shows the last copy with "Not updated ·
no connection", or, with none, "The leaderboard needs a connection."

**QZ31. Points start with a profile** (owner, 2026-10-27: "lets not record
any point if there is no profile"). Quizzes taken before one is made earn
nothing, are not sent and are not carried over; the first quiz after it is
the first that counts. A profile's name or city change reaches its rows on
the current boards at once.

**QZ32. Restoring a profile on a new phone keeps its points**, because they
belong to the profile, not the install.

## 9. The Gurmat Quiz page

**QZ33. The menu gains Gurmat Quiz**, after Saakhis, opening the quiz page.
The page is design 6A:

1. the header "Gurmat Quiz" with the player's total points (without a
   profile, **Make a profile to earn points** in its place);
2. **Coming up on the calendar**: today's topic first with **Start**, then the
   next two dates in the next 30 days that `days.json` maps, each with its
   date, topic and event;
3. **Featured categories**: All, Gurus, Gurdwaras, Banis, Heroes, Culture, as
   rounded saffron tiles with their drawings, the chosen one outlined;
4. the chosen category's quizzes, each a row with its glyph, its name, a
   **Today** or date chip where one applies, "5 random questions · {n} pts so
   far" ("5 random questions" alone without a profile), and **Start**.

The header's points open Your numbers, and so does a **Your quiz** row under
Coming up (with a profile: the points and today's place); a board icon in the
header opens the leaderboard.

**QZ34. Your numbers is design 7A**: a navy card with the initials, the name
and city, the total points, and the player's place today, this week and this
month on the Everyone board; then the month as a calendar, each day with the
points earned that day, and the month's total. Without a profile the screen
is the Make a profile card (QZ29) alone.

**QZ35. Your numbers and the quiz page's points come from the server** (`GET
/quiz/me`, with a profile only), fetched when either opens and after each
result; the last answer
is kept on the phone, so both open offline with the last numbers.

## 10. Building it

**Built 2026-10-27**, all six steps: content version 10, the Functions with
their unit and emulator tests, the app, and designs 113-119. **Deployed by
hand on 2026-10-27:** the Functions, the two `quizScores` indexes and the
three TTL policies on `deleteAt` (the owner's first quiz with a profile
earned +30 points and first place). The `/q/` page goes live with the next
`firebase deploy --only hosting:public` (PRD §11.5); until it does, a shared
link opens the website's 404 rather than the quiz.

1. This file, ARCHITECTURE §3.2, §5.13, §6.7, PRD §1.3, §4.21, §8.
2. The importer and the pipeline: the spreadsheet to `content/source/quiz/`,
   `content.db` (content version 10) and `functions/src/quiz-bank.json`.
3. The Functions: sessions, scoring, scores, boards, `/quiz/me`, the name
   and city sync; emulator tests for each.
4. The app: the Today card, the quiz, the result, the boards, the quiz page,
   Your numbers, the menu row; **the privacy screen rewritten in the same
   change** (PRD §8.3).
5. The share image, `/q/<topic>` in the manifest and on the website.
6. Designs 1A, the quiz, 4B, 5A, 5B, 6A and 7A in `build_phase2.py` as
   113 (Today), 114 (a question), 115 (4B), 116 (5A), 117 (5B), 118 (6A)
   and 119 (7A), the canvas republished.

## 11. Scenarios

**Today on a Gurpurab.** Given 27 October 2026, Prakash Purab of Sri Guru Ram
Das Sahib Ji, mapped to the topic Guru Ram Das Ji, when Today opens, then the
card shows TUE 27 OCT, 11 Katak, "Prakash Purab", "Guru Ram Das Ji", an
explanation from that topic word for word, an arrow and no button; a tap on
the card opens the Prakash Purab's Vichar page. The quiz card below shows
Guru Ram Das Ji with Start, and Gurdwaras, Banis, Heroes, Culture and All to
pick from, not Gurus.

**Today with no event.** Given a date with no mapped event, when Today opens,
then the card shows "Did you know?" and the topic QZ8 picks for that date,
with no arrow, and a tap on it does nothing; every phone shows the same topic
on that date.

**A category from Today.** Given the quiz card, when the player taps
Gurdwaras, then the quiz page opens with Gurdwaras chosen: Five Takhts and
Historic Gurdwaras.

**Two events.** Given 14 December 2026, with Shaheedi Purab of Sri Guru Tegh
Bahadur Sahib Ji and a Sahibzada's birth anniversary, when Today opens, then
the topic is Guru Tegh Bahadur Ji.

**Know more.** Given the Gurpurab card, when Know more is tapped, then the
Vichar page for Prakash Purab of Sri Guru Ram Das Ji opens.

**Five new questions.** Given a player who has just finished Guru Ram Das Ji,
when they start it again, then five questions are drawn again, two easy, two
medium and one hard, avoiding the five just seen.

**Right and wrong.** Given a question whose answer is C, when the player taps
B, then B turns red, C green, the explanation shows, and no source is shown.

**Points on a replay.** Given a player who scored 30 and then 40 on Guru Ram
Das Ji today, then their total rose by 70, and today's Guru Ram Das Ji board
and today's Everyone board count them at 40.

**A lower replay.** Given a best of 40 today on a topic, when the player
scores 20 on it, then their total rises by 20 and no board changes.

**Offline.** Given no connection, when the player taps Start, then
five questions show within the 5-second limit, the quiz runs, and the
result says "Points need a connection" with no leaderboard button.

**Without a profile.** Given a player without a profile, when they take a
quiz and get 4 right, then no request is made, the result shows 4 out of 5
with no points line and the Make a profile line, and when they open the
leaderboard the Make a profile card is above the rows and they are not
among them.

**Making a profile.** Given that player, when they make a profile and take
the same quiz again, then only the new quiz's points count, and they appear
on today's boards under their first name, surname initial and city.

**Top twenty.** Given 312 players today and the player 34th, when the board
opens, then it lists 20 rows, then the player's own row with 34, and "Top 20
· 312 played today".

**Shared link.** Given a link to `/q/guru-ram-das-ji`, when it is opened on a
phone with Hazri set up, then the Guru Ram Das Ji quiz starts at its first
question.

**Failure: a forged score.** Given a client that submits a session's five
choices claiming 50 points, then the server scores the choices with its own
key and records what they earn.

**Failure: a replayed submission.** Given a session already submitted, when
it is submitted again, then the server answers with the first result and
records nothing more.

**Failure: too fast.** Given a session submitted 4 seconds after it started,
then it is refused with `SESSION_TOO_FAST` and earns nothing.

**Failure: the daily limit.** Given a player's 30th session today, when they
start a 31st, then the server answers `QUIZ_DAILY_LIMIT` and the app offers
the offline quiz.

**Failure: a session without a profile.** Given an install with no profile,
when anything calls `POST /quiz/sessions`, then the server answers `404
NO_PROFILE` and stores nothing.

**Failure: an unknown question.** Given an older app whose `content.db` lacks
a question the server would draw, then the server draws only from the bank
version the app sent (ARCHITECTURE §6.7), so every id it returns exists on
the phone.

**Failure: a broken reference.** Given `days.json` naming an event that is
not in the calendar, or a slug that is not a Vichar page, then
`build_content_db.py` fails.

**Failure: Gurbani in a question.** Given a question, option or explanation
with Gurmukhi text in it, then `build_content_db.py` fails (QZ2).

## 12. Open decisions

| # | Question | Default |
|---|---|---|
| QZ-1 | The 54 questions carrying a reviewer's note (traditions differ, a date disputed) | They ship; the notes stay out of the app (QZ7), and none is used as an insight (QZ10) |
| QZ-2 | `days.json`: which events map to which topic | **Closed**: Claude's draft, accepted by the owner on 2026-10-27 (each Guru's Prakash, Gurgaddi, Joti Jot and Shaheedi Purab to that Guru; Bandi Chhor Divas and Miri-Piri Divas to Guru Hargobind Sahib Ji; Vaisakhi to Guru Gobind Singh Ji; the two Gurgaddi and Sampuranta days of Sri Guru Granth Sahib Ji to it; the Sahibzade, the Shaheeds and the Ghallugharas to Sikh Heroes or Sikh History; the Akal Takht's and Harmandir Sahib's foundation days to the Five Takhts or Historic Gurdwaras) |
| QZ-3 | Punjabi and Hindi questions | English until a reviewed translation exists (QZ6) |
| QZ-4 | A way to stay off the boards with a profile | **Closed**: none; everybody with a profile is listed (owner, 2026-10-26, confirmed 2026-10-27). The privacy screen says so plainly |
| QZ-5 | Your total (every attempt) and a board's score (best per topic per day) are different numbers | **Closed**: as written (owner, 2026-10-27) |
| QZ-8 | Points without a profile | **Closed**: none, and nothing is sent; points start with a profile (owner, 2026-10-27) |
| QZ-6 | The quiz in elder mode | **Closed**: on Today in elder mode too, with the Saakhis row (owner, 2026-10-27) |
| QZ-7 | The topic for a player abroad | **Closed**: by the phone's date, so a Gurpurab's quiz is on its day there; the boards still turn at midnight IST (owner, 2026-10-27) |

## 13. Acceptance

- Unit: QZ8 for an event day, a no-event day, two events, and the year's
  edges; QZ10's choice; QZ13's draw for a topic short of hard questions.
- Pipeline: the reference checks of QZ4 and QZ2 seen failing.
- Emulator: a session and its submission (QZ14, QZ18); a submission twice; a
  forged score; too fast, too late, the 31st session; no profile; QZ20's best
  per topic per day across two attempts; the board's two-minute rebuild; a
  name change reaching today's board.
- Widget: the Today card in each state (event, no event, no Know more, elder
  mode); a question answered right and wrong with no source; the result
  offline and without a profile, with no request made; the board with and
  without a profile; the quiz page's chips.
- `l10n_test` passes with every new string in pa, hi and en.
- Storage: ARCHITECTURE §3.2 (`quiz_topic`, `quiz_question`, `quiz_day`),
  §3.9.4 (`quiz_me_v1`, `quiz_boards_v1`), §5.13 (`quizSessions`,
  `quizPlayers`, `quizScores`, `quizBoards`), §6.7 (the endpoints).
