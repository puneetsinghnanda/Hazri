# 1. User profile: setup, email verification, restore

This file replaces the earlier accounts specification. Sections 0 to 12 are
the owner's PRD, *Feature Document: User Profile — Hazri (Nitnem app)*, dated
28 Sep 2026, converted from the Word document word for word, **with the
owner's amendments of 2026-10-05 and 2026-10-07 applied in place**. Each
amended passage carries a note pointing to **Section 13**, which records every
amendment (D1–D12), the other decisions taken alongside the PRD, and what is
still open. Where Section 13 and the PRD text disagree, Section 13 wins.

The earlier version of this file is in git history (`git show cc1c967:docs/features/01-accounts.md`). It
holds the research on sending options, the custom-domain rollout and the
boundary conditions of the old Firebase email-link design, which `CLAUDE.md`,
`docs/domain-setup.md` and `docs/signing.md` still cite by its section numbers.

---

Sep 28, 2026 · @Puneet Singh Nanda

## 0. Implementation directive (mandatory, read first)

This document is the single source of truth. The implementing AI (Claude Code) must build exactly what is written here and nothing else.

1.  **No inference.** Every behaviour, field, endpoint, status code, UI string, validation rule, timeout and file path must come from this document. Do not add, rename, merge or "improve" anything.

2.  **No extra features.** Do not add login, profile editing (other than Edit profile, §13 D11), profile deletion, analytics, iOS support, theming, or any feature not listed. Section 12 lists what is out of scope. *(Amended: localisation is required, §13 D1.)*

3.  **Exact strings.** UI copy, email text, error codes and JSON keys must be used character-for-character as written.

4.  **Placeholders stay placeholders.** Values in Section 2 written as {{LIKE_THIS}} must not be invented. Put them in the two config files named in Section 2 and leave the placeholder text in place if no value is provided.

5.  **Stop on ambiguity.** If anything required to proceed is missing, contradictory or unclear, stop and ask the developer. Do not guess, do not pick a "reasonable default".

6.  **Package versions.** Add packages with flutter pub add \<name\> / npm install \<name\> (latest stable at implementation time). Use only the APIs of those packages that this document names.

7.  **Existing Nitnem features.** This document covers only the user profile feature. Do not modify, remove or restyle existing Nitnem content screens. If the project has no home screen yet, create the one described in Section 8 with an empty area reserved for Nitnem content.

8.  **Done means tested.** Implementation is complete only when every item in Section 11 passes.

## 1. Overview and requirement traceability

The Android Flutter app lets a user create an optional profile without logging in, optionally verify their email through a link, and restore an existing profile on a new install by proving ownership of the email.

Identity model: every install is silently signed in with **Firebase Anonymous Authentication**. The anonymous uid identifies the device install. A profile is owned by exactly one uid at a time. The user never sees a login screen.

| Req \# | Requirement (summary)                                                       | Where implemented                           |
|--------|-----------------------------------------------------------------------------|---------------------------------------------|
| 1      | Install from Play Store, no login, banner on home to set up profile         | 8.3 Startup, 8.4 Home screen                |
| 2      | Form: Name, Email, Phone, City; Name/Email/City mandatory                   | 5 Validation, 8.5 Profile Setup screen      |
| 3      | Submit stores in Firestore; optionally ask to confirm email                 | 6.2 POST /profile, 8.6 Profile Saved dialog |
| 4      | Confirm email sends link; clicking link sets emailVerified = true           | 6.3, 6.5, 7 Email & deep links              |
| 5      | Link opens app page saying email verified, only after DB write succeeds     | 8.9 Link Result screen                      |
| 6      | Profile screen calls GET API for verification status                        | 6.1 GET /profile, 8.7 Profile screen        |
| 7      | If no profile, show option to set it up                                     | 8.4, 8.7                                    |
| 8      | Email already exists: tell user, confirm email, restore data                | 6.2 (409), 6.4, 6.5, 8.8                    |
| 9      | Name on home screen from backend or cache                                   | 8.2 Cache, 8.3 Startup, 8.4                 |
| 10     | User can change the email while it is not yet verified (e.g. typed wrongly) | 6.6, 8.7, 8.9, 8.11, 9.6                    |

Fixed decisions: backend is Firebase Cloud Functions + Firestore; platform is Android only; profile restore happens only after the user clicks a link sent to that email.

## 2. Configuration values (developer supplies)

All environment-specific values live in exactly two files: lib/config/app_config.dart (Flutter) and functions/src/config.ts (backend). No other file may hard-code these values.

| Placeholder              | Meaning                                       | Used in                                         |
|--------------------------|-----------------------------------------------|-------------------------------------------------|
| {{FIREBASE_PROJECT_ID}}  | Firebase project ID                           | Both config files, firebase.json, manifest host |
| {{ANDROID_PACKAGE_NAME}} | Android applicationId, e.g. com.example.hazri | assetlinks.json, fallback page                  |
| APP_DISPLAY_NAME         | Supplied: Hazri (app bar title and emails)    | functions config                                |
| {{SHA256_DEBUG}}         | SHA-256 of debug signing cert                 | assetlinks.json                                 |
| {{SHA256_UPLOAD}}        | SHA-256 of upload key                         | assetlinks.json                                 |
| {{SHA256_PLAY_SIGNING}}  | SHA-256 from Play Console → App integrity     | assetlinks.json                                 |
| {{SMTP_CONNECTION_URI}}  | SMTP URI for the Trigger Email extension      | Extension install only                          |
| {{EMAIL_FROM}}           | Sender address, e.g. no-reply@yourdomain      | Extension install only                          |

Derived constants (compute from the placeholders, do not change):

- HOSTING_ORIGIN = https://{{FIREBASE_PROJECT_ID}}.web.app

- API_BASE_URL = HOSTING_ORIGIN + "/api/v1"

- VERIFY_LINK_BASE = HOSTING_ORIGIN + "/verify"

- FUNCTIONS_REGION = asia-south1

Fixed business constants (put in both config files where used):

