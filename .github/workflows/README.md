# Getting a test APK

`build.yml` analyzes, tests and builds on every push, but it **only keeps the
APK when the run was started by hand**. To install the app on a phone:

1. Open the **Actions** tab, pick **Build** in the sidebar, then **Run
   workflow** and choose your branch.
2. When it finishes, download the `hazri-apk-<sha>` artifact at the bottom of
   the run page.
3. Unzip it and copy `app-arm64-v8a-release.apk` to the phone.
4. On the phone, open the file and allow installing from that source when
   prompted.

A push still builds the APK — that is what catches a Gradle or manifest break
no widget test can see — it simply does not store it. The reason is storage:
the allowance on this plan is 500 MB and one APK is about 95 MiB, so five of
them fill it and every run after that fails at the last step with *Artifact
storage quota has been hit*, which reads like a broken build and is not one.
For the same reason an artifact is kept for **three days**, not thirty; ask for
another run if you need it after that.

If a hand-started run does fail on the quota, delete some of the older
`hazri-apk-*` artifacts from their run pages — but note that GitHub only
recalculates the usage figure **every 6–12 hours**, so a build attempted right
after deleting can still be refused.

The APK is signed with the standard Android debug key, which is fine for
testing and cannot be uploaded to Google Play. A Play build uses Play App
Signing with an upload key kept outside this repository.
