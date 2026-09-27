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
- **Verification** is an emailed link, and the mail is sent by **Firebase
  Auth itself** -- `sendSignInLinkToEmail`, from
  `noreply@hazri-dfcc1.firebaseapp.com`, through Google's own mailer. There is
  no SMTP server, no email provider and no Function in the path today, and
  nothing to pay for. `kVerificationUrl` is
  `https://hazri-dfcc1.web.app/verify` (`lib/core/backend/backend.dart`) --
  Firebase Hosting, **not** Vercel; only the group invite base
  (`kInviteBase`) is still a Vercel path.
- **Verifying and restoring are the same call.** `continueWithLink` links the
  credential onto the anonymous user when one is signed in (same uid, so
  every group and diary row stays attached) and signs into the existing
  account when one is not. That is why one screen does both.
- **`emailVerified` is read off the auth user, never off Firestore**, so a
  phone cannot mark itself verified by writing a document. §1.8's "a Function
  sets `verified`" is therefore already solved, better, and costs nothing.
- The link is **pasted, not tapped**, because Android App Links need an
  `assetlinks.json` with a release signing fingerprint and there is no
  keystore yet.
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
6. ~~Nothing is deployed at `/verify`.~~ **Closed 2026-09-27.** Until that
   morning `https://hazri-dfcc1.web.app` had never been deployed at all — it
   answered Firebase's *Site Not Found* — so every verification link the app
   had ever sent landed on a dead end. `public/` is live now and `/verify`
   answers correctly in all three languages. **Like `firestore.rules`, it is
   published by hand and no workflow does it**, so the next change to those
   pages is only half done until somebody deploys again.
7. **Three different failures are reported as one.** `continueWithLink` maps
   `invalid-action-code` *and* `invalid-email` to `LinkProblem.alreadyUsed`,
   and `isSignInWithEmailLink == false` to `LinkProblem.wrongAddress`. A link
   truncated by a mail client, a link already used, and an address that does
   not match the one the link was minted for are three different things to do
   next, and the reader is told the same thing for all of them.
8. **`too-many-requests` is reported as `SangatUnavailable`**, which reads as
   "check your internet". It means the opposite: the network is fine and
   Firebase is throttling us. Somebody who has asked for the link three times
   because it has not arrived is then sent to look at their wifi.

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

**A9.** **An email that has been typed is not an email that has been
verified**, and the app must never conflate the two. Until the link has been
followed, the address is a string in Firestore that Firebase Auth has never
heard of, and it will recover nothing. Every surface that shows the address
shows its state beside it, and A5's promise is only ever made about a verified
one.

**A10.** **Restore never silently creates a second account.** Asking to
restore an address that no account has must say so. It must not sign the
person into a new, empty account that happens to carry the right email — which
is exactly what Firebase does by default, and what the app does today.

**A11.** **Setting up again on a phone that already had an account strands the
first one.** When `continueWithLink` falls through to `signInWithCredential`
because the address is already in use, the anonymous uid this phone just made
is abandoned along with its `users/{uid}` document. The app must either move
that document's contents onto the restored account or say plainly that the few
minutes' work on this phone is being dropped. Writing an orphan and saying
nothing is not one of the options.

**A12.** **The address can be changed while signed in, and that is the only
moment it can be.** An address nobody can reach any more is unrecoverable, so
changing it must be reachable from Settings and must re-verify.

**A13.** **A link that fails says which of the three things went wrong**:
expired or already used, the address does not match the link, or the link is
not a Hazri link at all (usually truncated by a mail client). Rate limiting is
its own message and is never dressed as being offline.

**A14.** **Restore brings back the account, not the phone.** Name, city,
verified address and group memberships come back. The diary comes back only if
diary sync was on (Y-4). Goals, ticks, bani progress, reminders and simran
history live in `user.db` and do not come back at all. The restore screen says
this **before** the link is sent, not after, because somebody who expects
their diary and gets an empty one will read a correct restore as a failure.

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
| An address nobody has an account for | They ask to restore it | "We have no account for that address." **Not** a new empty account with their name absent |
| A link mangled by the mail client | They paste part of it | "That does not look like a Hazri link — copy the whole address, including everything after the question mark" |
| The same link pasted twice | The second paste | "That link has already been used" and a button to send another — not "wrong address" |
| Four link requests in a minute | The fifth | "Too many attempts, wait a few minutes." **Never** "check your internet" |
| A verified account, diary sync off, new phone | They restore | Groups and name come back; the screen said beforehand that the diary would not, and says again that it did not |
| An account set up again on a reinstall, then verified | The link is followed | They land on the original account; what was done on this phone since the reinstall is either carried over or plainly said to be dropped |