| Constant                       | Value                                     |
|--------------------------------|-------------------------------------------|
| VERIFY_EMAIL_TOKEN_TTL_SECONDS | 86400 (24 hours)                          |
| RESTORE_TOKEN_TTL_SECONDS      | 3600 (1 hour)                             |
| EMAIL_COOLDOWN_SECONDS         | 60                                        |
| EMAIL_MAX_PER_WINDOW           | 5                                         |
| EMAIL_WINDOW_SECONDS           | 86400 (24 hours, rolling from first send) |
| HTTP_TIMEOUT_SECONDS (app)     | 15                                        |

## 3. Architecture and tech stack

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §1.2** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("01-accounts §3"), so a reference to this section still finds it.

## 4. Firestore DB schema

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §5.4** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("01-accounts §4"), so a reference to this section still finds it.

## 5. Field validation and normalization

The same rules run in the app (lib/validation/validators.dart) and on the server (functions/src/validation.ts). The server is authoritative. Normalize first, then validate the normalized value.

| Field | Required | Normalize                                        | Valid when                                           | Error message (exact)                                                                      |
|-------|----------|--------------------------------------------------|------------------------------------------------------|--------------------------------------------------------------------------------------------|
| Name  | Yes      | Trim; collapse runs of whitespace to one space   | 2–50 characters and matches NAME_REGEX               | Empty: Please enter your name · Invalid: Name must be 2–50 letters (spaces, . ' - allowed) |
| Email | Yes      | Trim (store); trim + lowercase (emailNormalized) | ≤ 254 characters and matches EMAIL_REGEX             | Empty: Please enter your email · Invalid: Please enter a valid email address               |
| Phone | No       | Remove every character that is not a digit, keeping a leading + if typed; empty → null | Always valid (§13 D2) | none |
| City  | Yes      | Chosen from the app's city list (§13 D9)          | A known city ID                                      | Empty: Please choose your city                                                             |

Regular expressions (Dart: RegExp(pattern, unicode: true); TypeScript: new RegExp(pattern, "u")):

```text
NAME_REGEX = ^[\p{L}\p{M}][\p{L}\p{M} .'\-]{1,49}$
EMAIL_REGEX = ^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$
```

*(Amended: `PHONE_REGEX` is removed. The phone number is not validated and any country code is accepted, §13 D2.)*

Rules:

- NAME_REGEX accepts Gurmukhi, Devanagari and Latin letters (Unicode letters and combining marks).

- The phone field is free text with the phone keyboard. There is no +91 prefix and no length limit. *(Amended, §13 D2.)*

- The server receives the phone as typed (or empty/absent) and stores it normalised as in the table above. *(Amended, §13 D2.)*

- Length checks count Unicode code points after normalization.

- Unknown JSON fields in request bodies are ignored.

## 6. Backend REST API

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §6.1** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("01-accounts §6"), so a reference to this section still finds it.

## 7. Emails and Android App Links

One link format serves both purposes: https://{{FIREBASE_PROJECT_ID}}.web.app/verify?token=\<rawToken\>. The server decides the purpose from the token document, not the URL.

### 7.1 Email templates (functions/src/email.ts)

{name} = profile.name, {link} = the verify link, {app} = Hazri. HTML-escape {name} in the HTML body. The HTML body is the text body with paragraphs in \<p\> tags and the link as \<a href="{link}"\>Open in {app}\</a\>.

**7.1-A Verify email** (VERIFY_EMAIL)

- Subject: Confirm your email for {app}

- Text body:

```text
Hi {name},

Tap the link below on your Android phone that has {app} installed to confirm your email:

{link}

This link expires in 24 hours. If you did not request this, you can ignore this email.
```

**7.1-B Restore profile** (RESTORE_PROFILE)

- Subject: Restore your {app} profile

- Text body:

```text
Hi {name},

Someone asked to restore your {app} profile on a new phone. If this was you, tap the link below on that phone:

{link}

This link expires in 1 hour. If you did not request this, ignore this email and your profile will stay as it is.
```

### 7.2 Digital Asset Links (hosting/public/.well-known/assetlinks.json)

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §8.1** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("01-accounts §7.2"), so a reference to this section still finds it.

### 7.3 Android intent filter (inside the main \<activity\> of AndroidManifest.xml)

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §8.2** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("01-accounts §7.3"), so a reference to this section still finds it.

### 7.4 Browser fallback page (hosting/public/verify/index.html)

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §8.3** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("01-accounts §7.4"), so a reference to this section still finds it.

## 8. Flutter app implementation

The app keeps one Riverpod ProfileController as the only source of profile state; every screen reads it, and only the flows below change it.

### 8.1 File structure

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §2.4** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("01-accounts §8.1"), so a reference to this section still finds it.

### 8.2 Services and local cache

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §2.5** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("01-accounts §8.2"), so a reference to this section still finds it.

### 8.3 ProfileController and app startup (Req 1, 9)

ProfileState (sealed): ProfileLoading, ProfileNone, ProfileLoaded(Profile profile, bool isStale), ProfileUnavailable (no cache and the server could not be reached).

Startup (ProfileController.build() returns ProfileLoading and starts \_bootstrap()):

1.  ensureSignedIn(). On NetworkException with no current user → state ProfileUnavailable; stop.

2.  cache.read() → not null → state ProfileLoaded(cached, isStale: true) (name shows instantly).

3.  Call GET /profile:

    - 200 → cache.write, state ProfileLoaded(p, isStale: false).

    - 404 NO_PROFILE → cache.clear(), state ProfileNone.

    - Any other error → keep ProfileLoaded(cached, true) if cached, else ProfileUnavailable.

Controller methods: refresh() (step 3 only, same rules), setProfile(Profile p) (cache.write + ProfileLoaded(p, false)), markNone() (cache.clear + ProfileNone).

main.dart order: WidgetsFlutterBinding.ensureInitialized() → Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform) → runApp(ProviderScope(child: App())) → in the root widget's first addPostFrameCallback, start DeepLinkService.

### 8.4 Home screen (Req 1, 7, 9)

- App bar: title Hazri, trailing icon button Icons.person → /profile.

- Greeting text at top: ProfileLoaded → Welcome, {name}; any other state → Welcome.

