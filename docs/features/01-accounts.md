# 1. User profile: setup, email verification, restore

This file replaces the earlier accounts specification. Sections 0 to 12 are
the owner's PRD, *Feature Document: User Profile — Hazri (Nitnem app)*, dated
28 Sep 2026, converted from the Word document word for word, **with the
owner's amendments of 2026-10-05 and 2026-10-07 applied in place**. Each
amended passage carries a note pointing to **Section 13**, which records every
amendment (D1–D10), the other decisions taken alongside the PRD, and what is
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

2.  **No extra features.** Do not add login, profile editing (other than the email change in 6.6), profile deletion, analytics, iOS support, theming, or any feature not listed. Section 12 lists what is out of scope. *(Amended: localisation is required, §13 D1.)*

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

The app never reads or writes Firestore directly. All data access goes through one HTTPS Cloud Function (api) that uses the Admin SDK; Firestore security rules deny all client access.

```text
[Flutter Android app]
| Firebase Anonymous Auth -> ID token
| HTTPS Authorization: Bearer <ID token>
v
[Firebase Hosting https://{{FIREBASE_PROJECT_ID}}.web.app]
|-- /api/** -> rewrite -> Cloud Function "api" (asia-south1, Express)
|-- /verify -> static fallback page (verify/index.html)
|-- /.well-known/assetlinks.json -> Android App Links verification
v
[Cloud Function "api"] --Admin SDK--> [Firestore (asia-south1)]
|-- writes docs to "mail" collection
v
[Trigger Email extension] --SMTP--> user inbox

User taps link in email -> Android opens app via App Link -> app calls POST /api/v1/tokens/verify
```

### 3.1 Backend stack

- Firebase Cloud Functions 2nd gen, Node.js 20, TypeScript.

- Packages: firebase-functions, firebase-admin, express.

- One exported function: export const api = onRequest({ region: "asia-south1" }, app); where app is the Express app.

- Express routes are mounted with the full /api/v1 prefix (Hosting forwards the full path).

- Firestore in Native mode, location asia-south1.

- Firebase Authentication with only the **Anonymous** provider enabled.

- Email delivery: official Firebase Extension **Trigger Email from Firestore** (firebase/firestore-send-email), collection name mail, configured with {{SMTP_CONNECTION_URI}} and {{EMAIL_FROM}}.

- Firebase Hosting serves the API rewrite, the fallback page and assetlinks.json.

### 3.2 App stack

- Flutter (stable channel), Android only, minSdkVersion 24. *(Amended, §13 D4.)*

- Packages: firebase_core, firebase_auth, http, shared_preferences, app_links, flutter_riverpod.

- State management: Riverpod Notifier / NotifierProvider only.

- Navigation: the app's existing go_router. *(Amended, §13 D3: the PRD's Navigator 1.0 calls below are read as their go_router equivalents.)*

- Firebase configured with FlutterFire CLI (flutterfire configure), producing lib/firebase_options.dart.

## 4. Firestore DB schema

Five collections. Only the Cloud Function writes them. All timestamps are Firestore Timestamp; createdAt/updatedAt use FieldValue.serverTimestamp(), expiry comparisons use Timestamp.now() inside the function.

### 4.1 profiles/{profileId}

profileId = Firestore auto-generated ID.

| Field                    | Type      | Nullable | Rule                                          |
|--------------------------|-----------|----------|-----------------------------------------------|
| profileId                | string    | no       | Same as document ID                           |
| ownerUid                 | string    | no       | Anonymous uid that currently owns the profile |
| name                     | string    | no       | Normalized per Section 5                      |
| email                    | string    | no       | Trimmed, as entered (case kept)               |
| emailNormalized          | string    | no       | Trimmed + lowercased                          |
| phone                    | string    | yes      | Normalised per Section 5 (§13 D2), or null    |
| cityId                   | string    | no       | A city ID from the app's city list (§13 D9). Replaces the free-text city. |
| lastSeenDay              | string    | yes      | IST day of the last attendance; written only by the attendance call, which leaves updatedAt alone (§13 D10) |
| emailVerified            | boolean   | no       | false on create                               |
| emailVerifiedAt          | timestamp | yes      | null until verified                           |
| createdAt                | timestamp | no       | Server timestamp                              |
| updatedAt                | timestamp | no       | Server timestamp on every write               |
| restoredAt               | timestamp | yes      | null; set on each successful restore          |
| emailQuota.lastSentAt    | timestamp | yes      | Last verification or restore email queued     |
| emailQuota.windowStartAt | timestamp | yes      | Start of current 24 h window                  |
| emailQuota.countInWindow | number    | no       | 0 on create                                   |

