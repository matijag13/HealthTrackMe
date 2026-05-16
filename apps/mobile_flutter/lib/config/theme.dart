import 'package:flutter/material.dart';

class AppColors {
  static const Color navy = Color(0xFF1A3A5C);
  static const Color blue = Color(0xFF4A90D9);
  static const Color teal = Color(0xFF2EC4B6);
  static const Color softBlue = Color(0xFFEAF4FB);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFE05252);
  static const Color success = Color(0xFF27AE60);
  static const Color background = Color(0xFFF0F6FC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1A1A2E);
  static const Color muted = Color(0xFF6B7280);
  static const Color border = Color(0xFFDDE8F0);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        primary: AppColors.blue,
        secondary: AppColors.teal,
        surface: AppColors.card,
        error: AppColors.danger,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(color: AppColors.text),
        bodyMedium: TextStyle(color: AppColors.text),
        titleMedium:
            TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
        titleLarge:
            TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
        labelSmall: TextStyle(color: AppColors.muted),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
