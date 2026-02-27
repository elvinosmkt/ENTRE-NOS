import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFFFF4DA3);
  static const Color primarySoft = Color(0xFFFFE5F3);
  static const Color secondary = Color(0xFF7C3AED);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF8F5F7);
  static const Color backgroundDark = Color(0xFF230F19);

  // Surface / Card
  static const Color surfaceLight = Color(0xFFF9FAFB);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF2A1F3D);

  // Neon Palette
  static const Color neonPink = Color(0xFFFF4DA3);
  static const Color neonBlue = Color(0xFF3B82F6);
  static const Color neonGreen = Color(0xFF4ADE80);
  static const Color neonPurple = Color(0xFF7C3AED);

  // Text Colors
  static const Color textLight = Color(0xFF1E232C);
  static const Color textDark = Color(0xFFF1F5F9);
  static const Color textGrey = Color(0xFF8391A1);
  static const Color textGreyDark = Color(0xFF9CA3B0);

  // Dividers / Borders
  static const Color dividerLight = Color(0xFFF3F4F6);
  static const Color dividerDark = Color(0xFF2D2D44);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF3D3D5C);

  // General Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color error = Color(0xFFFF4D4D);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFFB800);
}

/// Extension to get theme-aware colors easily
extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get surfaceColor => isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get cardColor => isDark ? AppColors.cardDark : AppColors.cardLight;
  Color get textColor => isDark ? AppColors.textDark : AppColors.textLight;
  Color get textSecondary => isDark ? AppColors.textGreyDark : AppColors.textGrey;
  Color get dividerColor => isDark ? AppColors.dividerDark : AppColors.dividerLight;
  Color get borderColor => isDark ? AppColors.borderDark : AppColors.borderLight;
}
