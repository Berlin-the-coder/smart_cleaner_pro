import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/storage_stats_service.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_state.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(getIt<StorageStatsService>());
});

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
  return DashboardViewModel(ref.watch(dashboardRepositoryProvider));
});

class DashboardViewModel extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardViewModel(this._repository) : super(const DashboardState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const DashboardState.loading();
    try {
      final snapshot = await _repository.loadSnapshot();
      // Fast fields ready — clear the "Checking your device…" spinner
      // now instead of waiting for the (much slower) app count.
      state = DashboardState.loaded(
        totalGB: snapshot.totalGB,
        usedGB: snapshot.usedGB,
        freeGB: snapshot.freeGB,
        usedPercent: snapshot.usedPercent,
        batteryPercent: snapshot.batteryPercent,
        installedAppCount: snapshot.installedAppCount,
      );

      // App count loads separately in the background; when it arrives
      // we just re-emit the SAME `loaded` state with the count filled
      // in. The header has already stopped spinning by this point, so
      // this update is invisible except for the app-count chip
      // populating a moment later.
      final appCount = await _repository.loadAppCount();
      final current = state;
      if (current is DashboardLoaded) {
        state = DashboardState.loaded(
          totalGB: current.totalGB,
          usedGB: current.usedGB,
          freeGB: current.freeGB,
          usedPercent: current.usedPercent,
          batteryPercent: current.batteryPercent,
          installedAppCount: appCount,
        );
      }
    } catch (e) {
      state = DashboardState.error('Failed to read storage stats: $e');
    }
  }

  Future<void> refresh() => load();
}
