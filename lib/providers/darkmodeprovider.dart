import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DarkModeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  Future<void> loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool("darkMode") ?? false;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = !_isDarkMode;
    await prefs.setBool("darkMode", _isDarkMode);
    notifyListeners();
  }
}