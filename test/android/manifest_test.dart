import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What the merged manifest must and must not carry.
///
/// `flutter_local_notifications` declares **no receivers** in its own
/// manifest — only permissions — so the app has to declare them, and the
/// plugin's README says why in as many words: "so that the plugin can
/// actually show the scheduled notification(s)".
///
/// Hazri declared the boot receiver and not the other one. Every reminder was
/// scheduled correctly, every alarm fired, and each broadcast arrived at a
/// component that did not exist, so nothing was ever shown. `zonedSchedule`
/// threw nothing, the notifications sat in `pendingNotificationRequests()`
/// looking healthy, and four rounds of fixes to the Dart went out before
/// anybody looked at the XML. No widget test can see this, which is exactly
/// why it is a test of the file.
void main() {
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  test('it is XML the manifest merger can parse', () {
    // A double hyphen inside a comment is illegal XML, and the only thing that
    // notices is `:app:processReleaseMainManifest` -- three minutes into a
    // Gradle run, with "Error parsing AndroidManifest.xml" and no line number.
    // Writing a comment with an em-dash habit in it cost exactly one build.
    final comments = RegExp(r'<!--(.*?)-->', dotAll: true)
        .allMatches(manifest)
        .map((m) => m.group(1)!);
    expect(comments, isNotEmpty, reason: 'the regex should find the comments');
    for (final body in comments) {
      expect(
        body,
        isNot(contains('--')),
        reason: 'a comment containing "--" makes the whole file unparseable',
      );
    }

    // And nothing else obviously malformed: every tag opened is closed.
    expect(
      RegExp('<manifest').allMatches(manifest).length,
      RegExp('</manifest>').allMatches(manifest).length,
    );
    expect(
      RegExp('<application').allMatches(manifest).length,
      RegExp('</application>').allMatches(manifest).length,
    );
  });

  group('flutter_local_notifications receivers', () {
    test('the one that shows a scheduled notification is declared', () {
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
        ),
        reason: 'without it no scheduled reminder is ever shown, silently',
      );
    });

    test('and the one that survives a reboot', () {
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver',
        ),
      );
      expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
      expect(manifest, contains('android.intent.action.TIMEZONE_CHANGED'));
    });
  });

  group('permissions', () {
    test('reminders can ask to notify and to be on time', () {
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android.permission.SCHEDULE_EXACT_ALARM'));
    });

    test('USE_EXACT_ALARM stays out: it is for alarm and calendar apps', () {
      expect(manifest, isNot(contains('android.permission.USE_EXACT_ALARM')));
    });

    test('the advertising ID is removed from the merged manifest (PRD 13)', () {
      expect(manifest, contains('com.google.android.gms.permission.AD_ID'));
      expect(manifest, contains('tools:node="remove"'));
    });
  });

  group('the signing key is not in the repository', () {
    // The release keystore is the one file in this project that cannot be
    // replaced. Lose it and the app can never be updated under the same
    // identity again; leak it and anybody can sign a package that Android
    // and `assetlinks.json` will both accept as Hazri.
    //
    // android/.gitignore refuses key.properties, *.jks and *.keystore, but a
    // `git add -f` or a path it does not cover would get past it silently,
    // and the commit that does it will not look like the one that mattered.
    // So this asks git what is actually tracked rather than trusting the
    // ignore file.

    List<String> tracked() {
      final result = Process.runSync('git', ['ls-files']);
      expect(result.exitCode, 0, reason: 'git ls-files failed');
      return (result.stdout as String)
          .split('\n')
          .where((line) => line.isNotEmpty)
          .toList();
    }

    test('no keystore is committed', () {
      final offences = tracked()
          .where((f) =>
              f.endsWith('.jks') ||
              f.endsWith('.keystore') ||
              f.endsWith('key.properties'))
          .toList();

      expect(offences, isEmpty,
          reason: 'a signing key or its passwords are in git: $offences. '
              'Remove it, then treat the key as compromised and make a new '
              'one -- history keeps it even after the file goes.');
    });

    test('no service account is committed either', () {
      // Same class of mistake, different file. A service-account key is
      // admin access to the whole Firebase project.
      final offences = tracked()
          .where((f) =>
              f.contains('service-account') ||
              RegExp(r'(^|/)\.env(\.|$)').hasMatch(f))
          .toList();

      expect(offences, isEmpty, reason: 'a credential file is in git: $offences');
    });
  });

  group('one instance, not four', () {
    // Tapping a verification link once produced four Hazri tasks in the
    // recents switcher, and the instance holding the reader's state was
    // never the one the link was delivered to.
    //
    // An empty taskAffinity means the activity belongs to no task, so every
    // launch from another app with FLAG_ACTIVITY_NEW_TASK -- which is how a
    // mail client opens a link -- starts a fresh one. singleTop only dedupes
    // within a task, so it never got a chance to.
    final xml = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    test('the launcher activity is singleTask', () {
      expect(xml, contains('android:launchMode="singleTask"'),
          reason: 'singleTop is not enough: an externally launched link '
              'lands in a new task, where there is nothing to be on top of');
    });

    test('there is no empty task affinity', () {
      expect(xml, isNot(contains('android:taskAffinity=""')),
          reason: 'no affinity means every external launch makes a task');
    });
  });

  group('App Links, so a verification link can be tapped', () {
    // Four things have to agree before Android will open the app on a link:
    // this filter, assetlinks.json on the host, the certificate the APK was
    // signed with, and the file actually being deployed. Any disagreement
    // fails in complete silence -- the link opens a browser, exactly as it
    // did before, with nothing said anywhere. Three of the four are checked
    // by tests; the deploy is a hand-run and cannot be.

    final xml = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    test('the filter is there and verifies itself', () {
      expect(xml, contains('android:autoVerify="true"'),
          reason: 'without autoVerify Android never fetches assetlinks.json, '
              'so the link is never associated with this app');
    });

    test('both Firebase hosts are declared', () {
      // One Hosting site under two names. A Firebase sign-in link has
      // arrived on each of them at different points in this project, and
      // declaring only one leaves the other opening a browser.
      for (final host in [
        'hazri-dfcc1.web.app',
        'hazri-dfcc1.firebaseapp.com',
      ]) {
        expect(xml, contains('android:host="$host"'), reason: 'missing $host');
      }
    });

    test('Flutter is told to hand the link to the router', () {
      // Without this the intent arrives, the app opens on its usual first
      // screen, and the link it was opened for is dropped.
      expect(xml, contains('flutter_deeplinking_enabled'));
    });

    test('the filter is not narrowed to a path', () {
      // Firebase moved its sign-in links from Dynamic Links onto a Hosting
      // domain in August 2025 and the path changed with it. Anything keyed
      // to a path is a thing that breaks quietly the next time they move it,
      // so IncomingLink reads the URL instead.
      final start = xml.indexOf('android:autoVerify="true"');
      final filter = xml.substring(start, xml.indexOf('</intent-filter>', start));
      expect(filter, isNot(contains('android:path')),
          reason: 'no pathPrefix, pathPattern or path on the App Link filter');
    });
  });
}