# Setting up `hazri.me`

Registered 2026-09-26 at **Namecheap** (nameservers: Namecheap BasicDNS).

**Status, 2026-10-18:** the pages track (steps 3 and 4) is done and waiting
on propagation. At Namecheap -> Advanced DNS, the parking CNAME on `www` and
the URL Redirect on `@` were deleted, and Firebase's two records were added:
A `@` -> `199.36.158.100` and TXT `@` -> `hosting-site=hazri-dfcc1` (TTL 5
min). `hazri.me` is on Authentication's authorized domains. Nothing is set for
`www.hazri.me` yet. The zone also carries Brevo's records for the profile
mail (`brevo1._domainkey` and `brevo2._domainkey` CNAMEs, a `brevo-code` TXT
on `@`, and `_dmarc` TXT `v=DMARC1; p=none; rua=mailto:rua@dmarc.brevo.com`),
which must stay. There is no SPF record; when one is added it is one line.

This is the record set and the order to add it in. The exact values come from
each provider's own wizard — Zoho's mail servers differ by the region the
account was created in, and Firebase's addresses are per project — so nothing
below is a value to copy. It is the *shape*, the order, and the four things
that go wrong.

Nothing here changes the app. `kSiteBase` stays on `hazri-dfcc1.web.app`
until Phase 3 (§1.7 step 7 of the earlier accounts spec,
`git show cc1c967:docs/features/01-accounts.md`), because a
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
(§1.7 option 1 of the earlier accounts spec). Once the profile spec
(`docs/features/01-accounts.md`) is built, the app sends its own mail through
the Trigger Email extension (its §3.1 and §13 W6) instead. A mailbox on the domain is wanted for the
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
"check your internet" (B18 and A13 of the earlier accounts spec,
`git show cc1c967:docs/features/01-accounts.md`).

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

## The console click-path, as of 2026-09-27

Console labels drift. If a name below does not match what is on screen, the
*shape* of the flow is what to follow: verify ownership with a TXT record,
then point A records at Firebase, then add the same domain to Auth's own
separate list.

### Before anything: deploy

**Hosting has to have been deployed once before a custom domain can be
added**, because the domain attaches to a site and the site is created by the
first deploy.

```bash
npm i -g firebase-tools
firebase login
firebase deploy --only hosting
```

Then open `https://hazri-dfcc1.web.app/verify` and check it is the page from
`public/verify/` and not a 404.

### Adding the domain

1. Firebase console → project `hazri-dfcc1` → **Build → Hosting**.
   **Not App Hosting.** That is the newer product for server-rendered
   frameworks, it is billed differently, and it is not what `public/` is.
2. On the site's row, **Add custom domain**.
3. Enter `hazri.me`. Firebase offers to also serve or redirect
   `www.hazri.me` — take the redirect unless there is a reason not to, so
   there is one canonical host.
4. Firebase shows a **TXT record** to prove the domain is yours. Add it at
   the registrar on `@`, wait, then **Verify**.
5. Once verified, Firebase shows the **A records** (usually two IPv4
   addresses). Add both at the registrar on `@`.
6. The status moves through *Pending verification* → *Needs setup* →
   *Pending* → **Connected**. The certificate is issued after propagation
   and the whole thing can take 24 hours. *Needs setup* that persists for a
   few hours is almost always propagation, not a mistake.

### Adding it to Auth

Separate list, separate part of the console, nothing links them.

7. Firebase console → **Authentication → Settings → Authorized domains** →
   **Add domain** → `hazri.me`.

Skipping this is `unauthorized-continue-uri`, which the app currently
reports as "check your internet" (B18, A13).

### What has and has not changed after this

`hazri.me` now serves the same `public/` as `hazri-dfcc1.web.app`, and the
app still points at `hazri-dfcc1.web.app`. The email link still comes from
the default host. That is correct: moving it is `linkDomain`, which waits
for the keystore.

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
