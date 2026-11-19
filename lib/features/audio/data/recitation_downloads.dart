import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/backend/backend.dart';
import '../../../core/db/content_db.dart' show AudioTrackRow;

/// Where a downloaded recitation is kept for good. Overridden in tests.
final recitationDirProvider = FutureProvider<Directory>((ref) async {
  final support = await getApplicationSupportDirectory();
  final dir = Directory('${support.path}/recitations');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
});

/// The client the downloads use. Overridden in tests.
final recitationHttpProvider = Provider<http.Client>((ref) => http.Client());

/// Where a recitation that is not in the APK is fetched from (PRD §8,
/// owner 2026-11-19): the Hazri website, `public/audio/` in the repository.
String recitationUrl(String file) => '$kSiteBase/audio/$file';

/// One downloadable recitation's state on this phone.
@immutable
sealed class RecitationState {
  const RecitationState();
}

class RecitationMissing extends RecitationState {
  const RecitationMissing();
}

class RecitationDownloading extends RecitationState {
  const RecitationDownloading(this.received, this.total);
  final int received;
  final int total;
  double get fraction => total <= 0 ? 0 : (received / total).clamp(0, 1);
}

class RecitationReady extends RecitationState {
  const RecitationReady(this.path);
  final String path;
}

class RecitationFailed extends RecitationState {
  const RecitationFailed({this.offline = false});

  /// No connection at all, rather than a download that broke off.
  final bool offline;
}

final recitationDownloadsProvider =
    NotifierProvider<RecitationDownloads, Map<String, RecitationState>>(RecitationDownloads.new);

/// Recitations the app downloads once rather than ships (Sukhmani Sahib,
/// owner 2026-11-19; Sehaj Paath later): fetched from the website, checked
/// against the SHA-256 in content.db, and then kept on the phone for good,
/// so every play after the first needs no connection. Nothing about the
/// person is sent: it is a plain request for the file.
class RecitationDownloads extends Notifier<Map<String, RecitationState>> {
  final _cancelled = <String>{};
  final _running = <String, Future<String?>>{};

  @override
  Map<String, RecitationState> build() => const {};

  void _set(String file, RecitationState s) => state = {...state, file: s};

  RecitationState of(AudioTrackRow row) => state[row.file] ?? const RecitationMissing();

  /// The kept file when it is complete, else null. A file of the wrong size
  /// is treated as not there: the download wrote to a `.part` first, so a
  /// complete-looking name is a complete file.
  Future<String?> readyPath(AudioTrackRow row) async {
    final dir = await ref.read(recitationDirProvider.future);
    final f = File('${dir.path}/${row.file}');
    if (f.existsSync() && (row.bytes == null || f.lengthSync() == row.bytes)) {
      if (state[row.file] is! RecitationReady) _set(row.file, RecitationReady(f.path));
      return f.path;
    }
    return null;
  }

  /// Downloads [row] if it is not here yet; the path, or null when it could
  /// not be had. A second call while one runs waits for the first.
  Future<String?> download(AudioTrackRow row) {
    // A block, not an arrow: `remove` returns this very future, and
    // whenComplete would wait for it, so the download would wait on itself.
    return _running[row.file] ??= _download(row).whenComplete(() {
      _running.remove(row.file);
    });
  }

  void cancel(AudioTrackRow row) => _cancelled.add(row.file);

  Future<String?> _download(AudioTrackRow row) async {
    final have = await readyPath(row);
    if (have != null) return have;
    _cancelled.remove(row.file);
    final dir = await ref.read(recitationDirProvider.future);
    final part = File('${dir.path}/${row.file}.part');
    final total = row.bytes ?? 0;
    _set(row.file, RecitationDownloading(0, total));
    IOSink? sink;
    try {
      final res = await ref.read(recitationHttpProvider).send(http.Request('GET', Uri.parse(recitationUrl(row.file))));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      sink = part.openWrite();
      var received = 0;
      final digest = AccumulatorSink<Digest>();
      final hasher = sha256.startChunkedConversion(digest);
      await for (final chunk in res.stream) {
        if (_cancelled.contains(row.file)) throw const _Cancelled();
        sink.add(chunk);
        hasher.add(chunk);
        received += chunk.length;
        _set(row.file, RecitationDownloading(received, total == 0 ? res.contentLength ?? 0 : total));
      }
      await sink.close();
      sink = null;
      hasher.close();
      final sum = digest.events.single.toString();
      if (row.sha256 != null && sum != row.sha256) throw StateError('checksum $sum');
      final kept = part.renameSync('${dir.path}/${row.file}');
      _set(row.file, RecitationReady(kept.path));
      return kept.path;
    } on _Cancelled {
      _set(row.file, const RecitationMissing());
    } on SocketException {
      _set(row.file, const RecitationFailed(offline: true));
    } on http.ClientException {
      _set(row.file, const RecitationFailed(offline: true));
    } on Object catch (e) {
      debugPrint('Hazri: recitation download failed ($e)');
      _set(row.file, const RecitationFailed());
    } finally {
      await sink?.close();
      if (part.existsSync()) part.deleteSync();
    }
    return null;
  }

  /// On Wi-Fi, fetches every downloadable recitation not yet here, quietly,
  /// so most people find it ready the first time they press play.
  Future<void> fetchOnWifi(List<ConnectivityResult> network, Iterable<AudioTrackRow> rows) async {
    if (!network.contains(ConnectivityResult.wifi) && !network.contains(ConnectivityResult.ethernet)) return;
    for (final row in rows.where((r) => r.pack == 'download')) {
      if (await readyPath(row) == null && state[row.file] is! RecitationDownloading) {
        await download(row);
      }
    }
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}

/// Collects the digest a chunked conversion produces.
class AccumulatorSink<T> implements Sink<T> {
  final events = <T>[];
  @override
  void add(T event) => events.add(event);
  @override
  void close() {}
}
