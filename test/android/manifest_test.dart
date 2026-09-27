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
}