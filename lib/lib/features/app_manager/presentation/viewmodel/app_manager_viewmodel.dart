import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_manager_repository.dart';
import '../../domain/app_manager_state.dart';

final appManagerRepositoryProvider = Provider<AppManagerRepository>((ref) {
  return AppManagerRepositoryImpl();
});

final appManagerViewModelProvider =
    StateNotifierProvider<AppManagerViewModel, AppManagerState>((ref) {
  return AppManagerViewModel(ref.watch(appManagerRepositoryProvider));
});

class AppManagerViewModel extends StateNotifier<AppManagerState> {
  final AppManagerRepository _repository;

  AppManagerViewModel(this._repository) : super(const AppManagerState.loading()) {
    load();
  }

  Future<void> load() async {
    if (!_repository.isSupported) {
      state = const AppManagerState.unsupportedPlatform();
      return;
    }

    state = const AppManagerState.loading();
    try {
      final apps = await _repository.getInstalledApps();
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      state = AppManagerState.loaded(apps: apps, sortOrder: AppSortOrder.nameAsc);
    } catch (e) {
      state = AppManagerState.error('Failed to load apps: $e');
    }
  }

  void setSortOrder(AppSortOrder order) {
    final current = state;
    if (current is! AppManagerLoaded) return;

    final sorted = [...current.apps];
    switch (order) {
      case AppSortOrder.nameAsc:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case AppSortOrder.installDateDesc:
        sorted.sort((a, b) => b.installedTimestamp.compareTo(a.installedTimestamp));
        break;
    }
    state = AppManagerState.loaded(apps: sorted, sortOrder: order);
  }

  Future<void> uninstall(String packageName) async {
    await _repository.uninstallApp(packageName);
    // Refresh after returning from the system uninstall dialog/flow.
    await load();
  }
}
