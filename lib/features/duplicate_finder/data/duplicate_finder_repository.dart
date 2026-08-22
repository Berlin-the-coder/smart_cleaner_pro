import 'dart:io';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/file_scan_service.dart';
import '../../../core/services/permission_service.dart';
import '../domain/duplicate_finder_state.dart';

abstract class DuplicateFinderRepository {
  Future<StoragePermissionResult> ensurePermission();

  /// Streams the CUMULATIVE set of confirmed duplicate groups as the
  /// scan progresses — each emission is the full picture so far, so
  /// the UI can show results building up live instead of waiting for
  /// the entire scan (walk + hash every candidate) to finish before
  /// showing anything.
  Stream<List<DuplicateGroup>> scan({DuplicateMediaType? onlyType});

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
    // Whole-device filesystem scanning has no iOS equivalent (see the
    // enum doc comment) — check this BEFORE requesting any permission,
    // since there's nothing meaningful to grant here on iOS.
    if (Platform.isIOS) return StoragePermissionResult.unsupportedPlatform;
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
  Stream<List<DuplicateGroup>> scan({DuplicateMediaType? onlyType}) async* {
    final root = Platform.isAndroid ? '/storage/emulated/0' : '';
    if (root.isEmpty) {
      yield [];
      return;
    }

    final activeTypes = onlyType == null
        ? _typeExtensions.entries.toList()
        : _typeExtensions.entries.where((e) => e.key == onlyType).toList();

    final extToType = <String, DuplicateMediaType>{};
    for (final entry in activeTypes) {
      for (final ext in entry.value) {
        extToType[ext.toLowerCase()] = entry.key;
      }
    }

    final byTypeThenSize = <DuplicateMediaType, Map<int, List<ScannedFile>>>{};
    final alreadyQueued = <String>{};
    final byHash = <String, List<(ScannedFile, DuplicateMediaType)>>{};

    List<DuplicateGroup> currentGroups() => [
          for (final entry in byHash.entries)
            if (entry.value.length >= 2)
              DuplicateGroup(
                type: entry.value.first.$2,
                hash: entry.key,
                files: [for (final (f, _) in entry.value) f],
              ),
        ];

    // Hashes whatever same-size groups have grown to 2+ members SINCE
    // the last time we checked, in small chunks. Called periodically
    // WHILE the walk is still running (see below) — this is what makes
    // results appear progressively for every type, not just when the
    // walk happens to already be warm in cache.
    Future<void> hashNewCandidates() async {
      final newCandidates = <(ScannedFile, DuplicateMediaType)>[];
      for (final entry in byTypeThenSize.entries) {
        for (final group in entry.value.values) {
          if (group.length < 2) continue;
          for (final f in group) {
            if (alreadyQueued.contains(f.path)) continue;
            alreadyQueued.add(f.path);
            newCandidates.add((f, entry.key));
          }
        }
      }
      if (newCandidates.isEmpty) return;

      const chunkSize = 40;
      for (var i = 0; i < newCandidates.length; i += chunkSize) {
        final chunk = newCandidates.sublist(
          i,
          (i + chunkSize).clamp(0, newCandidates.length),
        );
        final hashInput = [for (final (f, _) in chunk) (f.path, f.sizeBytes)];
        final hashes = await _scanService.hashFiles(hashInput);
        for (final (file, type) in chunk) {
          final hash = hashes[file.path];
          if (hash == null) continue;
          byHash.putIfAbsent(hash, () => []).add((file, type));
        }
      }
    }

    var batchesSinceHash = 0;
    var emittedAny = false;

    await for (final batch in _scanService.walkCached(root)) {
      for (final file in batch) {
        if (file.sizeBytes == 0) continue;
        final type = extToType[file.extension];
        if (type == null) continue;
        byTypeThenSize
            .putIfAbsent(type, () => {})
            .putIfAbsent(file.sizeBytes, () => [])
            .add(file);
      }

      // Every couple of walk batches, hash whatever newly qualifies —
      // interleaved with the walk instead of waiting for it to finish.
      batchesSinceHash++;
      if (batchesSinceHash >= 2) {
        batchesSinceHash = 0;
        await hashNewCandidates();
        final groups = currentGroups();
        if (groups.isNotEmpty || emittedAny) {
          emittedAny = true;
          yield groups;
        }
      }
    }

    // Final pass — catches any size-group whose qualifying 2nd member
    // was one of the very last files walked.
    await hashNewCandidates();
    yield currentGroups();
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
    // Keep the shared cache accurate so File Manager / Junk Cleaner
    // don't briefly show these files as still present.
    if (deleted > 0) _scanService.removeFromCache(paths);
    return (deletedCount: deleted, bytesFreed: freed);
  }
}
