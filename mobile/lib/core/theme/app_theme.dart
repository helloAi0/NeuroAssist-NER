import 'package:flutter/material.dart';

class AppTheme {
  // Core Colors
  static const Color primaryNavy = Color(0xFF1A237E);
  static const Color accentAmber = Color(0xFFFFC107);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color softTeal = Color(0xFF26A69A);
  static const Color alertRed = Color(0xFFD32F2F);
  static const Color backgroundGray = Color(0xFFF5F5F5);
  
  // The explicitly required colors for the Memory Game
  static const Color surfaceWhite = Colors.white;
  static const Color textDark = Colors.black87;

  // The main theme data
  static final ThemeData elderlyTheme = ThemeData(
    scaffoldBackgroundColor: backgroundGray,
    primaryColor: primaryNavy,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1A237E), // primaryNavy
      secondary: Color(0xFFFFC107), // accentAmber
      surface: Colors.white, // surfaceWhite
      error: Color(0xFFD32F2F), // alertRed
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A237E),
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
      titleMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textDark),
      bodyLarge: TextStyle(fontSize: 22, color: textDark),
      bodyMedium: TextStyle(fontSize: 20, color: textDark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}