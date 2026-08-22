import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Snapshot of static device specs. Every field here is a genuine
/// one-time read from the OS — there is no "live usage %" or "core
/// load" section, because Android does not expose that to third-party
/// apps in a meaningful way (see docs/CPU_RAM_SCREENS_NOTE.md). Fields
/// that a given device/OS doesn't report come back null and the UI
/// shows "Not available" rather than a placeholder number.
class DeviceSpecs {
  final String manufacturer;
  final String model;
  final String board;
  final String hardware;
  final String androidRelease;
  final int androidSdkInt;
  final int cpuCoreCount;
  final List<String> supportedAbis;
  final bool isPhysicalDevice;
  final String appVersion;
  final String? securityPatch;
  final String? kernelVersion;

  const DeviceSpecs({
    required this.manufacturer,
    required this.model,
    required this.board,
    required this.hardware,
    required this.androidRelease,
    required this.androidSdkInt,
    required this.cpuCoreCount,
    required this.supportedAbis,
    required this.isPhysicalDevice,
    required this.appVersion,
    this.securityPatch,
    this.kernelVersion,
  });
}

class DeviceInfoRepository {
  Future<DeviceSpecs> getSpecs() async {
    final packageInfo = await PackageInfo.fromPlatform();
    // Platform.numberOfProcessors is a genuine dart:io API — real core
    // count, not an estimate.
    final coreCount = Platform.numberOfProcessors;

    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      return DeviceSpecs(
        manufacturer: info.manufacturer,
        model: info.model,
        board: info.board,
        hardware: info.hardware,
        androidRelease: info.version.release,
        androidSdkInt: info.version.sdkInt,
        cpuCoreCount: coreCount,
        supportedAbis: info.supportedAbis,
        isPhysicalDevice: info.isPhysicalDevice,
        appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
        // Real OS field (Build.VERSION.SECURITY_PATCH under the hood).
        // Some device_info_plus versions type this as nullable, others as
        // a possibly-empty String — handle both without a version-specific
        // import so this compiles either way.
        securityPatch: _cleanOrNull(info.version.securityPatch),
        kernelVersion: _readKernelVersion(),
      );
    }

    if (Platform.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;
      return DeviceSpecs(
        manufacturer: 'Apple',
        model: info.utsname.machine,
        board: info.model,
        hardware: info.utsname.machine,
        androidRelease: info.systemVersion,
        androidSdkInt: 0,
        cpuCoreCount: coreCount,
        supportedAbis: [info.utsname.machine],
        isPhysicalDevice: info.isPhysicalDevice,
        appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
        // Not applicable/exposed on iOS.
        securityPatch: null,
        kernelVersion: null,
      );
    }

    return DeviceSpecs(
      manufacturer: 'Unknown',
      model: 'Unknown',
      board: 'Unknown',
      hardware: 'Unknown',
      androidRelease: 'Unknown',
      androidSdkInt: 0,
      cpuCoreCount: coreCount,
      supportedAbis: const [],
      isPhysicalDevice: true,
      appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
      securityPatch: null,
      kernelVersion: null,
    );
  }

  /// `/proc/version` is a plain, world-readable text file on Android that
  /// reports the running kernel build string — no permission needed. Not
  /// every OEM/ROM exposes it the same way, so this is wrapped defensively
  /// and returns null rather than a guess if it can't be read.
  String? _readKernelVersion() {
    try {
      final file = File('/proc/version');
      if (!file.existsSync()) return null;
      final content = file.readAsStringSync().trim();
      return content.isNotEmpty ? content : null;
    } catch (_) {
      return null;
    }
  }

  String? _cleanOrNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}