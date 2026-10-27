import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'content_db.g.dart';

/// Where a bani sits in the day.
enum BaniSlot { morning, evening, bedtime, none }

/// What a line is: a heading, the mangal, a verse, a rahao line or an ending.
enum LineKind { heading, mangal, verse, rahao, end }

@DataClassName('SourceRow')
class Sources extends Table {
  @override
  String get tableName => 'source';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get author => text().nullable()();
  TextColumn get kind => text()();
  TextColumn get licence => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get publisher => text().nullable()();
  TextColumn get pubDate => text().named('pub_date').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BaniRow')
class Banis extends Table {
  @override
  String get tableName => 'bani';

  TextColumn get id => text()();
  TextColumn get slug => text()();
  TextColumn get nameEn => text().named('name_en')();
  TextColumn get namePa => text().named('name_pa')();
  TextColumn get nameHi => text().named('name_hi')();
  TextColumn get category => text()();
  TextColumn get defaultSlot => text().named('default_slot')();
  IntColumn get sort => integer()();
  IntColumn get estMinutes => integer().named('est_minutes')();
  TextColumn get authorEn => text().named('author_en').nullable()();
  BoolColumn get hasText => boolean().named('has_text')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BaniVersionRow')
class BaniVersions extends Table {
  @override
  String get tableName => 'bani_version';

  TextColumn get id => text()();
  TextColumn get baniId => text().named('bani_id')();
  TextColumn get code => text()();
  TextColumn get labelEn => text().named('label_en').nullable()();
  TextColumn get labelPa => text().named('label_pa').nullable()();
  TextColumn get labelHi => text().named('label_hi').nullable()();
  BoolColumn get isDefault => boolean().named('is_default')();
  IntColumn get lineCount => integer().named('line_count')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LineRow')
class Lines extends Table {
  @override
  String get tableName => 'line';

  IntColumn get id => integer()();
  TextColumn get baniVersionId => text().named('bani_version_id')();
  IntColumn get idx => integer()();
  TextColumn get sectionLabelEn => text().named('section_label_en').nullable()();
  TextColumn get sectionLabelPa => text().named('section_label_pa').nullable()();
  TextColumn get sectionLabelHi => text().named('section_label_hi').nullable()();
  TextColumn get kind => text()();
  TextColumn get gurmukhi => text()();
  TextColumn get devanagari => text()();
  TextColumn get roman => text()();
  TextColumn get visraamJson => text().named('visraam_json').nullable()();
  IntColumn get wordCount => integer().named('word_count')();
  BoolColumn get wordAlign => boolean().named('word_align')();
  TextColumn get sourceId => text().named('source_id').nullable()();
  TextColumn get sourceRef => text().named('source_ref').nullable()();
  IntColumn get pauri => integer().nullable()();
  BoolColumn get endsPauri => boolean().named('ends_pauri').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MeaningRow')
class Meanings extends Table {
  @override
  String get tableName => 'meaning';

  IntColumn get lineId => integer().named('line_id')();
  TextColumn get lang => text()();
  // Named `body` because a getter called `text` would shadow drift's own
  // `text()` column builder.
  TextColumn get body => text().named('text')();
  TextColumn get sourceId => text().named('source_id').nullable()();
  BoolColumn get isAlt => boolean().named('is_alt')();
  TextColumn get kind => text()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {lineId, lang, isAlt};
}

@DataClassName('VoiceRow')
class Voices extends Table {
  @override
  String get tableName => 'voice';

  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get creditEn => text().named('credit_en').nullable()();
  TextColumn get creditPa => text().named('credit_pa').nullable()();
  TextColumn get creditHi => text().named('credit_hi').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AudioTrackRow')
class AudioTracks extends Table {
  @override
  String get tableName => 'audio_track';

  TextColumn get id => text()();
  TextColumn get baniVersionId => text().named('bani_version_id')();
  TextColumn get voiceId => text().named('voice_id').nullable()();
  TextColumn get pack => text()();
  TextColumn get file => text()();
  IntColumn get durationMs => integer().named('duration_ms').nullable()();
  IntColumn get bytes => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TimingRow')
class Timings extends Table {
  @override
  String get tableName => 'timing';

  TextColumn get audioTrackId => text().named('audio_track_id')();
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {audioTrackId};
}

/// One line of Gurbani a day, with its meaning (PRD 1.11).
///
/// [idx] is the position in the cycle, not an Ang: this dataset carries no Ang
/// numbers, and the app does not invent one.
@DataClassName('VicharRow')
class Vichars extends Table {
  @override
  String get tableName => 'vichar';

  IntColumn get idx => integer()();
  TextColumn get gurmukhi => text()();
  TextColumn get meaningPa => text().named('meaning_pa')();
  TextColumn get meaningEn => text().named('meaning_en')();

