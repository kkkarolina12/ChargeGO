import 'package:flutter/material.dart';

class ChargeGoColors {
  static const ice = Color(0xFFF5FAFF);
  static const frost = Color(0xFFEAF5FF);
  static const sky = Color(0xFF9AD1FF);
  static const electric = Color(0xFF409BFF);
  static const royal = Color(0xFF2359B8);
  static const navy = Color(0xFF0B2D69);
  static const graphite = Color(0xFF1E2937);
  static const muted = Color(0xFF65758B);
  static const cyan = Color(0xFF4DD9F7);
  static const success = Color(0xFF12A875);
  static const danger = Color(0xFFE5484D);
}

class AppTheme {
  static const Color _brandBlue = ChargeGoColors.royal;
  static const Color _darkBrandBlue = ChargeGoColors.sky;

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandBlue,
      primary: _brandBlue,
      secondary: ChargeGoColors.cyan,
      tertiary: ChargeGoColors.electric,
      surface: Colors.white,
      error: ChargeGoColors.danger,
      brightness: Brightness.light,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      scaffoldBackgroundColor: ChargeGoColors.ice,
      cardColor: Colors.white,
      visualDensity: VisualDensity.standard,
      textTheme: base.textTheme.apply(
        bodyColor: ChargeGoColors.graphite,
        displayColor: ChargeGoColors.graphite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ChargeGoColors.navy,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: ChargeGoColors.navy,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        prefixIconColor: ChargeGoColors.royal,
        labelStyle: const TextStyle(color: ChargeGoColors.muted),
        hintStyle: TextStyle(
          color: ChargeGoColors.muted.withValues(alpha: 0.72),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: ChargeGoColors.sky.withValues(alpha: 0.28),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: ChargeGoColors.electric,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ChargeGoColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: ChargeGoColors.danger,
            width: 1.4,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ChargeGoColors.royal,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ChargeGoColors.royal,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ChargeGoColors.royal,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: ChargeGoColors.royal,
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ChargeGoColors.navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return ChargeGoColors.royal;
            }
            return Colors.white;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return ChargeGoColors.navy;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: ChargeGoColors.sky.withValues(alpha: 0.35)),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _darkBrandBlue,
      primary: _darkBrandBlue,
      secondary: ChargeGoColors.cyan,
      tertiary: ChargeGoColors.electric,
      surface: const Color(0xFF111A28),
      error: const Color(0xFFFF8A8D),
      brightness: Brightness.dark,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF07111F),
      cardColor: const Color(0xFF111A28),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111A28),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF101B2B),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        prefixIconColor: ChargeGoColors.sky,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.48)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ChargeGoColors.sky, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkBrandBlue,
          foregroundColor: const Color(0xFF07111F),
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _darkBrandBlue,
        foregroundColor: Color(0xFF07111F),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ChargeGoColors.sky,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _darkBrandBlue,
        textColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF15233A),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return ChargeGoColors.sky;
            }
            return const Color(0xFF101B2B);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF07111F);
            }
            return Colors.white;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
      ),
    );
  }
}
