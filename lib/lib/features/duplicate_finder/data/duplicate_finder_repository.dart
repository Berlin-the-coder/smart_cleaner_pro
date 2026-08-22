import 'dart:io';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/file_scan_service.dart';
import '../../../core/services/permission_service.dart';
import '../domain/duplicate_finder_state.dart';

abstract class DuplicateFinderRepository {
  Future<StoragePermissionResult> ensurePermission();
  Future<List<DuplicateGroup>> scan({DuplicateMediaType? onlyType});
  Future<({int deletedCount, int bytesFreed})> deleteFiles(
    List<String> paths,
  );
}

class DuplicateFinderRepositoryImpl implements DuplicateFinderRepository {
  final FileScanService _scanService;
  final PermissionService _permissionService;

  DuplicateFinderRepositoryImpl(this._scanService, this._permissionService);

  @override
  Future<StoragePermissionResult> ensurePermission() async {
    final media = await _permissionService.requestMediaAccess();
    if (media != StoragePermissionResult.granted) return media;
    return _permissionService.requestManageExternalStorage();
  }

  static const _typeExtensions = {
    DuplicateMediaType.images: AppConstants.imageExtensions,
    DuplicateMediaType.videos: AppConstants.videoExtensions,
    DuplicateMediaType.audio: AppConstants.audioExtensions,
    DuplicateMediaType.documents: AppConstants.docExtensions,
  };

  @override
  Future<List<DuplicateGroup>> scan({DuplicateMediaType? onlyType}) async {
    final root = Platform.isAndroid ? '/storage/emulated/0' : '';
    if (root.isEmpty) return [];

    // OLD approach: one full storage walk PER type (up to 4 walks).
    // NEW approach: one single walk, then classify by extension in-memory.
    // This alone cuts duplicate-scan time by up to 4x on large devices.

    final activeTypes = onlyType == null
        ? _typeExtensions.entries.toList()
        : _typeExtensions.entries.where((e) => e.key == onlyType).toList();

    // Build a combined extension → type lookup for O(1) classification.
    final extToType = <String, DuplicateMediaType>{};
    for (final entry in activeTypes) {
      for (final ext in entry.value) {
        extToType[ext.toLowerCase()] = entry.key;
      }
    }

    // One walk — bucket each file by (type, size) in a single pass.
    // byTypeThenSize[type][size] = list of ScannedFiles
    final byTypeThenSize =
        <DuplicateMediaType, Map<int, List<ScannedFile>>>{};
    for (final entry in activeTypes) {
      byTypeThenSize[entry.key] = {};
    }

    await for (final batch in _scanService.scanForJunk(
      rootPath: root,
      extensionFilter: const [], // accept all; classify below
    )) {
      for (final file in batch) {
        if (file.sizeBytes == 0) continue;
        final type = extToType[file.extension];
        if (type == null) continue;
        byTypeThenSize[type]!
            .putIfAbsent(file.sizeBytes, () => [])
            .add(file);
      }
    }

    // For each type, hash only files that share a size (same logic as
    // before, but we reuse the already-bucketed bySize map instead of
    // running scanForDuplicates which would do another full walk).
    final groups = <DuplicateGroup>[];

    for (final typeEntry in byTypeThenSize.entries) {
      final bySize = typeEntry.value;
      final byHash = <String, List<ScannedFile>>{};

      // Collect candidates (same size, ≥2 files).
      final candidates = [
        for (final sizeGroup in bySize.values)
          if (sizeGroup.length >= 2) ...sizeGroup,
      ];

      // Hash in parallel (8 concurrent) — same strategy as FileScanService.
      const concurrency = 8;
      for (var i = 0; i < candidates.length; i += concurrency) {
        final chunk = candidates.sublist(
          i,
          (i + concurrency).clamp(0, candidates.length),
        );
        final results = await Future.wait(
          chunk.map((file) async {
            try {
              final hash = await _scanService.hashFile(file.path, file.sizeBytes);
              return (file: file, hash: hash);
            } catch (_) {
              return null;
            }
          }),
        );
        for (final r in results) {
          if (r == null) continue;
          byHash.putIfAbsent(r.hash, () => []).add(r.file);
        }
      }

      for (final hashEntry in byHash.entries) {
        if (hashEntry.value.length < 2) continue;
        groups.add(DuplicateGroup(
          type: typeEntry.key,
          hash: hashEntry.key,
          files: hashEntry.value,
        ));
      }
    }

    return groups;
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
    return (deletedCount: deleted, bytesFreed: freed);
  }
}
