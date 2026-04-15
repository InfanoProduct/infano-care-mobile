import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand
  static const Color purple       = Color(0xFF7C3AED);
  static const Color purpleLight  = Color(0xFFA855F7);
  static const Color pink         = Color(0xFFEC4899);
  static const Color pinkLight    = Color(0xFFF472B6);

  // Surface
  static const Color background   = Color(0xFFFDF4FF);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color surfaceCard  = Color(0xFFF9F0FF);

  // Text
  static const Color textDark     = Color(0xFF1E1B4B);
  static const Color textMedium   = Color(0xFF4B5563);
  static const Color textLight    = Color(0xFF9CA3AF);

  // Accent
  static const Color bloom        = Color(0xFFFBBF24);  // gold bloom highlight
  static const Color success      = Color(0xFF10B981);
  static const Color error        = Color(0xFFEF4444);
  static const Color softAmber    = Color(0xFFFFFBEB);
  static const Color teal         = Color(0xFF0D9488);

  // Gradient stops
  static const List<Color> brandGradient = [purple, pink];
  static const List<Color> cardGradient  = [Color(0xFFF5F3FF), Color(0xFFFDF2F8)];
}

class AppGradients {
  static const LinearGradient brand = LinearGradient(
    colors: AppColors.brandGradient,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient brandDiagonal = LinearGradient(
    colors: AppColors.brandGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softCard = LinearGradient(
    colors: AppColors.cardGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.nunito(
          fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textDark,
        ),
        displayMedium: GoogleFonts.nunito(
          fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark,
        ),
        headlineLarge: GoogleFonts.nunito(
          fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textDark,
        ),
        headlineMedium: GoogleFonts.nunito(
          fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textMedium,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textMedium,
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.surface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE9D5FF), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE9D5FF), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.purple, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.nunito(color: AppColors.textLight),
      ),
    );
  }
}
