import 'dart:io';

import 'package:flutter/services.dart';

class DeviceMemory {
  final double totalGB;
  final double availableGB;

  const DeviceMemory({
    required this.totalGB,
    required this.availableGB,
  });
}

/// Reads total/available device RAM via a native Android MethodChannel
/// (`ActivityManager.MemoryInfo`). Unlike per-app RAM usage — which
/// Android does not let third-party apps read accurately — total and
/// available device memory is a normal, no-permission API, so this is
/// genuinely real data (see docs/DEVICE_INFO_RAM_NATIVE_SETUP.md).
///
/// Reuses the same `smart_cleaner_pro/battery` channel as
/// [BatteryDetailsService] — one native `MethodChannel` handler on the
/// Android side, just one more `if` branch for `getDeviceMemory`.
/// Returns null (never a guessed number) if the native handler isn't
/// wired up yet, or on platforms without it.
class DeviceMemoryService {
  static const _channel = MethodChannel('smart_cleaner_pro/battery');

  Future<DeviceMemory?> getMemory() async {
    if (!Platform.isAndroid) return null;

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getDeviceMemory',
      );
      if (result == null) return null;

      final totalGB = (result['totalGB'] as num?)?.toDouble();
      final availableGB = (result['availableGB'] as num?)?.toDouble();
      if (totalGB == null || availableGB == null) return null;

      return DeviceMemory(totalGB: totalGB, availableGB: availableGB);
    } on MissingPluginException {
      // Native handler not added yet — see
      // docs/DEVICE_INFO_RAM_NATIVE_SETUP.md.
      return null;
    } catch (_) {
      return null;
    }
  }
}