- ProfileBanner below the greeting, shown only when state is ProfileNone or ProfileUnavailable. Hidden for ProfileLoading and ProfileLoaded. Not dismissible.

  - Title: Set up your profile

  - Subtitle: Add your name and email to personalise the app.

  - Whole banner tappable → /profile-setup.

- Below: area reserved for existing Nitnem content (unchanged).

### 8.5 Profile Setup screen (Req 2, 3, 8)

App bar title Set up profile. One Form with four TextFormFields in this order:

| Field | Label            | Keyboard                   | Extras                                 |
|-------|------------------|----------------------------|----------------------------------------|
| Name  | Name \*          | text, capitalization words | —                                      |
| Email | Email \*         | emailAddress               | autocorrect off                        |
| Phone | Phone (optional) | phone                      | No prefix, no formatter, no limit (§13 D2) |
| City  | City \*          | picker over the app's city list (§13 D9) | —                                      |

Full-width button Save Profile. autovalidateMode is disabled until the first submit, then onUserInteraction.

On tap:

1.  Run Section 5 validators. Any error → show inline, stop.

2.  Disable all fields and the button; the button shows a small CircularProgressIndicator.

3.  Call POST /profile. Re-enable the form on any non-success result.

| Result                     | App behaviour                                     |
|----------------------------|---------------------------------------------------|
| 201                        | setProfile(p); show Profile Saved dialog (8.6)    |
| 400 VALIDATION_ERROR       | Show each fields message under its field          |
| 409 EMAIL_EXISTS           | Show Email Exists dialog (8.8); keep typed values |
| 409 PROFILE_ALREADY_EXISTS | refresh(), then pushReplacementNamed('/profile')  |
| NetworkException           | SnackBar: network message (8.10)                  |
| Other error                | SnackBar: generic message (8.10)                  |

### 8.6 Profile Saved dialog (Req 3)

barrierDismissible: false.

- Title: Profile saved

- Body: Would you like to confirm your email {email}? This is optional.

- Skip for now → close dialog, pushNamedAndRemoveUntil('/', (\_) =\> false).

- Confirm my email → button shows progress, call POST /profile/verification-email:

  - 200 → close dialog, pushReplacementNamed('/email-sent', purpose VERIFY_EMAIL).

  - 409 EMAIL_ALREADY_VERIFIED → refresh(), go home.

  - 429 → SnackBar rate-limit message (8.10), stay on dialog.

  - Network/other → SnackBar Couldn't send the email. You can try again from your profile., close dialog, go home.

### 8.7 Profile screen (Req 6, 7)

Calls refresh() (GET /profile) in initState and again every time a route pushed from this screen returns.

- ProfileLoading (no cache) → centered CircularProgressIndicator.

- ProfileLoaded → the layout of design 100 ("identity card and badge shelf", chosen by the owner 2026-10-10, replacing 98), titled `profileYourTitle` (Your profile). From the top: a navy identity card with the Hazri mark, the name, the city with a pin, and the email with its state (`profileVerified` in green with a tick, or `profileNotVerified` in saffron), then under a rule three numbers: days of Hazri in all (`profileStatHazriDays`, every day that counts for hazri, `09-diary`), days in a row now (`profileStatInARow`, the current hazri streak) and badges earned (`profileStatBadges`); the Badges card (below); `profileEditButton` and `backupNowButton` side by side; one quiet line, the backup's line (`10-backup.md` §8.2) and the phone after a middle dot (the number, or `profilePhoneNotProvided`); `restoreDataButton` as a text button; and the privacy line `profilePrivacyLine` with a shield. While a refresh is running show a LinearProgressIndicator at the top.

  - isStale == true after the refresh finished → banner text Showing saved details. Couldn't refresh your email status. with button Retry → refresh().

  - emailVerified == false → button Confirm my email, inside the identity card under the email → POST /profile/verification-email: 200 → /email-sent (VERIFY_EMAIL); 409 EMAIL_ALREADY_VERIFIED → refresh(); 429 → rate-limit SnackBar; 404 NO_PROFILE → markNone(); network/other → matching SnackBar.

- ProfileNone → text No profile found and button Set up profile → /profile-setup.

- ProfileUnavailable → text Couldn't load your profile. with buttons Retry (→ refresh()) and Set up profile (→ /profile-setup).

**Change email (Req 10):** when ProfileLoaded and emailVerified == false, show a TextButton labelled Change email directly under the email, beside Confirm my email in the identity card. It opens the Change Email dialog (8.11). Hidden when the email is verified. *(Amended: a verified email is changed through Edit profile, §13 D11.)*

**Edit profile** *(added, §13 D11)*: when ProfileLoaded, a button `profileEditButton` opens the Edit Profile screen (§13.8).

**Badges** *(added 2026-10-08; design 100 from 2026-10-10)*: when ProfileLoaded, the Badges card sits under the identity card and above the buttons. Its content and taps are `12-badges.md` UI5; the menu header's row of badges is UI6.

### 8.8 Email Exists dialog and restore request (Req 8)

- Title: Email already registered

- Body: An account with {email} already exists. To restore it on this phone, we will send a confirmation link to this email.

- Cancel → close; form keeps its values.

- Send link → progress, POST /profile/restore-request with the typed email:

  - 200 → close dialog, pushReplacementNamed('/email-sent', purpose RESTORE_PROFILE).

  - 404 EMAIL_NOT_FOUND → close; SnackBar No account found for this email. Please tap Save Profile again.

  - 409 DEVICE_HAS_PROFILE → close; refresh(); pushReplacementNamed('/profile').

  - 429 → rate-limit SnackBar, stay on dialog.

  - Network/other → matching SnackBar, stay on dialog.

### 8.9 Email Sent screen and Link Result screen (Req 4, 5, 8)

**Email Sent screen** (/email-sent), app bar title Check your email:

- Text VERIFY_EMAIL: We sent a link to {email}. Open it on this phone to confirm your email.

- Text RESTORE_PROFILE: We sent a link to {email}. Open it on this phone within 1 hour to restore your profile.

- Button Resend link, disabled with label Resend in {n}s for cooldownSeconds after arrival and after each resend. Resend calls the same endpoint (6.3, or 6.4 with the same email). 429 → restart countdown with retryAfterSeconds if ≤ 120, else rate-limit SnackBar.

