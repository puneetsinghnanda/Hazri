import '../../../core/l10n/gen/app_localizations.dart';
import '../domain/badges.dart';

/// The per-badge strings of 12-badges §7.4.
extension BadgeText on L {
  String badgeMarks(BadgeId b) => switch (b) {
        BadgeId.jigyasu => badgeMarksJigyasu,
        BadgeId.shardhalu => badgeMarksShardhalu,
        BadgeId.abhyasi => badgeMarksAbhyasi,
        BadgeId.nitnemi => badgeMarksNitnemi,
        BadgeId.simrani => badgeMarksSimrani,
        BadgeId.paathi => badgeMarksPaathi,
        BadgeId.sevadar => badgeMarksSevadar,
        BadgeId.gursikh => badgeMarksGursikh,
        BadgeId.satsangi => badgeMarksSatsangi,
        BadgeId.vichari => badgeMarksVichari,
      };

  String badgeRule(BadgeId b) => switch (b) {
        BadgeId.jigyasu => badgeRuleJigyasu,
        BadgeId.shardhalu => badgeRuleShardhalu,
        BadgeId.abhyasi => badgeRuleAbhyasi,
        BadgeId.nitnemi => badgeRuleNitnemi,
        BadgeId.simrani => badgeRuleSimrani,
        BadgeId.paathi => badgeRulePaathi,
        BadgeId.sevadar => badgeRuleSevadar,
        BadgeId.gursikh => badgeRuleGursikh,
        BadgeId.satsangi => badgeRuleSatsangi,
        BadgeId.vichari => badgeRuleVichari,
      };

  /// [morningBanis]: the five names from `content.db`, for NITNEMI (UI4).
  String badgeHow(BadgeId b, {String morningBanis = ''}) => switch (b) {
        BadgeId.jigyasu => badgeHowJigyasu,
        BadgeId.shardhalu => badgeHowShardhalu,
        BadgeId.abhyasi => badgeHowAbhyasi,
        BadgeId.nitnemi => badgeHowNitnemi(morningBanis),
        BadgeId.simrani => badgeHowSimrani,
        BadgeId.paathi => badgeHowPaathi,
        BadgeId.sevadar => badgeHowSevadar,
        BadgeId.gursikh => badgeHowGursikh,
        BadgeId.satsangi => badgeHowSatsangi,
        BadgeId.vichari => badgeHowVichari,
      };
}