### 4.2 emailIndex/{emailHash}

Guarantees one profile per email. emailHash = lowercase hex SHA-256 of emailNormalized.

| Field     | Type      | Rule                         |
|-----------|-----------|------------------------------|
| profileId | string    | Profile that owns this email |
| createdAt | timestamp | Server timestamp             |

### 4.3 owners/{uid}

Guarantees one profile per install. Document ID = anonymous uid.

| Field     | Type      | Rule                      |
|-----------|-----------|---------------------------|
| profileId | string    | Profile owned by this uid |
| createdAt | timestamp | Server timestamp          |

### 4.4 verificationTokens/{tokenHash}

tokenHash = lowercase hex SHA-256 of the raw token. The raw token is never stored.

| Field           | Type      | Rule                                  |
|-----------------|-----------|---------------------------------------|
| tokenHash       | string    | Same as document ID                   |
| profileId       | string    | Target profile                        |
| purpose         | string    | VERIFY_EMAIL or RESTORE_PROFILE       |
| requestingUid   | string    | uid that requested the email          |
| emailNormalized | string    | Email the link was sent to            |
| status          | string    | ACTIVE, USED or SUPERSEDED            |
| createdAt       | timestamp | Server timestamp                      |
| expiresAt       | timestamp | now + TTL for the purpose (Section 2) |
| usedAt          | timestamp | null until used                       |
| usedByUid       | string    | null until used                       |

A token is **expired** when Timestamp.now() \>= expiresAt. Status is not changed to express expiry.

### 4.5 mail/{autoId}

Format required by the Trigger Email extension. The function only creates these documents.

| Field           | Type   | Rule                      |
|-----------------|--------|---------------------------|
| to              | string | profile.email (as stored) |
| message.subject | string | From Section 7.1          |
| message.text    | string | From Section 7.1          |
| message.html    | string | From Section 7.1          |

The extension adds a delivery field itself. The app never reads mail.

### 4.6 Indexes (firestore.indexes.json)

```json
{
"indexes": [
{
"collectionGroup": "verificationTokens",
"queryScope": "COLLECTION",
"fields": [
{ "fieldPath": "profileId", "order": "ASCENDING" },
{ "fieldPath": "purpose", "order": "ASCENDING" },
{ "fieldPath": "status", "order": "ASCENDING" }
]
},
{
"collectionGroup": "verificationTokens",
"queryScope": "COLLECTION",
"fields": [
{ "fieldPath": "profileId", "order": "ASCENDING" },
{ "fieldPath": "status", "order": "ASCENDING" }
]
}
],
"fieldOverrides": []
}
```

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

