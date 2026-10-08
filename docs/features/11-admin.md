# 11. Admin website

Written 2026-10-07 with Puneet Singh Nanda. The admin tools are a separate
website, not part of the app (owner, 2026-10-07). It is used by one person,
the owner.

## 0. Implementation directive (mandatory, read first)

1. **No inference.** Every page, action and check comes from this document.
2. **The server decides who is admin.** The website never decides it, and hiding a button is not security. Every admin endpoint checks the caller (2).
3. **The app's rules are unchanged.** The app still has no sign-in screen and no password. Google sign-in exists only on this website and only for the admin email.
4. **No third-party analytics or tracking.** Every number comes from Hazri's own Firestore data.
5. **Stop on ambiguity.** If anything required is missing or contradictory, stop and ask the developer.

## 1. What it is for

| Req # | Requirement (owner, 2026-10-07) | Where |
| --- | --- | --- |
| AD1 | Set up and run the built-in Sangat groups | 4.2 |
| AD2 | Act on reported groups: disable or delete | 4.3 |
| AD3 | Raise a person's limit of active custom groups when they ask support | 4.4 |
| AD4 | See analytics, such as how many people opened the app today | 4.1 |

## 2. Access

- **AC1.** The website is a separate Firebase Hosting site in the same project, `hazri-admin.web.app`. Nothing links to it from the app or the public site.
- **AC2.** Sign-in is Firebase Authentication with the **Google** provider, on the website only.
- **AC3.** Every request to `/api/v1/admin/*` carries the ID token. The `api` function accepts it only when all of these hold: the token is valid; `firebase.sign_in_provider` is `google.com`; `email_verified` is true; and `email` equals `ADMIN_EMAIL` in `functions/src/config.ts`, which is `puneetsingh1802@gmail.com`. Otherwise `403 NOT_ADMIN`.
- **AC4.** Any other Google account that signs in sees `adminNotAllowed` and can do nothing.
- **AC5.** Every admin action that changes data writes `adminAudit/{autoId}` `{ action, target, before, after, at }`.

## 3. Build

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §8.5** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("11-admin §3"), so a reference to this section still finds it.

## 4. Pages

### 4.1 Dashboard

| Figure | Source |
| --- | --- |
| Opened the app today | Profiles whose `lastSeenDay` is today, IST (`07-simran.md` §5.2); the globe's live count |
| Total profiles | Count of `profiles` |
| New profiles per day, last 30 days | `profiles.createdAt`, by IST day |
| Active custom groups | `groups` with `kind` `CUSTOM` and `status` `ACTIVE` |
| Built-in groups | Each with member count, current goal, total and percentage |
| Sangat paath today | Contributions counted today (IST) across all groups |
| Open reports | `groupReports` with `status` `OPEN` |

Figures are counted with `count()` aggregations when the page opens and when the admin presses Refresh. Nothing polls.

### 4.2 Built-in groups

- List of built-in groups with status, member count and current goal.
- **Create** and **Edit**: names in English, Punjabi and Hindi (each 1–64 characters); the goal template: Bani (from the bani list of `content.db`, served by the API) or Naam Simran with minutes (5–120); target (1–1,000,000); length in days (1–365).
- **Start** creates the first goal from today (IST). Editing the template changes the **next** goal, never the running one.
- **History**: past goals with dates, total, target and member count.
- **Disable / enable**: a disabled built-in group disappears from the app; it keeps its data.

### 4.3 Reports

- Open reports first: group name and ID, kind, reason, note, number of reports for that group, and when.
- Actions on the group: **Disable** (hidden from members, invite stops working, data kept), **Enable**, **Delete** (removes the group, its goals, members and contributions' group links; asks to type the group name to confirm), **Dismiss** the report.
- The group's page shows its name, creator's member key, member count, goal and total, so the admin can judge.

### 4.4 People

- Look up a profile by email.
- Shows name, city, email verified, created, last seen day, active custom groups and their limit.
- **Set group limit** to a number from 5 to 100. Stored in `groupLimits/{profileId}` (`08-sangat.md` §6.5).

## 5. API

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §6.6** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("11-admin §5"), so a reference to this section still finds it.

## 6. Strings

| Key | English |
| --- | --- |
| `adminNotAllowed` | This account cannot use Hazri admin. |

## 7. Scenarios

| # | Given | When | Then |
| --- | --- | --- | --- |
| AW-1 | Signed in as the admin email | Dashboard | Figures shown |
| AW-2 | Signed in with another Google account | Any page | `adminNotAllowed`; every API call returns `403` |
| AW-3 | A crafted request with an anonymous app token | `/api/v1/admin/dashboard` | `403 NOT_ADMIN` |
| AW-4 | Admin creates Amrit Vela Sangat, Japji Sahib, 100,000, 30 days, and starts it | — | It appears in the app's built-in list |
| AW-5 | Admin edits its target during a goal | — | The running goal is unchanged; the next one uses the new target |
| AW-6 | A group reported three times | Admin disables it | Hidden in the app; audit row written |
| AW-7 | Support request to raise a limit | Admin sets 10 | That person can have 10 active custom groups |

## 8. Acceptance

- [ ] Backend (emulator): every endpoint refuses non-admin tokens, including an anonymous token, a Google token with an unverified email, and a password-provider token with the admin email.
- [ ] Every changing action writes an audit row.
- [ ] Manual: sign in, create and start a built-in group, see it in the app.

## 9. Out of scope

- Any admin feature inside the mobile app.
- More than one admin, or roles.
- Editing users' goals, diaries or profiles beyond the group limit.
- Sending notifications or emails from the website.
