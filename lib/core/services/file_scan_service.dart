import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;

/// Restricted directories that cannot be read on Android 11+ even with
/// MANAGE_EXTERNAL_STORAGE — must be skipped, not just caught, otherwise a
/// single PathAccessException aborts the entire recursive listing.
///
/// NOTE: Android/media is deliberately NOT in this list. Unlike
/// Android/data and Android/obb (which stay blocked per-app even with
/// All Files Access due to additional SELinux policy), Android/media is
/// readable once MANAGE_EXTERNAL_STORAGE is granted — and it's exactly
/// where WhatsApp and many other apps store their videos/images
/// (Android/media/com.whatsapp/WhatsApp/Media/...). Excluding it meant
/// duplicate videos living there were never even scanned.
const _restrictedSegments = [
  'android/data',
  'android/obb',
];

/// Folder name fragments that get walked first within a directory's
/// children so common junk/media locations surface quickly — this is
/// done as a REORDERING within a single walk, not a second walk, so
/// nothing gets scanned twice.
const _priorityNameHints = [
  'cache',
  'dcim',
  'download',
  'whatsapp',
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

// ─── Isolate wire types ────────────────────────────────────────────────────

class _WalkJob {
  final String rootPath;
  final SendPort replyPort;
  const _WalkJob(this.rootPath, this.replyPort);
}

class _HashJob {
  final List<(String path, int size)> files;
  final SendPort replyPort;
  const _HashJob(this.files, this.replyPort);
}

class _FileData {
  final String path;
  final int sizeBytes;
  final int modifiedMs;
  final String extension;
  const _FileData(this.path, this.sizeBytes, this.modifiedMs, this.extension);
}

class _HashResult {
  final String path;
  final String? hash; // null = read failed, skip
  const _HashResult(this.path, this.hash);
}

/// Entry point for the single persistent worker isolate. Spawned exactly
/// ONCE per app session (see [_ScanWorker]) and reused for every scan or
/// hash request — this removes the isolate spawn/teardown cost that used
/// to happen on every single scan call (and, for hashing, on every
/// single FILE, which was the cause of scans hanging/stalling).
void _workerMain(SendPort initialReplyPort) {
  final commandPort = ReceivePort();
  initialReplyPort.send(commandPort.sendPort);

  commandPort.listen((message) {
    if (message is _WalkJob) {
      _runWalk(message.rootPath, message.replyPort);
    } else if (message is _HashJob) {
      _runHash(message.files, message.replyPort);
    }
  });
}

void _runWalk(String rootPath, SendPort replyPort) {
  const batchSize = 200;
  final batch = <_FileData>[];

  void flush() {
    if (batch.isEmpty) return;
    replyPort.send(List<_FileData>.of(batch));
    batch.clear();
  }

  void walk(String dirPath) {
    final lower = dirPath.toLowerCase();
    if (_restrictedSegments.any((seg) => lower.contains(seg))) return;

    List<FileSystemEntity> entries;
    try {
      entries = Directory(dirPath).listSync(followLinks: false);
    } catch (_) {
      return;
    }

    // Reorder so priority-hinted directories are visited first WITHIN
    // this same pass — gives fast early results without a second walk.
    entries.sort((a, b) {
      final aPriority =
          _priorityNameHints.any((h) => a.path.toLowerCase().contains(h));
      final bPriority =
          _priorityNameHints.any((h) => b.path.toLowerCase().contains(h));
      if (aPriority == bPriority) return 0;
      return aPriority ? -1 : 1;
    });

    for (final entity in entries) {
      final ePath = entity.path;
      final eLower = ePath.toLowerCase();
      if (_restrictedSegments.any((seg) => eLower.contains(seg))) continue;

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
        if (batch.length >= batchSize) flush();
      }
    }
  }

  walk(rootPath);
  flush();
  replyPort.send(null); // sentinel — walk finished
}

void _runHash(List<(String path, int size)> files, SendPort replyPort) {
  const sampleSize = 8192;
  final results = <_HashResult>[];

  for (final entry in files) {
    final (path, size) = entry;
    try {
      final raf = File(path).openSync();
      try {
        final headLen = size < sampleSize ? size : sampleSize;
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
        results.add(_HashResult(path, '$size:$headSum:$tailSum'));
      } finally {
        raf.closeSync();
      }
    } catch (_) {
      results.add(const _HashResult('', null)); // dropped below
    }
  }

  replyPort.send(results);
}

/// Owns the single long-lived worker isolate. Lazily spawned on first
/// use and kept alive for the rest of the app session — every scan or
/// hash request after the first one is sent to the SAME isolate, so
/// there's no repeated spawn latency.
class _ScanWorker {
  _ScanWorker._();
  static final _ScanWorker instance = _ScanWorker._();

  Isolate? _isolate;
  SendPort? _commandPort;
  Future<void>? _spawning;

