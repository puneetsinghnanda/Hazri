# 1. Accounts, joining and restoring

**There is no login, and there will not be one.** Rule 4, reaffirmed
2026-09-26. No password, no sign-in screen, ever.

---

## 1.1 Purpose

Somebody can read every bani, hear every recitation, keep a diary and mark
their hazri **without an account, without a network, and without ever being
asked who they are**. An account exists for exactly two reasons: to be in a
sangat with other people, and to get your diary back on a new phone.

## 1.2 What exists today

- **Anonymous Firebase Auth.** `FirebaseAccountRepository` signs in
  anonymously the first time somebody joins; there is no credential and no
  screen asking for one.
- `sangatAccountProvider` holds the account or null; `hasJoinedSangatProvider`
  is `account != null`. That boolean gates the Sangat tab and (until this
  week) wrongly gated the hazri banner.
- **Screens:** `join_sangat_screen`/`_sheet` (the invitation), `account_screen`
  (name, city, show-my-name), `verify_email_screen`, `restore_screen`.
- **Verification** is an emailed link. `kVerificationUrl` points at a Vercel
  path; the link is **pasted, not tapped**, because Android App Links need an
  `assetlinks.json` with a release signing fingerprint and there is no keystore
  yet.
- **Deletion** (privacy screen) removes memberships first, then the profile
  row, then the auth user — in that order, because a membership left behind is
  a name in somebody else's group with no account behind it.
- **Export** writes the account and memberships as indented JSON to the share
  sheet, and says in the file that the diary and goals are not in it.

## 1.3 Wrong or missing

1. **An anonymous account is one uninstall from gone.** Firebase anonymous auth
   is tied to the app install. Reinstall and you are a different person: your
   group memberships are unreachable and your synced diary is orphaned. The
   email link is the only recovery and **nothing tells anybody to set it up**.
2. **Nothing explains what the account is.** There is no screen that says "this
   is anonymous, here is what it costs you, here is how to not lose it".
3. **Restore is unreachable except by a link somebody already has.** If you
   never verified an email, there is no path at all.
4. **A pasted link is a bad experience** and will stay so until Phase 3's
   keystore.
5. **No account deletion from inside the sangat flow** — only from privacy,
   which is three menus deep.

## 1.4 The behaviour

**A1.** The app never asks who somebody is before letting them read. No
account is created at first run, at setup, or on opening any tab except
Sangat.

**A2.** An anonymous account is created at exactly one moment: the person taps
**Join the sangat** (or opens an invite link) and confirms. Nowhere else.

**A3.** At the moment the account is created, and not before, the app explains
in one screen: this has no password; it lives on this phone; to keep it if the
phone is lost, add an email. It offers **Add an email now** and **Later**.
Later is a real answer and is remembered.

**A4.** An email, once verified, is the only recovery key. It is stored on the
user document, never shown to other members, and is not a login — it proves
you are the same person, it does not let you sign in.

**A5.** **Recovery is possible on a new phone if and only if an email was
verified.** The app must say that, at A3 and in Settings, in those terms.
Anything softer is a promise it cannot keep.

**A6.** A member's display name is theirs to set, may be blank, and when blank
they appear as "a member" everywhere — not as their uid, not as "Anonymous".

**A7.** Deleting the account deletes: memberships (first), the synced diary,
the presence contributions that can be attributed, the profile, then the auth
user. The diary **on the phone is untouched** and the screen says so.

**A8.** Leaving the sangat entirely is not the same as deleting: memberships go
and the account stays, so rejoining does not orphan anything.

## 1.5 Scenarios

**Success**

| Given | When | Then |
|---|---|---|
| A fresh install, no account | The reader opens Today, Nitnem, Simran, Diary | Everything works; nothing asks for an account; the hazri banner shows |
| No account | They tap Join the sangat and confirm | An anonymous account is created, A3's explainer is shown once |
| An account, no email | They add an email and tap the link | The account is marked verified; Settings shows the email |
| A verified account, new phone | They enter the same email and confirm | Groups and synced diary come back; the local diary is merged, not replaced |
| An account | They rename themselves to blank | Every group shows them as "a member" |
| An account in two groups | They delete the account | Both memberships go, then the profile, then the auth user |

**Failure — each of these must have a specific message, never a generic error**

| Given | When | Then |
|---|---|---|
| No network | They tap Join | "This needs the internet. Everything else works without it." No half-created account |
| Firestore rules not published | Any sangat write | `SangatRefused` — "something is wrong at our end, not yours". **Never** reported as offline |
| An unverified account, phone lost | They install on a new phone | Honest: the old account cannot be recovered. Offered a fresh start, with the local diary intact |
| An email already used by another account | They try to verify it | Refused, with what to do next — not a silent failure |
| The verification link is expired | They paste it | "This link has expired" and a button to send another |
| The link is pasted with a trailing space or `?from=whatsapp` | They paste it | Parsed anyway (the parser is deliberately forgiving) |
| Auth delete succeeds, profile delete failed | Deletion | The account is unreachable either way; the screen does not claim a clean delete |
| Two phones, same verified email | Both write the diary | Last-writer-wins per day, and the day is merged not replaced. Never silently drop a day |

## 1.6 Backend

- `users/{uid}`: name, city, email, verified, createdAt. The client may not
  write `role`, `verified` or `groupTotal` — already enforced.
- **New:** `verified` is set by a Function after the link is followed, not by
  the client. A client that can write `verified` can claim anyone's email.
- **New:** a Function on auth-user delete cleans up anything the client could
  not reach, so a half-finished deletion finishes itself.

## 1.7 Open decisions

| # | Decision | Default |
|---|---|---|
| A-1 | Recovery beyond email — a recovery code shown once, or a QR handover phone-to-phone | Add a **recovery code** at A3: one line, copyable, works offline, no email server involved |
| A-2 | Whether an account is offered again later to somebody who tapped Later | Yes, once, after they have been in a group a week |
| A-3 | Tappable links need the Phase 3 keystore. Bring the keystore forward? | Yes — it also unblocks Play testing, and pasting links is the single worst moment in the app |

## 1.8 Acceptance

- Widget test: every tab is fully usable with `accountRepository` returning
  null, and nothing on screen asks for an account.
- Widget test: A3's explainer appears exactly once, at account creation.
- Rules test (emulator): a client cannot write `verified` on its own document.
- Rules test: a non-member cannot read a group's member list.
- Integration test: delete removes memberships before the profile.
- Device check: restore onto a second phone with a verified email.
