import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla el modo de tema (claro/oscuro) de toda la app de forma global
/// y persistente en el dispositivo.
class ThemeProvider {
  ThemeProvider._internal();
  static final ThemeProvider instance = ThemeProvider._internal();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  bool get isDarkMode => themeMode.value == ThemeMode.dark;

  /// Debe llamarse antes de runApp() para aplicar el tema guardado sin parpadeos.
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('tema_app');
    themeMode.value = saved == 'oscuro' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDarkMode(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tema_app', isDark ? 'oscuro' : 'claro');
  }

  Future<void> toggle() => setDarkMode(!isDarkMode);
}
