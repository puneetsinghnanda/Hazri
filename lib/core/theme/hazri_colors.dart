import 'package:flutter/material.dart';

/// Every colour token from `design/tokens.json`, carried on the [ThemeData] so
/// widgets never reach for a hard-coded value.
///
/// The two palettes are not a light/dark inversion of each other: in dark,
/// `primary` becomes Kesri (saffron) and `onPrimary` goes dark, which is why
/// each is spelled out in full rather than derived.
@immutable
class HazriColors extends ThemeExtension<HazriColors> {
  const HazriColors({
    required this.bg,
    required this.card,
    required this.card2,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.rule,
    required this.primary,
    required this.onPrimary,
    required this.kesri,
    required this.kesriSoft,
    required this.kesriInk,
    required this.sage,
    required this.sageSoft,
    required this.teal,
    required this.hl,
    required this.word,
    required this.scrim,
    required this.shadows,
  });

  /// Screen background.
  final Color bg;

  /// Card surface.
  final Color card;

  /// Secondary surface / chips.
  final Color card2;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color ink2;

  /// Tertiary text, inactive icons.
  final Color muted;

  /// Dividers.
  final Color rule;

  /// Primary buttons and brand: Neela navy in light, Kesri in dark.
  final Color primary;

  /// Text on [primary].
  final Color onPrimary;

  /// Saffron accent.
  final Color kesri;

  /// Accent container.
  final Color kesriSoft;

  /// Text and icons on [kesriSoft].
  final Color kesriInk;

  /// Success / done.
  final Color sage;

  /// Success container.
  final Color sageSoft;

  /// Info.
  final Color teal;

  /// Current-line highlight in the reader.
  final Color hl;

  /// Current-word colour and underline in the reader.
  final Color word;

  /// Bottom-sheet scrim.
  final Color scrim;

  /// The card elevation treatment: a soft double shadow in light, a hairline
  /// in dark.
  final List<BoxShadow> shadows;

  static const light = HazriColors(
    bg: Color(0xFFF4F3F8),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFECEBF3),
    ink: Color(0xFF1B1D3A),
    ink2: Color(0xFF4D5070),
    muted: Color(0xFF85879F),
    rule: Color(0xFFE1E1EA),
    primary: Color(0xFF262C63),
    onPrimary: Color(0xFFFFFFFF),
    kesri: Color(0xFFD9730D),
    kesriSoft: Color(0xFFFBE8D2),
    kesriInk: Color(0xFF9A4F00),
    sage: Color(0xFF2E7A57),
    sageSoft: Color(0xFFDCEFE5),
    teal: Color(0xFF1F7A8C),
    hl: Color(0xFFFBE5CB),
    word: Color(0xFFA04F00),
    scrim: Color(0x7314162D),
    shadows: [
      BoxShadow(color: Color(0x0F1B1D3A), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x121B1D3A), blurRadius: 28, offset: Offset(0, 10)),
    ],
  );

  static const dark = HazriColors(
    bg: Color(0xFF0C0F24),
    card: Color(0xFF161A37),
    card2: Color(0xFF1F2447),
    ink: Color(0xFFEDECF6),
    ink2: Color(0xFFB9BAD3),
    muted: Color(0xFF8084A6),
    rule: Color(0xFF2A2F55),
    primary: Color(0xFFF2A24E),
    onPrimary: Color(0xFF1C1206),
    kesri: Color(0xFFF2A24E),
    kesriSoft: Color(0xFF3A2A1A),
    kesriInk: Color(0xFFFFC27E),
    sage: Color(0xFF6CCB9C),
    sageSoft: Color(0xFF173327),
    teal: Color(0xFF6FC3D3),
    hl: Color(0x2BF2A24E),
    word: Color(0xFFFFC27E),
    scrim: Color(0x8C000000),
    shadows: [BoxShadow(color: Color(0x0AFFFFFF), spreadRadius: 1)],
  );

  @override
  HazriColors copyWith({
    Color? bg,
    Color? card,
    Color? card2,
    Color? ink,
    Color? ink2,
    Color? muted,
    Color? rule,
    Color? primary,
    Color? onPrimary,
    Color? kesri,
    Color? kesriSoft,
    Color? kesriInk,
    Color? sage,
    Color? sageSoft,
    Color? teal,
    Color? hl,
    Color? word,
    Color? scrim,
    List<BoxShadow>? shadows,
  }) {
    return HazriColors(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      card2: card2 ?? this.card2,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      muted: muted ?? this.muted,
      rule: rule ?? this.rule,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      kesri: kesri ?? this.kesri,
      kesriSoft: kesriSoft ?? this.kesriSoft,
      kesriInk: kesriInk ?? this.kesriInk,
      sage: sage ?? this.sage,
      sageSoft: sageSoft ?? this.sageSoft,
      teal: teal ?? this.teal,
      hl: hl ?? this.hl,
      word: word ?? this.word,
      scrim: scrim ?? this.scrim,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  HazriColors lerp(covariant HazriColors? other, double t) {
    if (other == null) return this;
    return HazriColors(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      card2: Color.lerp(card2, other.card2, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      kesri: Color.lerp(kesri, other.kesri, t)!,
      kesriSoft: Color.lerp(kesriSoft, other.kesriSoft, t)!,
      kesriInk: Color.lerp(kesriInk, other.kesriInk, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      sageSoft: Color.lerp(sageSoft, other.sageSoft, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      hl: Color.lerp(hl, other.hl, t)!,
      word: Color.lerp(word, other.word, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      shadows: BoxShadow.lerpList(shadows, other.shadows, t)!,
    );
  }
}

/// `context.colors` — the palette for the current theme.
extension HazriColorsContext on BuildContext {
  HazriColors get colors => Theme.of(this).extension<HazriColors>()!;
}
