# Getting a test APK

`build.yml` analyzes, tests and builds on every push, but it **only keeps the
APK when the run was started by hand**. To install the app on a phone:

1. Open the **Actions** tab, pick **Build** in the sidebar, then **Run
   workflow** and choose your branch.
2. When it finishes, open **Releases** and take `app-arm64-v8a-release.apk`
   from the pre-release tagged `apk-<branch>`. It is the APK itself, not a
   zip, so a phone can download it straight from that page.
3. Copy it to the phone, open it, and allow installing from that source when
   prompted.

There is a copy attached to the run page as an artifact too, but it is only a
convenience and it is allowed to fail: see below.

A push still builds the APK — that is what catches a Gradle or manifest break
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

The APK is signed with the standard Android debug key, which is fine for
testing and cannot be uploaded to Google Play. A Play build uses Play App
Signing with an upload key kept outside this repository.
