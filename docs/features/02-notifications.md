# 2. Notifications

Rewritten 2026-10-07 with Puneet Singh Nanda. It replaces the earlier version
of this file. Its delivery lessons (the manifest receivers, the permission,
the diagnostics screen) are kept in Section 7, because they are why no
notification arrived for a fortnight.

**The messages in Section 5 are the approved text, in all three languages.**
They were reviewed as mock-ups on the page *Hazri Notification Messages*
(<https://claude.ai/artifact/8GXeFoM4WxidhEE6EAZxVx>, private to the owner).
Where that page and this file differ, this file wins. The Punjabi and Hindi
were written by the implementer and await the owner's check
(`01-accounts.md` §13.9).

## 0. Implementation directive (mandatory, read first)

1. **No inference.** Every notification, time, condition and word comes from this document.
2. **A closed list.** Hazri sends the five kinds in Section 3 and nothing else.
3. **Stop on ambiguity.** If anything required is missing or contradictory, stop and ask the developer.
4. **Local first.** Kinds 1 to 4 are scheduled on the phone and need no network, account or profile. Only kind 5 is pushed, through Firebase Cloud Messaging (Section 8).
5. **No Gurbani in a notification.** No line of Gurbani and no paraphrase of one. Bani and event names come from `content.db` in the reader's language; nothing is said about an event's history. No emoji.
6. **An invitation, never a reproach.** No "you missed", no broken streak, no member named in a sangat message.
7. **Strings are localised** in `pa`, `hi` and `en` (CLAUDE.md rule 5). The keys in Section 5 go into the ARB files.
8. **Done means tested.** Section 11 passes, `flutter analyze` is clean and `flutter test` passes.

## 1. Requirement traceability

| Req # | Requirement (owner, 2026-10-07) | Where |
| --- | --- | --- |
| N1 | Daily morning reminder at 04:00, seven messages | 3, 4.1, 5.1 |
| N2 | One reminder per goal bani at its own reminder time | 3, 4.2, 5.2 |
| N3 | A notification for every Gurpurab and Sikh event | 3, 4.3, 5.3 |
| N4 | With no goal, a nudge to do 5 minutes of Naam Simran to mark Hazri, seven messages | 3, 4.4, 5.4 |
| N5 | Sangat goal reminders | 3, 4.5, 5.5, 8 |
| N6 | Exact message text defined for each | 5 |
| N7 | Firebase triggers for sangat notifications | 8 |

## 2. Definitions

| Term | Meaning |
| --- | --- |
| Local notification | Scheduled on the phone with `flutter_local_notifications`; arrives with no network |
| Push | Sent by a Cloud Function through Firebase Cloud Messaging (FCM) |
| Phone time | The phone's own clock and time zone. **Every time in this document is phone time** (owner, 2026-10-07), except where a sangat rule says otherwise. |
| Rotation | Seven messages, one per weekday, Sunday first, so the same words never repeat within a week |
| Fallback | The rotation's Sunday message, sent instead of a weekday message whose data is missing (4.6) |
| Hazri, goal, goal item | As `04-goals.md` §2 |

## 3. What is sent, and when

| # | Kind | Time (phone) | Condition | At most | Sent by | Channel |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Amrit Vela | 04:00 | Every day | 1 a day | Phone | `amrit_vela` |
| 2 | Goal bani | Each goal item's `reminderTime` | Item in scope and not yet met that day | 1 per item a day, plus one snooze | Phone | `goal_reminders` |
| 3a | Gurpurab | 06:00 on the day | Event of kind `prakash`, `gurgaddi` or `joti-jot` that the calendar flags or the reader switched on | 1 per Gurpurab | Phone | `sikh_calendar` |
| 3b | Sikh event | 07:00 on the day | Any other flagged or switched-on event kind | 1 per event | Phone | `sikh_calendar` |
| 4 | Hazri nudge | 07:00 | No active goal **and** no Hazri yet today | 1 a day | Phone | `hazri_nudge` |
| 5 | Sangat | 21:00, each member's own time | Member of a group with an active goal | See 4.5 | FCM | `sangat` |

There is **no daily cap** (owner, 2026-10-07): each kind sends at most its own allowance. Two Gurpurabs on one day are two notifications at 06:00; a Gurpurab and an event are one at 06:00 and one at 07:00. Shaheedi Purabs, including those of the Guru Sahibs, are kind `shaheedi` in the calendar and therefore come at 07:00 as events (owner, 2026-10-07).

## 4. Rules

### 4.1 Amrit Vela

- **AV1.** 04:00 every day, for everybody.
- **AV2.** The message is the rotation of 5.1 for that weekday.
- **AV3.** Tap or "Open {bani}" opens the reader on the first goal bani in scope that day, else Japji Sahib. "Start Nitnem" opens Nitnem. `{bani}` is that bani's name.
- **AV4.** With a profile, the expanded notification may carry the app's sunrise-arc picture with `{city}` (the profile city) and `{sunrise}` (from `SolarService`). Without a profile there is no city and no picture (`03-first-run.md` CY3). The text alone is complete without it.

### 4.2 Goal bani

- **GR1.** One notification per goal item, at its `reminderTime`, on each day the item is in scope (`04-goals.md` §4.8). Since 2026-10-19 every item has one, at the paath's own time (Naam Simran 05:30, Japji 06:00 … Kirtan Sohila 19:00), and it cannot be switched off (`04-goals.md` RM1).
- **GR2.** Not sent on a day the item is already met; it is cancelled as soon as it is met (`04-goals.md` RM3).
- **GR3.** "In 15 min" re-sends the same notification once, 15 minutes later, without the snooze button. No second snooze.
- **GR4.** A bani item uses message 5.2-A, a simran item 5.2-B. Tap opens the reader on that bani, or the Simran screen with the goal's minutes.

### 4.3 Gurpurab and Sikh events

- **CE1.** Events come from `content.db` (`calendar_event`); one is sent when `default_remind` is set, or the reader's own per-event switch says so.
- **CE2.** Kinds `prakash`, `gurgaddi`, `joti-jot` are Gurpurabs at 06:00; every other kind is an event at 07:00, on the event's date.
- **CE3.** Wording by kind (5.3): `prakash` and `gurgaddi` use the celebration text; `joti-jot` and `shaheedi` use the remembrance text; every other kind uses the plain event text. Never "Happy".
- **CE4.** `{event}` is the event's name in the reader's language. When that name is missing the English name is used and nothing is machine-translated. Only 10 of 147 events have a Punjabi name and none has Hindi; filling them in is content work, not code.
- **CE5.** Tap opens the calendar on that day. When the calendar has no data for a date (after 13 Mar 2027 until Nanakshahi 559 is added), nothing is sent.

### 4.4 Hazri nudge

- **HN1.** 07:00, only when there is no active goal and no Hazri has been marked yet today. Somebody who read Nitnem at 05:00 gets nothing.
- **HN2.** The message is the rotation of 5.4 for that weekday.
- **HN3.** Cancelled as soon as Hazri is marked, and never sent while a goal is active (goal reminders cover those days).
- **HN4.** Tap or "Begin 5 min" opens the Simran screen; "Begin 5 min" also starts the 5-minute sitting. "Set a goal" opens Add Goal with Naam Simran chosen.

### 4.5 Sangat

- **SG1.** Only to members of a group with an active group goal (or, for SG8, one that has just ended), on a phone with a profile and an FCM token (8.1).
- **SG2.** **Daily digest** at 21:00 in each member's own time zone, saying what the group did that day (5.5-A). Not sent on a day the group recorded no paath, because a zero would read as a reproach.
- **SG3.** **Milestones** when the group passes 25, 50 and 75 percent of its target (5.5-B), and **completion** at 100 percent (5.5-D). Each is sent once per goal. A milestone reached between 21:00 and 07:00 of a member's own time waits for 07:00.
- **SG4.** **Final days**: on the last two days of a goal not yet complete, the digest uses 5.5-C instead of 5.5-A.
- **SG5.** Never says who has not taken part. The only message naming a member is 5.5-E, which tells a creator who joined.
- **SG6.** The group goal itself (what is counted, when "today" ends for a group) is defined by `08-sangat.md`. "Today" for a group is the IST day (`08-sangat.md` CT9).
- **SG7. New members** (added 2026-10-07): once a day at 20:00 in the creator's own time, the creator of a custom group gets 5.5-E for the people who joined since the last one. Not sent on a day nobody joined. Built-in groups send none.
- **SG8. Group ended** (added 2026-10-07): when a custom group becomes inactive by its end date, every member gets 5.5-F at their next 21:00, instead of that day's digest. A group that met its target gets 5.5-D instead.
- **SG9. Simran goals:** where a message says `{bani}`, a Naam Simran goal uses `notifSangatSimranUnit` instead. A Simran goal counts minutes (`08-sangat.md` SG-1, 2026-10-09), so the digest and the final-days body, which say "paath", use their `...Simran` variants.

### 4.6 Rules for every local notification

- **CM1. Fallback.** A weekday message that needs data the app does not have when it plans the notification (a profile name, a streak, a live count, a profile) is replaced by the Sunday message of that rotation.
- **CM2. Planning.** `ReminderScheduler.reschedule()` plans every local notification for the next 7 days, nearest first, within the existing cap of 60 pending. It runs at app start, on resume, after every completion, sitting, Diary edit and goal change, after a time-zone or clock change, and from the boot receiver.
- **CM3. Data filled at planning.** Text is fixed when a notification is planned. A weekday message that needs data is used only when planned within 24 hours of firing; further ahead it is planned as the fallback and re-planned later.
- **CM4. Streak.** The streak in 5.1 Wednesday is the hazri streak (`09-diary.md` D9, D12) through the day before the notification. If that day's hazri is not yet marked when planning, the fallback is used. (Owner, 2026-10-10: the streak counts hazri, and the message says Hazri, not Nitnem.)
- **CM5. During a sitting.** A notification due while a Simran sitting is running is moved to the moment the sitting ends.
- **CM6. Language.** Text is in the app's language at planning time; changing the language re-plans.
- **CM7. Switches.** Each kind can be switched off on the Notifications screen. All are on by default, except Sangat, which is on only for members.

## 5. Messages

`{name}` is the profile name; `{city}` is the profile city and `{sunrise}` comes from it through `SolarService`; `{bani}`, `{event}` from `content.db`; `{weekday}` is the day's name in the app's language; numbers are formatted for the language. The example values on the review page (Harpreet, New Delhi, 06:22, 312, 12) are not part of the text.

### 5.1 Amrit Vela (04:00)

| Day | Key | When | English | ਪੰਜਾਬੀ | हिन्दी |
| --- | --- | --- | --- | --- | --- |
| Sun | `notifAv1` | Always; also the fallback | **Amrit Vela** / The quietest hour of the day is here. {bani} is ready when you are. | **ਅੰਮ੍ਰਿਤ ਵੇਲਾ** / ਦਿਨ ਦਾ ਸਭ ਤੋਂ ਸ਼ਾਂਤ ਸਮਾਂ ਆ ਗਿਆ ਹੈ। ਜਦੋਂ ਤੁਸੀਂ ਤਿਆਰ ਹੋਵੋ, {bani} ਖੁੱਲ੍ਹਾ ਹੈ। | **अमृत वेला** / दिन का सबसे शांत समय आ गया है। जब आप तैयार हों, {bani} खुला है। |
| Mon | `notifAv2` | Profile name known | **Good morning, {name}** / Sunrise in {city} is at {sunrise}. Your Nitnem is ready. | **ਸ਼ੁਭ ਸਵੇਰ, {name}** / {city} ਵਿੱਚ ਸੂਰਜ {sunrise} ਵਜੇ ਚੜ੍ਹੇਗਾ। ਤੁਹਾਡਾ ਨਿਤਨੇਮ ਤਿਆਰ ਹੈ। | **सुप्रभात, {name}** / {city} में सूर्योदय {sunrise} बजे है। आपका नितनेम तैयार है। |
| Tue | `notifAv3` | Always | **The sangat is waking up** / Mark your Hazri with Sangat. Begin now. | **ਸੰਗਤ ਜਾਗ ਰਹੀ ਹੈ** / ਸੰਗਤ ਨਾਲ ਆਪਣੀ ਹਾਜ਼ਰੀ ਲਗਾਓ। ਹੁਣੇ ਸ਼ੁਰੂ ਕਰੋ। | **संगत जाग रही है** / संगत के साथ अपनी हाज़री लगाएँ। अभी शुरू करें। |
| Wed | `notifAv4` | Streak of 3 or more (CM4) | **Day {streak} of your Hazri** / {streak} days in a row. Today's is waiting. | **ਤੁਹਾਡੀ ਹਾਜ਼ਰੀ ਦਾ ਦਿਨ {streak}** / ਲਗਾਤਾਰ {streak} ਦਿਨ। ਅੱਜ ਦੀ ਉਡੀਕ ਹੈ। | **आपकी हाज़िरी का दिन {streak}** / लगातार {streak} दिन। आज की प्रतीक्षा है। |
| Thu | `notifAv5` | Always | **Before the world wakes** / A few quiet minutes now, before the day begins. {bani} is one tap away. | **ਦੁਨੀਆ ਜਾਗਣ ਤੋਂ ਪਹਿਲਾਂ** / ਦਿਨ ਸ਼ੁਰੂ ਹੋਣ ਤੋਂ ਪਹਿਲਾਂ ਕੁਝ ਸ਼ਾਂਤ ਪਲ। {bani} ਬੱਸ ਇੱਕ ਟੈਪ ਦੂਰ ਹੈ। | **दुनिया जागने से पहले** / दिन शुरू होने से पहले कुछ शांत पल। {bani} बस एक टैप दूर है। |
| Fri | `notifAv6` | Always | **Your Hazri for {weekday}** / Mark today's Hazri with Nitnem or five minutes of Naam Simran. | **{weekday} ਦੀ ਤੁਹਾਡੀ ਹਾਜ਼ਰੀ** / ਨਿਤਨੇਮ ਜਾਂ ਪੰਜ ਮਿੰਟ ਨਾਮ ਸਿਮਰਨ ਨਾਲ ਅੱਜ ਦੀ ਹਾਜ਼ਰੀ ਲਗਾਓ। | **{weekday} की आपकी हाज़री** / नितनेम या पाँच मिनट नाम सिमरन से आज की हाज़री लगाएँ। |
| Sat | `notifAv7` | Always | **Start the day with Waheguru** / Nitnem first, everything else after. Hazri is open. | **ਦਿਨ ਦੀ ਸ਼ੁਰੂਆਤ ਵਾਹਿਗੁਰੂ ਨਾਲ** / ਪਹਿਲਾਂ ਨਿਤਨੇਮ, ਬਾਕੀ ਸਭ ਬਾਅਦ ਵਿੱਚ। ਹਾਜ਼ਰੀ ਖੁੱਲ੍ਹੀ ਹੈ। | **दिन की शुरुआत वाहिगुरु के साथ** / पहले नितनेम, बाकी सब बाद में। हाज़री खुली है। |

Actions: Sun "Open {bani}" and "Start Nitnem"; Thu "Open {bani}"; Fri "Start Nitnem" and "Begin 5 min"; every other day "Start Nitnem".

### 5.2 Goal bani (the item's own time)

| Key | For | English | ਪੰਜਾਬੀ | हिन्दी |
| --- | --- | --- | --- | --- |
| `notifGoalBani` (A) | A bani item | **Time for {bani}** / {done} of {target} today. Your goal, day {day} of {days}. | **{bani} ਦਾ ਸਮਾਂ** / ਅੱਜ {target} ਵਿੱਚੋਂ {done}। ਤੁਹਾਡਾ ਟੀਚਾ, {days} ਵਿੱਚੋਂ ਦਿਨ {day}। | **{bani} का समय** / आज {target} में से {done}। आपका लक्ष्य, {days} में से दिन {day}। |
| `notifGoalBaniOpen` (A, every-day item) | A bani item with no end date | **Time for {bani}** / {done} of {target} today. | **{bani} ਦਾ ਸਮਾਂ** / ਅੱਜ {target} ਵਿੱਚੋਂ {done}। | **{bani} का समय** / आज {target} में से {done}। |
| `notifGoalSimran` (B) | A simran item | **Your {minutes} minutes of Naam Simran** / One tap and the timer begins. | **ਤੁਹਾਡੇ {minutes} ਮਿੰਟ ਨਾਮ ਸਿਮਰਨ** / ਇੱਕ ਟੈਪ ਨਾਲ ਟਾਈਮਰ ਸ਼ੁਰੂ। | **आपके {minutes} मिनट नाम सिमरन** / एक टैप से टाइमर शुरू। |

Actions: A "Open {bani}" and "In 15 min"; B "Begin {minutes} min" and "In 15 min". The expanded A carries a progress bar of goal items met today out of items in scope.

### 5.3 Gurpurab and Sikh events

| Key | Kinds and time | English | ਪੰਜਾਬੀ | हिन्दी |
| --- | --- | --- | --- | --- |
| `notifGurpurab` | `prakash`, `gurgaddi` · 06:00 | **Today: {event}** / Mark the day with Nitnem and your Hazri. | **ਅੱਜ: {event}** / ਨਿਤਨੇਮ ਅਤੇ ਹਾਜ਼ਰੀ ਨਾਲ ਦਿਨ ਮਨਾਓ। | **आज: {event}** / नितनेम और हाज़री के साथ दिन मनाएँ। |
| `notifGurpurabRemember` | `joti-jot` · 06:00 | **Today we remember: {event}** / Begin the day with Nitnem and your Hazri. | **ਅੱਜ ਅਸੀਂ ਯਾਦ ਕਰਦੇ ਹਾਂ: {event}** / ਨਿਤਨੇਮ ਅਤੇ ਹਾਜ਼ਰੀ ਨਾਲ ਦਿਨ ਸ਼ੁਰੂ ਕਰੋ। | **आज हम याद करते हैं: {event}** / नितनेम और हाज़री के साथ दिन शुरू करें। |
| `notifEventRemember` | `shaheedi` · 07:00 | **Today we remember: {event}** / Begin the day with Nitnem and your Hazri. | **ਅੱਜ ਅਸੀਂ ਯਾਦ ਕਰਦੇ ਹਾਂ: {event}** / ਨਿਤਨੇਮ ਅਤੇ ਹਾਜ਼ਰੀ ਨਾਲ ਦਿਨ ਸ਼ੁਰੂ ਕਰੋ। | **आज हम याद करते हैं: {event}** / नितनेम और हाज़री के साथ दिन शुरू करें। |
| `notifEvent` | Every other kind · 07:00 | **Today: {event}** / Begin the day with Nitnem and your Hazri. | **ਅੱਜ: {event}** / ਨਿਤਨੇਮ ਅਤੇ ਹਾਜ਼ਰੀ ਨਾਲ ਦਿਨ ਸ਼ੁਰੂ ਕਰੋ। | **आज: {event}** / नितनेम और हाज़री के साथ दिन शुरू करें। |

Action: "See calendar".

### 5.4 Hazri nudge (07:00, no goal, no Hazri yet)

| Day | Key | When | English | ਪੰਜਾਬੀ | हिन्दी |
| --- | --- | --- | --- | --- | --- |
| Sun | `notifHn1` | Always; also the fallback | **Your Hazri for today is still open** / Five minutes of Naam Simran marks it. Begin when you're ready. | **ਤੁਹਾਡੀ ਅੱਜ ਦੀ ਹਾਜ਼ਰੀ ਅਜੇ ਬਾਕੀ ਹੈ** / ਪੰਜ ਮਿੰਟ ਨਾਮ ਸਿਮਰਨ ਨਾਲ ਹਾਜ਼ਰੀ ਲੱਗ ਜਾਂਦੀ ਹੈ। ਜਦੋਂ ਤਿਆਰ ਹੋਵੋ, ਸ਼ੁਰੂ ਕਰੋ। | **आपकी आज की हाज़री अभी बाकी है** / पाँच मिनट नाम सिमरन से हाज़री लग जाती है। जब तैयार हों, शुरू करें। |
| Mon | `notifHn2` | A live count for today is known (N-1) | **{count} of the sangat are here today** / Join them with five minutes of Waheguru Simran. | **ਅੱਜ ਸੰਗਤ ਦੇ {count} ਜੀਅ ਹਾਜ਼ਰ ਹਨ** / ਪੰਜ ਮਿੰਟ ਵਾਹਿਗੁਰੂ ਸਿਮਰਨ ਨਾਲ ਉਨ੍ਹਾਂ ਨਾਲ ਜੁੜੋ। | **आज संगत के {count} लोग हाज़िर हैं** / पाँच मिनट वाहिगुरु सिमरन से उनके साथ जुड़ें। |
| Tue | `notifHn3` | Always | **Five minutes, just for you** / Begin the day with Waheguru Simran, and your Hazri is marked. | **ਪੰਜ ਮਿੰਟ, ਸਿਰਫ਼ ਤੁਹਾਡੇ ਲਈ** / ਦਿਨ ਦੀ ਸ਼ੁਰੂਆਤ ਵਾਹਿਗੁਰੂ ਸਿਮਰਨ ਨਾਲ ਕਰੋ, ਤੇ ਹਾਜ਼ਰੀ ਲੱਗ ਜਾਵੇਗੀ। | **पाँच मिनट, सिर्फ़ आपके लिए** / दिन की शुरुआत वाहिगुरु सिमरन से करें, और हाज़री लग जाएगी। |
| Wed | `notifHn4` | Always | **Make it a habit** / Add Naam Simran to a daily goal and Hazri will remind you at your own time. | **ਇਸ ਨੂੰ ਆਦਤ ਬਣਾਓ** / ਨਾਮ ਸਿਮਰਨ ਨੂੰ ਰੋਜ਼ਾਨਾ ਟੀਚੇ ਵਿੱਚ ਜੋੜੋ, ਹਾਜ਼ਰੀ ਤੁਹਾਡੇ ਸਮੇਂ ’ਤੇ ਯਾਦ ਕਰਾਏਗੀ। | **इसे आदत बनाएँ** / नाम सिमरन को रोज़ के लक्ष्य में जोड़ें, हाज़री आपके समय पर याद दिलाएगी। |
| Thu | `notifHn5` | Always | **Five minutes before the day gets busy** / A short sitting of Naam Simran now marks today's Hazri. | **ਦਿਨ ਰੁੱਝਣ ਤੋਂ ਪਹਿਲਾਂ ਪੰਜ ਮਿੰਟ** / ਹੁਣੇ ਥੋੜ੍ਹਾ ਨਾਮ ਸਿਮਰਨ, ਤੇ ਅੱਜ ਦੀ ਹਾਜ਼ਰੀ ਲੱਗ ਜਾਂਦੀ ਹੈ। | **दिन व्यस्त होने से पहले पाँच मिनट** / अभी थोड़ा नाम सिमरन, और आज की हाज़री लग जाती है। |
| Fri | `notifHn6` | A profile exists | **Light up {city} on the globe** / Open Hazri and you show as live today. Five minutes of Simran marks your Hazri. | **ਗਲੋਬ ’ਤੇ {city} ਰੋਸ਼ਨ ਕਰੋ** / ਹਾਜ਼ਰੀ ਖੋਲ੍ਹੋ, ਅੱਜ ਤੁਸੀਂ ਲਾਈਵ ਦਿਖੋਗੇ। ਪੰਜ ਮਿੰਟ ਸਿਮਰਨ ਨਾਲ ਹਾਜ਼ਰੀ ਲੱਗਦੀ ਹੈ। | **ग्लोब पर {city} रोशन करें** / हाज़री खोलें, आज आप लाइव दिखेंगे। पाँच मिनट सिमरन से हाज़री लगती है। |
| Sat | `notifHn7` | Always | **One small step today** / Five minutes of Naam Simran. That's all today's Hazri needs. | **ਅੱਜ ਇੱਕ ਛੋਟਾ ਕਦਮ** / ਪੰਜ ਮਿੰਟ ਨਾਮ ਸਿਮਰਨ। ਅੱਜ ਦੀ ਹਾਜ਼ਰੀ ਲਈ ਬੱਸ ਇੰਨਾ ਹੀ। | **आज एक छोटा कदम** / पाँच मिनट नाम सिमरन। आज की हाज़री के लिए बस इतना ही। |

Actions: Sun "Begin 5 min" and "Later"; Wed "Set a goal" and "Begin 5 min"; Fri "Open Hazri"; every other day "Begin 5 min". "Later" dismisses; it does not snooze.

### 5.5 Sangat (push)

| Key | When | English | ਪੰਜਾਬੀ | हिन्दी |
| --- | --- | --- | --- | --- |
| `notifSangatDigest` (A) | Daily, 21:00 | **{group}: {count} paath today** / Together you're at {pct}% of {target} {bani}. Every paath adds to it. | **{group}: ਅੱਜ {count} ਪਾਠ** / ਮਿਲ ਕੇ {target} {bani} ਦਾ {pct}% ਪੂਰਾ। ਹਰ ਪਾਠ ਇਸ ਵਿੱਚ ਜੁੜਦਾ ਹੈ। | **{group}: आज {count} पाठ** / मिलकर {target} {bani} का {pct}% पूरा। हर पाठ इसमें जुड़ता है। |
| `notifSangatMilestone` (B) | 25, 50, 75 % | **{group} has reached {pct}%** / {done} of {target} {bani}, with {daysLeft} days to go. | **{group} ਨੇ {pct}% ਪੂਰਾ ਕੀਤਾ** / {target} {bani} ਵਿੱਚੋਂ {done}, {daysLeft} ਦਿਨ ਬਾਕੀ। | **{group} ने {pct}% पूरा किया** / {target} {bani} में से {done}, {daysLeft} दिन बाकी। |
| `notifSangatFinal` (C) | Last 2 days, not complete | **{daysLeft} days left for {group}** / {remaining} paath to the goal. Your paath today brings it closer. | **{group} ਲਈ {daysLeft} ਦਿਨ ਬਾਕੀ** / ਟੀਚੇ ਤੱਕ {remaining} ਪਾਠ। ਅੱਜ ਦਾ ਤੁਹਾਡਾ ਪਾਠ ਇਸ ਨੂੰ ਨੇੜੇ ਲਿਆਉਂਦਾ ਹੈ। | **{group} के लिए {daysLeft} दिन बाकी** / लक्ष्य तक {remaining} पाठ। आज का आपका पाठ इसे नज़दीक लाता है। |
| `notifSangatComplete` (D) | Target reached | **{group} reached its goal** / {target} {bani}, together. Waheguru Ji Ka Khalsa, Waheguru Ji Ki Fateh. | **{group} ਨੇ ਟੀਚਾ ਪੂਰਾ ਕੀਤਾ** / {target} {bani}, ਮਿਲ ਕੇ। ਵਾਹਿਗੁਰੂ ਜੀ ਕਾ ਖ਼ਾਲਸਾ, ਵਾਹਿਗੁਰੂ ਜੀ ਕੀ ਫ਼ਤਹਿ। | **{group} ने लक्ष्य पूरा किया** / {target} {bani}, मिलकर। वाहिगुरु जी का खालसा, वाहिगुरु जी की फ़तह। |

| `notifSangatJoined` (E) | 20:00, one person joined | **{name} joined {group}** / Your sangat is growing: {count} members now. | **{name} {group} ਵਿੱਚ ਸ਼ਾਮਲ ਹੋਏ** / ਤੁਹਾਡੀ ਸੰਗਤ ਵਧ ਰਹੀ ਹੈ: ਹੁਣ {count} ਮੈਂਬਰ। | **{name} {group} में शामिल हुए** / आपकी संगत बढ़ रही है: अब {count} सदस्य। |
| `notifSangatJoinedMany` (E) | 20:00, several joined | **{name} and {others} more joined {group}** / Your sangat is growing: {count} members now. | **{name} ਅਤੇ {others} ਹੋਰ {group} ਵਿੱਚ ਸ਼ਾਮਲ ਹੋਏ** / ਤੁਹਾਡੀ ਸੰਗਤ ਵਧ ਰਹੀ ਹੈ: ਹੁਣ {count} ਮੈਂਬਰ। | **{name} और {others} अन्य {group} में शामिल हुए** / आपकी संगत बढ़ रही है: अब {count} सदस्य। |
| `notifSangatEnded` (F) | Next 21:00 after the end date | **{group} has ended** / Together: {total} of {target} {bani}. Thank you for being part of it. | **{group} ਸਮਾਪਤ ਹੋ ਗਿਆ** / ਮਿਲ ਕੇ: {target} {bani} ਵਿੱਚੋਂ {total}। ਇਸ ਦਾ ਹਿੱਸਾ ਬਣਨ ਲਈ ਧੰਨਵਾਦ। | **{group} समाप्त हो गया** / मिलकर: {target} {bani} में से {total}। इसका हिस्सा बनने के लिए धन्यवाद। |
| `notifSangatSimranUnit` | In place of `{bani}` for Simran goals | minutes of Naam Simran | ਮਿੰਟ ਨਾਮ ਸਿਮਰਨ | मिनट नाम सिमरन |
| `notifSangatDigestSimran` (A) | Daily, 21:00, Simran goal | **{group}: {count} minutes of Naam Simran today** / Together you're at {pct}% of {target} minutes. Every minute of Simran adds to it. | **{group}: ਅੱਜ {count} ਮਿੰਟ ਨਾਮ ਸਿਮਰਨ** / ਮਿਲ ਕੇ {target} ਮਿੰਟ ਦਾ {pct}% ਪੂਰਾ। ਸਿਮਰਨ ਦਾ ਹਰ ਮਿੰਟ ਇਸ ਵਿੱਚ ਜੁੜਦਾ ਹੈ। | **{group}: आज {count} मिनट नाम सिमरन** / मिलकर {target} मिनट का {pct}% पूरा। सिमरन का हर मिनट इसमें जुड़ता है। |
| `notifSangatFinalBodySimran` (C) | Last 2 days, Simran goal (title as C) | {remaining} minutes to the goal. Your Simran today brings it closer. | ਟੀਚੇ ਤੱਕ {remaining} ਮਿੰਟ। ਅੱਜ ਦਾ ਤੁਹਾਡਾ ਸਿਮਰਨ ਇਸ ਨੂੰ ਨੇੜੇ ਲਿਆਉਂਦਾ ਹੈ। | लक्ष्य तक {remaining} मिनट। आज का आपका सिमरन इसे नज़दीक लाता है। |

`{name}` is the member's profile name, or `notifSangatSomeone` ("A Sangat member" / ਇੱਕ ਸੰਗਤ ਮੈਂਬਰ / एक संगत सदस्य) for a member without a profile.

Action: "Open Sangat". The expanded A carries a progress bar of the group's percentage.

### 5.6 Action labels

| Key | English | ਪੰਜਾਬੀ | हिन्दी |
| --- | --- | --- | --- |
| `notifActionOpenBani` | Open {bani} | {bani} ਖੋਲ੍ਹੋ | {bani} खोलें |
| `notifActionStartNitnem` | Start Nitnem | ਨਿਤਨੇਮ ਸ਼ੁਰੂ ਕਰੋ | नितनेम शुरू करें |
| `notifActionBeginMinutes` | Begin {minutes} min | {minutes} ਮਿੰਟ ਸ਼ੁਰੂ ਕਰੋ | {minutes} मिनट शुरू करें |
| `notifActionSnooze` | In 15 min | 15 ਮਿੰਟ ਬਾਅਦ | 15 मिनट बाद |
| `notifActionLater` | Later | ਬਾਅਦ ਵਿੱਚ | बाद में |
| `notifActionSeeCalendar` | See calendar | ਕੈਲੰਡਰ ਵੇਖੋ | कैलेंडर देखें |
| `notifActionSetGoal` | Set a goal | ਟੀਚਾ ਬਣਾਓ | लक्ष्य बनाएँ |
| `notifActionOpenHazri` | Open Hazri | ਹਾਜ਼ਰੀ ਖੋਲ੍ਹੋ | हाज़री खोलें |
| `notifActionOpenSangat` | Open Sangat | ਸੰਗਤ ਖੋਲ੍ਹੋ | संगत खोलें |

## 6. Local scheduling

### 6.1 Identifiers and channels

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §4.1** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("02-notifications §6.1"), so a reference to this section still finds it.

### 6.2 Planner

`ReminderPlanner.plan` stays a pure function. Its input gains the goal items in scope, today's Hazri and goal state (`04-goals.md` §4.6), the calendar events of the next 7 days, the profile name and city, the streak, and the last globe snapshot. Its output is occurrences with title, body, actions and route already in the planned language. `reschedule()` seeds nothing any more: there are no stored reminder rows, every occurrence is derived (CM2).

### 6.3 Snooze

"In 15 min" is handled by the notification-action callback without opening the app: it schedules a one-off copy at now + 15 minutes with no actions except "Open {bani}", and records `snoozed:{reminderId}:{day}` so a second snooze is not offered.

## 7. Delivery pipeline (kept from the earlier spec)

Six stages; a break in any one is total silence, and stages 1 and 6 are invisible to unit tests:

```text
1. Manifest     ScheduledNotificationReceiver and the boot receiver declared
2. Permission   POST_NOTIFICATIONS granted (Android 13+)
3. Plan         ReminderPlanner.plan -> occurrences
4. Schedule     zonedSchedule: exact when SCHEDULE_EXACT_ALARM is granted, else inexact
5. Push         FCM token registered (sangat only)
6. Delivery     doze and OEM battery killers
```

- **DP1.** `test/android/manifest_test.dart` keeps both receivers and the permissions; it has been watched failing and stays.
- **DP2.** `USE_EXACT_ALARM` is not declared; `SCHEDULE_EXACT_ALARM` is, and the app asks for it (owner, 2026-10-10). Without it every reminder is an inexact alarm, which Android may hold back by up to three quarters of the wait and never by less than ten minutes, so a 15:30 reminder planned in the morning can come in the evening; the owner's 15:30 reminder and the two-minute test both failed to arrive this way. While it is not allowed, a card saying so with "Allow on-time reminders" (opening Android's "Alarms & reminders") shows on the Notifications screen, in Diagnostics and in the goal sheet under a reminder time. Coming back to the app re-reads it and re-plans, so every reminder after that is exact.
- **DP3.** The Notifications screen asks for `POST_NOTIFICATIONS` and shows a card when it is refused.
- **DP5.** A re-plan never calls `cancelAll` (2026-10-10). It cancels only pending planned ids that are not planned again, replaces the rest under the same id, and takes away a showing goal reminder (and its snooze) for an item met today (GR2). The diagnostics test and a snooze copy carry ids outside the planner's range (`ReminderPlanner.diagnosticId`, `snoozeBit`) and are never touched. Before this, a re-plan followed every write and took "Send one now" off the screen half a second after it showed, deleted the two-minute test and any snooze before they fired, and cleared a delivered Amrit Vela when the app was opened.
- **DP6. The alarm test** (2026-10-10). With exact alarms allowed, the owner's 17:25 reminder and the two-minute test still did not arrive, while "Send one now" did, so the phone was not delivering the alarm or the plugin's path failed when it fired, and nothing on the phone could say which. Diagnostics now sets two alarms straight through Android without the plugin (`AlarmProbeReceiver`): an exact alarm, the way reminders are set, and an alarm-clock alarm, which phone makers almost never hold back. Each records when it arrived and posts its own notification. Only the alarm clock arriving means the phone is stopping Hazri's alarms (battery optimisation, background limits); both arriving while reminders do not means the plugin's path. A "Let Hazri run in the background" button opens Android's battery-optimisation list while it is not exempt.
- **DP7. Hazri schedules its own reminders** (2026-10-11). The alarm test (DP6) settled it on the owner's phone: both probe alarms arrived to the second while not one reminder scheduled through `flutter_local_notifications` ever showed, so the plugin's scheduled path (Gson-stored details read back in its receiver) was the fault. Every planned reminder, the snooze copy and the two-minute test are now set by `android/.../Reminders.kt`: the reminder is stored as JSON in Hazri's own preferences, the alarm carries only its id (`setExactAndAllowWhileIdle` when exact alarms are allowed, else `setAndAllowWhileIdle`), and `ReminderReceiver` posts it with its title, big text, progress and buttons on its high-importance channel. "Snooze" re-sends once in 15 minutes from `ReminderActionReceiver` without opening the app (GR3); a button with a route, or a tap, opens the app through `MainActivity`, which hands the payload to Dart on `app.hazri/reminders`. `ReminderBootReceiver` sets every future alarm again after a reboot, an update or a clock or time-zone change. The plugin remains for "Send one now", a Sangat push in the foreground, the channels and the permissions; whatever it still holds from earlier builds is cancelled at the next re-plan.
- **DP4. Diagnostics**, reachable from the Notifications screen in release builds: notifications allowed, exact alarms allowed, battery-optimisation exemption, number pending, the next three with their times, last delivered, "Send one now" and "Send one in two minutes".

