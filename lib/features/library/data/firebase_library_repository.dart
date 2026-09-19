import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/library_entry.dart';
import 'library_repository.dart';

/// The library on Firestore, under `content/`, which the rules make readable
/// by anybody signed in and writable by nobody.
///
/// Entries are fetched once and held for the session: they change when
/// somebody edits the website, not while a person is reading, and a list that
/// re-fetches on every keystroke of the search box would be a bill for
/// nothing.
class FirebaseLibraryRepository implements LibraryRepository {
  FirebaseLibraryRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  List<LibraryEntry>? _cached;

  CollectionReference<Map<String, Object?>> get _entries =>
      _db.collection('content').doc('vichar').collection('entries');

  @override
  Future<List<LibraryEntry>> entries() async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final snap = await _entries.limit(200).get();
      final list = snap.docs
          .map((d) => LibraryEntry.fromFirestore(d.id, d.data()))
          .whereType<LibraryEntry>()
          .toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      _cached = list;
      return list;
    } on FirebaseException catch (e) {
      debugPrint('Hazri: library fetch failed (${e.code})');
      return const [];
    }
  }

  @override
  Future<LibraryEntry?> entry(String id) async {
    final known = _cached?.where((e) => e.id == id).firstOrNull;
    // The list carries the body, so an entry already fetched needs no second
    // read. Only a deep link to something not in the list costs one.
    if (known != null && known.body.isNotEmpty) return known;
    try {
      final doc = await _entries.doc(id).get();
      final data = doc.data();
      if (data == null) return null;
      return LibraryEntry.fromFirestore(doc.id, data);
    } on FirebaseException catch (e) {
      debugPrint('Hazri: library entry $id failed (${e.code})');
      return null;
    }
  }
}
