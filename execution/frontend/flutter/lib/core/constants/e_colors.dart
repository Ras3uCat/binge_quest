import 'package:flutter/material.dart';

/// App color constants following the E-prefix convention.
/// Primary theme: Dark mode with purple/magenta gradients
/// Accent: Orange (CTAs, badges), Cyan/teal (secondary)
class EColors {
  EColors._();

  // Primary colors - Purple/Magenta gradient
  static const Color primary = Color(0xFF9C27B0);
  static const Color primaryDark = Color(0xFF7B1FA2);
  static const Color primaryLight = Color(0xFFCE93D8);

  // Secondary - Magenta
  static const Color secondary = Color(0xFFE91E63);
  static const Color secondaryDark = Color(0xFFC2185B);
  static const Color secondaryLight = Color(0xFFF48FB1);

  // Accent - Orange for CTAs and badges
  static const Color accent = Color(0xFFFF9800);
  static const Color accentDark = Color(0xFFF57C00);
  static const Color accentLight = Color(0xFFFFCC80);

  // Tertiary - Cyan/Teal (RAS3UCAT brand)
  static const Color tertiary = Color(0xFF00BCD4);
  static const Color tertiaryDark = Color(0xFF0097A7);
  static const Color tertiaryLight = Color(0xFF80DEEA);

  // Background colors (Dark theme)
  static const Color background = Color(0xFF121212);
  static const Color backgroundSecondary = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF252525);
  static const Color surfaceLight = Color(0xFF2C2C2C);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF000000);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFF5722)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surface, backgroundSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Card and border colors
  static const Color cardBackground = surface;
  static const Color divider = Color(0xFF3A3A3A);
  static const Color border = Color(0xFF424242);

  // Shimmer colors for loading states
  static const Color shimmerBase = Color(0xFF2A2A2A);
  static const Color shimmerHighlight = Color(0xFF3A3A3A);
}
