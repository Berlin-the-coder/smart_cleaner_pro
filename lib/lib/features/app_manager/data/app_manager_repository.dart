import 'dart:io';

import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

abstract class AppManagerRepository {
  bool get isSupported;
  Future<List<AppInfo>> getInstalledApps();
  Future<bool> uninstallApp(String packageName);
}

/// installed_apps only exposes name/package/version/icon/install date —
/// it does NOT expose per-app storage size. Getting real app size
/// requires Android's StorageStatsManager via a native MethodChannel
/// (and PACKAGE_USAGE_STATS, a separate special-access permission with
/// its own Play Store review requirements). Rather than show a made-up
/// size, this feature intentionally omits it — see COMPLIANCE notes in
/// the README ("Do NOT claim fake RAM boosting" applies here too).
class AppManagerRepositoryImpl implements AppManagerRepository {
  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Future<List<AppInfo>> getInstalledApps() async {
    if (!isSupported) return [];
    return InstalledApps.getInstalledApps(
      excludeSystemApps: true,
      excludeNonLaunchableApps: true,
      withIcon: true,
    );
  }

  @override
  Future<bool> uninstallApp(String packageName) async {
    if (!isSupported) return false;
    final result = await InstalledApps.uninstallApp(packageName);
    return result ?? false;
  }
}
