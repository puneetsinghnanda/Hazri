# 8. Sangat

Rewritten 2026-10-07 with Puneet Singh Nanda. It replaces the earlier version
of this file entirely, and with it the old sangat code (`01-accounts.md`
§13.3 W2). Every decision in it was taken by the owner on 2026-10-07.

## 0. Implementation directive (mandatory, read first)

1. **No inference.** Every behaviour, field, endpoint, limit and string comes from this document.
2. **The server is the source of truth** for groups, members, goals and totals. The phone keeps only a read-only copy of what the server last sent, for display (5.2), and a list of its own paath still to send (5.1).
3. **Server access follows the Profile PRD**: everything goes through the `api` Cloud Function under `/api/v1` with the Firebase ID token (`01-accounts.md` §6.0); Firestore rules deny all client access.
4. **No ranking.** Members are listed with their contributions but never ordered by them (4.6).
5. **No Gurbani** in group names set by the app, messages or notifications; bani names come from `content.db`.
6. **Strings are localised** in `pa`, `hi` and `en`. English source text is given here; the implementer writes `pa` and `hi` and the owner verifies them (`01-accounts.md` §13.9).
7. **Stop on ambiguity.** If anything required is missing or contradictory, stop and ask the developer.
8. **Done means tested.** Section 12 passes, `flutter analyze` is clean and `flutter test` passes.

## 1. Overview and requirement traceability

A Sangat group is a set of people working together toward one shared goal with an end date: so many paath of one bani, or so many minutes of Naam Simran. There are two kinds. **Built-in groups** are set up by the owner in the admin website (`11-admin.md`) and anybody can join or leave them. **Custom groups** are created by people with a profile for their family, Gurdwara or circle; they are private and joined only through an invite.

| Req # | Requirement (owner, 2026-10-07) | Where |
| --- | --- | --- |
| K1 | Three built-in groups: Amrit Vela Sangat, Simran Sangat, Sukhmani Sahib Sangat | 4.1 |
| K2 | People join and leave built-in groups themselves | 4.1, 7 |
| K3 | Built-in groups are configured in an admin website, not in the app | 4.1, `11-admin.md` |
| K4 | Creating a custom group needs a profile; joining one does not | 4.2, 4.3 |
| K5 | Custom groups are private, joined by invite link or code, with no approval | 4.3, 4.4 |
| K6 | Each group has one goal for its whole life: one bani, or minutes of Naam Simran, with a target and an end date of at most 365 days | 4.2, 4.5 |
| K7 | A group becomes inactive when its target is met or its end date passes, and keeps its history | 4.2 |
| K8 | A creator may have 5 active custom groups; support can raise it | 4.2, `11-admin.md` |
| K9 | Invites are shared through any app with a link and a code; the code lasts 30 days; installing from the link joins automatically | 4.4 |
| K10 | Every member's contribution is visible; the first 50 members are listed, then "N more members" | 4.6 |
| K11 | Members can report a group with a reason; support is emailed; the admin can disable or delete it | 4.7 |
| K12 | Diary "+" counts at most 3 a day toward a group | 4.5 |
| K13 | Paath done offline is sent when the phone is back online | 5.1 |
| K14 | Server schema and API | 6, 7 |

## 2. Definitions

| Term | Meaning |
| --- | --- |
| Built-in group | A permanent group created in the admin website. Anybody can join or leave it. Its goal resets (4.1). |
| Custom group | A group created in the app by a person with a profile. Private: it never appears in any list except its members' own. |
| Creator | The person who created a custom group. Built-in groups have no creator. |
| Member | Somebody who has joined a group. With a profile they are identified by their profile; without one, by their install's anonymous uid (4.3). |
| Goal | The group's one target: `BANI` (N paath of one bani) or `SIMRAN` (N minutes of Naam Simran, SG-1). |
| Contribution | One completed paath of the goal's bani (counting one), or one Naam Simran sitting (counting its whole minutes), by a member, counted toward the goal (4.5) |
| Group day | The calendar day in India Standard Time, the same for every group and member (owner, 2026-10-07). `dayIst` = `YYYY-MM-DD`. |
| Active / inactive | A group whose goal is running, or one that has ended. An inactive group can still be opened and read. |
| Disabled | A group the admin switched off after a report. It cannot be opened or joined. |

## 3. Constants

