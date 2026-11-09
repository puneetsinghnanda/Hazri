import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/backend/api_client.dart';
import 'package:hazri/features/backup/data/backup_worker.dart';

import '../profile/profile_fakes.dart';

/// 01-accounts §8.3 R2 in the background worker: a backup's NO_PROFILE
/// clears the profile only when GET /profile says the same.
void main() {
  late FakeServer server;
  late ApiClient api;

  setUp(() {
    server = FakeServer();
    api = ApiClient(auth: FakeAuth(), client: server.client, baseUrl: 'https://test/api/v1');
  });

  test('GET /profile finds it: not gone', () async {
    server.on('GET', '/profile', 200, {'profile': profileJson()});
    expect(await profileGone(api), isFalse);
  });

  test('GET /profile says NO_PROFILE: gone', () async {
    server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
    expect(await profileGone(api), isTrue);
  });

  test('an error or no network is not proof', () async {
    server.on('GET', '/profile', 500, errorJson('INTERNAL'));
    expect(await profileGone(api), isFalse);
    server.offline = true;
    expect(await profileGone(api), isFalse);
  });
}
