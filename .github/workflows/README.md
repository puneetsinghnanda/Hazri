# Getting a test APK

`build.yml` analyzes, tests and builds on every push **that touches the app**
(see "Which pushes build" below), but it **only keeps the APK when the run was
started by hand**. To install the app on a phone:

1. Open the **Actions** tab, pick **Build** in the sidebar, then **Run
   workflow** and choose your branch.
2. When it finishes, open **Releases** and take `app-arm64-v8a-release.apk`
   from the pre-release tagged `apk-<branch>`. It is the APK itself, not a
   zip, so a phone can download it straight from that page.
3. Copy it to the phone, open it, and allow installing from that source when
   prompted.

There is a copy attached to the run page as an artifact too, but it is only a
convenience and it is allowed to fail: see below.

**Which pushes build** (2026-10-19). Each run is about fifteen minutes and the
account's free Actions minutes are shared, so a push builds only when it
changes something the build reads: `lib/`, `test/`, `android/`, `assets/`,
`content/`, `tools/content_pipeline/`, the pubspec, `analysis_options.yaml`,
`l10n.yaml`, `.metadata`, `build.yml` itself, and the three outside files app
tests open (`firebase.json`, `public/.well-known/`,
`functions/src/notifications/messenger.ts`). A push that changes only the
website, docs, designs, the admin site or the Functions does not build the app
(the Functions have `functions.yml`). Run workflow by hand always builds. If a
test starts reading another file outside those folders, add it to the `paths`
lists in `build.yml`.

A push that touches the app still builds the APK — that is what catches a Gradle or manifest break
no widget test can see — it simply does not store it. The reason is storage:
the allowance on this plan is 500 MB and one APK is about 95 MiB, so five of
them fill it and every run after that fails at the last step with *Artifact
storage quota has been hit*, which reads like a broken build and is not one.
For the same reason an artifact is kept for **three days**, not thirty; ask for
another run if you need it after that.

**Why a release rather than an artifact.** The artifact store on this plan is
500 MB, its usage figure is account-wide rather than per repository, and
GitHub recalculates it only **every 6–12 hours**. So a run could build and
check a perfectly good APK and still be refused at the last step with
*Artifact storage quota has been hit* — which reads like a broken build and is
not one. It happened three times, once after the stored artifacts had already
been cut to a single 94 MiB file. **Release assets are not counted against
that quota at all.** The artifact upload is kept as a convenience and marked
`continue-on-error`, so the quota can no longer fail a build.

The APK is signed with the release key from the four `ANDROID_*` secrets
(`docs/signing.md`), or with a throwaway debug key when they are absent.

## Getting a Play Store bundle

A run started by hand also builds **`app-release.aab`**, the app bundle Google
Play takes, and attaches it to the same `apk-<branch>` pre-release. It is
built only when the release key is present, because Play binds the app to the
first upload key it sees. Its build number (`versionCode`) is the workflow's
run number, so each bundle is higher than the one before and Play never
refuses it as a repeat; the version name still comes from `pubspec.yaml`. The
log step *Build the Play Store bundle* prints the SHA-256 of the key that
signed it: that is the **upload key**. Play re-signs what it ships with its
own app signing key, whose SHA-256 (Play Console -> Setup -> App signing) also
has to go into `public/.well-known/assetlinks.json` and Firebase.
