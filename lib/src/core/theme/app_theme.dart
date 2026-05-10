import 'package:flutter/material.dart';

class AppTheme {
  static const Color _brandBlue = Color(0xFF2196F3);
  static const Color _darkBrandBlue = Color(0xFF64B5F6);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandBlue,
      primary: _brandBlue,
      secondary: const Color(0xFF00B8D9),
      surface: Colors.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7FAFE),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandBlue,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandBlue,
      primary: _darkBrandBlue,
      secondary: const Color(0xFF4DD0E1),
      surface: const Color(0xFF141A21),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      cardColor: const Color(0xFF161D26),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF101923),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkBrandBlue,
          foregroundColor: const Color(0xFF071018),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _darkBrandBlue,
        foregroundColor: Color(0xFF071018),
      ),
      listTileTheme: const ListTileThemeData(iconColor: _darkBrandBlue),
    );
  }
}