## 1.6 Why a restore fails

The boundary conditions, grouped by where the failure actually is. Each one is
a thing that can happen **after** somebody has completed setup and believes
they are safe.

### The email was never really bound to the account

These are the dangerous ones, because setup looks finished and is not.

| # | What happened | What the person sees today |
|---|---|---|
| B1 | The address was saved but the link was never followed | Firestore has the address; Firebase Auth has never heard of it. Restore mints a **brand new account** with a new uid, `_accountFor` finds no document and fabricates a blank one. It looks like it worked and everything is gone |
| B2 | A typo — `gmial.com`, a missing letter | Same as B1, plus the link is now sitting in a stranger's inbox, and following it would hand them an account |
| B3 | Verified at the time, unreachable now — a work address after leaving the job, a college address, an ISP address | Nothing in the app can help. The only cure was changing it while still signed in (A12), and that moment has passed |
| B4 | `emailVerified` is cached on the local `User` object | The account screen can say "not verified" about an address that is, or the reverse, until something calls `user.reload()` |

**B1 is the default outcome, not an edge case.** `sendSignInLinkToEmail`
creates an account for any address it is given; it is a sign-in method, not a
lookup. And the app cannot check first: `fetchSignInMethodsForEmail` returns an
empty list for every address once **Email Enumeration Protection** is on,
which is Firebase's default for projects of this vintage. So "do you have an
account for this address?" cannot be answered on the client at all — it needs
a Function calling `admin.auth().getUserByEmail`, or the flow has to stop
promising an answer it does not have. This is what A10 costs.

### The uid is lost or the link lands somewhere else

| # | What happened | Consequence |
|---|---|---|
| B5 | Uninstall with no verified email | The anonymous uid goes with the install. Android auto-backup does not reliably carry the Firebase Auth token. Unrecoverable, full stop |
| B6 | Reinstalled, set up again instead of restoring, then verified | `linkWithCredential` throws `credential-already-in-use`, the code falls through to `signInWithCredential` and lands on the original account — correct — but the second anonymous uid and its `users/{uid}` document are orphaned, with whatever was done in between. See A11 |
| B7 | `deleteEverything()` deleted the profile and then `user.delete()` failed (Firebase requires a recent sign-in) | The document is gone, the auth user survives, the address stays taken. A later restore signs into a uid with **no profile** and gets a blank account, and the same address cannot be used to start again cleanly |
| B8 | The auth user was disabled or deleted in the console | `user-disabled` / `user-not-found`, currently falling through to `JoinFailed` → "unavailable" |

### The link itself

| # | What happened | Firebase says | Today's message |
|---|---|---|---|
| B9 | The link expired | `expired-action-code` | Correct — "expired", with a resend |
| B10 | The link was already used (people tap first, nothing happens, then paste) | `invalid-action-code` | "Already used" — correct, by accident: it shares a branch with B11 |
| B11 | The address typed on the restore screen is not the one the link was minted for | `invalid-email` | Also "already used". **Wrong**, and the person resends for ever |
| B12 | The mail client wrapped or rewrote the URL (Outlook Safe Links, Gmail line-wrapping, a corporate rewriter) | `isSignInWithEmailLink` is false | "Wrong address". **Wrong** — nothing is wrong with the address |
| B13 | The mail did not arrive: spam, Promotions, a corporate filter, a provider that distrusts `firebaseapp.com` | nothing at all | Silence, then repeated attempts, then B14 |
| B14 | Too many attempts from this device or to this address | `too-many-requests` | `SangatUnavailable` — "check your internet", which is the opposite of true |
| B15 | The project's daily quota on Firebase's built-in mailer is spent | send fails | Every restore in the project fails until the next day, and nothing distinguishes it |
| B16 | Device clock badly wrong | code validation fails | Generic failure |

### Configuration, not code

These fail identically for everybody and are invisible in git.