- Button Back to Home → pushNamedAndRemoveUntil('/', (\_) =\> false).

For purpose VERIFY_EMAIL only, the Email Sent screen also shows a TextButton labelled Wrong email? Change it below the text. It opens the Change Email dialog (8.11). Not shown for RESTORE_PROFILE.

**DeepLinkService:** uses AppLinks(). Handles getInitialLink() once and every event of uriLinkStream. Accept a URI only if scheme https, host {{FIREBASE_PROJECT_ID}}.web.app, path /verify or /verify/. Ignore all others. Take query token; ignore a token already handled in this app process (dedupe). Navigate with navigatorKey.currentState!.pushNamed('/link-result', arguments: token ?? "").

**Link Result screen** (/link-result), app bar title Email link. On open it shows CircularProgressIndicator and text Checking your link…, then calls POST /tokens/verify. The success message is shown only after the server returns 200, which happens only after the Firestore write committed (Req 5).

| Server result              | Title                  | Message                                                      | Action on screen                                   |
|----------------------------|------------------------|--------------------------------------------------------------|----------------------------------------------------|
| 200 EMAIL_VERIFIED         | Email verified         | Your email is verified.                                      | If profile present → setProfile. Button Go to Home |
| 200 EMAIL_ALREADY_VERIFIED | Email verified         | Your email is already verified.                              | Same as above                                      |
| 200 PROFILE_RESTORED       | Profile restored       | Welcome back, {name}. Your profile has been restored.        | setProfile. Button Go to Home                      |
| 410 TOKEN_EXPIRED          | Link expired           | This link has expired.                                       | See button rule below                              |
| 404 TOKEN_INVALID          | Link not valid         | This link is invalid or has been replaced by a newer link.   | See button rule below                              |
| 409 TOKEN_ALREADY_USED     | Link already used      | This link has already been used.                             | See button rule below                              |
| 403 RESTORE_WRONG_DEVICE   | Wrong phone            | Open this link on the phone where you requested the restore. | Go to Home                                         |
| 409 DEVICE_HAS_PROFILE     | Profile already set up | This phone already has a profile.                            | refresh(); Go to Home                              |
| 400 INVALID_REQUEST        | Link not valid         | Invalid link.                                                | Go to Home                                         |
| NetworkException           | Couldn't check link    | Network message (8.10)                                       | Retry (repeat the call) and Go to Home             |
| Other error                | Couldn't check link    | Generic message (8.10)                                       | Retry and Go to Home                               |

Button rule for expired / invalid / used: purpose VERIFY_EMAIL and state is ProfileLoaded with emailVerified == false → button Send a new link (same handling as 8.7 Confirm my email). Purpose RESTORE_PROFILE and state is not ProfileLoaded → button Try again → pushReplacementNamed('/profile-setup'). Always also show Go to Home. Go to Home = pushNamedAndRemoveUntil('/', (\_) =\> false).

### 8.10 Shared messages (lib/util/messages.dart)

| Key                                  | Text                                                                               |
|--------------------------------------|------------------------------------------------------------------------------------|
| network                              | No internet connection. Please try again.                                          |
| generic                              | Something went wrong. Please try again.                                            |
| rateLimit (retryAfterSeconds ≤ 120)  | Please wait {n} seconds before requesting another email.                           |
| rateLimit (retryAfterSeconds \> 120) | Too many emails requested. Please try again in {h} hours. where h = ceil(n / 3600) |

### 8.11 Change Email dialog (Req 10)

File lib/widgets/change_email_dialog.dart. Opened only from 8.7 and the Email Sent screen (8.9), and only when state is ProfileLoaded with emailVerified == false. barrierDismissible: false.

- Title: Change email

- One TextFormField: label New email \*, pre-filled with the current email, keyboard emailAddress, autocorrect off, Section 5 email validator.

- Helper text: We will send a new confirmation link to this email.

- Buttons: Cancel (close, no change) and Save and send link.

- On Save and send link: validate; if the normalized value equals the current emailNormalized, show inline This is already your email and send nothing. Else disable the field and buttons, show progress, call PATCH /profile/email.

| Result                     | App behaviour                                                                                                                                                                                                |
|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 200 EMAIL_CHANGED          | setProfile(profile); close dialog; pushReplacementNamed('/email-sent', EmailSentArgs(VERIFY_EMAIL, profile.email, cooldownSeconds)) when opened from Email Sent, else pushNamed it; home greeting unaffected |
| 400 VALIDATION_ERROR       | Inline error from fields.email                                                                                                                                                                               |
| 400 EMAIL_UNCHANGED        | refresh(); inline This is already your email                                                                                                                                                                 |
| 409 EMAIL_EXISTS           | Inline An account with this email already exists; nothing changes                                                                                                                                            |
| 409 EMAIL_ALREADY_VERIFIED | Close; refresh(); SnackBar Your email is already verified and can't be changed.                                                                                                                              |
| 404 NO_PROFILE             | Close; markNone(); pushNamedAndRemoveUntil('/', (\_) =\> false)                                                                                                                                              |
| 429 RATE_LIMITED           | Rate-limit SnackBar (8.10); dialog stays open                                                                                                                                                                |
| NetworkException / other   | Matching SnackBar (8.10); dialog stays open, value kept                                                                                                                                                      |

## 9. Success, failure and boundary scenarios

Every row below must behave exactly as stated; each is already implied by Sections 5–8 and is listed so tests can check it.

### 9.1 Startup and home

| \#  | Scenario                                            | Expected result                                                               |
|-----|-----------------------------------------------------|-------------------------------------------------------------------------------|
| S1  | First launch, online                                | Anonymous sign-in; GET → 404; greeting Welcome; banner shown                  |
| S2  | First launch, offline                               | Sign-in fails → ProfileUnavailable; banner shown; Save shows network SnackBar |
| S3  | Relaunch with cache, online                         | Name shown instantly from cache; GET 200 updates cache                        |
| S4  | Relaunch with cache, offline                        | Name shown from cache; no banner; no error on home                            |
| S5  | Relaunch; profile was restored on another phone     | GET → 404 → cache cleared; Welcome + banner                                   |
| S6  | Cache JSON corrupt, or cache ownerUid ≠ current uid | Cache deleted; behaves as no cache                                            |
| S7  | App data cleared or app reinstalled                 | New uid, no cache → same as S1; user can restore via Req 8                    |

