import 'package:flutter/material.dart';

/// Centralized color tokens for the WAIN design system.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFC0006F);
  static const Color primaryLight = Color(0xFFE91E8C);
  static const Color primarySoft = Color(0xFFFF6B9D);
  static const Color primarySurface = Color(0xFFFFF0F6);
  static const Color darkPrimarySurface = Color(0xFF4A1735);

  // Light neutrals
  static const Color background = Color(0xFFF5F5F8);
  static const Color surface = Colors.white;
  static const Color surfaceTinted = Color(0xFFFAFAFA);
  static const Color border = Color(0xFFE8E8EC);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Dark neutrals
  static const Color darkBackground = Color(0xFF121214);
  static const Color darkSurface = Color(0xFF1E1E22);
  static const Color darkSurfaceTinted = Color(0xFF2A2A30);
  static const Color darkBorder = Color(0xFF3A3A42);
  static const Color darkTextPrimary = Color(0xFFF0F0F2);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextTertiary = Color(0xFF6B7280);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Utility
  static const Color shadowSoft = Color(0x0F000000);
  static const Color shadowOverlay = Color(0x1F000000);
}
