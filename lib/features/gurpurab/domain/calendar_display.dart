import '../../../core/db/content_db.dart';
import '../../../core/l10n/gen/app_localizations.dart';

/// How a calendar event reads on screen.
///
/// The bundled calendar is English with Punjabi on ten of its events (PRD
/// 1.14). Nothing is machine-translated to cover the rest, so a name missing
/// in the reader's language falls back to English rather than being invented
/// or left blank -- the same rule the meanings follow.
extension CalendarEventDisplay on CalendarEventRow {
  String nameFor(String lang) => switch (lang) {
        'pa' => namePa ?? nameEn,
        'hi' => nameHi ?? nameEn,
        _ => nameEn,
      };

  /// The Gurmukhi line under the name, when there is a reviewed one to show
  /// and it is not already the name itself.
  String? gurmukhiUnder(String lang) => lang == 'pa' ? null : namePa;

  /// The days the calendar calls Gurpurabs: a Guru's manifestation, their
  /// Guruship, or their merging with the Divine. The rest of the calendar --
  /// shaheedi divas, jorh melas, historical days, the moon and month markers
  /// -- is kept but sits behind the filter.
  bool get isGurpurab => const {'prakash', 'gurgaddi', 'joti-jot'}.contains(kind);
}

/// The document's Type column, in the reader's language.
String calendarKindLabel(L l, String kind) => switch (kind) {
      'prakash' => l.calendarKindPrakash,
      'gurgaddi' => l.calendarKindGurgaddi,
      'joti-jot' => l.calendarKindJotiJot,
      'shaheedi' => l.calendarKindShaheedi,
      'jor-mela' => l.calendarKindJorMela,
      'birth' => l.calendarKindBirth,
      'historical' => l.calendarKindHistorical,
      'festival' => l.calendarKindFestival,
      'special' => l.calendarKindSpecial,
      'sangrand' => l.calendarKindSangrand,
      'puranmashi' => l.calendarKindPuranmashi,
      'masya' => l.calendarKindMasya,
      _ => kind,
    };
