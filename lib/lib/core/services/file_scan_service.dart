import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;

/// Restricted directories that cannot be read on Android 11+ even with
/// MANAGE_EXTERNAL_STORAGE — must be skipped, not just caught, otherwise a
/// single PathAccessException aborts the entire recursive listing.
const _restrictedSegments = [
  'android/data',
  'android/obb',
  'android/media',
];

/// Priority folders to scan first — results appear faster to the user
/// because these dirs hold the most junk on a typical Android device.
const _priorityFolders = [
  '/storage/emulated/0/Android/cache',
  '/storage/emulated/0/.cache',
  '/storage/emulated/0/DCIM',
  '/storage/emulated/0/Download',
  '/storage/emulated/0/WhatsApp',
];

class ScannedFile {
  final String path;
  final int sizeBytes;
  final DateTime modified;
  final String extension;

  ScannedFile({
    required this.path,
    required this.sizeBytes,
    required this.modified,
    required this.extension,
  });
}

// ─── Isolate message types ────────────────────────────────────────────────────

class _WalkRequest {
  final SendPort replyPort;
  final String rootPath;
  final Set<String> restrictedSegments;
  const _WalkRequest(this.replyPort, this.rootPath, this.restrictedSegments);
}

class _FileData {
  final String path;
  final int sizeBytes;
  final int modifiedMs;
  final String extension;
  const _FileData(this.path, this.sizeBytes, this.modifiedMs, this.extension);
}

/// Entry point for the background isolate — walks the given directory tree
/// synchronously (no Dart event-loop overhead per file) and sends batches
/// of raw file data back over the SendPort. Runs entirely off the main
/// isolate so the UI thread is never blocked.
void _walkIsolate(_WalkRequest req) {
  const batchSize = 200;
  final batch = <_FileData>[];
  final restricted = req.restrictedSegments;

  void walk(String dirPath) {
    final lower = dirPath.toLowerCase();
    if (restricted.any((seg) => lower.contains(seg))) return;

    List<FileSystemEntity> entries;
    try {
      entries = Directory(dirPath).listSync(followLinks: false);
    } catch (_) {
      return;
    }

    for (final entity in entries) {
      final ePath = entity.path;
      final eLower = ePath.toLowerCase();
      if (restricted.any((seg) => eLower.contains(seg))) continue;

      if (entity is Directory) {
        walk(ePath);
      } else if (entity is File) {
        FileStat stat;
        try {
          stat = entity.statSync();
        } catch (_) {
          continue;
        }
        batch.add(_FileData(
          ePath,
          stat.size,
          stat.modified.millisecondsSinceEpoch,
          p.extension(ePath).toLowerCase(),
        ));
        if (batch.length >= batchSize) {
          req.replyPort.send(List<_FileData>.of(batch));
          batch.clear();
        }
      }
    }
  }

  walk(req.rootPath);

  // Flush remainder + sentinel null to signal completion.
  req.replyPort.send(List<_FileData>.of(batch));
  req.replyPort.send(null);
}

// ─── Service ──────────────────────────────────────────────────────────────────

class FileScanService {
  /// Streams ALL files under [rootPath] via a background isolate using
  /// synchronous directory listing (no async overhead per entry).
  ///
  /// Priority directories are yielded first so the UI shows early results
  /// while the deeper walk is still running.
  Stream<List<ScannedFile>> _walkAll(String rootPath) async* {
    // 1. Priority pass — fast first results for common junk locations.
    final priorityFiles = <ScannedFile>[];
    for (final folder in _priorityFolders) {
      if (!Directory(folder).existsSync()) continue;
      await for (final batch in _walkIsolateStream(folder)) {
        priorityFiles.addAll(batch);
      }
    }
    if (priorityFiles.isNotEmpty) yield priorityFiles;

    // 2. Full walk in a background isolate for everything else.
    yield* _walkIsolateStream(rootPath);
  }

  /// Runs a single recursive walk of [rootPath] in a background isolate,
  /// streaming back [ScannedFile] batches.
  Stream<List<ScannedFile>> _walkIsolateStream(String rootPath) async* {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _walkIsolate,
      _WalkRequest(
        receivePort.sendPort,
        rootPath,
        Set.unmodifiable(_restrictedSegments),
      ),
      debugName: 'file_walk:$rootPath',
    );