| Constant | Value |
| --- | --- |
| `GROUP_NAME_MAX` | 64 characters (Unicode code points, after trimming) |
| `CUSTOM_GROUP_MAX_MEMBERS` | 1,000 (built-in groups: no limit) |
| `CUSTOM_GROUPS_ACTIVE_DEFAULT` | 5 active custom groups per creator; the admin can set a higher number per person |
| `GOAL_DAYS_MIN` / `GOAL_DAYS_MAX` | 1 / 365, start day included |
| `GOAL_TARGET_MIN` / `GOAL_TARGET_MAX` | 1 / 1,000,000 |
| `SIMRAN_MINUTES_DEFAULT` / range | 5 / 5–120 (as `04-goals.md` §3) |
| `INVITE_CODE_TTL_DAYS` | 30 |
| `INVITE_CODE_ALPHABET` | `ABCDEFGHJKMNPQRSTUVWXYZ23456789` (no 0, O, 1, I or L), 8 characters, shown as `XXXX-XXXX` |
| `MEMBER_LIST_SIZE` | 50 |
| `DIARY_DAILY_CAP` | 3 Diary-added contributions per member per group per group day |
| `REPORT_NOTE_MAX` | 200 characters |
| `GROUP_GLOBE_SECONDS` | 120: how long a group's globe is kept before the server builds it again (GG6) |
| `GROUP_ARRIVALS_MINUTES` / `GROUP_ARRIVALS_MAX` | 60 / 12: the paath a group's globe replays as light (GG4) |

## 4. Rules

### 4.1 Built-in groups

- **BI1.** The three built-in groups at launch are Amrit Vela Sangat (ਅੰਮ੍ਰਿਤ ਵੇਲਾ ਸੰਗਤ, अमृत वेला संगत), Simran Sangat (ਸਿਮਰਨ ਸੰਗਤ, सिमरन संगत) and Sukhmani Sahib Sangat (ਸੁਖਮਨੀ ਸਾਹਿਬ ਸੰਗਤ, सुखमनी साहिब संगत). Their names are set in the admin website. More can be added there later.
- **BI2.** Nobody is a member until they join. Every user sees the list of built-in groups with Join or Leave, with or without a profile.
- **BI3.** Each has one goal at a time, set in the admin website: a bani or Naam Simran, a target (paath, or minutes for Naam Simran), and a length in days. An edit to the target or length reaches the running goal at once (11-admin §4.2).
- **BI4. Reset.** When the target is met, or when the end day passes unmet, the next group day a new goal starts with the same bani or minutes, target and length. The finished goal stays as history, with its total and every member's contribution.
- **BI5.** No member limit. Leaving and joining again is allowed at any time.

### 4.2 Custom groups

- **CG1. Creating** needs a profile (`ProfileLoaded`). Without one, Create shows the profile banner of `07-simran.md` NP3 with `sangatCreateNeedsProfile`.
- **CG2. Name:** 1–64 characters after trimming, any script. It is shown to members only.
- **CG3. Goal straight after.** Creating a group leads at once to setting its goal: `BANI` with a bani from `content.db`, or `SIMRAN` (minutes of Naam Simran); a target; and an end day from today (IST) to today + 364. The start day is the day the goal is set. A group with no goal yet can be shared but counts nothing.
- **CG4. One goal for life.** The goal's type, bani, minutes and target cannot change. Only the end day can be changed, by the creator, to any day from today to start + 364.
- **CG5. Limit.** A creator may have at most their limit of **active** custom groups (default 5). Inactive groups do not count. Over the limit, Create shows `sangatLimitReached` with the support address.
- **CG6. Inactive** when the target is met (at once, mid-day) or after the end day has passed. An inactive group is read-only: its goal, total, history and every member's contribution stay and can be opened. It cannot be joined, and nothing more counts toward it.
- **CG7. Ending early.** The creator sets the end day to today; the group becomes inactive after today.
- **CG8. Deleting** is allowed only while the creator is the only member. It removes the group and everything in it. Otherwise there is no delete.
- **CG9. The creator cannot leave.** The creator can remove any other member (MB4).
- **CG10.** Group type (family, Gurdwara, circle) is not stored: every custom group behaves the same.

### 4.3 Members

