import 'dart:io';

import 'package:flutter/services.dart';

class BatteryDetails {
  final double? temperatureCelsius;
  final double? voltage;
  final String? health;
  final String? technology;

  const BatteryDetails({
    this.temperatureCelsius,
    this.voltage,
    this.health,
    this.technology,
  });

  static const unavailable = BatteryDetails();
}

/// Reads battery temperature/health/voltage/technology via a native
/// Android MethodChannel. `battery_plus` only exposes level and charging
/// state — these extra fields come from Android's ACTION_BATTERY_CHANGED
/// sticky broadcast, which requires a small native handler (see
/// docs/BATTERY_NATIVE_SETUP.md). Real values only — if the native side
/// isn't wired up yet, or this runs on iOS (no equivalent public API),
/// this returns [BatteryDetails.unavailable] rather than fabricating
/// numbers, matching the app's no-fake-data policy.
class BatteryDetailsService {
  static const _channel = MethodChannel('smart_cleaner_pro/battery');

  Future<BatteryDetails> getDetails() async {
    if (!Platform.isAndroid) return BatteryDetails.unavailable;

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getBatteryDetails',
      );
      if (result == null) return BatteryDetails.unavailable;

      return BatteryDetails(
        temperatureCelsius: (result['temperatureCelsius'] as num?)?.toDouble(),
        voltage: (result['voltage'] as num?)?.toDouble(),
        health: result['health'] as String?,
        technology: result['technology'] as String?,
      );
    } on MissingPluginException {
      // Native handler not added yet — see docs/BATTERY_NATIVE_SETUP.md.
      return BatteryDetails.unavailable;
    } catch (_) {
      return BatteryDetails.unavailable;
    }
  }
}
