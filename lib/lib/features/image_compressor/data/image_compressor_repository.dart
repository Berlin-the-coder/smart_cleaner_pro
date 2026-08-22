import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

abstract class ImageCompressorRepository {
  Future<List<String>> pickImages();
  Future<int> fileSize(String path);

  /// Compresses [sourcePath] at [quality] (10–100), capping the longest
  /// side to [maxDimension]px, saves a copy to the device gallery via Gal
  /// (so it appears immediately without a MediaStore rescan), and returns
  /// the temp-file path of the compressed image.
  /// The original is never overwritten or deleted.
  Future<String?> compress({
    required String sourcePath,
    required int quality,
    required int maxDimension,
  });

  /// Requests gallery write access (Android 10+ / iOS).
  /// Returns true when access is granted.
  Future<bool> requestGalleryAccess();
}

class ImageCompressorRepositoryImpl implements ImageCompressorRepository {
  final ImagePicker _picker;

  ImageCompressorRepositoryImpl({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  // ── Pick ───────────────────────────────────────────────────────────────────
  @override
  Future<List<String>> pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 100);
    return files.map((f) => f.path).toList();
  }

  // ── File size ──────────────────────────────────────────────────────────────
  @override
  Future<int> fileSize(String path) async {
    final file = File(path);
    if (!await file.exists()) return 0;
    return file.length();
  }

  // ── Gallery access ─────────────────────────────────────────────────────────
  @override
  Future<bool> requestGalleryAccess() async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (hasAccess) return true;
      return await Gal.requestAccess(toAlbum: true);
    } catch (e) {
      debugPrint('[ImageCompressor] requestGalleryAccess error: $e');
      return false;
    }
  }

  // ── Compress + save to gallery ─────────────────────────────────────────────
  @override
  Future<String?> compress({
    required String sourcePath,
    required int quality,
    required int maxDimension,
  }) async {
    try {
      final targetPath = await _buildTempOutputPath(sourcePath);

      // 1. Compress the image into a temp file.
      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: quality,
        minWidth: maxDimension,
        minHeight: maxDimension,
        keepExif: false,
      );

      if (result == null) {
        debugPrint(
          '[ImageCompressor] compression returned null for $sourcePath',
        );
        return null;
      }

      // 2. Save to gallery via Gal.
      //    • Android → calls MediaScannerConnection so the image appears
      //      in the gallery immediately without a device reboot/rescan.
      //    • iOS     → calls PHAssetChangeRequest so it lands in Photos
      //      straight away.
      await Gal.putImage(result.path, album: 'Smart Cleaner Pro');

      debugPrint('[ImageCompressor] saved to gallery ✓ ${result.path}');
      return result.path;
    } on GalException catch (e) {
      // GalException carries a typed reason (accessDenied, notEnoughSpace…)
      debugPrint('[ImageCompressor] GalException ${e.type}: $e');
      return null;
    } catch (e) {
      debugPrint('[ImageCompressor] compress error: $e');
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Builds a unique path in the system temp directory.
  ///
  /// • HEIC / HEIF inputs are remapped to JPEG because
  ///   [FlutterImageCompress] cannot encode HEIC on Android.
  /// • A millisecond timestamp is appended so repeated compressions of
  ///   the same file never collide and never return a stale cached result.
  Future<String> _buildTempOutputPath(String sourcePath) async {
    final tempDir = await getTemporaryDirectory();

    final fileName = sourcePath.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    final baseName =
    dotIndex != -1 ? fileName.substring(0, dotIndex) : fileName;
    final ext =
    dotIndex != -1 ? fileName.substring(dotIndex).toLowerCase() : '';

    // flutter_image_compress cannot encode HEIC on Android.
    final outExt = (ext == '.heic' || ext == '.heif')
        ? '.jpg'
        : (ext.isEmpty ? '.jpg' : ext);

    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${tempDir.path}/${baseName}_compressed_$ts$outExt';
  }
}