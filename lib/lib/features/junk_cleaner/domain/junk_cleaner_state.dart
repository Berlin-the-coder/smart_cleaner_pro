import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/services/file_scan_service.dart';

part 'junk_cleaner_state.freezed.dart';

enum JunkCategory {
  apkFiles,
  cacheFiles,
  tempFiles,
  largeFiles,
  residualFiles,
}

extension JunkCategoryLabel on JunkCategory {
  String get label => switch (this) {
    JunkCategory.apkFiles => 'Useless APK Files',
    JunkCategory.cacheFiles => 'Cache Files',
    JunkCategory.tempFiles => 'Temporary Files',
    JunkCategory.largeFiles => 'Large Files',
    JunkCategory.residualFiles => 'Residual Files',
  };

  String get description => switch (this) {
    JunkCategory.apkFiles => 'Downloaded APK installers',
    JunkCategory.cacheFiles => 'App cache & temp data',
    JunkCategory.tempFiles => 'Temporary system files',
    JunkCategory.largeFiles => 'Files larger than 50MB',
    JunkCategory.residualFiles => 'Leftover app data',
  };
}

class JunkGroup {
  final JunkCategory category;
  final List<ScannedFile> files;
  final Set<String> selectedPaths;
  final bool isScanning; // category ka scan chal raha hai?

  JunkGroup({
    required this.category,
    required this.files,
    Set<String>? selectedPaths,
    this.isScanning = false,
  }) : selectedPaths = selectedPaths ?? files.map((f) => f.path).toSet();

  int get totalBytes => files.fold(0, (sum, f) => sum + f.sizeBytes);

  int get selectedBytes => files
      .where((f) => selectedPaths.contains(f.path))
      .fold(0, (sum, f) => sum + f.sizeBytes);

  bool get allSelected =>
      files.isNotEmpty && selectedPaths.length == files.length;

  JunkGroup copyWith({
    List<ScannedFile>? files,
    Set<String>? selectedPaths,
    bool? isScanning,
  }) =>
      JunkGroup(
        category: category,
        files: files ?? this.files,
        selectedPaths: selectedPaths ?? this.selectedPaths,
        isScanning: isScanning ?? this.isScanning,
      );
}

@freezed
class JunkCleanerState with _$JunkCleanerState {
  const factory JunkCleanerState.idle() = JunkCleanerIdle;

  const factory JunkCleanerState.permissionRequired() =
  JunkCleanerPermissionRequired;

  // Scanning: categories list dikhi rahegi, har ek ka isScanning flag
  const factory JunkCleanerState.scanning({
    required List<JunkGroup> groups,
  }) = JunkCleanerScanning;

  const factory JunkCleanerState.scanned({
    required List<JunkGroup> groups,
  }) = JunkCleanerScanned;

  const factory JunkCleanerState.cleaning() = JunkCleanerCleaning;

  const factory JunkCleanerState.cleaned({
    required int filesDeleted,
    required int bytesFreed,
  }) = JunkCleanerCleaned;

  const factory JunkCleanerState.error(String message) = JunkCleanerError;
}