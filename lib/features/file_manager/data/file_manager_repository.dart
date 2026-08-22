import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/file_scan_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/storage_stats_service.dart';
import '../domain/file_manager_state.dart';

abstract class FileManagerRepository {
  Future<StoragePermissionResult> ensurePermission();
  Future<List<CategorySummary>> computeCategorySizes();
  Future<({int usedBytes, int totalBytes})> getStorageOverview();

  /// Streams files as they're discovered by the single shared worker
  /// isolate — first batch typically arrives well under a second.
  Stream<List<ScannedFile>> streamCategory(FileCategory category);

  Future<List<ScannedFile>> searchFiles(String query);
  Future<bool> deleteFile(String path);
  Future<bool> renameFile(String path, String newName);
  Future<void> shareFile(String path);
}

class FileManagerRepositoryImpl implements FileManagerRepository {
  final FileScanService _scanService;
  final PermissionService _permissionService;
  final StorageStatsService _storageStatsService;

  FileManagerRepositoryImpl(
    this._scanService,
    this._permissionService,
    this._storageStatsService,
  );

  static const _root = '/storage/emulated/0';
  static const _downloadsRoot = '/storage/emulated/0/Download';

  static const _categoryExtensions = {
    FileCategory.images: AppConstants.imageExtensions,
    FileCategory.videos: AppConstants.videoExtensions,
    FileCategory.audio: AppConstants.audioExtensions,
    FileCategory.documents: AppConstants.docExtensions,
    FileCategory.zips: AppConstants.zipExtensions,
    FileCategory.apks: AppConstants.apkExtensions,
  };

  @override
  Future<StoragePermissionResult> ensurePermission() async {
    // Whole-device filesystem scanning has no iOS equivalent (see the
    // enum doc comment) — check this BEFORE requesting any permission,
    // since there's nothing meaningful to grant here on iOS.
    if (Platform.isIOS) return StoragePermissionResult.unsupportedPlatform;
    final media = await _permissionService.requestMediaAccess();
    if (media != StoragePermissionResult.granted) return media;
    return _permissionService.requestManageExternalStorage();
  }

  @override
  Future<List<CategorySummary>> computeCategorySizes() async {
    if (!Platform.isAndroid) return [];

    final byCategoryExt = {
      for (final c in FileCategory.values)
        if (c != FileCategory.downloads) c.name: _categoryExtensions[c]!,
    };

    final sizeByKey = await _scanService.computeCategorySizes(
      rootPath: _root,
      categoryExtensions: byCategoryExt,
      folderBuckets: {'downloads': _downloadsRoot},
    );
    final downloadsSize = sizeByKey['downloads'] ?? 0;

    return [
      for (final entry in sizeByKey.entries)
        if (entry.key != 'downloads')
          CategorySummary(
            category:
                FileCategory.values.firstWhere((c) => c.name == entry.key),
            sizeBytes: entry.value,
          ),
      CategorySummary(
          category: FileCategory.downloads, sizeBytes: downloadsSize),
    ];
  }

  @override
  Future<({int usedBytes, int totalBytes})> getStorageOverview() async {
    final stats = await _storageStatsService.getStats();
    final totalBytes = (stats.totalGB * 1024 * 1024 * 1024).round();
    final usedBytes = (stats.usedGB * 1024 * 1024 * 1024).round();
    return (usedBytes: usedBytes, totalBytes: totalBytes);
  }

  @override
  Stream<List<ScannedFile>> streamCategory(FileCategory category) async* {
    if (!Platform.isAndroid) {
      yield [];
      return;
    }

    final root =
        category == FileCategory.downloads ? _downloadsRoot : _root;

    final extensions = category == FileCategory.downloads
        ? AppConstants.imageExtensions +
            AppConstants.videoExtensions +
            AppConstants.audioExtensions +
            AppConstants.docExtensions
        : _categoryExtensions[category]!;

    yield* _scanService.scanForJunk(
      rootPath: root,
      extensionFilter: extensions,
    );
  }

  @override
  Future<List<ScannedFile>> searchFiles(String query) async {
    if (!Platform.isAndroid || query.trim().isEmpty) return [];
    final lowerQuery = query.toLowerCase();

    final allExtensions = AppConstants.imageExtensions +
        AppConstants.videoExtensions +
        AppConstants.audioExtensions +
        AppConstants.docExtensions +
        AppConstants.zipExtensions +
        AppConstants.apkExtensions;

    final results = <ScannedFile>[];
    await for (final batch in _scanService.scanForJunk(
      rootPath: _root,
      extensionFilter: allExtensions,
    )) {
      results.addAll(
        batch.where((f) =>
            f.path.split('/').last.toLowerCase().contains(lowerQuery)),
      );
      if (results.length >= 200) break;
    }
    return results;
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      await file.delete();
      _scanService.removeFromCache([path]);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> renameFile(String path, String newName) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      final dir = file.parent.path;
      await file.rename('$dir/$newName');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> shareFile(String path) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }
}