- **MB1. Joining without a profile** is allowed. The member is identified by their anonymous uid and shown as `sangatAnonymousName` ("Sangat member").
- **MB2. Creating a profile later** moves every membership and contribution of that uid to the profile, at once, in the profile-creation transaction (`01-accounts.md` §6.2). Clearing the app's data before creating a profile loses those memberships: there is nothing to restore them with.
- **MB3. With a profile**, memberships belong to the profile, not the phone, so a profile restore brings them back with nothing kept on the phone (`01-accounts.md` §6.5). The name shown is the profile's name and follows it when the profile is edited.
- **MB4. Removing.** The creator can remove a member. Leaving and removal keep the member's past contributions in the totals and history; the member's row shows as left.
- **MB5.** A removed member can join again with a valid invite.

### 4.4 Invites

- **IV1. Any member** of an active custom group can share its invite.
- **IV2. The code** belongs to the group and is valid for 30 days from when it was made. Sharing reuses the current code while it is valid; when it has expired, sharing makes a new one. The creator can also make a new one at any time ("Reset invite code"), which ends the old one at once.
- **IV3. Joining by link or code needs no approval** (owner, 2026-10-07).
- **IV4. The share** uses Android's share sheet, so the person chooses the app. Text: `sangatInviteMessage` (8.3) with the group name, the link `https://hazri-dfcc1.web.app/j/{code}` and the code.
- **IV5. The link page** (`public/j/index.html`):
    - With the app installed, the link is an App Link and opens the app on the Join screen with the code filled in (the same mechanism as `/verify`, `01-accounts.md` §7.3; the `/j` path is added to the intent filter).
    - Without the app, the page shows the code large with a Copy button, and a "Get Hazri" button to `https://play.google.com/store/apps/details?id={{ANDROID_PACKAGE_NAME}}&referrer=sangat_code%3D{code}`. The page carries Open Graph tags so the link previews in chat apps.
    - It never calls the API.
- **IV6. After installing,** the app reads the install referrer once on first launch with Google Play's Install Referrer library (approved by the owner, 2026-10-07). If it carries `sangat_code`, the app opens the Join screen with that code after onboarding. The referrer is read once and never sent anywhere.
- **IV7. Typing a code.** The Join screen accepts a code typed or pasted ("Paste code" button), with or without the hyphen, in any case. The app never reads the clipboard by itself.
- **IV8. Results:** joined; already a member (opens the group, no error); invalid or expired code (`sangatCodeInvalid`); group full (`sangatGroupFull`); group inactive (`sangatGroupEnded`); group disabled (`sangatCodeInvalid`).

### 4.5 Counting

- **CT1. What counts.** For a `BANI` goal, every completion of that bani (`04-goals.md` §5.4). For a `SIMRAN` goal, every sitting (`04-goals.md` §5.5), counting its whole minutes: a 7 min 59 s sitting adds 7, and one under a minute adds nothing (SG-1). Retracting a sitting takes back what it added.
- **CT2. When.** A contribution counts when its group day falls between the goal's start and end day, on or after the day the member joined, while the member is a member and the group is active.
- **CT3. Every group.** One paath counts once in every group the member belongs to whose goal it matches (owner, 2026-10-07).
- **CT4. Diary cap.** Completions and sittings added with the Diary "+" (`source` = `DIARY`) count at most `DIARY_DAILY_CAP` per member per group per group day; the rest are accepted and ignored for the group. The Diary itself is not capped (owner, 2026-10-07).
- **CT5. Undo.** Diary "−" on a contribution takes it back from every group it counted in (owner, 2026-10-07).
- **CT6. Leaving** keeps what was contributed (owner, 2026-10-07).
- **CT7. After the end.** Once a goal has completed or expired, nothing more counts toward it, including late arrivals from the outbox.
- **CT8. Totals** are kept by the server only (6.4), never by a phone.
- **CT9. Group day.** A contribution's group day is the IST date of its `completedAt` (or `startedAt` for a sitting). "Today" in a group always means the IST day.

### 4.6 What members see