### 9.2 Profile creation

| \#  | Scenario                                                             | Expected result                                                            |
|-----|----------------------------------------------------------------------|----------------------------------------------------------------------------|
| C1  | All valid, new email                                                 | 201; home shows Welcome, {name}; Profile Saved dialog                      |
| C2  | Phone left empty                                                     | Accepted; stored phone: null; profile shows Not provided                   |
| C3  | Name length 1 or 51 after normalization; no city chosen (§13 D9)     | Inline error; no request sent                                              |
| C4  | Name length exactly 2 or 50                                          | Accepted                                                                   |
| C5  | Name Harpreet Kaur                                                   | Stored as Harpreet Kaur                                                    |
| C6  | Name in Gurmukhi (e.g. ਹਰਪ੍ਰੀਤ)                                       | Accepted                                                                   |
| C7  | Phone in any format, with or without a country code (§13 D2)         | Accepted; stored normalised                                                |
| C8  | Email exists with different case / spaces                            | 409 EMAIL_EXISTS (comparison uses emailNormalized)                         |
| C9  | Two installs submit the same new email at once                       | Transaction: one gets 201, the other 409 EMAIL_EXISTS                      |
| C10 | Same install submits twice (double tap or retry after lost response) | Second call → 409 PROFILE_ALREADY_EXISTS → app refreshes and opens Profile |
| C11 | Client validation bypassed, server rejects                           | 400 VALIDATION_ERROR; messages under fields                                |
| C12 | Network drops during submit                                          | Network SnackBar; form values kept; retry safe (C10)                       |

### 9.3 Email verification

| \#  | Scenario                                                     | Expected result                                                                                                      |
|-----|--------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|
| V1  | Tap Confirm my email, then open link on same phone           | Email verified; Firestore emailVerified: true; Profile shows Verified                                                |
| V2  | Link opened while app is closed (cold start)                 | App opens, Link Result screen processes token                                                                        |
| V3  | Link opened while app is running                             | Link Result screen pushed on top                                                                                     |
| V4  | Same link opened again after success                         | 200 EMAIL_ALREADY_VERIFIED → Your email is already verified.                                                         |
| V5  | Older link opened after a newer one was sent                 | 404 TOKEN_INVALID; Send a new link shown                                                                             |
| V6  | Link opened more than 24 h after sending                     | 410 TOKEN_EXPIRED; Send a new link shown                                                                             |
| V7  | Link opened on another phone that has the app                | Profile marked verified; isOwner: false; that phone's cache untouched                                                |
| V8  | Link opened on a computer or phone without the app           | Fallback page (7.4); nothing written                                                                                 |
| V9  | Resend within 60 s                                           | 429; countdown restarts with retryAfterSeconds                                                                       |
| V10 | 6th email to the profile within 24 h                         | 429; Too many emails requested… message                                                                              |
| V11 | Confirm my email tapped when already verified (stale screen) | 409 EMAIL_ALREADY_VERIFIED → refresh shows Verified                                                                  |
| V12 | Network error on Link Result screen                          | Couldn't check link + Retry; token still usable                                                                      |
| V13 | Link with missing or malformed token                         | 400 (or empty token) → Invalid link.                                                                                 |
| V14 | SMTP delivery fails                                          | App still shows Check your email; user can resend after cooldown; developer sees mail/{id}.delivery.state == "ERROR" |

### 9.4 Profile restore

| \#  | Scenario                                                                  | Expected result                                                                                                     |
|-----|---------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| R1  | New install enters an existing email                                      | 409 → Email Exists dialog; no profile data returned                                                                 |
| R2  | Send link then link opened on same phone within 1 h                       | 200 PROFILE_RESTORED; home shows Welcome, {name}; emailVerified: true                                               |
| R3  | Restore link opened on a different phone                                  | 403 RESTORE_WRONG_DEVICE; nothing changes                                                                           |
| R4  | Restore link opened after 1 h                                             | 410; Try again → Profile Setup                                                                                      |
| R5  | User created a new profile with another email before opening restore link | 409 DEVICE_HAS_PROFILE; nothing changes                                                                             |
| R6  | Restore link opened twice                                                 | Second → 409 TOKEN_ALREADY_USED                                                                                     |
| R7  | Two restore requests; older link opened                                   | 404 TOKEN_INVALID                                                                                                   |
| R8  | After R2, the old phone opens the app                                     | GET → 404; cache cleared; banner shown                                                                              |
| R9  | After R2, old phone opens an old verify link                              | 404 TOKEN_INVALID (superseded during restore)                                                                       |
| R10 | Attacker spams restore for someone's email                                | Limited to 1 per 60 s and 5 per 24 h per profile; link only works on the attacker's phone if the victim forwards it |

### 9.5 Auth and server

| \#  | Scenario                                 | Expected result                                  |
|-----|------------------------------------------|--------------------------------------------------|
| A1  | ID token expired                         | 401 → token force-refreshed → one retry succeeds |
| A2  | Request without token (e.g. curl)        | 401 UNAUTHENTICATED                              |
| A3  | Unhandled server exception               | 500 INTERNAL; app shows generic message          |
| A4  | Client tries direct Firestore read/write | Denied by rules (10.1)                           |

### 9.6 Email change (Req 10)

