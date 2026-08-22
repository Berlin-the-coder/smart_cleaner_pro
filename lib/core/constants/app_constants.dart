/// Global, environment-agnostic constants.
/// Keep secrets (ad unit IDs, API keys) out of source control in real
/// projects — load them via --dart-define or a gitignored env file.
class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Cleaner Pro';

  // --- AdMob (TEST IDs — replace with real IDs before release) ---
  static const String admobAppIdAndroid =
      'ca-app-pub-3940256099942544~3347511713';
  static const String admobAppIdIOS =
      'ca-app-pub-3940256099942544~1458002511';
  static const String interstitialAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String bannerAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/6300978111';

  // --- In-app purchase ---
  static const String removeAdsProductId = 'smart_cleaner_pro_remove_ads';

  // --- Scan tuning ---
  static const int maxIsolateChunkSize = 500; // files per isolate batch
  static const List<String> junkExtensions = [
    '.tmp',
    '.log',
    '.cache',
    '.bak',
    '.old',
    '.dmp',
  ];

  static const List<String> imageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
  ];
  static const List<String> videoExtensions = [
    '.mp4', '.mov', '.mkv', '.avi', '.3gp', '.webm', '.m4v', '.ts',
  ];
  static const List<String> audioExtensions = ['.mp3', '.wav', '.aac', '.m4a'];
  static const List<String> docExtensions = [
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.txt',
  ];
  static const List<String> zipExtensions = ['.zip', '.rar', '.7z', '.tar', '.gz'];
  static const List<String> apkExtensions = ['.apk'];

  static const Duration adCooldown = Duration(minutes: 3);
}

class AssetPaths {
  AssetPaths._();
  static const String splashLottie = 'assets/lottie/splash.json';
  static const String cleaningLottie = 'assets/lottie/cleaning.json';
  static const String emptyState = 'assets/images/empty_state.png';
}

class PrefKeys {
  PrefKeys._();
  static const String isProUser = 'is_pro_user';
  static const String onboardingComplete = 'onboarding_complete';
  static const String themeMode = 'theme_mode';
  static const String lastScanTimestamp = 'last_scan_timestamp';

  static const darkMode           = 'dark_mode';
  static const notifications      = 'notifications';
  static const hapticFeedback     = 'haptic_feedback';
  static const autoCleanReminders = 'auto_clean_reminders';
  static const clearCacheOnExit   = 'clear_cache_on_exit';
  static const languageCode       = 'language_code';
}
