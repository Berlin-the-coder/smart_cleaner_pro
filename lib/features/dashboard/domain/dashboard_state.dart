import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_state.freezed.dart';

@freezed
class DashboardState with _$DashboardState {
  const factory DashboardState.loading() = DashboardLoading;

  const factory DashboardState.loaded({
    required double totalGB,
    required double usedGB,
    required double freeGB,
    required double usedPercent,
    // Real reads only — both cheap enough to fetch on dashboard load
    // without a full storage scan. Null when unavailable (e.g. iOS
    // doesn't expose an app count the same way) rather than a fake 0.
    int? batteryPercent,
    int? installedAppCount,
  }) = DashboardLoaded;

  const factory DashboardState.error(String message) = DashboardError;
}
