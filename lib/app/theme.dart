import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens for TMCEBMS.
class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF1B4F9C);
  static const Color deepBlue = Color(0xFF0F3B79);
  static const Color lightBlue = Color(0xFFE8F0FC);
  static const Color gold = Color(0xFFF2B705);
  static const Color goldDark = Color(0xFFD9A203);
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A2233);
  static const Color textSecondary = Color(0xFF6B7688);
  static const Color divider = Color(0xFFE3E8F0);

  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE8A400);
  static const Color danger = Color(0xFFE0483B);
  static const Color info = Color(0xFF2F7DD9);
  static const Color neutral = Color(0xFF8A93A6);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.gold,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.poppins().fontFamily,
    );

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
      headlineSmall: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
      bodyMedium: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
      labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.lightBlue,
        selectedColor: AppColors.primaryBlue,
        labelStyle: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.neutral,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.deepBlue,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
    );
  }
}
