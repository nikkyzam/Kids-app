import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF5B8DEF);
  static const Color primaryLight = Color(0xFFEEF3FE);
  static const Color secondary = Color(0xFFF5A623);
  static const Color surface = Color(0xFFFAFBFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1D2E);
  static const Color textMuted = Color(0xFF8E93A6);
  static const Color success = Color(0xFF4CAF7D);
  static const Color successLight = Color(0xFFE8F8EF);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);

  static const Color grossMotorColor = Color(0xFF5B8DEF);
  static const Color fineMotorColor = Color(0xFF9C6FDE);
  static const Color languageColor = Color(0xFF26C6DA);
  static const Color cognitiveColor = Color(0xFFF5A623);
  static const Color socialEmotionalColor = Color(0xFFFF7043);
  static const Color sensoryColor = Color(0xFF66BB6A);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          surface: surface,
        ),
        scaffoldBackgroundColor: surface,
        fontFamily: 'Nunito',
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEEF0F7), width: 1),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w800, color: textDark),
          displayMedium: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, color: textDark),
          titleLarge: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: textDark),
          titleMedium: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
          bodyLarge: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w400, color: textDark),
          bodyMedium: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w400, color: textMuted),
          labelLarge: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: textDark),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4F6FB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
        ),
      );
}
