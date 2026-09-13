import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'hazri_colors.dart';
import 'hazri_text.dart';

/// Builds the Material theme from the design tokens.
///
/// Material's own [ColorScheme] is derived from the tokens rather than the
/// other way round, so framework widgets (dialogs, sheets, ripples) land on
/// the same palette as the hand-built ones.
abstract final class HazriTheme {
  static ThemeData light({bool elder = false}) => _build(HazriColors.light, Brightness.light, elder);

  static ThemeData dark({bool elder = false}) => _build(HazriColors.dark, Brightness.dark, elder);

  static ThemeData _build(HazriColors c, Brightness brightness, bool elder) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.kesriSoft,
      onPrimaryContainer: c.kesriInk,
      secondary: c.kesri,
      onSecondary: c.onPrimary,
      secondaryContainer: c.kesriSoft,
      onSecondaryContainer: c.kesriInk,
      tertiary: c.teal,
      onTertiary: c.onPrimary,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: c.card,
      onSurface: c.ink,
      surfaceContainerLowest: c.bg,
      surfaceContainerLow: c.bg,
      surfaceContainer: c.card,
      surfaceContainerHigh: c.card2,
      surfaceContainerHighest: c.card2,
      onSurfaceVariant: c.ink2,
      outline: c.rule,
      outlineVariant: c.rule,
      shadow: const Color(0xFF1B1D3A),
      scrim: c.scrim,
      inverseSurface: c.ink,
      onInverseSurface: c.bg,
    );

    // Elder mode: text >= 1.6x and larger touch targets, app-wide (PRD 1.12).
    final scale = elder ? 1.6 : 1.0;
    TextStyle s(TextStyle t) => t.copyWith(
      fontSize: (t.fontSize ?? 15) * scale,
      color: c.ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      splashFactory: InkSparkle.splashFactory,
      fontFamily: HazriFonts.ui,
      fontFamilyFallback: HazriFonts.fallback,
      extensions: [c],
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: TextTheme(
        displayLarge: s(HazriText.display44),
        displayMedium: s(HazriText.display34),
        displaySmall: s(HazriText.display26),
        headlineMedium: s(HazriText.display22),
        titleLarge: s(HazriText.sectionTitle),
        titleMedium: s(HazriText.bodyStrong),
        bodyLarge: s(HazriText.body),
        bodyMedium: s(HazriText.body).copyWith(color: c.ink2),
        bodySmall: s(HazriText.bodySmall).copyWith(color: c.ink2),
        labelLarge: s(HazriText.button),
        labelMedium: s(HazriText.chip),
        labelSmall: s(HazriText.eyebrow).copyWith(color: c.muted),
      ),
      dividerTheme: DividerThemeData(color: c.rule, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.ink, size: elder ? 28 : 24),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.scrim,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(HazriRadius.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HazriRadius.card)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.kesri,
        inactiveTrackColor: c.rule,
        thumbColor: c.kesri,
        overlayColor: c.kesri.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? c.onPrimary : c.card,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? c.primary : c.card2,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? Colors.transparent : c.rule,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? c.primary : c.muted,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? c.primary : Colors.transparent,
        ),
        side: BorderSide(color: c.rule, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: HazriText.body.copyWith(color: c.bg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HazriRadius.button)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}
