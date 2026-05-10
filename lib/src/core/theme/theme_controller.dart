import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
      return ThemeController();
    });

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  static const _themeModeKey = 'theme_mode';

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, mode.name);
  }

  Future<void> _loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_themeModeKey);

    if (value == ThemeMode.dark.name) {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
  }
}
