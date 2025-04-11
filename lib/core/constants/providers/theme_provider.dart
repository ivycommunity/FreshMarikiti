import 'package:flutter/material.dart';
import 'theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = lightMode;

  ThemeData get themeData => _themeData;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}

/*
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Apply the theme used by the system

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDarkMode = _themeMode == ThemeMode.dark;

    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await prefs.setBool("isDarkMode", !isDarkMode);

    notifyListeners(); // Notify after storage update
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isDarkMode = prefs.getBool("isDarkMode");

    if (isDarkMode != null) {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      notifyListeners(); // Notify after retrieving from storage
    }
  }
}
*/