| # | What must be true | If it is not |
|---|---|---|
| B17 | Email/Password is enabled **and its Email link (passwordless) sub-toggle is on**, in Authentication → Sign-in method | `operation-not-allowed` on every send, project-wide. Nothing in this repository records whether it is on |
| B18 | The continue URL's host is in Authentication → Settings → Authorized domains (`hazri-dfcc1.web.app` and `.firebaseapp.com` are there by default) | `unauthorized-continue-uri`, currently reported as "unavailable" |
| B19 | Something is deployed at `https://hazri-dfcc1.web.app/verify` | Firebase's *Site Not Found*. The link still works if the whole URL is copied out of the address bar, and nothing tells anybody that. **Was the state until 2026-09-27**; the pages are live now, and the failure returns the moment a change to `public/` is committed and not deployed |
| B20 | `firestore.rules` is published | Auth succeeds and the profile read is refused → `SangatRefused`. The restore "failed" for a reason that is not in Auth at all |
| B21 | There is a network, and it is not a captive portal | `network-request-failed` → "unavailable", which is right |

### It worked, and it still looks like it failed

| # | | |
|---|---|---|
| B22 | Diary sync was off (Y-4 is still open) | The account comes back with an empty diary. Correct behaviour, experienced as data loss — hence A14 |
| B23 | Goals, ticks, bani progress, reminders, simran history are in `user.db` | They never come back, on any setting. Only the diary is even a candidate |
| B24 | The verification email is in English | Somebody using Punjabi or Hindi gets the one thing the app says to them outside the app in a language they did not choose. Rule 5 stops at the app's edge today. See §1.7 |

---

## 1.7 Sending the email — what it takes

Nothing is being paid for or configured today: `sendSignInLinkToEmail` uses
Firebase Auth's own mailer. The question is whether that stays true.

### Option 1 — Firebase's built-in mailer (what is in the code now)

Sender `noreply@hazri-dfcc1.firebaseapp.com`. No SMTP, no provider, no domain,
no Function, no cost.

What it takes, all in the console, all free:

1. **Authentication → Sign-in method → Email/Password → enable, and enable
   the Email link (passwordless sign-in) sub-toggle.** (B17. Verify this
   rather than assume it — a send has never been proved to work end to end.)
2. **Authentication → Settings → Authorized domains** — confirm
   `hazri-dfcc1.web.app` is listed. (B18)
3. **Authentication → Templates → Email address sign-in** — set the sender
   name, the reply-to and the wording. Firebase offers per-locale versions of
   the template and picks one from `FirebaseAuth.instance.setLanguageCode()`;
   the app should set that from `AppSettings` at start-up. Check which locales
   the console actually offers before promising Punjabi. (B24)
4. **Deploy the pages in `public/`.** Written on 2026-09-26; `firebase deploy
   --only hosting` is the whole of what is left (B19). `/verify` reads the
   address it was opened with: when it carries an `oobCode` it shows the
   whole URL with a copy button and where to paste it, and when it does not
   it sends the reader back to the email, which is the only honest answer.
   `/j/<groupId>` does the same for an invite code, using the same
   last-path-segment rule as `groupIdFromInvite`, so both sides are forgiving
   in the same way. All three languages, no fonts fetched, no framework.
   Hosting's free tier (360 MB/day) covers this many times over, and
   **Hosting bandwidth is not Firestore reads** — these pages cost nothing on
   the meter that bills.

**Limits to accept:** the sender domain cannot be changed, the mail says
`firebaseapp.com`, deliverability is Google's rather than ours, and there is a
per-project daily quota that Firebase does not publish as a number (B15).

**Verdict: this is the right answer for Phase 2**, and step 4 is the whole
difference between restore working and restore not working.

### Option 2 — custom SMTP inside Firebase Auth

Authentication → Templates → the SMTP settings behind the pencil. Supply a
host, port, username, password and a From address, and Firebase keeps sending
the mail but from us. Needs a domain, a mailbox or an ESP's SMTP credentials,
and SPF + DKIM records on the domain. Costs the domain and whatever the ESP
charges — free tiers at Resend, Mailgun, Brevo and SES all cover a project
this size.

Buys: the mail comes from `hazri.app`, deliverability we can see and fix, and
the project quota stops applying. Changes no Dart at all.

**Only worth it once a domain exists.** It is also half of Phase 3's App
Links, which need a domain serving `assetlinks.json` anyway — so buy the
domain once and both problems close together.