## 8. Sangat notifications through Firebase Cloud Messaging

### 8.1 Device tokens

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §5.10** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("02-notifications §8.1"), so a reference to this section still finds it.

### 8.2 Functions

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §7.2** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("02-notifications §8.2"), so a reference to this section still finds it.

### 8.3 The message

- **FM1.** The text is rendered on the server in each recipient's `locale`, so Android shows it even when the app is not running. The server's copy of the strings (`functions/src/notifications/{en,pa,hi}.json`) is generated from the `notifSangat*` and `notifActionOpenSangat` keys of the ARB files at build time; the ARB files stay the single source.
- **FM2.** Payload: `notification { title, body }`, `android { channelId: "sangat_v2", priority: "normal" }` (the high-importance channel, ARCHITECTURE §4.1), `data { kind, groupId, route: "/sangat/{groupId}" }`. Sent with `sendEach` in batches of at most 500.
- **FM3.** In the foreground the app shows the same notification itself (FCM does not display foreground messages on its own).
- **FM4.** A token that FCM reports as unregistered or invalid is deleted at once; nothing is retried.
- **FM5.** No member names, profile IDs or emails are ever in a payload; only the group name, counts and the bani name.

### 8.4 Cost

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §7.3** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("02-notifications §8.4"), so a reference to this section still finds it.

