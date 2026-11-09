import 'library_entry.dart';

/// The picture beside an entry in the library (design 122, option 1,
/// owner 2026-11-09; docs/vichar-content.md Library).
///
/// Five pictures, bundled in `assets/vichar/`, shared by the kind of day an
/// entry is about rather than drawn for each one: the app fetches no photo,
/// because PRD §8 lists no photo host. Keyed on [LibraryEntry.label], the
/// kind of day as the source writes it.
enum VicharPicture {
  /// Harmandir Sahib at dawn: the default, and the Gurdwaras tile.
  dawn,

  /// Harmandir Sahib under the moon: Masya, Puranmashi, Sangrand.
  night,

  /// Sri Guru Granth Sahib Ji in the palki: the Gurgaddi of the Granth, and
  /// the Guru Sahibans tile.
  palki,

  /// A Guru's figure with light where the face would be (CLAUDE.md rule 3):
  /// Prakash Purab, Joti Jot and the other Gurgaddi days.
  guruLight,

  /// A Shaheed Singh: Shaheedi and the days in history.
  shaheed;

  String get asset => 'assets/vichar/${switch (this) {
        dawn => 'dawn',
        night => 'night',
        palki => 'palki',
        guruLight => 'guru-light',
        shaheed => 'shaheed',
      }}.jpg';
}

VicharPicture vicharPictureFor(LibraryEntry e) => switch (e.label) {
      'Masya' || 'Puranmashi' || 'Sangrand' => VicharPicture.night,
      'Gurgaddi' when e.id.contains('granth') => VicharPicture.palki,
      'Prakash Purab' || 'Joti Jot' || 'Gurgaddi' => VicharPicture.guruLight,
      'Shaheedi' || 'Day in history' => VicharPicture.shaheed,
      _ => VicharPicture.dawn,
    };