- **VS1. My groups:** active groups first, then inactive ones, muted and marked `sangatEndedHeading` (design 102, 2026-10-10: one grid, not a second list). Each shows its percentage in a ring, name, total of target, and days left or "Ended on {date}".
- **VS2. Built-in groups:** every active built-in group, with its goal, member count and Join or Leave.
- **VS3. A group:** name; goal (bani or Naam Simran with minutes, target, start and end); total, percentage, today's total, days left or "Ended on {date}"; member count; and the member list. Design 103 (2026-10-10) adds what this phone did toward the goal: **yours today**, counted on the phone from `user.db` the way the server counts it (CT1: today's paath of the goal's bani, or the whole minutes of today's sittings), and **yours toward the goal**, the member row marked `isYou`.
- **VS4. The member list** shows at most 50 members: those with a profile first, alphabetically by name, then "Sangat member" rows. Each row shows the name and that member's contribution to the goal. After 50, one line reads `sangatAndMore` ("and 450 more"). No further loading.
- **VS5.** Nobody is shown a position, a rank, or who has not contributed.
- **VS6.** The creator's row carries `sangatCreatorLabel`.

### 4.6a The group's globe (owner, 2026-10-17: design option C, for custom and built-in groups alike; designs 104, 105)

- **GG1. Where.** On every group screen the goal ring in the navy band wraps a small globe, in place of the big number. The total of the target and the percentage sit under the ring, then the key `sangatGlobeKey`: You · {today} today · {notYet} not yet · {cities} cities. The rest of the screen is design 103.
- **GG2. Who is on it.** The group's active members who have a profile, by the city on their profile, as counts per city. Never a name, a member key or anything finer than a city (GG7). Members without a profile have no city and are not drawn; they are still counted in the key's "not yet" or "today". A member row from before cities were kept takes its city from the member's profile on the group's first globe build (ARCHITECTURE §6.4a, the one-off fill, 2026-10-18), so every member with a profile is on the globe without waiting for their next paath.
- **GG3. The dots.** As the Simran globe (`07-simran.md`), with its sizes (SZ1), threads and arcs (DR6–DR8), zoom (ZM1–ZM3) and tap card (TT1–TT3), but counted for this group: **green** is members who added to this goal today (their latest counted paath's group day is today, CT9); **blue** is the rest; **you** are orange on your own profile's city and come off your city's green if your own "yours today" (VS3) is above 0, else off its blue. Without a profile you are not drawn and nothing is taken off. The tap card uses `sangatGlobeTipToday` and `sangatGlobeTipNotYet`.
- **GG4. Paath arriving as light.** The server gives the group's paath counted toward the current goal in the last `GROUP_ARRIVALS_MINUTES` minutes, newest first, at most `GROUP_ARRIVALS_MAX`, each with the city of the member who did it (none without a profile). On opening the group, the app plays them oldest first, one every 0.8 s: a point of light runs from that city into the ring's leading edge, which glows as it lands. After that, each refresh plays only the new ones. A paath with no city starts from the rim of the globe. With reduced motion on, no light runs.
- **GG4a. Every dot is tied to the ring (owner, 2026-10-18).** Each dot on the near side of the globe -- you, today and not yet -- has a dashed line in its own colour to the ring's leading edge, all the time and not only while a paath arrives: the path a paath from that city travels (GG4 flies along the same curve), as design 104 draws it. The lines turn with the globe; a dot round the back has none. With reduced motion they are still drawn, since they do not move by themselves.
- **GG5. The line under the band.** `sangatArrivals` ("{count} paath arrived in the last hour") for a bani goal, `sangatArrivalsMinutes` ("{minutes} minutes of Naam Simran in the last hour") for a Naam Simran goal, counting what GG4 returned. Not shown when there are none.
- **GG6. Freshness and cost.** The app fetches the group's globe on opening the group and every 2 minutes while the screen is visible, as the Simran globe does (`07-simran.md` GB1). The server keeps one globe per group and builds it again only when it is older than `GROUP_GLOBE_SECONDS`, so the cost does not grow with the number of people looking (ARCHITECTURE §5.6, §6.3 7.15).
- **GG7. Privacy.** Counts per city only. In a small group a city with one member can point to that member, which the owner accepted on 2026-10-17; it is the same city their profile already shows on the Simran globe, now also as a member of this group. The privacy screen says so (`privacyGroupGlobe`).
- **GG8. Offline.** The last globe is kept with the group's copy on the phone (5.2) and shown first; with none, the globe draws only you.
- **GG9. An ended goal** keeps its globe as it was, with no arrivals and no line.
- **GG10. Decided while building (2026-10-17).** The key always takes you off so its three figures add up to the members; without a profile it has no You and nothing comes off, and it shows nothing until a globe has arrived. "Cities" counts every city with members, including one the phone does not know. The phone keeps only arrivals of the last 60 minutes by its own clock, so an old copy never claims a recent paath. A paath without a city starts from the rim opposite the ring's edge.

### 4.7 Reports

- **RP1.** Any member can report a group from its menu with a reason: Offensive name, Spam, Not about Sikhi, or Other. Other allows an optional note of up to 200 characters.
- **RP2.** The server stores the report and emails `support@hazri.me` through the email service of `01-accounts.md` §13.3 W6 with the group's ID, name, reason, note and the reporter's member key. The reporter sees `sangatReportSent`.
- **RP3.** One report per member per group; reporting again replaces the reason.
- **RP4.** The admin can disable or delete a group (`11-admin.md`). A disabled group disappears from every member's list and cannot be opened or joined.

## 5. On the phone

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §3.5** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("08-sangat §5"), so a reference to this section still finds it.

## 6. Server schema (Firestore, `asia-south1`)

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §5.6** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("08-sangat §6"), so a reference to this section still finds it.

## 7. API

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §6.3** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("08-sangat §7"), so a reference to this section still finds it.

## 8. App behaviour

### 8.1 Sangat tab

The tab follows **design 102** ("dashboard tiles", owner, 2026-10-10).

1. **Create group** (navy, "One goal, an end date") and **Join group** (saffron, "With a link or code", opening Join) as two tiles side by side.
2. **My groups** (VS1) as a grid two tiles wide. A tile opens the group.
3. **Join the sangat**: the built-in groups (VS2) as full-width rows in one card, each with its icon, name, goal on one line, member count and Join or Leave. A row opens the group once joined.
4. With no network and no copy yet, `sangatOffline`.

### 8.2 Screens

| Screen | Contents |
| --- | --- |
| Create group | Name field (64), then Set goal: Bani or Naam Simran; bani picker from `content.db` (none for Naam Simran); target (paath, or minutes of Naam Simran); end date (up to 365 days). Then Share invite. |
| Join | Code field (`XXXX-XXXX`), "Paste code", Join. Filled automatically from an App Link or the install referrer. |
| Group | **Design 103** ("ring in a navy band, timeline below", owner, 2026-10-10), with **the group's globe inside the ring** (GG1–GG9, designs 104 and 105, owner, 2026-10-17), for built-in and custom groups alike: back, the name over "Built-in group · N members" (a custom group: "N members"), the menu; the ring around the globe, with total of target and percentage and the key under it, and the goal under that; the arrivals line (GG5) just below the band. Then the current goal as three points -- started, today with the days left, and the end, which for a built-in group says when the next goal starts (BI4); an ended goal shows two. Then three figures: the sangat today, yours today and yours toward the goal (VS3); then **Sit for {paath}** (SC1); then the members (VS4, VS5). Menu: Share invite; for the creator also Change end date, Reset invite code, Remove member (on a member row), Delete (CG8); for others Leave; for all Report. A custom group also has Share invite as a button below the members. |
| Report | The four reasons, the note for Other, Send. |

- **SC1. Sit for {paath}.** While a member and while the goal is active, the group screen carries one primary button that starts the goal's paath: `sangatSitFor` with `sangatGoalSimran` ("Sit for Naam Simran") opens the Simran tab, as Today's Simran button does; with the bani's name from `content.db` ("Sit for Japji Sahib") it opens the reader at that bani. It is not shown to somebody who is not a member, or once the goal has ended.

### 8.3 Strings

| Key | English |
| --- | --- |
| `sangatTitle` | Sangat |
| `sangatMyGroups` | My groups |
| `sangatBuiltInGroups` | Join the sangat |
| `sangatEndedHeading` | Ended |
| `sangatCreate` | Create group |
| `sangatJoinWithCode` | Join with a code |
| `sangatJoin` | Join |
| `sangatLeave` | Leave |
| `sangatCreateNeedsProfile` | Create your profile to start a group of your own. |
| `sangatLimitReached` | You have {limit} active groups. To start more, write to support@hazri.me. |
| `sangatGroupName` | Group name |
| `sangatGoalBani` | Paath of one bani |
| `sangatGoalSimran` | Naam Simran |
| `sangatGoalTarget` | Target |
| `sangatGoalEnds` | Ends on |
| `sangatGoalSummaryBani` | {target} {bani} by {date} |
| `sangatGoalSummarySimran` | {target} minutes of Naam Simran by {date} |
| `sangatSimranMinutesUnit` | minutes of Naam Simran |
| `sangatGoalTargetMinutes` | Target, in minutes of Naam Simran |
| `sangatProgress` | {total} of {target} · {pct}% |
| `sangatToday` | {count} today |
| `sangatProgressMinutes` | {total} of {target} min · {pct}% |
| `sangatTodayMinutes` | {count} min today |
| `sangatDaysLeft` | {days} days left |
| `sangatEndedOn` | Ended on {date} |
| `sangatMembers` | {count} members |
| `sangatMoreMembers` | {count} more members |
| `sangatAnonymousName` | Sangat member |
| `sangatCreatorLabel` | Started this group |
| `sangatShareInvite` | Share invite |
| `sangatInviteMessage` | Join "{group}" on Hazri: {target} {goal} together by {date}. Tap {link} or enter code {code} in the app. |
| `sangatResetCode` | Reset invite code |
| `sangatPasteCode` | Paste code |
| `sangatCodeInvalid` | This code isn't valid. Ask for a new invite. |
| `sangatGroupFull` | This group is full. |
| `sangatGroupEnded` | This group has ended. |
| `sangatChangeEndDate` | Change end date |
| `sangatRemoveMember` | Remove from group |
| `sangatDeleteGroup` | Delete group |
| `sangatReport` | Report group |
| `sangatReportReasonOffensive` | Offensive name |
| `sangatReportReasonSpam` | Spam |
| `sangatReportReasonOffTopic` | Not about Sikhi |
| `sangatReportReasonOther` | Other |
| `sangatReportSent` | Thank you. We'll look into it. |
| `sangatUpdatedAt` | Updated {time} |
| `sangatOffline` | Can't reach the sangat right now |
| `sangatCreateSub` | One goal, an end date |
| `sangatJoinGroupTile` | Join group |
| `sangatJoinGroupSub` | With a link or code |
| `sangatTotalOf` | {total} of {target} |
| `sangatTotalOfMinutes` | {total} of {target} min |
| `sangatOfTarget` | of {target} |
| `sangatOfTargetMinutes` | of {target} min |
| `sangatBuiltInKind` | Built-in group |
| `sangatGroupMenu` | Group menu |
| `sangatThisGoal` | This goal |
| `sangatDayOf` | Day {day} of {days} |
| `sangatStarted` | Started |
| `sangatEnds` | Ends |
| `sangatEndsNewGoal` | Ends; new goal starts {date} |
| `sangatFigureSangatToday` | Sangat today |
| `sangatFigureYoursToday` | Yours today |
| `sangatFigureYoursGoal` | Yours toward the goal |
| `sangatMinUnit` | min |
| `sangatSitFor` | Sit for {paath} |
| `sangatMembersHeading` | Members |
| `sangatMembersAtoZ` | {count} · A to Z |
| `sangatAndMore` | and {count} more |

## 9. Notifications

As `02-notifications.md` §4.5 and §8, plus the two added on 2026-10-07: "{name} joined {group}", once a day to the creator, and "{group} has ended", to every member (`02-notifications.md` 5.5-E and 5.5-F). Members without a profile get no push: push needs a profile (`02-notifications.md` FT1).

## 10. Scenarios

| # | Given | When | Then |
| --- | --- | --- | --- |
| S-1 | No profile | Opens Sangat | Built-in groups with Join; Create shows the profile banner |
| S-2 | No profile | Joins Simran Sangat | Member as "Sangat member"; every sitting adds its minutes |
| S-3 | S-2 | Creates a profile | Memberships and contributions move to the profile; the row shows the name |
| S-4 | Profile | Creates "Gill Parivar", goal 5,000 Japji Sahib by 31 Dec | Group active; Share invite offered |
| S-5 | Five active custom groups | Creates a sixth | `GROUP_LIMIT_REACHED` |
| S-6 | Five active, one ended | Creates another | Allowed |
| S-7 | A member shares the invite to WhatsApp | Recipient with Hazri taps the link | App opens on Join with the code; one tap joins |
| S-8 | Recipient without Hazri | Taps link, installs from Play | First launch offers to join with the code (install referrer) |
| S-9 | Code older than 30 days | Joining | `sangatCodeInvalid`; the next share makes a new code |
| S-10 | Creator resets the code | Old link used | `sangatCodeInvalid` |
| S-11 | Member in two groups with Japji goals | Reads Japji | Counts 1 in each |
| S-12 | Member adds 5 Japji with Diary "+" today | — | Diary shows 5; each group counts 3 |
| S-13 | Japji read offline | Signal returns | Outbox sent; totals rise once |
| S-14 | S-13 sent twice after a lost reply | — | Counted once |
| S-15 | Diary "−" on a counted Japji | — | Taken back from each group |
| S-16 | A Simran group | A 7-minute sitting, then a 40-second one | 7 minutes added, then nothing; Hazri marked by the first |
| S-17 | Target reached at 14:00 | — | Goal completed; custom group inactive at once; later paath not counted |
| S-18 | Built-in goal met on the 10th | 00:05 IST on the 11th | New goal with the same settings; the old one in history |
| S-19 | Built-in goal ends unmet | Next day | Same reset |
| S-20 | Creator sets end date to today | After today | Inactive, history kept |
| S-21 | Creator alone in the group | Delete | Deleted |
| S-22 | Group with members | Creator tries to leave or delete | Not offered; server refuses |
| S-23 | Creator removes a member | — | Row shows as left; contribution stays in the total |
| S-24 | Group of 500 | Opened | 50 rows, names alphabetical then "Sangat member", then "450 more members" |
| S-25 | Group at 1,000 members | Somebody joins | `sangatGroupFull` |
| S-26 | A member reports "Spam" | — | Report stored; support emailed; "Thank you" |
| S-27 | Admin disables the group | Members refresh | Gone from their lists; link invalid |
| S-28 | Offline | Opens a group | Last copy with its time |
| S-29 | Profile restored on a new phone | Opens Sangat | All memberships there, from the server |
| S-30 | 50,000 members read Japji within a minute in a built-in group | — | Shards absorb it; total correct within a minute |

## 11. Privacy and cost

- Each counted paath sends its bani or sitting length, its time and its source to the server. The privacy screen will be redesigned to say so (owner, 2026-10-07: later).
- Reads: opening a group costs the group, its goal and up to 50 member rows (about 52 reads); the copy on the phone (5.2) is shown first and the group itself is not polled.
- The group's globe (GG6): one read of the stored globe per fetch, and a rebuild at most every 2 minutes while somebody is looking: a custom group reads its active member rows (at most 1,000) and up to 12 recent contributions; a built-in group runs two counts per city of the reference list and the same 12 reads.
- Writes: each paath writes one contribution document and one total per custom group it counts in; built-in groups write a shard instead.

## 12. Acceptance checklist

- [ ] Backend (emulator): every endpoint and error of Section 7; idempotent contributions; Diary cap; retraction; join by expired, reset and valid codes; group full; creator rules; profile creation adopting `u_` memberships; `sangatTotals` and `sangatRollover` across a day change and a reset.
- [ ] Rules test: no client can read or write any collection in Section 6.
- [ ] App: outbox add, send, retry and delete; cache shown first and replaced; Join filled from an App Link and from a fake install referrer; every screen of 8.2.
- [ ] Every key of 8.3 in `pa`, `hi` and `en`.
- [ ] Device: link opens the app; Play install joins via the referrer; an offline paath counts after reconnecting.

## 13. Decisions

| # | Question | Decision |
| --- | --- | --- |
| SG-1 | Does a Simran goal count sittings or total minutes? | **Decided 2026-10-09 (owner), replacing 2026-10-07:** total minutes of Naam Simran; every sitting adds its whole minutes and a goal has no sitting length (CT1). The 2026-10-07 answer was sittings of at least the goal's minutes |
| SG-3 | A globe in a group | **Decided 2026-10-17:** option C for custom and built-in groups: the globe inside the goal ring, with paath arriving as light (GG1–GG9). Counts per city only, never names (GG7) |
| SG-2 | Built-in groups and their names | **Decided 2026-10-07:** three, named as in BI1; Daily Nitnem Sangat removed |
| — | Every other rule | Decided by the owner on 2026-10-07 |

## 14. Out of scope

- Group chat, messages, photos, or any free text between members beyond the group name.
- Public or listed custom groups.
- Approval of joins.
- More than one bani per group, or changing a goal's target.
- A group's members on the Simran globe: a group has its own globe (GG1), and the Simran globe stays everybody's.
