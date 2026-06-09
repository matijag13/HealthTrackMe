import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _localeKey = 'healthtrackme_locale';
  static const supportedLanguageCodes = ['en', 'sl'];

  Locale? _locale;

  Locale? get locale => _locale;

  String get languageCode => _locale?.languageCode ?? 'en';

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null && supportedLanguageCodes.contains(code)) {
      _locale = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode;
    if (!supportedLanguageCodes.contains(code)) return;
    if (_locale?.languageCode == code) return;

    _locale = Locale(code);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, code);
  }

  String labelForCode(String code) {
    return switch (code) {
      'sl' => 'Slovenščina',
      _ => 'English',
    };
  }
}
