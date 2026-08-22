import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
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
  return FileManagerViewModel(ref.watch(fileManagerRepositoryProvider));
});

class FileManagerViewModel extends StateNotifier<FileManagerState> {
  final FileManagerRepository _repository;

  FileManagerViewModel(this._repository)
      : super(const FileManagerState.overviewLoading()) {
    loadOverview();
  }

  Future<void> loadOverview() async {
    final permission = await _repository.ensurePermission();
    if (permission != StoragePermissionResult.granted) {
      state = const FileManagerState.permissionRequired();
      return;
    }

    state = const FileManagerState.overviewLoading();
    try {
      // These two reads are independent (one hits disk_space_plus, the
      // other walks the filesystem) — starting both before awaiting
      // either cuts the wall-clock wait roughly in half versus doing
      // them one after another.
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
    // Guard against a stale search overwriting a newer one.
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

  Future<void> openCategory(FileCategory category) async {
    final permission = await _repository.ensurePermission();
    if (permission != StoragePermissionResult.granted) {
      state = const FileManagerState.permissionRequired();
      return;
    }

    state = FileManagerState.loading(category);
    try {
      final files = await _repository.listCategory(category);
      _sortAndSet(category, files, FileSortBy.date, FileViewMode.grid);
    } catch (e) {
      state = FileManagerState.error('Failed to load files: $e');
    }
  }

  void backToOverview() => loadOverview();

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
    final sorted = [...files];
    switch (sortBy) {
      case FileSortBy.name:
        sorted.sort((a, b) => a.path.split('/').last.toLowerCase().compareTo(
          b.path.split('/').last.toLowerCase(),
        ));
        break;
      case FileSortBy.date:
        sorted.sort((a, b) => b.modified.compareTo(a.modified));
        break;
      case FileSortBy.size:
        sorted.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
    }
    state = FileManagerState.loaded(
      category: category,
      files: sorted,
      sortBy: sortBy,
      viewMode: viewMode,
    );
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