# 8. Sangat: groups, roles, invites

---

## 8.1 Purpose

Keeping a paath or a simran together — a family, a local sangat, a circle —
without it becoming a leaderboard, and without anybody having to log in.

## 8.2 What exists today

**Three kinds** (`GroupKind`): `family`, `sangat`, `circle`. The kind is not
decoration — **a circle counts minutes and everything else counts paath**, and
that one difference runs through the goal, the member rows and every number on
screen.

**A group goal** (`GroupGoal`): a bani slug (or `simran` for a circle), a
target in the group's unit, an optional `endsAt`, and the Gurpurab the date was
picked from if it was.

**Membership** lives at `groups/{g}/members/{uid}` with `{name, count, role}`.
`role` is `admin` or `member`. The person who creates the group is its admin;
everybody else joins as a member. **The rules pin `role` on update**, so
nobody can promote themselves — and nobody can promote anybody else either.

**Invites.** The group id *is* the invite. The link is a prefix plus the id
(`https://puneetsinghnanda.vercel.app/hazri-app/j/<id>`, a site that does not
exist yet); the code is the id on its own. `get` on a group document is open to
anybody signed in who knows the id; `list` is shut to all but listed groups.
That split is what lets a newcomer read the group they are about to join — the
older rule gated `read` on `isMember`, so every code was refused.

**Counting.** `count()` and `sum()` aggregation queries give the member count
and the group total. **No counter field**, deliberately: every member can write
the group document, so every member could lie about a stored count, and Spark
had no Function to keep an honest one.

**Listed groups.** `listed` is refused on create and pinned on update, so a
group made in the app is always private. Asking to be listed writes
`listingRequested`; approving one is a console edit (`docs/group-listing.md`).

## 8.3 Wrong or missing

1. **Role management does not exist.** There is exactly one admin, set at
   creation, for ever. No promotion, no transfer, no second admin. **If the
   admin leaves or uninstalls, the group is permanently unadministered** — no
   one can set the goal again.
2. **No way to remove a member** from the app, though the rules allow it.
3. **No group discovery.** `listed` cannot be set from the app at all, so the
   entire listed-group idea is inert.
4. **Counts are recomputed on every read.** Fine at ten members, expensive at
   a thousand, and it is why the globe uses a different model.
5. **Nothing notifies anybody of anything** — no push existed.
6. **A group cannot be left tidily.** Leaving is in the rules; the flow is
   thin.
7. **No group history.** A finished group goal leaves no record.

## 8.4 The behaviour

### Roles

**K1 — three roles, not two:** `admin`, `member`, and implicitly `former`
(a deleted membership). An admin can: set the group goal, rename the group,
remove a member, promote a member to admin, and request listing.

**K2 — a group always has at least one admin.** The last admin cannot leave or
demote themselves without naming a successor. This is the fix for the
unadministered group.

**K3 — promotion and demotion are Function-only.** A client cannot write
`role`, including its own. The Function checks the caller is an admin of that
group. Rules stay as they are; the Function uses admin privileges.

**K4 — removing a member deletes their membership row** and nothing of theirs:
their diary, goals and hazri are on their phone and are not the group's.

**K5 — a member sees who the admin is**, so "ask your admin to set the goal"
names a person.

### Invites

**K6 — the code is the invite**, and is presented first: large, kesri,
tappable to copy, with one line saying where to paste it. The link is offered
too and reads sensibly once the site exists.

**K7 — an invite is not a secret but is not guessable** — 20 characters. There
is no expiry and no revocation in this pass; K-2 below.

**K8 — joining is idempotent.** Joining a group you are already in returns you
to it rather than erroring.

### Counting

**K9 — the group total is maintained by a Function**, not aggregated on read
and not written by clients. Every member can still write their own `count`;
the Function sums them. This is the thing Blaze unlocks and the reason the
"never store a counter" rule existed.

**K10 — no member is ever ranked against another.** Rows show what each person
contributed; there is no order by count, no position, no "top member".

## 8.5 Scenarios

**Success**

| Given | When | Then |
|---|---|---|
| No account | Tapping Sangat | The invitation to join, explaining what it costs. Nothing else in the app changes |
| An account | Creating a family group | Created; the creator is admin; the invite code is shown |
| A code | Pasting it on Join | The group is read, the membership written, the group opens |
| A whole link with `?from=whatsapp` | Pasting | Parsed; the trailing segment is taken as the id |
| An admin | Setting a goal of 101 Japji by a Gurpurab | Stored with the occasion; every member sees it |
| A member | Logging 2 paath | Their count +2; the group total follows within seconds |
| A circle | Logging 11 minutes | Counted in minutes, not paath |
| The target is reached | The last paath | Every member is pushed once; the group screen celebrates |
| An admin | Promoting a member | Two admins; both can set the goal |
| The only admin | Trying to leave | Refused, asked to name a successor first |
| A member | Leaving | Their row goes; their diary is untouched; the total drops |

**Failure**

| Given | When | Then |
|---|---|---|
| Rules not published | Any write | `SangatRefused` — "our end, not yours". **Never** offline |
| A wrong or made-up code | Join | "No group with that code" — not a generic error, and no membership row |
| A code for a deleted group | Join | The same message; no partial join |
| No network | Join | "This needs the internet", and nothing half-written |
| Joining a group you are in | Join | Opens the group. No duplicate row, no error |
| A member tries to set the goal | — | The control says who the admin is, rather than being absent |
| A client forges `role: admin` | Write | Refused by the rules **and** covered by a rules test |
| The admin uninstalls without a successor | — | K2 prevents it. For groups already in this state, a Function promotes the earliest-joined member and tells them |
| Two members log the last paath at once | — | The Function is idempotent; one celebration, correct total |
| 500 members | Opening the group | The total is one read of a maintained field, not 500 |

## 8.6 Backend

| Function | Trigger | Does |
|---|---|---|
| `onMemberWrite` | `groups/{g}/members/{uid}` | Maintains `memberCount` and `total`; pushes P1/P3/P5 |
| `setRole` | Callable | Promote/demote, admin-only, enforces K2 |
| `removeMember` | Callable | Admin-only |
| `approveListing` | Callable | Owner-only; flips `listed` after review |
| `dailyDigest` | Scheduled | P2, one per group per member-timezone |
| `healAdminless` | Scheduled, daily | Promotes the earliest-joined member of a group with no admin |

## 8.7 Open decisions

| # | Decision | Default |
|---|---|---|
| K-1 | Maximum group size | 500. Above that the model needs sharding and nobody needs it yet |
| K-2 | Rotatable invite codes | Not now. The group id being the invite is what makes it work offline-ish and simply. Revisit if a code leaks |
| K-3 | Can a member see other members' counts at all? | Yes, as contributions, never ordered. A family wants to see the family |
| K-4 | Group chat or messages | **No.** Free text between people is a moderation surface this app is not built to carry |

## 8.8 Acceptance

- Rules tests (emulator) for every rule: `get` open by id, `list` shut,
  `role` unwritable, `listed` unwritable, a member editing only their own row.
- Emulator tests for each Function, including running twice.
- A test that the last admin cannot leave.
- A test that a non-member cannot read the member list.
- Device: two phones, a group, a goal, a paath each, the total agreeing.