## 9. Notifications screen

- One switch per kind of Section 3 (3a and 3b share one, "Gurpurab and Sikh events"). Sangat is shown only to group members.
- The per-event switches of the calendar stay where they are.
- The permission card (DP3), the exact-alarm note (DP2) and the diagnostics entry (DP4).
- The old Rehras, Kirtan Sohila and Daily Simran rows, with their sunrise and sunset times, are removed.

## 10. Scenarios

| # | Given | When | Then |
| --- | --- | --- | --- |
| T-1 | Any phone, a Sunday | 04:00 | 5.1 Sun |
| T-2 | No profile, a Monday | 04:00 | 5.1 Sun (fallback, no name) |
| T-3 | Streak 12 through Tuesday, planned Tuesday after Nitnem | Wed 04:00 | "Day 12 of your Nitnem" |
| T-4 | Streak unknown at planning | Wed 04:00 | 5.1 Sun |
| T-5 | Goal: Japji ×1 at 06:40; read at 06:10 | 06:40 | Nothing |
| T-6 | Goal: Japji ×3 at 06:40; one paath | 06:40 | "Time for Japji Sahib / 1 of 3 today…" |
| T-7 | T-6 | "In 15 min" | One copy at 06:55 without a snooze button |
| T-8 | Goal with three banis at three times | Each time | Three notifications |
| T-9 | 27 Oct, Prakash Purab | 06:00 | `notifGurpurab` with the event's name |
| T-10 | 3 Nov, two Gurpurabs | 06:00 | Two notifications |
| T-11 | 1 Nov, a Shaheedi day | 07:00 | `notifEventRemember` |
| T-12 | Reader in Toronto | Any of the above | At the stated time on the Toronto clock |
| T-13 | Event with no Punjabi name, reader in Punjabi | 06:00 | Punjabi text with the English event name |
| T-14 | No goal, nothing done | 07:00 | 5.4 for the weekday |
| T-15 | No goal, Japji read at 05:30 | 07:00 | Nothing |
| T-16 | A goal is active | 07:00 | No Hazri nudge |
| T-17 | A Simran sitting runs 06:55–07:10 | 07:00 events | Shown at 07:10 |
| T-18 | Group member in Delhi, group did 128 paath | 21:00 | Digest 5.5-A in the member's language |
| T-19 | Same group, member in London | 21:00 London | Digest at 21:00 London |
| T-20 | Group crosses 50% at 23:30 Delhi | — | Delhi members get 5.5-B at 07:00; it is sent once |
| T-21 | Group recorded no paath today | 21:00 | No digest |
| T-22 | Member leaves the last group | — | Token deleted; no further sangat pushes |
| T-23 | Profile restored on a new phone | — | The old phone's token is deleted |
| T-24 | FCM reports a token unregistered | Sending | Token deleted, no retry |
| T-24a | Two people joined the creator's group today | 20:00 creator's time | One 5.5-E naming the first and "1 more" |
| T-24b | A custom group passes its end date unmet | Members' next 21:00 | 5.5-F instead of the digest |
| T-25 | No network all day | 04:00, goal times, 06:00, 07:00 | All local notifications arrive |
| T-26 | Permission refused | Notifications screen | The card; nothing pretends to be scheduled |
| T-27 | Phone rebooted | Boot | Everything re-planned |

