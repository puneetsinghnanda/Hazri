# Setting up `hazri.me`

Registered 2026-09-26. **Connected to nothing** at the time of writing.

This is the record set and the order to add it in. The exact values come from
each provider's own wizard — Zoho's mail servers differ by the region the
account was created in, and Firebase's addresses are per project — so nothing
below is a value to copy. It is the *shape*, the order, and the four things
that go wrong.

Nothing here changes the app. `kSiteBase` stays on `hazri-dfcc1.web.app`
until Phase 3 (`docs/features/01-accounts.md` §1.7, step 7), because a
verification link already sitting in somebody's inbox has to keep working.

---

## Do it now or later?

**The DNS now. The app later.**

| | Why |
|---|---|
| Certificates take up to 24 hours after DNS propagates | A problem found now costs nothing; found during Phase 3 it blocks the keystore work |
| The mailbox is useful today | Play Store developer contact, the `Reply-To` on the verification mail, the Phase 3 feedback address, the registrar's own contact |
| Sending reputation warms with age | A domain that has been carrying mail for months is trusted more than one that starts sending on launch day |
| Nothing in the app points at it | So none of this can break the flow that works today |

The one thing to **not** do early is step 4 below — moving the email link
itself onto the domain. That waits for the keystore, because until App Links
verify there is nothing to gain and a link on an unverified host to churn.

---

## The records

All at the registrar, in one zone — but they are **two independent tracks**,
and only one of them needs anything bought.

| Track | Steps | Needs | When |
|---|---|---|---|
| **Pages** | 3, 4 | the domain, which exists | Can be done today |
| **Mail** | 1, 2, 5 | a Zoho Mail account, which does not exist yet | Whenever the mailbox is bought |

Neither blocks the other and the records do not collide, so the numbering
below is the order *within* a track, not a queue to work through.

**No mailbox is needed for anything the app does.** Firebase sends the
verification mail itself, from `noreply@hazri-dfcc1.firebaseapp.com`
(`01-accounts.md` §1.7 option 1). A mailbox on the domain is wanted for the
Play Store developer contact, which is public and required at publish, the
`Reply-To` on that mail, and the Phase 3 feedback address. So it is a
before-the-Play-Store item, not a now item.

### 1. The mailbox — Zoho Mail

| Type | Host | Value | From |
|---|---|---|---|
| TXT | `@` | `zoho-verification=zb……` | Zoho's add-domain wizard |
| MX | `@` | three hosts with priorities 10 / 20 / 50 | Zoho — **region-specific**, `.in` and `.com` accounts differ |
| TXT | `zmail._domainkey` | the DKIM public key | Zoho, after the domain verifies |

Do this first: mail has the longest tail, and everything else is independent
of it.

### 2. SPF — **one record, ever**

| Type | Host | Value |
|---|---|---|
| TXT | `@` | `v=spf1 include:<zoho's include> ~all` |

When a transactional sender is added later (§1.7 option 2), **edit this
record** to carry both includes. Do not add a second one. See the traps.

### 3. The pages — Firebase Hosting

| Type | Host | Value | From |
|---|---|---|---|
| TXT | `@` | `google-site-verification=……` | Firebase console → Hosting → Add custom domain |
| A | `@` | the addresses Firebase gives | same |
| AAAA | `@` | if offered | same |
| A / CNAME | `www` | whichever Firebase gives for the second host | same |

Add `hazri.me` and `www.hazri.me` as two custom domains, or add the apex and
let Firebase redirect. Either is fine; pick one and be consistent.

After this, `hazri.me` serves the same `public/` as `hazri-dfcc1.web.app`.
**The email links do not move.** That is step 4 and it is deliberate.

### 4. Firebase Auth — authorized domains

Not DNS. Firebase console → Authentication → Settings → Authorized domains →
add `hazri.me`.

**Hosting and Auth keep separate lists.** A domain added to the first and not
the second is `unauthorized-continue-uri`, which the app currently reports as
"check your internet" (`01-accounts.md` B18, A13).

### 5. DMARC — after the mailbox works

| Type | Host | Value |
|---|---|---|
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:dmarc@hazri.me; fo=1` |

`p=none` first, and read a few weeks of reports before tightening to
`quarantine`. The `rua` address has to be a mailbox that exists, so this
comes after step 1.

---

## Later, with the Phase 3 keystore

- **`ActionCodeSettings.linkDomain`** — the only thing that actually moves
  the email link onto `hazri.me`. Until it is set, links stay on the default
  host however much of the website is on the domain.
- **`/.well-known/assetlinks.json`** — a file in `public/`, not a DNS record.
  Carries the release keystore's SHA-256, served over HTTPS with no redirect.
  This is what makes a link tappable, and it is blocked on the keystore, not
  the domain.
- **A transactional sender's SPF include and DKIM** — *edit* the SPF record;
  DKIM is its own record with its own selector, so it coexists with Zoho's.
- **An HSTS header in `firebase.json`.** `.me` is not on the HSTS preload
  list the way `.app` is, so the protection `hazri-dfcc1.web.app` gets for
  free has to be set by hand here.
- **`kSiteBase`** in `lib/core/backend/backend.dart`, last. One constant, and
  the test holding both URLs on one host catches anything left behind.

---

## The four things that go wrong

1. **Two SPF records.** One `v=spf1` per domain, always. A second is a
   `permerror` and every receiver treats the domain as unauthenticated —
   quietly, with no bounce. When the sender is added, edit the line.

2. **A CNAME on the apex.** Some hosting guides say to CNAME the root at the
   host. Do not: a CNAME at the apex legally excludes every other record on
   that name, which takes out the MX and the TXT records and therefore all
   the mail. Firebase gives A records for the apex for exactly this reason.

3. **Hosting verified, Auth forgotten.** Step 4 is a different list in a
   different part of the console and nothing reminds you.

4. **Deciding it is broken too early.** DNS propagation plus Firebase's
   certificate issuance runs to 24 hours. Set TTL to 300 while setting up so
   a mistake is cheap to correct, and raise it once it is stable.

---

## Checking it

```bash
dig +short hazri.me A
dig +short hazri.me MX
dig +short hazri.me TXT          # exactly one v=spf1 line
dig +short zmail._domainkey.hazri.me TXT
dig +short _dmarc.hazri.me TXT
curl -sI https://hazri.me/verify | head -1
```

The SPF check is the one to actually read rather than glance at: count the
`v=spf1` lines and stop at one.
