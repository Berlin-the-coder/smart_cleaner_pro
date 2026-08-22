import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/ads_service.dart';
import '../../../../core/services/file_scan_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../data/duplicate_finder_repository.dart';
import '../../domain/duplicate_finder_state.dart';

final duplicateFinderRepositoryProvider =
    Provider<DuplicateFinderRepository>((ref) {
  return DuplicateFinderRepositoryImpl(
    getIt<FileScanService>(),
    getIt<PermissionService>(),
  );
});

final duplicateFinderViewModelProvider = StateNotifierProvider<
    DuplicateFinderViewModel, DuplicateFinderState>((ref) {
  return DuplicateFinderViewModel(
    ref.watch(duplicateFinderRepositoryProvider),
    getIt<AdsService>(),
    ref,
  );
});

/// Plain (non-freezed) flag the view can watch to show a small "still
/// finding duplicates…" indicator while results keep streaming in.
final duplicateFinderScanningProvider = StateProvider<bool>((ref) => false);

class DuplicateFinderViewModel extends StateNotifier<DuplicateFinderState> {
  final DuplicateFinderRepository _repository;
  final AdsService _adsService;
  final Ref _ref;

  DuplicateFinderViewModel(this._repository, this._adsService, this._ref)
      : super(const DuplicateFinderState.typePicker());

  /// Switches to the results view as soon as the FIRST duplicate group
  /// is confirmed, then keeps updating that same `scanned` state as
  /// more groups are found — instead of showing a spinner for the
  /// entire 15-20 second scan and only revealing everything at once at
  /// the end.
  Future<void> startScan({DuplicateMediaType? onlyType}) async {
    final permission = await _repository.ensurePermission();
    if (permission == StoragePermissionResult.unsupportedPlatform) {
      state = DuplicateFinderState.error(T.of('notAvailableOnIOS'));
      return;
    }
    if (permission != StoragePermissionResult.granted) {
      state = const DuplicateFinderState.permissionRequired();
      return;
    }

    state = const DuplicateFinderState.scanning();
    _ref.read(duplicateFinderScanningProvider.notifier).state = true;

    try {
      var shownAny = false;
      await for (final groups in _repository.scan(onlyType: onlyType)) {
        shownAny = true;
        state = DuplicateFinderState.scanned(groups: groups);
      }
      if (!shownAny) {
        state = const DuplicateFinderState.scanned(groups: []);
      }
    } catch (e) {
      state = DuplicateFinderState.error('Scan failed: $e');
    } finally {
      _ref.read(duplicateFinderScanningProvider.notifier).state = false;
    }
  }

  void toggleFile(String hash, String path) {
    final current = state;
    if (current is! DuplicateFinderScanned) return;

    final updatedGroups = current.groups.map((group) {
      if (group.hash != hash) return group;
      final selected = Set<String>.from(group.selectedPaths);
      if (!selected.remove(path)) selected.add(path);
      return group.copyWith(selectedPaths: selected);
    }).toList();

    state = DuplicateFinderState.scanned(groups: updatedGroups);
  }

  Future<void> deleteSelected() async {
    final current = state;
    if (current is! DuplicateFinderScanned) return;

    final selectedPaths = current.groups
        .expand((g) => g.selectedPaths)
        .toList(growable: false);
    if (selectedPaths.isEmpty) return;

    state = const DuplicateFinderState.deleting();
    final result = await _repository.deleteFiles(selectedPaths);
    state = DuplicateFinderState.deleted(
      filesDeleted: result.deletedCount,
      bytesFreed: result.bytesFreed,
    );
    await _adsService.maybeShowInterstitial();
  }

  void reset() => state = const DuplicateFinderState.typePicker();

  /// Used by the permission-required screen's "Grant Access" button —
  /// re-requests the permission and, if granted, returns to the type
  /// picker so the user can choose what to scan (rather than jumping
  /// straight into a full "scan everything").
  Future<void> retryPermission() async {
    final permission = await _repository.ensurePermission();
    if (permission == StoragePermissionResult.granted) {
      state = const DuplicateFinderState.typePicker();
    }
  }
}
