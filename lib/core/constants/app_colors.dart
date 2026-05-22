import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // --- Theme Mode: Normal Dark ---
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceCard = Color(0xFF252525);
  
  static const Color darkPrimary = Color(0xFF6366F1); // Indigo
  static const Color darkSecondary = Color(0xFF06B6D4); // Cyan
  static const Color darkAccent = Color(0xFF10B981); // Emerald Green
  
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
  static const Color darkTextMuted = Color(0xFF9CA3AF);

  // --- Theme Mode: Normal Light ---
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF3F4F6);
  
  static const Color lightPrimary = Color(0xFF4F46E5); // Indigo Deep
  static const Color lightSecondary = Color(0xFF0891B2); // Cyan Deep
  static const Color lightAccent = Color(0xFF059669); // Emerald Deep
  
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF374151);
  static const Color lightTextMuted = Color(0xFF6B7280);

  // --- Accessibility Mode: High Contrast (Neon Visuals) ---
  // Ideal for low-vision (Tunanetra) or high-visibility needs
  static const Color hcBackground = Color(0xFF000000); // Pure Black
  static const Color hcSurface = Color(0xFF111111);
  static const Color hcSurfaceCard = Color(0xFF222222);
  
  static const Color hcPrimary = Color(0xFFFFEB3B); // Neon Yellow (highly readable on black)
  static const Color hcSecondary = Color(0xFF00FFFF); // Cyan Neon
  static const Color hcAccent = Color(0xFF39FF14); // Neon Green
  
  static const Color hcTextPrimary = Color(0xFFFFFFFF); // Pure White
  static const Color hcTextSecondary = Color(0xFFFFEB3B); // Neon Yellow
  static const Color hcTextMuted = Color(0xFFD3D3D3); // Light Grey

  // --- Common Status Colors ---
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
