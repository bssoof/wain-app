import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// App theme configuration and backwards-compatible color aliases.
class AppTheme {
  AppTheme._();

  // Backwards-compatible aliases used across the current codebase.
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.primaryLight;
  static const Color accentColor = AppColors.primarySoft;
  static const Color primarySurfaceColor = AppColors.primarySurface;

  static const Color successColor = AppColors.success;
  static const Color errorColor = AppColors.error;
  static const Color warningColor = AppColors.warning;
  static const Color infoColor = AppColors.info;

  static const Color backgroundColor = AppColors.background;
  static const Color surfaceColor = AppColors.surface;
  static const Color surfaceTintedColor = AppColors.surfaceTinted;
  static const Color borderColor = AppColors.border;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textTertiary = AppColors.textTertiary;

  static const Color darkBackground = AppColors.darkBackground;
  static const Color darkSurface = AppColors.darkSurface;
  static const Color darkSurfaceTinted = AppColors.darkSurfaceTinted;
  static const Color darkBorder = AppColors.darkBorder;
  static const Color darkTextPrimary = AppColors.darkTextPrimary;
  static const Color darkTextSecondary = AppColors.darkTextSecondary;
  static const Color darkTextTertiary = AppColors.darkTextTertiary;

  static ThemeData get lightTheme => _buildTheme(brightness: Brightness.light);

  static ThemeData get darkTheme => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = _buildColorScheme(isDark: isDark);
    final textTheme = AppTypography.buildTextTheme(
      textPrimary: isDark ? darkTextPrimary : textPrimary,
      textSecondary: isDark ? darkTextSecondary : textSecondary,
      textTertiary: isDark ? darkTextTertiary : textTertiary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Cairo',
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? darkBackground : backgroundColor,
      canvasColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: textTheme.titleLarge,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.radiusMd,
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusMd),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurfaceTinted : surfaceTintedColor,
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMd,
          borderSide: const BorderSide(color: primaryColor, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMd,
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMd,
          borderSide: const BorderSide(color: errorColor, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withAlpha(90),
          disabledForegroundColor: colorScheme.onPrimary.withAlpha(170),
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: textTheme.labelMedium,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusMd),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.xl),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? darkSurfaceTinted : surfaceTintedColor,
        disabledColor: (isDark ? darkSurfaceTinted : surfaceTintedColor)
            .withAlpha(170),
        selectedColor: primarySurfaceColor,
        secondarySelectedColor: primarySurfaceColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusSm),
        labelStyle: textTheme.titleSmall ?? const TextStyle(),
        secondaryLabelStyle: (textTheme.titleSmall ?? const TextStyle())
            .copyWith(color: colorScheme.primary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusMd),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
    );
  }

  static ColorScheme _buildColorScheme({required bool isDark}) {
    final base = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    return base.copyWith(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: isDark
          ? AppColors.darkPrimarySurface
          : primarySurfaceColor,
      onPrimaryContainer: isDark ? darkTextPrimary : primaryColor,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      tertiary: accentColor,
      onTertiary: Colors.white,
      error: errorColor,
      onError: Colors.white,
      surface: isDark ? darkSurface : surfaceColor,
      onSurface: isDark ? darkTextPrimary : textPrimary,
      onSurfaceVariant: isDark ? darkTextSecondary : textSecondary,
      outline: isDark ? darkBorder : borderColor,
      shadow: isDark ? Colors.black : AppColors.shadowSoft,
      surfaceTint: Colors.transparent,
    );
  }
}