  @override
  Set<Column> get primaryKey => {idx};
}

/// The Naam Simran recitation. Not a bani, so it has no bani_version and does
/// not belong in [AudioTracks]; its json carries the shape the Simran ring
/// follows (PRD 1.13).
@DataClassName('SimranTrackRow')
class SimranTracks extends Table {
  @override
  String get tableName => 'simran_track';

  TextColumn get id => text()();
  TextColumn get file => text()();
  IntColumn get durationMs => integer().named('duration_ms').nullable()();
  IntColumn get bytes => integer().nullable()();
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NanakshahiMonthRow')
class NanakshahiMonths extends Table {
  @override
  String get tableName => 'nanakshahi_month';

  IntColumn get nsYear => integer().named('ns_year')();
  IntColumn get idx => integer()();
  TextColumn get nameEn => text().named('name_en')();
  TextColumn get namePa => text().named('name_pa')();
  TextColumn get nameHi => text().named('name_hi')();
  TextColumn get startDate => text().named('start_date')();
  IntColumn get days => integer()();

  @override
  Set<Column> get primaryKey => {nsYear, idx};
}

@DataClassName('CalendarEventRow')
class CalendarEvents extends Table {
  @override
  String get tableName => 'calendar_event';

  TextColumn get id => text()();
  IntColumn get nsYear => integer().named('ns_year')();
  TextColumn get date => text()();
  TextColumn get kind => text()();
  TextColumn get nameEn => text().named('name_en')();

  /// Null where the bundled calendar has no reviewed name in that language.
  ///
  /// The supplied calendar is English, and ten events carry Punjabi from the
  /// earlier partial jantri. Nothing is machine-translated to fill the rest,
  /// so the reader falls back to English -- the rule the meanings follow.
  TextColumn get namePa => text().named('name_pa').nullable()();
  TextColumn get nameHi => text().named('name_hi').nullable()();
  TextColumn get nsLabel => text().named('ns_label').nullable()();
  BoolColumn get defaultRemind => boolean().named('default_remind')();

  /// The source marks this entry as its own cross-check rather than something
  /// the SGPC jantri confirms, so the app says so instead of implying it.
  BoolColumn get supplementary => boolean().named('supplementary')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CityRow')
class Cities extends Table {
  @override
  String get tableName => 'city';

  TextColumn get id => text()();
  TextColumn get nameEn => text().named('name_en')();
  TextColumn get namePa => text().named('name_pa')();
  TextColumn get nameHi => text().named('name_hi')();
  TextColumn get countryCode => text().named('country_code')();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get tz => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('QuoteRow')
class Quotes extends Table {
  @override
  String get tableName => 'quote';

  TextColumn get id => text()();
  TextColumn get gurmukhi => text()();
  TextColumn get devanagari => text()();
  TextColumn get roman => text()();
  TextColumn get attributionEn => text().named('attribution_en').nullable()();
  TextColumn get attributionPa => text().named('attribution_pa').nullable()();
  TextColumn get attributionHi => text().named('attribution_hi').nullable()();
  TextColumn get sourceId => text().named('source_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MetaRow')
class Metas extends Table {
  @override
  String get tableName => 'meta';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// The bundled, read-only content database.
///
/// It is built by `tools/content_pipeline` and shipped in `assets/content/`,
/// then copied into app storage on first run and whenever `content_version`
/// changes, because SQLite cannot read directly from the asset bundle.
@DriftDatabase(
  tables: [
    Sources,
    Banis,
    BaniVersions,
    Lines,
    Meanings,
    Voices,
    AudioTracks,
    Timings,
    SimranTracks,
    Vichars,
    NanakshahiMonths,
    CalendarEvents,
    Cities,
    Quotes,
    Metas,
  ],
)
class ContentDb extends _$ContentDb {
  ContentDb(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // The file always arrives fully built, so drift must not try to create or
    // alter anything in it.
    onCreate: (m) async {},
    onUpgrade: (m, from, to) async {},
    beforeOpen: (details) async {
      await customStatement('PRAGMA query_only = ON');
    },
  );

  /// The content version baked in by the pipeline.
  static const int expectedVersion = 11;

  /// Copies `assets/content/content.db` into app storage if it is missing or
  /// out of date, and returns the opened database.
  static Future<ContentDb> open() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'content.db'));
    final stamp = File(p.join(dir.path, 'content.version'));

    final installed = stamp.existsSync() ? stamp.readAsStringSync().trim() : '';
    if (!file.existsSync() || installed != '$expectedVersion') {
      final bytes = await rootBundle.load('assets/content/content.db');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await stamp.writeAsString('$expectedVersion', flush: true);
    }
    // Queries run on a background isolate so a 385-line bani never blocks a
    // frame (PRD §13, 60 fps reader scroll).
    return ContentDb(NativeDatabase.createInBackground(file));
  }
}