### Option 2b — the link on our own domain

A custom domain **on Firebase Hosting**, passed as
`ActionCodeSettings.linkDomain`.

This one is not a free choice. Firebase Dynamic Links shut down on
2025-08-25, and [Firebase's migration guide][fdl] says email links are now
minted on a Firebase Hosting domain — the auto-provisioned default, or a
custom Hosting domain. **A link on a host Firebase Hosting does not serve
cannot be minted at all**, so putting `public/` anywhere else would mean two
hosts, two deploys, and `assetlinks.json` on the one the links do not use.
That is what closes the question of a second hosting provider: it was
considered on 2026-09-26 and ruled out on this, not on price.

Worth doing at the same moment as option 2 and Phase 3's App Links — one
domain, deployed once, closes the sender, the tappable link and
`assetlinks.json` together.

[fdl]: https://firebase.google.com/docs/auth/android/email-link-migration

### What connecting `hazri.me` will take

**`docs/domain-setup.md` is the record set, the order, and the four things
that go wrong.** This is the summary.

Registered 2026-09-26 and **not connected to anything**. Nothing in the app
refers to it and nothing should until Phase 3, because a link already in
somebody's inbox has to keep working: the domain is added *alongside*
`hazri-dfcc1.web.app`, never instead of it.

When it goes live:

1. **Firebase Hosting** — add the domain, take the A/AAAA records it gives.
   The certificate is issued after DNS propagates, which can take a day.
2. **Authentication → Settings → Authorized domains** — add it there too.
   Hosting and Auth are separate lists, and missing the second is
   `unauthorized-continue-uri` (B18).
3. **`ActionCodeSettings.linkDomain`** — only then does the email link itself
   move onto the domain. Until it is set, links stay on the default host
   whatever the website says.
4. **One `v=spf1` TXT record** carrying both the mailbox's include and the
   sender's. Two SPF records is a `permerror` and quietly breaks
   deliverability. DKIM is fine as separate records, one selector each.
5. **`assetlinks.json`** at `/.well-known/`, served over HTTPS with no
   redirect, carrying the release keystore's SHA-256. This is what makes the
   link tappable, and it is blocked on the keystore, not the domain (A-3).
6. **An HSTS header in `firebase.json`.** `.me` is not on the HSTS preload
   list, unlike `.app` — `hazri-dfcc1.web.app` gets that for free and
   `hazri.me` will not, so the header has to be set by hand.
7. `kSiteBase` in `lib/core/backend/backend.dart`, last: one constant, and
   the test that holds the two URLs on one host catches anything left
   behind.

### Option 3 — mint the link ourselves and send it ourselves

A callable Function calls `admin.auth().generateSignInWithEmailLink()` and
hands the URL to an ESP's API. Or the same thing without writing the sending
half: the **Trigger Email from Firestore** extension watches a collection and
sends what is written to it — in which case the rules must refuse every client
write to that collection, or anybody signed in can send mail as us.

Buys the things options 1 and 2 cannot: the mail in the reader's own language
including Punjabi whatever the console offers, our own template, bounce and
complaint handling, and — the real one — the Function can call
`getUserByEmail` first, which is the only way to answer A10 and stop B1.

Costs one Function invocation per send (nothing, at this scale, inside the
₹2,000 cap) plus the ESP, and it is the only option with code to maintain.

**Verdict: Phase 3**, and it arrives naturally with the `approveListing` and
digest Functions rather than on its own.

### Option 4 — a recovery code instead of, or beside, email (decision A-1)

A code shown once at setup, exchanged for a custom token by a Function.
No mailbox, no deliverability, no B9–B15 at all — and a new secret for
somebody to lose. It answers none of B1's problem by itself, because a code
nobody wrote down is a code nobody has.

**Verdict: beside, not instead.** It is the answer for somebody who will not
give an address, and it is the only recovery that works with the radio off.

### The recommendation

| When | Do |
|---|---|
| Now, Phase 2 | Option 1, including step 4 — run `firebase deploy --only hosting`, and confirm B17 and B18 in the console. Fix the three error mappings (A13). Say A14 out loud on the restore screen |
| With the Phase 3 keystore | **`hazri.me` is registered (2026-09-26).** Connect it then, once: it serves `assetlinks.json` (tappable links), `/verify`, and SPF/DKIM for option 2's sender |
| Phase 3 | Option 3, so the mail is in the reader's language and `getUserByEmail` can close B1 and A10. Option 4 beside it |

---

## 1.8 Backend

- `users/{uid}`: name, city, email, verified, createdAt. The client may not
  write `role`, `verified` or `groupTotal` — already enforced.
- `verified` is **not** a Firestore field the app trusts. `emailVerified` is
  read off the Firebase Auth user, which no client can write, so this is
  already stronger than a Function setting a field. Anything written into
  `users/{uid}` about verification is a mirror for other people to read, never
  the thing the app checks.
- **New (Phase 3):** a `lookupAccountByEmail` callable, because
  `getUserByEmail` is the only way a client can be told "no account for that
  address" (A10, B1) with Email Enumeration Protection on.
- **New:** a Function on auth-user delete cleans up anything the client could
  not reach, so a half-finished deletion finishes itself.

## 1.9 Open decisions

| # | Decision | Default |
|---|---|---|
| A-1 | Recovery beyond email — a recovery code shown once, or a QR handover phone-to-phone | Add a **recovery code** at A3: one line, copyable, works offline, no email server involved |
| A-2 | Whether an account is offered again later to somebody who tapped Later | Yes, once, after they have been in a group a week |
| A-3 | Tappable links need the Phase 3 keystore. Bring the keystore forward? | Yes — it also unblocks Play testing, and pasting links is the single worst moment in the app |
| A-4 | Which sender: Firebase's `firebaseapp.com`, or our own domain (§1.7 option 2) | **Closed 2026-09-26: Firebase's**, until a domain is bought for `assetlinks.json`; then both move together. When a sender is bought it is a transactional service (Brevo, or Zoho's ZeptoMail), **never a mailbox's SMTP** — Zoho Mail's own limits page caps external sending at 50–500/hour on reputation and says bulk sending is "not permitted under business usage policy", so one throttle would take out the inbox and the sending together |
| A-5 | B6/A11 — carry the orphaned document's contents onto the restored account, or say it is being dropped | Say it is being dropped. Merging two profiles is a lot of machinery for a few minutes of one phone's work, and a wrong merge is worse than an honest sentence |
| A-6 | Does restore promise anything about the diary when sync is off (A14, Y-4)? | No, and it says so before the link is sent. This is settled by Y-4 in `09-diary.md`; it must not be answered twice |
| A-7 | `kInviteBase` is still a Vercel path that serves nothing. Move it to the same host as `/verify`? | **Closed 2026-09-26: yes.** Both now derive from `kSiteBase` in `lib/core/backend/backend.dart`, and a test holds that they share a host. Vercel is out of the project entirely |

## 1.10 Acceptance

- Widget test: every tab is fully usable with `accountRepository` returning
  null, and nothing on screen asks for an account.
- Widget test: A3's explainer appears exactly once, at account creation.
- Rules test (emulator): a client cannot write `verified` on its own document.
- Rules test: a non-member cannot read a group's member list.
- Integration test: delete removes memberships before the profile.
- Device check: restore onto a second phone with a verified email.
- Device check: restore an address **no account has**, and be told so rather
  than landed in a blank account (A10, B1). This is the one that is wrong
  today, so it is the one that must be seen to fail before it is fixed.
- Device check: the link out of a real inbox, tapped, on a phone — the page
  at `/verify` must exist and must say what to do (B19). **Half done
  2026-09-27:** `/verify` is deployed and its no-code branch was seen in a
  browser. The branch that matters — a real link, carrying a real `oobCode` —
  has not been walked yet, and it is the one that proves B17 and B18 too.
- Unit test: each of `expired-action-code`, `invalid-action-code`,
  `invalid-email`, a non-Hazri string and `too-many-requests` produces its own
  message (A13, B10-B14). Five errors, five messages, asserted separately.
- Unit test: `sendVerificationLink` on `unauthorized-continue-uri` and
  `operation-not-allowed` does not say "check your internet" (B17, B18).
- Widget test: the restore screen states what does and does not come back
  **before** the link is sent (A14).
- Console check, written down with a date: email link sign-in is enabled, the
  authorized domains include the continue URL's host, and the template's
  sender and wording have been read (B17, B18). None of this is visible in
  git, so a note in the PR description is the only record there is.
