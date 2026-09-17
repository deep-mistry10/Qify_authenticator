import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

ThemeData buildQifyTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: isDark ? const Color(0xFF42B39B) : AppConstants.primary,
    onPrimary: Colors.white,
    primaryContainer: isDark ? const Color(0xFF0D4D40) : const Color(0xFFDCEFE9),
    onPrimaryContainer: isDark ? const Color(0xFFC4F4E7) : const Color(0xFF075541),
    secondary: isDark ? const Color(0xFF9AB4AC) : const Color(0xFF55716A),
    onSecondary: Colors.white,
    secondaryContainer: isDark ? const Color(0xFF2A3D38) : const Color(0xFFE6ECE9),
    onSecondaryContainer: isDark ? const Color(0xFFDCEBE6) : const Color(0xFF223A34),
    tertiary: isDark ? const Color(0xFFA8C7BD) : const Color(0xFF58756D),
    onTertiary: Colors.white,
    tertiaryContainer: isDark ? const Color(0xFF30433E) : const Color(0xFFE7EEEB),
    onTertiaryContainer: isDark ? const Color(0xFFD9ECE6) : const Color(0xFF263F38),
    error: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: isDark ? const Color(0xFF5C201B) : const Color(0xFFF9DEDC),
    onErrorContainer: isDark ? const Color(0xFFFFDAD6) : const Color(0xFF410E0B),
    surface: isDark ? const Color(0xFF111613) : AppConstants.surface,
    onSurface: isDark ? const Color(0xFFE3E5E2) : AppConstants.textPrimary,
    surfaceContainerHighest: isDark ? const Color(0xFF252B28) : AppConstants.surfaceSoft,
    onSurfaceVariant: isDark ? const Color(0xFFC0C9C5) : AppConstants.textSecondary,
    outline: isDark ? const Color(0xFF8C9691) : AppConstants.border,
    outlineVariant: isDark ? const Color(0xFF414945) : const Color(0xFFE5EAE7),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: isDark ? AppConstants.surface : const Color(0xFF29302C),
    onInverseSurface: isDark ? AppConstants.textPrimary : Colors.white,
    inversePrimary: isDark ? AppConstants.primary : const Color(0xFF72D3BB),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF111613)
        : AppConstants.background,
    visualDensity: VisualDensity.standard,

    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: isDark
          ? const Color(0xFF111613)
          : AppConstants.background,
      foregroundColor: isDark ? const Color(0xFFE3E5E2) : AppConstants.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: isDark ? const Color(0xFFE3E5E2) : AppConstants.textPrimary,
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
    ),

    cardTheme: CardThemeData(
      color: isDark ? const Color(0xFF171C19) : AppConstants.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF303833) : AppConstants.border,
          width: 1,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF171C19) : AppConstants.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF909B96) : const Color(0xFF82908A),
      ),
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFFB6C1BC) : AppConstants.textSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF39423D) : AppConstants.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF39423D) : AppConstants.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF42B39B) : AppConstants.primary,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFB3261E)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.6),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF2C947C) : AppConstants.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: isDark
            ? const Color(0xFF28332F)
            : const Color(0xFFD9E2DE),
        disabledForegroundColor: isDark
            ? const Color(0xFF8E9B96)
            : const Color(0xFF7C8984),
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? const Color(0xFF42B39B) : AppConstants.primary,
        side: BorderSide(
          color: isDark ? const Color(0xFF60736C) : const Color(0xFF8B9691),
          width: 1.2,
        ),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? const Color(0xFF42B39B) : AppConstants.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: isDark ? const Color(0xFFDDE5E1) : AppConstants.textPrimary,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: isDark ? const Color(0xFF2C947C) : AppConstants.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: isDark ? const Color(0xFF1A211E) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF39423D) : AppConstants.border,
        ),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: isDark ? const Color(0xFF303833) : AppConstants.border,
      thickness: 1,
      space: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF252B28) : const Color(0xFF202623),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),

    textTheme: TextTheme(
      displaySmall: TextStyle(
        color: isDark ? const Color(0xFFE7EAE7) : AppConstants.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      headlineLarge: TextStyle(
        color: isDark ? const Color(0xFFE7EAE7) : AppConstants.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        color: isDark ? const Color(0xFFE7EAE7) : AppConstants.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      headlineSmall: TextStyle(
        color: isDark ? const Color(0xFFE7EAE7) : AppConstants.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: isDark ? const Color(0xFFE7EAE7) : AppConstants.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: isDark ? const Color(0xFFE7EAE7) : AppConstants.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: isDark ? const Color(0xFFE7EAE7) : AppConstants.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: isDark ? const Color(0xFFC0CAC5) : AppConstants.textSecondary,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        color: isDark ? const Color(0xFFB1BCB7) : AppConstants.textSecondary,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        color: isDark ? const Color(0xFF98A49F) : AppConstants.textMuted,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: isDark ? const Color(0xFFE1E6E3) : AppConstants.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
