import 'package:flutter/widgets.dart';

/// Font families bundled with the app (all SIL Open Font License).
abstract final class HazriFonts {
  /// All UI text, Latin and Devanagari.
  static const String ui = 'Mukta';

  /// Headlines, big numbers and Gurmukhi UI headings.
  static const String display = 'BalooPaaji2';

  /// Gurbani set in Gurmukhi.
  static const String gurmukhi = 'NotoSerifGurmukhi';

  /// Gurbani set in Devanagari.
  static const String devanagari = 'NotoSerifDevanagari';

  /// Fallbacks so a glyph missing from one family still renders.
  static const List<String> fallback = [ui, devanagari, gurmukhi];
}

/// The type scale from `design/tokens.json`, plus the handful of sizes the
/// screens use directly.
abstract final class HazriText {
  static const TextStyle body = TextStyle(
    fontFamily: HazriFonts.ui,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: HazriFonts.ui,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: HazriFonts.ui,
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: HazriFonts.ui,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle captionStrong = TextStyle(
    fontFamily: HazriFonts.ui,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );

  /// 12 sp, 600, uppercase, +0.08 em.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: HazriFonts.ui,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 12 * 0.08,
  );

  static const TextStyle button = TextStyle(
    fontFamily: HazriFonts.ui,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle chip = TextStyle(
    fontFamily: HazriFonts.ui,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle navLabel = TextStyle(
    fontFamily: HazriFonts.ui,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// App wordmark in the header.
  static const TextStyle brand = TextStyle(
    fontFamily: HazriFonts.display,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 20 * 0.01,
  );

  /// Screen greeting / page title.
  static const TextStyle display26 = TextStyle(
    fontFamily: HazriFonts.display,
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle display22 = TextStyle(
    fontFamily: HazriFonts.display,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  /// The big number in the day arc and ring timers.
  static const TextStyle display34 = TextStyle(
    fontFamily: HazriFonts.display,
    fontSize: 34,
    height: 1,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle display44 = TextStyle(
    fontFamily: HazriFonts.display,
    fontSize: 44,
    height: 1,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: HazriFonts.ui,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  /// Gurbani in Gurmukhi at [size].
  static TextStyle gurmukhi(double size, {FontWeight weight = FontWeight.w500}) => TextStyle(
    fontFamily: HazriFonts.gurmukhi,
    fontSize: size,
    height: 1.7,
    fontWeight: weight,
  );

  /// Gurbani in Devanagari at [size].
  static TextStyle devanagari(double size, {FontWeight weight = FontWeight.w500}) => TextStyle(
    fontFamily: HazriFonts.devanagari,
    fontSize: size,
    height: 1.7,
    fontWeight: weight,
  );

  /// Roman transliteration at [size].
  static TextStyle roman(double size, {FontWeight weight = FontWeight.w400}) => TextStyle(
    fontFamily: HazriFonts.ui,
    fontSize: size,
    height: 1.5,
    fontWeight: weight,
  );
}

/// Radii from `design/tokens.json`.
abstract final class HazriRadius {
  static const double card = 20;
  static const double button = 16;
  static const double chip = 999;
  static const double navPill = 16;
  static const double iconButton = 12;
  static const double sheet = 28;
}

/// Sizes from `design/tokens.json`.
abstract final class HazriSize {
  static const double buttonMinHeight = 52;
  static const double elderButtonMinHeight = 72;
  static const Size navPill = Size(58, 32);
  static const double minTouchTarget = 48;
  static const double elderTouchTarget = 64;

  /// Tablets run the phone layout, centred (PRD §4.1).
  static const double maxContentWidth = 560;

  /// Horizontal page padding used by every screen.
  static const double gutter = 20;
}

/// Reader type defaults from `design/tokens.json` -> type.
abstract final class ReaderType {
  static const double gurmukhiDefault = 22;
  static const double devanagariDefault = 21;
  static const double romanDefault = 18;
  static const double min = 16;
  static const double max = 40;
  static const double elderMin = 30;
}
