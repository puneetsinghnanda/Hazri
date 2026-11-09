import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/library/domain/library_entry.dart';
import 'package:hazri/features/library/domain/vichar_picture.dart';

LibraryEntry _e(String label, {String id = 'x'}) =>
    LibraryEntry(id: id, kind: EntryKind.day, title: 't', label: label);

/// Design 122: the picture beside an entry, by its kind of day
/// (docs/vichar-content.md Library).
void main() {
  test('the monthly days are Harmandir Sahib under the moon', () {
    for (final l in ['Masya', 'Puranmashi', 'Sangrand']) {
      expect(vicharPictureFor(_e(l)), VicharPicture.night, reason: l);
    }
  });

  test('the Gurgaddi of Sri Guru Granth Sahib Ji is the palki; '
      'every other Gurgaddi, Prakash and Joti Jot is light', () {
    expect(
      vicharPictureFor(_e('Gurgaddi', id: 'gurta-gaddi-diwas-guru-granth-sahib-ji')),
      VicharPicture.palki,
    );
    for (final l in ['Gurgaddi', 'Prakash Purab', 'Joti Jot']) {
      expect(vicharPictureFor(_e(l, id: 'gurgaddi-purab-guru-angad-dev-ji')),
          VicharPicture.guruLight, reason: l);
    }
  });

  test('Shaheedi and the days in history are the Shaheed Singh; '
      'anything else is the dawn', () {
    expect(vicharPictureFor(_e('Shaheedi')), VicharPicture.shaheed);
    expect(vicharPictureFor(_e('Day in history')), VicharPicture.shaheed);
    for (final l in ['Birth anniversary', 'Jor Mela', 'Festival', 'Special day', '']) {
      expect(vicharPictureFor(_e(l)), VicharPicture.dawn, reason: l);
    }
  });

  test('every picture is a bundled file', () {
    for (final p in VicharPicture.values) {
      expect(File(p.asset).existsSync(), isTrue, reason: p.asset);
    }
  });
}
