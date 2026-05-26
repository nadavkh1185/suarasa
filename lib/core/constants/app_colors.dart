import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // --- Theme Mode: Calm Light ---
  static const Color lightBackground = Color(0xFFEAF7FF);
  static const Color lightBackgroundEnd = Color(0xFFCDEBFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xF2FFFFFF);
  
  static const Color lightPrimary = Color(0xFF0F4C81);
  static const Color lightSecondary = Color(0xFF1B8FBF);
  static const Color lightAccent = Color(0xFF2DBE9F);
  
  static const Color lightTextPrimary = Color(0xFF082B4C);
  static const Color lightTextSecondary = Color(0xFF17476B);
  static const Color lightTextMuted = Color(0xFF4D6D86);

  // --- Haptic Focus Mode ---
  // Tetap terang dan tidak kontras ekstrem; mode ini mengutamakan getaran dan suara.
  static const Color hcBackground = Color(0xFFD8F0FF);
  static const Color hcSurface = Color(0xFFEFFAFF);
  static const Color hcSurfaceCard = Color(0xFFFFFFFF);
  
  static const Color hcPrimary = Color(0xFF062947);
  static const Color hcSecondary = Color(0xFF0B6E99);
  static const Color hcAccent = Color(0xFF047857);
  
  static const Color hcTextPrimary = Color(0xFF061F36);
  static const Color hcTextSecondary = Color(0xFF0F3C5B);
  static const Color hcTextMuted = Color(0xFF456B86);

  // --- Common Status Colors ---
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
