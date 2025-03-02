import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!Intl.defaultLocale!.contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
  }

  void changeLanguage() {
    if (_locale.languageCode == 'en') {
      setLocale(const Locale('sw'));
    } else {
      setLocale(const Locale('en'));
    }
  }
}
