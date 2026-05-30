import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightBackground,
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardTheme: CardThemeData(
        color: AppColors.lightSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.78),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.lightPrimary.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.lightPrimary.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.4),
        ),
      ),
      textTheme: _buildTextTheme(
        baseTheme: ThemeData.light().textTheme,
        textColor: AppColors.lightTextPrimary,
        mutedColor: AppColors.lightTextSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;

  static ThemeData get highContrastTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        surface: AppColors.hcBackground,
        primary: AppColors.hcPrimary,
        secondary: AppColors.hcSecondary,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.hcTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.hcBackground,
      cardTheme: CardThemeData(
        color: AppColors.hcSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.hcPrimary, width: 1.5),
        ),
      ),
      textTheme: _buildTextTheme(
        baseTheme: ThemeData.light().textTheme,
        textColor: AppColors.hcTextPrimary,
        mutedColor: AppColors.hcTextSecondary,
        isHighContrast: true,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.hcPrimary, size: 28),
        titleTextStyle: TextStyle(
          color: AppColors.hcPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme({
    required TextTheme baseTheme,
    required Color textColor,
    required Color mutedColor,
    bool isHighContrast = false,
  }) {
    final double scaleFactor = isHighContrast ? 1.15 : 1.0;

    return GoogleFonts.interTextTheme(baseTheme).copyWith(
      displayLarge: TextStyle(
        fontSize: 32 * scaleFactor,
        fontWeight: isHighContrast ? FontWeight.w900 : FontWeight.bold,
        color: textColor,
        letterSpacing: 0,
      ),
      displayMedium: TextStyle(
        fontSize: 28 * scaleFactor,
        fontWeight: isHighContrast ? FontWeight.w900 : FontWeight.bold,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 22 * scaleFactor,
        fontWeight: isHighContrast ? FontWeight.bold : FontWeight.w600,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 18 * scaleFactor,
        fontWeight: isHighContrast ? FontWeight.bold : FontWeight.w600,
        color: mutedColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16 * scaleFactor,
        fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * scaleFactor,
        fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
        color: mutedColor,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14 * scaleFactor,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: 0,
      ),
    );
  }
}
