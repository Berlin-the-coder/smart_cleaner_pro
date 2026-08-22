import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/services/file_scan_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/storage_stats_service.dart';
import '../../data/file_manager_repository.dart';
import '../../domain/file_manager_state.dart';

typedef _Files = List<ScannedFile>;

final fileManagerRepositoryProvider = Provider<FileManagerRepository>((ref) {
  return FileManagerRepositoryImpl(
    getIt<FileScanService>(),
    getIt<PermissionService>(),
    getIt<StorageStatsService>(),
  );
});

final fileManagerViewModelProvider =
    StateNotifierProvider<FileManagerViewModel, FileManagerState>((ref) {
  return FileManagerViewModel(ref.watch(fileManagerRepositoryProvider), ref);
});

/// Plain (non-freezed) flag the UI can watch to show a small "still
/// scanning" spinner while a category is loading. Kept outside the
/// freezed union deliberately — the .freezed.dart file for
/// FileManagerState isn't being regenerated in this environment, so the
/// ViewModel only ever emits the existing `loaded` state, updated
/// progressively as batches arrive.
final fileManagerScanningProvider = StateProvider<bool>((ref) => false);

class FileManagerViewModel extends StateNotifier<FileManagerState> {
  final FileManagerRepository _repository;
  final Ref _ref;
  StreamSubscription<List<ScannedFile>>? _categorySub;

  FileManagerViewModel(this._repository, this._ref)
      : super(const FileManagerState.overviewLoading()) {
    loadOverview();
  }

  @override
  void dispose() {
    _categorySub?.cancel();
    super.dispose();
  }

  Future<void> loadOverview() async {
    final permission = await _repository.ensurePermission();
    if (permission == StoragePermissionResult.unsupportedPlatform) {
      state = FileManagerState.error(T.of('notAvailableOnIOS'));
      return;
    }
    if (permission != StoragePermissionResult.granted) {
      state = const FileManagerState.permissionRequired();
      return;
    }

    state = const FileManagerState.overviewLoading();
    try {
      final storageFuture = _repository.getStorageOverview();
      final categoriesFuture = _repository.computeCategorySizes();
      final storage = await storageFuture;
      final categories = await categoriesFuture;
      state = FileManagerState.overview(
        categories: categories,
        usedBytes: storage.usedBytes,
        totalBytes: storage.totalBytes,
      );
    } catch (e) {
      state = FileManagerState.error('Failed to load storage overview: $e');
    }
  }

  Future<void> search(String query) async {
    final current = state;
    if (current is! FileManagerOverview) return;

    if (query.trim().isEmpty) {
      state = FileManagerState.overview(
        categories: current.categories,
        usedBytes: current.usedBytes,
        totalBytes: current.totalBytes,
      );
      return;
    }

    final results = await _repository.searchFiles(query);
    final latest = state;
    if (latest is! FileManagerOverview) return;
    state = FileManagerState.overview(
      categories: latest.categories,
      usedBytes: latest.usedBytes,
      totalBytes: latest.totalBytes,
      searchQuery: query,
      searchResults: results,
    );
  }

  /// Opens a category and streams results in — files appear as soon as
  /// the first batch arrives instead of waiting for the whole scan.
  /// Every update uses the EXISTING `loaded` state (same shape as
  /// before); [fileManagerScanningProvider] is toggled separately so the
  /// view can show a small progress indicator without needing a new
  /// FileManagerState case.
  Future<void> openCategory(FileCategory category) async {
    final permission = await _repository.ensurePermission();
    if (permission == StoragePermissionResult.unsupportedPlatform) {
      state = FileManagerState.error(T.of('notAvailableOnIOS'));
      return;
    }
    if (permission != StoragePermissionResult.granted) {
      state = const FileManagerState.permissionRequired();
      return;
    }

    await _categorySub?.cancel();
    _categorySub = null;

    state = FileManagerState.loading(category);

    final accumulated = <ScannedFile>[];
    const defaultSort = FileSortBy.date;
    const defaultView = FileViewMode.grid;
    var firstBatch = true;

    _ref.read(fileManagerScanningProvider.notifier).state = true;

    _categorySub = _repository.streamCategory(category).listen(
      (batch) {
        accumulated.addAll(batch);

        if (firstBatch) {
          firstBatch = false;
          state = FileManagerState.loaded(
            category: category,
            files: _sorted(accumulated, defaultSort),
            sortBy: defaultSort,
            viewMode: defaultView,
          );
          return;
        }

        final current = state;
        if (current is FileManagerLoaded) {
          state = FileManagerState.loaded(
            category: category,
            files: _sorted(accumulated, current.sortBy),
            sortBy: current.sortBy,
            viewMode: current.viewMode,
          );
        }
      },
      onDone: () {
        _ref.read(fileManagerScanningProvider.notifier).state = false;
        final current = state;
        if (current is FileManagerLoaded) return; // already showing results
        // No files ever arrived — still need to leave the loading state.
        state = FileManagerState.loaded(
          category: category,
          files: const [],
          sortBy: defaultSort,
          viewMode: defaultView,
        );
        _categorySub = null;
      },
      onError: (e) {
        _ref.read(fileManagerScanningProvider.notifier).state = false;
        state = FileManagerState.error('Failed to load files: $e');
        _categorySub = null;
      },
      cancelOnError: true,
    );
  }

  void backToOverview() {
    _categorySub?.cancel();
    _categorySub = null;
    _ref.read(fileManagerScanningProvider.notifier).state = false;
    loadOverview();
  }

  void setSortBy(FileSortBy sortBy) {
    final current = state;
    if (current is! FileManagerLoaded) return;
    _sortAndSet(current.category, current.files, sortBy, current.viewMode);
  }

  void toggleViewMode() {
    final current = state;
    if (current is! FileManagerLoaded) return;
    state = FileManagerState.loaded(
      category: current.category,
      files: current.files,
      sortBy: current.sortBy,
      viewMode: current.viewMode == FileViewMode.grid
          ? FileViewMode.list
          : FileViewMode.grid,
    );
  }

  void _sortAndSet(
    FileCategory category,
    _Files files,
    FileSortBy sortBy,
    FileViewMode viewMode,
  ) {
    state = FileManagerState.loaded(
      category: category,
      files: _sorted(files, sortBy),
      sortBy: sortBy,
      viewMode: viewMode,
    );
  }

  _Files _sorted(_Files files, FileSortBy sortBy) {
    final sorted = [...files];
    switch (sortBy) {
      case FileSortBy.name:
        sorted.sort((a, b) => a.path
            .split('/')
            .last
            .toLowerCase()
            .compareTo(b.path.split('/').last.toLowerCase()));
        break;
      case FileSortBy.date:
        sorted.sort((a, b) => b.modified.compareTo(a.modified));
        break;
      case FileSortBy.size:
        sorted.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
    }
    return sorted;
  }

  Future<void> deleteFile(String path) async {
    final current = state;
    if (current is! FileManagerLoaded) return;
    final ok = await _repository.deleteFile(path);
    if (ok) {
      final updated = current.files.where((f) => f.path != path).toList();
      state = FileManagerState.loaded(
        category: current.category,
        files: updated,
        sortBy: current.sortBy,
        viewMode: current.viewMode,
      );
    }
  }

  Future<void> renameFile(String path, String newName) async {
    final ok = await _repository.renameFile(path, newName);
    if (ok) {
      final current = state;
      if (current is FileManagerLoaded) {
        await openCategory(current.category);
      }
    }
  }

  Future<void> shareFile(String path) => _repository.shareFile(path);
}
