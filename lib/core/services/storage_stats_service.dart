import 'package:disk_space_plus/disk_space_plus.dart';

class StorageStats {
  final double totalGB;
  final double freeGB;

  const StorageStats({required this.totalGB, required this.freeGB});

  double get usedGB => (totalGB - freeGB).clamp(0, totalGB);
  double get usedPercent => totalGB == 0 ? 0 : (usedGB / totalGB) * 100;
}

/// Wraps platform disk-space APIs. Kept as an injectable service so
/// ViewModels never talk to plugins directly (testable via a fake).
class StorageStatsService {
  final DiskSpacePlus _diskSpace;

  StorageStatsService({DiskSpacePlus? diskSpace})
      : _diskSpace = diskSpace ?? DiskSpacePlus();

  Future<StorageStats> getStats() async {
    // getTotalDiskSpace / getFreeDiskSpace are getters on this package
    // (Future<double>?), not methods — no () after them.
    final total = await _diskSpace.getTotalDiskSpace ?? 0;
    final free = await _diskSpace.getFreeDiskSpace ?? 0;
    // disk_space_plus returns MB
    return StorageStats(totalGB: total / 1024, freeGB: free / 1024);
  }
}
