import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _languageCode = 'en';
  Locale _locale = const Locale('en', 'US');

  bool get isDarkMode => _isDarkMode;
  Locale get locale => _locale;
  String get languageCode => _languageCode;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _languageCode = prefs.getString('languageCode') ?? 'en';
      _setLocale(_languageCode);
      notifyListeners();  // 👈 Important - UI rebuild cheyyan
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  // 👇 Dark Mode Toggle - Full app maran
  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    notifyListeners();  // 👈 Important - Full app rebuild
  }

  Future<void> changeLanguage(String languageCode) async {
    _languageCode = languageCode;
    _setLocale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
    notifyListeners();
  }

  void _setLocale(String languageCode) {
    switch (languageCode) {
      case 'en':
        _locale = const Locale('en', 'US');
        break;
      case 'ml':
        _locale = const Locale('ml', 'IN');
        break;
      case 'hi':
        _locale = const Locale('hi', 'IN');
        break;
      case 'ta':
        _locale = const Locale('ta', 'IN');
        break;
      default:
        _locale = const Locale('en', 'US');
    }
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English 🇬🇧';
      case 'ml':
        return 'Malayalam 🇮🇳';
      case 'hi':
        return 'Hindi 🇮🇳';
      case 'ta':
        return 'Tamil 🇮🇳';
      default:
        return 'English 🇬🇧';
    }
  }

  List<Map<String, String>> get supportedLanguages {
    return [
      {'code': 'en', 'name': 'English 🇬🇧'},
      {'code': 'ml', 'name': 'Malayalam 🇮🇳'},
      {'code': 'hi', 'name': 'Hindi 🇮🇳'},
      {'code': 'ta', 'name': 'Tamil 🇮🇳'},
    ];
  }
}