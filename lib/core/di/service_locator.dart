// lib/core/di/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ads_service.dart';
import '../services/file_scan_service.dart';
import '../services/permission_service.dart';
import '../services/purchase_service.dart';
import '../services/settings_notifier.dart';
import '../services/settings_service.dart';
import '../services/storage_stats_service.dart';

final getIt = GetIt.instance;

/// Kicked off from main() right before runApp() and awaited by
/// SplashView (alongside its own animation timer) instead of being
/// awaited BEFORE runApp(). Awaiting it before runApp() meant Flutter
/// couldn't paint a single frame — not even our own splash screen —
/// until every service here (including Purchase/Billing SDK
/// connection, which can genuinely take a few seconds on a cold start)
/// had finished, producing a blank native screen before our splash
/// screen ever appeared. Now the native screen hands off to our splash
/// immediately, and this work happens invisibly during the splash's
/// existing animation window.
Future<void>? serviceLocatorReady;

Future<void> setupServiceLocator() async {
  // ── Core Services ──────────────────────────────────────────────────────
  getIt.registerLazySingleton<PermissionService>(() => PermissionService());
  getIt.registerLazySingleton<StorageStatsService>(
        () => StorageStatsService(),
  );
  getIt.registerLazySingleton<FileScanService>(() => FileScanService());

  // ── Ads ────────────────────────────────────────────────────────────────
  final ads = AdsService();
  await ads.initialize();
  getIt.registerSingleton<AdsService>(ads);

  // ── Purchases ──────────────────────────────────────────────────────────
  final purchases = PurchaseService();
  await purchases.initialize();
  getIt.registerSingleton<PurchaseService>(purchases);

  purchases.proStatusStream.listen((isPro) => ads.isProUser = isPro);

  // ── Settings ───────────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();

  getIt.registerSingleton<SettingsService>(
    SettingsService(prefs),
  );

  final settingsNotifier = SettingsNotifier();
  await settingsNotifier.init(); // SharedPreferences se load karo
  getIt.registerSingleton<SettingsNotifier>(settingsNotifier);
}