| \#  | Scenario                                                          | Expected result                                                                                                           |
|-----|-------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------|
| E1  | Unverified user changes to a new valid email                      | 200; emailIndex moved to new email; verify link sent to new email; Email Sent screen shows new email                      |
| E2  | Link sent to the old email opened after the change                | 404 TOKEN_INVALID; nothing changes                                                                                        |
| E3  | New email belongs to another profile                              | 409 EMAIL_EXISTS inline; nothing changes                                                                                  |
| E4  | New email equals current one (any case or spaces)                 | Blocked in app; server returns 400 EMAIL_UNCHANGED if reached                                                             |
| E5  | Email already verified                                            | Change email not shown; server returns 409 EMAIL_ALREADY_VERIFIED if called                                               |
| E6  | Change within 60 s of the last email, or 6th email in 24 h        | 429; nothing changes (email, index, tokens untouched)                                                                     |
| E7  | Another install registers the old email after the change          | 201 (old email was released)                                                                                              |
| E8  | Verify link click and email change arrive together                | Transactions serialize: verify first → change gets 409 EMAIL_ALREADY_VERIFIED; change first → link gets 404 TOKEN_INVALID |
| E9  | Network drops after the server committed the change; user retries | 400 EMAIL_UNCHANGED → app refreshes and shows the new email                                                               |
| E10 | A restore link for the old email is pending on another phone      | Superseded by the change → 404 TOKEN_INVALID                                                                              |
| E11 | User changes email several times                                  | Only the newest link works; each change counts toward the email quota                                                     |

## 10. Security rules, project config and deployment

### 10.1 firestore.rules — deny all client access

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §5.11** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("01-accounts §10.1"), so a reference to this section still finds it.

### 10.2 firebase.json

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §5.12** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("01-accounts §10.2"), so a reference to this section still finds it.

### 10.3 Android build settings

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §8.4** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("01-accounts §10.3"), so a reference to this section still finds it.

### 10.4 Deployment steps (developer, in this order)

> **Moved to [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) §9.2** on 2026-10-08, word for word, as the one home for schema, storage and APIs. It keeps this file's numbering there ("01-accounts §10.4"), so a reference to this section still finds it.

## 11. Acceptance checklist

Implementation is complete only when all items pass. Backend tests run against the Firebase Emulator Suite (Auth, Firestore, Functions) with Jest; app tests use flutter_test.

**Backend (Jest + emulators)**

- [ ] Validation unit tests cover every rule and boundary in Section 5 and rows C3–C7.

- [ ] POST /profile: 201, 400, both 409 codes, and the concurrent case C9.

- [ ] GET /profile: 200, 404, and stale-owner cleanup (6.1).

- [ ] Quota: cooldown (V9) and 5-per-24h (V10), including window reset after 24 h.

- [ ] Token creation supersedes older ACTIVE tokens of the same purpose (V5, R7).

- [ ] /tokens/verify: every row of the 6.5 table, plus V4, V7, R3, R5, R6, R8, R9.

- [ ] Each send creates exactly one mail document with the Section 7.1 subject and text.

- [ ] Requests without a valid ID token return 401.

- [ ] Firestore rules deny all client reads and writes (rules unit test).

**App (flutter_test)**

- [ ] Validators match Section 5 exactly (same cases as backend).

- [ ] ProfileController startup produces the states in S1–S6 (mock API and cache).

- [ ] Home shows banner only for ProfileNone / ProfileUnavailable; greeting per 8.4.

- [ ] Profile Setup handles every row of the 8.5 result table.

- [ ] Link Result screen shows the exact title/message/buttons for every row of the 8.9 table.

- [ ] DeepLinkService accepts only the 7.x URI and ignores duplicates.

**Manual on a real Android device**

- [ ] App Links verified (10.4 step 8); tapping the email link in Gmail opens the app.

- [ ] Full flows V1, V2, V3 and R2 work end to end.

- [ ] Offline launch with cache shows the name (S4).

**Email change**

- [ ] Backend: PATCH /profile/email covers every row of the 6.6 table and E1–E11.

- [ ] Backend: after a change, the old emailIndex doc is gone, the new one exists, and all older tokens are SUPERSEDED.

- [ ] App: Change Email dialog handles every row of the 8.11 table; button hidden when verified (E5).

## 12. Out of scope (do not build)

Anything not listed in Sections 1–11 is out of scope. Specifically:

- Login, sign-up, passwords, Google/phone sign-in, or linking the anonymous account to another provider.

- Editing the phone number; deleting or exporting a profile. *(Amended: name, email and city can be edited, §13 D11.)*

- Phone number verification (OTP).

- iOS, web or desktop builds.

- Nitnem content, audio, or progress tracking. *(Amended: restore brings back goals and diary entries, §13 D8.)*

- Push notifications, analytics, crash reporting, App Check, dark-mode work, custom theming. *(Amended: localisation is in scope, §13 D1.)*

- An admin panel or any other UI for the database.

- Firebase Dynamic Links (shut down by Google in August 2025) or any custom URL scheme.

---

## 13. Amendments and decisions

### 13.1 Amendments to the PRD

Decided by the owner on 2026-10-05 and confirmed on 2026-10-07; D7, D9, D10 and D11 were decided on 2026-10-07, D9 and D10 with the Simran spec. Each one is applied in the PRD text above where it says *(Amended)*.

| # | Topic | PRD said | Decision |
|---|---|---|---|
| D1 | Localisation | Out of scope (§0.2, §12) | **Required**: every user-facing string in `pa`, `hi` and `en` (CLAUDE.md rule 5). The PRD's English strings are the `en` source text, used character for character; `pa` and `hi` are added in the ARB files. |
| D2 | Phone number | 10 digits matching `PHONE_REGEX`, stored as `+91` + digits | **No validation and no fixed country code.** Stored normalised: every character that is not a digit is removed, and a leading `+` is kept if typed. |
| D3 | Navigation | Navigator 1.0, named routes, global `navigatorKey` | **Keep go_router.** `pushNamed`, `pushReplacementNamed` and `pushNamedAndRemoveUntil('/', …)` mean go_router's `push`, `pushReplacement` and `go('/')`. Incoming links go through go_router's top-level `redirect`, which is what lets a restore link reach the right screen on a phone that has never been set up. |
| D4 | minSdk | 23 | **24**, as the app is today |
| D5 | Android backup | `allowBackup="false"` | **Leave backup on** (`allowBackup="true"`). Switching it off loses `user.db` (diary, goals, every tick) on uninstall or a new phone. |
| D6 | App Link fingerprints | Debug, upload and Play signing SHA-256 | **Release fingerprint only.** CI keeps no debug keystore, so there is no stable debug fingerprint; a debug install gets no App Link and a tapped link opens a browser. |
| D7 | Launch mode | `singleTop` | **Keep `singleTask`** (decided 2026-10-07), as the app ships it and `test/android/manifest_test.dart` holds it, with the default `taskAffinity` (13.6). A tapped mail link then returns to the running app instead of stacking a new copy on top of it. |
| D8 | Restore | Profile only; no non-profile data (§12) | **Restore brings back goals and diary entries** (completions and simran sittings) as well as the profile. |
| D9 | City | Free text, 2–50 letters | **Chosen from the app's city list** and stored as `cityId`, because the Simran globe needs its position and state (`07-simran.md` §5). Mandatory at creation. It changes only through Edit profile (D11). The request and the DTO carry `cityId` where the PRD says `city`. Somebody whose city is not on the list picks the nearest; cities are added through `tools/content_pipeline/cities.json` (`07-simran.md` S-10). |
| D10 | Attendance | Not in the PRD | **`lastSeenDay`** on the profile, set once a day by `POST /api/v1/presence/attendance` (`07-simran.md` §6.1). That write does not change `updatedAt`, so a daily visit is not mistaken for a profile change. |
| D11 | Editing | Only an unverified email (6.6); everything else out of scope (§12) | **Edit profile: name, email and city.** The phone number is not editable. See 13.8. |
| D12 | Sangat memberships | Not in the PRD | **Profile creation adopts the install's Sangat memberships.** Inside the §6.2 transaction, every membership, contribution and cap the caller's uid made without a profile moves to the new profile (`08-sangat.md` MB2). |

