import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/e_colors.dart';
import '../constants/e_sizes.dart';

/// App theme configuration for BingeQuest.
/// Dark theme with purple/magenta gradients, orange accents.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: EColors.primary,
        onPrimary: EColors.textOnPrimary,
        primaryContainer: EColors.primaryDark,
        secondary: EColors.secondary,
        onSecondary: EColors.textOnPrimary,
        secondaryContainer: EColors.secondaryDark,
        tertiary: EColors.tertiary,
        surface: EColors.surface,
        onSurface: EColors.textPrimary,
        error: EColors.error,
        onError: EColors.textOnPrimary,
      ),
      scaffoldBackgroundColor: EColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: EColors.background,
        foregroundColor: EColors.textPrimary,
        elevation: ESizes.appBarElevation,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: EColors.textPrimary,
          fontSize: ESizes.fontXl,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: EColors.surface,
        selectedItemColor: EColors.primary,
        unselectedItemColor: EColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: EColors.surface,
        indicatorColor: EColors.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: EColors.primary,
              fontSize: ESizes.fontSm,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: EColors.textTertiary,
            fontSize: ESizes.fontSm,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: EColors.primary);
          }
          return const IconThemeData(color: EColors.textTertiary);
        }),
      ),
      cardTheme: CardThemeData(
        color: EColors.cardBackground,
        elevation: ESizes.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ESizes.cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EColors.primary,
          foregroundColor: EColors.textOnPrimary,
          minimumSize: const Size(double.infinity, ESizes.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ESizes.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: ESizes.fontLg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: EColors.primary,
          minimumSize: const Size(double.infinity, ESizes.buttonHeightMd),
          side: const BorderSide(color: EColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ESizes.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: ESizes.fontLg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: EColors.primary,
          textStyle: const TextStyle(
            fontSize: ESizes.fontMd,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: EColors.accent,
        foregroundColor: EColors.textOnAccent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ESizes.md,
          vertical: ESizes.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          borderSide: const BorderSide(color: EColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          borderSide: const BorderSide(color: EColors.error),
        ),
        hintStyle: const TextStyle(color: EColors.textTertiary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: EColors.surfaceLight,
        selectedColor: EColors.primary,
        labelStyle: const TextStyle(color: EColors.textPrimary),
        secondaryLabelStyle: const TextStyle(color: EColors.textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ESizes.radiusRound),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: EColors.divider,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: EColors.primary,
        linearTrackColor: EColors.surfaceLight,
        circularTrackColor: EColors.surfaceLight,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: EColors.surface,
        contentTextStyle: const TextStyle(color: EColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: EColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ESizes.radiusLg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: EColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ESizes.radiusLg),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: ESizes.fontDisplay,
          fontWeight: FontWeight.bold,
          color: EColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: ESizes.fontXxl,
          fontWeight: FontWeight.bold,
          color: EColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: ESizes.fontXl,
          fontWeight: FontWeight.bold,
          color: EColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: ESizes.fontXl,
          fontWeight: FontWeight.w600,
          color: EColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: ESizes.fontLg,
          fontWeight: FontWeight.w600,
          color: EColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: ESizes.fontLg,
          fontWeight: FontWeight.w600,
          color: EColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: ESizes.fontMd,
          fontWeight: FontWeight.w500,
          color: EColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: ESizes.fontSm,
          fontWeight: FontWeight.w500,
          color: EColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: ESizes.fontLg,
          color: EColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: ESizes.fontMd,
          color: EColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: ESizes.fontSm,
          color: EColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: ESizes.fontMd,
          fontWeight: FontWeight.w600,
          color: EColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: ESizes.fontSm,
          fontWeight: FontWeight.w500,
          color: EColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: ESizes.fontXs,
          color: EColors.textTertiary,
        ),
      ),
    );
  }
}
