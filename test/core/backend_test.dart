import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/backend/backend.dart';

/// The server is optional, and these are the tests that keep it that way.
///
/// Phase 2 adds a backend to an app whose whole promise is that it works with
/// the radio off. The risk is not that Firebase breaks — it is that a feature
/// quietly starts assuming it is there, and the app stops opening for
/// somebody on a phone with no Play Services. So the default is offline, and
/// offline is a working app rather than an error.
void main() {
  test('the default backend is offline, so a test never reaches a server', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(backendProvider).isUp, isFalse);
  });

  test('every call on the offline backend succeeds and does nothing', () async {
    const backend = OfflineBackend();

    // No null checks and no try/catch at the call site: that is the point of
    // having an offline implementation rather than a nullable backend.
    await expectLater(backend.start(), completes);
    await expectLater(backend.setAnalyticsEnabled(true), completes);
    expect(backend.isUp, isFalse);
  });

  test('starting the offline backend does not make it claim to be up', () async {
    const backend = OfflineBackend();
    await backend.start();

    expect(backend.isUp, isFalse,
        reason: 'isUp must describe the server, not whether start() was called');
  });
}
