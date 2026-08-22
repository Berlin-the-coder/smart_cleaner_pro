import 'dart:io';
import '../../../core/services/file_scan_service.dart';
import '../../../core/services/permission_service.dart';
import '../domain/junk_cleaner_state.dart';

abstract class JunkCleanerRepository {
  Future<StoragePermissionResult> ensurePermission();

  /// Per-category scan — yields updated groups list as the scan progresses
  Stream<List<JunkGroup>> scan();

  Future<({int deletedCount, int bytesFreed})> deleteFiles(List<String> paths);
}

class JunkCleanerRepositoryImpl implements JunkCleanerRepository {
  final FileScanService _scanService;
  final PermissionService _permissionService;

  JunkCleanerRepositoryImpl(this._scanService, this._permissionService);

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

  static const _root = '/storage/emulated/0';
  static const _tempExtensions = {'.tmp', '.log', '.bak', '.old', '.dmp'};
  static const _residualExtensions = {'.bak', '.old', '.dmp'};
  static const _largeFileThreshold = 50 * 1024 * 1024;

  @override
  Stream<List<JunkGroup>> scan() async* {
    if (!Platform.isAndroid) {
      yield [];
      return;
    }

    // NOTE: this used to run one full recursive walk of all of storage
    // PER category (5 separate walks — and the "Large Files" one on its
    // own already walked literally every file, since it has no extension
    // filter). That's why scanning felt slow. A single file only needs
    // to be looked at once to know which of the 5 categories it belongs
    // to, so this now does exactly one walk and classifies each file
    // into every category it matches as it goes — same real files, same
    // real categorization rules, ~5x less disk walking.
    final byCategory = <JunkCategory, List<ScannedFile>>{
      for (final c in JunkCategory.values) c: <ScannedFile>[],
    };

    // Initial frame — every category shows its scanning spinner right away.
    yield JunkCategory.values
        .map((c) => JunkGroup(category: c, files: const [], isScanning: true))
        .toList();

    var lastEmit = DateTime.now();

    await for (final batch in _scanService.scanForJunk(
      rootPath: _root,
      extensionFilter: const [], // every file — classification happens below
    )) {
      for (final file in batch) {
        final ext = file.extension.toLowerCase();
        final lowerPath = file.path.toLowerCase();
        final inCache = lowerPath.contains('/cache/') || lowerPath.contains('/.cache/');

        if (ext == '.apk') {
          byCategory[JunkCategory.apkFiles]!.add(file);
        }
        if ((ext == '.cache' || ext == '.tmp') && inCache) {
          byCategory[JunkCategory.cacheFiles]!.add(file);
        }
        if (_tempExtensions.contains(ext) && !inCache) {
          byCategory[JunkCategory.tempFiles]!.add(file);
        }
        if (file.sizeBytes > _largeFileThreshold) {
          byCategory[JunkCategory.largeFiles]!.add(file);
        }
        if (_residualExtensions.contains(ext) && !inCache) {
          byCategory[JunkCategory.residualFiles]!.add(file);
        }
      }

      // Throttle UI updates to a few times a second instead of once per
      // 40-file batch — keeps the scan responsive-looking without
      // spamming setState on a big device with thousands of batches.
      final now = DateTime.now();
      if (now.difference(lastEmit).inMilliseconds >= 400) {
        yield [
          for (final c in JunkCategory.values)
            JunkGroup(category: c, files: List.of(byCategory[c]!), isScanning: true),
        ];
        lastEmit = now;
      }
    }

    yield [
      for (final c in JunkCategory.values)
        JunkGroup(category: c, files: List.of(byCategory[c]!), isScanning: false),
    ];
  }

  @override
  Future<({int deletedCount, int bytesFreed})> deleteFiles(
      List<String> paths,
      ) async {
    int deleted = 0;
    int freed = 0;
    for (final path in paths) {
      try {
        final file = File(path);
        if (!await file.exists()) continue;
        final size = await file.length();
        await file.delete();
        deleted++;
        freed += size;
      } catch (_) {
        continue;
      }
    }
    if (deleted > 0) _scanService.removeFromCache(paths);
    return (deletedCount: deleted, bytesFreed: freed);
  }
}