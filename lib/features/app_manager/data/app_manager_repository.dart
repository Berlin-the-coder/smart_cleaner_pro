import 'dart:async';
import 'dart:io';

import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

abstract class AppManagerRepository {
  bool get isSupported;

  /// Phase 1 — fast: names + packages, NO icons. Returns in a fraction
  /// of the time the old withIcon:true call took, because the plugin
  /// doesn't decode every APK's launcher icon.
  Future<List<AppInfo>> getInstalledAppsWithoutIcons();

  /// Streams each app's icon as it becomes ready — see impl for details.
  Stream<AppInfo> loadIconsForAppsStream(List<String> packageNames);

  Future<bool> uninstallApp(String packageName);
}

class AppManagerRepositoryImpl implements AppManagerRepository {
  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Future<List<AppInfo>> getInstalledAppsWithoutIcons() async {
    if (!isSupported) return [];
    return InstalledApps.getInstalledApps(
      excludeSystemApps: true,
      excludeNonLaunchableApps: true,
      withIcon: false,
    );
  }

  /// Emits each app's full info (with icon) as soon as it's ready —
  /// NOT batched-then-returned-all-at-once. Uses bounded concurrency
  /// (6 in-flight requests) so multiple apps load in parallel, but each
  /// one is handed to the caller the moment it completes, letting the
  /// UI show apps one at a time as their icons arrive instead of
  /// waiting for every single icon before updating at all.
  Stream<AppInfo> loadIconsForAppsStream(List<String> packageNames) {
    if (!isSupported || packageNames.isEmpty) {
      return const Stream.empty();
    }

    const concurrency = 10;
    final controller = StreamController<AppInfo>();
    var nextIndex = 0;
    var active = 0;
    var finished = false;

    void maybeClose() {
      if (finished) return;
      if (nextIndex >= packageNames.length && active == 0) {
        finished = true;
        controller.close();
      }
    }

    void pump() {
      while (active < concurrency && nextIndex < packageNames.length) {
        final pkg = packageNames[nextIndex++];
        active++;
        InstalledApps.getAppInfo(pkg).then((info) {
          active--;
          if (info != null && !controller.isClosed) controller.add(info);
          pump();
          maybeClose();
        }).catchError((_) {
          active--;
          pump();
          maybeClose();
        });
      }
    }

    controller.onListen = pump;
    return controller.stream;
  }

  @override
  Future<bool> uninstallApp(String packageName) async {
    if (!isSupported) return false;
    final result = await InstalledApps.uninstallApp(packageName);
    return result ?? false;
  }
}
