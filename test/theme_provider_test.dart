import 'package:conecta_mais/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'uses the system theme by default and persists user selection',
    () async {
      SharedPreferences.setMockInitialValues({});
      final provider = await AppThemeProvider.load();

      expect(provider.themeMode, ThemeMode.system);

      await provider.setThemeMode(ThemeMode.dark);
      final reloadedProvider = await AppThemeProvider.load();

      expect(reloadedProvider.themeMode, ThemeMode.dark);
    },
  );
}
