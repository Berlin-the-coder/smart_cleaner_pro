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