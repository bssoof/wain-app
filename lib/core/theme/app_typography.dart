import 'package:flutter/material.dart';

/// Centralized text scale for the WAIN design system.
class AppTypography {
  AppTypography._();

  static TextTheme buildTextTheme({
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
  }) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: textSecondary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textTertiary,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: textTertiary,
      ),
    );
  }
}
