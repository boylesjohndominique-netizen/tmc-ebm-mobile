import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens for TMCEBMS — iOS-inspired, vibrant, minimal.
class AppColors {
  AppColors._();

  static bool isDark = false;

  // Brand
  static const Color primary = Color(0xFF2F6BFF);
  static const Color primaryDeep = Color(0xFF1D4FD8);
  static Color get primarySoft => isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE9EFFF);
  static const Color gold = Color(0xFFFFAF1F);
  static Color get goldSoft => isDark ? const Color(0xFF332812) : const Color(0xFFFFF3DC);

  // Neutrals
  static Color get background => isDark ? const Color(0xFF0F141C) : const Color(0xFFF4F6FB);
  static Color get surface => isDark ? const Color(0xFF171E2C) : Colors.white;
  static Color get surfaceMuted => isDark ? const Color(0xFF1E2738) : const Color(0xFFF6F8FC);
  static Color get divider => isDark ? const Color(0xFF263347) : const Color(0xFFE7EBF3);

  // Text
  static Color get textPrimary => isDark ? const Color(0xFFF1F5FD) : const Color(0xFF101A2D);
  static Color get textSecondary => isDark ? const Color(0xFF9DB0CC) : const Color(0xFF5A6980);
  static Color get textTertiary => isDark ? const Color(0xFF657795) : const Color(0xFF97A2B6);

  // Semantic
  static const Color success = Color(0xFF1FA760);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4455);
  static const Color info = Color(0xFF3B82F6);
  static const Color neutral = Color(0xFF93A0B5);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4C86FF), primary, primaryDeep],
  );
}

/// Corner-radius scale used across the whole app.
class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 100;
}

/// Soft depth system — layered, subtle, never heavy.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get soft => AppColors.isDark
      ? const [
          BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3)),
        ]
      : const [
          BoxShadow(color: Color(0x0B122A5C), blurRadius: 10, offset: Offset(0, 3)),
        ];

  static List<BoxShadow> get card => AppColors.isDark
      ? const [
          BoxShadow(color: Color(0x4D000000), blurRadius: 18, offset: Offset(0, 6)),
        ]
      : const [
          BoxShadow(color: Color(0x13122A5C), blurRadius: 18, offset: Offset(0, 6)),
        ];

  static List<BoxShadow> get floating => AppColors.isDark
      ? const [
          BoxShadow(color: Color(0x66000000), blurRadius: 32, offset: Offset(0, 14)),
        ]
      : const [
          BoxShadow(color: Color(0x26122A5C), blurRadius: 32, offset: Offset(0, 14)),
        ];

  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: AppColors.isDark ? 0.30 : 0.25),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const bg = Color(0xFFF4F6FB);
    const surf = Colors.white;
    const txtPrim = Color(0xFF101A2D);
    const txtSec = Color(0xFF5A6980);
    const txtTert = Color(0xFF97A2B6);
    const div = Color(0xFFE7EBF3);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.gold,
        surface: surf,
      ),
      scaffoldBackgroundColor: bg,
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: txtPrim,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: txtPrim,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: txtPrim,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: txtPrim,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: txtPrim,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        height: 1.45,
        color: txtPrim,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        height: 1.4,
        color: txtSec,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.35,
        color: txtTert,
      ),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: txtPrim,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        iconTheme: const IconThemeData(color: txtPrim, size: 22),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surf,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: txtTert, fontSize: 14),
        prefixIconColor: txtTert,
        suffixIconColor: txtTert,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: div),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: div),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFDCE3F0),
          disabledForegroundColor: txtTert,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: Color(0xFFD9DFEA), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(txtPrim)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFFF6F8FC),
        selectedColor: AppColors.primary,
        disabledColor: const Color(0xFFF6F8FC),
        checkmarkColor: Colors.white,
        side: const BorderSide(color: div),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          color: txtPrim,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: txtTert, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : surf,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : div,
        ),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surf,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surf,
        modalBackgroundColor: surf,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFFD9DFEA),
        dragHandleSize: Size(40, 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF16223C),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        elevation: 6,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0xFFE9EFFF),
      ),
      dividerTheme: const DividerThemeData(color: div, thickness: 1, space: 1),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static ThemeData get dark {
    const bg = Color(0xFF0F141C);
    const surf = Color(0xFF171E2C);
    const surfMuted = Color(0xFF1E2738);
    const txtPrim = Color(0xFFF1F5FD);
    const txtSec = Color(0xFF9DB0CC);
    const txtTert = Color(0xFF657795);
    const div = Color(0xFF263347);
    const brand = Color(0xFF3B7BF6);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        brightness: Brightness.dark,
        primary: brand,
        secondary: AppColors.gold,
        surface: surf,
        surfaceContainer: surfMuted,
        onSurface: txtPrim,
      ),
      scaffoldBackgroundColor: bg,
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: txtPrim,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: txtPrim,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: txtPrim,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: txtPrim,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: txtPrim,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        height: 1.45,
        color: txtPrim,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        height: 1.4,
        color: txtSec,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.35,
        color: txtTert,
      ),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: txtPrim,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        iconTheme: const IconThemeData(color: txtPrim, size: 22),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surf,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: txtTert, fontSize: 14),
        prefixIconColor: txtTert,
        suffixIconColor: txtTert,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: div),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: div),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF222B3A),
          disabledForegroundColor: txtTert,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: div, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(txtPrim)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfMuted,
        selectedColor: brand,
        disabledColor: surfMuted,
        checkmarkColor: Colors.white,
        side: const BorderSide(color: div),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          color: txtPrim,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: txtTert, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? brand : surf,
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
        backgroundColor: surf,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surf,
        modalBackgroundColor: surf,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        showDragHandle: true,
        dragHandleColor: div,
        dragHandleSize: Size(40, 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfMuted,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        elevation: 6,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brand,
        linearTrackColor: Color(0xFF1E2D4A),
      ),
      dividerTheme: const DividerThemeData(color: div, thickness: 1, space: 1),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
