import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:installed_apps/installed_apps.dart';

import '../../../core/services/storage_stats_service.dart';

abstract class DashboardRepository {
  Future<DashboardSnapshot> loadSnapshot();
  Future<int?> loadAppCount();
}

class DashboardSnapshot {
  final double totalGB;
  final double usedGB;
  final double freeGB;
  final double usedPercent;
  final int? batteryPercent;
  final int? installedAppCount;

  const DashboardSnapshot({
    required this.totalGB,
    required this.usedGB,
    required this.freeGB,
    required this.usedPercent,
    this.batteryPercent,
    this.installedAppCount,
  });
}

/// Repository pattern keeps the ViewModel decoupled from concrete
/// plugins — a fake implementation is swapped in for widget/unit tests
/// via Riverpod overrides.
///
/// Only fetches data that's cheap to read on every dashboard load:
/// storage stats, battery level, and installed-app count. Junk size,
/// duplicate size, and file counts are NOT precomputed here — those
/// need a real storage walk, which stays an explicit user action inside
/// each feature (see each feature's own scan flow) rather than
/// something that runs automatically every time the home screen opens.
class DashboardRepositoryImpl implements DashboardRepository {
  final StorageStatsService _storageStatsService;
  final Battery _battery;

  DashboardRepositoryImpl(this._storageStatsService, {Battery? battery})
      : _battery = battery ?? Battery();

  /// Fast path — storage + battery only. This is what the dashboard
  /// waits on before it stops showing "Checking your device…". Both
  /// calls are fired together instead of one-after-another, so total
  /// wait time is the SLOWER of the two, not the sum.
  @override
  Future<DashboardSnapshot> loadSnapshot() async {
    final results = await Future.wait([
      _storageStatsService.getStats(),
      _battery.batteryLevel.then<int?>((v) => v).catchError((_) => null),
    ]);

    final stats = results[0] as StorageStats;
    final batteryPercent = results[1] as int?;

    return DashboardSnapshot(
      totalGB: stats.totalGB,
      usedGB: stats.usedGB,
      freeGB: stats.freeGB,
      usedPercent: stats.usedPercent,
      batteryPercent: batteryPercent,
      installedAppCount: null, // filled in afterwards, see loadAppCount()
    );
  }

  /// Slow path — installed-app count. Serializing every installed app
  /// (system apps included) across the platform channel just to get a
  /// number is the real cost here, even with withIcon:false; on a
  /// device with 250+ apps this alone can take several seconds. It's
  /// fetched separately, AFTER the header has already stopped
  /// spinning, so it never blocks the "Checking your device…" state.
  @override
  Future<int?> loadAppCount() async {
    if (!Platform.isAndroid) return null;
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
        withIcon: false,
      );
      return apps.length;
    } catch (_) {
      return null;
    }
  }
}
