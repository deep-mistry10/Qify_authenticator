import 'package:flutter/material.dart';

ThemeData buildQifyTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF245B8F),
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? const Color(0xFF101418) : const Color(0xFFF5F7F9),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: isDark ? const Color(0xFF101418) : const Color(0xFFF5F7F9),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      filled: true,
      fillColor: isDark ? const Color(0xFF171C21) : Colors.white,
    ),
  );
}
