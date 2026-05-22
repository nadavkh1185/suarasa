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
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardTheme: CardThemeData(
        color: AppColors.lightSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkBackground,
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: _buildTextTheme(
        baseTheme: ThemeData.dark().textTheme,
        textColor: AppColors.darkTextPrimary,
        mutedColor: AppColors.darkTextSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData get highContrastTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.hcBackground,
        primary: AppColors.hcPrimary,
        secondary: AppColors.hcSecondary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.hcBackground,
      cardTheme: CardThemeData(
        color: AppColors.hcSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.hcPrimary, width: 2),
        ),
      ),
      textTheme: _buildTextTheme(
        baseTheme: ThemeData.dark().textTheme,
        textColor: AppColors.hcTextPrimary,
        mutedColor: AppColors.hcTextSecondary,
        isHighContrast: true,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.hcSurface,
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
    // High contrast has slightly larger font sizes and bolder weights for accessibility
    final double scaleFactor = isHighContrast ? 1.15 : 1.0;
    
    return GoogleFonts.interTextTheme(baseTheme).copyWith(
      displayLarge: TextStyle(
        fontSize: 32 * scaleFactor,
        fontWeight: isHighContrast ? FontWeight.w900 : FontWeight.bold,
        color: textColor,
        letterSpacing: -0.5,
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
        letterSpacing: 1.0,
      ),
    );
  }
}
