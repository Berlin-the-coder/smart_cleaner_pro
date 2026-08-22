import 'translations/en_translations.dart';
import 'translations/ur_translations.dart';
import 'translations/es_translations.dart';
import 'translations/fr_translations.dart';
import 'translations/ar_translations.dart';
import 'translations/hi_translations.dart';
import 'translations/zh_translations.dart';

/// Drop-in replacement — no BuildContext needed.
/// Call anywhere: T.of('quickClean')
class T {
  static String _lang = 'en';

  static void setLanguage(String code) => _lang = code;

  static String of(String key) =>
      (_translations[_lang] ?? _translations['en']!)[key] ?? key;

  static final _translations = <String, Map<String, String>>{
    'en': enTranslations,
    'ur': urTranslations,
    'es': esTranslations,
    'fr': frTranslations,
    'ar': arTranslations,
    'hi': hiTranslations,
    'zh': zhTranslations,
  };
}