  Future<SendPort> _ensureSpawned() async {
    if (_commandPort != null) return _commandPort!;
    if (_spawning != null) {
      await _spawning;
      return _commandPort!;
    }

    final completer = Completer<void>();
    _spawning = completer.future;

    final initPort = ReceivePort();
    _isolate = await Isolate.spawn(
      _workerMain,
      initPort.sendPort,
      debugName: 'scan_worker',
    );
    _commandPort = await initPort.first as SendPort;
    initPort.close();

    completer.complete();
    return _commandPort!;
  }

  Stream<List<ScannedFile>> walk(String rootPath) async* {
    final cmd = await _ensureSpawned();
    final replyPort = ReceivePort();
    cmd.send(_WalkJob(rootPath, replyPort.sendPort));

    try {
      await for (final msg in replyPort) {
        if (msg == null) break;
        final raw = msg as List<_FileData>;
        yield raw
            .map((d) => ScannedFile(
                  path: d.path,
                  sizeBytes: d.sizeBytes,
                  modified: DateTime.fromMillisecondsSinceEpoch(d.modifiedMs),
                  extension: d.extension,
                ))
            .toList(growable: false);
      }
    } finally {
      replyPort.close();
    }
  }

  Future<Map<String, String>> hashMany(
    List<(String path, int size)> files,
  ) async {
    if (files.isEmpty) return {};
    final cmd = await _ensureSpawned();
    final replyPort = ReceivePort();
    cmd.send(_HashJob(files, replyPort.sendPort));

    final results = await replyPort.first as List<_HashResult>;
    replyPort.close();

    final map = <String, String>{};
    for (final r in results) {
      if (r.hash != null && r.path.isNotEmpty) map[r.path] = r.hash!;
    }
    return map;
  }
}

// ─── Shared storage snapshot cache ─────────────────────────────────────────

class _StorageSnapshot {
  final List<ScannedFile> files;
  final DateTime capturedAt;
  _StorageSnapshot(this.files, this.capturedAt);
}

/// Caches the result of a full walk per root path, for a short TTL.
/// Shared across File Manager, Junk Cleaner, and Duplicate Finder (they
/// all go through [FileScanService], which is a singleton) — so opening
/// File Manager, then a category inside it, then going back, then
/// opening Duplicate Finder, all reuse the SAME walk instead of each
/// re-scanning all of storage from disk.
///
/// A real walk only happens: on the very first scan of a session, after
/// the TTL expires (something may have changed on disk that we don't
/// know about), or when explicitly invalidated (e.g. after a delete).
class _SnapshotCache {
  _SnapshotCache._();
  static final _SnapshotCache instance = _SnapshotCache._();

  static const ttl = Duration(minutes: 10);
  final Map<String, _StorageSnapshot> _byRoot = {};

  _StorageSnapshot? get(String root) {
    final s = _byRoot[root];
    if (s == null) return null;
    if (DateTime.now().difference(s.capturedAt) > ttl) return null;
    return s;
  }

  void set(String root, List<ScannedFile> files) {
    _byRoot[root] = _StorageSnapshot(List.of(files), DateTime.now());
  }

  void invalidateAll() => _byRoot.clear();

  /// Surgically removes specific paths from every cached snapshot —
  /// used right after a delete so the cache reflects reality without
  /// needing a full rescan. Cheap: just filtering in-memory lists.
  void removePaths(Set<String> paths) {
    if (paths.isEmpty) return;
    for (final key in _byRoot.keys.toList()) {
      final snap = _byRoot[key]!;
      final filtered =
          snap.files.where((f) => !paths.contains(f.path)).toList();
      if (filtered.length != snap.files.length) {
        _byRoot[key] = _StorageSnapshot(filtered, snap.capturedAt);
      }
    }
  }
}

// ─── Public service ─────────────────────────────────────────────────────────

class FileScanService {
  final _worker = _ScanWorker.instance;

  /// Streams the file list for [rootPath] — instantly from cache
  /// (single batch) if a fresh snapshot exists, or via a real disk walk
  /// (multiple batches, refreshing the cache as it completes) if not.
  /// Even on a cache hit the list is chunked into UI-sized pieces so
  /// callers that render progressively still get a nice incremental
  /// fill instead of one big jump — it's just near-instant since no
  /// disk I/O is involved.
  Stream<List<ScannedFile>> walkCached(
    String rootPath, {
    bool forceRefresh = false,
  }) async* {
    if (!forceRefresh) {
      final cached = _SnapshotCache.instance.get(rootPath);
      if (cached != null) {
        const chunk = 150;
        for (var i = 0; i < cached.files.length; i += chunk) {
          yield cached.files.sublist(
            i,
            (i + chunk).clamp(0, cached.files.length),
          );
          // Without this, a cache hit delivers ALL chunks in one tight
          // microtask burst — Dart doesn't yield control back to
          // Flutter's frame scheduler between plain `yield` statements
          // in an async* generator unless something actually suspends.
          // This tiny delay forces a real event-loop tick between
          // batches so the UI gets a chance to paint each one instead
          // of the whole list appearing to "jump in" at once.
          await Future.delayed(Duration.zero);
        }
        if (cached.files.isEmpty) yield const [];
        return;
      }
    }

    final collected = <ScannedFile>[];
    await for (final batch in _worker.walk(rootPath)) {
      collected.addAll(batch);
      yield batch;
    }
    _SnapshotCache.instance.set(rootPath, collected);
  }

