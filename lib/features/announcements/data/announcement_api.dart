import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/api_client.dart';

/// One announcement as the app shows it (02-notifications AN4).
@immutable
class Announcement {
  const Announcement({required this.id, required this.title, required this.message, this.createdAt});

  final String id;
  final String title;

  /// Short formatting the admin editor writes: **bold**, *italic*, lines
  /// that start "- " as bullets, and [text](https://...) links.
  final String message;
  final DateTime? createdAt;
}

class AnnouncementApi {
  AnnouncementApi(this._api);
  final ApiClient _api;

  Future<Announcement> fetch(String id, String lang) async {
    final j = await _api.get('/announcements/${Uri.encodeComponent(id)}', query: {'lang': lang});
    return Announcement(
      id: '${j['id']}',
      title: '${j['title'] ?? ''}',
      message: '${j['message'] ?? ''}',
      createdAt: DateTime.tryParse('${j['createdAt']}')?.toLocal(),
    );
  }

  /// AN5: the tap report, with a profile only; once per profile on the server.
  Future<void> opened(String id) => _api.post('/announcements/${Uri.encodeComponent(id)}/opened');
}

final announcementApiProvider = Provider<AnnouncementApi>((ref) => AnnouncementApi(ref.watch(apiClientProvider)));
