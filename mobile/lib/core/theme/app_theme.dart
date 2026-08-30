import 'package:flutter/material.dart';

class AppTheme {
  // High-Contrast Accessible Palette
  static const Color primaryNavy = Color(0xFF0D1B2A);
  static const Color accentAmber = Color(0xFFFFB703);
  static const Color successGreen = Color(0xFF2A9D8F);
  static const Color alertRed = Color(0xFFE63946);
  static const Color backgroundGray = Color(0xFFF8F9FA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF101010);
  static const Color softTeal = Color(0xFF4DB6AC); // Added to fix undefined_getter error

  static final ThemeData elderlyTheme = ThemeData(
    scaffoldBackgroundColor: backgroundGray,
    primaryColor: primaryNavy,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.light(
      primary: primaryNavy,
      secondary: accentAmber,
      surface: surfaceWhite,
      error: alertRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryNavy,
      foregroundColor: surfaceWhite,
      centerTitle: true,
      elevation: 2,
    ),
    // Enforce high readability (minimum 18pt - 20pt base text size)
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
      headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textDark),
      titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
      titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textDark),
      bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
      bodyMedium: TextStyle(fontSize: 18, color: textDark),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryNavy,
      selectedItemColor: accentAmber,
      unselectedItemColor: Colors.white70,
      selectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  );
}