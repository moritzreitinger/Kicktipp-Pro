import 'package:flutter/material.dart';

enum AppThemeMode {
  grassGreen,
  floodlightNight,
  redDerby,
  goldenTrophy,
  steelCity,
}

class ThemeColors {
  final Color primary;
  final Color light;
  final Color medium;
  final Color dark;

  const ThemeColors({
    required this.primary,
    required this.light,
    required this.medium,
    required this.dark,
  });
}

class AppTheme {
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);
  static const Color darkGray = Color(0xFF616161);
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color segmentSelected = Color(0xFFEEEEEE);

  // Default theme (Golden Trophy / Orange)
  static const Color primaryOrange = Color(0xFFE67E22);

  // Theme Farben
  static const Map<AppThemeMode, ThemeColors> themeColors = {
    AppThemeMode.grassGreen: ThemeColors(
      primary: Color(0xFF27AE60),
      light: Color(0xFF2ECC71),
      medium: Color(0xFF229954),
      dark: Color(0xFF1E8449),
    ),
    AppThemeMode.floodlightNight: ThemeColors(
      primary: Color(0xFF2980B9),
      light: Color(0xFF3498DB),
      medium: Color(0xFF2874A6),
      dark: Color(0xFF1B4F72),
    ),
    AppThemeMode.redDerby: ThemeColors(
      primary: Color(0xFFE74C3C),
      light: Color(0xFFEC7063),
      medium: Color(0xFFC0392B),
      dark: Color(0xFF922B21),
    ),
    AppThemeMode.goldenTrophy: ThemeColors(
      primary: Color(0xFFE67E22),
      light: Color(0xFFF39C12),
      medium: Color(0xFFD68910),
      dark: Color(0xFFB8641B),
    ),
    AppThemeMode.steelCity: ThemeColors(
      primary: Color(0xFF34495E),
      light: Color(0xFF5D6D7B),
      medium: Color(0xFF2C3E50),
      dark: Color(0xFF1A252F),
    ),
  };

  static Color getPrimaryColor(AppThemeMode mode) {
    return themeColors[mode]?.primary ?? primaryOrange;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        primary: primaryOrange,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      scaffoldBackgroundColor: lightGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: segmentSelected,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: cardBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
