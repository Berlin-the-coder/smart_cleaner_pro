import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/services/file_scan_service.dart';
import '../../../core/services/translation_service.dart';

part 'file_manager_state.freezed.dart';

enum FileCategory { images, videos, audio, documents, zips, apks, downloads }

extension FileCategoryLabel on FileCategory {
  String get label => switch (this) {
        FileCategory.images => T.of('fileCatImages'),
        FileCategory.videos => T.of('fileCatVideos'),
        FileCategory.audio => T.of('fileCatAudio'),
        FileCategory.documents => T.of('fileCatDocuments'),
        FileCategory.zips => T.of('fileCatArchives'),
        FileCategory.apks => T.of('apks'),
        FileCategory.downloads => T.of('fileCatDownloads'),
      };

  IconData get icon => switch (this) {
        FileCategory.images => Icons.image_outlined,
        FileCategory.videos => Icons.videocam_outlined,
        FileCategory.audio => Icons.music_note_outlined,
        FileCategory.documents => Icons.description_outlined,
        FileCategory.zips => Icons.folder_zip_outlined,
        FileCategory.apks => Icons.android_outlined,
        FileCategory.downloads => Icons.download_outlined,
      };
}

enum FileSortBy { name, date, size }
enum FileViewMode { grid, list }

/// One category card on the overview screen — real size, computed from
/// disk, not an estimate.
class CategorySummary {
  final FileCategory category;
  final int sizeBytes;
  const CategorySummary({required this.category, required this.sizeBytes});
}

@freezed
class FileManagerState with _$FileManagerState {
  const factory FileManagerState.overviewLoading() = FileManagerOverviewLoading;

  const factory FileManagerState.overview({
    required List<CategorySummary> categories,
    required int usedBytes,
    required int totalBytes,
    String? searchQuery,
    List<ScannedFile>? searchResults,
  }) = FileManagerOverview;

  const factory FileManagerState.permissionRequired() =
      FileManagerPermissionRequired;
  const factory FileManagerState.loading(FileCategory category) =
      FileManagerLoading;
  const factory FileManagerState.loaded({
    required FileCategory category,
    required List<ScannedFile> files,
    required FileSortBy sortBy,
    required FileViewMode viewMode,
  }) = FileManagerLoaded;
  const factory FileManagerState.error(String message) = FileManagerError;
}