    try {
      await for (final msg in receivePort) {
        if (msg == null) break; // sentinel — isolate finished
        final rawBatch = msg as List<_FileData>;
        yield rawBatch
            .map((d) => ScannedFile(
                  path: d.path,
                  sizeBytes: d.sizeBytes,
                  modified: DateTime.fromMillisecondsSinceEpoch(d.modifiedMs),
                  extension: d.extension,
                ))
            .toList(growable: false);
      }
    } finally {
      receivePort.close();
      isolate.kill(priority: Isolate.immediate);
    }
  }

  /// Streams files under [rootPath] whose extension is in [extensionFilter],
  /// in batches, so the UI can show progress.
  /// Always completes — even with zero matches — by yielding a final
  /// (possibly empty) batch, so listeners never spin forever.
  Stream<List<ScannedFile>> scanForJunk({
    required String rootPath,
    required List<String> extensionFilter,
  }) async* {
    final root = Directory(rootPath);
    if (!root.existsSync()) {
      yield [];
      return;
    }

    final filters = extensionFilter.map((e) => e.toLowerCase()).toSet();
    final batch = <ScannedFile>[];
    const uiBatchSize = 80; // larger batches → fewer setState calls
    bool emittedAny = false;

    await for (final fileBatch in _walkAll(rootPath)) {
      for (final file in fileBatch) {
        if (filters.isEmpty || filters.contains(file.extension)) {
          batch.add(file);
        }
        if (batch.length >= uiBatchSize) {
          emittedAny = true;
          yield List.of(batch);
          batch.clear();
        }
      }
    }

    if (batch.isNotEmpty || !emittedAny) {
      yield List.of(batch);
    }
  }

  /// Groups files under [rootPath] matching [extensionFilter] by content
  /// signature. Two-pass: group by size first (cheap), then only hash
  /// files that share a size with at least one other file — avoids
  /// hashing the entire storage for files that are obviously unique.
  ///
  /// Hashing is now done in parallel (up to 8 concurrent tasks) for a
  /// significant speed-up on duplicate-heavy libraries.
  Future<Map<String, List<ScannedFile>>> scanForDuplicates({
    required String rootPath,
    required List<String> extensionFilter,
  }) async {
    final root = Directory(rootPath);
    if (!root.existsSync()) return {};

    final filters = extensionFilter.map((e) => e.toLowerCase()).toSet();
    final bySize = <int, List<ScannedFile>>{};

    await for (final batch in _walkAll(rootPath)) {
      for (final file in batch) {
        if (file.sizeBytes == 0) continue;
        if (filters.isNotEmpty && !filters.contains(file.extension)) continue;
        bySize.putIfAbsent(file.sizeBytes, () => []).add(file);
      }
    }

    // Only hash files that share a size with at least one other file.
    final candidates = [
      for (final group in bySize.values)
        if (group.length >= 2) ...group,
    ];

    // Hash in parallel — 8 concurrent I/O operations balance throughput
    // and avoid saturating the storage bus.
    const concurrency = 8;
    final byHash = <String, List<ScannedFile>>{};
    final mu = Object(); // lightweight guard (single-threaded Dart, just doc)

    for (var i = 0; i < candidates.length; i += concurrency) {
      final chunk = candidates.sublist(
        i,
        (i + concurrency).clamp(0, candidates.length),
      );
      final results = await Future.wait(
        chunk.map((file) async {
          try {
            final hash = await _quickHash(file.path, file.sizeBytes);
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

    byHash.removeWhere((_, files) => files.length < 2);
    return byHash;
  }

  /// Public wrapper around [_quickHash] — used by repositories that already
  /// have a [ScannedFile] and want to hash it without triggering another walk.
  Future<String> hashFile(String path, int sizeBytes) =>
      _quickHash(path, sizeBytes);

  /// Cheap content fingerprint: size + first/last 8KB checksum.
  /// Reads bytes synchronously via readAsBytesSync on a capped slice
  /// to avoid RandomAccessFile open/close overhead per file.
  Future<String> _quickHash(String path, int size) async {
    // Run the synchronous I/O in a separate isolate so we don't block
    // the event loop while reading the sample bytes.
    return await Isolate.run(() {
      final file = File(path);
      const sampleSize = 8192; // 8 KB — catches more near-duplicates than 4 KB

      final headLen = size < sampleSize ? size : sampleSize;
      final raf = file.openSync();
      try {
        final head = raf.readSync(headLen);
        int headSum = 0;
        for (final b in head) {
          headSum = (headSum * 31 + b) & 0x7fffffff;
        }

        int tailSum = 0;
        if (size > sampleSize) {
          raf.setPositionSync(size - sampleSize);
          final tail = raf.readSync(sampleSize);
          for (final b in tail) {
            tailSum = (tailSum * 31 + b) & 0x7fffffff;
          }
        }
        return '$size:$headSum:$tailSum';
      } finally {
        raf.closeSync();
      }
    });
  }

  /// Total size of all files under [path] (skips restricted folders).
  Future<int> getDirectorySize(String path) async {
    int total = 0;
    await for (final batch in _walkAll(path)) {
      for (final file in batch) {
        total += file.sizeBytes;
      }
    }
    return total;
  }

  /// Walks [rootPath] exactly once, bucketing total size per category
  /// key based on [categoryExtensions] (category key → extension list).
  /// Far cheaper than walking the whole tree once per category.
  Future<Map<String, int>> computeCategorySizes({
    required String rootPath,
    required Map<String, List<String>> categoryExtensions,
    Map<String, String>? folderBuckets,
  }) async {
    final root = Directory(rootPath);
    if (!root.existsSync()) return {};

    final extToCategory = <String, String>{};
    for (final entry in categoryExtensions.entries) {
      for (final ext in entry.value) {
        extToCategory[ext.toLowerCase()] = entry.key;
      }
    }

    final buckets = <String, String>{
      for (final entry in (folderBuckets ?? const {}).entries)
        entry.key: entry.value.endsWith('/')
            ? entry.value.substring(0, entry.value.length - 1)
            : entry.value,
    };

    final totals = <String, int>{
      for (final k in categoryExtensions.keys) k: 0,
      for (final k in buckets.keys) k: 0,
    };

    await for (final batch in _walkAll(rootPath)) {
      for (final file in batch) {
        final category = extToCategory[file.extension];
        if (category != null) {
          totals[category] = (totals[category] ?? 0) + file.sizeBytes;
        }
        for (final entry in buckets.entries) {
          if (file.path.startsWith('${entry.value}/')) {
            totals[entry.key] = (totals[entry.key] ?? 0) + file.sizeBytes;
          }
        }
      }
    }
    return totals;
  }
}
