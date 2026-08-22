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
      state = DashboardState.loaded(
        totalGB: snapshot.totalGB,
        usedGB: snapshot.usedGB,
        freeGB: snapshot.freeGB,
        usedPercent: snapshot.usedPercent,
        batteryPercent: snapshot.batteryPercent,
        installedAppCount: snapshot.installedAppCount,
      );
    } catch (e) {
      state = DashboardState.error('Failed to read storage stats: $e');
    }
  }

  Future<void> refresh() => load();
}
