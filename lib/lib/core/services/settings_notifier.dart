// lib/core/services/settings_notifier.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'translation_service.dart'; // ← ADD

class SettingsNotifier extends ChangeNotifier {
  bool   _darkMode           = false;
  bool   _notifications      = true;
  bool   _hapticFeedback     = true;
  bool   _autoCleanReminders = true;
  bool   _clearCacheOnExit   = false;
  String _languageCode       = 'en';

  bool   get darkMode           => _darkMode;
  bool   get notifications      => _notifications;
  bool   get hapticFeedback     => _hapticFeedback;
  bool   get autoCleanReminders => _autoCleanReminders;
  bool   get clearCacheOnExit   => _clearCacheOnExit;
  String get languageCode       => _languageCode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode           = prefs.getBool(PrefKeys.darkMode)           ?? false;
    _notifications      = prefs.getBool(PrefKeys.notifications)      ?? true;
    _hapticFeedback     = prefs.getBool(PrefKeys.hapticFeedback)     ?? true;
    _autoCleanReminders = prefs.getBool(PrefKeys.autoCleanReminders) ?? true;
    _clearCacheOnExit   = prefs.getBool(PrefKeys.clearCacheOnExit)   ?? false;
    _languageCode       = prefs.getString(PrefKeys.languageCode)     ?? 'en';
    T.setLanguage(_languageCode); // ← ADD
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    _darkMode = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.darkMode, v);
  }

  Future<void> setNotifications(bool v) async {
    _notifications = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.notifications, v);
  }

  Future<void> setHapticFeedback(bool v) async {
    _hapticFeedback = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.hapticFeedback, v);
  }

  Future<void> setAutoCleanReminders(bool v) async {
    _autoCleanReminders = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.autoCleanReminders, v);
  }

  Future<void> setClearCacheOnExit(bool v) async {
    _clearCacheOnExit = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.clearCacheOnExit, v);
  }

  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    T.setLanguage(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.languageCode, code);
  }
}