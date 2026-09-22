import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale_code';

  SettingsCubit() : super(const SettingsState(
    themeMode: ThemeMode.system,
    locale: Locale('en'),
  )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Theme
    final isDark = prefs.getBool(_themeKey);
    ThemeMode mode = ThemeMode.system;
    if (isDark != null) {
      mode = isDark ? ThemeMode.dark : ThemeMode.light;
    }

    // Load Locale
    final langCode = prefs.getString(_localeKey) ?? 'en';
    final locale = Locale(langCode);

    emit(state.copyWith(themeMode: mode, locale: locale));
  }

  Future<void> toggleTheme(bool isDark) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    emit(state.copyWith(themeMode: mode));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  Future<void> changeLanguage(String languageCode) async {
    final locale = Locale(languageCode);
    emit(state.copyWith(locale: locale));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }
}