  /// Call after deleting files so the cache doesn't keep serving stale
  /// (already-deleted) entries — cheap in-memory patch, no rescan.
  void removeFromCache(Iterable<String> paths) =>
      _SnapshotCache.instance.removePaths(paths.toSet());

  /// Forces the next scan of any root to re-walk from disk. Call this
  /// after operations that could add/move a large number of files in
  /// ways [removeFromCache] can't precisely account for.
  void invalidateCache() => _SnapshotCache.instance.invalidateAll();

  /// Streams files under [rootPath] whose extension is in
  /// [extensionFilter] (empty filter = all files), in UI-friendly
  /// batches. Always completes — even with zero matches — by yielding a
  /// final (possibly empty) batch, so listeners never spin forever.
  Stream<List<ScannedFile>> scanForJunk({
    required String rootPath,
    required List<String> extensionFilter,
  }) async* {
    if (!Directory(rootPath).existsSync()) {
      yield [];
      return;
    }

    final filters = extensionFilter.map((e) => e.toLowerCase()).toSet();
    final batch = <ScannedFile>[];
    const uiBatchSize = 80;
    bool emittedAny = false;

    await for (final fileBatch in walkCached(rootPath)) {
      for (final file in fileBatch) {
        if (filters.isEmpty || filters.contains(file.extension)) {
          batch.add(file);
        }
        if (batch.length >= uiBatchSize) {
          emittedAny = true;
          yield List.of(batch);
          batch.clear();
          // Same reasoning as in walkCached: force a real event-loop
          // tick between batches so Flutter's frame scheduler actually
          // gets to paint each one, instead of several batches landing
          // in one tight burst and looking like a sudden jump.
          await Future.delayed(Duration.zero);
        }
      }
    }

    if (batch.isNotEmpty || !emittedAny) {
      yield List.of(batch);
    }
  }

  /// Progressive duplicate scan: walks (cached if fresh), buckets
  /// candidates by size, then hashes in small chunks — emitting the
  /// cumulative set of CONFIRMED duplicate groups after every chunk
  /// instead of making the caller wait for every single file to be
  /// hashed before seeing anything. Each emission is the full picture
  /// so far (already-found groups don't disappear on the next emit).
  Stream<Map<String, List<ScannedFile>>> scanForDuplicatesStream({
    required String rootPath,
    required List<String> extensionFilter,
  }) async* {
    if (!Directory(rootPath).existsSync()) {
      yield {};
      return;
    }

    final filters = extensionFilter.map((e) => e.toLowerCase()).toSet();
    final bySize = <int, List<ScannedFile>>{};

    await for (final batch in walkCached(rootPath)) {
      for (final file in batch) {
        if (file.sizeBytes == 0) continue;
        if (filters.isNotEmpty && !filters.contains(file.extension)) continue;
        bySize.putIfAbsent(file.sizeBytes, () => []).add(file);
      }
    }

    final candidates = [
      for (final group in bySize.values)
        if (group.length >= 2) ...group,
    ];
    if (candidates.isEmpty) {
      yield {};
      return;
    }

    const hashChunkSize = 40;
    final byHash = <String, List<ScannedFile>>{};

    for (var i = 0; i < candidates.length; i += hashChunkSize) {
      final chunk = candidates.sublist(
        i,
        (i + hashChunkSize).clamp(0, candidates.length),
      );
      final hashInput = [for (final f in chunk) (f.path, f.sizeBytes)];
      final hashes = await _worker.hashMany(hashInput);

      for (final file in chunk) {
        final hash = hashes[file.path];
        if (hash == null) continue;
        byHash.putIfAbsent(hash, () => []).add(file);
      }

      final confirmedSoFar = <String, List<ScannedFile>>{
        for (final e in byHash.entries)
          if (e.value.length >= 2) e.key: List.of(e.value),
      };
      yield confirmedSoFar;
    }
  }

  /// Hashes many (path, size) pairs in one batched round-trip.
  Future<Map<String, String>> hashFiles(
    List<(String path, int size)> files,
  ) =>
      _worker.hashMany(files);

  /// Total size of all files under [path] (skips restricted folders).
  Future<int> getDirectorySize(String path) async {
    int total = 0;
    await for (final batch in walkCached(path)) {
      for (final file in batch) {
        total += file.sizeBytes;
      }
    }
    return total;
  }

  /// Walks [rootPath] exactly once (cached if fresh), bucketing total
  /// size per category key based on [categoryExtensions].
  Future<Map<String, int>> computeCategorySizes({
    required String rootPath,
    required Map<String, List<String>> categoryExtensions,
    Map<String, String>? folderBuckets,
  }) async {
    if (!Directory(rootPath).existsSync()) return {};

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

    await for (final batch in walkCached(rootPath)) {
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
