# Deploying the Phase 2 backend by hand

No workflow deploys anything to Firebase. CI checks the Functions and builds
the admin site and the APK; everything below is run by hand, from a clone of
this branch, by somebody signed in to the Firebase CLI as an owner of
`hazri-dfcc1`.

**Order matters.** The new APK talks only to the `api` Function, through the
Hosting rewrite `/api/**`. Until steps 4 to 6 are done, the app still reads,
plays, keeps the diary and badges (all on the phone), but the profile, the
sangat and the globe say they cannot reach the server.

## 0. Once, on the machine

```bash
npm install -g firebase-tools        # 13.x or later
firebase login
firebase use hazri-dfcc1             # .firebaserc already names it
```

Node 20 is what the Functions run on (`functions/package.json` `engines`).

## 1. The admin Hosting site

Done 2026-10-09. `hazri-admin` is taken by another Firebase project (site
ids are global), so the site is **`hazri-admin-d4b72`**:

```bash
firebase hosting:sites:create hazri-admin-d4b72
```

`.firebaserc` maps the `admin` target to it, and `ADMIN_ORIGINS` in
`functions/src/config.ts` lets it call the `api` Function.

## 2. Google sign-in for the admin site

Firebase console → Authentication:

1. **Sign-in method** → add **Google**, enable it. Keep **Anonymous** on: every
   phone signs in with it.
2. **Settings → Authorized domains** → add `hazri-admin-d4b72.web.app` and
   `hazri-admin-d4b72.firebaseapp.com`.

Project settings → Your apps → **Add app → Web**, name it "Hazri admin". Then:

```bash
cp admin/env.example admin/.env.local   # git ignores .env.local
```

and fill `VITE_FIREBASE_API_KEY` and `VITE_FIREBASE_APP_ID` from the web
app's config. Only `ADMIN_EMAIL` in `functions/src/config.ts` is let in.

## 3. The email secret

The `api` Function declares `BREVO_API_KEY` as a secret, so **the deploy
fails if the secret does not exist**. Until the Brevo account is ready, set
a placeholder; the server treats `{{...}}` as "not configured" and the app
says that email is not set up yet (503 `EMAIL_NOT_CONFIGURED`).

```bash
firebase functions:secrets:set BREVO_API_KEY     # paste {{BREVO_API_KEY}} for now
```

Brevo (done 2026-10-09 except the key):

1. `hazri.me` is authenticated in Brevo (Brevo code and DKIM at Namecheap);
   the sender is `noreply@hazri.me`, "Hazri", set in `functions/src/config.ts`,
   with `Reply-To: support@hazri.me`, which Namecheap forwards to the owner.
2. In Brevo: **Transactional → Settings**, turn click and open tracking
   off. A tracked link is rewritten through Brevo, so the verification link
   opens a browser instead of the app, and it is third-party tracking.
3. **Security → Authorised IPs**: blocking of unknown IPs off. Cloud
   Functions have no fixed address.
4. `firebase functions:secrets:set BREVO_API_KEY` with the API key
   (`xkeysib-...`, not the SMTP key).
5. Redeploy the Functions (step 5). A new secret version is only picked up
   by a deploy.

## 4. Firestore rules and indexes

```bash
firebase deploy --only firestore
```

The rules deny every client read and write: from this build on, only the
Functions touch Firestore. **This stops older APKs' sangat and globe**, which
wrote Firestore directly, so publish it together with the new APK. Check the
console's Rules tab against `firestore.rules` afterwards (CLAUDE.md:
the failure mode is quiet).

## 5. The Functions

```bash
cd functions && npm ci && cd ..
firebase deploy --only functions
```

The first deploy may ask to enable Cloud Scheduler, Eventarc and Secret
Manager APIs; say yes. It deploys `api` (HTTPS, public invoker),
the scheduled `sangatTotals`, `sangatRollover`, `sangatDispatch` and
`buildGlobeSnapshot`, and the Firestore triggers `sangatProfileSync`,
`sangatMilestone` and `badgeGoalReached`, all in `asia-south1` with
`maxInstances: 10`.

Smoke test: every route needs a Firebase ID token, so a bare request
should be refused with 401, which proves the Function is up and answering.

```bash
curl -si https://hazri-dfcc1.web.app/api/v1/profile | head -1   # after step 6
```

## 6. The public Hosting site

```bash
firebase deploy --only hosting:public
```

This carries the `/api/**` rewrite the app calls, `/verify`, `/j/<code>`
with its Play link and preview tags, and `.well-known/assetlinks.json`.

## 7. The admin site

```bash
cd admin && npm ci && npm run build && cd ..
firebase deploy --only hosting:admin
```

Open <https://hazri-admin-d4b72.web.app>, sign in with the admin Google account.

## 8. The built-in groups

In the admin site, create the three built-in groups (`08-sangat.md`) and
press **Start** on each. Until then the Sangat tab lists none.

## 9. Afterwards

- **Email/Password provider:** the new profile flow sends its own links and
  needs only Anonymous. Turn Email/Password off once no installed build
  still uses the old verification (CLAUDE.md, Known gaps).
- **Backups:** point-in-time recovery and scheduled Firestore backups are
  switched on in the console (owner, 2026-10-08).
- **Budget:** the ₹2,000/month cap stays; `maxInstances` is the real limit.
