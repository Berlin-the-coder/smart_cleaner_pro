import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:installed_apps/installed_apps.dart';

import '../../../core/services/storage_stats_service.dart';

abstract class DashboardRepository {
  Future<DashboardSnapshot> loadSnapshot();
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

  @override
  Future<DashboardSnapshot> loadSnapshot() async {
    final stats = await _storageStatsService.getStats();

    int? batteryPercent;
    try {
      batteryPercent = await _battery.batteryLevel;
    } catch (_) {
      batteryPercent = null;
    }

    int? appCount;
    if (Platform.isAndroid) {
      try {
        final apps = await InstalledApps.getInstalledApps(
          excludeSystemApps: false,
          excludeNonLaunchableApps: true,
        );
        appCount = apps.length;
      } catch (_) {
        appCount = null;
      }
    }

    return DashboardSnapshot(
      totalGB: stats.totalGB,
      usedGB: stats.usedGB,
      freeGB: stats.freeGB,
      usedPercent: stats.usedPercent,
      batteryPercent: batteryPercent,
      installedAppCount: appCount,
    );
  }
}
