import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The app draws its own header, so the platform must not draw one too.
///
/// The Android 12 splash screen API lives on `Theme.DeviceDefault.DayNight`,
/// and switching the v31 themes to that parent quietly brought an ActionBar
/// with it — every other configuration uses a `NoTitleBar` theme. The result
/// was a second header above every screen, showing `android:label` in the
/// system font over Hazri's own brand bar. Nothing in Dart could see it and no
/// widget test could fail on it.
void main() {
  final res = Directory('android/app/src/main/res');

  List<File> styleFiles() => res
      .listSync()
      .whereType<Directory>()
      .where((d) => d.path.split('/').last.startsWith('values'))
      .map((d) => File('${d.path}/styles.xml'))
      .where((f) => f.existsSync())
      .toList();

  test('no activity theme brings an ActionBar with it', () {
    final files = styleFiles();
    expect(files, isNotEmpty, reason: 'no styles.xml found under $res');

    for (final file in files) {
      final xml = file.readAsStringSync();
      // One <style> block at a time: a file can declare several.
      for (final block in RegExp(r'<style\b[^>]*>.*?</style>', dotAll: true)
          .allMatches(xml)
          .map((m) => m.group(0)!)) {
        final name = RegExp(r'name="([^"]+)"').firstMatch(block)?.group(1) ?? '?';
        final parent = RegExp(r'parent="([^"]+)"').firstMatch(block)?.group(1) ?? '';
        final barless = parent.contains('NoTitleBar') || parent.contains('NoActionBar');
        final suppressed = block.contains('name="android:windowNoTitle">true<') &&
            block.contains('name="android:windowActionBar">false<');

        expect(
          barless || suppressed,
          isTrue,
          reason: '${file.path}: $name inherits $parent, which has an ActionBar, '
              'and does not set windowNoTitle/windowActionBar to turn it off',
        );
      }
    }
  });

  test('a dark phone on Android 12+ still gets the platform splash screen', () {
    // Night mode outranks the version qualifier when Android picks a resource,
    // so values-night/ beats values-v31/ and the splash attributes are lost
    // unless values-night-v31/ exists as well.
    final v31 = File('${res.path}/values-v31/styles.xml');
    final night = File('${res.path}/values-night/styles.xml');
    if (!v31.existsSync() || !night.existsSync()) return;

    final nightV31 = File('${res.path}/values-night-v31/styles.xml');
    expect(
      nightV31.existsSync(),
      isTrue,
      reason: 'values-night/ and values-v31/ both exist, so values-night-v31/ '
          'has to as well',
    );
    expect(
      nightV31.readAsStringSync(),
      contains('windowSplashScreenAnimatedIcon'),
      reason: 'values-night-v31/ should carry the same splash attributes as '
          'values-v31/',
    );
  });
}
