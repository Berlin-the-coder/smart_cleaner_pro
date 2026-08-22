// lib/core/services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _darkModeKey = 'dark_mode';
  static const String _notificationsKey = 'notifications';
  static const String _hapticFeedbackKey = 'haptic_feedback';
  static const String _autoCleanRemindersKey = 'auto_clean_reminders';
  static const String _clearCacheOnExitKey = 'clear_cache_on_exit';
  static const String _languageCodeKey = 'language_code';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // ─── Getters ─────────────────────────────────────────────────────────────

  bool get darkMode => _prefs.getBool(_darkModeKey) ?? false;
  bool get notifications => _prefs.getBool(_notificationsKey) ?? true;
  bool get hapticFeedback => _prefs.getBool(_hapticFeedbackKey) ?? true;
  bool get autoCleanReminders => _prefs.getBool(_autoCleanRemindersKey) ?? true;
  bool get clearCacheOnExit => _prefs.getBool(_clearCacheOnExitKey) ?? false;
  String get languageCode => _prefs.getString(_languageCodeKey) ?? 'en';

  // ─── Setters ─────────────────────────────────────────────────────────────

  Future<void> setDarkMode(bool value) => _prefs.setBool(_darkModeKey, value);
  Future<void> setNotifications(bool value) => _prefs.setBool(_notificationsKey, value);
  Future<void> setHapticFeedback(bool value) => _prefs.setBool(_hapticFeedbackKey, value);
  Future<void> setAutoCleanReminders(bool value) =>
      _prefs.setBool(_autoCleanRemindersKey, value);
  Future<void> setClearCacheOnExit(bool value) =>
      _prefs.setBool(_clearCacheOnExitKey, value);
  Future<void> setLanguageCode(String code) =>
      _prefs.setString(_languageCodeKey, code);
}