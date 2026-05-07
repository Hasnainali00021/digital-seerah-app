import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app-wide dark/light mode toggle.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

ThemeMode initialThemeMode = ThemeMode.light;

const String _themeModePrefsKey = 'theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(initialThemeMode);

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModePrefsKey, mode.name);
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    unawaited(_saveThemeMode(mode));
  }

  void toggle() {
    final nextMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setThemeMode(nextMode);
  }

  bool get isDark => state == ThemeMode.dark;
}
