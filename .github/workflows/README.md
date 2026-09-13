# Getting a test APK

`build.yml` runs on every push. To install the app on a phone:

1. Open the **Actions** tab, pick the newest run of **Build** on your branch.
2. Download the `hazri-apk-<sha>` artifact at the bottom of the run page.
3. Unzip it and copy `app-arm64-v8a-release.apk` to the phone.
4. On the phone, open the file and allow installing from that source when
   prompted.

The APK is signed with the standard Android debug key, which is fine for
testing and cannot be uploaded to Google Play. A Play build uses Play App
Signing with an upload key kept outside this repository.