### 13.2 What D8 needs

Goals and diary entries live on the phone (`docs/features/04-goals.md` §5) and reach the cloud only through the planned weekly sync. A restore can bring back only what was synced before the old phone was lost, so:

- The weekly backup (`10-backup.md`) writes `goals`, `goalItems`, `completions` and `simranSessions` under `profiles/{profileId}/` through the `api` Cloud Function.
- After `200 PROFILE_RESTORED` (§6.5) the app offers to download those rows and merge them into `user.db` (`10-backup.md` §4.3 and §8.3).
- The existing diary sync (`lib/features/sync/`, 13.4) writes Firestore directly, which §10.1's deny-all rules forbid. The weekly backup replaces it.
- Anything done after the last weekly sync is not restored. The restore screen must say so rather than imply a complete copy.
- The backup and the download are specified in `10-backup.md`. Until it is built, a restore returns only the profile.

### 13.3 Scope of the rewrite

| # | Decision |
|---|---|
| W1 | The PRD is a **replacement**. Existing account code is removed, not adapted, and rebuilt from the PRD. Unit tests cover the positive **and** the negative path of each rule. |
| W2 | **The sangat comes out entirely** — all code and all logic. A separate PRD will define how it works. |
| W3 | **No existing data is kept.** Firestore holds test documents only; nothing is migrated. |
| W4 | Follow the PRD and nothing else. Do not carry forward the old design's decisions. |
| W5 | **Localisation is required** (`pa`, `hi`, `en`, per rule 5). An updated PRD will carry the strings. |
| W6 | Sending: **Brevo or similar**, to be configured. |
| W7 | Cost model as the PRD states it: accepted. |

### 13.4 What the sangat's removal takes with it

Settled 2026-10-05, question by question:

| Part | Decision |
|---|---|
| **Diary sync** (`lib/features/sync/`, 498 lines) | **Stays** with the sangat's removal, and is then replaced by the weekly backup (`10-backup.md`). |
| **The globe and presence** (Simran tab) | **Comes out.** Separate logic to follow. |
| **The Vichar library** | **Moves behind the new API.** No direct client read survives. |
| **`docs/PRD.md` §8 (then §13.1) and the privacy screen** | **Will change.** The two are one promise and are rewritten together. |
| **Today's banners** (join banner, hazri banner) | Separate logic to follow. |

What this touches outside `lib/features/sangat/` (28 files, 5,352 lines):
`lib/main.dart`, `lib/app/menu_sheet.dart`,
`features/today/ui/today_screen.dart`,
`features/simran/data/simran_controller.dart`,
`features/settings/ui/settings_screen.dart`,
`features/sync/ui/sync_screen.dart`,
`features/about/ui/privacy_screen.dart`, and fifteen test files.

### 13.5 Phone numbers

| # | Decision |
|---|---|
| P1 | **No validation**, for now. No regex, no `libphonenumber`, no country metadata in the APK. The PRD's `PHONE_REGEX = ^[6-9][0-9]{9}$` is dropped. |
| P2 | **Any country code is accepted.** The `+91` prefix is not hard-coded anywhere — not in the field, not in what is stored. |
| P3 | **Stored normalised.** One spelling reaches the server: every character that is not a digit is removed, and a leading `+` is kept if the reader typed one. |

P1 and P3 pull against each other and it is worth being honest about where:
with no validation there is no country to infer, so `9876543210` and
`+919876543210` normalise to two different strings and are two different
accounts. Normalising is still worth doing — it collapses spaces, dashes and
brackets, which is where the same number typed twice usually differs — but
**the phone number is not a reliable key for finding an account** until a
country code is required. Anything that looks up an account by phone has to
treat a miss as "no account found", never as proof there isn't one.

### 13.6 Android

| # | Decision |
|---|---|
| A-1 | `android:taskAffinity` keeps its **default** value (the package name). The attribute is **never set to the empty string**. An empty affinity is what put four Hazri icons in the recents switcher: it means the activity belongs to no task, so every tap of a mail link starts a new one and `launchMode="singleTask"` has nothing to match against. |

`launchMode="singleTask"` (D7) is not the whole story on its own: without
A-1 it has no task to match against, and the affinity is the missing line.

### 13.7 Deliberately untouched

| Area | Decision |
|---|---|
| **Firebase Analytics** | **Do not touch it.** `firebase_analytics: ^12.6.0` stays in `pubspec.yaml`, collection stays off, the inert Settings switch stays. A separate feature document will cover it. |
| **Which parts of the app may require the network** | To be decided later. Until then, **follow the PRD**. |

### 13.8 Edit profile (D11)

**Screen.** `/profile-edit`, opened from the Profile screen in `ProfileLoaded`. App bar `profileEditTitle`. The layout is design 101 (chosen by the owner 2026-10-10):

