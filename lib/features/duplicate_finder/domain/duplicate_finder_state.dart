import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/services/file_scan_service.dart';
import '../../../core/services/translation_service.dart';

part 'duplicate_finder_state.freezed.dart';

enum DuplicateMediaType { images, videos, audio, documents }

extension DuplicateMediaTypeLabel on DuplicateMediaType {
  String get label => switch (this) {
        DuplicateMediaType.images => T.of('dupCatImages'),
        DuplicateMediaType.videos => T.of('dupCatVideos'),
        DuplicateMediaType.audio => T.of('dupCatAudio'),
        DuplicateMediaType.documents => T.of('dupCatDocuments'),
      };

  /// Short form ("Images" not "Duplicate Images") for tight spaces like
  /// the type-picker grid cards. Previously this was derived by
  /// stripping the English word "Duplicate " off [label] with
  /// replaceFirst — that only ever worked in English and produced the
  /// full, longer translated string in every other language, which is
  /// what caused the grid cards to overflow once [label] became
  /// translatable.
  String get shortLabel => switch (this) {
        DuplicateMediaType.images => T.of('fileCatImages'),
        DuplicateMediaType.videos => T.of('fileCatVideos'),
        DuplicateMediaType.audio => T.of('fileCatAudio'),
        DuplicateMediaType.documents => T.of('fileCatDocuments'),
      };
}

/// One set of identical files (same SHA-256 hash), grouped under a media
/// type for display. Selection defaults to "keep the newest, select the
/// rest for deletion" — a safe default the user can still override.
class DuplicateGroup {
  final DuplicateMediaType type;
  final String hash;
  final List<ScannedFile> files;
  final Set<String> selectedPaths;

  DuplicateGroup({
    required this.type,
    required this.hash,
    required this.files,
    Set<String>? selectedPaths,
  }) : selectedPaths = selectedPaths ?? _defaultSelection(files);

  static Set<String> _defaultSelection(List<ScannedFile> files) {
    if (files.length < 2) return {};
    final sorted = [...files]..sort((a, b) => b.modified.compareTo(a.modified));
    // Keep the newest (sorted.first), pre-select the rest for deletion.
    return sorted.skip(1).map((f) => f.path).toSet();
  }

  int get selectedBytes => files
      .where((f) => selectedPaths.contains(f.path))
      .fold(0, (sum, f) => sum + f.sizeBytes);

  DuplicateGroup copyWith({Set<String>? selectedPaths}) => DuplicateGroup(
        type: type,
        hash: hash,
        files: files,
        selectedPaths: selectedPaths ?? this.selectedPaths,
      );
}

@freezed
class DuplicateFinderState with _$DuplicateFinderState {
  /// Competitor-style menu: pick which media type to scan (or "all").
  const factory DuplicateFinderState.typePicker() = DuplicateFinderTypePicker;
  const factory DuplicateFinderState.permissionRequired() =
      DuplicateFinderPermissionRequired;
  const factory DuplicateFinderState.scanning() = DuplicateFinderScanning;
  const factory DuplicateFinderState.scanned({
    required List<DuplicateGroup> groups,
  }) = DuplicateFinderScanned;
  const factory DuplicateFinderState.deleting() = DuplicateFinderDeleting;
  const factory DuplicateFinderState.deleted({
    required int filesDeleted,
    required int bytesFreed,
  }) = DuplicateFinderDeleted;
  const factory DuplicateFinderState.error(String message) =
      DuplicateFinderError;
}
