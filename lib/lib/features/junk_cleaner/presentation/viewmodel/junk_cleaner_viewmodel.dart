import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/ads_service.dart';
import '../../../../core/services/file_scan_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../data/junk_cleaner_repository.dart';
import '../../domain/junk_cleaner_state.dart';

final junkCleanerRepositoryProvider = Provider<JunkCleanerRepository>((ref) {
  return JunkCleanerRepositoryImpl(
    getIt<FileScanService>(),
    getIt<PermissionService>(),
  );
});

final junkCleanerViewModelProvider =
StateNotifierProvider<JunkCleanerViewModel, JunkCleanerState>((ref) {
  return JunkCleanerViewModel(
    ref.watch(junkCleanerRepositoryProvider),
    getIt<AdsService>(),
  );
});

class JunkCleanerViewModel extends StateNotifier<JunkCleanerState> {
  final JunkCleanerRepository _repository;
  final AdsService _adsService;

  JunkCleanerViewModel(this._repository, this._adsService)
      : super(const JunkCleanerState.idle());

  Future<void> startScan() async {
    final permission = await _repository.ensurePermission();
    if (permission != StoragePermissionResult.granted) {
      state = const JunkCleanerState.permissionRequired();
      return;
    }

    try {
      await for (final groups in _repository.scan()) {
        // Check karo scanning chal rahi hai ya sab done hain
        final stillScanning = groups.any((g) => g.isScanning);
        if (stillScanning) {
          state = JunkCleanerState.scanning(groups: groups);
        } else {
          // Sirf non-empty groups dikhao
          final nonEmpty = groups.where((g) => g.files.isNotEmpty).toList();
          state = JunkCleanerState.scanned(groups: nonEmpty);
        }
      }
    } catch (e) {
      state = JunkCleanerState.error('Scan failed: $e');
    }
  }

  // Category ki saari files toggle karo
  void toggleCategory(JunkCategory category) {
    final current = state;
    final groups = _getGroups(current);
    if (groups == null) return;

    final updatedGroups = groups.map((group) {
      if (group.category != category) return group;
      final newSelected = group.allSelected
          ? <String>{} // sab deselect
          : group.files.map((f) => f.path).toSet(); // sab select
      return group.copyWith(selectedPaths: newSelected);
    }).toList();

    state = _rebuildState(current, updatedGroups);
  }

  // Individual file toggle
  void toggleFile(JunkCategory category, String path) {
    final current = state;
    final groups = _getGroups(current);
    if (groups == null) return;

    final updatedGroups = groups.map((group) {
      if (group.category != category) return group;
      final selected = Set<String>.from(group.selectedPaths);
      if (!selected.remove(path)) selected.add(path);
      return group.copyWith(selectedPaths: selected);
    }).toList();

    state = _rebuildState(current, updatedGroups);
  }

  Future<void> cleanSelected() async {
    final current = state;
    final groups = _getGroups(current);
    if (groups == null) return;

    final selectedPaths =
    groups.expand((g) => g.selectedPaths).toList(growable: false);
    if (selectedPaths.isEmpty) return;

    state = const JunkCleanerState.cleaning();
    final result = await _repository.deleteFiles(selectedPaths);
    state = JunkCleanerState.cleaned(
      filesDeleted: result.deletedCount,
      bytesFreed: result.bytesFreed,
    );

    await _adsService.maybeShowInterstitial();
  }

  void reset() => state = const JunkCleanerState.idle();

  // Helpers
  List<JunkGroup>? _getGroups(JunkCleanerState s) => switch (s) {
    JunkCleanerScanning(:final groups) => groups,
    JunkCleanerScanned(:final groups) => groups,
    _ => null,
  };

  JunkCleanerState _rebuildState(
      JunkCleanerState current,
      List<JunkGroup> groups,
      ) =>
      switch (current) {
        JunkCleanerScanning() => JunkCleanerState.scanning(groups: groups),
        JunkCleanerScanned() => JunkCleanerState.scanned(groups: groups),
        _ => current,
      };
}