import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens for TMCEBMS — iOS 26 inspired Liquid Glass.
class AppColors {
  AppColors._();

  static bool isDark = false;

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2F6BFF);
  static const Color primaryDeep = Color(0xFF1B4FD6);
  static Color get primarySoft =>
      isDark ? const Color(0xFF172849) : const Color(0xFFE8EFFF);
  static const Color gold = Color(0xFFFFAF1F);
  static Color get goldSoft =>
      isDark ? const Color(0xFF352811) : const Color(0xFFFFF3DC);

  // ── Neutrals ─────────────────────────────────────────────────────────────
  static Color get background =>
      isDark ? const Color(0xFF070B12) : const Color(0xFFF2F5FB);
  static Color get surface => isDark ? const Color(0xFF121A29) : Colors.white;
  static Color get surfaceMuted =>
      isDark ? const Color(0xFF182235) : const Color(0xFFF4F7FC);
  static Color get surfaceElevated =>
      isDark ? const Color(0xFF1B263B) : const Color(0xFFFBFCFE);
  static Color get divider =>
      isDark ? const Color(0xFF26344A) : const Color(0xFFE4E9F2);

  // ── Text ─────────────────────────────────────────────────────────────────
  static Color get textPrimary =>
      isDark ? const Color(0xFFF3F7FF) : const Color(0xFF0B1220);
  static Color get textSecondary =>
      isDark ? const Color(0xFF9FB1CC) : const Color(0xFF5A6980);
  static Color get textTertiary =>
      textTertiaryFor(isDark ? Brightness.dark : Brightness.light);

  static Color textTertiaryFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF6B7E9C)
          : const Color(0xFF95A2B7);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22B573);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFF04A5E);
  static const Color info = Color(0xFF3B82F6);
  static const Color neutral = Color(0xFF94A3B8);

  // ── Liquid Glass ─────────────────────────────────────────────────────────
  static Color get glassFill =>
      Colors.white.withValues(alpha: isDark ? 0.09 : 0.72);
  static Color get glassFillStrong =>
      Colors.white.withValues(alpha: isDark ? 0.14 : 0.86);
  static Color get glassBorder =>
      Colors.white.withValues(alpha: isDark ? 0.14 : 0.78);
  static Color get glassBorderSoft =>
      Colors.white.withValues(alpha: isDark ? 0.08 : 0.48);
  static Color get glassHighlight =>
      Colors.white.withValues(alpha: isDark ? 0.18 : 0.68);
  static Color get glassShadowTint =>
      (isDark ? Colors.black : const Color(0xFF1B2A4A)).withValues(alpha: 0.24);

  static LinearGradient get glassSheen => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.12 : 0.56),
          glassFill,
          glassFill,
        ],
        stops: const [0.0, 0.42, 1.0],
      );

  static LinearGradient get ambientGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF0A1222), Color(0xFF060A12), Color(0xFF09101E)]
            : const [Color(0xFFDCE5F4), Color(0xFFD1DCEF), Color(0xFFD8E2F3)],
        stops: const [0.0, 0.55, 1.0],
      );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B93FF), primary, primaryDeep],
  );

  static LinearGradient get premiumGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF3D6FE8), Color(0xFF2448A8)]
            : const [Color(0xFF4C86FF), Color(0xFF2F6BFF), Color(0xFF1B4FD6)],
      );

  static LinearGradient get goldGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFCB66), gold, Color(0xFFF08C00)],
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

