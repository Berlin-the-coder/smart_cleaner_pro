import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum StoragePermissionResult {
  granted,
  denied,
  permanentlyDenied,

  /// Whole-device filesystem scanning (Junk Cleaner, Duplicate Finder,
  /// File Manager's raw folder browsing) has no iOS equivalent — iOS
  /// apps are sandboxed and simply cannot enumerate arbitrary paths
  /// like Android's /storage/emulated/0. This isn't a permission that
  /// can be granted; it's a platform capability that doesn't exist.
  unsupportedPlatform,
}

/// Centralizes scoped-storage-compliant permission requests.
///
/// Android 13+ uses granular media permissions (photos/videos/audio);
/// Android 11-12 needs MANAGE_EXTERNAL_STORAGE for whole-device scanning
/// features like the Junk Cleaner and Duplicate Finder. iOS relies on the
/// Photos permission only — Smart Cleaner Pro never requests full
/// filesystem access on iOS, in line with App Store policy.
class PermissionService {
  Future<StoragePermissionResult> requestMediaAccess() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return _map(status);
    }

    // Android
    final sdkInt = await _androidSdkInt();
    if (sdkInt >= 33) {
      final statuses = await [
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ].request();
      final anyPermanentlyDenied =
          statuses.values.any((s) => s.isPermanentlyDenied);
      final allGranted = statuses.values.every((s) => s.isGranted);
      if (allGranted) return StoragePermissionResult.granted;
      if (anyPermanentlyDenied) {
        return StoragePermissionResult.permanentlyDenied;
      }
      return StoragePermissionResult.denied;
    }

    final status = await Permission.storage.request();
    return _map(status);
  }

  /// Only required for full-device Junk/Duplicate scans on Android 11+.
  /// Always show an explanation dialog BEFORE calling this — Play policy
  /// requires justifying MANAGE_EXTERNAL_STORAGE in-app and in the listing.
  Future<StoragePermissionResult> requestManageExternalStorage() async {
    if (!Platform.isAndroid) return StoragePermissionResult.granted;
    final status = await Permission.manageExternalStorage.request();
    return _map(status);
  }

  Future<bool> isNotificationGranted() async {
    return Permission.notification.status.isGranted;
  }

  StoragePermissionResult _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return StoragePermissionResult.granted;
    }
    if (status.isPermanentlyDenied) {
      return StoragePermissionResult.permanentlyDenied;
    }
    return StoragePermissionResult.denied;
  }

  Future<int> _androidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }
}
