# Signing the Android app

The release APK is signed with one keystore, held as four GitHub secrets.
This is how to make it and set them. It is done once.

**Read this first.** The keystore is the one file in this project that
cannot be replaced:

* **Lose it** and the app can never be updated under the same identity.
  Google Play will refuse an upload signed by anything else, and on a phone
  the new APK will not install over the old one.
* **Leak it** and anybody can sign a package that Android, Play and
  `assetlinks.json` all accept as Hazri.

So back it up somewhere that is not only the laptop, and never commit it.
`android/.gitignore` refuses `key.properties`, `*.jks` and `*.keystore`, and
`test/android/manifest_test.dart` asks git what is tracked rather than
trusting the ignore file.

---

## 1. Make the key

Java's `keytool` comes with any JDK, and Android Studio ships one.

```bash
keytool -genkeypair -v \
  -keystore hazri-release.jks \
  -alias hazri \
  -keyalg RSA -keysize 4096 \
  -validity 10000 \
  -storetype PKCS12
```

**If you run this in Cloud Shell**, the file lands in the Cloud Shell home
directory and you have to bring it down yourself:

```bash
cloudshell download hazri-release.jks
```

Cloud Shell's home persists between sessions, which makes it look like a
safe place to leave it. It is not: **Google deletes the home directory after
120 days of inactivity.** Four months of not opening Cloud Shell and the one
irreplaceable file in this project is gone. Download it, back it up, and
treat what stays there as a copy rather than the copy.

**`keytool` writes the file into whatever directory you run it from**, so
run it somewhere deliberate. The repository root is fine — the root
`.gitignore` refuses `*.jks`, `*.keystore` and `key.properties` anywhere in
the tree — but somewhere outside the repository is better, because a file
that is never in the working tree cannot be committed by a mistake.

It asks for a password twice and then for a name and organisation. The
name fields go into the certificate and are visible to anybody who inspects
a signed APK; they are not checked by anyone, so put something true and
unremarkable. Use the **same password** for the store and the key — the
Gradle config supports two, but a second one is a second thing to lose for
no benefit.

`-validity 10000` is about 27 years. Play requires a certificate that
outlives the app; a short one is a cliff nobody sees coming.

**Back the file up now**, before going further. Somewhere that is not only
this laptop: a password manager's file attachment, an encrypted archive in
your own cloud storage, a USB stick in a drawer. Two of those, ideally. The
password goes somewhere separate from the file.

## 2. Turn it into a secret

GitHub secrets hold text, so the keystore travels as base64.

```bash
# Cloud Shell / Linux
base64 -w0 hazri-release.jks > hazri-release.jks.base64
# and then: cloudshell download hazri-release.jks.base64

# macOS
base64 -i hazri-release.jks | tr -d '\n' > hazri-release.jks.base64

# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("hazri-release.jks")) |
  Set-Content hazri-release.jks.base64 -NoNewline
```

The `-w0` and the `tr -d '\n'` do the same job, and it matters: some `base64` builds wrap at 76 columns, and a
wrapped value pasted into a secret decodes to something that is not a
keystore. The workflow runs `keytool -list` on the decoded file for exactly
this reason, so a bad paste fails in one line instead of four screens of
Java.

## 3. Set the four secrets

GitHub → the repository → **Settings → Secrets and variables → Actions →
New repository secret**. Four of them:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | the whole contents of `hazri-release.jks.base64` |
| `ANDROID_KEYSTORE_PASSWORD` | the password from step 1 |
| `ANDROID_KEY_ALIAS` | `hazri` |
| `ANDROID_KEY_PASSWORD` | the same password |

Then delete `hazri-release.jks.base64`. The `.jks` itself stays, backed up.

## 4. Build, and read the fingerprint out of the APK

Actions → Build → **Run workflow**. Two steps in the log matter:

* *Say which key this build is signed with* — it should say the release key.
  If it warns instead, the secret is not set on this repository.
* *Which certificate actually signed it* — prints the SHA-256 that
  `apksigner` reads back out of the built APK.

That second number, not the one `keytool` printed in step 1, is what goes
into `public/.well-known/assetlinks.json` for Android App Links. Reading it
from the artefact rather than the input is the point: a mismatch there fails
link verification **silently** — the link simply opens a browser and nobody
is told why.

## 5. The first install after this

The APK is now signed with a different key from every previous build, so it
will not install over one. **Uninstall the old app once.** That takes
`user.db` with it — the diary, the goals, every tick, and any unverified
anonymous account.

This is the last time that happens. Every build after this one installs over
the last.

---

## Signing locally

Not needed for CI. If you want a locally built APK that installs over a CI
one, put `android/key.properties` beside the keystore:

```properties
storeFile=/absolute/path/to/hazri-release.jks
storePassword=…
keyAlias=hazri
keyPassword=…
```

Gradle picks it up when it exists and falls back to the debug key when it
does not, which is why a fresh clone still builds.

---

## The fingerprint, and where it goes

`public/.well-known/assetlinks.json` carries it, and
`test/android/assetlinks_test.dart` checks the shape — a truncated paste is
still valid JSON and still looks plausible, and **every way of getting this
file wrong fails in silence**: the link opens a browser exactly as it did
before, with no error on the phone and no warning at build time.

The current key, made 2026-09-27, valid to 2054:

```
SHA-256  B3:1B:43:F5:73:9A:8F:DA:DB:E8:20:16:5A:55:8B:5B:83:02:6F:4C:62:D6:0F:83:37:66:E2:8C:AA:FF:D2:F8
SHA-1    AA:79:E1:30:15:EB:64:6A:0F:5F:2C:03:6C:B3:82:BF:2A:68:84:CA
```

A fingerprint is safe to write down and safe to publish — `assetlinks.json`
is served to the whole internet by design. It is the keystore and its
password that are not.

**`assetlinks.json` changes nothing until it is deployed**, by hand:

```bash
firebase deploy --only hosting
```

Then check that Google can read it, which is what Android actually does:

```
https://digitalassetlinks.googleapis.com/v1/statements:list
  ?source.web.site=https://hazri-dfcc1.web.app
  &relation=delegate_permission/common.handle_all_urls
```

A `statements` array naming `app.hazri` means the web half is done. Links
still will not open the app until the manifest declares a matching
intent-filter and the app knows what to do with the link it receives — see
A-3 of the earlier accounts spec (`git show cc1c967:docs/features/01-accounts.md`) and
§7.2–7.3 and §13 D6–D7 of the current one (`docs/features/01-accounts.md`).
