import 'package:flutter/foundation.dart';

/// The ten badges, in the order of 12-badges §2: the order of every list, of
/// AN2's "highest", and of UI4's previous and next.
enum BadgeId {
  jigyasu('JIGYASU', 'Jigyasu', 'ਜਿਗਿਆਸੂ', 'जिज्ञासु',
      'M3 17h18M7 17a5 5 0 0 1 10 0M12 7v3M6.5 10.5l1.5 1.5M17.5 10.5L16 12'),
  shardhalu('SHARDHALU', 'Shardhalu', 'ਸ਼ਰਧਾਲੂ', 'श्रद्धालु',
      'M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z'),
  abhyasi('ABHYASI', 'Abhyasi', 'ਅਭਿਆਸੀ', 'अभ्यासी',
      'M4 12a8 8 0 0 1 14-5.3M20 12a8 8 0 0 1-14 5.3M18 3v4h-4M6 21v-4h4'),
  nitnemi('NITNEMI', 'Nitnemi', 'ਨਿਤਨੇਮੀ', 'नितनेमी',
      'M12 6.5C10.5 5.2 8 4.5 4 4.5v13c4 0 6.5.7 8 2 1.5-1.3 4-2 8-2v-13c-4 0-6.5.7-8 2zM12 6.5v13'),
  simrani('SIMRANI', 'Simrani', 'ਸਿਮਰਨੀ', 'सिमरनी', 'M12 4a8 8 0 1 1-.01 0M12 20v2.5'),
  paathi('PAATHI', 'Paathi', 'ਪਾਠੀ', 'पाठी',
      'M5 4h11a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3zM5 17a3 3 0 0 1 3-3h11M13 4v6l2-1.5L17 10V4'),
  sevadar('SEVADAR', 'Sevadar', 'ਸੇਵਾਦਾਰ', 'सेवादार',
      'M3 15h4l3 2h6a2 2 0 0 0 0-4h-3M12 10.5s-3-1.9-3-4.2A1.8 1.8 0 0 1 12 5a1.8 1.8 0 0 1 3 1.3c0 2.3-3 4.2-3 4.2z'),
  gursikh('GURSIKH', 'Gursikh', 'ਗੁਰਸਿੱਖ', 'गुरसिख',
      'M12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM12 2.5V5M12 19v2.5M2.5 12H5M19 12h2.5M5.3 5.3l1.8 1.8'
          'M16.9 16.9l1.8 1.8M5.3 18.7l1.8-1.8M16.9 7.1l1.8-1.8'),
  satsangi('SATSANGI', 'Satsangi', 'ਸਤਿਸੰਗੀ', 'सतसंगी',
      'M12 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM6.5 20a5.5 5.5 0 0 1 11 0M5 11.5a2.2 2.2 0 1 0 0-4.4'
          'M2 17.5a4 4 0 0 1 3-3.6M19 11.5a2.2 2.2 0 1 1 0-4.4M22 17.5a4 4 0 0 0-3-3.6'),
  vichari('VICHARI', 'Vichari', 'ਵੀਚਾਰੀ', 'वीचारी', 'M3 19l6-8 4 5 3-3 5 6zM16 8a2 2 0 1 0 0-4 2 2 0 0 0 0 4z');

  const BadgeId(this.id, this.latin, this.gurmukhi, this.devanagari, this.emblemPath);

  /// As stored: `JIGYASU` …
  final String id;

  /// The names of §2. Proper nouns, like a bani's name: the same in every
  /// UI language, chosen by script (§7.4).
  final String latin;
  final String gurmukhi;
  final String devanagari;

  /// The emblem's mark, an SVG path on a 24×24 grid (designs 95–99).
  final String emblemPath;

  /// The name in the reader's script: Devanagari for Hindi, else Gurmukhi.
  String nameFor(String languageCode) => languageCode == 'hi' ? devanagari : gurmukhi;

  /// 1-based, for `badgeNumber`.
  int get number => index + 1;

  static BadgeId? byId(String id) => values.where((b) => b.id == id).firstOrNull;
}

/// The counts of 12-badges §3.1.
@immutable
class BadgeCounts {
  const BadgeCounts({
    this.hazriDays = 0,
    this.nitnemDays = 0,
    this.simranDays = 0,
    this.banisCompleted = const {},
    this.allBanis = const {},
    this.goalsReached = 0,
    this.joins = 0,
  });

  final int hazriDays;
  final int nitnemDays;
  final int simranDays;

  /// Distinct bani ids ever completed.
  final Set<String> banisCompleted;

  /// Every bani in `content.db` (HC5).
  final Set<String> allBanis;

  /// The Sangat facts (§5), 0 without a profile.
  final int goalsReached;
  final int joins;
}

/// §3.2: which badges the counts meet. [earned] is what is already held, for
/// GURSIKH's three named badges, which stay held once held (NT1).
Set<BadgeId> badgesMet(BadgeCounts c, {Set<BadgeId> earned = const {}}) {
  final met = <BadgeId>{
    if (c.hazriDays >= 1) BadgeId.jigyasu,
    if (c.hazriDays >= 7) BadgeId.shardhalu,
    if (c.hazriDays >= 40) BadgeId.abhyasi,
    if (c.nitnemDays >= 40) BadgeId.nitnemi,
    if (c.simranDays >= 108) BadgeId.simrani,
    if (c.allBanis.isNotEmpty && c.banisCompleted.containsAll(c.allBanis)) BadgeId.paathi,
    if (c.goalsReached >= 3) BadgeId.sevadar,
    if (c.joins >= 5) BadgeId.satsangi,
    if (c.hazriDays >= 365) BadgeId.vichari,
  };
  final held = {...earned, ...met};
  if (held.containsAll({BadgeId.nitnemi, BadgeId.simrani, BadgeId.paathi}) && c.hazriDays >= 180) {
    met.add(BadgeId.gursikh);
  }
  return met;
}
