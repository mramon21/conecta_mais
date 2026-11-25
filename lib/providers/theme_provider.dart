import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeProvider extends ChangeNotifier {
  AppThemeProvider._(this._preferences, this._themeMode);

  static const _themeModeKey = 'theme_mode';

  final SharedPreferences _preferences;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  static Future<AppThemeProvider> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_themeModeKey);
    final themeMode = ThemeMode.values.where((mode) => mode.name == savedMode);
    return AppThemeProvider._(
      preferences,
      themeMode.isEmpty ? ThemeMode.system : themeMode.first,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final saved = await _preferences.setString(_themeModeKey, mode.name);
    if (!saved) {
      throw StateError('Não foi possível salvar a preferência de tema.');
    }
    _themeMode = mode;
    notifyListeners();
  }
}