/// Soft depth system — layered, subtle, never heavy.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get soft => AppColors.isDark
      ? const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 4)),
        ]
      : const [
          BoxShadow(
              color: Color(0x0A1B2A4A), blurRadius: 14, offset: Offset(0, 4)),
        ];

  static List<BoxShadow> get card => AppColors.isDark
      ? const [
          BoxShadow(
              color: Color(0x4D000000), blurRadius: 26, offset: Offset(0, 10)),
        ]
      : const [
          BoxShadow(
              color: Color(0x10223A66), blurRadius: 26, offset: Offset(0, 10)),
        ];

  static List<BoxShadow> get floating => AppColors.isDark
      ? const [
          BoxShadow(
              color: Color(0x73000000), blurRadius: 38, offset: Offset(0, 18)),
        ]
      : const [
          BoxShadow(
              color: Color(0x241B2A4A), blurRadius: 38, offset: Offset(0, 18)),
        ];

  static List<BoxShadow> get glass => AppColors.isDark
      ? const [
          BoxShadow(
              color: Color(0x59000000), blurRadius: 30, offset: Offset(0, 14)),
          BoxShadow(
              color: Color(0x14FFFFFF), blurRadius: 1, offset: Offset(0, 1)),
        ]
      : const [
          BoxShadow(
              color: Color(0x1A1B2A4A), blurRadius: 30, offset: Offset(0, 14)),
          BoxShadow(
              color: Color(0x66FFFFFF), blurRadius: 1, offset: Offset(0, 1)),
        ];

  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: AppColors.primary
              .withValues(alpha: AppColors.isDark ? 0.34 : 0.28),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        bg: const Color(0xFFF2F5FB),
        surf: Colors.white,
        surfMuted: const Color(0xFFF4F7FC),
        txtPrim: const Color(0xFF0B1220),
        txtSec: const Color(0xFF5A6980),
        txtTert: const Color(0xFF95A2B7),
        div: const Color(0xFFE4E9F2),
        brand: AppColors.primary,
        fieldFill: Colors.white.withValues(alpha: 0.62),
        sheet: const Color(0xFFF8FAFE),
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        bg: const Color(0xFF070B12),
        surf: const Color(0xFF121A29),
        surfMuted: const Color(0xFF182235),
        txtPrim: const Color(0xFFF3F7FF),
        txtSec: const Color(0xFF9FB1CC),
        txtTert: const Color(0xFF6B7E9C),
        div: const Color(0xFF26344A),
        brand: const Color(0xFF4C8BFF),
        fieldFill: Colors.white.withValues(alpha: 0.07),
        sheet: const Color(0xFF111A2B),
      );

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
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        brightness: brightness,
        primary: brand,
        secondary: AppColors.gold,
        surface: surf,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      fontFamily: GoogleFonts.inter().fontFamily,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        height: 1.12,
        color: txtPrim,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 27,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        height: 1.15,
        color: txtPrim,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.45,
        height: 1.2,
        color: txtPrim,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: txtPrim,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: txtPrim,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: txtPrim,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        height: 1.5,
        color: txtPrim,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13.5,
        height: 1.45,
        color: txtSec,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.35,
        color: txtTert,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: Colors.white,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: txtSec,
      ),
    );

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c, width: w),
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
        hintStyle: TextStyle(
            color: txtTert, fontSize: 14.5, fontWeight: FontWeight.w400),
        prefixIconColor: txtTert,
        suffixIconColor: txtTert,
        iconColor: txtTert,
        border: border(div.withValues(alpha: 0.9)),
        enabledBorder: border(div.withValues(alpha: 0.72)),
        focusedBorder: border(brand, 1.5),
        errorBorder: border(AppColors.danger.withValues(alpha: 0.8)),
        focusedErrorBorder: border(AppColors.danger, 1.6),
        errorStyle: const TextStyle(fontSize: 12, color: AppColors.danger),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: brightness == Brightness.dark
              ? const Color(0xFF232E42)
              : const Color(0xFFDDE4F0),
          disabledForegroundColor: txtTert,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: div, width: 1.2),
          backgroundColor: fieldFill,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle: textTheme.labelLarge,
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
        checkmarkColor: Colors.white,
        side: BorderSide(color: div.withValues(alpha: 0.7)),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          color: txtPrim,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        side: BorderSide(color: txtTert, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? brand
              : Colors.transparent,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? brand : div,
        ),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xF2141E30)
            : const Color(0xF7FFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
            ? const Color(0xF21B2638)
            : const Color(0xF2121C2E),
        contentTextStyle: const TextStyle(
          color: Colors.white,
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
        linearTrackColor: div.withValues(alpha: 0.55),
      ),
      dividerTheme: DividerThemeData(color: div, thickness: 1, space: 1),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: brand,
        thumbColor: Colors.white,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        headerBackgroundColor: brand,
        headerForegroundColor: Colors.white,
      ),
    );
  }
}
