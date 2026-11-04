import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_palette.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Seçili tam palet (5 tema). Değer AppPalette'te statik tutulur; burada
  // yalnızca UI yenilemesi (notify) tetiklenir.
  String get paletteId => AppPalette.currentId;

  Future<void> setPalette(String id) async {
    await AppPalette.set(id);
    notifyListeners();
  }

  static const String _themeKey = 'theme_mode';
  late SharedPreferences _prefs;
  bool _initialized = false;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final themeValue = _prefs.getString(_themeKey);

      if (themeValue != null) {
        if (themeValue == 'light') {
          _themeMode = ThemeMode.light;
        } else if (themeValue == 'dark') {
          _themeMode = ThemeMode.dark;
        } else {
          _themeMode = ThemeMode.system;
        }
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (!_initialized) {
      await _loadThemeMode();
    }

    _themeMode = mode;

    String themeValue;
    switch (mode) {
      case ThemeMode.light:
        themeValue = 'light';
        break;
      case ThemeMode.dark:
        themeValue = 'dark';
        break;
      default:
        themeValue = 'system';
    }

    try {
      await _prefs.setString(_themeKey, themeValue);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }

    notifyListeners();
  }
}
