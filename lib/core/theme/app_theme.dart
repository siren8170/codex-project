import 'package:flutter/material.dart';

class AppColors {
  static const forest = Color(0xFF173E35);
  static const background = Color(0xFFF6F7F2);
  static const mint = Color(0xFFBDEAAC);
  static const ink = Color(0xFF182F2B);
  static const green = Color(0xFF4B9567);
  static const softGreen = Color(0xFFEEF5E9);
  static const muted = Color(0xFF66746D);
  static const border = Color(0xFFE1E8DF);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      primary: AppColors.forest,
      secondary: AppColors.green,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -0.8,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 34,
          height: 1.18,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -1.6,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -0.7,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.65,
          color: AppColors.muted,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.green,
          letterSpacing: 1,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.forest,
        unselectedItemColor: AppColors.muted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
