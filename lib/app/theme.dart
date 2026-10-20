import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens for TMCEBMS — Clean Apple-inspired 3-color system.
///
/// Follows a strict 60-30-10 3-color principle without harsh pure white or
/// pitch black:
///   1. 60% Soft Neutral Surfaces (Soft Pearl/Alabaster in Light; Soft Slate
///      Charcoal in Dark)
///   2. 30% Harmonized Slate / Cloud Ink for typography & secondary UI
///   3. 10% TMC Royal Blue & Warm Gold accents
class AppColors {
  AppColors._();

  static bool isDark = false;

  // ── 10% Brand Accents ────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2F6BFF);
  static const Color primaryDeep = Color(0xFF1D52D8);
  static Color get primarySoft =>
      isDark ? const Color(0xFF2A3B5C) : const Color(0xFFE3ECFF);
  static const Color gold = Color(0xFFF5A623);
  static Color get goldSoft =>
      isDark ? const Color(0xFF3A301E) : const Color(0xFFFEF0D6);
  static const Color onPrimary = Color(0xFFF7F9FC);

  // ── 60% Soft Neutral Surfaces (no harsh #FFFFFF or #000000) ──────────────
  static Color get background =>
      isDark ? const Color(0xFF18202F) : const Color(0xFFEEF2F7);
  static Color get surface =>
      isDark ? const Color(0xFF222D40) : const Color(0xFFF7F9FC);
  static Color get surfaceMuted =>
      isDark ? const Color(0xFF2B384E) : const Color(0xFFE4EAF3);
  static Color get surfaceElevated =>
      isDark ? const Color(0xFF27344A) : const Color(0xFFFAFBFD);
  static Color get divider =>
      isDark ? const Color(0xFF314059) : const Color(0xFFD9E1EE);

  // ── 30% Slate / Cloud Typography (always legible in Light & Dark) ────────
  static Color get textPrimary =>
      isDark ? const Color(0xFFE8EEF7) : const Color(0xFF1E293B);
  static Color get textSecondary =>
      isDark ? const Color(0xFFB2C2DA) : const Color(0xFF475569);
  static Color get textTertiary =>
      textTertiaryFor(isDark ? Brightness.dark : Brightness.light);

  static Color textTertiaryFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF8C9FBC)
          : const Color(0xFF64748B);

  // ── Semantic (tuned to harmonize with the 3-color palette) ───────────────
  static const Color success = Color(0xFF1FA968);
  static const Color warning = Color(0xFFE59A1A);
  static const Color danger = Color(0xFFE54858);
  static const Color info = Color(0xFF2F6BFF);
  static const Color neutral = Color(0xFF64748B);

  // ── Borderless Frosted Surfaces ──────────────────────────────────────────
  static Color get glassFill => isDark
      ? const Color(0xFF222D40).withValues(alpha: 0.90)
      : const Color(0xFFF7F9FC).withValues(alpha: 0.92);
  static Color get glassFillStrong => isDark
      ? const Color(0xFF253146).withValues(alpha: 0.96)
      : const Color(0xFFF9FAFD).withValues(alpha: 0.96);
  static Color get glassBorder => Colors.transparent;
  static Color get glassBorderSoft => Colors.transparent;
  static Color get glassHighlight => isDark
      ? const Color(0xFFE8EEF7).withValues(alpha: 0.08)
      : const Color(0xFFF7F9FC).withValues(alpha: 0.75);
  static Color get glassShadowTint =>
      (isDark ? const Color(0xFF0B101B) : const Color(0xFF1E293B))
          .withValues(alpha: 0.20);

  static LinearGradient get glassSheen => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF28354B).withValues(alpha: 0.94),
                const Color(0xFF222D40).withValues(alpha: 0.91),
              ]
            : [
                const Color(0xFFFAFBFD).withValues(alpha: 0.96),
                const Color(0xFFF3F6FB).withValues(alpha: 0.92),
              ],
      );

  static LinearGradient get ambientGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF1B2436), Color(0xFF18202F), Color(0xFF151C2A)]
            : const [Color(0xFFF2F5FA), Color(0xFFEEF2F7), Color(0xFFE8EEF6)],
        stops: const [0.0, 0.55, 1.0],
      );

  static LinearGradient get headlineGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFFE8EEF7), Color(0xFF6B9DFF)]
            : const [Color(0xFF1E293B), Color(0xFF2F6BFF)],
      );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4B83FF), primary, primaryDeep],
  );

  static LinearGradient get premiumGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF3E73F6), Color(0xFF254DB8)]
            : const [Color(0xFF4780FF), Color(0xFF2F6BFF), Color(0xFF1D52D8)],
      );

  static LinearGradient get goldGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF8BC4E), gold, Color(0xFFD9880F)],
      );
}

/// Corner-radius scale used across the whole app.
class AppRadius {
  AppRadius._();
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double xxl = 34;
  static const double pill = 999;
}