Six endpoints under API_BASE_URL (https://{{FIREBASE_PROJECT_ID}}.web.app/api/v1). All request and response bodies are JSON (Content-Type: application/json).

### 6.0 Common rules

**Authentication middleware (all endpoints):** read header Authorization: Bearer \<idToken\>; verify with admin.auth().verifyIdToken(idToken); set callerUid = decoded.uid. Missing or invalid → 401 UNAUTHENTICATED.

**Error body (every non-2xx):**

```json
{ "error": { "code": "ERROR_CODE", "message": "Human readable text", "fields": { "name": "..." }, "retryAfterSeconds": 42, "purpose": "VERIFY_EMAIL" } }
```

fields only for VALIDATION_ERROR; retryAfterSeconds only for RATE_LIMITED; purpose only for token errors. Omit keys that do not apply.

**Profile DTO (returned wherever profile appears):**

```json
{ "profileId": "abc", "name": "Harpreet Kaur", "email": "Harpreet@Example.com", "phone": "+919876543210", "cityId": "amritsar", "emailVerified": false, "createdAt": "2026-09-28T10:00:00.000Z" }
```

phone may be null. Never return ownerUid, emailNormalized, emailQuota or token data.

**Unexpected exceptions:** log with logger.error, respond 500 INTERNAL with message Something went wrong.

**Email quota check** (used by 6.3 and 6.4, evaluated inside the transaction on the target profile's emailQuota, now = Timestamp.now()):

1.  If lastSentAt != null and now - lastSentAt \< 60 s → 429 RATE_LIMITED, retryAfterSeconds = 60 - elapsed (rounded up).

2.  If windowStartAt == null or now - windowStartAt \>= 86400 s → the new window starts: windowStartAt = now, countInWindow = 1.

3.  Else if countInWindow \>= 5 → 429 RATE_LIMITED, retryAfterSeconds = 86400 - (now - windowStartAt) (rounded up).

4.  Else countInWindow = countInWindow + 1.

5.  Always set lastSentAt = now when the send proceeds.

**Token creation** (used by 6.3 and 6.4): rawToken = crypto.randomBytes(32).toString("base64url") (43 characters); tokenHash = sha256Hex(rawToken); link = VERIFY_LINK_BASE + "?token=" + rawToken. Before creating, in the same transaction, query verificationTokens where profileId == X, purpose == P, status == "ACTIVE" and set each to SUPERSEDED. Only the newest link for a purpose works.

### 6.1 GET /api/v1/profile — read caller's profile (Req 6, 9)

Logic: read owners/{callerUid}. If missing → 404. Else read profiles/{profileId} and return it. If the profile document is missing or its ownerUid != callerUid, delete owners/{callerUid} and return 404.

| Status | Body                                       |
|--------|--------------------------------------------|
| 200    | { "profile": \<Profile DTO\> }             |
| 404    | error NO_PROFILE, message No profile found |
| 401    | error UNAUTHENTICATED                      |

### 6.2 POST /api/v1/profile — create profile (Req 2, 3, 8)

Request: { "name": "...", "email": "...", "phone": "9876543210" \| "" \| null, "cityId": "..." }

Logic:

1.  Normalize and validate per Section 5. Any failure → 400 VALIDATION_ERROR with every failing field in fields (key = field name, value = the Section 5 message).

2.  Compute emailNormalized and emailHash.

3.  In one Firestore transaction: read owners/{callerUid} → exists → 409 PROFILE_ALREADY_EXISTS. Read emailIndex/{emailHash} → exists → 409 EMAIL_EXISTS. Else create profiles/{newId} (Section 4.1 defaults), emailIndex/{emailHash}, owners/{callerUid}.

4.  Return 201 with the new profile (read it back after commit so timestamps are resolved).

| Status    | Body                                                                          |
|-----------|-------------------------------------------------------------------------------|
| 201       | { "profile": \<Profile DTO\> }                                                |
| 400       | error VALIDATION_ERROR + fields                                               |
| 409       | error EMAIL_EXISTS, message An account with this email already exists         |
| 409       | error PROFILE_ALREADY_EXISTS, message A profile already exists on this device |
| 401 / 500 | per 6.0                                                                       |

EMAIL_EXISTS must not return any data of the existing profile.

### 6.3 POST /api/v1/profile/verification-email — send verify link (Req 4)

Request body: {}.

Logic, in one transaction: read owners/{callerUid} → missing → 404 NO_PROFILE. Read the profile. If emailVerified == true → 409 EMAIL_ALREADY_VERIFIED. Run the quota check. Supersede active VERIFY_EMAIL tokens, create the new token doc (purpose VERIFY_EMAIL, requestingUid = callerUid, TTL 86400 s), update emailQuota and updatedAt, create the mail doc with template 7.1-A.

| Status    | Body                                                                                         |
|-----------|----------------------------------------------------------------------------------------------|
| 200       | { "result": "VERIFICATION_EMAIL_SENT", "email": "\<profile.email\>", "cooldownSeconds": 60 } |
| 404       | error NO_PROFILE                                                                             |
| 409       | error EMAIL_ALREADY_VERIFIED, message Your email is already verified                         |
| 429       | error RATE_LIMITED, message Please wait before requesting another email + retryAfterSeconds  |
| 401 / 500 | per 6.0                                                                                      |

### 6.4 POST /api/v1/profile/restore-request — send restore link (Req 8)

Request: { "email": "..." }

Logic:

1.  Validate email per Section 5 → failure → 400 VALIDATION_ERROR (fields.email).

2.  In one transaction: read owners/{callerUid} → exists → 409 DEVICE_HAS_PROFILE. Read emailIndex/{emailHash} → missing → 404 EMAIL_NOT_FOUND. Read the profile. Run the quota check. Supersede active RESTORE_PROFILE tokens for that profile, create the token (purpose RESTORE_PROFILE, requestingUid = callerUid, TTL 3600 s), update emailQuota and updatedAt, create the mail doc with template 7.1-B addressed to the stored profile.email.

| Status    | Body                                                                                    |
|-----------|-----------------------------------------------------------------------------------------|
| 200       | { "result": "RESTORE_EMAIL_SENT", "email": "\<profile.email\>", "cooldownSeconds": 60 } |
| 400       | error VALIDATION_ERROR                                                                  |
| 404       | error EMAIL_NOT_FOUND, message No account found for this email                          |
| 409       | error DEVICE_HAS_PROFILE, message A profile already exists on this device               |
| 429       | error RATE_LIMITED + retryAfterSeconds                                                  |
| 401 / 500 | per 6.0                                                                                 |

### 6.5 POST /api/v1/tokens/verify — consume a link (Req 4, 5, 8)

Request: { "token": "\<rawToken\>" }

Logic:

1.  If token is not a string matching ^\[A-Za-z0-9\_-\]{43}\$ → 400 INVALID_REQUEST.

2.  tokenHash = sha256Hex(token). In one transaction read verificationTokens/{tokenHash}.

3.  Missing, or status == SUPERSEDED → 404 TOKEN_INVALID (include purpose when the doc exists).

4.  Read profiles/{token.profileId} (always exists; no delete feature).

5.  **If purpose == VERIFY_EMAIL:**

    - status == USED: if profile emailVerified == true → 200 EMAIL_ALREADY_VERIFIED; else 409 TOKEN_ALREADY_USED.

    - Expired → 410 TOKEN_EXPIRED.

    - Profile emailNormalized != token.emailNormalized → 404 TOKEN_INVALID.

    - Else set profile emailVerified = true, emailVerifiedAt = serverTimestamp (only if currently null), updatedAt; set token status = USED, usedAt, usedByUid = callerUid. Commit, then return 200 EMAIL_VERIFIED.

    - isOwner = (profile.ownerUid == callerUid). Include profile only when isOwner is true.

6.  **If purpose == RESTORE_PROFILE:**

    - status == USED → 409 TOKEN_ALREADY_USED.

    - Expired → 410 TOKEN_EXPIRED.

    - Profile emailNormalized != token.emailNormalized → 404 TOKEN_INVALID.

    - token.requestingUid != callerUid → 403 RESTORE_WRONG_DEVICE.

    - owners/{callerUid} exists → 409 DEVICE_HAS_PROFILE.

    - Else: oldUid = profile.ownerUid; delete owners/{oldUid}; create owners/{callerUid}; update profile ownerUid = callerUid, emailVerified = true, emailVerifiedAt (only if null), restoredAt, updatedAt; set this token USED, usedAt, usedByUid; set every other ACTIVE token of this profile (any purpose) to SUPERSEDED. Commit, then return 200 PROFILE_RESTORED with profile.

| Status    | Body                                                                                                                    |
|-----------|-------------------------------------------------------------------------------------------------------------------------|
| 200       | { "result": "EMAIL_VERIFIED", "purpose": "VERIFY_EMAIL", "isOwner": true, "profile": \<DTO, only if isOwner\> }         |
| 200       | { "result": "EMAIL_ALREADY_VERIFIED", "purpose": "VERIFY_EMAIL", "isOwner": bool, "profile": \<DTO, only if isOwner\> } |
| 200       | { "result": "PROFILE_RESTORED", "purpose": "RESTORE_PROFILE", "isOwner": true, "profile": \<DTO\> }                     |
| 400       | error INVALID_REQUEST, message Invalid link                                                                             |
| 404       | error TOKEN_INVALID, message This link is invalid or has been replaced by a newer link                                  |
| 409       | error TOKEN_ALREADY_USED, message This link has already been used                                                       |
| 410       | error TOKEN_EXPIRED, message This link has expired                                                                      |
| 403       | error RESTORE_WRONG_DEVICE, message Open this link on the phone where you requested the restore                         |
| 409       | error DEVICE_HAS_PROFILE                                                                                                |
| 401 / 500 | per 6.0                                                                                                                 |

Note: clicking a restore link proves ownership of the email, so it also sets emailVerified = true. After a restore, the old install loses access; its next GET returns 404 (Section 9).

### 6.6 PATCH /api/v1/profile/email — change unverified email (Req 10)

The email can be changed only while emailVerified == false. A successful change also sends a verification link to the new email, so the quota check applies to the change itself.

Request: { "email": "\<new email\>" }

Logic (Firestore transactions must do all reads before any write):

1.  Normalize and validate email per Section 5 → failure → 400 VALIDATION_ERROR (fields.email).

2.  In one transaction, reads: owners/{callerUid} → missing → 404 NO_PROFILE. Read the profile. emailVerified == true → 409 EMAIL_ALREADY_VERIFIED. New emailNormalized equals the profile's emailNormalized → 400 EMAIL_UNCHANGED. Read emailIndex/{newEmailHash} → exists → 409 EMAIL_EXISTS. Run the quota check (6.0). Query all ACTIVE tokens of this profile (any purpose).

3.  Same transaction, writes: delete emailIndex/{oldEmailHash}; create emailIndex/{newEmailHash} (profileId, createdAt); update profile email (trimmed), emailNormalized, emailQuota, updatedAt (emailVerified stays false); set every queried ACTIVE token to SUPERSEDED; create a new VERIFY_EMAIL token for the new email (requestingUid = callerUid, TTL 86400 s); create the mail doc with template 7.1-A addressed to the new email.

4.  Return 200 with the updated profile (read back after commit).

| Status    | Body                                                                             |
|-----------|----------------------------------------------------------------------------------|
| 200       | { "result": "EMAIL_CHANGED", "profile": \<Profile DTO\>, "cooldownSeconds": 60 } |
| 400       | error VALIDATION_ERROR + fields.email                                            |
| 400       | error EMAIL_UNCHANGED, message This is already your email                        |
| 404       | error NO_PROFILE                                                                 |
| 409       | error EMAIL_ALREADY_VERIFIED, message A verified email can't be changed          |
| 409       | error EMAIL_EXISTS, message An account with this email already exists            |
| 429       | error RATE_LIMITED + retryAfterSeconds                                           |
| 401 / 500 | per 6.0                                                                          |

The old email is released at once: another install may create a profile with it. Links sent to the old email stop working (superseded, and 6.5 checks emailNormalized).

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

```json
[
{
"relation": ["delegate_permission/common.handle_all_urls"],
"target": {
"namespace": "android_app",
"package_name": "{{ANDROID_PACKAGE_NAME}}",
"sha256_cert_fingerprints": ["<release signing SHA-256>"]
}
}
]
```

*(Amended: only the release signing fingerprint is published, §13 D6.)*

### 7.3 Android intent filter (inside the main \<activity\> of AndroidManifest.xml)

```xml
<meta-data android:name="flutter_deeplinking_enabled" android:value="false" />
<intent-filter android:autoVerify="true">
<action android:name="android.intent.action.VIEW" />
<category android:name="android.intent.category.DEFAULT" />
<category android:name="android.intent.category.BROWSABLE" />
<data android:scheme="https" android:host="{{FIREBASE_PROJECT_ID}}.web.app" android:pathPrefix="/verify" />
</intent-filter>
```

The main activity keeps android:launchMode="singleTask" and the default taskAffinity. The \<application\> tag keeps android:allowBackup="true". *(Amended, §13 D5 and D7.)*

### 7.4 Browser fallback page (hosting/public/verify/index.html)

Shown only when Android does not hand the link to the app (app not installed, or link opened on a computer). It never calls the API.

- Title and heading: Open this link in the app

- Paragraph: Open this link on the Android phone where the app is installed.

- Button Open in app: href is built by inline JavaScript from location.search as intent://{{FIREBASE_PROJECT_ID}}.web.app/verify\<location.search\>#Intent;scheme=https;package={{ANDROID_PACKAGE_NAME}};end.

- Link Get the app on Google Play → https://play.google.com/store/apps/details?id={{ANDROID_PACKAGE_NAME}}.

- Self-contained HTML, inline CSS, no external resources.

## 8. Flutter app implementation

The app keeps one Riverpod ProfileController as the only source of profile state; every screen reads it, and only the flows below change it.

### 8.1 File structure

```text
lib/
main.dart # init Firebase, ProviderScope, MaterialApp, routes, navigatorKey
firebase_options.dart # generated by flutterfire configure
config/app_config.dart # Section 2 values
models/profile.dart # Profile (fromJson/toJson of Profile DTO)
models/api_exception.dart # ApiException, NetworkException
validation/validators.dart # Section 5
services/auth_service.dart # ensureSignedIn(), getIdToken()
services/api_client.dart # HTTP + auth header + 401 retry + timeout
services/profile_api.dart # one method per endpoint in Section 6
services/profile_cache.dart # shared_preferences read/write/clear
services/deep_link_service.dart # app_links listener -> navigation
state/profile_controller.dart # ProfileState + ProfileController (Notifier)
screens/home_screen.dart
screens/profile_setup_screen.dart
screens/profile_screen.dart
screens/email_sent_screen.dart
screens/link_result_screen.dart
widgets/profile_banner.dart
widgets/change_email_dialog.dart
util/messages.dart # shared error strings (8.10)

functions/src/
index.ts app.ts config.ts auth.ts errors.ts validation.ts quota.ts tokens.ts email.ts routes/profile.ts routes/tokens.ts

hosting/public/
.well-known/assetlinks.json verify/index.html
```

Named routes: / HomeScreen, /profile-setup ProfileSetupScreen, /profile ProfileScreen, /email-sent EmailSentScreen (argument EmailSentArgs{purpose, email, cooldownSeconds}), /link-result LinkResultScreen (argument String token).

### 8.2 Services and local cache

**AuthService.ensureSignedIn():** if FirebaseAuth.instance.currentUser == null, call signInAnonymously(). Called before every API request. **getIdToken(forceRefresh)** returns currentUser!.getIdToken(forceRefresh).

**ApiClient.request(method, path, body):**

1.  ensureSignedIn(), then get the ID token.

2.  Send with headers Authorization: Bearer \<token\> and Content-Type: application/json, timeout 15 s.

3.  On 401: get token with forceRefresh: true, retry once. A second 401 throws ApiException.

4.  2xx → return decoded JSON. Non-2xx → throw ApiException(statusCode, code, message, fields, retryAfterSeconds, purpose) parsed from the error body.

5.  SocketException, TimeoutException, http.ClientException, or FirebaseAuthException with code network-request-failed → throw NetworkException.

6.  No other automatic retries.

**ProfileCache** (shared_preferences key profile_cache_v1), value = JSON of the Profile DTO plus ownerUid:

- write(profile): stores DTO + ownerUid = currentUser.uid.

- read(): returns null and deletes the key if missing, not valid JSON, or ownerUid != currentUser?.uid.

- clear(): removes the key.

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

- ProfileLoaded → rows: Name, Email, Phone (value or Not provided), City, Email status = Verified (green, Icons.verified) or Not verified (orange). While a refresh is running show a LinearProgressIndicator at the top.

  - isStale == true after the refresh finished → banner text Showing saved details. Couldn't refresh your email status. with button Retry → refresh().

  - emailVerified == false → button Confirm my email → POST /profile/verification-email: 200 → /email-sent (VERIFY_EMAIL); 409 EMAIL_ALREADY_VERIFIED → refresh(); 429 → rate-limit SnackBar; 404 NO_PROFILE → markNone(); network/other → matching SnackBar.

- ProfileNone → text No profile found and button Set up profile → /profile-setup.

- ProfileUnavailable → text Couldn't load your profile. with buttons Retry (→ refresh()) and Set up profile (→ /profile-setup).

**Change email (Req 10):** when ProfileLoaded and emailVerified == false, show a TextButton labelled Change email directly under the Email row. It opens the Change Email dialog (8.11). Hidden when the email is verified.

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

```text
rules_version = '2';
service cloud.firestore {
match /databases/{database}/documents {
match /{document=**} {
allow read, write: if false;
}
}
}
```

### 10.2 firebase.json

The ignore list must not contain \*\*/.\*, otherwise .well-known/assetlinks.json is not deployed.

```json
{
"firestore": { "rules": "firestore.rules", "indexes": "firestore.indexes.json" },
"functions": [{ "source": "functions", "codebase": "default", "runtime": "nodejs20" }],
"hosting": {
"public": "hosting/public",
"ignore": ["firebase.json", "**/node_modules/**"],
"rewrites": [
{ "source": "/api/**", "function": { "functionId": "api", "region": "asia-south1" } },
{ "source": "/verify", "destination": "/verify/index.html" }
],
"headers": [
{ "source": "/.well-known/assetlinks.json", "headers": [{ "key": "Content-Type", "value": "application/json" }] }
]
}
}
```

### 10.3 Android build settings

- android/app/build.gradle(.kts): minSdk = 24; applicationId = "{{ANDROID_PACKAGE_NAME}}". *(Amended, §13 D4.)*

- AndroidManifest.xml: \<uses-permission android:name="android.permission.INTERNET" /\>, android:allowBackup="true", plus Section 7.3. *(Amended, §13 D5.)*

### 10.4 Deployment steps (developer, in this order)

1.  Create the Firebase project; set Firestore location asia-south1; enable Authentication → Anonymous.

2.  Upgrade to the Blaze plan (required for Cloud Functions and extensions).

3.  Install extension firebase/firestore-send-email: collection mail, SMTP URI {{SMTP_CONNECTION_URI}}, default FROM {{EMAIL_FROM}}.

4.  Run flutterfire configure for Android.

5.  Fill assetlinks.json fingerprints (./gradlew signingReport for debug/upload; Play Console → App integrity for Play signing).

6.  firebase deploy --only firestore,functions,hosting.

7.  Check https://{{FIREBASE_PROJECT_ID}}.web.app/.well-known/assetlinks.json returns the JSON.

8.  Install the app and run adb shell pm get-app-links {{ANDROID_PACKAGE_NAME}}; the host must show verified.

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

- Editing a profile other than the email change in 6.6; deleting or exporting a profile; changing an email that is already verified.

- Phone number verification (OTP).

- iOS, web or desktop builds.

- Nitnem content, audio, or progress tracking. *(Amended: restore brings back goals and diary entries, §13 D8.)*

- Push notifications, analytics, crash reporting, App Check, dark-mode work, custom theming. *(Amended: localisation is in scope, §13 D1.)*

- An admin panel or any other UI for the database.

- Firebase Dynamic Links (shut down by Google in August 2025) or any custom URL scheme.

---

## 13. Amendments and decisions

### 13.1 Amendments to the PRD

Decided by the owner on 2026-10-05 and confirmed on 2026-10-07; D7, D9 and D10 were decided on 2026-10-07, the last two with the Simran spec. Each one is applied in the PRD text above where it says *(Amended)*.

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
| D9 | City | Free text, 2–50 letters | **Chosen from the app's city list** and stored as `cityId`, because the Simran globe needs its position and state (`07-simran.md` §5). Mandatory at creation. It changes only when the profile is updated, which today means never: §12 has no profile editing beyond the email. The request and the DTO carry `cityId` where the PRD says `city`. Somebody whose city is not on the list picks the nearest (open: `07-simran.md` S-10). |
| D10 | Attendance | Not in the PRD | **`lastSeenDay`** on the profile, set once a day by `POST /api/v1/presence/attendance` (`07-simran.md` §6.1). That write does not change `updatedAt`, so a daily visit is not mistaken for a profile change. |

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
| **`docs/PRD.md` §13.1 and the privacy screen** | **Will change.** The two are one promise and are rewritten together. |
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

### 13.8 Settled on 2026-10-07

1. **The `pa` and `hi` strings** are written by the implementer alongside the English, and the owner verifies them before release. `l10n_test.dart` is not relaxed: every key lands in all three languages at once.
2. **The sangat PRD lands before this is built.** No implementation starts until the owner has written the technical specification of every feature (`README.md`, "The order to build in").

### 13.9 Still open

1. **Brevo credentials** (W6). The owner will supply them. Until then: write the sender against Brevo's API with the key read from Secret Manager, so switching it on is configuration rather than code.
