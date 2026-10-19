import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Where the last copy of the library is kept on the phone, so Vichar opens
/// with the radio off once it has been fetched (owner, 2026-10-19).
///
/// It holds the API's answer as it came, one JSON string: the entries are
/// published text, not anything the person wrote, so they live in the app's
/// own support directory rather than `user.db`, and the backup leaves them
/// out — a restore fetches them again like any fresh install.
abstract interface class LibraryStore {
  /// The saved answer, or null when there is none or it cannot be read.
  Future<String?> read();

  /// Replaces the saved answer. A failure is logged, never thrown: a phone
  /// that cannot save simply keeps fetching.
  Future<void> write(String json);
}

/// `vichar-entries.json` in the application support directory.
class FileLibraryStore implements LibraryStore {
  const FileLibraryStore();

  Future<File> _file() async =>
      File('${(await getApplicationSupportDirectory()).path}/vichar-entries.json');

  @override
  Future<String?> read() async {
    try {
      final f = await _file();
      return await f.exists() ? await f.readAsString() : null;
    } on Object catch (e) {
      debugPrint('Hazri: saved library unreadable ($e)');
      return null;
    }
  }

  @override
  Future<void> write(String json) async {
    try {
      final f = await _file();
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(json, flush: true);
      await tmp.rename(f.path);
    } on Object catch (e) {
      debugPrint('Hazri: library not saved ($e)');
    }
  }
}

/// A store in memory, for tests and for a build with no file system to use.
class MemoryLibraryStore implements LibraryStore {
  MemoryLibraryStore([this.saved]);

  String? saved;

  @override
  Future<String?> read() async => saved;

  @override
  Future<void> write(String json) async => saved = json;
}
