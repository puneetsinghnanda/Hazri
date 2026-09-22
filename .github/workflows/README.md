# Getting a test APK

`build.yml` analyzes, tests and builds on every push, but it **only keeps the
APK when the run was started by hand**. To install the app on a phone:

1. Open the **Actions** tab, pick **Build** in the sidebar, then **Run
   workflow** and choose your branch.
2. When it finishes, open **Releases**: the run publishes a pre-release
   tagged `apk-<branch>` with `app-arm64-v8a-release.apk` attached, replacing
   the previous one for that branch. The same file is also attached to the
   run page as the `hazri-apk-<sha>` artifact, when the quota below allows.
3. Copy `app-arm64-v8a-release.apk` to the phone.
4. On the phone, open the file and allow installing from that source when
   prompted.

A push still builds the APK — that is what catches a Gradle or manifest break
no widget test can see — it simply does not store it. The reason is storage:
the allowance on this plan is 500 MB and one APK is about 95 MiB, so five of
them fill it and every run after that fails at the last step with *Artifact
storage quota has been hit*, which reads like a broken build and is not one.
For the same reason an artifact is kept for **three days**, not thirty; ask for
another run if you need it after that.

The release is why the quota no longer matters for getting a build: release
assets are not counted against it. If the artifact step is refused, the run
still passes and the release still has the APK. Deleting old `hazri-apk-*`
artifacts is still worth doing, but GitHub only recalculates the usage figure
**every 6–12 hours**, so the artifact copy can stay refused for a while after.

The APK is signed with the standard Android debug key, which is fine for
testing and cannot be uploaded to Google Play. A Play build uses Play App
Signing with an upload key kept outside this repository.