/// Grounded Apple-style elevation shadows — multi-layered ambient + key shadows
/// so cards, chips, inputs, and buttons have natural depth without thin borders.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get soft => AppColors.isDark
      ? const [
          BoxShadow(
            color: Color(0x420B101B),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
          BoxShadow(
            color: Color(0x260B101B),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x161E293B),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
          BoxShadow(
            color: Color(0x0D1E293B),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ];

  static List<BoxShadow> get card => AppColors.isDark
      ? const [
          BoxShadow(
            color: Color(0x540B101B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x2E0B101B),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x1C1E293B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x0F1E293B),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ];

  static List<BoxShadow> get floating => AppColors.isDark
      ? const [
          BoxShadow(
            color: Color(0x6B0B101B),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Color(0x380B101B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x241E293B),
            blurRadius: 34,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: Color(0x121E293B),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ];

  static List<BoxShadow> get glass => card;

  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: AppColors.primary
              .withValues(alpha: AppColors.isDark ? 0.36 : 0.28),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.primary
              .withValues(alpha: AppColors.isDark ? 0.20 : 0.14),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static const List<String> _appleFontFallback = [
    '.SF Pro Display',
    '.SF Pro Text',
    'SF Pro Display',
    'SF Pro Text',
    'Helvetica Neue',
  ];

  static final ThemeData light = _build(
    brightness: Brightness.light,
    bg: const Color(0xFFEEF2F7),
    surf: const Color(0xFFF7F9FC),
    surfMuted: const Color(0xFFE4EAF3),
    txtPrim: const Color(0xFF1E293B),
    txtSec: const Color(0xFF475569),
    txtTert: const Color(0xFF64748B),
    div: const Color(0xFFD9E1EE),
    brand: AppColors.primary,
    fieldFill: const Color(0xFFE6ECF5),
    sheet: const Color(0xFFF7F9FC),
  );

  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    bg: const Color(0xFF18202F),
    surf: const Color(0xFF222D40),
    surfMuted: const Color(0xFF2B384E),
    txtPrim: const Color(0xFFE8EEF7),
    txtSec: const Color(0xFFB2C2DA),
    txtTert: const Color(0xFF8C9FBC),
    div: const Color(0xFF314059),
    brand: const Color(0xFF4D84FF),
    fieldFill: const Color(0xFF2B384E),
    sheet: const Color(0xFF222D40),
  );

  static TextStyle _appleFont({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    ).copyWith(fontFamilyFallback: _appleFontFallback);
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surf,
    required Color surfMuted,
    required Color txtPrim,
    required Color txtSec,
    required Color txtTert,
    required Color div,
    required Color brand,
    required Color fieldFill,
    required Color sheet,
  }) {
    final fontFamily = GoogleFonts.plusJakartaSans().fontFamily;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        brightness: brightness,
        primary: brand,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.gold,
        surface: surf,
        onSurface: txtPrim,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surf,
      dividerColor: div,
      fontFamily: fontFamily,
      fontFamilyFallback: _appleFontFallback,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(
          bodyColor: txtPrim,
          displayColor: txtPrim,
          fontFamilyFallback: _appleFontFallback,
        )
        .copyWith(
          headlineLarge: _appleFont(
            fontSize: 31,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.14,
            color: txtPrim,
          ),
          headlineMedium: _appleFont(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.65,
            height: 1.16,
            color: txtPrim,
          ),
          headlineSmall: _appleFont(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.45,
            height: 1.2,
            color: txtPrim,
          ),
          titleLarge: _appleFont(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: txtPrim,
          ),
          titleMedium: _appleFont(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: txtPrim,
          ),
          titleSmall: _appleFont(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            color: txtPrim,
          ),
          bodyLarge: _appleFont(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            height: 1.5,
            color: txtPrim,
          ),
          bodyMedium: _appleFont(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.05,
            height: 1.45,
            color: txtSec,
          ),
          bodySmall: _appleFont(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.38,
            color: txtTert,
          ),
          labelLarge: _appleFont(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
            color: txtPrim,
          ),
          labelMedium: _appleFont(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.05,
            color: txtSec,
          ),
          labelSmall: _appleFont(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: txtTert,
          ),
        );

    OutlineInputBorder borderlessInput() => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        );

    final buttonLabelStyle = _appleFont(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.15,
      color: AppColors.onPrimary,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: txtPrim,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        iconTheme: IconThemeData(color: txtPrim, size: 21),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: _appleFont(
          color: txtTert,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: _appleFont(
          color: txtSec,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: txtSec,
        suffixIconColor: txtSec,
        iconColor: txtSec,
        border: borderlessInput(),
        enabledBorder: borderlessInput(),
        focusedBorder: borderlessInput(),
        errorBorder: borderlessInput(),
        focusedErrorBorder: borderlessInput(),
        errorStyle: _appleFont(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.danger,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: surfMuted,
          disabledForegroundColor: txtTert,
          minimumSize: const Size.fromHeight(54),
          elevation: 3,
          shadowColor: brand.withValues(alpha: 0.32),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: buttonLabelStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide.none,
          backgroundColor: fieldFill,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: buttonLabelStyle.copyWith(color: brand),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle: buttonLabelStyle.copyWith(color: brand),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(txtPrim)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: fieldFill,
        selectedColor: brand,
        disabledColor: fieldFill,
        checkmarkColor: AppColors.onPrimary,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: _appleFont(
          color: txtPrim,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        secondaryLabelStyle: _appleFont(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        side: BorderSide.none,
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? brand : fieldFill,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? brand : surfMuted,
        ),
        thumbColor: const WidgetStatePropertyAll(AppColors.onPrimary),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surf,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: const Color(0x330B101B),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        showDragHandle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF2B384E)
            : const Color(0xFF1E293B),
        contentTextStyle: _appleFont(
          color: AppColors.onPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        elevation: 8,
        insetPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brand,
        linearTrackColor: surfMuted,
      ),
      dividerTheme: DividerThemeData(
        color: div.withValues(alpha: 0.45),
        thickness: 0.8,
        space: 1,
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: brand,
        thumbColor: AppColors.onPrimary,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        headerBackgroundColor: brand,
        headerForegroundColor: AppColors.onPrimary,
      ),
    );
  }
}
