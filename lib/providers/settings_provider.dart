import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  bool _useDynamicColor = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get useDynamicColor => _useDynamicColor;

  SettingsProvider() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = switch (prefs.getString('theme_mode') ?? 'system') {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _locale = Locale(prefs.getString('locale') ?? 'en');
    _useDynamicColor = prefs.getBool('use_dynamic_color') ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    (await SharedPreferences.getInstance()).setString('locale', locale.languageCode);
  }

  Future<void> setUseDynamicColor(bool value) async {
    _useDynamicColor = value;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool('use_dynamic_color', value);
  }
}