1. A first card, `profileEditTodayIn` with the city chosen in the field below: today's sunrise and sunset there (`profileEditSunrise`, `profileEditSunset`), worked out on the phone with the same `SolarService` as Today, so it needs no network; the chip `profileEditChangedFrom` with the saved city, shown only while the field differs from the saved city; and `profileEditCityHelp`.
2. A second card with three outlined fields, labels on the border, pre-filled: Name (validated as §5, helper `profileEditNameHelp`), City (the same picker as §8.5) and Email (read-only: the address, a small green verified mark when it is verified, and `profileChangeEmail` inside the same row), with `profileEditEmailHelp` under it. A verified email carries no warning; a pending change shows `profileEmailPending` quietly under the address.
3. Button `profileEditSave` at the foot, enabled only when the name or city differs from the profile.

**Name and city: `PATCH /api/v1/profile`.** Request `{ "name"?: "...", "cityId"?: "..." }`.

1. Validate what is present per §5 → `400 VALIDATION_ERROR` + `fields`.
2. In one transaction: `owners/{callerUid}` missing → `404 NO_PROFILE`. Nothing differs from the stored profile → `400 NOTHING_CHANGED`. Otherwise write the changed fields and `updatedAt`.
3. `200 { "result": "PROFILE_UPDATED", "profile": <DTO> }`. The app calls `setProfile`. A new city shows on the globe from the next snapshot (`07-simran.md` AT5).

**Email.** `profileChangeEmail` opens the Change Email dialog (§8.11).

- **Unverified email:** exactly §6.6, unchanged.
- **Verified email:** the change waits for the new address to be confirmed, so a mistyped address can never take away the one that restores the profile. **(Open, E-1)**
    1. `PATCH /api/v1/profile/email` on a verified profile no longer returns `409 EMAIL_ALREADY_VERIFIED`. It validates and quota-checks as §6.6, then reserves `emailIndex/{newEmailHash}` for this profile (`409 EMAIL_EXISTS` if taken), stores `pendingEmail` and `pendingEmailNormalized` on the profile, supersedes any older `CHANGE_EMAIL` token, and sends template 7.1-A with a token of new purpose `CHANGE_EMAIL` (TTL as `VERIFY_EMAIL`) to the new address. Response `200 { "result": "EMAIL_CHANGE_PENDING", "profile": <DTO>, "cooldownSeconds": 60 }`.
    2. Until the link is opened, `email`, `emailVerified` and restore all stay on the old address.
    3. `POST /api/v1/tokens/verify` with a `CHANGE_EMAIL` token: if it is still the newest and `pendingEmailNormalized` matches, set `email` and `emailNormalized` to the pending address, delete the old `emailIndex` document, clear the pending fields, keep `emailVerified` = true, set `emailVerifiedAt`, supersede every other ACTIVE token, and return `200 { "result": "EMAIL_CHANGED", "purpose": "CHANGE_EMAIL", "isOwner": ..., "profile": <DTO if owner> }`. Expired, used or replaced links behave as §6.5.
    4. A second change request before the first is confirmed releases the first reserved `emailIndex` document and replaces the pending address.
    5. The Profile screen shows `profileEmailPending` with the pending address under the email in the identity card until it is confirmed.

**New profile fields:** `pendingEmail` and `pendingEmailNormalized` (string, nullable, null when nothing is pending). The DTO gains `pendingEmail`.

**Strings:** `profileEditButton` Edit profile · `profileEditTitle` Edit profile · `profileEditSave` Save changes · `profileChangeEmail` Change email · `profileEmailPending` Waiting for you to confirm {email} · `profileUpdated` Profile updated · `profileEditTodayIn` Today in {city} · `profileEditChangedFrom` Changed from {city} · `profileEditSunrise` Sunrise · `profileEditSunset` Sunset · `profileEditCityHelp` Your sunrise times on Today and your dot on the Simran globe follow it. · `profileEditNameHelp` 2 to 50 letters. Spaces, full stops, apostrophes and hyphens are fine. · `profileEditEmailHelp` A new email takes over only once you confirm it from the link we send.

**Profile screen strings (design 100):** `profileYourTitle` Your profile · `profileStatHazriDays` day / days of Hazri · `profileStatInARow` in a row · `profileStatBadges` badge / badges earned · `profilePhoneNotProvided` Phone not provided · `profilePrivacyLine` Your email is never shown to anyone in the app. Your city is one dot on the Simran globe, and nothing finer.

**Scenarios**

| # | Given | When | Then |
| --- | --- | --- | --- |
| P-1 | Profile in Delhi | City changed to Amritsar and saved | `PROFILE_UPDATED`; next globe snapshot counts the person in Amritsar |
| P-2 | Profile | Name changed to one letter | Inline error; nothing sent |
| P-3 | Profile | Save with nothing changed | Button disabled; server would return `NOTHING_CHANGED` |
| P-4 | Unverified email | Email changed | §6.6 as before: changed at once, link to the new address |
| P-5 | Verified email a@x | Change to b@x requested | `EMAIL_CHANGE_PENDING`; email still a@x and verified; b@x reserved; link sent to b@x |
| P-6 | P-5 | Link opened | Email becomes b@x, verified; a@x released |
| P-7 | P-5 | Link never opened; profile restored on a new phone | Restore goes to a@x, which still works |
| P-8 | P-5 | Change to c@x requested before confirming | b@x released; only the c@x link works |
| P-9 | Another profile owns b@x | Change to b@x | `409 EMAIL_EXISTS`; nothing changes |

### 13.9 Settled on 2026-10-07

1. **The `pa` and `hi` strings** are written by the implementer alongside the English, and the owner verifies them before release. `l10n_test.dart` is not relaxed: every key lands in all three languages at once.
2. **The sangat PRD lands before this is built.** No implementation starts until the owner has written the technical specification of every feature (`README.md`, "The order to build in").

### 13.10 Still open

1. **E-1, changing a verified email** (13.8). Default: the change waits until the new address is confirmed, and the old one keeps working for restore until then.
2. **Brevo credentials** (W6). The owner will supply them. Until then: write the sender against Brevo's API with the key read from Secret Manager, so switching it on is configuration rather than code.