## 11. Acceptance checklist

- [ ] `ReminderPlanner.plan` unit tests for every rule of Section 4 and every row of Section 10 that is local.
- [ ] `reschedule()` tested end to end with a fake service, including re-planning after a completion and a time-zone change.
- [ ] Every key of Section 5 present in `pa`, `hi` and `en` (`l10n_test.dart`), and the server copy generated from them.
- [ ] `manifest_test.dart` green and watched failing (DP1).
- [ ] Functions (emulator): the dispatcher picks exactly the tokens at 21:00, skips groups with no paath, sends milestones once, holds night milestones until 07:00, and deletes unregistered tokens.
- [ ] Rules test: clients cannot read or write `fcmTokens` or `sangatNotices`.
- [ ] Device: diagnostics shows pending > 0; "Send one now" arrives; "in two minutes" arrives; one arrives after a reboot; a sangat push arrives with the app closed.

## 12. Decisions

| # | Question | Decision |
| --- | --- | --- |
| N-a | Amrit Vela time | **Decided:** 04:00, seven weekday messages (5.1) |
| N-b | Hazri nudge time | **Decided:** 07:00, seven weekday messages, only with no goal and no Hazri |
| N-c | Snooze | **Decided:** one 15-minute snooze on goal reminders |
| N-d | Daily cap | **Decided:** none; each kind sends at most its own allowance |
| N-e | Emoji | **Decided:** none |
| N-f | Gurpurab and events | **Decided:** Gurpurab 06:00, events 07:00, on the day, one notification each; no evening-before or week-ahead message |
| N-g | Phone time or IST | **Decided:** phone time for every local notification |
| N-h | Shaheedi Purabs of the Guru Sahibs | **Decided:** events at 07:00, as their calendar kind says |
| N-1 | Monday's Hazri nudge needs today's live count, which the phone rarely has when it plans the night before | **Open.** As written it will usually send the Sunday fallback. Alternatives: say "yesterday", or replace the message |
| N-2 | The earlier spec also had Rehras and Kirtan Sohila reminders, a daily Simran reminder, "you were added to a sangat", a new Vichar entry, and a corrected-line notice | **Open.** Removed here, because the owner's list of 2026-10-07 is the closed list (0.2) |
| N-i | New-member and group-ended notifications | **Decided 2026-10-07:** added (SG7, SG8) |

## 13. Out of scope

- Any notification not in Section 3.
- Notifications on any platform but Android.
- Analytics on notification opens.
